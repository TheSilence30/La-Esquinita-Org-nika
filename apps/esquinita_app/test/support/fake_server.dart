import 'package:esquinita_app/data/remote/server_api.dart';
import 'package:esquinita_core/esquinita_core.dart';

// A fake server for the login tests: two users, an Administrador and a
// Trabajo who must change the initial password.

const adminId = 'u-admin';
const staffId = 'u-staff';

/// Cheap Argon2id for tests; verify reads the cost from the hash itself.
const testHasher = PasswordHasher(memoryKib: 64, iterations: 1);

class FakeUser {
  FakeUser(
    this.id,
    this.password, {
    this.mustChange = false,
    this.admin = false,
  });
  final String id;
  String password;
  bool mustChange;
  final bool admin;
  bool active = true;
}

/// In-memory server: logins, /me, register, pull, logout, refresh (rotating,
/// a reuse revokes the user's logins) and push (idempotent by op_id).
class FakeServer implements ServerApi {
  FakeServer(this.pinHash);

  /// Every user's PIN hash in the pull (the Administrador may change it).
  String pinHash;
  final users = {
    'Administrador': FakeUser(adminId, 'admin-1234', admin: true),
    'Trabajo': FakeUser(staffId, 'trabajo-1234', mustChange: true),
  };
  bool offline = false;

  /// The Administrador took this device out of service: 403
  /// `device_blocked` on login, refresh and every route with a session;
  /// nothing is revoked.
  bool deviceBlocked = false;

  static const _blocked = ApiException(
    ApiFailure.forbidden,
    '{"error":"device_blocked"}',
  );

  /// What the login sends as the `Date` header; null: none.
  DateTime? serverTime;
  final registered = <(String, String)>[];
  final loggedOut = <String>[];
  final logins = <String>[]; // device ids
  int _n = 0;

  /// Refresh tokens that still work.
  final liveRefresh = <String>{};

  /// Access tokens the server treats as expired (401).
  final expired = <String>{};
  final refreshes = <String>[];
  final inbox = <String, SyncCommand>{};
  final reported = <int>[];
  int pulls = 0;

  /// Apply the next refresh but lose its answer (the app never sees the new
  /// token).
  bool loseNextRefresh = false;

  void _check() {
    if (offline) throw const ApiException(ApiFailure.offline);
  }

  FakeUser _byToken(String token) =>
      users.values.firstWhere((u) => token.startsWith('a-${u.id}-'));

  @override
  Future<LoginTokens> login(String u, String p, String deviceId) async {
    _check();
    final user = users[u];
    if (user == null || user.password != p) {
      throw const ApiException(ApiFailure.unauthorized);
    }
    if (deviceBlocked) throw _blocked;
    logins.add(deviceId);
    return _issue(user);
  }

  /// The access token issued last.
  String? lastAccess;

  LoginTokens _issue(FakeUser user) {
    _n++;
    lastAccess = 'a-${user.id}-$_n';
    liveRefresh.add('r-${user.id}-$_n');
    return (
      accessToken: 'a-${user.id}-$_n',
      refreshToken: 'r-${user.id}-$_n',
      mustChangePassword: user.mustChange,
      serverTime: serverTime,
    );
  }

  FakeUser _authorized(String token) {
    if (deviceBlocked) throw _blocked;
    if (expired.contains(token) || !token.startsWith('a-')) {
      throw const ApiException(ApiFailure.unauthorized);
    }
    return _byToken(token);
  }

  @override
  Future<LoginTokens> refresh(String refreshToken) async {
    _check();
    if (deviceBlocked) throw _blocked; // before rotating, as the server
    refreshes.add(refreshToken);
    final user = users.values.firstWhere(
      (u) => refreshToken.startsWith('r-${u.id}-'),
    );
    if (!liveRefresh.remove(refreshToken)) {
      // Reused: revoke every login of the user, as the real server does.
      liveRefresh.removeWhere((t) => t.startsWith('r-${user.id}-'));
      throw const ApiException(ApiFailure.unauthorized);
    }
    final t = _issue(user);
    if (loseNextRefresh) {
      loseNextRefresh = false;
      throw const ApiException(ApiFailure.offline, 'timeout');
    }
    return t;
  }

  @override
  Future<List<PushResult>> push(
    String token,
    List<SyncCommand> commands, {
    required int pendingOps,
  }) async {
    _check();
    _authorized(token);
    reported.add(pendingOps);
    return [
      for (final c in commands)
        inbox.containsKey(c.opId)
            ? PushResult(
                c.opId,
                PushStatus.duplicate,
                originalStatus: PushStatus.applied,
              )
            : PushResult((inbox[c.opId] = c).opId, PushStatus.applied),
    ];
  }

  @override
  Future<Map<String, Object?>> me(String token) async {
    _check();
    return {
      'user': {'id': _byToken(token).id},
    };
  }

  @override
  Future<void> changePassword(String token, String current, String next) async {
    _check();
    if (next.length < 8) throw const ApiException(ApiFailure.rejected);
    _byToken(token)
      ..password = next
      ..mustChange = false;
  }

