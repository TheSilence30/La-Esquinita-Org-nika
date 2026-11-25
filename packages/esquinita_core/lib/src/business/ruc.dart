/// Whether [ruc] is a Peruvian RUC: 11 digits, prefix 10, 15, 16, 17 or 20,
/// and SUNAT's modulo-11 check digit.
bool isValidRuc(String ruc) {
  if (!RegExp(r'^(10|15|16|17|20)[0-9]{9}$').hasMatch(ruc)) return false;
  const weights = [5, 4, 3, 2, 7, 6, 5, 4, 3, 2];
  var sum = 0;
  for (var i = 0; i < 10; i++) {
    sum += int.parse(ruc[i]) * weights[i];
  }
  final check = (11 - sum % 11) % 10; // 10 -> 0, 11 -> 1
  return int.parse(ruc[10]) == check;
}
