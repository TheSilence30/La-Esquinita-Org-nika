import 'package:esquinita_app/app/lima_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UTC shown in Lima (UTC-5), also across midnight', () {
    expect(
      limaDateTime(DateTime.utc(2026, 11, 25, 17, 46)),
      '25/11/2026 12:46',
    );
    expect(limaDateTime(DateTime.utc(2026, 1, 1, 3, 5)), '31/12/2025 22:05');
  });
}
