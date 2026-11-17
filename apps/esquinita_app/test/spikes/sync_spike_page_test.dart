import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:esquinita_app/app/theme.dart';
import 'package:esquinita_app/data/local/database.dart';
import 'package:esquinita_app/data/sync/outbox_store.dart';
import 'package:esquinita_app/data/sync/sync_client.dart';
import 'package:esquinita_app/spikes/sync_spike_page.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Future<void> finish(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox()); // disposes the scheduler
  final closed = db.close();
  await tester.pump();
  await closed;
}

class _Server implements PushTransport {
  final seen = <String>{};
  bool offline = false;

  @override
  Future<List<PushResult>> push(List<SyncCommand> commands) async {
    if (offline) throw const SyncException('Sin conexión con el servidor.');
    return [
      for (final c in commands)
        seen.add(c.opId)
            ? PushResult(c.opId, PushStatus.applied)
            : PushResult(
                c.opId,
                PushStatus.duplicate,
                originalStatus: PushStatus.applied,
              ),
    ];
  }
}

void main() {
  Future<(AppDatabase, _Server)> pump(WidgetTester tester, Size size) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Everything runs on the fake clock: no runAsync, so drift's futures and
    // the scheduler's timers advance only through pump().
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    final server = _Server();
    final saved = OutboxStore(db).setServerUrl('http://192.168.1.50:8080');
    await tester.pump();
    await saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: SyncSpikePage(db: db, transportFor: (_) => server),
      ),
    );
    await settle(tester);
    return (db, server);
  }

  for (final size in const [Size(893, 533), Size(533, 893), Size(1340, 800)]) {
    testWidgets('lays out without overflow at $size', (tester) async {
      final (db, _) = await pump(tester, size);
      await tester.tap(find.text('Crear 30'));
      await settle(tester);
      expect(tester.takeException(), isNull);
      await finish(tester, db);
    });
  }

  testWidgets('offline: pending count; online: synced, once', (tester) async {
    final (db, server) = await pump(tester, const Size(1340, 800));
    server.offline = true;
    await tester.tap(find.text('Crear operación'));
    await tester.tap(find.text('Crear operación'));
    await settle(tester);
    await tester.tap(find.text('Sincronizar'));
    await settle(tester);
    expect(find.text('Error · pendientes 2'), findsOneWidget);
    expect(
      find.textContaining('Sin conexión con el servidor. Reintento en 5 s.'),
      findsOneWidget,
    );

    server.offline = false;
    await tester.tap(find.text('Sincronizar'));
    await settle(tester);
    expect(find.text('Sincronizado'), findsOneWidget);
    expect(server.seen, hasLength(2));

    await tester.tap(find.text('Reenviar todo'));
    await settle(tester);
    expect(find.textContaining('respuesta: duplicado'), findsNWidgets(2));
    expect(server.seen, hasLength(2));
    await finish(tester, db);
  });
}
