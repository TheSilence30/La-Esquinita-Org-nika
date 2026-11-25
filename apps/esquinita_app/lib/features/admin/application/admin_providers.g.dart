// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adminClient)
final adminClientProvider = AdminClientProvider._();

final class AdminClientProvider
    extends $FunctionalProvider<AdminClient, AdminClient, AdminClient>
    with $Provider<AdminClient> {
  AdminClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminClientHash();

  @$internal
  @override
  $ProviderElement<AdminClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AdminClient create(Ref ref) {
    return adminClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminClient>(value),
    );
  }
}

String _$adminClientHash() => r'11b947e3cfd7327c78a9fdbe2b37d1afef9e9e6b';

/// Every user, from the server (needs a connection).

@ProviderFor(adminUsers)
final adminUsersProvider = AdminUsersProvider._();

/// Every user, from the server (needs a connection).

final class AdminUsersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AdminUser>>,
          List<AdminUser>,
          FutureOr<List<AdminUser>>
        >
    with $FutureModifier<List<AdminUser>>, $FutureProvider<List<AdminUser>> {
  /// Every user, from the server (needs a connection).
  AdminUsersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminUsersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminUsersHash();

  @$internal
  @override
  $FutureProviderElement<List<AdminUser>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AdminUser>> create(Ref ref) {
    return adminUsers(ref);
  }
}

String _$adminUsersHash() => r'fe9a4e721a60a0c6a05444800312c422687a1e69';

/// The ticket settings, from the server.

@ProviderFor(adminSettings)
final adminSettingsProvider = AdminSettingsProvider._();

/// The ticket settings, from the server.

final class AdminSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, String?>>,
          Map<String, String?>,
          FutureOr<Map<String, String?>>
        >
    with
        $FutureModifier<Map<String, String?>>,
        $FutureProvider<Map<String, String?>> {
  /// The ticket settings, from the server.
  AdminSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminSettingsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, String?>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, String?>> create(Ref ref) {
    return adminSettings(ref);
  }
}

String _$adminSettingsHash() => r'b04033f8d4135e9495a56f99ce44e4eff1f7839d';

/// Every registered device, from the server.

@ProviderFor(adminDevices)
final adminDevicesProvider = AdminDevicesProvider._();

/// Every registered device, from the server.

final class AdminDevicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AdminDevice>>,
          List<AdminDevice>,
          FutureOr<List<AdminDevice>>
        >
    with
        $FutureModifier<List<AdminDevice>>,
        $FutureProvider<List<AdminDevice>> {
  /// Every registered device, from the server.
  AdminDevicesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminDevicesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminDevicesHash();

  @$internal
  @override
  $FutureProviderElement<List<AdminDevice>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AdminDevice>> create(Ref ref) {
    return adminDevices(ref);
  }
}

String _$adminDevicesHash() => r'738d03a05fc7850ce7a322ff95d23abbce5d3c0d';
