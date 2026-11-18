import 'package:esquinita_app/prototype/checkout.dart';
import 'package:esquinita_app/prototype/demo_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cash: change = tendered − total; not enough cash is refused', () {
    final d = CheckoutDraft(4350, mixedAllowed: false);
    expect(d.problem, isNull); // exact by default
    d.parts.single.tenderedCents = 5000;
    expect(d.changeCents, 650);
    expect(d.drawerCents, 4350);
    d.parts.single.tenderedCents = 4000;
    expect(d.problem, 'El efectivo recibido no alcanza.');
  });

  test('Yape/Plin do not go into the cash drawer', () {
    final d = CheckoutDraft(2590, mixedAllowed: false)..choose(PayMethod.yape);
    expect(d.problem, isNull);
    expect(d.drawerCents, 0);
    expect(d.changeCents, 0);
  });

  test('mixed payments must add up to the total', () {
    final d = CheckoutDraft(10000, mixedAllowed: true);
    d.parts.single.amountCents = 6000;
    d.addPart(PayMethod.yape);
    expect(d.parts.last.amountCents, 4000); // what was missing
    expect(d.problem, isNull);
    expect(d.drawerCents, 6000);
    d.parts.last.amountCents = 3000;
    expect(d.problem, startsWith('Faltan'));
    d.parts.last.amountCents = 5000;
    expect(d.problem, startsWith('Los pagos superan'));
    d.removePart(1);
    expect(d.parts.single.amountCents, 10000);
  });

  test('mixed payments only when the setting allows them', () {
    final d = CheckoutDraft(1000, mixedAllowed: false);
    expect(() => d.addPart(PayMethod.plin), throwsStateError);
  });

  test('credit needs a registered customer and takes no payment', () {
    final d = CheckoutDraft(6720, mixedAllowed: true)..credit = true;
    expect(d.problem, contains('cliente registrado'));
    d.customer = sampleCustomers.first;
    expect(d.problem, isNull);
    expect(d.drawerCents, 0);
  });

  test('quick cash amounts: exact, then bills above the total', () {
    expect(quickCashAmounts(4350), [4350, 5000, 10000, 20000]);
    expect(quickCashAmounts(500), [500, 1000, 2000, 5000]);
  });
}
