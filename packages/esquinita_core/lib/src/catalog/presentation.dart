import '../money/money.dart';

/// [quantity] of a presentation in thousandths of the product's base unit,
/// with the presentation's explicit factor (docs/modelo-datos.md §3.1):
/// 2 × "Caja x12" (factor 12 000) = 24 units; 3 × "Bolsa 500 g" with base
/// kg (factor 500) = 1.5 kg. Rounded to the thousandth, half away from 0.
Quantity toBaseUnits(Quantity quantity, int factorMilli) {
  if (factorMilli <= 0) {
    throw ArgumentError.value(factorMilli, 'factorMilli', 'must be > 0');
  }
  final product = quantity.milli * factorMilli;
  final rounded = (product.abs() + 500) ~/ 1000;
  return Quantity(product < 0 ? -rounded : rounded);
}
