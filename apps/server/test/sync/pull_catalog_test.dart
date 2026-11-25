// The catalog in GET /sync/pull and its paging, against a real PostgreSQL.
// Set TEST_DATABASE_URL (CI does); without it these tests are skipped.
@Tags(['db'])
library;

import 'dart:convert';

import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/auth/bootstrap.dart';
import 'package:esquinita_server/db.dart';
import 'package:esquinita_server/sync/pull_service.dart';
import 'package:esquinita_server/sync/push_service.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../support/schema.dart';

const _und = '019abb00-0000-7000-8000-000000000001';
const _cat = '019abb00-0000-7000-8000-000000000012';
const _tablet = '019abe00-0000-7000-8000-0000000000d1';

void main() {
  final url = testDatabaseUrl;
  if (url == null) {
    test(
      'catalog pull against PostgreSQL',
      () {},
      skip: 'set TEST_DATABASE_URL',
    );
    return;
  }

  late Pool<void> db;
  late CreateProduct quinua;

  setUpAll(() async {
    db = openPool(url);
    await resetSchema(db);
    await bootstrapUsers(db, {
      'ADMIN_INITIAL_PASSWORD': 'admin-inicial-1',
      'ADMIN_INITIAL_PIN': '1234',
      'STAFF_INITIAL_PASSWORD': 'trabajo-inicial-1',
      'STAFF_INITIAL_PIN': '5678',
    }, hasher: const PasswordHasher(memoryKib: 64, iterations: 1));
    final staff =
        (await db.execute(
              "select id from users where username = 'Trabajo'",
            )).single[0]!
            as String;
    quinua = CreateProduct(
      productId: uuidV7(),
      internalCode: 'T1-000001',
      name: 'Quinua',
      categoryId: _cat,
      baseUnitId: _und,
      tracksLots: true,
      unitCostCents: 850,
      presentations: [
        NewPresentation(
          id: uuidV7(),
          name: 'Unidad',
          factorMilli: 1000,
          isBase: true,
          retailPriceCents: 1200,
          barcodes: const [
            NewBarcode(code: '4006381333931', format: BarcodeFormat.ean13),
          ],
        ),
      ],
      initialStock: [
        InitialStock(
          movementId: uuidV7(),
          qtyMilli: 5000,
          lotId: uuidV7(),
          lotCode: 'L1',
          expiresOn: '2027-05-30',
        ),
      ],
    );
    await PushService(db).push([
      SyncCommand(
        opId: uuidV7(),
        deviceId: _tablet,
        userId: staff,
        createdAt: DateTime.utc(2026, 11, 25),
        type: CreateProduct.type,
        payload: quinua.toPayload(),
      ),
    ]);
  });

  tearDownAll(() => db.close());

  Map<String, Object?> changes(Map<String, Object?> r) =>
      r['changes']! as Map<String, Object?>;

  test('the catalog comes down with the masters, as plain JSON', () async {
    final r = await PullService(db).pull(0, _tablet);
    expect(r['more'], isFalse);
    final c = changes(r);
    expect((c['units']! as List).length, 3);
    expect((c['categories']! as List).length, 6);
    expect(c['products'], [
      containsPair('internal_code', 'T1-000001'),
    ]);
    expect(c['barcodes'], [containsPair('code', '4006381333931')]);
    expect(c['lots'], [containsPair('expires_on', '2027-05-30')]);
    expect(c['stock_balances'], [containsPair('qty_milli', 5000)]);
    expect(c['product_costs'], [
      allOf(
        containsPair('avg_cost_cents', 850),
        containsPair('on_hand_milli', 5000),
      ),
    ]);
    expect(() => jsonEncode(r), returnsNormally, reason: 'no DateTime inside');
  });

  test('paged: every row exactly once, in version order, and the last page '
      'says no more', () async {
    final whole = await PullService(db).pull(0, _tablet);
    List<String> keys(Map<String, Object?> r) => [
      for (final MapEntry(key: t, value: rows) in changes(r).entries)
        for (final row in rows! as List)
          '$t:${(row as Map<String, Object?>)['version']}',
    ];
    final expected = keys(whole)..sort();

    final paged = PullService(db, pageSize: 7);
    final seen = <String>[];
    var cursor = 0;
    var pages = 0;
    while (true) {
      final r = await paged.pull(cursor, _tablet);
      pages++;
      final page = keys(r);
      expect(page.length, lessThanOrEqualTo(7));
      seen.addAll(page);
      final next = r['cursor']! as int;
      expect(next, greaterThanOrEqualTo(cursor));
      cursor = next;
      if (r['more'] != true) break;
    }
    expect(seen..sort(), expected);
    expect(pages, (expected.length / 7).ceil());
    expect(cursor, whole['cursor']);
    // Nothing new: an empty page.
    final last = await paged.pull(cursor, _tablet);
    expect(keys(last), isEmpty);
    expect(last['more'], isFalse);
  });
}
