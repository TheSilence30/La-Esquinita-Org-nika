import 'package:esquinita_app/features/scanning/application/scan_session.dart';
import 'package:flutter_test/flutter_test.dart';

final t0 = DateTime.utc(2026, 11, 4, 12);
DateTime ms(int m) => t0.add(Duration(milliseconds: m));
Duration mono(int m) => Duration(milliseconds: m);

/// One frame at [m] ms on both clocks (they agree unless a test says not).
void frame(ScanSession s, List<String> codes, int m) =>
    s.onFrame(codes, mono(m), ms(m));

/// Holds [code] in view from [from] to [to] ms at ~30 fps.
void hold(ScanSession s, String code, int from, int to) {
  for (var t = from; t <= to; t += 33) {
    frame(s, [code], t);
  }
}

void main() {
  const a = '7750000000011';
  const b = '7750000000028';

  test('product held still for 10 s adds one unit', () {
    final s = ScanSession();
    hold(s, a, 0, 10000);
    expect(s.reads, hasLength(1));
    expect(s.tally, {a: 1});
    expect(s.ignoredRepeats, greaterThan(250));
  });

  test('× cantidad applies to the next read only, then resets to 1', () {
    final s = ScanSession()..multiplier = 6;
    hold(s, a, 0, 100);
    expect(s.tally, {a: 6});
    expect(s.multiplier, 1);
    // Taken away and shown again: one more unit.
    hold(s, a, 2000, 2100);
    expect(s.tally, {a: 7});
    expect(s.totalUnits, 7);
  });

  test('multiplier is clamped to 1..999', () {
    final s = ScanSession()..multiplier = 0;
    expect(s.multiplier, 1);
    s.multiplier = 5000;
    expect(s.multiplier, ScanSession.maxMultiplier);
  });

  test('manual entry bypasses the camera filter and uses the multiplier', () {
    final s = ScanSession()..multiplier = 3;
    s.addManual(' $b ', ms(0));
    s.addManual(b, ms(10));
    expect(s.tally, {b: 4});
    expect(s.addManual('   ', ms(20)), isNull);
  });

  test('latency stats and CSV evidence', () {
    final s = ScanSession();
    hold(s, a, 0, 66); // accepted at 33 → latency 33 ms
    frame(s, [b], 1000);
    frame(s, [b], 1200); // latency 200 ms
    expect(s.averageLatency, const Duration(microseconds: 116500));
    expect(s.latencyPercentile(50), const Duration(milliseconds: 33));
    expect(s.latencyPercentile(95), const Duration(milliseconds: 200));
    final csv = s.toCsv();
    expect(
      csv,
      contains('confirm_ms=300 cooldown_ms=1500 rearm_ms=500 qr=off'),
    );
    s.includeQr = true;
    expect(s.toCsv(), contains('qr=on'));
    expect(csv, contains('n,code,units,source,at_utc,latency_ms'));
    expect(csv, contains('1,$a,1,camera,'));
    expect(csv.trim().split('\n').last, endsWith(',200'));
  });

  test('wall-clock jumps do not affect filtering or frame rate', () {
    final s = ScanSession();
    // Held still for 3 s at 25 fps while the UTC clock jumps 1 h back
    // halfway (NTP sync / manual change). Monotonic time keeps going.
    for (var t = 0; t <= 3000; t += 40) {
      final wall = t < 1500 ? ms(t) : ms(t).subtract(const Duration(hours: 1));
      s.onFrame([a], mono(t), wall);
    }
    expect(s.reads, hasLength(1));
    expect(s.reads.single.at, ms(40)); // read keeps its own UTC time
    expect(s.detectionFps, closeTo(25, 0.01));
  });

  test('CSV quotes codes with commas or quotes', () {
    final s = ScanSession()..addManual('A,"B"', ms(0));
    expect(s.toCsv(), contains('1,"A,""B""",1,manual,'));
  });

  test('clear resets everything', () {
    final s = ScanSession()..multiplier = 4;
    hold(s, a, 0, 500);
    s.clear();
    expect(s.reads, isEmpty);
    expect(s.multiplier, 1);
    expect(s.framesWithCodes, 0);
    hold(s, a, 533, 600);
    expect(s.reads, hasLength(1));
  });
}
