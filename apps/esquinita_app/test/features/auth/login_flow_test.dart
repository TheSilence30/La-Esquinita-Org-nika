import 'package:drift/native.dart';
import 'package:esquinita_app/app/providers.dart';
import 'package:esquinita_app/data/local/database.dart';
import 'package:esquinita_app/features/auth/application/auth_providers.dart';
import 'package:esquinita_app/features/auth/application/local_auth.dart';
import 'package:esquinita_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_server.dart';

// End to end through the real screens: first start → password → forced
// change → app → "Cambiar usuario" → PIN. Fake server, in-memory database.
void main() {
  testWidgets('register, log in, change the initial password, then the PIN', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1340, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final pinHash = (await tester.runAsync(() => testHasher.hash('4821')))!;
    final server = FakeServer(pinHash);
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        localAuthProvider.overrideWithValue(
          LocalAuth(
            db: db,
            apiFor: (_) => server,
            verifyPin: verifyPinArgon2,
            platform: 'android',
          ),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await tester.runAsync(db.close);
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AuthGate()),
    );

    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
      }
    }

    Future<void> type(String label, String text) =>
        tester.enterText(find.widgetWithText(TextField, label), text);

    Future<void> tap(String text) async {
      await tester.tap(find.text(text).last);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      await settle();
    }

    // First start.
    await settle();
    expect(find.text('Registrar este equipo'), findsOneWidget);
    await type('Dirección del servidor', 'http://pc:8080');
    await type('Nombre del equipo', 'Tablet caja');
    await type('Contraseña', 'admin-1234');
    await tap('Registrar equipo');
    expect(server.registered, [('Tablet caja', 'android')]);

    // Every user is listed; nobody has a saved login yet, so tapping a name
    // asks only for the password (no username to type).
    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Administrador'), findsOne);
    await tap('Trabajo');
    expect(
      find.text(
        'Entra una vez con tu contraseña. Necesita conexión con el servidor.',
      ),
      findsOne,
    );
    expect(find.widgetWithText(TextField, 'Usuario'), findsNothing);
    await type('Contraseña', 'trabajo-1234');
    await tap('Entrar');

    // Forced change of the initial password.
    expect(find.text('Elige tu contraseña'), findsOneWidget);
    await type('Nueva contraseña', 'nueva-clave-1');
    await type('Repite la contraseña', 'otra-clave-1');
    await tap('Guardar y entrar');
    expect(find.text('Las dos contraseñas no coinciden.'), findsOneWidget);
    await type('Repite la contraseña', 'nueva-clave-1');
    // The device clock is 1 h ahead of the server: warned inside the app.
    server.serverTime = DateTime.now().subtract(const Duration(hours: 1));
    await tap('Guardar y entrar');
    expect(server.users['Trabajo']!.password, 'nueva-clave-1');
    expect(container.read(currentSessionProvider)?.userId, staffId);
    expect(find.byType(EsquinitaApp), findsOneWidget);
    expect(find.text(LocalAuth.clockMismatch), findsOneWidget);

    // "Cambiar usuario", then back in with the PIN, wrong once.
    container.read(currentSessionProvider.notifier).lock();
    await settle();
    await tap('Trabajo');
    await type('PIN', '1111');
    await tap('Entrar');
    expect(find.text('PIN incorrecto. Te quedan 4 intentos.'), findsOneWidget);
    await type('PIN', '4821');
    await tap('Entrar');
    expect(container.read(currentSessionProvider)?.userId, staffId);
    expect(find.byType(EsquinitaApp), findsOneWidget);

    // With a saved login, the password is still one tap away (for when the
    // sync indicator asks for it), without typing the username.
    container.read(currentSessionProvider.notifier).lock();
    await settle();
    await tap('Trabajo');
    await tap('Entrar con contraseña');
    expect(find.widgetWithText(TextField, 'Usuario'), findsNothing);
    await type('Contraseña', 'nueva-clave-1');
    await tap('Entrar');
    expect(container.read(currentSessionProvider)?.userId, staffId);
  });
}
