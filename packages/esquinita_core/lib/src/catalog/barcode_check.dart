import 'internal_barcode.dart';

/// Store barcode formats (`barcodes.format`).
enum BarcodeFormat { ean13, ean8, upca, upce, code128, code39 }

/// A valid [format], or the Spanish (Peru) [error] for the screen or the
/// CSV row.
typedef BarcodeCheck = ({BarcodeFormat? format, String? error});

/// Checks a typed, scanned or CSV barcode (ESPECIFICACION §29.2): check
/// digit of EAN-13/EAN-8/UPC-A/UPC-E, characters of Code128/Code39, and
/// codes Excel damaged (scientific notation, lost leading zeros). [scanned]
/// is the format the reader reported, if any; check digits are verified
/// even then.
BarcodeCheck checkBarcode(String raw, {BarcodeFormat? scanned}) {
  final code = raw.trim();
  if (code.isEmpty) return _error('Falta el código.');
  if (RegExp(r'^\d+([.,]\d+)?[eE][+]?\d+$').hasMatch(code)) {
    return _error(
      'El código se dañó en Excel (notación científica, como 7.75E+12). '
      'Pon la columna como texto y vuelve a escribirlo.',
    );
  }
  final digits = RegExp(r'^\d+$').hasMatch(code);
  if (digits && scanned != BarcodeFormat.code128) {
    switch (code.length) {
      case 13:
        return _checked(BarcodeFormat.ean13, _ean13Ok(code), 'EAN-13');
      case 12:
        return _checked(BarcodeFormat.upca, _ean13Ok('0$code'), 'UPC-A');
      case 8:
        if (scanned == BarcodeFormat.upce) {
          return _checked(BarcodeFormat.upce, _upceOk(code), 'UPC-E');
        }
        if (_ean8Ok(code)) return _ok(BarcodeFormat.ean8);
        if (_upceOk(code)) return _ok(BarcodeFormat.upce);
        return _error('Dígito verificador incorrecto (EAN-8).');
    }
    if (code.length < 13 && _ean13Ok(code.padLeft(13, '0'))) {
      return _error(
        'Se perdieron ceros a la izquierda (Excel): debería ser '
        '${code.padLeft(13, '0')}. Pon la columna como texto.',
      );
    }
    if (scanned == null) {
      return _error('Un código numérico de tienda tiene 8, 12 o 13 dígitos.');
    }
  }
  if (scanned != BarcodeFormat.code128 &&
      RegExp(r'^[0-9A-Z .$/+%-]+$').hasMatch(code)) {
    return _ok(BarcodeFormat.code39);
  }
  if (RegExp(r'^[\x20-\x7E]+$').hasMatch(code)) {
    return _ok(BarcodeFormat.code128);
  }
  return _error('El código tiene caracteres que un lector no da (tildes, ñ…).');
}

BarcodeCheck _ok(BarcodeFormat f) => (format: f, error: null);

BarcodeCheck _error(String e) => (format: null, error: e);

BarcodeCheck _checked(BarcodeFormat f, bool ok, String name) =>
    ok ? _ok(f) : _error('Dígito verificador incorrecto ($name).');

bool _ean13Ok(String c) =>
    ean13CheckDigit(c.substring(0, 12)) == int.parse(c[12]);

bool _ean8Ok(String c) {
  var sum = 0;
  for (var i = 0; i < 7; i++) {
    sum += int.parse(c[i]) * (i.isEven ? 3 : 1);
  }
  return (10 - sum % 10) % 10 == int.parse(c[7]);
}

/// UPC-E (number system 0 or 1): its check digit is the one of the UPC-A
/// it expands to.
bool _upceOk(String c) {
  if (c[0] != '0' && c[0] != '1') return false;
  final d = c.substring(1, 7);
  final body = switch (d[5]) {
    '0' || '1' || '2' => '${d.substring(0, 2)}${d[5]}0000${d.substring(2, 5)}',
    '3' => '${d.substring(0, 3)}00000${d.substring(3, 5)}',
    '4' => '${d.substring(0, 4)}00000${d[4]}',
    _ => '${d.substring(0, 5)}0000${d[5]}',
  };
  return ean13CheckDigit('0${c[0]}$body') == int.parse(c[7]);
}
