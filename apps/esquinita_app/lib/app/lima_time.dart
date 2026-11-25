/// "25/11/2026 12:46" in America/Lima, whatever the device's time zone.
/// shortcut: Lima is a fixed UTC-5 (no daylight saving since 1994); use the
/// `timezone` package if Peru ever brings it back.
String limaDateTime(DateTime at) {
  final t = at.toUtc().subtract(const Duration(hours: 5));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
}
