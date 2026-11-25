import 'dart:convert';

import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/auth/auth_service.dart';
import 'package:esquinita_server/auth/bootstrap.dart';
import 'package:postgres/postgres.dart';

/// Why an Administrador change was refused; the route maps it to a status.
enum AdminRefusal {
  /// No such user or device (404).
  notFound,

  /// Another user already has that username, in any case (409).
  usernameTaken,

  /// An Administrador cannot deactivate themselves or drop their own role,
  /// nor take their own device out of service. This also keeps at least one
  /// active Administrador: whoever makes the change stays one (409).
  self,
}

/// Thrown with the [AdminRefusal].
class AdminException implements Exception {
  /// Refused for [refusal].
  const AdminException(this.refusal);

  /// Why.
  final AdminRefusal refusal;
}

/// Users, ticket settings and devices for the Administrador (task 7). Every
/// change is online (CLAUDE.md §7), audited in the same transaction, and
/// bumps `version`, so devices get it on their next pull. Nothing is
/// deleted: users and devices are deactivated.
class AdminService {
  /// Uses [_db].
  AdminService(
    this._db, {
    PasswordHasher hasher = const PasswordHasher(),
    DateTime Function()? clock,
  }) : _hasher = hasher, // ignore: prefer_initializing_formals
       _clock = clock ?? DateTime.now;

  final Pool<void> _db;
  final PasswordHasher _hasher;
  final DateTime Function() _clock;

  /// Role codes an Administrador can give.
  static const roleIds = {'admin': adminRoleId, 'staff': staffRoleId};

  /// The ticket settings this screen edits; the rest belong to their phase.
  static const ticketSettings = [
    'business.name',
    'business.address',
    'business.ruc',
    'business.phone',
    'business.whatsapp',
    'ticket.footer',
  ];

  // --- users -----------------------------------------------------------------

  /// Every user, deactivated ones too. Never a hash: only whether a PIN is
  /// set.
  Future<List<Map<String, Object?>>> users() async {
    final rows = await _db.execute(
      '$_userSelect order by u.active desc, lower(u.full_name)',
    );
    return [for (final r in rows) _userJson(r)];
  }

  /// Creates a user who must change [password] on the first login.
  Future<Map<String, Object?>> createUser(
    AuthUser actor, {
    required String username,
    required String fullName,
    required String role,
    required String password,
    required String pin,
  }) async {
    final id = uuidV7();
    final passwordHash = await _hasher.hash(password);
    final pinHash = await _hasher.hash(pin);
    await _tx((tx) async {
      await _usernameFree(tx, username, null);
      await tx.execute(
        Sql.named('''
          insert into users (id, username, full_name, password_hash, pin_hash,
                             must_change_password, version)
          values (@id:uuid, @u:text, @n:text, @p:text, @pin:text, true, 0)'''),
        parameters: {
          'id': id,
          'u': username,
          'n': fullName,
          'p': passwordHash,
          'pin': pinHash,
        },
      );
      await _setRole(tx, id, role);
      await _audit(
        tx,
        actor,
        'users.create',
        'users',
        id,
        after: {'username': username, 'full_name': fullName, 'role': role},
      );
    });
    return (await _user(_db, id))!;
  }

  /// Changes the given fields; the others stay. Deactivating ends every
  /// login of the user.
  Future<Map<String, Object?>> updateUser(
    AuthUser actor,
    String id, {
    String? username,
    String? fullName,
    String? role,
    bool? active,
  }) async {
    await _tx((tx) async {
      final before = await _user(tx, id, lock: true);
      if (before == null) throw const AdminException(AdminRefusal.notFound);
      final self = id == actor.userId;
      if (self &&
          (active == false || (role != null && role != before['role']))) {
        throw const AdminException(AdminRefusal.self);
      }
      if (username != null) await _usernameFree(tx, username, id);
      await tx.execute(
        Sql.named('''
          update users set username = coalesce(@u:text, username),
                           full_name = coalesce(@n:text, full_name),
                           active = coalesce(@a:boolean, active)
          where id = @id:uuid'''),
        parameters: {'id': id, 'u': username, 'n': fullName, 'a': active},
      );
      if (role != null && role != before['role']) await _setRole(tx, id, role);
      if (active == false) await _revoke(tx, 'user_id', id);
      final after = (await _user(tx, id))!;
      await _audit(
        tx,
        actor,
        'users.update',
        'users',
        id,
        before: _visible(before),
        after: _visible(after),
      );
    });
    return (await _user(_db, id))!;
  }

