import 'package:esquinita_core/esquinita_core.dart';

import 'demo_data.dart';

/// Initial payment methods (CLAUDE.md §6.6). No cards.
enum PayMethod {
  cash('Efectivo', affectsCashDrawer: true),
  yape('Yape', needsReference: true),
  plin('Plin', needsReference: true),
  wallet('Billetera digital'),
  transfer('Transferencia', needsReference: true);

  const PayMethod(
    this.label, {
    this.affectsCashDrawer = false,
    this.needsReference = false,
  });

  final String label;
  final bool affectsCashDrawer;

  /// Shows the "N.º de operación" field (optional in the prototype).
  final bool needsReference;
}

class PaymentPart {
  PaymentPart(this.method, this.amountCents);

  PayMethod method;
  int amountCents;

  /// Cash handed over by the customer; change = tendered − amount.
  int? tenderedCents;
  String reference = '';

  int get changeCents => method == PayMethod.cash && tenderedCents != null
      ? tenderedCents! - amountCents
      : 0;
}

/// The payment being built on the checkout screen. Pure logic, no UI.
class CheckoutDraft {
  CheckoutDraft(this.totalCents, {required this.mixedAllowed})
    : parts = [PaymentPart(PayMethod.cash, totalCents)];

  final int totalCents;

  /// Setting `sales.mixed_payments`.
  final bool mixedAllowed;

  /// Credit sale: needs a registered customer, takes no payment and adds
  /// nothing to the cash drawer. Debt tracking comes in Fase 5.
  bool credit = false;
  DemoCustomer? customer;

  final List<PaymentPart> parts;

  bool get isMixed => parts.length > 1;

  /// Single payment: the whole total in [method].
  void choose(PayMethod method) {
    parts
      ..clear()
      ..add(PaymentPart(method, totalCents));
  }

  /// Mixed payments: adds a part for what is still missing.
  void addPart(PayMethod method) {
    if (!mixedAllowed) throw StateError('mixed payments are disabled');
    parts.add(PaymentPart(method, remainingCents.clamp(0, totalCents)));
  }

  void removePart(int index) {
    parts.removeAt(index);
    if (parts.length == 1) parts.single.amountCents = totalCents;
  }

  int get paidCents => parts.fold(0, (s, p) => s + p.amountCents);
  int get remainingCents => totalCents - paidCents;
  int get changeCents => parts.fold(0, (s, p) => s + p.changeCents);

  /// Cents that go into the cash drawer (not Yape/Plin/transfers).
  int get drawerCents => credit
      ? 0
      : parts
            .where((p) => p.method.affectsCashDrawer)
            .fold(0, (s, p) => s + p.amountCents);

  /// Why the sale cannot be confirmed yet, or null when it can.
  String? get problem {
    if (credit) {
      return customer == null
          ? 'Elige un cliente registrado para vender a crédito.'
          : null;
    }
    if (parts.any((p) => p.amountCents <= 0)) {
      return 'Cada medio de pago debe tener un monto.';
    }
    if (remainingCents > 0) {
      return 'Faltan ${Money(remainingCents).format()} por cubrir.';
    }
    if (remainingCents < 0) {
      return 'Los pagos superan el total en ${Money(-remainingCents).format()}.';
    }
    for (final p in parts) {
      if (p.method == PayMethod.cash &&
          p.tenderedCents != null &&
          p.tenderedCents! < p.amountCents) {
        return 'El efectivo recibido no alcanza.';
      }
    }
    return null;
  }
}

/// Quick cash amounts: exact, then the next round bills above the total.
List<int> quickCashAmounts(int totalCents) {
  final options = <int>{totalCents};
  for (final bill in const [1000, 2000, 5000, 10000, 20000]) {
    if (bill > totalCents) options.add(bill);
    if (options.length == 4) break;
  }
  return options.toList();
}
