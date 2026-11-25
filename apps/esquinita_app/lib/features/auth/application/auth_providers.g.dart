// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(localAuth)
final localAuthProvider = LocalAuthProvider._();

final class LocalAuthProvider
    extends $FunctionalProvider<LocalAuth, LocalAuth, LocalAuth>
    with $Provider<LocalAuth> {
  LocalAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localAuthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localAuthHash();

  @$internal
  @override
  $ProviderElement<LocalAuth> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocalAuth create(Ref ref) {
    return localAuth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalAuth value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalAuth>(value),
    );
  }
}

String _$localAuthHash() => r'045fbc5f00503923012210b8f88d1191d4eb52a6';

/// Whether this device finished its first-start setup.

@ProviderFor(deviceRegistered)
final deviceRegisteredProvider = DeviceRegisteredProvider._();

/// Whether this device finished its first-start setup.

final class DeviceRegisteredProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether this device finished its first-start setup.
  DeviceRegisteredProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceRegisteredProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceRegisteredHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return deviceRegistered(ref);
  }
}

String _$deviceRegisteredHash() => r'cdd880bb1fdda8760e4bd83c9b38e0028248bd0d';

/// Who is using the app now; null shows the login screen.

@ProviderFor(CurrentSession)
final currentSessionProvider = CurrentSessionProvider._();

/// Who is using the app now; null shows the login screen.
final class CurrentSessionProvider
    extends $NotifierProvider<CurrentSession, AppSession?> {
  /// Who is using the app now; null shows the login screen.
  CurrentSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentSessionHash();

  @$internal
  @override
  CurrentSession create() => CurrentSession();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppSession? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppSession?>(value),
    );
  }
}

String _$currentSessionHash() => r'560666838e133a7c785bc9c987ce3ec845e315c8';

/// Who is using the app now; null shows the login screen.

abstract class _$CurrentSession extends $Notifier<AppSession?> {
  AppSession? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppSession?, AppSession?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppSession?, AppSession?>,
              AppSession?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
