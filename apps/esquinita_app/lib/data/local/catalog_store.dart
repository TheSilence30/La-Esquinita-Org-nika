import 'package:drift/drift.dart';
import 'package:esquinita_core/esquinita_core.dart';

import '../sync/outbox_store.dart';
import 'database.dart';

/// A product that cannot be recorded; [message] is for the screen.
final class CatalogException implements Exception {
  const CatalogException(this.message);

  /// Spanish (Peru).
  final String message;

  @override
  String toString() => message;
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

  /// The presentation a barcode belongs to here, and its product's name;
  /// null when no product has it.
  Future<({String presentationId, String productName})?> findBarcode(
    String code,
  ) async {
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
          case (:final productName, presentationId: _)?) {
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
