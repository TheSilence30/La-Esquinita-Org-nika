import '../sync/uuid_v7.dart';
import 'barcode_check.dart';

/// A barcode of a new presentation; [generated] for the store's own `29…`.
final class NewBarcode {
  const NewBarcode({
    required this.code,
    required this.format,
    this.generated = false,
  });

  final String code;
  final BarcodeFormat format;
  final bool generated;

  Map<String, Object?> toJson() => {
    'code': code,
    'format': format.name,
    'generated': generated,
  };
}

/// A presentation of a new product (docs/modelo-datos.md §3.1).
final class NewPresentation {
  const NewPresentation({
    required this.id,
    required this.name,
    required this.factorMilli,
    required this.isBase,
    required this.retailPriceCents,
    this.wholesalePriceCents,
    this.wholesaleMinMilli,
    this.barcodes = const [],
  });

  final String id;
  final String name;

  /// Base units × 1000; the base presentation is 1000.
  final int factorMilli;
  final bool isBase;
  final int retailPriceCents;
  final int? wholesalePriceCents;
  final int? wholesaleMinMilli;
  final List<NewBarcode> barcodes;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'factor_milli': factorMilli,
    'is_base': isBase,
    'retail_price_cents': retailPriceCents,
    'wholesale_price_cents': wholesalePriceCents,
    'wholesale_min_milli': wholesaleMinMilli,
    'barcodes': [for (final b in barcodes) b.toJson()],
  };
}

/// Stock counted when the product is registered: an `initial` movement,
/// never an edited balance (CLAUDE.md §6.1).
final class InitialStock {
  const InitialStock({
    required this.movementId,
    required this.qtyMilli,
    this.lotId,
    this.lotCode,
    this.expiresOn,
  });

  final String movementId;

  /// Base unit, > 0.
  final int qtyMilli;

  /// Products that track lots only.
  final String? lotId;
  final String? lotCode;

  /// `YYYY-MM-DD`; null: the lot does not expire.
  final String? expiresOn;

  Map<String, Object?> toJson() => {
    'movement_id': movementId,
    'qty_milli': qtyMilli,
    'lot_id': lotId,
    'lot_code': lotCode,
    'expires_on': expiresOn,
  };
}

/// `CreateProduct`: a product registered on a device, also offline
/// (docs/modelo-datos.md §6). Every id comes from the device.
final class CreateProduct {
  const CreateProduct({
    required this.productId,
    required this.internalCode,
    required this.name,
    required this.categoryId,
    required this.baseUnitId,
    required this.presentations,
    this.description,
    this.brandId,
    this.tracksLots = false,
    this.minStockMilli = 0,
    this.unitCostCents = 0,
    this.initialStock = const [],
  });

  static const type = 'CreateProduct';

  final String productId;
  final String internalCode;
  final String name;
  final String? description;
  final String categoryId;
  final String? brandId;
  final String baseUnitId;
  final bool tracksLots;
  final int minStockMilli;

  /// Purchase cost per base unit, the first average (§3.4).
  final int unitCostCents;
  final List<NewPresentation> presentations;
  final List<InitialStock> initialStock;

