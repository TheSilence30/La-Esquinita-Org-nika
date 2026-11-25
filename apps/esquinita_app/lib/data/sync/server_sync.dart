import 'package:drift/drift.dart';
import 'package:esquinita_core/esquinita_core.dart';

import '../local/database.dart';
import '../remote/server_api.dart';
import 'outbox_store.dart';
import 'replica_store.dart';
import 'sync_client.dart';

/// Push and pull with the saved login of the user on screen: a 15-minute
/// access token from the rotating refresh token in the encrypted database.
///
/// A refresh token is used once: the new one is saved before anything else.
/// If the app dies between the server rotating it and that save, the next
/// refresh reuses the old one, the server revokes the login, and syncing
/// waits for a password login (user, 2026-11-22). Nothing pending is lost.
class ServerSync implements PushTransport {
  ServerSync({
    required this.db,
    required this.apiFor,
    required this.currentUserId,
  });

  final AppDatabase db;
  final ServerApi Function(String serverUrl) apiFor;

  /// Who is on screen now; null when nobody is logged in.
  final String? Function() currentUserId;

  late final _outbox = OutboxStore(db);
  late final _replicas = ReplicaStore(db);

  ({String userId, String token})? _access;

  static const needsPassword = SyncException(
    'Entra con tu contraseña para sincronizar.',
    needsPassword: true,
  );

  /// Retried like any error: once reactivated, it syncs by itself with the
  /// same login, without the password (user, 2026-11-25).
  static const deviceBlocked = SyncException(
    'Este equipo fue dado de baja. Pide al Administrador que lo reactive.',
  );

  @override
  Future<List<PushResult>> push(
    List<SyncCommand> commands, {
    required int pendingOps,
  }) =>
      _call((api, token) => api.push(token, commands, pendingOps: pendingOps));

  /// Master data changed since the local cursor, applied in one transaction.
  Future<void> pull() => _call(
    (api, token) async =>
        _replicas.apply(await api.pull(token, await _replicas.cursor())),
  );

  Future<T> _call<T>(Future<T> Function(ServerApi api, String token) f) async {
    try {
      return await authorized(f);
    } on ApiException catch (e) {
      throw _syncError(e);
    }
  }

  /// Runs [f] with a valid access token of the user on screen; on a 401
  /// (expired), refreshes once and retries. Other server answers come back
  /// as [ApiException]; a missing login as [SyncException].
  Future<T> authorized<T>(
    Future<T> Function(ServerApi api, String token) f,
  ) async {
    final url = await _outbox.serverUrl();
    if (url == null) {
      throw const SyncException('Falta registrar el equipo.');
    }
    final api = apiFor(url);
    for (var attempt = 0; ; attempt++) {
      final token = await _token(api);
      try {
        return await f(api, token);
      } on ApiException catch (e) {
        if (e.failure == ApiFailure.unauthorized && attempt == 0) {
          _access = null;
          continue;
        }
        rethrow;
      }
    }
  }

  Future<String> _token(ServerApi api) async {
    final userId = currentUserId();
    if (userId == null) throw needsPassword;
    if (_access case (userId: final u, :final token) when u == userId) {
      return token;
    }
    final session = await (db.select(
      db.localSessions,
    )..where((s) => s.userId.equals(userId))).getSingleOrNull();
    final refresh = session?.refreshToken;
    if (refresh == null) throw needsPassword;
    final LoginTokens t;
    try {
      t = await api.refresh(refresh);
    } on ApiException catch (e) {
      if (e.deviceBlocked) throw deviceBlocked; // keep the token
      if (e.failure == ApiFailure.unauthorized) {
        // Revoked or expired: never send it again.
        await _saveRefresh(userId, null);
        throw needsPassword;
      }
      throw _syncError(e);
    }
    await _saveRefresh(userId, t.refreshToken);
    _access = (userId: userId, token: t.accessToken);
    return t.accessToken;
  }

  Future<void> _saveRefresh(String userId, String? token) =>
      (db.update(db.localSessions)..where((s) => s.userId.equals(userId)))
          .write(LocalSessionsCompanion(refreshToken: Value(token)));

  static SyncException _syncError(ApiException e) => switch (e.failure) {
    _ when e.deviceBlocked => deviceBlocked,
    ApiFailure.offline => SyncException(
      'Sin conexión con el servidor. Revisa el Wi‑Fi.',
      detail: e.detail,
    ),
    ApiFailure.unauthorized => needsPassword,
    _ => SyncException('El servidor respondió con un error.', detail: e.detail),
  };
}
