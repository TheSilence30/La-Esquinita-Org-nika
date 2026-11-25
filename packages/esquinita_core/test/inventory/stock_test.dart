import 'package:esquinita_core/esquinita_core.dart';
import 'package:test/test.dart';

void main() {
  final today = DateTime(2026, 11, 25);
  LotStock lot(String id, String? expires, int units) => (
    lotId: id,
    expiresOn: expires == null ? null : DateTime.parse(expires),
    balance: Quantity.units(units),
  );
  List<(String?, int)>? split(List<LotStock> lots, int units) => allocateFefo(
    lots,
    Quantity.units(units),
    today,
  )?.takes.map((t) => (t.lotId, t.qty.milli ~/ 1000)).toList();
  bool? warns(List<LotStock> lots, int units) =>
      allocateFefo(lots, Quantity.units(units), today)?.stockWarning;

  test('stock is the sum of its movements', () {
    expect(
      sumMovements([
        const Quantity.units(24),
        const Quantity.units(-3),
        const Quantity(-500),
      ]),
      const Quantity(20500),
    );
    expect(sumMovements([]), Quantity.zero);
  });

  test('FEFO: the soonest expiry first, lots without expiry last', () {
    final lots = [
      lot('sin-vencer', null, 10),
      lot('mayo', '2027-05-30', 5),
      lot('enero', '2027-01-15', 3),
    ];
    expect(split(lots, 2), [('enero', 2)]);
    expect(split(lots, 7), [('enero', 3), ('mayo', 4)]);
    expect(split(lots, 12), [('enero', 3), ('mayo', 5), ('sin-vencer', 4)]);
  });

  test('expired lots are blocked; a lot expiring today still sells', () {
    final lots = [
      lot('vencido', '2026-11-24', 10),
      lot('hoy', '2026-11-25', 2),
    ];
    expect(split(lots, 2), [('hoy', 2)]);
    expect(split([lot('vencido', '2026-11-24', 10)], 1), isNull);
  });

  test('every lot expired: still blocked, even with stock (user, '
      '2026-11-25)', () {
    final lots = [
      lot('vencido', '2026-11-24', 10),
      lot('muy-vencido', '2026-01-01', 5),
    ];
    expect(split(lots, 1), isNull);
    expect(warns(lots, 1), isNull);
  });

  test('a product without any lot yet sells "sin lote", with the stock '
      'warning (user, 2026-11-25)', () {
    expect(split([], 3), [(null, 3)]);
    expect(warns([], 3), isTrue);
  });

  test('the warning only when some lot goes negative', () {
    final lots = [lot('enero', '2027-01-15', 3), lot('mayo', '2027-05-30', 1)];
    expect(warns(lots, 4), isFalse, reason: 'exactly the stock');
    expect(warns(lots, 5), isTrue);
  });

  test('not enough: the rest goes to the lot that expires last, which goes '
      'negative', () {
    final lots = [lot('enero', '2027-01-15', 3), lot('mayo', '2027-05-30', 1)];
    expect(split(lots, 6), [('enero', 3), ('mayo', 3)]);
    // Lots already negative give nothing; the last one takes it all.
    final empty = [
      lot('enero', '2027-01-15', -2),
      lot('mayo', '2027-05-30', 0),
    ];
    expect(split(empty, 4), [('mayo', 4)]);
  });

  test('ties in expiry are resolved the same way on every device', () {
    final lots = [lot('b', '2027-01-15', 1), lot('a', '2027-01-15', 1)];
    expect(split(lots, 1), [('a', 1)]);
  });

  test('the quantity must be positive', () {
    expect(
      () => allocateFefo([lot('a', null, 1)], Quantity.zero, today),
      throwsArgumentError,
    );
  });
}
