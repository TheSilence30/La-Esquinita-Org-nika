import 'package:drift/drift.dart';
import 'package:esquinita_core/esquinita_core.dart';

import '../sync/outbox_store.dart';
import '../sync/replica_store.dart';
import 'database.dart';

/// A product that cannot be recorded; [message] is for the screen.
final class CatalogException implements Exception {
  const CatalogException(this.message);

  /// Spanish (Peru).
  final String message;

  @override
  String toString() => message;
}

/// What the product form chooses from.
typedef CatalogOptions = ({
  List<ReplicaCategory> categories,
  List<ReplicaBrand> brands,
  List<ReplicaUnit> units,
});

/// A row of the product list.
typedef ProductSummary = ({
  ReplicaProduct product,
  String unitCode,
  int stockMilli,
  bool localStock,
});

/// Stock of one lot (null: without lot): the server's balance plus this
/// device's movements not in it yet.
typedef LotStock = ({ReplicaLot? lot, int qtyMilli});

/// The product sheet.
final class ProductDetail {
  const ProductDetail({
    required this.product,
    required this.unit,
    required this.categoryName,
    required this.brandName,
    required this.cost,
    required this.presentations,
    required this.stock,
    required this.localStock,
    required this.rejectedMessage,
  });

  final ReplicaProduct product;
  final ReplicaUnit unit;
  final String? categoryName;
  final String? brandName;

  /// Show only with `catalog.view_cost`.
  final ReplicaProductCost? cost;
  final List<
    ({ReplicaPresentation presentation, List<ReplicaBarcode> barcodes})
  >
  presentations;
  final List<LotStock> stock;

  /// Some of [stock] has not reached the server's balances yet.
  final bool localStock;

  /// The server rejected its `CreateProduct`: the local copy stays, with why.
  final String? rejectedMessage;

  int get stockMilli => stock.fold(0, (t, s) => t + s.qtyMilli);
}

/// Registers products on this device, also offline (`CreateProduct`,
/// docs/modelo-datos.md §6): the local rows and the outbox command in one
/// transaction. The pull later replaces the local rows with the server's.
class CatalogStore {
  CatalogStore(this.db);

  final AppDatabase db;
  late final _outbox = OutboxStore(db);

  /// The next internal code of this device: its series and a counter
  /// (`T1-000042`), so two devices offline never repeat one.
  Future<String> nextInternalCode() async {
    final (:prefix, digit: _) = await _series();
    return '$prefix-${(await _next('seq.internal_code')).toString().padLeft(6, '0')}';
  }

  /// A new store code `29…` with this device's digit (§3.6), for products
  /// without a manufacturer's barcode.
  Future<String> nextGeneratedBarcode() async {
    final (prefix: _, :digit) = await _series();
    return internalEan13(
      deviceDigit: digit,
      sequence: await _next('seq.barcode'),
    );
  }

  /// The presentation a barcode belongs to here, and its product; null when
  /// no product has it.
  Future<({String presentationId, String productId, String productName})?>
  findBarcode(String code) async {
    final row = await (db.select(db.barcodes).join([
      innerJoin(
        db.productPresentations,
        db.productPresentations.id.equalsExp(db.barcodes.presentationId),
      ),
      innerJoin(
        db.products,
        db.products.id.equalsExp(db.productPresentations.productId),
      ),
    ])..where(db.barcodes.code.equals(code.trim()))).getSingleOrNull();
    if (row == null) return null;
    return (
      presentationId: row.readTable(db.barcodes).presentationId,
      productId: row.readTable(db.products).id,
      productName: row.readTable(db.products).name,
    );
  }

