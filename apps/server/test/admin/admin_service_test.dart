// Users, ticket settings and devices against a real PostgreSQL. Set
// TEST_DATABASE_URL (CI does); without it these tests are skipped.
@Tags(['db'])
library;

import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/admin/admin_service.dart';
import 'package:esquinita_server/auth/auth_service.dart';
import 'package:esquinita_server/auth/bootstrap.dart';
import 'package:esquinita_server/auth/jwt.dart';
import 'package:esquinita_server/db.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../support/schema.dart';

const _pc = '019a9a00-0000-7000-8000-0000000000d1';
const _tablet = '019a9a00-0000-7000-8000-0000000000d2';

/// Cheap Argon2id: verify reads the cost from the hash.
const _hasher = PasswordHasher(memoryKib: 64, iterations: 1);

void main() {
  final url = testDatabaseUrl;
  if (url == null) {
    test('admin against PostgreSQL', () {}, skip: 'set TEST_DATABASE_URL');
    return;
  }

  late Pool<void> db;
  late AdminService admin;
  late AuthService auth;
  late AuthUser actor; // the Administrador, on the PC
  final now = DateTime.utc(2026, 11, 25, 15);

  setUp(() async {
    db = openPool(url);
    await resetSchema(db);
    await bootstrapUsers(db, {
      'ADMIN_INITIAL_PASSWORD': 'admin-inicial-1',
      'ADMIN_INITIAL_PIN': '1234',
      'STAFF_INITIAL_PASSWORD': 'trabajo-inicial-1',
      'STAFF_INITIAL_PIN': '5678',
    }, hasher: _hasher);
    for (final (id, platform, series, digit) in [
      (_pc, 'windows', 'P1', 1),
      (_tablet, 'android', 'T1', 2),
    ]) {
      await db.execute(
        Sql.named('''
          insert into devices (id, name, platform, series_prefix,
                               barcode_digit, version)
          values (@id:uuid, @s:text, @p:text, @s:text, @d:int4, 0)'''),
        parameters: {'id': id, 'p': platform, 's': series, 'd': digit},
      );
    }
    admin = AdminService(db, hasher: _hasher, clock: () => now);
    auth = AuthService(
      db,
      Jwt(
        'test-secret-with-at-least-32-characters!',
        ttl: const Duration(minutes: 15),
      ),
      refreshTtl: const Duration(days: 30),
      hasher: _hasher,
    );
    final adminId =
        (await db.execute(
              "select id from users where username = 'Administrador'",
            )).single[0]!
            as String;
    actor = AuthUser(
      userId: adminId,
      deviceId: _pc,
      username: 'Administrador',
      permissions: const {'users.manage', 'settings.manage'},
    );
  });

  tearDown(() => db.close());

  Future<Map<String, Object?>> userNamed(String username) async =>
      (await admin.users()).firstWhere((u) => u['username'] == username);

  Future<List<List<Object?>>> audit() async => [
    for (final r in await db.execute(
      'select action, entity_type, entity_id, before, after, user_id, '
      'device_id from audit_log order by at, action',
    ))
      r.toList(),
  ];

  Future<int> liveTokens(String column, String id) async =>
      (await db.execute(
            Sql.named(
              'select count(*) from refresh_tokens '
              'where $column = @id:uuid and revoked_at is null',
            ),
            parameters: {'id': id},
          )).single[0]!
          as int;

  Matcher refused(AdminRefusal r) =>
      throwsA(isA<AdminException>().having((e) => e.refusal, 'refusal', r));

  group('users', () {
    test('list: role, PIN set, never a hash', () async {
      final users = await admin.users();
      expect(users.map((u) => (u['username'], u['role'], u['has_pin'])), [
        ('Administrador', 'admin', true),
        ('Trabajo', 'staff', true),
      ]);
      expect(users.first.keys, isNot(contains('password_hash')));
      expect(users.first.keys, isNot(contains('pin_hash')));
    });

    test('create: logs in with the initial password, must change it, '
        'audited without secrets; a taken username (any case) is a '
        '409', () async {
      final u = await admin.createUser(
        actor,
        username: 'Maria',
        fullName: 'María Pérez',
        role: 'staff',
        password: 'inicial-maria',
        pin: '4321',
      );
      expect(u['role'], 'staff');
      final r = await auth.login('maria', 'inicial-maria', _tablet);
      expect(r.mustChangePassword, isTrue);
      final hashes = (await db.execute(
        "select pin_hash from users where username = 'Maria'",
      )).single[0]!;
      expect(await _hasher.verify('4321', hashes as String), isTrue);
      final a = (await audit()).single;
      expect(a.take(3), ['users.create', 'users', u['id']]);
      expect(a[4], {
        'username': 'Maria',
        'full_name': 'María Pérez',
        'role': 'staff',
      });
      expect(a[5], actor.userId);
      expect(a[6], _pc);
      await expectLater(
        admin.createUser(
          actor,
          username: 'MARIA',
          fullName: 'Otra',
          role: 'staff',
          password: 'inicial-otra',
          pin: '1111',
        ),
        refused(AdminRefusal.usernameTaken),
      );
    });

    test('update: rename and change role; the new version reaches the '
        'pull', () async {
      final staff = await userNamed('Trabajo');
      final v0 =
          (await db.execute('select max(version) from users')).single[0]!
              as int;
      final u = await admin.updateUser(
        actor,
        staff['id']! as String,
        username: 'Rosa',
        fullName: 'Rosa Quispe',
        role: 'admin',
      );
      expect(
        (u['username'], u['full_name'], u['role']),
        (
          'Rosa',
          'Rosa Quispe',
          'admin',
        ),
      );
      final roles = await db.execute(
        Sql.named(
          'select role_id, active, version from user_roles '
          'where user_id = @u:uuid order by role_id',
        ),
        parameters: {'u': staff['id']},
      );
      expect(roles.map((r) => (r[0], r[1])), [
        (adminRoleId, true),
        (staffRoleId, false),
      ]);
      expect(roles.every((r) => (r[2]! as int) > v0), isTrue);
      final a = (await audit()).single;
      expect(a[3], {
        'username': 'Trabajo',
        'full_name': 'Trabajo',
        'role': 'staff',
        'active': true,
      });
      expect((a[4]! as Map)['role'], 'admin');
      await expectLater(
        admin.updateUser(
          actor,
          staff['id']! as String,
          username:
              'admin'
              'istrador',
        ),
        refused(AdminRefusal.usernameTaken),
      );
    });

    test('deactivate ends every login of the user; reactivate lets them '
        'back in', () async {
      final id = (await userNamed('Trabajo'))['id']! as String;
      final t = (await auth.login(
        'Trabajo',
        'trabajo-inicial-1',
        _tablet,
      )).tokens!;
      await admin.updateUser(actor, id, active: false);
      expect(await liveTokens('user_id', id), 0);
      expect(await auth.authenticate(t.accessToken), isNull);
      await admin.updateUser(actor, id, active: true);
      expect(
        (await auth.login('Trabajo', 'trabajo-inicial-1', _tablet)).failure,
        isNull,
      );
    });

    test('an Administrador cannot deactivate themselves or drop their own '
        'role (so one active Administrador always remains)', () async {
      await expectLater(
        admin.updateUser(actor, actor.userId, active: false),
        refused(AdminRefusal.self),
      );
      await expectLater(
        admin.updateUser(actor, actor.userId, role: 'staff'),
        refused(AdminRefusal.self),
      );
      // Renaming themselves is fine.
      final u = await admin.updateUser(actor, actor.userId, fullName: 'Leo');
      expect(u['full_name'], 'Leo');
      await expectLater(
        admin.updateUser(actor, '019a9a00-0000-7000-8000-00000000ffff'),
        refused(AdminRefusal.notFound),
      );
    });

    test('temporary password: must change it, logins end; new PIN', () async {
      final id = (await userNamed('Trabajo'))['id']! as String;
      await auth.login('Trabajo', 'trabajo-inicial-1', _tablet);
      await admin.setPassword(actor, id, 'temporal-123');
      expect(await liveTokens('user_id', id), 0);
      expect(
        (await auth.login('Trabajo', 'trabajo-inicial-1', _tablet)).failure,
        LoginFailure.invalidCredentials,
      );
      final r = await auth.login('Trabajo', 'temporal-123', _tablet);
      expect(r.mustChangePassword, isTrue);

      final v0 =
          (await db.execute(
                Sql.named('select version from users where id = @u:uuid'),
                parameters: {'u': id},
              )).single[0]!
              as int;
      await admin.setPin(actor, id, '908172');
      final row = (await db.execute(
        Sql.named('select pin_hash, version from users where id = @u:uuid'),
        parameters: {'u': id},
      )).single;
      expect(await _hasher.verify('908172', row[0]! as String), isTrue);
      expect(row[1]! as int, greaterThan(v0), reason: 'devices pull it');
      expect((await audit()).map((a) => a[0]), [
        'users.set_password',
        'users.set_pin',
      ]);
      expect(
        (await audit()).every((a) => a[3] == null && a[4] == null),
        isTrue,
      );
    });
  });

  group('settings', () {
    test('only the changed ones are saved and audited; null is JSON '
        'null', () async {
      final before = await admin.settings();
      expect(before['business.ruc'], '10409288419');
      expect(before['business.phone'], isNull);
      expect(before.keys, unorderedEquals(AdminService.ticketSettings));
      final after = await admin.updateSettings(actor, {
        'business.ruc': '10409288419', // the same: nothing
        'business.phone': '987 654 321',
        'ticket.footer': 'Gracias, vuelva pronto',
      });
      expect(after['business.phone'], '987 654 321');
      expect(after['ticket.footer'], 'Gracias, vuelva pronto');
      expect((await audit()).map((a) => [a[0], a[2], a[3], a[4]]), [
        [
          'settings.update',
          'business.phone',
          {'value': null},
          {'value': '987 654 321'},
        ],
        [
          'settings.update',
          'ticket.footer',
          {'value': 'Gracias por su preferencia'},
          {'value': 'Gracias, vuelva pronto'},
        ],
      ]);
      await admin.updateSettings(actor, {'business.phone': null});
      final raw = await db.execute(
        'select value is null, jsonb_typeof(value) from settings '
        "where key = 'business.phone'",
      );
      expect(raw.single.toList(), [false, 'null']);
    });
  });

  group('devices', () {
    test('list with the last contact', () async {
      await auth.login('Trabajo', 'trabajo-inicial-1', _tablet);
      final ds = await admin.devices();
      expect(ds.map((d) => (d['series_prefix'], d['active'])), [
        ('P1', true),
        ('T1', true),
      ]);
      expect(ds.first['last_seen_at'], isNull);
      expect(ds.last['last_seen_at'], isNotNull);
    });

    test('"Dar de baja" ends every login on the device and blocks it; '
        '"Reactivar" lets it in; the own device cannot be taken out', () async {
      final t = (await auth.login(
        'Trabajo',
        'trabajo-inicial-1',
        _tablet,
      )).tokens!;
      await admin.setDeviceActive(actor, _tablet, active: false);
      expect(await liveTokens('device_id', _tablet), 0);
      expect(await auth.authenticate(t.accessToken), isNull);
      expect(
        (await auth.login('Trabajo', 'trabajo-inicial-1', _tablet)).failure,
        LoginFailure.deviceBlocked,
      );
      await admin.setDeviceActive(actor, _tablet, active: false); // no-op
      await admin.setDeviceActive(actor, _tablet, active: true);
      expect(
        (await auth.login('Trabajo', 'trabajo-inicial-1', _tablet)).failure,
        isNull,
      );
      expect((await audit()).map((a) => (a[0], a[2])), [
        ('devices.deactivate', _tablet),
        ('devices.reactivate', _tablet),
      ]);
      await expectLater(
        admin.setDeviceActive(actor, _pc, active: false),
        refused(AdminRefusal.self),
      );
      await expectLater(
        admin.setDeviceActive(
          actor,
          '019a9a00-0000-7000-8000-00000000ffff',
          active: true,
        ),
        refused(AdminRefusal.notFound),
      );
    });
  });
}
