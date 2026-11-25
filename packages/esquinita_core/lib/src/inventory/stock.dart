import '../money/money.dart';

/// Stock is the sum of its movements, never a stored number (CLAUDE.md
/// §6.1).
Quantity sumMovements(Iterable<Quantity> movements) =>
    movements.fold(Quantity.zero, (a, b) => a + b);

/// A lot and its local balance, as FEFO sees it.
typedef LotStock = ({String lotId, DateTime? expiresOn, Quantity balance});

/// How much of a sale item comes out of one lot; [lotId] null: "sin lote".
typedef LotTake = ({String? lotId, Quantity qty});

/// The split, and whether some lot (or "sin lote") goes negative: the sale
/// then carries the stock warning.
typedef FefoSplit = ({List<LotTake> takes, bool stockWarning});

/// Splits [qty] (base unit, > 0) among [lots] first-expired-first-out
/// (docs/modelo-datos.md §3.2):
///
/// 1. expired lots are blocked, with no exception ([today]: Lima's date);
/// 2. the soonest expiry first, lots without expiry last;
/// 3. each lot gives up to its positive balance;
/// 4. what is left goes to the sellable lot that expires last, which goes
///    negative (the sale then carries a stock warning).
///
/// A product without any lot yet sells "sin lote" (null lot, negative
/// balance) with the warning, like a sale without local stock. Null only
/// when it has lots and every one is expired: then it cannot be sold until
/// stock comes in (user, 2026-11-25).
FefoSplit? allocateFefo(Iterable<LotStock> lots, Quantity qty, DateTime today) {
  if (qty.milli <= 0) throw ArgumentError.value(qty, 'qty', 'must be > 0');
  if (lots.isEmpty) {
    return (takes: [(lotId: null, qty: qty)], stockWarning: true);
  }
  final day = DateTime.utc(today.year, today.month, today.day);
  final sellable = [
    for (final l in lots)
      if (l.expiresOn == null || !_date(l.expiresOn!).isBefore(day)) l,
  ];
  if (sellable.isEmpty) return null;
  sellable.sort((a, b) {
    final (x, y) = (a.expiresOn, b.expiresOn);
    final byDate = x == null
        ? (y == null ? 0 : 1)
        : (y == null ? -1 : _date(x).compareTo(_date(y)));
    return byDate != 0 ? byDate : a.lotId.compareTo(b.lotId);
  });
  final takes = <String, int>{};
  var left = qty.milli;
  for (final l in sellable) {
    if (left == 0) break;
    final take = left < l.balance.milli ? left : l.balance.milli;
    if (take > 0) {
      takes[l.lotId] = take;
      left -= take;
    }
  }
  final short = left > 0;
  if (short) {
    final last = sellable.last.lotId;
    takes[last] = (takes[last] ?? 0) + left;
  }
  return (
    takes: [
      for (final MapEntry(:key, :value) in takes.entries)
        (lotId: key, qty: Quantity(value)),
    ],
    stockWarning: short,
  );
}

DateTime _date(DateTime d) => DateTime.utc(d.year, d.month, d.day);
