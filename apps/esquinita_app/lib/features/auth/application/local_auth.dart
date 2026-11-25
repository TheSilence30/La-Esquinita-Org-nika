import 'package:drift/drift.dart';
import 'package:esquinita_core/esquinita_core.dart';

import '../../../data/local/database.dart';
import '../../../data/remote/server_api.dart';
import '../../../data/sync/outbox_store.dart';
import '../../../data/sync/replica_store.dart';

/// Whether [pin] matches [hash] (Argon2id). Production runs it in a
/// background isolate: it takes about 1 s on the tablet (user, 2026-11-20).
typedef PinVerifier = Future<bool> Function(String pin, String hash);

/// Who is using the app.
class AppSession {
  const AppSession({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.permissions,
    required this.homeView,
  });

  final String userId;
  final String username;
  final String fullName;

  /// `modulo.accion` codes, from the local replicas (the core rule).
  final Set<String> permissions;

  /// `dashboard` or `sales`: the first screen of the user's role.
  final String homeView;

  bool can(String permission) => permissions.contains(permission);
}

/// Thrown when setting the device up fails for a reason the screen shows.
final class SetupException implements Exception {
  const SetupException(this.message);

  /// Spanish (Peru).
  final String message;
}

/// Outcome of a password login.
sealed class PasswordLogin {}

final class LoggedIn extends PasswordLogin {
  LoggedIn(this.session);
  final AppSession session;
}

/// First login with the initial password: choose a new one first.
final class NeedsNewPassword extends PasswordLogin {}

/// Outcome of a PIN login.
sealed class PinLogin {}

final class PinOk extends PinLogin {
  PinOk(this.session);
  final AppSession session;
}

final class WrongPin extends PinLogin {
  WrongPin(this.attemptsLeft);
  final int attemptsLeft;
}

/// The PIN cannot be used now; the password (online) is needed. [reason] is
/// for the screen.
final class PinNeedsPassword extends PinLogin {
  PinNeedsPassword(this.reason);
  final String reason;
}

/// An active user on this device's login screen. [blockedReason] null: the
/// PIN works; otherwise the password is needed and this says why.
typedef LoginUser = ({
  String userId,
  String username,
  String fullName,
  String? blockedReason,
});

