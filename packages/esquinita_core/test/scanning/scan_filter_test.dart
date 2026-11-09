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

  group('diagnostics: max gap and suspicious re-arms', () {
    test('max gap covers the whole appearance, also after acceptance', () {
      final f = ScanFilter();
      f.offer(a, ms(0));
      expect(f.offer(a, ms(100)).maxGap, ms(100)); // accepted here
      expect(f.offer(a, ms(450)).maxGap, ms(350)); // still visible
      expect(f.offer(a, ms(500)).maxGap, ms(350));
    });

    test('re-arm starts a new appearance: its absence is not a gap', () {
      final f = ScanFilter();
      feed(f, a, fromMs: 0, toMs: 99);
      final r = f.offer(a, ms(800)); // 701 ms away, still remembered
      expect(r.rearmed, isTrue);
      expect(r.gap, ms(800 - 99));
      expect(r.maxGap, Duration.zero);
    });

    test('600 ms dropout while held still → suspicious, then extra read', () {
      final f = ScanFilter();
      expect(feed(f, a, fromMs: 0, toMs: 2013), [33]);
      // Dropout 2013 → 2613 (600 ms), product never left.
      final back = f.offer(a, ms(2613));
      expect(back.suspiciousRearm, isTrue);
      final extra = f.offer(a, ms(2646));
      expect(extra.isAccepted, isTrue);
      expect(extra.afterSuspiciousRearm, isTrue);
    });

    test('suspicious re-arm inside cooldown and then gone → no extra read', () {
      final f = ScanFilter();
      expect(feed(f, a, fromMs: 0, toMs: 99), [33]);
      // Back after 601 ms, removed for good before the 1.5 s cooldown.
      final results = [for (var t = 700; t <= 900; t += 33) f.offer(a, ms(t))];
      expect(results.first.suspiciousRearm, isTrue);
      expect(results.where((r) => r.isAccepted), isEmpty);
    });

    test('range is rearmAbsence..limit inclusive', () {
      for (final (absence, expected) in [
        (499, false), // not even a re-arm
        (500, true),
        (1000, true),
        (1001, false),
      ]) {
        final f = ScanFilter();
        feed(f, a, fromMs: 0, toMs: 2013);
        final r = f.offer(a, ms(2013 + absence));
        expect(r.suspiciousRearm, expected, reason: '$absence ms');
        // Past the limit the code is forgotten and returns as new.
        expect(
          r.rearmed,
          absence >= 500 && absence <= 1000,
          reason: '$absence',
        );
        expect(r.gap == null, absence > 1000, reason: '$absence ms');
      }
    });

    test('long absence: forgotten, not suspicious, normal second read', () {
      final f = ScanFilter();
      feed(f, a, fromMs: 0, toMs: 2013);
      final back = f.offer(a, ms(3500));
      expect(back.gap, isNull);
      expect(back.suspiciousRearm, isFalse);
      final read = f.offer(a, ms(3533));
      expect(read.isAccepted, isTrue);
      expect(read.afterSuspiciousRearm, isFalse);
    });

    test('a code never accepted is not re-armed by an absence', () {
      final f = ScanFilter();
      f.offer(a, ms(0));
      expect(f.offer(a, ms(600)).rearmed, isFalse);
    });

    test('custom limit is honored', () {
      final f = ScanFilter(
        const ScanFilterConfig(suspiciousRearmLimit: Duration(seconds: 2)),
      );
      feed(f, a, fromMs: 0, toMs: 2013);
      expect(f.offer(a, ms(2013 + 1800)).suspiciousRearm, isTrue);
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

    test('suspicious limit below rearmAbsence is rejected', () {
      expect(
        () => ScanFilter(
          const ScanFilterConfig(
            suspiciousRearmLimit: Duration(milliseconds: 400),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('copyWith changes only the given value', () {
      final c = const ScanFilterConfig().copyWith(
        suspiciousRearmLimit: const Duration(seconds: 2),
      );
      expect(c.suspiciousRearmLimit, const Duration(seconds: 2));
      expect(c.rearmAbsence, const Duration(milliseconds: 500));
      expect(c.cooldown, const Duration(milliseconds: 1500));
    });

    test('non-positive durations are rejected', () {
      expect(
        () => ScanFilter(const ScanFilterConfig(cooldown: Duration.zero)),
        throwsArgumentError,
      );
    });
  });
}
