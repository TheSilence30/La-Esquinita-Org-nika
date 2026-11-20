import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// ADR-0004: how long the tablet takes to check a PIN with the server's
// Argon2id parameters. Run in profile mode (debug is several times slower):
//   flutter drive --profile --driver=test_driver/integration_test.dart \
//     --target=integration_test/argon2_timing_test.dart -d <device>
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Argon2id PIN check time', (tester) async {
    const hasher = PasswordHasher();
    final hash = await hasher.hash('482915');
    final ms = <int>[];
    for (var i = 0; i < 5; i++) {
      final w = Stopwatch()..start();
      expect(
        await hasher.verify(i.isEven ? '482915' : '000000', hash),
        i.isEven,
      );
      ms.add(w.elapsedMilliseconds);
    }
    ms.sort();
    binding.reportData = {'argon2id_verify_ms': ms, 'median_ms': ms[2]};
  });
}
