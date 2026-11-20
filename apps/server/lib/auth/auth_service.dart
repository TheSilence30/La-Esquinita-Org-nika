import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/auth/jwt.dart';
import 'package:postgres/postgres.dart';

/// The user behind a valid access token, with the permissions read from the
/// database on this request (docs/modelo-datos.md §4).
class AuthUser {
  /// A session's user.
  const AuthUser({
    required this.userId,
    required this.deviceId,
    required this.username,
    required this.permissions,
  });

  /// `users.id`.
  final String userId;

  /// The device the session was opened on (from the token).
  final String deviceId;

  /// Login name.
  final String username;

  /// `modulo.accion` codes granted by the user's active roles.
  final Set<String> permissions;

  /// Whether the user has [permission].
  bool can(String permission) => permissions.contains(permission);
}

/// Access token (JWT), refresh token and the access token's lifetime in
/// seconds.
typedef Tokens = ({String accessToken, String refreshToken, int expiresIn});

/// Why a login failed.
enum LoginFailure {
  /// Unknown user, wrong password or deactivated user (one answer for all).
  invalidCredentials,

  /// Too many recent failures for this username.
  locked,
}

/// Either `tokens` (and whether the password must be changed) or `failure`.
typedef LoginResult = ({
  Tokens? tokens,
  bool mustChangePassword,
  LoginFailure? failure,
});

/// Outcome of a password change.
enum PasswordChange {
  /// Saved; every login of the user ended.
  changed,

  /// The current password did not match.
  wrongPassword,

  /// Shorter than [AuthService.minPasswordLength].
  tooShort,

  /// Same as the current password.
  sameAsBefore,
}

/// Login with Argon2id, short JWT access tokens and rotating refresh tokens
/// (CLAUDE.md §3, §11).
class AuthService {
  /// Uses [_db] for users and refresh tokens and [_jwt] for access tokens.
  AuthService(
    this._db,
    this._jwt, {
    required this.refreshTtl,
    PasswordHasher hasher = const PasswordHasher(),
    DateTime Function()? clock,
  }) : _passwords = hasher,
       _clock = clock ?? DateTime.now;

  final Pool<void> _db;
  final Jwt _jwt;
  final PasswordHasher _passwords;
  final DateTime Function() _clock;

  /// How long a refresh token works (`JWT_REFRESH_TTL_DAYS`).
  final Duration refreshTtl;

  /// Failed logins per username: 5 within [lockWindow] lock it for the
  /// rest of the window.
  // shortcut: in memory, per server process and lost on restart; move it to
  // PostgreSQL if the server ever runs more than one process.
  final _failures = <String, List<DateTime>>{};

  /// Failed logins that lock a username.
  static const maxFailures = 5;

  /// How far back failures count, and how long the lock lasts.
  static const lockWindow = Duration(minutes: 15);

  /// Shortest password accepted.
  static const minPasswordLength = 8;

  /// Verified when the username does not exist, so the answer takes the
  /// same time and does not reveal which usernames exist.
  static const _dummyHash =
      r'$argon2id$v=19$m=19456,t=2,p=1$AAECAwQFBgcICQoLDA0ODw'
      r'$xfViBWB08DC1DCyYYpfE8Zel6TztIC++D/IMWX0FN6A';

  /// Checks [username] and [password] and opens a session on [deviceId].
  Future<LoginResult> login(
    String username,
    String password,
    String deviceId,
  ) async {
    final key = username.trim().toLowerCase();
    if (_isLocked(key)) {
      return (
        tokens: null,
        mustChangePassword: false,
        failure: LoginFailure.locked,
      );
    }
    final rows = await _db.execute(
      Sql.named('''
        select id, password_hash, active, must_change_password from users
        where lower(username) = @u:text'''),
      parameters: {'u': key},
    );
    final row = rows.isEmpty ? null : rows.single;
    final ok = await _passwords.verify(
      password,
      row == null ? _dummyHash : row[1]! as String,
    );
    if (row == null || !ok || !(row[2]! as bool)) {
      (_failures[key] ??= []).add(_clock());
      return (
        tokens: null,
        mustChangePassword: false,
        failure: LoginFailure.invalidCredentials,
      );
    }
    _failures.remove(key);
    final userId = row[0]! as String;
    final tokens = await _db.runTx(
      (tx) => _issue(tx, userId, deviceId, family: uuidV7()),
    );
    return (
      tokens: tokens,
      mustChangePassword: row[3]! as bool,
      failure: null,
    );
  }

  /// New tokens for a valid refresh token, which stops working. Presenting
  /// a token that was already rotated means it was copied: the whole login
  /// (its family) is revoked.
  Future<Tokens?> refresh(String refreshToken) => _db.runTx((tx) async {
    final rows = await tx.execute(
      Sql.named('''
        select t.id, t.family_id, t.user_id, t.device_id, t.expires_at,
               t.revoked_at, u.active
        from refresh_tokens t join users u on u.id = t.user_id
        where t.token_hash = @h:text
        for update of t'''),
      parameters: {'h': _hash(refreshToken)},
    );
    if (rows.isEmpty) return null;
    final r = rows.single;
    final family = r[1]! as String;
    if (r[5] != null) {
      await _revokeFamily(tx, family);
      return null;
    }
    if (!(r[4]! as DateTime).isAfter(_clock()) || !(r[6]! as bool)) {
      return null;
    }
    await tx.execute(
      Sql.named(
        'update refresh_tokens set revoked_at = @now:timestamptz '
        'where id = @id:uuid',
      ),
      parameters: {'id': r[0], 'now': _clock()},
    );
    return _issue(tx, r[2]! as String, r[3]! as String, family: family);
  });

