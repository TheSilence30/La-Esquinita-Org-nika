/// Turns a raw stream of camera detections into deliberate "reads".
///
/// A camera reports the same barcode many times per second while it stays in
/// view. A read is accepted only when all of these hold:
///
/// 1. **Confirmation**: the code was seen in two detections no more than
///    [ScanFilterConfig.confirmWindow] apart (filters out misreads).
/// 2. **Re-arm**: after being accepted, the code must disappear for at least
///    [ScanFilterConfig.rearmAbsence] before it can count again. A product held
///    still in front of the camera counts once, no matter for how long.
/// 3. **Cooldown**: at least [ScanFilterConfig.cooldown] since the last
///    acceptance of that same code.
///
/// Each code is tracked independently: a different product is accepted as
/// soon as it is confirmed. Timestamps are passed in, so the filter has no
/// clock and is fully deterministic. They must come from a **monotonic**
/// clock (e.g. a `Stopwatch`): wall-clock time can jump (NTP, manual change,
/// time zone) and would break the gap arithmetic.
library;

class ScanFilterConfig {
  const ScanFilterConfig({
    this.confirmWindow = const Duration(milliseconds: 300),
    this.cooldown = const Duration(milliseconds: 1500),
    this.rearmAbsence = const Duration(milliseconds: 500),
  });

  /// Max gap between the two detections that confirm a code.
  final Duration confirmWindow;

  /// Min time between two acceptances of the same code.
  final Duration cooldown;

  /// Min time a code must be out of view before it can be accepted again.
  final Duration rearmAbsence;

  /// Throws [ArgumentError] when any value is not positive.
  void validate() {
    for (final (name, value) in [
      ('confirmWindow', confirmWindow),
      ('cooldown', cooldown),
      ('rearmAbsence', rearmAbsence),
    ]) {
      if (value <= Duration.zero) {
        throw ArgumentError.value(value, name, 'must be positive');
      }
    }
  }
}

enum ScanOutcome {
  /// New read: the caller should act on it (add to cart, count, ...).
  accepted,

  /// First sighting; waiting for a second detection to confirm.
  awaitingConfirmation,

  /// Already accepted and has not left the view long enough.
  stillVisible,

  /// Re-armed, but the cooldown since the last acceptance has not elapsed.
  coolingDown,
}

class ScanResult {
  const ScanResult(this.code, this.outcome, {this.latency});

  final String code;
  final ScanOutcome outcome;

  /// For accepted reads: time from the first detection of this appearance of
  /// the code until acceptance.
  final Duration? latency;

  bool get isAccepted => outcome == ScanOutcome.accepted;
}

class _CodeState {
  _CodeState(this.lastSeen) : appearedAt = lastSeen;

  Duration lastSeen;
  Duration appearedAt;
  Duration? lastAcceptedAt;
  bool armed = true;
  bool confirmed = false;
}

class ScanFilter {
  ScanFilter([this.config = const ScanFilterConfig()]) {
    config.validate();
  }

  final ScanFilterConfig config;
  final Map<String, _CodeState> _states = {};

  /// Feeds one detection of [code] observed at [at], the elapsed time of a
  /// monotonic clock. Timestamps must not go backwards.
  ScanResult offer(String code, Duration at) {
    _prune(at);
    final state = _states[code];
    if (state == null) {
      _states[code] = _CodeState(at);
      return ScanResult(code, ScanOutcome.awaitingConfirmation);
    }

    final gap = at - state.lastSeen;
    if (gap >= config.rearmAbsence) {
      // The code left the view: this is a new appearance.
      state
        ..armed = true
        ..confirmed = false
        ..appearedAt = at;
    } else if (gap <= config.confirmWindow) {
      state.confirmed = true;
    }
    state.lastSeen = at;

    if (!state.confirmed) {
      return ScanResult(code, ScanOutcome.awaitingConfirmation);
    }
    if (!state.armed) {
      return ScanResult(code, ScanOutcome.stillVisible);
    }
    final last = state.lastAcceptedAt;
    if (last != null && at - last < config.cooldown) {
      return ScanResult(code, ScanOutcome.coolingDown);
    }

    state
      ..armed = false
      ..lastAcceptedAt = at;
    return ScanResult(
      code,
      ScanOutcome.accepted,
      latency: at - state.appearedAt,
    );
  }

  /// Forgets everything (e.g. when the scan context changes).
  void reset() => _states.clear();

  /// Drops codes that are out of view and past cooldown: they behave exactly
  /// like never-seen codes, so keeping them only costs memory.
  void _prune(Duration now) {
    _states.removeWhere((_, s) {
      final last = s.lastAcceptedAt;
      return now - s.lastSeen >= config.rearmAbsence &&
          (last == null || now - last >= config.cooldown);
    });
  }
}