  /// Records [p] by [userId]: product, cost, presentations, barcodes, lots,
  /// initial `initial` movements and the command, all or nothing. Throws
  /// [CatalogException] for a broken rule or a code another product has.
  Future<String> recordCreateProduct(
    CreateProduct p, {
    required String userId,
    DateTime? now,
  }) async {
    if (p.problems() case [final first, ...]) throw CatalogException(first);
    for (final b in p.presentations.expand((x) => x.barcodes)) {
      if (await findBarcode(b.code)
          case (:final productName, productId: _, presentationId: _)?) {
        throw CatalogException('El código ${b.code} ya es de «$productName».');
      }
    }
    final cmd = SyncCommand(
      opId: uuidV7(),
      deviceId: await _outbox.deviceId(),
      userId: userId,
      createdAt: now ?? DateTime.now(),
      type: CreateProduct.type,
      payload: p.toPayload(),
    );
    await db.transaction(() async {
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: p.productId,
              internalCode: p.internalCode,
              name: p.name.trim(),
              description: Value(p.description),
              categoryId: p.categoryId,
              brandId: Value(p.brandId),
              baseUnitId: p.baseUnitId,
              tracksLots: p.tracksLots,
              minStockMilli: p.minStockMilli,
              active: true,
              version: 0,
            ),
          );
      await db
          .into(db.productCosts)
          .insert(
            ProductCostsCompanion.insert(
              productId: p.productId,
              avgCostCents: p.unitCostCents,
              lastCostCents: p.unitCostCents,
              onHandMilli: 0, // the server's comes with the pull
              version: 0,
            ),
          );
      for (final x in p.presentations) {
        await db
            .into(db.productPresentations)
            .insert(
              ProductPresentationsCompanion.insert(
                id: x.id,
                productId: p.productId,
                name: x.name.trim(),
                factorMilli: x.factorMilli,
                isBase: x.isBase,
                retailPriceCents: x.retailPriceCents,
                wholesalePriceCents: Value(x.wholesalePriceCents),
                wholesaleMinMilli: Value(x.wholesaleMinMilli),
                active: true,
                version: 0,
              ),
            );
        for (final b in x.barcodes) {
          await db
              .into(db.barcodes)
              .insert(
                BarcodesCompanion.insert(
                  code: b.code.trim(),
                  presentationId: x.id,
                  format: b.format.name,
                  generated: b.generated,
                  active: true,
                  version: 0,
                ),
              );
        }
      }
      for (final s in p.initialStock) {
        if (s.lotId case final lot?) {
          await db
              .into(db.lots)
              .insertOnConflictUpdate(
                LotsCompanion.insert(
                  id: lot,
                  productId: p.productId,
                  lotCode: s.lotCode!.trim(),
                  expiresOn: Value(s.expiresOn),
                  version: 0,
                ),
              );
        }
        await db
            .into(db.stockMovements)
            .insert(
              StockMovementsCompanion.insert(
                id: s.movementId,
                productId: p.productId,
                lotId: Value(s.lotId),
                qtyMilli: s.qtyMilli,
                type: 'initial',
                opId: cmd.opId,
                userId: userId,
                occurredAt: cmd.createdAt,
              ),
            );
      }
      await _outbox.enqueue(cmd);
    });
    return cmd.opId;
  }

  /// Active categories, brands and units for the product form.
  Future<CatalogOptions> options() async => (
    categories:
        await (db.select(db.categories)
              ..where((c) => c.active)
              ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
            .get(),
    brands:
        await (db.select(db.brands)
              ..where((b) => b.active)
              ..orderBy([(b) => OrderingTerm.asc(b.name)]))
            .get(),
    units: await (db.select(db.units)..where((u) => u.active)).get(),
  );

  /// Products by name, internal code or exact barcode ('' lists them all),
  /// with their local stock.
  Stream<List<ProductSummary>> watchProducts(String query, {int limit = 200}) {
    final q = query.trim();
    final like =
        '%${q.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}')}%';
    return db
        .customSelect(
          'WITH own AS ($_ownLocal) '
          'SELECT p.*, u.code AS unit_code, '
          '  COALESCE((SELECT SUM(b.qty_milli) FROM stock_balances b '
          '            WHERE b.product_id = p.id), 0) '
          '  + COALESCE((SELECT SUM(o.qty) FROM own o '
          '              WHERE o.product_id = p.id), 0) AS stock, '
          '  EXISTS (SELECT 1 FROM own o WHERE o.product_id = p.id) AS local '
          'FROM products p JOIN units u ON u.id = p.base_unit_id '
          r"WHERE ?1 = '' OR p.name LIKE ?2 ESCAPE '\' "
          r"  OR p.internal_code LIKE ?2 ESCAPE '\' "
          '  OR EXISTS (SELECT 1 FROM barcodes c '
          '    JOIN product_presentations x ON x.id = c.presentation_id '
          '    WHERE x.product_id = p.id AND c.code = ?1) '
          'ORDER BY p.name COLLATE NOCASE LIMIT ?3',
          variables: [
            Variable.withString(q),
            Variable.withString(like),
            Variable.withInt(limit),
          ],
          readsFrom: _stockTables,
        )
        .watch()
        .map(
          (rows) => [
            for (final r in rows)
              (
                product: db.products.map(r.data),
                unitCode: r.read<String>('unit_code'),
                stockMilli: r.read<int>('stock'),
                localStock: r.read<bool>('local'),
              ),
          ],
        );
  }

  /// Everything the product sheet shows; null when [productId] is unknown.
  Stream<ProductDetail?> watchProduct(String productId) => db
      .customSelect('SELECT 1', readsFrom: _stockTables)
      .watch()
      .asyncMap((_) => _detail(productId));

  Future<ProductDetail?> _detail(String id) async {
    final p = await (db.select(
      db.products,
    )..where((x) => x.id.equals(id))).getSingleOrNull();
    if (p == null) return null;
    final presentations =
        await (db.select(db.productPresentations)
              ..where((x) => x.productId.equals(id))
              ..orderBy([
                (x) => OrderingTerm.desc(x.isBase),
                (x) => OrderingTerm.asc(x.factorMilli),
              ]))
            .get();
    final ids = [for (final x in presentations) x.id];
    final codes = await (db.select(
      db.barcodes,
    )..where((c) => c.presentationId.isIn(ids))).get();
    final lots = {
      for (final l in await (db.select(
        db.lots,
      )..where((l) => l.productId.equals(id))).get())
        l.id: l,
    };
    final byLot = <String?, int>{};
    for (final b in await (db.select(
      db.stockBalances,
    )..where((b) => b.productId.equals(id))).get()) {
      byLot[b.lotId] = (byLot[b.lotId] ?? 0) + b.qtyMilli;
    }
    final own = await db
        .customSelect(
          'SELECT lot_id, qty FROM ($_ownLocal) WHERE product_id = ?',
          variables: [Variable.withString(id)],
        )
        .get();
    for (final r in own) {
      final lot = r.read<String?>('lot_id');
      byLot[lot] = (byLot[lot] ?? 0) + r.read<int>('qty');
    }
    final rejected = await db
        .customSelect(
          'SELECT message FROM outbox '
          "WHERE type = 'CreateProduct' AND status = 'rejected' "
          r"AND json_extract(payload, '$.product_id') = ?",
          variables: [Variable.withString(id)],
        )
        .getSingleOrNull();
    final brandId = p.brandId;
    return ProductDetail(
      product: p,
      unit: await (db.select(
        db.units,
      )..where((u) => u.id.equals(p.baseUnitId))).getSingle(),
      categoryName: (await (db.select(
        db.categories,
      )..where((c) => c.id.equals(p.categoryId))).getSingleOrNull())?.name,
      brandName: brandId == null
          ? null
          : (await (db.select(
              db.brands,
            )..where((b) => b.id.equals(brandId))).getSingleOrNull())?.name,
      cost: await (db.select(
        db.productCosts,
      )..where((c) => c.productId.equals(id))).getSingleOrNull(),
      presentations: [
        for (final x in presentations)
          (
            presentation: x,
            barcodes: [
              for (final c in codes)
                if (c.presentationId == x.id) c,
            ],
          ),
      ],
      stock: [
        for (final MapEntry(key: lot, value: qty) in byLot.entries)
          (lot: lots[lot], qtyMilli: qty),
      ]..sort(_byExpiry),
      localStock: own.isNotEmpty,
      rejectedMessage: rejected == null
          ? null
          : rejected.read<String?>('message') ?? 'sin motivo',
    );
  }

  /// Soonest expiry first; then lots that never expire; "no lot" last.
  static int _byExpiry(LotStock a, LotStock b) {
    String key(LotStock s) => switch (s.lot) {
      null => '~~',
      final l => l.expiresOn ?? '~${l.lotCode}',
    };
    return key(a).compareTo(key(b));
  }

  late final _stockTables = <ResultSetImplementation<dynamic, dynamic>>{
    db.products,
    db.units,
    db.categories,
    db.brands,
    db.productCosts,
    db.productPresentations,
    db.barcodes,
    db.lots,
    db.stockBalances,
    db.stockMovements,
    db.outbox,
    db.localSettings,
  };

  /// This device's movements the server's balances do not have yet: still
  /// pending, or applied after the last complete pull started (CLAUDE.md §7).
  static const _ownLocal =
      'SELECT m.product_id, m.lot_id, SUM(m.qty_milli) AS qty '
      'FROM stock_movements m JOIN outbox o ON o.op_id = m.op_id '
      "WHERE o.status = 'pending' OR o.applied_seq > COALESCE("
      '  (SELECT CAST(value AS INTEGER) FROM local_settings '
      "   WHERE key = '${ReplicaStore.coversAppliedKey}'), 0) "
      'GROUP BY m.product_id, m.lot_id';

  Future<({String prefix, int digit})> _series() async {
    final id = await _outbox.deviceId();
    final d = await (db.select(
      db.devices,
    )..where((x) => x.id.equals(id))).getSingleOrNull();
    if (d == null) {
      throw const CatalogException(
        'Este equipo aún no tiene su serie. Sincroniza una vez con conexión.',
      );
    }
    return (prefix: d.seriesPrefix, digit: d.barcodeDigit);
  }

  /// A per-device counter in the encrypted database, never reused.
  Future<int> _next(String key) => db.transaction(() async {
    final row = await (db.select(
      db.localSettings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    final next = (int.tryParse(row?.value ?? '') ?? 0) + 1;
    await db
        .into(db.localSettings)
        .insertOnConflictUpdate(
          LocalSettingsCompanion.insert(key: key, value: '$next'),
        );
    return next;
  });
}
