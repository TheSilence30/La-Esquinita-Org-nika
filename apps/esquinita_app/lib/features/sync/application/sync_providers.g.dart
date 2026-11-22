// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The sync engine: push the outbox in batches, then pull master data.
///
/// It also syncs right after an operation is recorded (the pending count
/// goes up) while someone is logged in (user, 2026-11-22). Logging in and
/// the app coming back to the foreground start a round too (`SyncTriggers`).

@ProviderFor(syncEngine)
final syncEngineProvider = SyncEngineProvider._();

/// The sync engine: push the outbox in batches, then pull master data.
///
/// It also syncs right after an operation is recorded (the pending count
/// goes up) while someone is logged in (user, 2026-11-22). Logging in and
/// the app coming back to the foreground start a round too (`SyncTriggers`).

final class SyncEngineProvider
    extends $FunctionalProvider<SyncScheduler, SyncScheduler, SyncScheduler>
    with $Provider<SyncScheduler> {
  /// The sync engine: push the outbox in batches, then pull master data.
  ///
  /// It also syncs right after an operation is recorded (the pending count
  /// goes up) while someone is logged in (user, 2026-11-22). Logging in and
  /// the app coming back to the foreground start a round too (`SyncTriggers`).
  SyncEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncEngineHash();

  @$internal
  @override
  $ProviderElement<SyncScheduler> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncScheduler create(Ref ref) {
    return syncEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncScheduler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncScheduler>(value),
    );
  }
}

String _$syncEngineHash() => r'8a7d44426725d7926283484db2a06c320bf667fc';

@ProviderFor(SyncStatus)
final syncStatusProvider = SyncStatusProvider._();

final class SyncStatusProvider extends $NotifierProvider<SyncStatus, SyncView> {
  SyncStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncStatusHash();

  @$internal
  @override
  SyncStatus create() => SyncStatus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncView value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncView>(value),
    );
  }
}

String _$syncStatusHash() => r'8e2b295ef49c660dae21a10a6cc0783a63886e61';

abstract class _$SyncStatus extends $Notifier<SyncView> {
  SyncView build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SyncView, SyncView>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SyncView, SyncView>,
              SyncView,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
