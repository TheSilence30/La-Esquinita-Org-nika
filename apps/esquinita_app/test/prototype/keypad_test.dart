import 'package:esquinita_app/prototype/pos/pos_dialogs.dart';
import 'package:esquinita_app/prototype/widgets/keypad.dart';
import 'package:flutter_test/flutter_test.dart';

String type(String keys, {int decimals = 2, int max = 99999999}) {
  var text = '';
  for (final k in keys.split('')) {
    text = padInput(text, k, decimals: decimals, max: max) ?? text;
  }
  return text;
}

int value(String keys, {int decimals = 2}) =>
    padValue(type(keys, decimals: decimals), decimals: decimals);

void main() {
  group('money (2 decimals): whole soles first, "." for céntimos', () {
    test('25 → S/ 25.00, 350 → S/ 350.00', () {
      expect(value('25'), 2500);
      expect(value('350'), 35000);
    });

    test('30.5 → S/ 30.50, 30.55, a third decimal is ignored', () {
      expect(value('30.5'), 3050);
      expect(value('30.55'), 3055);
      expect(value('30.559'), 3055);
    });

    test('.5 → S/ 0.50; a second "." is ignored; no leading zeros', () {
      expect(value('.5'), 50);
      expect(value('1.2.3'), 123);
      expect(type('007'), '7');
    });

    test('backspace removes the last character', () {
      expect(value('25.5⌫'), 2500);
      expect(value('25.5⌫⌫'), 2500);
      expect(value('25.5⌫⌫⌫'), 200);
    });

    test('over max is rejected', () {
      expect(padInput('999', '9', decimals: 2, max: 99999), isNull);
      expect(padInput('999', '.', decimals: 2, max: 99999), '999.');
    });

    test('padText round-trips values set from outside', () {
      for (final v in [0, 50, 2500, 2550, 2505, 35000]) {
        expect(padValue(padText(v, decimals: 2), decimals: 2), v);
      }
      expect(padText(2500, decimals: 2), '25');
    });
  });

  group('kg (3 decimals) → grams', () {
    test('1.5 → 1500 g, 2 → 2000 g, 0.25 → 250 g, 1.2345 → 1234 g', () {
      expect(value('1.5', decimals: 3), 1500);
      expect(value('2', decimals: 3), 2000);
      expect(value('0.25', decimals: 3), 250);
      expect(value('1.2345', decimals: 3), 1234);
    });

    test('max 50 kg; padText round-trips', () {
      expect(padInput('50', '0', decimals: 3, max: 50000), isNull);
      for (final g in [250, 1000, 1500, 2050]) {
        expect(padValue(padText(g, decimals: 3), decimals: 3), g);
      }
    });
  });

  group('grams (0 decimals): plain integer', () {
    test('digits and 00; "." not allowed', () {
      expect(value('5', decimals: 0), 5);
      expect(padInput('5', '00', decimals: 0, max: 50000), '500');
      expect(padInput('', '00', decimals: 0, max: 50000), isNull);
      expect(padInput('5', '.', decimals: 0, max: 50000), isNull);
    });
  });

  test('weightLabel', () {
    expect(weightLabel(300), '300 g');
    expect(weightLabel(1500), '1.500 kg');
    expect(weightLabel(2000), '2 kg');
  });
}
