import 'dart:io';

import 'package:drift/native.dart';
import 'package:esquinita_app/data/local/catalog_store.dart';
import 'package:esquinita_app/data/local/database.dart';
import 'package:esquinita_app/data/sync/outbox_store.dart';
import 'package:esquinita_app/data/sync/replica_store.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter_test/flutter_test.dart';

const _und = '019abb00-0000-7000-8000-000000000001';
const _cat = '019abb00-0000-7000-8000-000000000011';
final _user = uuidV7();

void main() {
  late AppDatabase db;
  late CatalogStore catalog;
  late ReplicaStore replicas;

  /// A pull answer with [changes] and [cursor].
  Map<String, Object?> page(int cursor, Map<String, Object?> changes) => {
    'cursor': cursor,
    'more': false,
    'changes': changes,
  };

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    catalog = CatalogStore(db);
    replicas = ReplicaStore(db);
    final device = await OutboxStore(db).deviceId();
    await replicas.apply(
      page(10, {
        'devices': [
          {
            'id': device,
            'name': 'Tablet',
            'platform': 'android',
            'series_prefix': 'T2',
            'barcode_digit': 2,
            'active': true,
            'version': 3,
          },
        ],
        'units': [
          {
            'id': _und,
            'code': 'und',
            'name': 'Unidad',
            'kind': 'count',
            'active': true,
            'version': 4,
          },
        ],
        'categories': [
          {
            'id': _cat,
            'name': 'Orgánicos',
            'sort_order': 1,
            'active': true,
            'version': 5,
          },
        ],
      }),
    );
  });

  tearDown(() => db.close());

  CreateProduct quinua(String code, {List<NewPresentation>? presentations}) =>
      CreateProduct(
        productId: uuidV7(),
        internalCode: 'T2-000001',
        name: 'Quinua',
        categoryId: _cat,
        baseUnitId: _und,
        unitCostCents: 850,
        presentations:
            presentations ??
            [
              NewPresentation(
                id: uuidV7(),
                name: 'Unidad',
                factorMilli: 1000,
                isBase: true,
                retailPriceCents: 1200,
                barcodes: [NewBarcode(code: code, format: BarcodeFormat.ean13)],
              ),
            ],
        initialStock: [InitialStock(movementId: uuidV7(), qtyMilli: 24000)],
      );

  test('internal and 29… codes come from this device\'s series and never '
      'repeat, also after a restart', () async {
    expect(await catalog.nextInternalCode(), 'T2-000001');
    expect(await catalog.nextInternalCode(), 'T2-000002');
    final a = await CatalogStore(db).nextGeneratedBarcode(); // new instance
    final b = await catalog.nextGeneratedBarcode();
    expect(a, startsWith('292'));
    expect(a, isNot(b));
    expect(checkBarcode(a).format, BarcodeFormat.ean13);
    expect(checkBarcode(b).format, BarcodeFormat.ean13);
  });

  test('without its series (never synced) it cannot number codes', () async {
    await db.delete(db.devices).go();
    expect(
      catalog.nextInternalCode,
      throwsA(
        isA<CatalogException>().having(
          (e) => e.message,
          'm',
          contains('serie'),
        ),
      ),
    );
  });

  test('records the product and its command together; the movement is '
      'this device\'s, tied to the command', () async {
    final p = quinua('4006381333931');
    final opId = await catalog.recordCreateProduct(p, userId: _user);
    expect((await db.select(db.products).getSingle()).name, 'Quinua');
    expect((await db.select(db.productCosts).getSingle()).avgCostCents, 850);
    expect(await db.select(db.productPresentations).get(), hasLength(1));
    expect((await catalog.findBarcode('4006381333931'))?.productName, 'Quinua');
    final m = await db.select(db.stockMovements).getSingle();
    expect(
      (m.qtyMilli, m.type, m.opId, m.userId),
      (24000, 'initial', opId, _user),
    );
    final cmd = (await OutboxStore(db).pending()).single;
    expect(cmd.type, CreateProduct.type);
    expect(cmd.opId, opId);
    expect(cmd.payload, p.toPayload());
  });

  test('all or nothing: a failure leaves neither rows nor command', () async {
    final id = uuidV7(); // two presentations with the same id
    final p = quinua(
      '4006381333931',
      presentations: [
        NewPresentation(
          id: id,
          name: 'Unidad',
          factorMilli: 1000,
          isBase: true,
          retailPriceCents: 1200,
        ),
        NewPresentation(
          id: id,
          name: 'Caja',
          factorMilli: 12000,
          isBase: false,
          retailPriceCents: 13000,
        ),
      ],
    );
    await expectLater(
      catalog.recordCreateProduct(p, userId: _user),
      throwsA(isA<SqliteException>()),
    );
    expect(await db.select(db.products).get(), isEmpty);
    expect(await db.select(db.stockMovements).get(), isEmpty);
    expect(await OutboxStore(db).pending(), isEmpty);
  });

  test('a code another product has here, or a broken rule, is refused '
      'before writing anything', () async {
    await catalog.recordCreateProduct(quinua('4006381333931'), userId: _user);
    await expectLater(
      catalog.recordCreateProduct(quinua('4006381333931'), userId: _user),
      throwsA(
        isA<CatalogException>().having(
          (e) => e.message,
          'm',
          contains('«Quinua»'),
        ),
      ),
    );
    await expectLater(
      catalog.recordCreateProduct(quinua('4006381333932'), userId: _user),
      throwsA(isA<CatalogException>()),
    );
    expect(await OutboxStore(db).pending(), hasLength(1));
  });

  test('the pull replaces the local copy with the server\'s; balances '
      'without a lot keep one row', () async {
    final p = quinua('4006381333931');
    await catalog.recordCreateProduct(p, userId: _user);
    Map<String, Object?> balance(int qty, int version) => {
      'product_id': p.productId,
      'lot_id': null,
      'qty_milli': qty,
      'version': version,
    };
    await replicas.apply(
      page(20, {
        'products': [
          {
            'id': p.productId,
            'internal_code': p.internalCode,
            'name': 'Quinua orgánica',
            'description': null,
            'category_id': _cat,
            'brand_id': null,
            'base_unit_id': _und,
            'tracks_lots': false,
            'min_stock_milli': 0,
            'active': true,
            'version': 15,
          },
        ],
        'stock_balances': [balance(24000, 16)],
      }),
    );
    await replicas.apply(
      page(21, {
        'stock_balances': [balance(23000, 21)],
      }),
    );
    final product = await db.select(db.products).getSingle();
    expect((product.name, product.version), ('Quinua orgánica', 15));
    final b = await db.select(db.stockBalances).getSingle();
    expect((b.lotId, b.lotKey, b.qtyMilli), (null, '', 23000));
  });

  test('pullAll downloads page after page from the stored cursor', () async {
    final asked = <int>[];
    final pages = [
      {...page(30, {}), 'more': true},
      {...page(40, {}), 'more': true},
      page(41, {}),
    ];
    await replicas.pullAll((since) async {
      asked.add(since);
      return pages[asked.length - 1];
    });
    expect(asked, [10, 30, 40]);
    expect(await replicas.cursor(), 41);
  });

  test('a v2 database (Fase 1) upgrades to v3 and keeps its data', () async {
    final dir = await Directory.systemTemp.createTemp('esq_mig');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/local.db');
    final old = AppDatabase(NativeDatabase(file));
    await old
        .into(old.localSettings)
        .insert(
          LocalSettingsCompanion.insert(key: 'server_url', value: 'http://pc'),
        );
    // Back to what a Fase 1 device has: no catalog tables, user_version 2.
    for (final t in [
      'categories',
      'brands',
      'units',
      'products',
      'product_costs',
      'product_presentations',
      'barcodes',
      'lots',
      'stock_balances',
      'stock_movements',
    ]) {
      await old.customStatement('DROP TABLE $t');
    }
    await old.customStatement('PRAGMA user_version = 2');
    await old.close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    expect(
      (await upgraded.select(upgraded.localSettings).getSingle()).value,
      'http://pc',
    );
    expect(await upgraded.select(upgraded.products).get(), isEmpty);
    final index = await upgraded
        .customSelect(
          "SELECT name FROM sqlite_master WHERE name = 'stock_movements_product'",
        )
        .get();
    expect(index, hasLength(1));
  });
}
