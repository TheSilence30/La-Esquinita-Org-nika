import 'package:drift/native.dart';
import 'package:esquinita_app/data/local/database.dart';
import 'package:esquinita_app/data/sync/server_sync.dart';
import 'package:esquinita_app/features/admin/application/admin_client.dart';
import 'package:esquinita_app/features/auth/application/local_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_server.dart';

// The Administrador screens' use cases against the fake server: the saved
// login's token, a sync round after each change, Spanish refusals.
void main() {
  late AppDatabase db;
  late FakeServer server;
  late AdminClient admin;
  var rounds = 0;
  String? onScreen;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    server = FakeServer(await testHasher.hash('4821'));
    final auth = LocalAuth(
      db: db,
      apiFor: (_) => server,
      verifyPin: verifyPinArgon2,
      platform: 'android',
    );
    await auth.setUpDevice(
      serverUrl: 'http://pc:8080',
      deviceName: 'Tablet caja',
      username: 'Administrador',
      password: 'admin-1234',
    );
    await auth.loginWithPassword('Administrador', 'admin-1234');
    onScreen = adminId;
    rounds = 0;
    admin = AdminClient(
      ServerSync(db: db, apiFor: (_) => server, currentUserId: () => onScreen),
      afterChange: () async => rounds++,
    );
  });

  tearDown(() => db.close());

  Matcher fails(String text) => throwsA(
    isA<AdminFailure>().having((e) => e.message, 'message', contains(text)),
  );

  test('reads users, settings and devices without a sync round', () async {
    expect((await admin.users()).map((u) => (u.username, u.role)), [
      ('Administrador', 'admin'),
      ('Trabajo', 'staff'),
    ]);
    expect((await admin.settings())[TicketSetting.ruc], '10409288419');
    final devices = await admin.devices();
    expect(devices.first.lastSeenAt, DateTime.utc(2026, 11, 25, 17, 46));
    expect(rounds, 0);
  });

  test('each change sends only the given fields and then syncs', () async {
    await admin.createUser(
      username: 'Maria',
      fullName: 'María',
      role: 'staff',
      password: 'inicial-maria',
      pin: '1234',
    );
    await admin.updateUser(staffId, active: false);
    await admin.saveSettings({TicketSetting.phone: null});
    await admin.setDeviceActive('d-tablet', active: false);
    expect(server.requests.map((r) => [r.$1, r.$2, r.$3]), [
      [
        'POST',
        '/users',
        {
          'username': 'Maria',
          'full_name': 'María',
          'role': 'staff',
          'password': 'inicial-maria',
          'pin': '1234',
        },
      ],
      [
        'PATCH',
        '/users/$staffId',
        {'active': false},
      ],
      [
        'PATCH',
        '/settings',
        {TicketSetting.phone: null},
      ],
      [
        'PATCH',
        '/devices/d-tablet',
        {'active': false},
      ],
    ]);
    expect(rounds, 4);
  });

  test('refusals in Spanish; a refused change does not sync', () async {
    await expectLater(
      admin.createUser(
        username: 'trabajo',
        fullName: 'Otro',
        role: 'staff',
        password: 'inicial-otro',
        pin: '1234',
      ),
      fails('ya existe'),
    );
    await expectLater(
      admin.updateUser(adminId, active: false),
      fails('No puedes desactivarte'),
    );
    await expectLater(admin.setPin('u-nadie', '1234'), fails('Ya no existe'));
    server.offline = true;
    await expectLater(admin.users(), fails('necesitan conexión'));
    expect(rounds, 0);
  });

  test('Trabajo is refused; without a login it asks for the PIN', () async {
    // Trabajo must change the initial password before getting a session.
    server.users['Trabajo']!.mustChange = false;
    await LocalAuth(
      db: db,
      apiFor: (_) => server,
      verifyPin: verifyPinArgon2,
      platform: 'android',
    ).loginWithPassword('Trabajo', 'trabajo-1234');
    onScreen = staffId;
    await expectLater(admin.users(), fails('Solo un Administrador'));
    onScreen = null;
    await expectLater(admin.users(), fails('escribe tu PIN'));
  });
}
