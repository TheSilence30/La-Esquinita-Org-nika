import '../money/money.dart';

/// Price of a weighed item (base unit kg, so [weight] milli = grams):
/// price per kg × weight, rounded to the cent.
Money priceForWeight(Quantity weight, Money pricePerKg) =>
    pricePerKg.times(weight);

/// Grams to weigh so the item costs about [amount] ("S/ 5 de kion"):
/// rounded to the nearest gram. Charge [priceForWeight] of the result, which
/// may differ from [amount] by a fraction of a cent per gram.
Quantity weightForAmount(Money amount, Money pricePerKg) {
  if (pricePerKg.cents <= 0) {
    throw ArgumentError.value(pricePerKg, 'pricePerKg', 'must be > 0');
  }
  if (amount.cents < 0) throw ArgumentError.value(amount, 'amount');
  return Quantity(
    (amount.cents * 1000 + pricePerKg.cents ~/ 2) ~/ pricePerKg.cents,
  );
}