  /// Ends the login of [refreshToken] (every rotation of it).
  Future<void> logout(String refreshToken) => _db.runTx((tx) async {
    final rows = await tx.execute(
      Sql.named(
        'select family_id from refresh_tokens where token_hash = @h:text',
      ),
      parameters: {'h': _hash(refreshToken)},
    );
    if (rows.isNotEmpty) await _revokeFamily(tx, rows.single[0]! as String);
  });

  /// The user of a valid access token, if still active; null otherwise.
  Future<AuthUser?> authenticate(String accessToken) async {
    final claims = _jwt.verify(accessToken);
    if (claims == null) return null;
    final rows = await _db.execute(
      Sql.named(
        'select username from users where id = @u:uuid and active',
      ),
      parameters: {'u': claims.userId},
    );
    if (rows.isEmpty) return null;
    return AuthUser(
      userId: claims.userId,
      deviceId: claims.deviceId,
      username: rows.single[0]! as String,
      permissions: await _permissions(claims.userId),
    );
  }

  /// `GET /me`: the user, their roles (with the first screen) and
  /// permissions. Never the password or PIN hashes.
  Future<Map<String, Object?>> me(AuthUser user) async {
    final u = (await _db.execute(
      Sql.named('''
        select id, username, full_name, must_change_password from users
        where id = @u:uuid'''),
      parameters: {'u': user.userId},
    )).single;
    final roles = await _db.execute(
      Sql.named('''
        select r.code, r.name, r.home_view from user_roles ur
        join roles r on r.id = ur.role_id and r.active
        where ur.user_id = @u:uuid and ur.active
        order by r.code'''),
      parameters: {'u': user.userId},
    );
    return {
      'user': {
        'id': u[0],
        'username': u[1],
        'full_name': u[2],
        'must_change_password': u[3],
      },
      'roles': [
        for (final r in roles) {'code': r[0], 'name': r[1], 'home_view': r[2]},
      ],
      'permissions': (user.permissions.toList()..sort()),
    };
  }

  /// Changes the password and ends every login of the user (the device
  /// logs in again with the new one).
  Future<PasswordChange> changePassword(
    AuthUser user,
    String current,
    String next,
  ) async {
    if (next.length < minPasswordLength) return PasswordChange.tooShort;
    if (next == current) return PasswordChange.sameAsBefore;
    final hash =
        (await _db.execute(
              Sql.named('select password_hash from users where id = @u:uuid'),
              parameters: {'u': user.userId},
            )).single[0]!
            as String;
    if (!await _passwords.verify(current, hash)) {
      return PasswordChange.wrongPassword;
    }
    final newHash = await _passwords.hash(next);
    await _db.runTx((tx) async {
      await tx.execute(
        Sql.named('''
          update users set password_hash = @h:text,
                           must_change_password = false
          where id = @u:uuid'''),
        parameters: {'u': user.userId, 'h': newHash},
      );
      await tx.execute(
        Sql.named('''
          update refresh_tokens set revoked_at = @now:timestamptz
          where user_id = @u:uuid and revoked_at is null'''),
        parameters: {'u': user.userId, 'now': _clock()},
      );
    });
    return PasswordChange.changed;
  }

  Future<Set<String>> _permissions(String userId) async {
    final rows = await _db.execute(
      Sql.named('''
        select distinct rp.permission_code
        from user_roles ur
        join roles r on r.id = ur.role_id and r.active
        join role_permissions rp on rp.role_id = r.id and rp.active
        join permissions p on p.code = rp.permission_code and p.active
        where ur.user_id = @u:uuid and ur.active'''),
      parameters: {'u': userId},
    );
    return {for (final r in rows) r[0]! as String};
  }

  Future<Tokens> _issue(
    TxSession tx,
    String userId,
    String deviceId, {
    required String family,
  }) async {
    final refresh = _randomToken();
    await tx.execute(
      Sql.named('''
        insert into refresh_tokens
          (id, family_id, user_id, device_id, token_hash, created_at, expires_at)
        values (@id:uuid, @f:uuid, @u:uuid, @d:uuid, @h:text,
                @now:timestamptz, @exp:timestamptz)'''),
      parameters: {
        'id': uuidV7(),
        'f': family,
        'u': userId,
        'd': deviceId,
        'h': _hash(refresh),
        'now': _clock(),
        'exp': _clock().add(refreshTtl),
      },
    );
    return (
      accessToken: _jwt.sign((userId: userId, deviceId: deviceId)),
      refreshToken: refresh,
      expiresIn: _jwt.ttl.inSeconds,
    );
  }

  Future<void> _revokeFamily(TxSession tx, String family) => tx.execute(
    Sql.named('''
      update refresh_tokens set revoked_at = @now:timestamptz
      where family_id = @f:uuid and revoked_at is null'''),
    parameters: {'f': family, 'now': _clock()},
  );

  bool _isLocked(String key) {
    final since = _clock().subtract(lockWindow);
    final recent = (_failures[key] ?? [])
      ..removeWhere((t) => !t.isAfter(since));
    if (recent.isEmpty) _failures.remove(key);
    return recent.length >= maxFailures;
  }

  /// 256 random bits; the database keeps only its SHA-256.
  static String _randomToken() {
    final r = Random.secure();
    return base64Url
        .encode([for (var i = 0; i < 32; i++) r.nextInt(256)])
        .replaceAll('=', '');
  }

  static String _hash(String token) =>
      sha256.convert(utf8.encode(token)).toString();
}
