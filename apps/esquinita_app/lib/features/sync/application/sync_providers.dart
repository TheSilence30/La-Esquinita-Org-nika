import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers.dart';
import '../../../data/sync/server_sync.dart';
import '../../../data/sync/sync_client.dart';
import '../../auth/application/auth_providers.dart';

part 'sync_providers.g.dart';

/// The sync engine: push the outbox in batches, then pull master data.
///
/// It also syncs right after an operation is recorded (the pending count
/// goes up) while someone is logged in (user, 2026-11-22). Logging in and
/// the app coming back to the foreground start a round too (`SyncTriggers`).
@Riverpod(keepAlive: true)
SyncScheduler syncEngine(Ref ref) {
  final store = ref.watch(outboxStoreProvider);
  final server = ref.watch(serverSyncProvider);
  final auth = ref.watch(localAuthProvider);
  final engine = SyncScheduler(
    SyncClient(store, server),
    pull: () async {
      await server.pull();
      await auth.markTimeSeen();
    },
  );
  var last = 0;
  final sub = store.watchPendingCount().listen((n) {
    if (n > last && ref.read(currentSessionProvider) != null) engine.start();
    last = n;
  });
  ref.onDispose(() {
    unawaited(sub.cancel());
    engine.dispose();
  });
  return engine;
}

/// The server with the saved login of the user on screen (sync and the
/// Administrador screens).
@Riverpod(keepAlive: true)
ServerSync serverSync(Ref ref) => ServerSync(
  db: ref.watch(appDatabaseProvider),
  apiFor: ref.watch(localAuthProvider).apiFor,
  currentUserId: () => ref.read(currentSessionProvider)?.userId,
);

/// What the indicator shows. [pending] is null until the first count.
typedef SyncView = ({int? pending, SyncRunState run});

@Riverpod(keepAlive: true)
class SyncStatus extends _$SyncStatus {
  @override
  SyncView build() {
    final engine = ref.watch(syncEngineProvider);
    final runs = engine.states.listen(
      (r) => state = (pending: state.pending, run: r),
    );
    final counts = ref
        .watch(outboxStoreProvider)
        .watchPendingCount()
        .listen((n) => state = (pending: n, run: state.run));
    ref.onDispose(() {
      unawaited(runs.cancel());
      unawaited(counts.cancel());
    });
    return (
      pending: null,
      run: SyncRunState(running: engine.running, error: engine.lastError),
    );
  }
}
