import 'dart:convert';

import 'package:esquinita_app/app/theme.dart';
import 'package:esquinita_app/features/auth/application/admin_check.dart';
import 'package:esquinita_app/features/auth/widgets/key_lost_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('checkAdministrator', () {
    var loggedOut = false;

    MockClient server({int login = 200, List<String> perms = const []}) =>
        MockClient((r) async {
          switch (r.url.path) {
            case '/auth/login':
              final body = jsonDecode(r.body) as Map;
              expect(body['username'], 'Administrador');
              return http.Response(
                jsonEncode({'access_token': 'a', 'refresh_token': 'r'}),
                login,
              );
            case '/me':
              expect(r.headers['authorization'], 'Bearer a');
              return http.Response(jsonEncode({'permissions': perms}), 200);
            case '/auth/logout':
              loggedOut = true;
              return http.Response('', 204);
          }
          return http.Response('', 404);
        });

    Future<AdminCheck> check(MockClient c) => checkAdministrator(
      serverUrl: 'http://pc:8080/',
      username: 'Administrador',
      password: 'x',
      client: c,
    );

    setUp(() => loggedOut = false);

    test('settings.manage confirms, and the session is closed', () async {
      expect(
        await check(server(perms: ['settings.manage'])),
        AdminCheck.confirmed,
      );
      expect(loggedOut, isTrue);
    });

    test('Trabajo is not enough', () async {
      expect(
        await check(server(perms: ['sales.create'])),
        AdminCheck.notAdministrator,
      );
      expect(loggedOut, isTrue);
    });

    test('wrong password or locked; no server', () async {
      expect(await check(server(login: 401)), AdminCheck.wrongCredentials);
      expect(await check(server(login: 429)), AdminCheck.wrongCredentials);
      expect(await check(server(login: 500)), AdminCheck.offline);
      expect(
        await check(MockClient((_) => throw http.ClientException('no'))),
        AdminCheck.offline,
      );
    });
  });

  group('KeyLostPage', () {
    late int discards;

    Future<void> pump(WidgetTester tester, AdminCheck answer) async {
      discards = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: KeyLostPage(
            reason: 'Hay una base local, pero no su llave.',
            onDiscard: () async => discards++,
            check: (_, _, _) async => answer,
          ),
        ),
      );
    }

    Future<void> tapDiscard(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField).last, 'clave');
      await tester.tap(find.text('Descartar la base local'));
      await tester.pumpAndSettle();
    }

    testWidgets('says why and that nothing was deleted', (tester) async {
      await pump(tester, AdminCheck.confirmed);
      expect(
        find.text('Hay una base local, pero no su llave.'),
        findsOneWidget,
      );
      expect(find.textContaining('No se borró nada'), findsOneWidget);
      expect(discards, 0);
    });

    testWidgets('without an Administrador, nothing is discarded', (
      tester,
    ) async {
      for (final (answer, message) in [
        (AdminCheck.wrongCredentials, 'Usuario o contraseña incorrectos.'),
        (AdminCheck.notAdministrator, 'Ese usuario no es Administrador.'),
        (AdminCheck.offline, 'Sin conexión'),
      ]) {
        await pump(tester, answer);
        await tapDiscard(tester);
        expect(find.textContaining(message), findsOneWidget);
        expect(find.text('¿Descartar la base local?'), findsNothing);
        expect(discards, 0);
      }
    });

    testWidgets('a confirmed Administrador still has to say yes', (
      tester,
    ) async {
      await pump(tester, AdminCheck.confirmed);
      await tapDiscard(tester);
      expect(find.text('¿Descartar la base local?'), findsOneWidget);
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      expect(discards, 0);

      await tapDiscard(tester);
      await tester.tap(find.text('Sí, descartar'));
      await tester.pumpAndSettle();
      expect(discards, 1);
    });
  });
}
