import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/local/database.dart';
import '../data/sync/outbox_store.dart';
import '../data/sync/replica_store.dart';

part 'providers.g.dart';

/// The open, encrypted local database. `main` opens it before the app starts
/// and overrides this provider; tests override it with an in-memory one.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) =>
    throw UnimplementedError('override appDatabaseProvider in main');

@Riverpod(keepAlive: true)
OutboxStore outboxStore(Ref ref) => OutboxStore(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
ReplicaStore replicaStore(Ref ref) =>
    ReplicaStore(ref.watch(appDatabaseProvider));
