import 'package:esquinita_core/esquinita_core.dart';
import 'package:test/test.dart';

void main() {
  BarcodeFormat? format(String c, {BarcodeFormat? scanned}) =>
      checkBarcode(c, scanned: scanned).format;
  String? error(String c, {BarcodeFormat? scanned}) =>
      checkBarcode(c, scanned: scanned).error;

  test('valid codes of each store format (standard examples)', () {
    expect(format('4006381333931'), BarcodeFormat.ean13);
    expect(format(' 4006381333931 '), BarcodeFormat.ean13, reason: 'trimmed');
    expect(format('96385074'), BarcodeFormat.ean8);
    expect(format('036000291452'), BarcodeFormat.upca);
    expect(format('04252614'), BarcodeFormat.upce);
    expect(format('ABC-123'), BarcodeFormat.code39);
    expect(format('abc-123'), BarcodeFormat.code128);
    expect(
      format('1234567890', scanned: BarcodeFormat.code128),
      BarcodeFormat.code128,
    );
  });

  test('the store\'s own 29… codes are valid EAN-13', () {
    for (final seq in [1, 42, 999999999]) {
      final code = internalEan13(deviceDigit: 3, sequence: seq);
      expect(format(code), BarcodeFormat.ean13, reason: code);
    }
  });

  test('a wrong check digit says which format', () {
    expect(error('4006381333932'), contains('EAN-13'));
    expect(error('036000291453'), contains('UPC-A'));
    expect(error('96385075'), contains('EAN-8'));
    expect(error('04252615', scanned: BarcodeFormat.upce), contains('UPC-E'));
  });

  test('codes damaged by Excel are named as such', () {
    expect(error('7.75E+12'), contains('notación científica'));
    expect(error('7,75E+12'), contains('notación científica'));
    expect(error('7.75e12'), contains('notación científica'));
    // 0012345678905 lost its two leading zeros.
    expect(error('12345678905'), contains('0012345678905'));
  });

  test('other lengths, empty codes and characters a reader never gives', () {
    expect(error('1234567890'), contains('8, 12 o 13'));
    expect(error('   '), 'Falta el código.');
    expect(error('Piña'), contains('caracteres'));
  });

  test('presentations convert with their explicit factor', () {
    expect(toBaseUnits(const Quantity.units(2), 12000), const Quantity(24000));
    expect(toBaseUnits(const Quantity.units(3), 500), const Quantity(1500));
    expect(toBaseUnits(const Quantity(1500), 12000), const Quantity(18000));
    expect(toBaseUnits(const Quantity(-2000), 6000), const Quantity(-12000));
    // A thousandth of a 0.5 g presentation rounds half away from zero.
    expect(toBaseUnits(const Quantity(1), 500), const Quantity(1));
    expect(() => toBaseUnits(const Quantity(1000), 0), throwsArgumentError);
  });
}
