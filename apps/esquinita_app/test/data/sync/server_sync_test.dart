import 'package:drift/native.dart';
import 'package:esquinita_app/data/local/database.dart';
import 'package:esquinita_app/data/sync/outbox_store.dart';
import 'package:esquinita_app/data/sync/server_sync.dart';
import 'package:esquinita_app/data/sync/sync_client.dart';
import 'package:esquinita_app/features/auth/application/local_auth.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_server.dart';

// Push and pull with the saved login: rotating refresh, expired access
// token, revoked login (user, 2026-11-22: then ask for the password).
void main() {
  late AppDatabase db;
  late FakeServer server;
  late OutboxStore store;
  String? onScreen;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    server = FakeServer(await testHasher.hash('4821'));
    store = OutboxStore(db);
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
  });

  tearDown(() => db.close());

  ServerSync sync() =>
      ServerSync(db: db, apiFor: (_) => server, currentUserId: () => onScreen);

  Future<String?> savedRefresh() async => (await (db.select(
    db.localSessions,
  )..where((s) => s.userId.equals(adminId))).getSingle()).refreshToken;

  Future<int> record(int n) async {
    for (var i = 0; i < n; i++) {
      await store.recordSpikeOperation(
        SpikeOperation(note: 'Op $i', amountCents: i),
        userId: onScreen!,
      );
    }
    return n;
  }

  test('pushes with the saved login and saves the rotated refresh token '
      'before using it', () async {
    final first = await savedRefresh();
    final s = sync();
    await record(3);
    expect(await SyncClient(store, s).sync(), 3);
    expect(server.inbox, hasLength(3));
    expect(server.refreshes, [first]);
    final rotated = await savedRefresh();
    expect(rotated, isNot(first));
    expect(server.liveRefresh, contains(rotated));
    await s.pull();
    expect(server.pulls, 3, reason: 'setup + login + this one');
    expect(server.refreshes, hasLength(1), reason: 'access token reused');
  });

  test(
    'an expired access token is refreshed once and the call retried',
    () async {
      final s = sync();
      await s.pull();
      server.expired.add(server.lastAccess!);
      await record(1);
      expect(await SyncClient(store, s).sync(), 1);
      expect(server.refreshes, hasLength(2));
    },
  );

  test('offline: an error to retry; nothing changes', () async {
    final before = await savedRefresh();
    server.offline = true;
    await record(1);
    await expectLater(
      SyncClient(store, sync()).sync(),
      throwsA(
        isA<SyncException>().having((e) => e.needsPassword, 'pw', isFalse),
      ),
    );
    expect(await savedRefresh(), before);
    expect(await store.pendingCount(), 1);
  });

  test('the app missed a rotated refresh: the reuse revokes the login; it '
      'asks for the password, keeps the pending ones and never resends the '
      'dead token', () async {
    server.loseNextRefresh = true;
    await record(2);
    await expectLater(
      SyncClient(store, sync()).sync(),
      throwsA(isA<SyncException>()),
    );
    // Restart: the old token was never replaced, so it is reused.
    await expectLater(
      SyncClient(store, sync()).sync(),
      throwsA(
        isA<SyncException>().having((e) => e.needsPassword, 'pw', isTrue),
      ),
    );
    expect(await savedRefresh(), isNull);
    expect(await store.pendingCount(), 2);
    final calls = server.refreshes.length;
    await expectLater(
      SyncClient(store, sync()).sync(),
      throwsA(isA<SyncException>()),
    );
    expect(server.refreshes, hasLength(calls), reason: 'not sent again');

    // A password login brings a new saved login; the PIN was never needed.
    await LocalAuth(
      db: db,
      apiFor: (_) => server,
      verifyPin: verifyPinArgon2,
      platform: 'android',
    ).loginWithPassword('Administrador', 'admin-1234');
    expect(await SyncClient(store, sync()).sync(), 2);
    expect(server.inbox, hasLength(2));
  });

  test('nobody logged in, or a user without a saved login: asks for the '
      'password and calls nothing', () async {
    await record(1);
    for (final user in [null, staffId]) {
      onScreen = user;
      await expectLater(
        SyncClient(store, sync()).sync(),
        throwsA(
          isA<SyncException>().having((e) => e.needsPassword, 'pw', isTrue),
        ),
      );
    }
    expect(server.refreshes, isEmpty);
  });

  test('another user on screen: their own login is used', () async {
    final s = sync();
    await s.pull();
    // Trabajo logs in on this device (after the forced change).
    final auth = LocalAuth(
      db: db,
      apiFor: (_) => server,
      verifyPin: verifyPinArgon2,
      platform: 'android',
    );
    await auth.loginWithNewPassword('Trabajo', 'trabajo-1234', 'nueva-1234');
    onScreen = staffId;
    await s.pull();
    expect(server.refreshes.last, startsWith('r-$staffId-'));
  });
}
