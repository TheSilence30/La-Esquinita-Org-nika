import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../sync/application/sync_providers.dart';
import 'admin_client.dart';

part 'admin_providers.g.dart';

@Riverpod(keepAlive: true)
AdminClient adminClient(Ref ref) => AdminClient(
  ref.watch(serverSyncProvider),
  afterChange: () => ref.read(syncEngineProvider).syncNow(),
);

/// Every user, from the server (needs a connection).
@riverpod
Future<List<AdminUser>> adminUsers(Ref ref) =>
    ref.watch(adminClientProvider).users();

/// The ticket settings, from the server.
@riverpod
Future<Map<String, String?>> adminSettings(Ref ref) =>
    ref.watch(adminClientProvider).settings();

/// Every registered device, from the server.
@riverpod
Future<List<AdminDevice>> adminDevices(Ref ref) =>
    ref.watch(adminClientProvider).devices();
