import 'package:drift/native.dart';
import 'package:esquinita_app/app/providers.dart';
import 'package:esquinita_app/data/local/database.dart';
import 'package:esquinita_app/data/sync/server_sync.dart';
import 'package:esquinita_app/features/admin/application/admin_client.dart';
import 'package:esquinita_app/features/admin/application/admin_providers.dart';
import 'package:esquinita_app/features/admin/widgets/admin_page.dart';
import 'package:esquinita_app/features/auth/application/auth_providers.dart';
import 'package:esquinita_app/features/auth/application/local_auth.dart';
import 'package:esquinita_app/prototype/widgets/notice.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_server.dart';

// The Ajustes page (Negocio, Usuarios, Equipos) against the fake server.
void main() {
  late AppDatabase db;
  late FakeServer server;
  late ProviderContainer container;

  Future<void> start(
    WidgetTester tester, {
    Set<String> permissions = const {
      Permissions.usersManage,
      Permissions.settingsManage,
    },
    Size size = const Size(1280, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
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
    });
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        adminClientProvider.overrideWithValue(
          AdminClient(
            ServerSync(
              db: db,
              apiFor: (_) => server,
              currentUserId: () => adminId,
            ),
            afterChange: () async {},
          ),
        ),
      ],
    );
    container
        .read(currentSessionProvider.notifier)
        .open(
          AppSession(
            userId: adminId,
            username: 'Administrador',
            fullName: 'Administrador',
            permissions: permissions,
            homeView: 'dashboard',
          ),
        );
    addTearDown(() async {
      container.dispose();
      await tester.runAsync(db.close);
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (_, child) => NoticeHost(child: child!),
          home: const Scaffold(body: AdminPage()),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('Trabajo sees nothing of it', (tester) async {
    await start(tester, permissions: const {Permissions.salesCreate});
    expect(find.text('Solo un Administrador entra aquí.'), findsOne);
    expect(server.requests, isEmpty);
  });

  testWidgets('Negocio: a wrong RUC is not sent; only the changed field '
      'is', (tester) async {
    await start(tester);
    expect(find.text('Negocio'), findsOne);
    expect(find.text('Usuarios'), findsOne);
    expect(find.text('Equipos'), findsOne);
    final ruc = find.byKey(const Key('setting-${TicketSetting.ruc}'));
    expect(
      find.descendant(of: ruc, matching: find.text('10409288419')),
      findsOne,
    );

    await tester.enterText(ruc, '10409288418');
    await tap(tester, find.text('Guardar'));
    expect(find.textContaining('RUC no válido'), findsOne);
    expect(server.requests.where((r) => r.$1 == 'PATCH'), isEmpty);

    await tester.enterText(ruc, '10409288419');
    await tester.enterText(
      find.byKey(const Key('setting-${TicketSetting.phone}')),
      '987 654 321',
    );
    await tap(tester, find.text('Guardar'));
    expect(server.requests.where((r) => r.$1 == 'PATCH').single.$3, {
      TicketSetting.phone: '987 654 321',
    });
    expect(find.text('Datos del negocio guardados.'), findsOne);
  });

  testWidgets('Equipos: "Dar de baja" asks first, then shows "Reactivar"', (
    tester,
  ) async {
    await start(tester);
    await tap(tester, find.text('Equipos'));
    expect(
      find.textContaining('Última conexión: 25/11/2026 12:46'),
      findsWidgets,
    );
    final pc = find.byKey(const Key('device-P1'));
    await tap(
      tester,
      find.descendant(of: pc, matching: find.text('Dar de baja')),
    );
    expect(find.text('¿Dar de baja «PC caja»?'), findsOne);
    await tap(tester, find.widgetWithText(FilledButton, 'Dar de baja'));
    expect(server.devices['d-pc'], isFalse);
    // Hidden by default; the switch shows it again, with "Reactivar".
    expect(pc, findsNothing);
    await tap(tester, find.text('Mostrar desactivados (1)'));
    expect(find.descendant(of: pc, matching: find.text('Reactivar')), findsOne);
  });

  testWidgets('Equipos: a tap renames the device', (tester) async {
    await start(tester);
    await tap(tester, find.text('Equipos'));
    await tap(tester, find.byKey(const Key('device-T1')));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      'Tablet caja 2',
    );
    await tap(tester, find.text('Guardar'));
    expect(server.deviceNames['d-tablet'], 'Tablet caja 2');
    expect(find.textContaining('Tablet caja 2'), findsOne);
  });

  testWidgets('Usuarios on a phone: create one; the PIN is checked first', (
    tester,
  ) async {
    await start(tester, size: const Size(360, 740));
    await tap(tester, find.text('Usuarios'));
    expect(find.text('Administrador (tú)'), findsOne);
    await tap(tester, find.text('Nuevo usuario'));
    final dialog = find.byType(AlertDialog);
    Finder field(String label) => find.descendant(
      of: dialog,
      matching: find.widgetWithText(TextFormField, label),
    );
    await tester.enterText(field('Nombre completo'), 'María Pérez');
    await tester.enterText(field('Usuario'), 'Maria');
    await tester.enterText(field('Contraseña temporal'), 'inicial-maria');
    await tester.enterText(field('PIN (4 a 6 dígitos)'), '12');
    await tap(tester, find.text('Crear'));
    expect(find.text('De 4 a 6 dígitos.'), findsOne);
    expect(server.requests.where((r) => r.$1 == 'POST'), isEmpty);

    await tester.enterText(field('PIN (4 a 6 dígitos)'), '1234');
    await tap(tester, find.text('Crear'));
    expect(server.requests.where((r) => r.$1 == 'POST').single.$2, '/users');
    expect(server.users['Maria']!.mustChange, isTrue);
    expect(find.byKey(const Key('user-Maria')), findsOne);
  });
}

/// Drift and the fake server run outside the fake clock.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
}

Future<void> tap(WidgetTester tester, Finder f) async {
  await tester.tap(f.last);
  await tester.pump(); // starts the tab/dialog motion
  await tester.pump(const Duration(milliseconds: 400)); // and ends it
  await settle(tester);
}
