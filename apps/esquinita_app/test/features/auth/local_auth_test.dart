import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:esquinita_app/data/local/database.dart';
import 'package:esquinita_app/features/auth/application/local_auth.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_server.dart';

void main() {
  late AppDatabase db;
  late FakeServer server;
  late DateTime now;
  late String pinHash;
  var crashOnVerify = false;

  setUpAll(() async => pinHash = await testHasher.hash('4821'));

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    server = FakeServer(pinHash);
    now = DateTime.utc(2026, 11, 20, 9);
    crashOnVerify = false;
  });

  tearDown(() => db.close());

  /// A new instance is what the app gets after a restart: nothing in memory.
  LocalAuth auth() => LocalAuth(
    db: db,
    apiFor: (url) {
      expect(url, 'http://pc:8080');
      return server;
    },
    verifyPin: (pin, hash) {
      if (crashOnVerify) throw StateError('app closed');
      return verifyPinArgon2(pin, hash);
    },
    platform: 'android',
    clock: () => now,
  );

  Future<void> setUp_() => auth().setUpDevice(
    serverUrl: 'http://pc:8080',
    deviceName: 'Tablet caja',
    username: 'Administrador',
    password: 'admin-1234',
  );

  Future<AppSession> adminLogin() async => ((await auth().loginWithPassword(
    'Administrador',
    'admin-1234',
  )) as LoggedIn).session;

  Future<int> failedPins(String userId) async => (await (db.select(
    db.localSessions,
  )..where((s) => s.userId.equals(userId))).getSingle()).failedPins;

  group('first start', () {
    test('an Administrador registers the device; masters are pulled; that '
        'login is closed and leaves no saved login', () async {
      expect(await auth().isRegistered(), isFalse);
      await setUp_();
      expect(await auth().isRegistered(), isTrue);
      expect(server.registered, [('Tablet caja', 'android')]);
      expect(server.loggedOut, hasLength(1));
      expect(await db.select(db.users).get(), hasLength(2));
      expect(await db.select(db.localSessions).get(), isEmpty);
    });

    test('wrong password, Trabajo, or no server: not registered', () async {
      for (final (user, password, offline, message) in [
        ('Administrador', 'mal', false, 'incorrectos'),
        ('Trabajo', 'trabajo-1234', false, 'Solo un Administrador'),
        ('Administrador', 'admin-1234', true, 'Sin conexión'),
      ]) {
        server.offline = offline;
        await expectLater(
          auth().setUpDevice(
            serverUrl: 'http://pc:8080',
            deviceName: 'Tablet caja',
            username: user,
            password: password,
          ),
          throwsA(
            isA<SetupException>().having(
              (e) => e.message,
              'm',
              contains(message),
            ),
          ),
        );
        expect(await auth().isRegistered(), isFalse);
      }
    });
  });

  group('password login', () {
    setUp(setUp_);

    test('opens the session with the role home and the permissions from '
        'the replicas, and saves the login for the PIN', () async {
      final s = await adminLogin();
      expect(s.userId, adminId);
      expect(s.homeView, 'dashboard');
      expect(s.permissions, {Permissions.usersManage, Permissions.salesCreate});
      final saved = await db.select(db.localSessions).getSingle();
      expect(saved.passwordLoginAt.isAtSameMomentAs(now), isTrue);
      expect(saved.refreshToken, startsWith('r-$adminId'));
      expect(server.logins.toSet(), hasLength(1), reason: 'same device id');
    });

    test('first login: the initial password must be changed first', () async {
      final first = await auth().loginWithPassword('Trabajo', 'trabajo-1234');
      expect(first, isA<NeedsNewPassword>());
      expect(await db.select(db.localSessions).get(), isEmpty);
      await expectLater(
        auth().loginWithNewPassword('Trabajo', 'trabajo-1234', 'corta'),
        throwsA(isA<SetupException>()),
      );
      final s = await auth().loginWithNewPassword(
        'Trabajo',
        'trabajo-1234',
        'nueva-clave-9',
      );
      expect(s.homeView, 'sales');
      expect(s.can(Permissions.usersManage), isFalse);
      expect(server.users['Trabajo']!.password, 'nueva-clave-9');
    });

    Future<String?> lastSeen() async => (await (db.select(
      db.localSettings,
    )..where((s) => s.key.equals('last_seen_at'))).getSingleOrNull())?.value;

    test('the server time, not the device clock, starts the 7 days and '
        'sets the time seen; 4 min off gives no warning', () async {
      server.serverTime = now.add(const Duration(minutes: 4));
      final s = await adminLogin();
      expect(s.clockWarning, isNull);
      final saved = await db.select(db.localSessions).getSingle();
      expect(
        saved.passwordLoginAt.isAtSameMomentAs(server.serverTime!),
        isTrue,
      );
      expect(await lastSeen(), '${server.serverTime!.millisecondsSinceEpoch}');
    });

    test('a device clock more than 5 min off the server warns, and a clock '
        'behind then blocks the PIN', () async {
      for (final off in [
        const Duration(minutes: 6),
        -const Duration(hours: 3),
      ]) {
        server.serverTime = now.add(off);
        final s = await adminLogin();
        expect(s.clockWarning, LocalAuth.clockMismatch);
        expect(
          (await db.select(db.localSessions).getSingle()).passwordLoginAt
              .isAtSameMomentAs(server.serverTime!),
          isTrue,
        );
      }
      // The device is 3 h ahead of the server now: the PIN still works.
      server.offline = true;
      expect(await auth().loginWithPin(adminId, '4821'), isA<PinOk>());
      server
        ..offline = false
        ..serverTime = now.add(const Duration(minutes: 6));
      await adminLogin(); // device 6 min behind the server
      server.offline = true;
      final r = await auth().loginWithPin(adminId, '4821');
      expect((r as PinNeedsPassword).reason, contains('hora'));
    });

    test('offline: says to use the PIN', () async {
      server.offline = true;
      await expectLater(
        auth().loginWithPassword('Administrador', 'admin-1234'),
        throwsA(
          isA<SetupException>().having((e) => e.message, 'm', contains('PIN')),
        ),
      );
    });
  });

  group('PIN, offline', () {
    setUp(() async {
      await setUp_();
      await adminLogin();
      server.offline = true;
    });

    test('the right PIN opens the session without the server', () async {
      final users = {for (final u in await auth().loginUsers()) u.userId: u};
      expect(users[adminId]!.blockedReason, isNull);
      // Listed too, but without a login here it needs the password.
      expect(users[staffId]!.blockedReason, contains('contraseña'));
      final r = await auth().loginWithPin(adminId, '4821');
      expect((r as PinOk).session.homeView, 'dashboard');
    });

    test('wrong PINs count down; the count survives a restart; 5 require '
        'the password, even with the right PIN after that', () async {
      for (var left = 4; left >= 1; left--) {
        final r = await auth().loginWithPin(adminId, '0000'); // new instance
        expect((r as WrongPin).attemptsLeft, left);
      }
      expect(await failedPins(adminId), 4);
      expect(
        await auth().loginWithPin(adminId, '0000'),
        isA<PinNeedsPassword>(),
      );
      expect(
        await auth().loginWithPin(adminId, '4821'),
        isA<PinNeedsPassword>(),
      );
      expect(
        (await auth().loginUsers())
            .firstWhere((u) => u.userId == adminId)
            .blockedReason,
        contains('5 veces'),
      );

      server.offline = false;
      await adminLogin(); // the password resets the count
      expect(await failedPins(adminId), 0);
      expect(await auth().loginWithPin(adminId, '4821'), isA<PinOk>());
    });

    test('the right PIN resets the count', () async {
      await auth().loginWithPin(adminId, '0000');
      await auth().loginWithPin(adminId, '0000');
      expect(await auth().loginWithPin(adminId, '4821'), isA<PinOk>());
      expect(await failedPins(adminId), 0);
    });

    test('the attempt is counted before checking: closing the app during '
        'the check gives no free attempt', () async {
      crashOnVerify = true;
      await expectLater(auth().loginWithPin(adminId, '0000'), throwsStateError);
      expect(await failedPins(adminId), 1);
    });

    test('7 days after the password login the PIN stops working', () async {
      now = now.add(const Duration(days: 7) - const Duration(minutes: 1));
      expect(await auth().loginWithPin(adminId, '4821'), isA<PinOk>());
      now = now.add(const Duration(minutes: 1));
      final r = await auth().loginWithPin(adminId, '4821');
      expect((r as PinNeedsPassword).reason, contains('7 días'));
      expect(await failedPins(adminId), 0, reason: 'not counted as a failure');
    });

    test('a clock set back before the login is not trusted', () async {
      now = now.subtract(const Duration(minutes: 4));
      expect(await auth().loginWithPin(adminId, '4821'), isA<PinOk>());
      now = now.subtract(const Duration(days: 1));
      expect(
        await auth().loginWithPin(adminId, '4821'),
        isA<PinNeedsPassword>(),
      );
    });

    test('a clock set back more than 5 min from the latest time seen blocks '
        'the PIN; 4 min does not; the time seen survives a restart and '
        'never goes down', () async {
      now = DateTime.utc(2026, 11, 22, 12);
      await auth().loginUsers(); // the app opens at 12:00
      now = DateTime.utc(2026, 11, 22, 11, 30);
      await auth().markTimeSeen(); // an earlier time does not lower it
      expect(
        await db.select(db.localSettings).get(),
        contains(
          isA<LocalSetting>()
              .having((s) => s.key, 'key', 'last_seen_at')
              .having(
                (s) => s.value,
                'value',
                '${DateTime.utc(2026, 11, 22, 12).millisecondsSinceEpoch}',
              ),
        ),
      );

      now = DateTime.utc(2026, 11, 22, 11, 56); // 4 min behind
      expect(await auth().loginWithPin(adminId, '4821'), isA<PinOk>());

      now = DateTime.utc(2026, 11, 22, 11, 54); // 6 min behind, new instance
      final r = await auth().loginWithPin(adminId, '4821');
      expect((r as PinNeedsPassword).reason, contains('hora'));
      expect(await failedPins(adminId), 0, reason: 'not counted as a failure');
      expect(
        (await auth().loginUsers())
            .firstWhere((u) => u.userId == adminId)
            .blockedReason,
        contains('hora'),
      );
    });

    test('a password login trusts the clock again: a clock once set '
        'forward does not block the PIN for good', () async {
      now = DateTime.utc(2030);
      await auth().markTimeSeen();
      now = DateTime.utc(2026, 11, 22, 12);
      expect(
        await auth().loginWithPin(adminId, '4821'),
        isA<PinNeedsPassword>(),
      );
      server.offline = false;
      await adminLogin();
      expect(await auth().loginWithPin(adminId, '4821'), isA<PinOk>());
    });

    test('a deactivated user (after a pull) or one without a login here '
        'cannot use the PIN', () async {
      expect(
        await auth().loginWithPin(staffId, '4821'),
        isA<PinNeedsPassword>(),
      );
      await (db.update(db.users)..where((u) => u.id.equals(adminId))).write(
        const UsersCompanion(active: Value(false)),
      );
      final r = await auth().loginWithPin(adminId, '4821');
      expect((r as PinNeedsPassword).reason, contains('desactivado'));
      expect(
        (await auth().loginUsers()).map((u) => u.userId),
        isNot(contains(adminId)),
        reason: 'not offered on the login screen',
      );
    });

    test('logout forgets the saved login, also offline', () async {
      await auth().logout(adminId);
      expect(await db.select(db.localSessions).get(), isEmpty);
      expect(
        await auth().loginWithPin(adminId, '4821'),
        isA<PinNeedsPassword>(),
      );
    });
  });

  test('logout online also ends the login on the server', () async {
    await setUp_();
    final s = await adminLogin();
    await auth().logout(s.userId);
    expect(server.loggedOut.last, startsWith('r-$adminId'));
  });
}
