import 'package:esquinita_app/prototype/checkout.dart';
import 'package:esquinita_app/prototype/demo_data.dart';
import 'package:esquinita_app/prototype/demo_store.dart';
import 'package:esquinita_app/prototype/widgets/notice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 17, 15);
  late DemoStore store;

  setUp(() => store = DemoStore(clock: () => today));

  DemoProduct p(String id) => store.catalog.firstWhere((x) => x.id == id);

  group('inventory adjustments (prototype)', () {
    test('add and remove stock, never below zero', () {
      final cafe = p('cafe'); // 18
      store.adjustStock(cafe, 5000, reason: 'Ajuste');
      expect(cafe.totalStockMilli, 23000);
      store.adjustStock(cafe, -30000, reason: 'Ajuste');
      expect(cafe.totalStockMilli, 0);
      expect(
        store.scanForSale('7752345600018').message,
        endsWith('sin stock local'),
      );
    });

    test('lots: adjust one, move expiry, add a new one', () {
      final miel = p('miel');
      final expired = miel.lots.first; // L-2403
      expect(expired.isExpired(today), isTrue);
      store.setLotExpiry(expired, today.add(const Duration(days: 60)));
      expect(miel.sellableStockMilli(today), 15000); // 2 + 3 + 10
      final lot = store.addLot(
        miel,
        'LOT36',
        today.add(const Duration(days: 90)),
        4000,
      );
      expect(miel.lots, contains(lot));
      store.adjustStock(miel, -1000, lot: lot, reason: 'Ajuste');
      expect(lot.qtyMilli, 3000);
      expect(miel.totalStockMilli, 18000);
      expect(store.checkLotCode(miel, 'lot36'), isNotNull); // duplicate
      expect(store.checkLotCode(miel, ' '), isNotNull);
    });

    test('user example: lot34 ×5 + lot36 ×3 = 8, sold FEFO', () {
      final cafe = p('cafe')..stockMilli = 0;
      store
        ..addLot(cafe, 'LOT34', today.add(const Duration(days: 20)), 5000)
        ..addLot(cafe, 'LOT36', today.add(const Duration(days: 80)), 3000);
      expect(cafe.totalStockMilli, 8000);
      store.addToCart(cafe, cafe.base, 6000);
      expect(store.cart.single.lots.map((t) => (t.lot?.code, t.qtyMilli)), [
        ('LOT34', 5000),
        ('LOT36', 1000),
      ]);
    });

    test('stock without lot: kept or moved into the first lot', () {
      final cafe = p('cafe'); // 18 without lot
      store.addLot(cafe, 'A1', today.add(const Duration(days: 30)), 2000);
      expect((cafe.stockMilli, cafe.totalStockMilli), (18000, 20000));
      final chia = p('chia'); // 22 without lot
      final lot = store.addLot(
        chia,
        'B1',
        today.add(const Duration(days: 30)),
        0,
        moveUnlotted: true,
      );
      expect((chia.stockMilli, lot.qtyMilli), (0, 22000));
    });

    test('lots first (FEFO), then stock without lot', () {
      final cafe = p('cafe'); // 18 without lot
      store.addLot(cafe, 'A1', today.add(const Duration(days: 30)), 2000);
      store.addToCart(cafe, cafe.base, 5000);
      expect(store.cart.single.lots.map((t) => (t.lot?.code, t.qtyMilli)), [
        ('A1', 2000),
        (null, 3000),
      ]);
    });

    test('a lot picked by hand goes first; back to automatic', () {
      final miel = p('miel'); // L-2410 ×3 (expires first), L-2502 ×10
      store.addToCart(miel, miel.base, 2000);
      final line = store.cart.single;
      expect(line.lots.single.lot?.code, 'L-2410');
      final later = miel.lots.firstWhere((l) => l.code == 'L-2502');
      store.pinLot(line, lot: later);
      expect(line.lots.single.lot?.code, 'L-2502');
      store.pinLot(line);
      expect(line.lots.single.lot?.code, 'L-2410');
    });

    test('kardex: adjustments, counts and sales are recorded', () {
      final cafe = p('cafe'); // 18
      store
        ..adjustStock(cafe, 2000, reason: 'Recepción de compra')
        ..countStock(cafe, 19000);
      expect(cafe.stockMilli, 19000);
      store.addToCart(cafe, cafe.base, 1000);
      store.confirmSale(
        CheckoutDraft(store.cartTotalCents, mixedAllowed: false),
      );
      final moves = store.movementsOf(cafe);
      expect(moves.first.reason, startsWith('Venta T1-'));
      expect(moves.map((m) => m.deltaMilli), [-1000, -1000, 2000]);
      expect(moves[1].reason, 'Conteo físico');
    });
  });

  group('sales scan traffic light', () {
    test('green: added, quantity accumulates', () {
      final first = store.scanForSale('7750543400036'); // quinua, 46 in stock
      expect(first.level, NoticeLevel.ok);
      expect(first.message, 'Quinua blanca orgánica 1 kg ×1');
      expect(store.scanForSale('7750543400036').message, endsWith('×2'));
      expect(store.cart.single.qtyMilli, 2000);
    });

    test('amber: no local stock (still added) or low stock', () {
      final none = store.scanForSale('7750123400016'); // almendras, 0
      expect(none.level, NoticeLevel.warn);
      expect(none.message, endsWith('sin stock local'));
      final low = store.scanForSale('7755678900011'); // maca, 4 (min 5)
      expect(low.level, NoticeLevel.warn);
      expect(low.message, endsWith('stock bajo'));
      expect(store.cart, hasLength(2));
    });

    test('red: unknown code, nothing added, offers to register it', () {
      final r = store.scanForSale('123456');
      expect(r.level, NoticeLevel.error);
      expect(r.unknownCode, '123456');
      expect(store.cart, isEmpty);
    });

    test('red: all lots expired is blocked', () {
      final miel = p('miel');
      miel.lots.removeWhere((l) => !l.isExpired(today)); // only L-2403 left
      final r = store.scanForSale('7751234500017');
      expect(r.level, NoticeLevel.error);
      expect(store.cart, isEmpty);
    });
  });

  test('FEFO skips the expired lot and takes the one that expires first', () {
    final miel = p('miel');
    expect(store.addToCart(miel, miel.base, 4000), isNull);
    final line = store.cart.single;
    expect(line.lots.map((t) => (t.lot?.code, t.qtyMilli)), [
      ('L-2410', 3000),
      ('L-2502', 1000),
    ]);
    expect(line.stockWarning, isFalse);
  });

  test('selling beyond local stock is allowed with a warning', () {
    final miel = p('miel');
    store.addToCart(miel, miel.base, 20000); // 13 sellable
    expect(store.cart.single.stockWarning, isTrue);
    final almendras = p('almendras'); // 0 in stock
    store.addToCart(almendras, almendras.base, 1000);
    expect(store.cart.last.stockWarning, isTrue);
  });

  test('a product whose lots are all expired cannot be sold', () {
    var now = today;
    final later = DemoStore(clock: () => now);
    final miel = later.catalog.firstWhere((x) => x.id == 'miel');
    now = today.add(const Duration(days: 400)); // every honey lot expired
    expect(later.addToCart(miel, miel.base, 1000), contains('vencidos'));
    expect(later.cart, isEmpty);
  });

  test('wholesale price from the presentation minimum; box factor', () {
    final quinua = p('quinua');
    store.addToCart(quinua, quinua.base, 6000);
    expect(store.cart.single.isWholesale, isTrue);
    expect(store.cart.single.totalCents, 6 * 1300);
    store.addToCart(quinua, quinua.presentations[1], 1000); // Caja x12
    expect(store.cart.last.baseQtyMilli, 12000);
  });

  test('weight line: grams × price per kg', () {
    final kion = p('kion');
    store.addToCart(kion, kion.base, 417);
    expect(store.cart.single.totalCents, 500);
  });

  test('weight line with a price per kg typed in the calculator', () {
    final kion = p('kion');
    store.addToCart(kion, kion.base, 300, perKgCents: 1000);
    final line = store.cart.single;
    expect(line.priceOverrideCents, 1000);
    expect(line.totalCents, 300);
    store.setWeight(line, 500, 1200); // back to the list price
    expect(line.priceOverrideCents, isNull);
    expect(line.totalCents, 600);
  });

  test(
    'confirming moves stock, keeps the sale and only cash in the drawer',
    () {
      final miel = p('miel');
      final before = store.expectedCashCents;
      store.addToCart(miel, miel.base, 2000);
      final draft = CheckoutDraft(store.cartTotalCents, mixedAllowed: true)
        ..choose(PayMethod.yape);
      store.confirmSale(draft);
      expect(miel.lots.firstWhere((l) => l.code == 'L-2410').qtyMilli, 1000);
      expect(store.cart, isEmpty);
      expect(store.expectedCashCents, before); // Yape: not in the drawer
    },
  );
}
