import 'dart:async';
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

  /// `pending_ops` of each request.
  final reported = <int>[];

  /// Throw this instead of answering (e.g. the saved login was revoked).
  SyncException? fail;

  /// Called inside each request, before answering.
  Future<void> Function()? during;

  @override
  Future<List<PushResult>> push(
    List<SyncCommand> commands, {
    required int pendingOps,
  }) async {
    requests++;
    if (fail case final e?) throw e;
    await during?.call();
    reported.add(pendingOps);
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

const user = '019a0000-0000-7000-8000-0000000000a1';

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
    final id = await store.recordSpikeOperation(op(1), userId: user);
    expect(await db.select(db.spikeOperations).get(), hasLength(1));
    expect((await store.pending()).single.opId, id);

    // The command insert fails (same op_id): the projection rolls back too.
    await expectLater(
      store.recordSpikeOperation(op(2), userId: user, opId: id),
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
      await OutboxStore(local).recordSpikeOperation(op(i), userId: user);
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
      await store.recordSpikeOperation(op(i), userId: user);
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
      await store.recordSpikeOperation(op(i), userId: user);
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
      await store.recordSpikeOperation(op(i), userId: user);
    }
    final client = SyncClient(store, server);
    await client.sync();
    expect(await client.sync(resendAll: true), 2);
    expect(await statuses(), {'applied': 2});
    expect(server.inbox, hasLength(2));
  });

  test('a server answer for other commands is refused', () async {
    await store.recordSpikeOperation(op(1), userId: user);
    final client = SyncClient(store, _WrongAnswers());
    await expectLater(client.sync(), throwsA(isA<SyncException>()));
    expect(await store.watchPendingCount().first, 1);
  });

  test('retries wait longer after each failure, up to 60 s (user, '
      '2026-11-22)', () {
    expect(
      [for (var n = 1; n <= 8; n++) retryDelay(n).inSeconds],
      [5, 10, 20, 40, 60, 60, 60, 60],
    );
    expect(retryDelay(1000).inSeconds, 60);
  });

  test('each request reports what is still pending after it', () async {
    for (var i = 0; i < 3; i++) {
      await store.recordSpikeOperation(op(i), userId: user);
    }
    await SyncClient(store, server, batchSize: 1).sync();
    expect(server.reported, [2, 1, 0]);
  });

  test('two devices offline, then both online: every operation once', () async {
    final other = AppDatabase(NativeDatabase.memory());
    addTearDown(other.close);
    final stores = [store, OutboxStore(other)];
    expect(await stores[0].deviceId(), isNot(await stores[1].deviceId()));
    server.onlineFor = 0; // both offline
    for (final st in stores) {
      for (var i = 0; i < 5; i++) {
        await st.recordSpikeOperation(op(i), userId: user);
      }
      await expectLater(
        SyncClient(st, server).sync(),
        throwsA(isA<SyncException>()),
      );
    }
    server.onlineFor = null;
    for (final st in stores) {
      expect(await SyncClient(st, server).sync(), 5);
      expect(await st.pendingCount(), 0);
    }
    expect(server.inbox, hasLength(10));
  });

  group('scheduler', () {
    Future<SyncRunState> round(SyncScheduler s) async {
      final next = s.states.firstWhere((r) => !r.running);
      await s.syncNow();
      return next;
    }

    test('nothing pending after a round: no 30 s timer; a failure retries '
        'in 5 s', () async {
      final s = SyncScheduler(SyncClient(store, server));
      addTearDown(s.dispose);
      expect((await round(s)).nextIn, isNull);
      await store.recordSpikeOperation(op(1), userId: user);
      server.onlineFor = 0;
      final failed = await round(s);
      expect(failed.error, isNotNull);
      expect(failed.nextIn, const Duration(seconds: 5));
    });

    test(
      'a revoked login stops the retries until someone asks again',
      () async {
        await store.recordSpikeOperation(op(1), userId: user);
        server.fail = const SyncException('x', needsPassword: true);
        final s = SyncScheduler(SyncClient(store, server));
        addTearDown(s.dispose);
        final r = await round(s);
        expect(r.error!.needsPassword, isTrue);
        expect(r.nextIn, isNull);
        expect(await store.pendingCount(), 1, reason: 'nothing is lost');
      },
    );

    test(
      'an operation recorded during a round is sent right after it',
      () async {
        await store.recordSpikeOperation(op(1), userId: user);
        final s = SyncScheduler(SyncClient(store, server));
        addTearDown(s.dispose);
        var recorded = false;
        server.during = () async {
          if (recorded) return;
          recorded = true;
          await store.recordSpikeOperation(op(2), userId: user);
          unawaited(s.syncNow()); // what the pending-count trigger does
        };
        final done = s.states.where((r) => !r.running).take(2).toList();
        await s.syncNow();
        await done;
        expect(await store.pendingCount(), 0);
        expect(server.inbox, hasLength(2));
      },
    );

    test('nothing pending and someone logged in: a round every 60 s to pull '
        'the Administrador changes; nobody logged in: none', () async {
      var loggedIn = true;
      final s = SyncScheduler(
        SyncClient(store, server),
        pull: () async {},
        loggedIn: () => loggedIn,
      );
      addTearDown(s.dispose);
      expect((await round(s)).nextIn, const Duration(seconds: 60));
      loggedIn = false;
      expect((await round(s)).nextIn, isNull);
    });

    test('pull runs after the push, in the same round', () async {
      final order = <String>[];
      await store.recordSpikeOperation(op(1), userId: user);
      server.during = () async => order.add('push');
      final s = SyncScheduler(
        SyncClient(store, server),
        pull: () async => order.add('pull'),
      );
      addTearDown(s.dispose);
      await round(s);
      expect(order, ['push', 'pull']);
    });
  });
}

class _WrongAnswers implements PushTransport {
  @override
  Future<List<PushResult>> push(
    List<SyncCommand> commands, {
    required int pendingOps,
  }) async => [PushResult(uuidV7(), PushStatus.applied)];
}
