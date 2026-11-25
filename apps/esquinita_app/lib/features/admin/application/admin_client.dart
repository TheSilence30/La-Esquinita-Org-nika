import 'dart:convert';

import '../../../data/remote/server_api.dart';
import '../../../data/sync/server_sync.dart';
import '../../../data/sync/sync_client.dart';

/// A user as the Administrador sees it (never a hash).
typedef AdminUser = ({
  String id,
  String username,
  String fullName,

  /// `admin` or `staff`.
  String role,
  bool active,
  bool hasPin,
  bool mustChangePassword,
  DateTime? lastLoginAt,
});

/// A registered device and its last contact with the server.
typedef AdminDevice = ({
  String id,
  String name,

  /// `android` or `windows`.
  String platform,
  String seriesPrefix,
  bool active,
  DateTime? lastSeenAt,
  int pendingOps,
});

/// The ticket settings this screen edits.
abstract final class TicketSetting {
  static const name = 'business.name';
  static const address = 'business.address';
  static const ruc = 'business.ruc';
  static const phone = 'business.phone';
  static const whatsapp = 'business.whatsapp';
  static const footer = 'ticket.footer';
}

/// Thrown with the Spanish (Peru) [message] for the screen.
final class AdminFailure implements Exception {
  const AdminFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Users, ticket settings and devices (task 7). Every change is online
/// (CLAUDE.md §7); [afterChange] then runs a sync round, so this device's
/// replicas get it at once.
class AdminClient {
  AdminClient(this._server, {required this.afterChange});

  final ServerSync _server;
  final Future<void> Function() afterChange;

  Future<List<AdminUser>> users() async => [
    for (final u in (await _get('/users'))['users']! as List)
      _user(u as Map<String, Object?>),
  ];

  Future<void> createUser({
    required String username,
    required String fullName,
    required String role,
    required String password,
    required String pin,
  }) => _change('POST', '/users', {
    'username': username,
    'full_name': fullName,
    'role': role,
    'password': password,
    'pin': pin,
  });

  /// Only the fields given change.
  Future<void> updateUser(
    String id, {
    String? username,
    String? fullName,
    String? role,
    bool? active,
  }) => _change('PATCH', '/users/$id', {
    'username': ?username,
    'full_name': ?fullName,
    'role': ?role,
    'active': ?active,
  });

  /// A temporary password: the user changes it on the next login.
  Future<void> setPassword(String id, String password) =>
      _change('POST', '/users/$id/password', {'password': password});

  Future<void> setPin(String id, String pin) =>
      _change('POST', '/users/$id/pin', {'pin': pin});

  /// [TicketSetting] key → value (a string or null).
  Future<Map<String, String?>> settings() async => {
    for (final MapEntry(:key, :value) in (await _get('/settings')).entries)
      key: value as String?,
  };

  Future<void> saveSettings(Map<String, String?> changed) =>
      _change('PATCH', '/settings', changed);

  Future<List<AdminDevice>> devices() async => [
    for (final d in (await _get('/devices'))['devices']! as List)
      _device(d as Map<String, Object?>),
  ];

  Future<void> renameDevice(String id, String name) =>
      _change('PATCH', '/devices/$id', {'name': name});

  /// false: "Dar de baja"; true: "Reactivar".
  Future<void> setDeviceActive(String id, {required bool active}) =>
      _change('PATCH', '/devices/$id', {'active': active});

  // --- internals -------------------------------------------------------------

  Future<Map<String, Object?>> _get(String path) =>
      _run((api, token) => api.request('GET', path, token));

  Future<void> _change(
    String method,
    String path,
    Map<String, Object?> body,
  ) async {
    await _run((api, token) => api.request(method, path, token, body: body));
    await afterChange();
  }

  Future<T> _run<T>(Future<T> Function(ServerApi api, String token) f) async {
    try {
      return await _server.authorized(f);
    } on SyncException catch (e) {
      throw AdminFailure(e.message);
    } on ApiException catch (e) {
      throw AdminFailure(message(e));
    }
  }

  /// What the screen says for a refused change.
  static String message(ApiException e) => switch (e.failure) {
    _ when e.deviceBlocked => ServerSync.deviceBlocked.message,
    ApiFailure.offline =>
      'Sin conexión con el servidor. Estos cambios necesitan conexión.',
    ApiFailure.forbidden => 'Solo un Administrador puede hacer esto.',
    ApiFailure.unauthorized => ServerSync.needsPassword.message,
    ApiFailure.notFound => 'Ya no existe. Actualiza la lista.',
    _ => switch (_code(e.detail)) {
      'username_taken' => 'Ese nombre de usuario ya existe.',
      'self' =>
        'No puedes desactivarte, quitarte el rol de Administrador ni dar de '
            'baja el equipo que estás usando.',
      final String? c when c != null && c.contains(':') =>
        'Revisa los datos ($c).',
      _ => 'El servidor no aceptó el cambio. Intenta de nuevo.',
    },
  };

  static String? _code(String? body) {
    try {
      return (jsonDecode(body ?? '') as Map<String, Object?>)['error']
          as String?;
    } on Object {
      return null;
    }
  }

  static AdminUser _user(Map<String, Object?> u) => (
    id: u['id']! as String,
    username: u['username']! as String,
    fullName: u['full_name']! as String,
    role: u['role'] as String? ?? 'staff',
    active: u['active']! as bool,
    hasPin: u['has_pin']! as bool,
    mustChangePassword: u['must_change_password']! as bool,
    lastLoginAt: _date(u['last_login_at']),
  );

  static AdminDevice _device(Map<String, Object?> d) => (
    id: d['id']! as String,
    name: d['name']! as String,
    platform: d['platform']! as String,
    seriesPrefix: d['series_prefix']! as String,
    active: d['active']! as bool,
    lastSeenAt: _date(d['last_seen_at']),
    pendingOps: d['pending_ops']! as int,
  );

  static DateTime? _date(Object? v) =>
      v == null ? null : DateTime.parse(v as String);
}