  @override
  Future<Map<String, Object?>> registerDevice(
    String token,
    String name,
    String platform,
  ) async {
    _check();
    if (!_byToken(token).admin) throw const ApiException(ApiFailure.forbidden);
    registered.add((name, platform));
    return {'series_prefix': 'T1'};
  }

  @override
  Future<Map<String, Object?>> pull(String token, int since) async {
    _check();
    _authorized(token);
    pulls++;
    Map<String, Object?> role(String id, String view) => {
      'id': id,
      'code': id,
      'name': id,
      'home_view': view,
      'active': true,
      'version': 1,
    };
    return {
      'cursor': 100 + _n,
      'changes': {
        'users': [
          for (final MapEntry(key: name, value: u) in users.entries)
            {
              'id': u.id,
              'username': name,
              'full_name': name,
              'pin_hash': pinHash,
              'active': u.active,
              'version': 1,
            },
        ],
        'roles': [role('admin', 'dashboard'), role('staff', 'sales')],
        'permissions': [
          for (final c in [Permissions.usersManage, Permissions.salesCreate])
            {'code': c, 'description': c, 'active': true, 'version': 1},
        ],
        'role_permissions': [
          for (final (r, c) in [
            ('admin', Permissions.usersManage),
            ('admin', Permissions.salesCreate),
            ('staff', Permissions.salesCreate),
          ])
            {'role_id': r, 'permission_code': c, 'active': true, 'version': 1},
        ],
        'user_roles': [
          {
            'user_id': adminId,
            'role_id': 'admin',
            'active': true,
            'version': 1,
          },
          {
            'user_id': staffId,
            'role_id': 'staff',
            'active': true,
            'version': 1,
          },
        ],
      },
    };
  }

  @override
  Future<void> logout(String refreshToken) async {
    _check();
    loggedOut.add(refreshToken);
    liveRefresh.remove(refreshToken);
  }

  // --- Administrador routes (task 7) -----------------------------------------

  /// Every admin request: (method, path, body).
  final requests = <(String, String, Map<String, Object?>?)>[];

  final settings = <String, Object?>{
    'business.name': 'La Esquinita Orgánika',
    'business.address': 'Av. Famesa',
    'business.ruc': '10409288419',
    'business.phone': null,
    'business.whatsapp': null,
    'ticket.footer': 'Gracias por su preferencia',
  };

  /// Device id → active.
  final devices = <String, bool>{'d-tablet': true, 'd-pc': true};

  static Never _refuse(String error) =>
      throw ApiException(ApiFailure.rejected, '{"error":"$error"}');

  @override
  Future<Map<String, Object?>> request(
    String method,
    String path,
    String token, {
    Map<String, Object?>? body,
  }) async {
    _check();
    final me = _authorized(token);
    if (!me.admin) throw const ApiException(ApiFailure.forbidden);
    requests.add((method, path, body));
    final parts = path.split('/').skip(1).toList();
    FakeUser byId(String id) => users.values.firstWhere(
      (u) => u.id == id,
      orElse: () => throw const ApiException(ApiFailure.notFound),
    );
    switch ((method, parts)) {
      case ('GET', ['users']):
        return {
          'users': [
            for (final MapEntry(key: name, value: u) in users.entries)
              {
                'id': u.id,
                'username': name,
                'full_name': name,
                'role': u.admin ? 'admin' : 'staff',
                'active': u.active,
                'has_pin': true,
                'must_change_password': u.mustChange,
                'last_login_at': null,
              },
          ],
        };
      case ('POST', ['users']):
        final name = body!['username']! as String;
        if (users.keys.any((k) => k.toLowerCase() == name.toLowerCase())) {
          _refuse('username_taken');
        }
        users[name] = FakeUser(
          'u-$name',
          body['password']! as String,
          mustChange: true,
          admin: body['role'] == 'admin',
        );
        return {'id': 'u-$name'};
      case ('PATCH', ['users', final id]):
        final u = byId(id);
        if (id == me.id && body!['active'] == false) _refuse('self');
        if (body!['active'] case final bool a) u.active = a;
        return {'id': id};
      case ('POST', ['users', final id, 'password' || 'pin']):
        byId(id);
        return const {};
      case ('GET', ['settings']):
        return settings;
      case ('PATCH', ['settings']):
        settings.addAll(body!);
        return settings;
      case ('GET', ['devices']):
        return {
          'devices': [
            for (final MapEntry(key: id, value: active) in devices.entries)
              {
                'id': id,
                'name': id == 'd-pc' ? 'PC caja' : 'Tablet caja',
                'platform': id == 'd-pc' ? 'windows' : 'android',
                'series_prefix': id == 'd-pc' ? 'P1' : 'T1',
                'active': active,
                'last_seen_at': '2026-11-25T17:46:00.000Z',
                'pending_ops': 0,
              },
          ],
        };
      case ('PATCH', ['devices', final id]):
        if (!devices.containsKey(id)) {
          throw const ApiException(ApiFailure.notFound);
        }
        devices[id] = body!['active']! as bool;
        return const {};
    }
    throw ApiException(ApiFailure.rejected, 'no route $method $path');
  }
}
