import 'package:esquinita_core/esquinita_core.dart';
import 'package:test/test.dart';

void main() {
  const kion = Money(1200); // S/ 12.00 por kg

  test('weight → price, rounded to the cent', () {
    expect(
      priceForWeight(const Quantity(417), kion),
      const Money(500),
    ); // 5.004
    expect(priceForWeight(const Quantity(1250), kion), const Money(1500));
    expect(priceForWeight(const Quantity(1), kion), const Money(1)); // 1.2 ¢
    expect(priceForWeight(Quantity.zero, kion), Money.zero);
  });

  test('amount → grams, then the charged price', () {
    final g = weightForAmount(const Money(500), kion);
    expect(g, const Quantity(417)); // 416.67 g → 417 g
    expect(priceForWeight(g, kion), const Money(500));

    expect(weightForAmount(const Money(1200), kion), const Quantity(1000));
    expect(weightForAmount(Money.zero, kion), Quantity.zero);
    // S/ 13.50 por kg, S/ 10 → 740.74 g → 741 g → S/ 10.00
    final quinua = weightForAmount(const Money(1000), const Money(1350));
    expect(quinua, const Quantity(741));
    expect(priceForWeight(quinua, const Money(1350)), const Money(1000));
  });

  test('rejects a zero price per kg or a negative amount', () {
    expect(
      () => weightForAmount(const Money(100), Money.zero),
      throwsArgumentError,
    );
    expect(() => weightForAmount(const Money(-1), kion), throwsArgumentError);
  });
}
