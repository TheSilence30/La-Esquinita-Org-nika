// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The open, encrypted local database. `main` opens it before the app starts
/// and overrides this provider; tests override it with an in-memory one.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// The open, encrypted local database. `main` opens it before the app starts
/// and overrides this provider; tests override it with an in-memory one.

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// The open, encrypted local database. `main` opens it before the app starts
  /// and overrides this provider; tests override it with an in-memory one.
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'cd89999af5b121916081f287b7704a6b0efc252b';

@ProviderFor(outboxStore)
final outboxStoreProvider = OutboxStoreProvider._();

final class OutboxStoreProvider
    extends $FunctionalProvider<OutboxStore, OutboxStore, OutboxStore>
    with $Provider<OutboxStore> {
  OutboxStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'outboxStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$outboxStoreHash();

  @$internal
  @override
  $ProviderElement<OutboxStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OutboxStore create(Ref ref) {
    return outboxStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OutboxStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OutboxStore>(value),
    );
  }
}

String _$outboxStoreHash() => r'0878dde3dd91c2a72218e519ac15e95a8154cfa1';

@ProviderFor(replicaStore)
final replicaStoreProvider = ReplicaStoreProvider._();

final class ReplicaStoreProvider
    extends $FunctionalProvider<ReplicaStore, ReplicaStore, ReplicaStore>
    with $Provider<ReplicaStore> {
  ReplicaStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'replicaStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$replicaStoreHash();

  @$internal
  @override
  $ProviderElement<ReplicaStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReplicaStore create(Ref ref) {
    return replicaStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReplicaStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReplicaStore>(value),
    );
  }
}

String _$replicaStoreHash() => r'28275ad42ceec347fb092d3d455e3d2e9a45e521';
