import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:esquinita_app/data/local/database.dart';
import 'package:esquinita_app/data/sync/outbox_store.dart';
import 'package:esquinita_app/data/sync/sync_client.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory server with the real server's idempotency rules (those are
/// tested against PostgreSQL in apps/server).
class FakeServer implements PushTransport {
  final inbox = <String, PushStatus>{};
  int requests = 0;

  /// Answer this many requests, then behave as offline.
  int? onlineFor;

  /// Apply the next request but lose its response.
  bool loseNextResponse = false;

  @override
  Future<List<PushResult>> push(List<SyncCommand> commands) async {
    requests++;
    if (onlineFor case final n? when requests > n) {
      throw const SyncException('Sin conexión con el servidor.');
    }
    final results = [
      for (final c in commands)
        if (inbox[c.opId] case final original?)
          PushResult(c.opId, PushStatus.duplicate, originalStatus: original)
        else
          PushResult(c.opId, inbox[c.opId] = PushStatus.applied),
    ];
    if (loseNextResponse) {
      loseNextResponse = false;
      throw const SyncException('El servidor no respondió a tiempo.');
    }
    return results;
  }
}

SpikeOperation op(int i) => SpikeOperation(note: 'Op $i', amountCents: i);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late OutboxStore store;
  late FakeServer server;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = OutboxStore(db);
    server = FakeServer();
  });

  tearDown(() => db.close());

  Future<Map<String, int>> statuses() async {
    final counts = <String, int>{};
    for (final o in await db.select(db.outbox).get()) {
      counts[o.status] = (counts[o.status] ?? 0) + 1;
    }
    return counts;
  }

  test('an operation and its command are written together or not at '
      'all', () async {
    final id = await store.recordSpikeOperation(op(1));
    expect(await db.select(db.spikeOperations).get(), hasLength(1));
    expect((await store.pending()).single.opId, id);

    // The command insert fails (same op_id): the projection rolls back too.
    await expectLater(
      store.recordSpikeOperation(op(2), opId: id),
      throwsA(isA<SqliteException>()),
    );
    expect(await db.select(db.spikeOperations).get(), hasLength(1));
    expect(await db.select(db.outbox).get(), hasLength(1));
  });

  test('offline operations survive closing and reopening the app, then '
      'sync once', () async {
    final dir = await Directory.systemTemp.createTemp('esquinita_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/esquinita.sqlite');

    var local = AppDatabase(NativeDatabase(file));
    final deviceId = await OutboxStore(local).deviceId();
    for (var i = 0; i < 3; i++) {
      await OutboxStore(local).recordSpikeOperation(op(i));
    }
    await local.close(); // app closed

    local = AppDatabase(NativeDatabase(file)); // app reopened
    addTearDown(local.close);
    final reopened = OutboxStore(local);
    expect(await reopened.deviceId(), deviceId);
    expect(await reopened.watchPendingCount().first, 3);

    expect(await SyncClient(reopened, server).sync(), 3);
    expect(await reopened.watchPendingCount().first, 0);
    expect(server.inbox, hasLength(3));
  });

  test('a lost response is resent and counted once', () async {
    for (var i = 0; i < 3; i++) {
      await store.recordSpikeOperation(op(i));
    }
    server.loseNextResponse = true;
    final client = SyncClient(store, server);
    await expectLater(client.sync(), throwsA(isA<SyncException>()));
    expect(await store.watchPendingCount().first, 3);
    expect((await db.select(db.outbox).get()).first.attempts, 1);

    expect(await client.sync(), 3);
    expect(await statuses(), {'applied': 3});
    final rows = await db.select(db.outbox).get();
    expect(rows.map((r) => r.lastResponse).toSet(), {'duplicate'});
    expect(rows.map((r) => r.lastError).toSet(), {null});
    expect(server.inbox, hasLength(3)); // the server applied them once
  });

  test('30 operations, connection lost halfway: the rest stays pending and '
      'the next sync completes with exactly 30', () async {
    for (var i = 0; i < 30; i++) {
      await store.recordSpikeOperation(op(i));
    }
    final client = SyncClient(store, server, batchSize: 1);
    server.onlineFor = 15;
    await expectLater(client.sync(), throwsA(isA<SyncException>()));
    expect(await statuses(), {'applied': 15, 'pending': 15});

    server.onlineFor = null; // airplane mode off
    expect(await client.sync(), 15);
    expect(await statuses(), {'applied': 30});
    expect(server.inbox, hasLength(30));
  });

  test('"Reenviar todo" gets duplicates and keeps the verdicts', () async {
    for (var i = 0; i < 2; i++) {
      await store.recordSpikeOperation(op(i));
    }
    final client = SyncClient(store, server);
    await client.sync();
    expect(await client.sync(resendAll: true), 2);
    expect(await statuses(), {'applied': 2});
    expect(server.inbox, hasLength(2));
  });

  test('a server answer for other commands is refused', () async {
    await store.recordSpikeOperation(op(1));
    final client = SyncClient(store, _WrongAnswers());
    await expectLater(client.sync(), throwsA(isA<SyncException>()));
    expect(await store.watchPendingCount().first, 1);
  });

  test('retries wait longer after each failure, up to 5 minutes', () {
    expect(
      [for (var n = 1; n <= 8; n++) retryDelay(n).inSeconds],
      [5, 10, 20, 40, 80, 160, 300, 300],
    );
  });
}

class _WrongAnswers implements PushTransport {
  @override
  Future<List<PushResult>> push(List<SyncCommand> commands) async => [
    PushResult(uuidV7(), PushStatus.applied),
  ];
}
