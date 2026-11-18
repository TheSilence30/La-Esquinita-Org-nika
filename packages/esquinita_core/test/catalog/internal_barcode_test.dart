import 'package:esquinita_core/esquinita_core.dart';
import 'package:test/test.dart';

void main() {
  test('EAN-13 check digit matches known codes', () {
    expect(ean13CheckDigit('775054340003'), 6); // 7750543400036
    expect(ean13CheckDigit('400638133393'), 1); // 4006381333931
  });

  test('internal codes: 29 + device digit + sequence + check digit', () {
    final code = internalEan13(deviceDigit: 1, sequence: 42);
    expect(code, hasLength(13));
    expect(code.substring(0, 12), '291000000042');
    expect(int.parse(code[12]), ean13CheckDigit('291000000042'));
    expect(
      internalEan13(deviceDigit: 1, sequence: 42),
      isNot(internalEan13(deviceDigit: 2, sequence: 42)),
    );
  });

  test('rejects out-of-range input', () {
    expect(() => internalEan13(deviceDigit: 10, sequence: 1), throwsRangeError);
    expect(() => internalEan13(deviceDigit: 1, sequence: 0), throwsRangeError);
    expect(() => ean13CheckDigit('12345'), throwsArgumentError);
  });
}
