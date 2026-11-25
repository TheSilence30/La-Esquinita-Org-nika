// Stock projections against a real PostgreSQL (migration
// 20261125000002): every movement updates stock_balances and
// product_costs.on_hand_milli in its own transaction, and on_hand_milli
// always equals the sum of the product's balances (user, 2026-11-25).
// Set TEST_DATABASE_URL (CI does); without it, skipped.
@Tags(['db'])
library;

import 'dart:math';

import 'package:esquinita_server/db.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../support/schema.dart';

const _und = '019abb00-0000-7000-8000-000000000001';
const _cat = '019abb00-0000-7000-8000-000000000011';
const _user = '019abc00-0000-7000-8000-0000000000a1';
const _device = '019abc00-0000-7000-8000-0000000000d1';

void main() {
  final url = testDatabaseUrl;
  if (url == null) {
    test(
      'stock projections against PostgreSQL',
      () {},
      skip: 'set TEST_DATABASE_URL',
    );
    return;
  }

  late Pool<void> db;
  var n = 0;
  final products = <String>[];
  final lotsOf = <String, List<String?>>{}; // null: no lot

  String id() => '019abc00-0000-7000-8000-${(++n).toString().padLeft(12, '0')}';

  setUpAll(() async {
    db = openPool(url);
    await resetSchema(db);
    await db.execute(
      Sql.named('''
        insert into users (id, username, full_name, password_hash, version)
        values (@id:uuid, 'u', 'u', 'x', 0)'''),
      parameters: {'id': _user},
    );
    for (var i = 0; i < 4; i++) {
      final p = id();
      final withLots = i.isEven;
      await db.execute(
        Sql.named('''
          insert into products (id, internal_code, name, category_id,
                                base_unit_id, tracks_lots, version)
          values (@id:uuid, @c:text, @c:text, @cat:uuid, @u:uuid, @l:boolean,
                  0)'''),
        parameters: {
          'id': p,
          'c': 'P$i',
          'cat': _cat,
          'u': _und,
          'l': withLots,
        },
      );
      products.add(p);
      lotsOf[p] = [null];
      if (withLots) {
        for (final (code, expires) in [('L1', '2027-01-15'), ('L2', null)]) {
          final l = id();
          await db.execute(
            Sql.named('''
              insert into lots (id, product_id, lot_code, expires_on, version)
              values (@id:uuid, @p:uuid, @c:text, @e:date, 0)'''),
            parameters: {
              'id': l,
              'p': p,
              'c': code,
              'e': expires == null ? null : DateTime.parse(expires),
            },
          );
          lotsOf[p]!.add(l);
        }
      }
    }
  });

  tearDownAll(() => db.close());

  Future<void> move(
    Session s,
    String product,
    String? lot,
    int qty, {
    String type = 'adjustment',
  }) => s.execute(
    Sql.named('''
      insert into stock_movements (id, product_id, lot_id, qty_milli, type,
        reason, source_type, source_id, device_id, user_id, occurred_at)
      values (@id:uuid, @p:uuid, @l:uuid, @q:int8, @t:text, 'Prueba',
              'adjustment_line', @id:uuid, @d:uuid, @u:uuid, now())'''),
    parameters: {
      'id': id(),
      'p': product,
      'l': lot,
      'q': qty,
      't': type,
      'd': _device,
      'u': _user,
    },
  );

  /// Per product: on_hand_milli, Σ stock_balances, Σ stock_movements; and
  /// per (product, lot) the balance against its movements.
  Future<void> expectConsistent() async {
    final rows = await db.execute('''
      select p.id,
             coalesce(c.on_hand_milli, 0),
             (select coalesce(sum(qty_milli), 0)::int8 from stock_balances b
              where b.product_id = p.id),
             (select coalesce(sum(qty_milli), 0)::int8 from stock_movements m
              where m.product_id = p.id)
      from products p left join product_costs c on c.product_id = p.id''');
    for (final r in rows) {
      expect(r[1], r[2], reason: 'on_hand_milli = Σ balances (${r[0]})');
      expect(r[2], r[3], reason: 'Σ balances = Σ movements (${r[0]})');
    }
    final lots = await db.execute('''
      select b.qty_milli, (select coalesce(sum(m.qty_milli), 0)::int8
                           from stock_movements m
                           where m.product_id = b.product_id
                             and m.lot_id is not distinct from b.lot_id)
      from stock_balances b''');
    for (final r in lots) {
      expect(r[0], r[1], reason: 'each balance = its movements');
    }
  }

  test('300 random movements (in, out, negative stock) keep on_hand_milli '
      'equal to the sum of the balances, after each one', () async {
    final random = Random(7);
    for (var i = 0; i < 300; i++) {
      final p = products[random.nextInt(products.length)];
      final lots = lotsOf[p]!;
      final qty = (random.nextInt(20001) - 10000) | 1; // never 0
      await move(db, p, lots[random.nextInt(lots.length)], qty);
      if (i % 25 == 0) await expectConsistent();
    }
    await expectConsistent();
  });

  Future<int> onHand(String product) async =>
      (await db.execute(
            Sql.named(
              'select on_hand_milli from product_costs '
              'where product_id = @p:uuid',
            ),
            parameters: {'p': product},
          )).single[0]!
          as int;

  test('20 transactions at once on the same product and lot', () async {
    final p = products.first;
    final before = await onHand(p);
    await Future.wait([
      for (var i = 0; i < 20; i++)
        db.runTx((tx) async {
          await move(tx, p, lotsOf[p]![1], 1000);
          await move(tx, p, null, -500);
        }),
    ]);
    final after = await onHand(p);
    expect(after - before, 20 * 500);
    await expectConsistent();
  });

  test('a rolled-back transaction leaves no movement, balance or on_hand '
      'behind', () async {
    final p = products.last;
    Future<List<Object?>> state() async => (await db.execute(
      Sql.named(
        '''
        select (select count(*) from stock_movements where product_id = @p:uuid),
               (select coalesce(sum(qty_milli), 0)::int8 from stock_balances
                where product_id = @p:uuid),
               (select on_hand_milli from product_costs where product_id = @p:uuid)''',
      ),
      parameters: {'p': p},
    )).single.toList();
    final before = await state();
    await expectLater(
      db.runTx((tx) async {
        await move(tx, p, null, 5000, type: 'initial');
        throw StateError('the command failed after its movement');
      }),
      throwsStateError,
    );
    expect(await state(), before);
  });

  test('movements never change: a correction is a new movement', () async {
    final m = (await db.execute('select id from stock_movements limit 1'))
        .single[0];
    Matcher refused() => throwsA(
      isA<ServerException>().having((e) => e.code, 'sqlstate', '23001'),
    );
    expect(
      () => db.execute(
        Sql.named(
          'update stock_movements set qty_milli = 1 where id = @m:uuid',
        ),
        parameters: {'m': m},
      ),
      refused(),
    );
    expect(
      () => db.execute(
        Sql.named('delete from stock_movements where id = @m:uuid'),
        parameters: {'m': m},
      ),
      refused(),
    );
    await expectConsistent();
  });
}
