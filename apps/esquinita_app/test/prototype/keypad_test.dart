import 'package:esquinita_app/prototype/widgets/keypad.dart';
import 'package:flutter_test/flutter_test.dart';

String type(String keys, {bool money = true, int max = 99999999}) {
  var text = '';
  for (final k in keys.split('')) {
    text = padInput(text, k, money: money, max: max) ?? text;
  }
  return text;
}

int cents(String keys) => padValue(type(keys), money: true);

void main() {
  group('money: whole soles first, "." for céntimos', () {
    test('25 → S/ 25.00, 350 → S/ 350.00', () {
      expect(cents('25'), 2500);
      expect(cents('350'), 35000);
    });

    test('30.5 → S/ 30.50, 30.55, a third decimal is ignored', () {
      expect(cents('30.5'), 3050);
      expect(cents('30.55'), 3055);
      expect(cents('30.559'), 3055);
    });

    test('.5 → S/ 0.50; a second "." is ignored; no leading zeros', () {
      expect(cents('.5'), 50);
      expect(cents('1.2.3'), 123);
      expect(type('007'), '7');
    });

    test('backspace removes the last character', () {
      expect(cents('25.5⌫'), 2500);
      expect(cents('25.5⌫⌫'), 2500);
      expect(cents('25.5⌫⌫⌫'), 200);
    });

    test('over max is rejected', () {
      expect(padInput('999', '9', money: true, max: 99999), isNull);
      expect(padInput('999', '.', money: true, max: 99999), '999.');
    });

    test('padText round-trips values set from outside', () {
      for (final v in [0, 50, 2500, 2550, 2505, 35000]) {
        expect(padValue(padText(v, money: true), money: true), v);
      }
      expect(padText(2500, money: true), '25');
    });
  });

  group('grams: plain integer', () {
    test('digits and 00; "." not allowed', () {
      expect(padValue(type('5', money: false), money: false), 5);
      expect(padInput('5', '00', money: false, max: 50000), '500');
      expect(padInput('', '00', money: false, max: 50000), isNull);
      expect(padInput('5', '.', money: false, max: 50000), isNull);
    });
  });
}
