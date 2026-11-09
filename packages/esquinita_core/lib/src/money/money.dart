/// Amount of money in PEN, stored as integer cents. Never use `double`.
final class Money implements Comparable<Money> {
  const Money(this.cents);

  const Money.soles(int soles) : cents = soles * 100;

  static const zero = Money(0);

  final int cents;

  Money operator +(Money other) => Money(cents + other.cents);
  Money operator -(Money other) => Money(cents - other.cents);
  Money operator -() => Money(-cents);

  /// Price × quantity, rounded half away from zero to the cent.
  Money times(Quantity quantity) {
    final milliCents = cents * quantity.milli;
    final rounded = (milliCents.abs() + 500) ~/ 1000;
    return Money(milliCents < 0 ? -rounded : rounded);
  }

  /// `S/ 1,234.50` (negative: `-S/ 1,234.50`).
  String format() {
    final abs = cents.abs();
    final grouped = (abs ~/ 100).toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final centsPart = (abs % 100).toString().padLeft(2, '0');
    final sign = cents < 0 ? '-' : '';
    return '${sign}S/ $grouped.$centsPart';
  }

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => format();
}

/// Quantity in thousandths of the base unit (supports weight in kg).
final class Quantity implements Comparable<Quantity> {
  const Quantity(this.milli);

  const Quantity.units(int units) : milli = units * 1000;

  static const zero = Quantity(0);

  final int milli;

  Quantity operator +(Quantity other) => Quantity(milli + other.milli);
  Quantity operator -(Quantity other) => Quantity(milli - other.milli);
  Quantity operator *(int factor) => Quantity(milli * factor);

  @override
  int compareTo(Quantity other) => milli.compareTo(other.milli);

  @override
  bool operator ==(Object other) => other is Quantity && other.milli == milli;

  @override
  int get hashCode => milli.hashCode;

  /// `3` for whole units, `1.250` otherwise.
  @override
  String toString() {
    final sign = milli < 0 ? '-' : '';
    final whole = milli.abs() ~/ 1000;
    final frac = milli.abs() % 1000;
    if (frac == 0) return '$sign$whole';
    return '$sign$whole.${frac.toString().padLeft(3, '0')}';
  }
}
