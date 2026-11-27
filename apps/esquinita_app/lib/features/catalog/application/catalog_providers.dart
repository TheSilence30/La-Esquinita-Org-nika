import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers.dart';
import '../../../data/local/catalog_store.dart';

part 'catalog_providers.g.dart';

@Riverpod(keepAlive: true)
CatalogStore catalogStore(Ref ref) =>
    CatalogStore(ref.watch(appDatabaseProvider));

/// The product list for [query] (name, internal code or barcode).
@riverpod
Stream<List<ProductSummary>> productSearch(Ref ref, String query) =>
    ref.watch(catalogStoreProvider).watchProducts(query);

@riverpod
Stream<ProductDetail?> productDetail(Ref ref, String productId) =>
    ref.watch(catalogStoreProvider).watchProduct(productId);

/// Categories, brands and units for the product form.
@riverpod
Future<CatalogOptions> catalogOptions(Ref ref) =>
    ref.watch(catalogStoreProvider).options();
