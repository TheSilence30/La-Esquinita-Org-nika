import 'package:esquinita_app/prototype/checkout.dart';
import 'package:esquinita_app/prototype/demo_data.dart';
import 'package:esquinita_app/prototype/demo_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 17, 15);
  late DemoStore store;

  setUp(() => store = DemoStore(clock: () => today));

  DemoProduct p(String id) => store.catalog.firstWhere((x) => x.id == id);

  test('FEFO skips the expired lot and takes the one that expires first', () {
    final miel = p('miel');
    expect(store.addToCart(miel, miel.base, 4000), isNull);
    final line = store.cart.single;
    expect(line.lots.map((t) => (t.lot.code, t.qtyMilli)), [
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
