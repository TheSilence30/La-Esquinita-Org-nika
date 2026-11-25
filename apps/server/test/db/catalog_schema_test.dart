// Phase 2 schema and seed (docs/modelo-datos.md §2.1–§2.2, §3) against a
// real PostgreSQL. Set TEST_DATABASE_URL (CI does); without it, skipped.
@Tags(['db'])
library;

import 'package:esquinita_server/db.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../support/schema.dart';

const _und = '019abb00-0000-7000-8000-000000000001';
const _organicos = '019abb00-0000-7000-8000-000000000011';
const _user = '019abb00-0000-7000-8000-0000000000a1';
const _device = '019abb00-0000-7000-8000-0000000000d1';

void main() {
  final url = testDatabaseUrl;
  if (url == null) {
    test(
      'catalog schema against PostgreSQL',
      () {},
      skip: 'set TEST_DATABASE_URL',
    );
    return;
  }

  late Pool<void> db;
  var n = 0;

  setUpAll(() async {
    db = openPool(url);
    await resetSchema(db);
    await db.execute(
      Sql.named('''
        insert into users (id, username, full_name, password_hash, version)
        values (@id:uuid, 'u', 'u', 'x', 0)'''),
      parameters: {'id': _user},
    );
  });

  tearDownAll(() => db.close());

  String id() => '019abb00-0000-7000-8000-${(++n).toString().padLeft(12, '0')}';

  Future<String> product({bool lots = false}) async {
    final p = id();
    await db.execute(
      Sql.named(
        '''
        insert into products (id, internal_code, name, category_id,
                              base_unit_id, tracks_lots, version)
        values (@id:uuid, @c:text, 'Quinua', @cat:uuid, @u:uuid, @l:boolean, 0)''',
      ),
      parameters: {
        'id': p,
        'c': 'P$n',
        'cat': _organicos,
        'u': _und,
        'l': lots,
      },
    );
    return p;
  }

  Future<String> presentation(
    String product, {
    String name = 'Unidad',
    int factor = 1000,
    bool base = true,
  }) async {
    final p = id();
    await db.execute(
      Sql.named('''
        insert into product_presentations (id, product_id, name, factor_milli,
                                           is_base, retail_price_cents, version)
        values (@id:uuid, @p:uuid, @n:text, @f:int8, @b:boolean, 1200, 0)'''),
      parameters: {'id': p, 'p': product, 'n': name, 'f': factor, 'b': base},
    );
    return p;
  }

  Matcher violates(String code) => throwsA(
    isA<ServerException>().having((e) => e.code, 'sqlstate', code),
  );
  const unique = '23505';
  const check = '23514';

  test('seed: units und, kg, l and the six example categories', () async {
    expect(
      (await db.execute('select code, kind from units order by code')).map(
        (r) => r.toList(),
      ),
      [
        ['kg', 'weight'],
        ['l', 'volume'],
        ['und', 'count'],
      ],
    );
    expect(
      (await db.execute(
        'select name from categories order by sort_order',
      )).map((r) => r[0]),
      [
        'Orgánicos',
        'Alimentos',
        'Bebidas',
        'Productos naturales',
        'Suplementos',
        'Otros',
      ],
    );
  });

  test('categories and brands: names unique ignoring case', () async {
    expect(
      () => db.execute(
        'insert into categories (id, name, version) values '
        "('019abb00-0000-7000-8000-0000000000c1', 'ORGÁNICOS', 0)",
      ),
      violates(unique),
    );
    await db.execute(
      'insert into brands (id, name, version) values '
      "('019abb00-0000-7000-8000-0000000000b1', 'Inka', 0)",
    );
    expect(
      () => db.execute(
        'insert into brands (id, name, version) values '
        "('019abb00-0000-7000-8000-0000000000b2', 'inka', 0)",
      ),
      violates(unique),
    );
  });

  test('presentations: factor explicit and > 0; one base (factor 1000) per '
      'product; names unique per product', () async {
    final p = await product();
    await presentation(p);
    await presentation(p, name: 'Caja x12', factor: 12000, base: false);
    expect(() => presentation(p, name: 'Otra base'), violates(unique));
    expect(
      () => presentation(p, name: 'caja X12', factor: 6000, base: false),
      violates(unique),
    );
    expect(
      () => presentation(p, name: 'Cero', factor: 0, base: false),
      violates(check),
    );
    final q = await product();
    expect(() => presentation(q, factor: 500), violates(check));
  });

  test('barcodes: unique across every product and presentation', () async {
    final a = await presentation(await product());
    final b = await presentation(await product());
    Future<void> code(String presentation) => db.execute(
      Sql.named('''
        insert into barcodes (code, presentation_id, format, version)
        values ('7750000000001', @p:uuid, 'ean13', 0)'''),
      parameters: {'p': presentation},
    );
    await code(a);
    expect(() => code(b), violates(unique));
  });

  test('lots: unique per product, code and expiry, a null expiry '
      'included', () async {
    final p = await product(lots: true);
    Future<void> lot(String? expires) => db.execute(
      Sql.named('''
        insert into lots (id, product_id, lot_code, expires_on, version)
        values (@id:uuid, @p:uuid, 'L1', @e:date, 0)'''),
      parameters: {
        'id': id(),
        'p': p,
        'e': expires == null ? null : DateTime.parse(expires),
      },
    );
    await lot('2027-05-30');
    await lot(null);
    expect(() => lot('2027-05-30'), violates(unique));
    expect(() => lot(null), violates(unique));
  });

  test('movements: never zero; adjustments and losses need a reason; '
      'balances unique per product and lot (null lot included)', () async {
    final p = await product();
    Future<void> move(String type, int qty, {String? reason}) => db.execute(
      Sql.named('''
        insert into stock_movements (id, product_id, qty_milli, type, reason,
          source_type, source_id, device_id, user_id, occurred_at)
        values (@id:uuid, @p:uuid, @q:int8, @t:text, @r:text, 'product',
                @p:uuid, @d:uuid, @u:uuid, now())'''),
      parameters: {
        'id': id(),
        'p': p,
        'q': qty,
        't': type,
        'r': reason,
        'd': _device,
        'u': _user,
      },
    );
    await move('initial', 24000);
    expect(() => move('initial', 0), violates(check));
    expect(() => move('adjustment', -1000), violates(check));
    expect(() => move('loss', -1000, reason: '  '), violates(check));
    await move('adjustment', -1000, reason: 'Roto');

    final other = await product(); // no movements, so no balance yet
    Future<void> balance() => db.execute(
      Sql.named('''
        insert into stock_balances (product_id, lot_id, qty_milli, version)
        values (@p:uuid, null, 23000, 0)'''),
      parameters: {'p': other},
    );
    await balance();
    expect(balance, violates(unique));
  });

  test('replicated tables take a new version on every change', () async {
    final p = await product();
    Future<int> version() async =>
        (await db.execute(
              Sql.named('select version from products where id = @p:uuid'),
              parameters: {'p': p},
            )).single[0]!
            as int;
    final v0 = await version();
    expect(v0, greaterThan(0), reason: 'the trigger, not the 0 inserted');
    await db.execute(
      Sql.named("update products set name = 'Quinua roja' where id = @p:uuid"),
      parameters: {'p': p},
    );
    expect(await version(), greaterThan(v0));
  });

  test('a loss line takes stock out', () async {
    final adj = id();
    await db.execute(
      Sql.named('''
        insert into stock_adjustments (id, reason, device_id, user_id,
                                       occurred_at)
        values (@id:uuid, 'Merma', @d:uuid, @u:uuid, now())'''),
      parameters: {'id': adj, 'd': _device, 'u': _user},
    );
    final p = await product();
    Future<void> line(int qty) => db.execute(
      Sql.named('''
        insert into stock_adjustment_lines (id, adjustment_id, product_id,
                                            qty_milli, is_loss)
        values (@id:uuid, @a:uuid, @p:uuid, @q:int8, true)'''),
      parameters: {'id': id(), 'a': adj, 'p': p, 'q': qty},
    );
    await line(-2000);
    expect(() => line(2000), violates(check));
  });
}
