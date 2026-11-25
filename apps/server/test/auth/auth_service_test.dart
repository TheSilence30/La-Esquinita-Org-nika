// Login, sessions and first users against a real PostgreSQL. Set
// TEST_DATABASE_URL (CI does); without it these tests are skipped.
@Tags(['db'])
library;

import 'package:esquinita_server/auth/auth_service.dart';
import 'package:esquinita_server/auth/bootstrap.dart';
import 'package:esquinita_server/auth/jwt.dart';
import 'package:esquinita_server/db.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../support/schema.dart';

const _device = '019a9a00-0000-7000-8000-0000000000d1';

const _env = {
  'ADMIN_INITIAL_PASSWORD': 'admin-inicial-1',
  'ADMIN_INITIAL_PIN': '1234',
  'STAFF_INITIAL_PASSWORD': 'trabajo-inicial-1',
  'STAFF_INITIAL_PIN': '567890',
};

void main() {
  final url = testDatabaseUrl;
  if (url == null) {
    test('auth against PostgreSQL', () {}, skip: 'set TEST_DATABASE_URL');
    return;
  }

  late Pool<void> db;
  late AuthService auth;
  var now = DateTime.utc(2026, 11, 19, 12);

  setUpAll(() async {
    db = openPool(url);
    await resetSchema(db);
  });

  setUp(() {
    now = DateTime.utc(2026, 11, 19, 12);
    // A new service per test: the in-memory failure counter starts empty.
    auth = AuthService(
      db,
      Jwt(
        'test-secret-with-at-least-32-characters!',
        ttl: const Duration(minutes: 15),
        clock: () => now,
      ),
      refreshTtl: const Duration(days: 30),
      clock: () => now,
    );
  });

  tearDownAll(() => db.close());

  Future<Tokens> login(String user, String password) async {
    final r = await auth.login(user, password, _device);
    expect(r.failure, isNull, reason: '$user should log in');
    return r.tokens!;
  }

  Future<void> setActive(String username, {required bool active}) => db.execute(
    Sql.named('update users set active = @a:boolean where username = @u'),
    parameters: {'a': active, 'u': username},
  );

  group('first users', () {
    test('need every value in .env, with valid PINs', () async {
      for (final missing in _env.keys) {
        expect(
          () => bootstrapUsers(db, {..._env}..remove(missing)),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains(missing),
            ),
          ),
        );
      }
      expect(
        () => bootstrapUsers(db, {..._env, 'ADMIN_INITIAL_PIN': '12'}),
        throwsStateError,
      );
      expect((await db.execute('select count(*) from users')).single[0], 0);
    });

    test(
      'creates Administrador and Trabajo once, hashed, with their roles',
      () async {
        expect(await bootstrapUsers(db, _env), isTrue);
        expect(await bootstrapUsers(db, _env), isFalse);
        final rows = await db.execute(r'''
        select u.username, r.code, u.must_change_password,
               u.password_hash like '$argon2id$%', u.pin_hash like '$argon2id$%',
               u.password_hash <> 'admin-inicial-1'
        from users u join user_roles ur on ur.user_id = u.id
        join roles r on r.id = ur.role_id order by u.username''');
        expect(rows.map((r) => r.toList()), [
          ['Administrador', 'admin', true, true, true, true],
          ['Trabajo', 'staff', true, true, true, true],
        ]);
      },
    );
  });

  group('login', () {
    test(
      'right password: tokens, permissions by role, must change it',
      () async {
        final r = await auth.login('administrador', 'admin-inicial-1', _device);
        expect(r.mustChangePassword, isTrue); // username ignores case
        final admin = await auth.authenticate(r.tokens!.accessToken);
        expect(admin!.permissions, hasLength(34));
        expect(admin.deviceId, _device);
        final staff = await auth.authenticate(
          (await login('Trabajo', 'trabajo-inicial-1')).accessToken,
        );
        expect(staff!.permissions, hasLength(19));
        expect(staff.can('sales.create'), isTrue);
        expect(staff.can('users.manage'), isFalse);
      },
    );

    test('a login bumps the user version, so the device pulls its PIN '
        'hash (ADR-0004)', () async {
      Future<List<Object?>> state() async => (await db.execute(
        "select version, last_login_at from users where username = 'Trabajo'",
      )).single;
      final before = await state();
      await login('Trabajo', 'trabajo-inicial-1');
      final after = await state();
      expect(after[0]! as int, greaterThan(before[0]! as int));
      expect(after[1], now);
      await auth.login('Trabajo', 'mal', _device);
      expect((await state())[0], after[0], reason: 'a failure bumps nothing');
    });

    test('wrong password and unknown user get the same answer', () async {
      for (final (u, p) in [
        ('Administrador', 'otra-clave'),
        ('Nadie', 'admin-inicial-1'),
      ]) {
        final r = await auth.login(u, p, _device);
        expect(r.failure, LoginFailure.invalidCredentials, reason: u);
        expect(r.tokens, isNull);
      }
    });

    test('5 failures lock the username for 15 minutes', () async {
      for (var i = 0; i < AuthService.maxFailures; i++) {
        await auth.login('Trabajo', 'mal', _device);
      }
      final locked = await auth.login('Trabajo', 'trabajo-inicial-1', _device);
      expect(locked.failure, LoginFailure.locked);
      now = now.add(AuthService.lockWindow);
      await login('Trabajo', 'trabajo-inicial-1');
    });

    test('an access token expires after 15 minutes', () async {
      final t = await login('Trabajo', 'trabajo-inicial-1');
      now = now.add(const Duration(minutes: 15));
      expect(await auth.authenticate(t.accessToken), isNull);
    });
  });

  group('sessions', () {
    test(
      'refresh rotates; reusing an old token revokes the whole login',
      () async {
        final first = await login('Trabajo', 'trabajo-inicial-1');
        final second = await auth.refresh(first.refreshToken);
        expect(second, isNotNull);
        expect(second!.refreshToken, isNot(first.refreshToken));
        expect(await auth.authenticate(second.accessToken), isNotNull);
        expect(await auth.refresh(first.refreshToken), isNull); // copied token
        expect(await auth.refresh(second.refreshToken), isNull); // family gone
      },
    );

    test('a refresh token expires after 30 days', () async {
      final t = await login('Trabajo', 'trabajo-inicial-1');
      now = now.add(const Duration(days: 30));
      expect(await auth.refresh(t.refreshToken), isNull);
    });

    test('logout ends the login; unknown tokens are ignored', () async {
      final t = await login('Trabajo', 'trabajo-inicial-1');
      await auth.logout(t.refreshToken);
      await auth.logout('not-a-token');
      expect(await auth.refresh(t.refreshToken), isNull);
    });

    test('a deactivated user loses access at once', () async {
      final t = await login('Trabajo', 'trabajo-inicial-1');
      await setActive('Trabajo', active: false);
      expect(await auth.authenticate(t.accessToken), isNull);
      expect(await auth.refresh(t.refreshToken), isNull);
      final r = await auth.login('Trabajo', 'trabajo-inicial-1', _device);
      expect(r.failure, LoginFailure.invalidCredentials);
      await setActive('Trabajo', active: true);
    });

    test('a device taken out of service is refused at once (DeviceBlocked, '
        'not a dead session); an unregistered device still logs in (it '
        'registers after)', () async {
      const other = '019a9a00-0000-7000-8000-0000000000d9';
      final r = await auth.login('Trabajo', 'trabajo-inicial-1', other);
      expect(r.failure, isNull, reason: 'not registered yet');
      await db.execute(
        Sql.named('''
          insert into devices (id, name, platform, series_prefix,
                               barcode_digit, active, version)
          values (@d:uuid, 'Perdido', 'android', 'T9', 9, false, 0)'''),
        parameters: {'d': other},
      );
      expect(
        () => auth.authenticate(r.tokens!.accessToken),
        throwsA(isA<DeviceBlocked>()),
      );
      expect(
        () => auth.refresh(r.tokens!.refreshToken),
        throwsA(isA<DeviceBlocked>()),
      );
      final again = await auth.login('Trabajo', 'trabajo-inicial-1', other);
      expect(again.failure, LoginFailure.deviceBlocked);
      final wrong = await auth.login('Trabajo', 'mal', other);
      expect(
        wrong.failure,
        LoginFailure.invalidCredentials,
        reason: 'says nothing about the device without the password',
      );
      // Back in service: the same refresh token still works (not rotated).
      await db.execute(
        Sql.named('update devices set active = true where id = @d:uuid'),
        parameters: {'d': other},
      );
      expect(await auth.refresh(r.tokens!.refreshToken), isNotNull);
      // Other devices are not affected.
      expect(
        await auth.authenticate(
          (await login('Trabajo', 'trabajo-inicial-1')).accessToken,
        ),
        isNotNull,
      );
    });

    test('the PIN renews a lost session, only where the user already '
        'logged in with the password (ADR-0005)', () async {
      const tablet = '019a9a00-0000-7000-8000-0000000000d8';
      const fresh = '019a9a00-0000-7000-8000-0000000000d7';
      for (final (id, series, digit) in [(tablet, 'T8', 8), (fresh, 'T7', 7)]) {
        await db.execute(
          Sql.named('''
            insert into devices (id, name, platform, series_prefix,
                                 barcode_digit, version)
            values (@d:uuid, 'Tablet', 'android', @s:text, @g:int4, 0)'''),
          parameters: {'d': id, 's': series, 'g': digit},
        );
      }
      final staffId =
          (await db.execute(
                "select id from users where username = 'Trabajo'",
              )).single[0]!
              as String;
      // A user who must change the password needs the password.
      expect(
        (await auth.loginWithPin(staffId, '567890', fresh)).failure,
        LoginFailure.invalidCredentials,
      );
      await db.execute(
        'update users set must_change_password = false '
        "where username = 'Trabajo'",
      );
      // Never logged in on [fresh]: the PIN alone opens nothing there.
      expect(
        (await auth.loginWithPin(staffId, '567890', fresh)).failure,
        LoginFailure.invalidCredentials,
      );
      final first = (await auth.login(
        'Trabajo',
        'trabajo-inicial-1',
        tablet,
      )).tokens!;
      await auth.logout(first.refreshToken); // the session is lost
      expect(
        (await auth.loginWithPin(staffId, '0000', tablet)).failure,
        LoginFailure.invalidCredentials,
      );
      final r = await auth.loginWithPin(staffId, '567890', tablet);
      expect(r.failure, isNull);
      final user = await auth.authenticate(r.tokens!.accessToken);
      expect((user!.userId, user.deviceId), (staffId, tablet));
      expect(await auth.refresh(r.tokens!.refreshToken), isNotNull);

      // Out of service: refused, but only after the right PIN.
      await db.execute(
        Sql.named('update devices set active = false where id = @d:uuid'),
        parameters: {'d': tablet},
      );
      expect(
        (await auth.loginWithPin(staffId, '567890', tablet)).failure,
        LoginFailure.deviceBlocked,
      );
    });

    test('wrong PINs count with wrong passwords: 5 lock the user', () async {
      const tablet = '019a9a00-0000-7000-8000-0000000000d8';
      await db.execute(
        Sql.named('update devices set active = true where id = @d:uuid'),
        parameters: {'d': tablet},
      );
      final staffId =
          (await db.execute(
                "select id from users where username = 'Trabajo'",
              )).single[0]!
              as String;
      for (var i = 0; i < 3; i++) {
        await auth.loginWithPin(staffId, '0000', tablet);
      }
      await auth.login('Trabajo', 'mal', _device);
      await auth.login('Trabajo', 'mal', _device);
      expect(
        (await auth.loginWithPin(staffId, '567890', tablet)).failure,
        LoginFailure.locked,
      );
      expect(
        (await auth.login('Trabajo', 'trabajo-inicial-1', _device)).failure,
        LoginFailure.locked,
      );
      // Back as the seed left it, for the tests after this one.
      await db.execute(
        'update users set must_change_password = true '
        "where username = 'Trabajo'",
      );
    });

    test('/me has roles and permissions, never a hash', () async {
      final user = await auth.authenticate(
        (await login('Trabajo', 'trabajo-inicial-1')).accessToken,
      );
      final me = await auth.me(user!);
      expect(me['user'], {
        'id': user.userId,
        'username': 'Trabajo',
        'full_name': 'Trabajo',
        'must_change_password': true,
      });
      expect(me['roles'], [
        {'code': 'staff', 'name': 'Trabajo', 'home_view': 'sales'},
      ]);
      expect(me['permissions'], hasLength(19));
      expect(me.toString(), isNot(contains(r'$argon2id')));
    });
  });

  group('password change', () {
    test('checks the current one and the new one', () async {
      final user = await auth.authenticate(
        (await login('Administrador', 'admin-inicial-1')).accessToken,
      );
      expect(
        await auth.changePassword(user!, 'mal', 'nueva-clave-1'),
        PasswordChange.wrongPassword,
      );
      expect(
        await auth.changePassword(user, 'admin-inicial-1', 'corta'),
        PasswordChange.tooShort,
      );
      expect(
        await auth.changePassword(user, 'admin-inicial-1', 'admin-inicial-1'),
        PasswordChange.sameAsBefore,
      );
    });

    test(
      'saves it, clears the first-login flag and ends every login',
      () async {
        final t = await login('Administrador', 'admin-inicial-1');
        final user = await auth.authenticate(t.accessToken);
        expect(
          await auth.changePassword(user!, 'admin-inicial-1', 'nueva-clave-1'),
          PasswordChange.changed,
        );
        expect(await auth.refresh(t.refreshToken), isNull);
        final old = await auth.login(
          'Administrador',
          'admin-inicial-1',
          _device,
        );
        expect(old.failure, LoginFailure.invalidCredentials);
        final r = await auth.login('Administrador', 'nueva-clave-1', _device);
        expect(r.mustChangePassword, isFalse);
      },
    );
  });

  test('the database keeps only the SHA-256 of refresh tokens', () async {
    final t = await login('Trabajo', 'trabajo-inicial-1');
    final hits = await db.execute(
      Sql.named('select count(*) from refresh_tokens where token_hash = @t'),
      parameters: {'t': t.refreshToken},
    );
    expect(hits.single[0], 0);
  });
}
