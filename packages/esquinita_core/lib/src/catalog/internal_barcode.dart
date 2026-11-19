/// EAN-13 check digit for the first 12 digits.
int ean13CheckDigit(String twelveDigits) {
  if (!RegExp(r'^\d{12}$').hasMatch(twelveDigits)) {
    throw ArgumentError.value(twelveDigits, 'twelveDigits');
  }
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    sum += int.parse(twelveDigits[i]) * (i.isEven ? 1 : 3);
  }
  return (10 - sum % 10) % 10;
}

/// Store-internal EAN-13: `29` + device digit + 9-digit sequence + check
/// digit (docs/modelo-datos.md §3.6). The device digit keeps two offline
/// devices from issuing the same code; `29` leaves `2x` free for a scale.
String internalEan13({required int deviceDigit, required int sequence}) {
  if (deviceDigit < 0 || deviceDigit > 9) {
    throw RangeError.range(deviceDigit, 0, 9, 'deviceDigit');
  }
  if (sequence < 1 || sequence > 999999999) {
    throw RangeError.range(sequence, 1, 999999999, 'sequence');
  }
  final body = '29$deviceDigit${sequence.toString().padLeft(9, '0')}';
  return '$body${ean13CheckDigit(body)}';
}