  /// A temporary password: the user must change it on the next login, and
  /// every login of theirs ends now.
  Future<void> setPassword(AuthUser actor, String id, String password) async {
    final hash = await _hasher.hash(password);
    await _tx((tx) async {
      await _exists(tx, id);
      await tx.execute(
        Sql.named('''
          update users set password_hash = @h:text, must_change_password = true
          where id = @id:uuid'''),
        parameters: {'id': id, 'h': hash},
      );
      await _revoke(tx, 'user_id', id);
      await _audit(tx, actor, 'users.set_password', 'users', id);
    });
  }

  /// A new PIN. Devices where the user logged in get it on their next pull.
  Future<void> setPin(AuthUser actor, String id, String pin) async {
    final hash = await _hasher.hash(pin);
    await _tx((tx) async {
      await _exists(tx, id);
      await tx.execute(
        Sql.named('update users set pin_hash = @h:text where id = @id:uuid'),
        parameters: {'id': id, 'h': hash},
      );
      await _audit(tx, actor, 'users.set_pin', 'users', id);
    });
  }

  // --- settings --------------------------------------------------------------

  /// The ticket settings, key → value (a string or null).
  Future<Map<String, Object?>> settings() async {
    final rows = await _db.execute(
      Sql.named('select key, value from settings where key = any(@k:_text)'),
      parameters: {'k': ticketSettings},
    );
    return {for (final r in rows) r[0]! as String: r[1]};
  }

  /// Saves the [values] that changed (ticket settings only), audited one by
  /// one.
  Future<Map<String, Object?>> updateSettings(
    AuthUser actor,
    Map<String, Object?> values,
  ) async {
    await _tx((tx) async {
      for (final MapEntry(:key, :value) in values.entries) {
        final old = await tx.execute(
          Sql.named(
            'select value from settings where key = @k:text for update',
          ),
          parameters: {'k': key},
        );
        final before = old.single[0];
        if (before == value) continue; // unchanged: no new version
        await tx.execute(
          // Text cast, so a null value is JSON null (the column is not null).
          Sql.named(
            'update settings set value = @v:text::jsonb where key = @k:text',
          ),
          parameters: {'k': key, 'v': jsonEncode(value)},
        );
        await _audit(
          tx,
          actor,
          'settings.update',
          'settings',
          key,
          before: {'value': before},
          after: {'value': value},
        );
      }
    });
    return settings();
  }

  // --- devices ---------------------------------------------------------------

  /// Every registered device with its last contact with the server.
  Future<List<Map<String, Object?>>> devices() async {
    final rows = await _db.execute('''
      select d.id, d.name, d.platform, d.series_prefix, d.active, d.created_at,
             greatest(s.last_push_at, s.last_pull_at,
                      (select max(t.created_at) from refresh_tokens t
                       where t.device_id = d.id)),
             coalesce(s.pending_ops, 0)
      from devices d left join device_sync_status s on s.device_id = d.id
      order by d.active desc, d.series_prefix''');
    return [
      for (final r in rows)
        {
          'id': r[0],
          'name': r[1],
          'platform': r[2],
          'series_prefix': r[3],
          'active': r[4],
          'registered_at': (r[5]! as DateTime).toUtc().toIso8601String(),
          'last_seen_at': (r[6] as DateTime?)?.toUtc().toIso8601String(),
          'pending_ops': r[7],
        },
    ];
  }

  /// "Dar de baja" ([active] false): every login on the device ends and the
  /// server refuses it from now on; what the device keeps is not touched.
  /// "Reactivar" ([active] true) lets it log in again.
  Future<void> setDeviceActive(
    AuthUser actor,
    String id, {
    required bool active,
  }) => _tx((tx) async {
    if (!active && id == actor.deviceId) {
      throw const AdminException(AdminRefusal.self);
    }
    final rows = await tx.execute(
      Sql.named('''
            update devices set active = @a:boolean
            where id = @id:uuid and active <> @a:boolean
            returning id'''),
      parameters: {'id': id, 'a': active},
    );
    if (rows.isEmpty) {
      await _exists(tx, id, table: 'devices');
      return; // already so
    }
    if (!active) await _revoke(tx, 'device_id', id);
    await _audit(
      tx,
      actor,
      active ? 'devices.reactivate' : 'devices.deactivate',
      'device',
      id,
    );
  });

