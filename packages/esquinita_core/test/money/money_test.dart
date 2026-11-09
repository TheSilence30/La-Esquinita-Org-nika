import 'package:esquinita_core/esquinita_core.dart';
import 'package:test/test.dart';

void main() {
  group('Money.format', () {
    test('formats PEN with thousands separator', () {
      expect(const Money(123450).format(), 'S/ 1,234.50');
      expect(const Money(123456789).format(), 'S/ 1,234,567.89');
      expect(const Money(5).format(), 'S/ 0.05');
      expect(Money.zero.format(), 'S/ 0.00');
      expect(const Money(-150).format(), '-S/ 1.50');
    });
  });

  group('Money.times', () {
    test('multiplies by whole units', () {
      expect(
        const Money(350).times(const Quantity.units(3)),
        const Money(1050),
      );
    });

    test('multiplies by weight and rounds half up to the cent', () {
      // S/ 12.99 per kg × 0.375 kg = 4.87125 → S/ 4.87
      expect(const Money(1299).times(const Quantity(375)), const Money(487));
      // S/ 0.01 × 0.5 = 0.005 → S/ 0.01
      expect(const Money(1).times(const Quantity(500)), const Money(1));
      expect(const Money(-1).times(const Quantity(500)), const Money(-1));
    });
  });

  group('Quantity', () {
    test('prints units and thousandths', () {
      expect(const Quantity.units(3).toString(), '3');
      expect(const Quantity(1250).toString(), '1.250');
      expect(const Quantity(-5).toString(), '-0.005');
    });

    test('arithmetic', () {
      expect(const Quantity.units(2) * 3, const Quantity.units(6));
      expect(
        const Quantity(1500) + const Quantity(250) - const Quantity(750),
        const Quantity.units(1),
      );
    });
  });
}
