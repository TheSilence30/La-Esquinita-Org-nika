// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(catalogStore)
final catalogStoreProvider = CatalogStoreProvider._();

final class CatalogStoreProvider
    extends $FunctionalProvider<CatalogStore, CatalogStore, CatalogStore>
    with $Provider<CatalogStore> {
  CatalogStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogStoreHash();

  @$internal
  @override
  $ProviderElement<CatalogStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CatalogStore create(Ref ref) {
    return catalogStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CatalogStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CatalogStore>(value),
    );
  }
}

String _$catalogStoreHash() => r'd76fe61f5d188b634b2d0266afe9571a471f3e83';

/// The product list for [query] (name, internal code or barcode).

@ProviderFor(productSearch)
final productSearchProvider = ProductSearchFamily._();

/// The product list for [query] (name, internal code or barcode).

final class ProductSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductSummary>>,
          List<ProductSummary>,
          Stream<List<ProductSummary>>
        >
    with
        $FutureModifier<List<ProductSummary>>,
        $StreamProvider<List<ProductSummary>> {
  /// The product list for [query] (name, internal code or barcode).
  ProductSearchProvider._({
    required ProductSearchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'productSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productSearchHash();

  @override
  String toString() {
    return r'productSearchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ProductSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ProductSummary>> create(Ref ref) {
    final argument = this.argument as String;
    return productSearch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productSearchHash() => r'310b5768858d169a81d2c82be9d909ec3e9970d2';

/// The product list for [query] (name, internal code or barcode).

final class ProductSearchFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ProductSummary>>, String> {
  ProductSearchFamily._()
    : super(
        retry: null,
        name: r'productSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The product list for [query] (name, internal code or barcode).

  ProductSearchProvider call(String query) =>
      ProductSearchProvider._(argument: query, from: this);

  @override
  String toString() => r'productSearchProvider';
}

@ProviderFor(productDetail)
final productDetailProvider = ProductDetailFamily._();

final class ProductDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProductDetail?>,
          ProductDetail?,
          Stream<ProductDetail?>
        >
    with $FutureModifier<ProductDetail?>, $StreamProvider<ProductDetail?> {
  ProductDetailProvider._({
    required ProductDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'productDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productDetailHash();

  @override
  String toString() {
    return r'productDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<ProductDetail?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ProductDetail?> create(Ref ref) {
    final argument = this.argument as String;
    return productDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productDetailHash() => r'fdd263550da0cdc7f3dd2e9f552bde451a31cb14';

final class ProductDetailFamily extends $Family
    with $FunctionalFamilyOverride<Stream<ProductDetail?>, String> {
  ProductDetailFamily._()
    : super(
        retry: null,
        name: r'productDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProductDetailProvider call(String productId) =>
      ProductDetailProvider._(argument: productId, from: this);

  @override
  String toString() => r'productDetailProvider';
}

/// Categories, brands and units for the product form.

@ProviderFor(catalogOptions)
final catalogOptionsProvider = CatalogOptionsProvider._();

/// Categories, brands and units for the product form.

final class CatalogOptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<CatalogOptions>,
          CatalogOptions,
          FutureOr<CatalogOptions>
        >
    with $FutureModifier<CatalogOptions>, $FutureProvider<CatalogOptions> {
  /// Categories, brands and units for the product form.
  CatalogOptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogOptionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogOptionsHash();

  @$internal
  @override
  $FutureProviderElement<CatalogOptions> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CatalogOptions> create(Ref ref) {
    return catalogOptions(ref);
  }
}

String _$catalogOptionsHash() => r'94d7f28a26409337440479ae2e6339928c8eeba9';
