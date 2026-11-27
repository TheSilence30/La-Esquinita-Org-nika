import 'package:esquinita_core/esquinita_core.dart';

import '../../../data/local/catalog_store.dart';

/// `12.50` or `12,5` → 1250; null when empty, negative or with more than 2
/// decimals.
int? parseCents(String text) => _parseScaled(text, 2);

/// `1.5`, `1,500` or `0,250` → milli (1500, 1500, 250); null when empty,
/// negative or with more than 3 decimals.
int? parseMilli(String text) => _parseScaled(text, 3);

int? _parseScaled(String text, int decimals) {
  final m = RegExp(r'^(\d+)(?:[.,](\d*))?$').firstMatch(text.trim());
  if (m == null) return null;
  final frac = m[2] ?? '';
  if (frac.length > decimals) return null;
  var scale = 1;
  for (var i = 0; i < decimals; i++) {
    scale *= 10;
  }
  return int.parse(m[1]!) * scale + int.parse(frac.padRight(decimals, '0'));
}

/// One presentation as typed in the form.
final class PresentationDraft {
  const PresentationDraft({
    required this.name,
    required this.factorMilli,
    required this.priceCents,
    this.wholesaleCents,
    this.wholesaleMinMilli,
    this.barcode,
    this.generatedBarcode = false,
  });

  final String name;

  /// Base units in one of it × 1000 ("Bolsa 500 g" of a kg product: 500).
  final int factorMilli;
  final int priceCents;
  final int? wholesaleCents;

  /// In this presentation's units.
  final int? wholesaleMinMilli;
  final String? barcode;

  /// [barcode] is the store's own `29…`.
  final bool generatedBarcode;
}

/// The "Registrar producto" form, before the device gives it ids and codes.
final class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.categoryId,
    required this.unitId,
    required this.base,
    this.brandId,
    this.extras = const [],
    this.tracksLots = false,
    this.minStockMilli = 0,
    this.costCents = 0,
    this.initialMilli = 0,
    this.lotCode,
    this.expiresOn,
  });

  final String name;
  final String categoryId;
  final String? brandId;
  final String unitId;

  /// Factor 1000: one base unit, priced per unit, kg or litre.
  final PresentationDraft base;
  final List<PresentationDraft> extras;
  final bool tracksLots;
  final int minStockMilli;

  /// Per base unit.
  final int costCents;

  /// Base unit; 0: no initial stock.
  final int initialMilli;
  final String? lotCode;

  /// `YYYY-MM-DD`; null: the lot does not expire.
  final String? expiresOn;
}

/// Records [d] by [userId] on this device (also offline): ids, internal
/// code and barcode formats come from here, then [CatalogStore]
/// validates and writes it with its command. Returns the product id.
/// Throws [CatalogException] with the reason in Spanish.
Future<String> registerProduct(
  CatalogStore store,
  ProductDraft d, {
  required String userId,
}) async {
  NewPresentation presentation(PresentationDraft x, {required bool base}) {
    final code = x.barcode?.trim() ?? '';
    final check = code.isEmpty ? null : checkBarcode(code);
    if (check?.error case final e?) throw CatalogException('$code: $e');
    return NewPresentation(
      id: uuidV7(),
      name: x.name.trim(),
      factorMilli: base ? 1000 : x.factorMilli,
      isBase: base,
      retailPriceCents: x.priceCents,
      wholesalePriceCents: x.wholesaleCents,
      wholesaleMinMilli: x.wholesaleCents == null ? null : x.wholesaleMinMilli,
      barcodes: [
        if (check case (format: final f?, error: null))
          NewBarcode(code: code, format: f, generated: x.generatedBarcode),
      ],
    );
  }

  final presentations = [
    presentation(d.base, base: true),
    for (final x in d.extras) presentation(x, base: false),
  ];
  final lot = d.tracksLots && d.initialMilli > 0;
  final p = CreateProduct(
    productId: uuidV7(),
    internalCode: await store.nextInternalCode(),
    name: d.name.trim(),
    categoryId: d.categoryId,
    brandId: d.brandId,
    baseUnitId: d.unitId,
    tracksLots: d.tracksLots,
    minStockMilli: d.minStockMilli,
    unitCostCents: d.costCents,
    presentations: presentations,
    initialStock: [
      if (d.initialMilli > 0)
        InitialStock(
          movementId: uuidV7(),
          qtyMilli: d.initialMilli,
          lotId: lot ? uuidV7() : null,
          lotCode: lot ? d.lotCode?.trim() : null,
          expiresOn: lot ? d.expiresOn : null,
        ),
    ],
  );
  await store.recordCreateProduct(p, userId: userId);
  return p.productId;
}
