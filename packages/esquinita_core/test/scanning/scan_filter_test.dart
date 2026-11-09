import 'package:esquinita_core/esquinita_core.dart';
import 'package:test/test.dart';

/// Monotonic elapsed time, as a `Stopwatch` reports it.
Duration ms(int millis) => Duration(milliseconds: millis);

/// Feeds [code] every [everyMs] from [fromMs] to [toMs] (inclusive) and
/// returns the timestamps (ms) of accepted reads.
List<int> feed(
  ScanFilter filter,
  String code, {
  required int fromMs,
  required int toMs,
  int everyMs = 33,
}) {
  final accepted = <int>[];
  for (var t = fromMs; t <= toMs; t += everyMs) {
    if (filter.offer(code, ms(t)).isAccepted) accepted.add(t);
  }
  return accepted;
}

void main() {
  const a = '7750000000011';
  const b = '7750000000028';

  group('confirmation (two detections)', () {
    test('a single detection is never accepted', () {
      final f = ScanFilter();
      expect(f.offer(a, ms(0)).outcome, ScanOutcome.awaitingConfirmation);
    });

    test('second detection within 300 ms accepts, with latency', () {
      final f = ScanFilter();
      f.offer(a, ms(0));
      final r = f.offer(a, ms(300));
      expect(r.outcome, ScanOutcome.accepted);
      expect(r.latency, const Duration(milliseconds: 300));
    });

    test('second detection after 300 ms does not confirm', () {
      final f = ScanFilter();
      f.offer(a, ms(0));
      expect(f.offer(a, ms(400)).outcome, ScanOutcome.awaitingConfirmation);
      // A third one close to the second confirms; latency counts from the
      // first detection of this appearance.
      final r = f.offer(a, ms(450));
      expect(r.outcome, ScanOutcome.accepted);
      expect(r.latency, const Duration(milliseconds: 450));
    });
  });

  group('a product held still counts once', () {
    test('10 s in view at ~30 fps → exactly one read', () {
      final f = ScanFilter();
      expect(feed(f, a, fromMs: 0, toMs: 10000), hasLength(1));
    });

    test('10 s in view with jittery detections (gaps < 500 ms) → one read', () {
      final f = ScanFilter();
      const gaps = [40, 120, 480, 60, 499, 250, 33, 400];
      var t = 0;
      var accepted = 0;
      var i = 0;
      while (t <= 10000) {
        if (f.offer(a, ms(t)).isAccepted) accepted++;
        t += gaps[i++ % gaps.length];
      }
      expect(accepted, 1);
    });

    test('while still visible the outcome is stillVisible', () {
      final f = ScanFilter();
      feed(f, a, fromMs: 0, toMs: 2000);
      expect(f.offer(a, ms(2033)).outcome, ScanOutcome.stillVisible);
    });
  });

  group('re-arm after absence (500 ms)', () {
    test('removed ≥ 500 ms and shown again after cooldown → second read', () {
      final f = ScanFilter();
      expect(feed(f, a, fromMs: 0, toMs: 1000), [33]);
      // Out of view 1000 → 2000, then back in view.
      expect(feed(f, a, fromMs: 2000, toMs: 4000), [2033]);
    });

    test('gap shorter than 500 ms does not re-arm', () {
      final f = ScanFilter();
      final first = feed(f, a, fromMs: 0, toMs: 1716);
      expect(first, [33]);
      // 499 ms gap, then visible again well past the cooldown.
      expect(feed(f, a, fromMs: 2215, toMs: 6000), isEmpty);
    });

    test('re-armed inside cooldown waits until 1.5 s, then accepts', () {
      final f = ScanFilter();
      expect(feed(f, a, fromMs: 0, toMs: 99), [33]);
      // Gone 99 → 700 (601 ms), back and kept in view.
      f.offer(a, ms(700));
      expect(f.offer(a, ms(733)).outcome, ScanOutcome.coolingDown);
      final accepted = feed(f, a, fromMs: 766, toMs: 3000);
      expect(accepted, hasLength(1));
      expect(accepted.single, greaterThanOrEqualTo(33 + 1500));
    });
  });

  group('independent codes', () {
    test('a different code is accepted while the first is cooling down', () {
      final f = ScanFilter();
      feed(f, a, fromMs: 0, toMs: 66);
      f.offer(b, ms(100));
      expect(f.offer(b, ms(133)).outcome, ScanOutcome.accepted);
    });

    test('two codes in the same frames are each accepted once', () {
      final f = ScanFilter();
      var accepted = 0;
      for (var t = 0; t <= 5000; t += 33) {
        if (f.offer(a, ms(t)).isAccepted) accepted++;
        if (f.offer(b, ms(t)).isAccepted) accepted++;
      }
      expect(accepted, 2);
    });

    test('reset forgets visible codes', () {
      final f = ScanFilter();
      feed(f, a, fromMs: 0, toMs: 500);
      f.reset();
      expect(feed(f, a, fromMs: 533, toMs: 600), [566]);
    });
  });

  group('configurable timings', () {
    test('custom confirm window, cooldown and absence are honored', () {
      final f = ScanFilter(
        const ScanFilterConfig(
          confirmWindow: Duration(milliseconds: 100),
          cooldown: Duration(seconds: 3),
          rearmAbsence: Duration(seconds: 1),
        ),
      );
      f.offer(a, ms(0));
      expect(f.offer(a, ms(150)).isAccepted, isFalse); // gap > 100 ms
      expect(f.offer(a, ms(200)).isAccepted, isTrue);
      // 800 ms gap: not enough absence with rearmAbsence = 1 s.
      expect(feed(f, a, fromMs: 1000, toMs: 4000, everyMs: 50), isEmpty);
      // 1.2 s gap and past the 3 s cooldown → accepted again.
      expect(feed(f, a, fromMs: 5200, toMs: 5400, everyMs: 50), [5250]);
    });

    test('non-positive durations are rejected', () {
      expect(
        () => ScanFilter(const ScanFilterConfig(cooldown: Duration.zero)),
        throwsArgumentError,
      );
    });
  });
}