/// Device setup, password and PIN logins (ADR-0004, plan Fase 1 §C).
class LocalAuth {
  LocalAuth({
    required this.db,
    required this.apiFor,
    required this.verifyPin,
    required this.platform,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final ServerApi Function(String serverUrl) apiFor;
  final PinVerifier verifyPin;

  /// `android` or `windows` (`devices.platform`).
  final String platform;
  final DateTime Function() _clock;

  /// The PIN works this long after the last password login (user decision).
  static const sessionLength = Duration(days: 7);

  /// Wrong PINs in a row that require the password.
  static const maxFailedPins = 5;

  /// A device clock this far behind the last login, or behind the latest
  /// time the app has seen, is not trusted.
  static const clockTolerance = Duration(minutes: 5);

  /// Records the device time if it is the latest seen (`last_seen_at`, in
  /// the encrypted database). It never goes down here, so setting the clock
  /// back cannot stretch the 7 days of the PIN. Called when the app opens,
  /// on every login and after every sync round.
  Future<void> markTimeSeen() async {
    final now = _clock().millisecondsSinceEpoch;
    if (now > (await _lastSeen() ?? 0)) await _set(_lastSeenKey, '$now');
  }

  late final _outbox = OutboxStore(db);
  late final _replicas = ReplicaStore(db);

  Future<bool> isRegistered() async =>
      await _get('device_registered') == 'true';

  /// Registers this device on the server with an Administrador's password
  /// and downloads users, roles and settings. That login is closed at once.
  Future<void> setUpDevice({
    required String serverUrl,
    required String deviceName,
    required String username,
    required String password,
  }) async {
    final api = apiFor(serverUrl);
    final LoginTokens t;
    try {
      t = await api.login(username, password, await _outbox.deviceId());
    } on ApiException catch (e) {
      throw SetupException(_loginMessage(e.failure));
    }
    try {
      await api.registerDevice(t.accessToken, deviceName, platform);
      await _pull(api, t.accessToken);
    } on ApiException catch (e) {
      throw SetupException(switch (e.failure) {
        ApiFailure.forbidden =>
          'Solo un Administrador puede registrar este equipo.',
        ApiFailure.offline => _offline,
        _ => 'El servidor no aceptó el registro (${e.detail ?? ''}).',
      });
    } finally {
      await _quietly(() => api.logout(t.refreshToken));
    }
    await _outbox.setServerUrl(serverUrl);
    await _set('device_registered', 'true');
  }

  /// Online login. On success the PIN works on this device for 7 days.
  Future<PasswordLogin> loginWithPassword(
    String username,
    String password,
  ) async {
    final api = await _api();
    final t = await _login(api, username, password);
    if (t.mustChangePassword) {
      await _quietly(() => api.logout(t.refreshToken));
      return NeedsNewPassword();
    }
    return LoggedIn(await _open(api, t));
  }

  /// First login: changes the initial password (the server then ends every
  /// login of the user) and logs in with the new one.
  Future<AppSession> loginWithNewPassword(
    String username,
    String current,
    String next,
  ) async {
    final api = await _api();
    final t = await _login(api, username, current);
    try {
      await api.changePassword(t.accessToken, current, next);
    } on ApiException catch (e) {
      throw SetupException(
        e.failure == ApiFailure.offline
            ? _offline
            : 'La nueva contraseña no es válida: usa 8 caracteres o más y '
                  'distinta de la actual.',
      );
    }
    return _open(api, await _login(api, username, next));
  }

  /// Every active user in the local replica, so nobody types a username.
  Future<List<LoginUser>> loginUsers() async {
    await markTimeSeen(); // the login screen is the app opening
    final lastSeen = await _lastSeen();
    final rows =
        await (db.select(db.users).join([
                leftOuterJoin(
                  db.localSessions,
                  db.localSessions.userId.equalsExp(db.users.id),
                ),
              ])
              ..where(db.users.active)
              ..orderBy([OrderingTerm.asc(db.users.fullName)]))
            .get();
    return [
      for (final r in rows)
        (
          userId: r.readTable(db.users).id,
          username: r.readTable(db.users).username,
          fullName: r.readTable(db.users).fullName,
          blockedReason: switch (r.readTableOrNull(db.localSessions)) {
            null => 'Entra una vez con tu contraseña.',
            final s => _blocked(s, r.readTable(db.users), lastSeen),
          },
        ),
    ];
  }

  /// Offline login. The attempt is counted before checking, so closing the
  /// app during the check gives no free attempts.
  Future<PinLogin> loginWithPin(String userId, String pin) async {
    final session = await (db.select(
      db.localSessions,
    )..where((s) => s.userId.equals(userId))).getSingleOrNull();
    final user = await (db.select(
      db.users,
    )..where((u) => u.id.equals(userId))).getSingleOrNull();
    if (session == null || user == null) {
      return PinNeedsPassword('Entra una vez con tu contraseña.');
    }
    final blocked = _blocked(session, user, await _lastSeen());
    if (blocked != null) return PinNeedsPassword(blocked);
    final failed = session.failedPins + 1;
    await _setFailedPins(userId, failed);
    if (await verifyPin(pin, user.pinHash!)) {
      await _setFailedPins(userId, 0);
      await markTimeSeen();
      return PinOk(await _session(userId));
    }
    if (failed >= maxFailedPins) {
      return PinNeedsPassword(
        'PIN incorrecto $maxFailedPins veces. Entra con tu contraseña.',
      );
    }
    return WrongPin(maxFailedPins - failed);
  }

  /// Ends the login here and on the server (if reachable). The PIN stops
  /// working on this device until the next password login.
  Future<void> logout(String userId) async {
    final session = await (db.select(
      db.localSessions,
    )..where((s) => s.userId.equals(userId))).getSingleOrNull();
    final refresh = session?.refreshToken;
    if (refresh != null) {
      await _quietly(() async => (await _api()).logout(refresh));
    }
    await (db.delete(
      db.localSessions,
    )..where((s) => s.userId.equals(userId))).go();
  }

  // --- internals -----------------------------------------------------------

  static const _offline =
      'Sin conexión con el servidor. Revisa el Wi‑Fi y la dirección.';

  static String _loginMessage(ApiFailure f) => switch (f) {
    ApiFailure.unauthorized => 'Usuario o contraseña incorrectos.',
    ApiFailure.locked => 'Demasiados intentos. Espera 15 minutos.',
    ApiFailure.offline => _offline,
    _ => 'El servidor no respondió bien. Intenta de nuevo.',
  };

  String? _blocked(LocalSession s, ReplicaUser u, int? lastSeen) {
    if (!u.active) return 'Este usuario está desactivado.';
    if (u.pinHash == null) return 'Entra una vez con tu contraseña.';
    if (s.failedPins >= maxFailedPins) {
      return 'PIN incorrecto $maxFailedPins veces. Entra con tu contraseña.';
    }
    final now = _clock();
    if (lastSeen != null &&
        now.millisecondsSinceEpoch < lastSeen - clockTolerance.inMilliseconds) {
      return 'La hora del equipo está atrasada. Corrígela o entra con tu '
          'contraseña.';
    }
    final age = now.difference(s.passwordLoginAt);
    if (age >= sessionLength || age < -clockTolerance) {
      return 'Pasaron 7 días desde tu último ingreso con contraseña. '
          'Conéctate y entra con ella.';
    }
    return null;
  }

  Future<ServerApi> _api() async {
    final url = await _outbox.serverUrl();
    if (url == null) throw const SetupException('Falta registrar el equipo.');
    return apiFor(url);
  }

  Future<LoginTokens> _login(ServerApi api, String u, String p) async {
    try {
      return await api.login(u, p, await _outbox.deviceId());
    } on ApiException catch (e) {
      throw SetupException(
        e.failure == ApiFailure.offline
            ? 'Sin conexión con el servidor. Si ya entraste antes en este '
                  'equipo, usa tu PIN.'
            : _loginMessage(e.failure),
      );
    }
  }

  /// After a password login: user id from /me, fresh replicas (they bring
  /// this user's PIN hash) and the saved login.
  Future<AppSession> _open(ServerApi api, LoginTokens t) async {
    final session = await _sessionOf(t.accessToken, api);
    await db
        .into(db.localSessions)
        .insertOnConflictUpdate(
          LocalSessionsCompanion.insert(
            userId: session.userId,
            refreshToken: Value(t.refreshToken),
            passwordLoginAt: _clock(),
            failedPins: const Value(0),
          ),
        );
    // The server accepted the password: trust the clock again, even if
    // lower, so a clock once set forward does not block the PIN for good.
    await _set(_lastSeenKey, '${_clock().millisecondsSinceEpoch}');
    return session;
  }

  Future<AppSession> _sessionOf(String accessToken, ServerApi api) async {
    try {
      final me = await api.me(accessToken);
      await _pull(api, accessToken);
      return await _session(
        (me['user']! as Map<String, Object?>)['id']! as String,
      );
    } on ApiException {
      throw const SetupException(_offline);
    }
  }

  Future<void> _pull(ServerApi api, String accessToken) async =>
      _replicas.apply(await api.pull(accessToken, await _replicas.cursor()));

  /// The session from the local replicas: the same data with or without a
  /// connection.
  Future<AppSession> _session(String userId) async {
    final user = await (db.select(
      db.users,
    )..where((u) => u.id.equals(userId))).getSingle();
    final views =
        await (db.select(db.userRoles).join([
              innerJoin(db.roles, db.roles.id.equalsExp(db.userRoles.roleId)),
            ])..where(
              db.userRoles.userId.equals(userId) &
                  db.userRoles.active &
                  db.roles.active,
            ))
            .map((r) => r.readTable(db.roles).homeView)
            .get();
    return AppSession(
      userId: userId,
      username: user.username,
      fullName: user.fullName,
      permissions: await _replicas.permissionsOf(userId),
      homeView: views.contains('dashboard') ? 'dashboard' : 'sales',
    );
  }

  Future<void> _setFailedPins(String userId, int n) =>
      (db.update(db.localSessions)..where((s) => s.userId.equals(userId)))
          .write(LocalSessionsCompanion(failedPins: Value(n)));

  static const _lastSeenKey = 'last_seen_at';

  /// Milliseconds since epoch (UTC).
  Future<int?> _lastSeen() async =>
      int.tryParse(await _get(_lastSeenKey) ?? '');

  Future<String?> _get(String key) async => (await (db.select(
    db.localSettings,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _set(String key, String value) => db
      .into(db.localSettings)
      .insertOnConflictUpdate(
        LocalSettingsCompanion.insert(key: key, value: value),
      );

  static Future<void> _quietly(Future<void> Function() f) async {
    try {
      await f();
    } on Exception {
      // Best effort: the token expires on its own.
    }
  }
}

/// The real check: core's Argon2id.
Future<bool> verifyPinArgon2(String pin, String hash) =>
    const PasswordHasher().verify(pin, hash);
