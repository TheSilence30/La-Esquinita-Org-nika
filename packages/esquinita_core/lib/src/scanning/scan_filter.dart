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
/// Diagnostics (Spike 1): every result reports the gap since the previous
/// detection of the code and the largest gap of the current appearance. A
/// **suspicious re-arm** is an absence between [ScanFilterConfig.rearmAbsence]
/// and [ScanFilterConfig.suspiciousRearmLimit] of a code that was already
/// accepted: short enough that the product probably never left and the
/// detector just dropped out. An acceptance that follows one is flagged as a
/// likely extra read.
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
    this.suspiciousRearmLimit = const Duration(milliseconds: 1000),
  });

  /// Max gap between the two detections that confirm a code.
  final Duration confirmWindow;

  /// Min time between two acceptances of the same code.
  final Duration cooldown;

  /// Min time a code must be out of view before it can be accepted again.
  final Duration rearmAbsence;

  /// Longest absence (inclusive) still counted as a suspicious re-arm.
  /// Diagnostics only: it never changes which reads are accepted.
  final Duration suspiciousRearmLimit;

  ScanFilterConfig copyWith({
    Duration? confirmWindow,
    Duration? cooldown,
    Duration? rearmAbsence,
    Duration? suspiciousRearmLimit,
  }) => ScanFilterConfig(
    confirmWindow: confirmWindow ?? this.confirmWindow,
    cooldown: cooldown ?? this.cooldown,
    rearmAbsence: rearmAbsence ?? this.rearmAbsence,
    suspiciousRearmLimit: suspiciousRearmLimit ?? this.suspiciousRearmLimit,
  );

  /// Throws [ArgumentError] when any value is not positive, or when
  /// [suspiciousRearmLimit] is below [rearmAbsence].
  void validate() {
    for (final (name, value) in [
      ('confirmWindow', confirmWindow),
      ('cooldown', cooldown),
      ('rearmAbsence', rearmAbsence),
      ('suspiciousRearmLimit', suspiciousRearmLimit),
    ]) {
      if (value <= Duration.zero) {
        throw ArgumentError.value(value, name, 'must be positive');
      }
    }
    if (suspiciousRearmLimit < rearmAbsence) {
      throw ArgumentError.value(
        suspiciousRearmLimit,
        'suspiciousRearmLimit',
        'must be at least rearmAbsence',
      );
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
  const ScanResult(
    this.code,
    this.outcome, {
    this.latency,
    this.gap,
    this.maxGap = Duration.zero,
    this.rearmed = false,
    this.suspiciousRearm = false,
    this.afterSuspiciousRearm = false,
  });

  final String code;
  final ScanOutcome outcome;

  /// For accepted reads: time from the first detection of this appearance of
  /// the code until acceptance.
  final Duration? latency;

  /// Time since the previous detection of this code; null when the filter
  /// had no record of it (first sighting, or forgotten long ago).
  final Duration? gap;

  /// Largest gap between consecutive detections in the current appearance
  /// (the absence that started it is not included).
  final Duration maxGap;

  /// This detection started a new appearance of an already accepted code.
  /// Past [ScanFilterConfig.suspiciousRearmLimit] (and the cooldown) the
  /// code may already be forgotten: it then returns as a first sighting
  /// ([gap] null, not re-armed), which is equivalent for acceptance.
  final bool rearmed;

  /// [rearmed] after an absence within the suspicious range.
  final bool suspiciousRearm;

  /// For accepted reads: the appearance began with a suspicious re-arm, so
  /// this read is probably an extra (double) read.
  final bool afterSuspiciousRearm;

  bool get isAccepted => outcome == ScanOutcome.accepted;
}

class _CodeState {
  _CodeState(this.lastSeen) : appearedAt = lastSeen;

  Duration lastSeen;
  Duration appearedAt;
  Duration? lastAcceptedAt;
  bool armed = true;
  bool confirmed = false;
  Duration maxGap = Duration.zero;
  bool suspicious = false;
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
    var rearmed = false;
    var suspicious = false;
    if (gap >= config.rearmAbsence) {
      // The code left the view: this is a new appearance.
      rearmed = state.lastAcceptedAt != null;
      suspicious = rearmed && gap <= config.suspiciousRearmLimit;
      state
        ..armed = true
        ..confirmed = false
        ..appearedAt = at
        ..maxGap = Duration.zero
        ..suspicious = suspicious;
    } else {
      if (gap > state.maxGap) state.maxGap = gap;
      if (gap <= config.confirmWindow) state.confirmed = true;
    }
    state.lastSeen = at;

    ScanResult result(ScanOutcome outcome, {Duration? latency}) => ScanResult(
      code,
      outcome,
      latency: latency,
      gap: gap,
      maxGap: state.maxGap,
      rearmed: rearmed,
      suspiciousRearm: suspicious,
      afterSuspiciousRearm: outcome == ScanOutcome.accepted && state.suspicious,
    );

    if (!state.confirmed) return result(ScanOutcome.awaitingConfirmation);
    if (!state.armed) return result(ScanOutcome.stillVisible);
    final last = state.lastAcceptedAt;
    if (last != null && at - last < config.cooldown) {
      return result(ScanOutcome.coolingDown);
    }

    state
      ..armed = false
      ..lastAcceptedAt = at;
    return result(ScanOutcome.accepted, latency: at - state.appearedAt);
  }

  /// Forgets everything (e.g. when the scan context changes).
  void reset() => _states.clear();

  /// Drops codes that are out of view and past cooldown: they behave exactly
  /// like never-seen codes, so keeping them only costs memory. They are kept
  /// through the suspicious range so a return can still be classified.
  void _prune(Duration now) {
    _states.removeWhere((_, s) {
      final last = s.lastAcceptedAt;
      return now - s.lastSeen > config.suspiciousRearmLimit &&
          (last == null || now - last >= config.cooldown);
    });
  }
}