  // --- internals -------------------------------------------------------------

  Future<T> _tx<T>(Future<T> Function(TxSession tx) f) async {
    try {
      return await _db.runTx(f);
    } on ServerException catch (e) {
      // Two admins creating the same username at once.
      if (e.code == '23505') {
        throw const AdminException(AdminRefusal.usernameTaken);
      }
      rethrow;
    }
  }

  Future<void> _usernameFree(Session tx, String username, String? id) async {
    final rows = await tx.execute(
      Sql.named(
        '''
        select 1 from users
        where lower(username) = lower(@u:text) and id is distinct from @id:uuid''',
      ),
      parameters: {'u': username, 'id': id},
    );
    if (rows.isNotEmpty) throw const AdminException(AdminRefusal.usernameTaken);
  }

  Future<void> _exists(Session tx, String id, {String table = 'users'}) async {
    final rows = await tx.execute(
      Sql.named('select 1 from $table where id = @id:uuid'),
      parameters: {'id': id},
    );
    if (rows.isEmpty) throw const AdminException(AdminRefusal.notFound);
  }

  /// One active role per user: [role] on, every other one off.
  Future<void> _setRole(Session tx, String userId, String role) async {
    await tx.execute(
      Sql.named('''
        update user_roles set active = false
        where user_id = @u:uuid and role_id <> @r:uuid and active'''),
      parameters: {'u': userId, 'r': roleIds[role]},
    );
    await tx.execute(
      Sql.named('''
        insert into user_roles (user_id, role_id, version)
        values (@u:uuid, @r:uuid, 0)
        on conflict (user_id, role_id) do update set active = true
        where not user_roles.active'''),
      parameters: {'u': userId, 'r': roleIds[role]},
    );
  }

  Future<void> _revoke(Session tx, String column, String id) => tx.execute(
    Sql.named('''
      update refresh_tokens set revoked_at = @now:timestamptz
      where $column = @id:uuid and revoked_at is null'''),
    parameters: {'id': id, 'now': _clock()},
  );

  Future<Map<String, Object?>?> _user(
    Session tx,
    String id, {
    bool lock = false,
  }) async {
    final rows = await tx.execute(
      Sql.named(
        '$_userSelect where u.id = @id:uuid ${lock ? 'for update of u' : ''}',
      ),
      parameters: {'id': id},
    );
    return rows.isEmpty ? null : _userJson(rows.single);
  }

  /// Never a hash: only whether a PIN is set.
  static const _userSelect = '''
    select u.id, u.username, u.full_name, u.active, u.must_change_password,
           u.pin_hash is not null, u.last_login_at,
           (select r.code from user_roles ur join roles r on r.id = ur.role_id
            where ur.user_id = u.id and ur.active and r.active
            order by r.code limit 1)
    from users u''';

  static Map<String, Object?> _userJson(ResultRow r) => {
    'id': r[0],
    'username': r[1],
    'full_name': r[2],
    'active': r[3],
    'must_change_password': r[4],
    'has_pin': r[5],
    'last_login_at': (r[6] as DateTime?)?.toUtc().toIso8601String(),
    'role': r[7],
  };

  /// What the audit keeps of a user: never a hash, nor login times.
  static Map<String, Object?> _visible(Map<String, Object?> u) => {
    for (final k in ['username', 'full_name', 'role', 'active']) k: u[k],
  };

  Future<void> _audit(
    Session tx,
    AuthUser actor,
    String action,
    String entityType,
    String entityId, {
    Map<String, Object?>? before,
    Map<String, Object?>? after,
  }) => tx.execute(
    Sql.named('''
      insert into audit_log (at, user_id, device_id, action, entity_type,
                             entity_id, before, after)
      values (@at:timestamptz, @u:uuid, @d:uuid, @a:text, @t:text, @e:text,
              @b:jsonb, @af:jsonb)'''),
    parameters: {
      'at': _clock(),
      'u': actor.userId,
      'd': actor.deviceId,
      'a': action,
      't': entityType,
      'e': entityId,
      'b': before,
      'af': after,
    },
  );
}
