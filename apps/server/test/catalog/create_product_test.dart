// CreateProduct through the push, against a real PostgreSQL. Set
// TEST_DATABASE_URL (CI does); without it these tests are skipped.
@Tags(['db'])
library;

import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/auth/bootstrap.dart';
import 'package:esquinita_server/db.dart';
import 'package:esquinita_server/sync/push_service.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../support/schema.dart';

const _und = '019abb00-0000-7000-8000-000000000001';
const _organicos = '019abb00-0000-7000-8000-000000000011';
const _tablet = '019abd00-0000-7000-8000-0000000000d1';
const _pc = '019abd00-0000-7000-8000-0000000000d2';
const _hasher = PasswordHasher(memoryKib: 64, iterations: 1);

void main() {
  final url = testDatabaseUrl;
  if (url == null) {
    test(
      'CreateProduct against PostgreSQL',
      () {},
      skip: 'set TEST_DATABASE_URL',
    );
    return;
  }

  late Pool<void> db;
  late PushService push;
  late String staff;

  setUpAll(() async {
    db = openPool(url);
    await resetSchema(db);
    await bootstrapUsers(db, {
      'ADMIN_INITIAL_PASSWORD': 'admin-inicial-1',
      'ADMIN_INITIAL_PIN': '1234',
      'STAFF_INITIAL_PASSWORD': 'trabajo-inicial-1',
      'STAFF_INITIAL_PIN': '5678',
    }, hasher: _hasher);
    staff =
        (await db.execute(
              "select id from users where username = 'Trabajo'",
            )).single[0]!
            as String;
    push = PushService(db);
  });

  tearDownAll(() => db.close());

  CreateProduct product({
    String code = '4006381333931',
    bool lots = false,
    String category = _organicos,
    List<InitialStock>? stock,
  }) {
    final n = uuidV7();
    return CreateProduct(
      productId: n,
      internalCode: 'T1-${n.substring(24)}',
      name: 'Quinua orgánica 500 g',
      categoryId: category,
      baseUnitId: _und,
      tracksLots: lots,
      unitCostCents: 850,
      presentations: [
        NewPresentation(
          id: uuidV7(),
          name: 'Unidad',
          factorMilli: 1000,
          isBase: true,
          retailPriceCents: 1200,
          barcodes: [NewBarcode(code: code, format: BarcodeFormat.ean13)],
        ),
        NewPresentation(
          id: uuidV7(),
          name: 'Caja x12',
          factorMilli: 12000,
          isBase: false,
          retailPriceCents: 13200,
        ),
      ],
      initialStock:
          stock ?? [InitialStock(movementId: uuidV7(), qtyMilli: 24000)],
    );
  }

  SyncCommand command(
    Map<String, Object?> payload, {
    String device = _tablet,
    String? user,
  }) => SyncCommand(
    opId: uuidV7(),
    deviceId: device,
    userId: user ?? staff,
    createdAt: DateTime.utc(2026, 11, 25, 15),
    type: CreateProduct.type,
    payload: payload,
  );

  Future<List<Object?>> one(String sql, Map<String, Object?> params) async =>
      (await db.execute(Sql.named(sql), parameters: params)).single.toList();

  test('creates the product with its cost, presentations, code and initial '
      'stock, audited; a resend changes nothing', () async {
    final p = product();
    final c = command(p.toPayload());
    expect((await push.push([c])).single.status, PushStatus.applied);
    final id = {'p': p.productId};
    expect(
      await one(
        'select name, internal_code, category_id, tracks_lots from products '
        'where id = @p:uuid',
        id,
      ),
      [p.name, p.internalCode, _organicos, false],
    );
    expect(
      await one(
        'select avg_cost_cents, last_cost_cents, on_hand_milli '
        'from product_costs where product_id = @p:uuid',
        id,
      ),
      [850, 850, 24000],
    );
    expect(
      await one(
        'select count(*), sum(factor_milli)::int8 from product_presentations '
        'where product_id = @p:uuid',
        id,
      ),
      [2, 13000],
    );
    expect(
      await one(
        "select presentation_id from barcodes where code = '4006381333931'",
        {},
      ),
      [p.presentations.first.id],
    );
    expect(
      await one(
        'select qty_milli, lot_id from stock_balances '
        'where product_id = @p:uuid',
        id,
      ),
      [24000, null],
    );
    expect(
      await one(
        'select type, unit_cost_cents, op_id, user_id from stock_movements '
        'where product_id = @p:uuid',
        id,
      ),
      ['initial', 850, c.opId, staff],
    );
    expect(
      await one(
        "select user_id, device_id, after->>'internal_code' from audit_log "
        "where action = 'catalog.create' and entity_id = @p:text",
        {'p': p.productId},
      ),
      [staff, _tablet, p.internalCode],
    );

    final again = (await push.push([c])).single;
    expect(again.status, PushStatus.duplicate);
    expect(
      await one(
        'select count(*) from stock_movements where product_id = @p:uuid',
        id,
      ),
      [1],
    );
  });

  test('a product with lots gets its lots and one balance per lot', () async {
    InitialStock lot(String code, String? expires, int qty) => InitialStock(
      movementId: uuidV7(),
      qtyMilli: qty,
      lotId: uuidV7(),
      lotCode: code,
      expiresOn: expires,
    );
    final p = product(
      code: '96385074',
      lots: true,
      stock: [lot('L1', '2027-05-30', 10000), lot('L2', null, 2000)],
    );
    expect(
      (await push.push([command(p.toPayload())])).single.status,
      PushStatus.applied,
    );
    final rows = await db.execute(
      Sql.named('''
        select l.lot_code, l.expires_on::text, b.qty_milli
        from lots l join stock_balances b on b.lot_id = l.id
        where l.product_id = @p:uuid order by l.lot_code'''),
      parameters: {'p': p.productId},
    );
    expect(rows.map((r) => r.toList()), [
      ['L1', '2027-05-30', 10000],
      ['L2', null, 2000],
    ]);
    expect(
      await one(
        'select on_hand_milli from product_costs where product_id = @p:uuid',
        {'p': p.productId},
      ),
      [12000],
    );
  });

  test('the same code registered offline on two devices: the second '
      'product is created without it, as a conflict to merge', () async {
    final first = product(code: '036000291452');
    final second = product(code: '036000291452');
    await push.push([command(first.toPayload())]);
    final r = (await push.push([command(second.toPayload(), device: _pc)]))
        .single;
    expect(r.status, PushStatus.conflict);
    expect(r.message, contains('036000291452'));
    expect(
      await one(
        'select count(*) from products where id = @p:uuid',
        {'p': second.productId},
      ),
      [1],
      reason: 'nothing done offline is lost',
    );
    expect(
      await one(
        "select presentation_id from barcodes where code = '036000291452'",
        {},
      ),
      [first.presentations.first.id],
    );
    expect(
      await one(
        "select type, status, details->>'existing_presentation_id', "
        "details->>'new_product_id' from sync_conflicts "
        "where entity_id = '036000291452'",
        {},
      ),
      [
        'duplicate_barcode',
        'open',
        first.presentations.first.id,
        second.productId,
      ],
    );
    expect(
      await one(
        'select status from sync_inbox where op_id = @op:uuid',
        {'op': r.opId},
      ),
      ['conflict'],
    );
  });

  test('refusals leave nothing behind and are kept for a resend: unknown '
      'category, a user without catalog.create, a broken rule', () async {
    final noRole = uuidV7();
    await db.execute(
      Sql.named('''
        insert into users (id, username, full_name, password_hash, version)
        values (@id:uuid, 'sinrol', 'Sin rol', 'x', 0)'''),
      parameters: {'id': noRole},
    );
    final unknown = product(category: '019abd00-0000-7000-8000-00000000ffff');
    final broken = product().toPayload()..['presentations'] = [];
    for (final (c, message) in [
      (command(unknown.toPayload()), 'Categoría desconocida'),
      (command(product().toPayload(), user: noRole), 'no puede registrar'),
      (command(broken), 'presentación base'),
    ]) {
      final r = (await push.push([c])).single;
      expect(r.status, PushStatus.rejected);
      expect(r.message, contains(message));
      final again = (await push.push([c])).single;
      expect(again.originalStatus, PushStatus.rejected);
      expect(again.message, contains(message));
    }
    expect(
      await one(
        'select count(*) from products where id = @p:uuid',
        {'p': unknown.productId},
      ),
      [0],
    );
  });
}