  /// Every rule broken, in Spanish (Peru), for the screen; empty when valid.
  /// The server checks the same before applying.
  List<String> problems() {
    final p = <String>[];
    if (!isUuid(productId)) p.add('Falta el id del producto.');
    if (internalCode.trim().isEmpty) p.add('Falta el código interno.');
    if (name.trim().isEmpty || name.length > 120) {
      p.add('El nombre debe tener de 1 a 120 caracteres.');
    }
    if (!isUuid(categoryId)) p.add('Elige una categoría.');
    if (brandId != null && !isUuid(brandId!)) p.add('Marca no válida.');
    if (!isUuid(baseUnitId)) p.add('Elige la unidad base.');
    if (minStockMilli < 0) p.add('El stock mínimo no puede ser negativo.');
    if (unitCostCents < 0) p.add('El costo no puede ser negativo.');

    final bases = presentations.where((x) => x.isBase).toList();
    if (bases.length != 1) {
      p.add('Debe haber exactamente una presentación base.');
    } else if (bases.single.factorMilli != 1000) {
      p.add('La presentación base equivale a 1 unidad base.');
    }
    final names = <String>{};
    final codes = <String>{};
    for (final x in presentations) {
      final label = '«${x.name}»';
      if (!isUuid(x.id)) p.add('Presentación $label sin id.');
      if (x.name.trim().isEmpty) p.add('Una presentación no tiene nombre.');
      if (!names.add(x.name.trim().toLowerCase())) {
        p.add('La presentación $label está repetida.');
      }
      if (x.factorMilli <= 0) {
        p.add('La presentación $label necesita cuántas unidades base trae.');
      }
      if (x.retailPriceCents < 0) p.add('Precio de $label no válido.');
      if ((x.wholesalePriceCents ?? 0) < 0 || (x.wholesaleMinMilli ?? 1) <= 0) {
        p.add('Precio mayorista de $label no válido.');
      }
      for (final b in x.barcodes) {
        final check = checkBarcode(b.code, scanned: b.format);
        if (check.error case final e?) p.add('${b.code}: $e');
        if (!codes.add(b.code)) p.add('El código ${b.code} está repetido.');
      }
    }

    final lots = <String>{};
    for (final s in initialStock) {
      if (!isUuid(s.movementId)) p.add('Stock inicial sin id.');
      if (s.qtyMilli <= 0) p.add('El stock inicial debe ser mayor que 0.');
      if (s.expiresOn != null &&
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s.expiresOn!)) {
        p.add('Fecha de vencimiento no válida: ${s.expiresOn}.');
      }
      if (tracksLots) {
        if (s.lotId == null || !isUuid(s.lotId!)) p.add('Lote sin id.');
        if ((s.lotCode ?? '').trim().isEmpty) {
          p.add('Este producto controla lotes: escribe el lote.');
        }
        if (!lots.add('${s.lotCode?.trim()}|${s.expiresOn}')) {
          p.add('El lote ${s.lotCode} está repetido.');
        }
      } else if (s.lotId != null || s.lotCode != null || s.expiresOn != null) {
        p.add('Este producto no controla lotes.');
      }
    }
    return p;
  }

  Map<String, Object?> toPayload() => {
    'product_id': productId,
    'internal_code': internalCode,
    'name': name,
    'description': description,
    'category_id': categoryId,
    'brand_id': brandId,
    'base_unit_id': baseUnitId,
    'tracks_lots': tracksLots,
    'min_stock_milli': minStockMilli,
    'unit_cost_cents': unitCostCents,
    'presentations': [for (final x in presentations) x.toJson()],
    'initial_stock': [for (final s in initialStock) s.toJson()],
  };

  /// Throws [FormatException] for a malformed payload or a broken rule.
  factory CreateProduct.fromPayload(Map<String, Object?> p) {
    T req<T>(Map<String, Object?> m, String k) => switch (m[k]) {
      final T v => v,
      _ => throw FormatException('$k: missing or wrong type'),
    };
    T? opt<T>(Map<String, Object?> m, String k) => switch (m[k]) {
      null => null,
      final T v => v,
      _ => throw FormatException('$k: wrong type'),
    };
    List<Map<String, Object?>> list(Map<String, Object?> m, String k) => [
      for (final e in req<List<Object?>>(m, k))
        e is Map<String, Object?> ? e : throw FormatException('$k: objects'),
    ];
    BarcodeFormat format(String f) => BarcodeFormat.values.firstWhere(
      (x) => x.name == f,
      orElse: () => throw FormatException('format: $f'),
    );
    final cmd = CreateProduct(
      productId: req(p, 'product_id'),
      internalCode: req(p, 'internal_code'),
      name: req(p, 'name'),
      description: opt(p, 'description'),
      categoryId: req(p, 'category_id'),
      brandId: opt(p, 'brand_id'),
      baseUnitId: req(p, 'base_unit_id'),
      tracksLots: req(p, 'tracks_lots'),
      minStockMilli: req(p, 'min_stock_milli'),
      unitCostCents: req(p, 'unit_cost_cents'),
      presentations: [
        for (final x in list(p, 'presentations'))
          NewPresentation(
            id: req(x, 'id'),
            name: req(x, 'name'),
            factorMilli: req(x, 'factor_milli'),
            isBase: req(x, 'is_base'),
            retailPriceCents: req(x, 'retail_price_cents'),
            wholesalePriceCents: opt(x, 'wholesale_price_cents'),
            wholesaleMinMilli: opt(x, 'wholesale_min_milli'),
            barcodes: [
              for (final b in list(x, 'barcodes'))
                NewBarcode(
                  code: req(b, 'code'),
                  format: format(req(b, 'format')),
                  generated: req(b, 'generated'),
                ),
            ],
          ),
      ],
      initialStock: [
        for (final s in list(p, 'initial_stock'))
          InitialStock(
            movementId: req(s, 'movement_id'),
            qtyMilli: req(s, 'qty_milli'),
            lotId: opt(s, 'lot_id'),
            lotCode: opt(s, 'lot_code'),
            expiresOn: opt(s, 'expires_on'),
          ),
      ],
    );
    if (cmd.problems() case [final first, ...]) throw FormatException(first);
    return cmd;
  }
}
