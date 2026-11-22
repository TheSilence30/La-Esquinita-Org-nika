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

  final String pinHash;
  final users = {
    'Administrador': FakeUser(adminId, 'admin-1234', admin: true),
    'Trabajo': FakeUser(staffId, 'trabajo-1234', mustChange: true),
  };
  bool offline = false;
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
    );
  }

  FakeUser _authorized(String token) {
    if (expired.contains(token) || !token.startsWith('a-')) {
      throw const ApiException(ApiFailure.unauthorized);
    }
    return _byToken(token);
  }

  @override
  Future<LoginTokens> refresh(String refreshToken) async {
    _check();
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
}
