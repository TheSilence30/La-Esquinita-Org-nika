import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/foundation.dart';

enum ScanSource { camera, manual }

class ScanRead {
  ScanRead({
    required this.code,
    required this.at,
    required this.units,
    required this.source,
    this.latency,
    this.afterSuspiciousRearm = false,
    this.absence,
  });

  final String code;
  final DateTime at;
  final int units;
  final ScanSource source;

  /// First detection → acceptance (camera only).
  final Duration? latency;

  /// Accepted right after a suspicious re-arm: probably an extra read.
  final bool afterSuspiciousRearm;

  /// How long the code was out of view before the appearance that produced
  /// this read (camera only); null when it was first seen in this session.
  /// Tells a detector dropout (~0.5–1 s) from a deliberate re-show (~2 s).
  final Duration? absence;

  /// Largest gap between detections of this appearance (camera only). Keeps
  /// growing after acceptance while the code stays in view.
  Duration? maxGap;
}

/// Spike 1 session: filters camera frames, applies the "× cantidad"
/// multiplier, aggregates a cart-like tally per code and collects metrics.
class ScanSession extends ChangeNotifier {
  ScanSession({ScanFilterConfig config = const ScanFilterConfig()})
    : _filter = ScanFilter(config);

  static const maxMultiplier = 999;

  ScanFilter _filter;
  ScanFilterConfig get config => _filter.config;

  final List<ScanRead> _reads = [];
  List<ScanRead> get reads => List.unmodifiable(_reads);

  /// Units per code, in first-read order (like cart lines).
  final Map<String, int> _tally = {};
  Map<String, int> get tally => Map.unmodifiable(_tally);

  int _multiplier = 1;

  /// Units the next accepted read adds. Resets to 1 after use.
  int get multiplier => _multiplier;

  bool _includeQr = false;

  /// Whether the camera decodes QR codes. Off by default (sales use retail
  /// barcodes only); recorded in the CSV.
  bool get includeQr => _includeQr;
  set includeQr(bool value) {
    if (value == _includeQr) return;
    _includeQr = value;
    notifyListeners();
  }

  int framesWithCodes = 0;
  int ignoredRepeats = 0;

  /// Absences in the suspicious range (see `ScanFilter`), extra read or not.
  int suspiciousRearms = 0;

  /// Reads accepted right after a suspicious re-arm.
  int extraReads = 0;

  /// The read of each code's current appearance, whose max gap is updated.
  final Map<String, ScanRead> _openReads = {};

  // Kept here, not in the filter: the filter forgets codes after the
  // suspicious limit, but the CSV needs every absence measured exactly.
  final Map<String, Duration> _lastSeen = {};
  final Map<String, Duration?> _absence = {};

  // Monotonic: frame rate must not be skewed by wall-clock jumps. Only
  // intervals shorter than rearmAbsence count (a code stayed in view), so
  // idle time between products does not dilute the rate.
  Duration? _lastFrameAt;
  int _inViewIntervals = 0;
  Duration _inViewTime = Duration.zero;

  int get totalUnits => _tally.values.fold(0, (a, b) => a + b);

  set multiplier(int value) {
    final clamped = value.clamp(1, maxMultiplier);
    if (clamped == _multiplier) return;
    _multiplier = clamped;
    notifyListeners();
  }

  /// Applies new timings. Starts a fresh filter (codes in view are forgotten).
  void updateConfig(ScanFilterConfig config) {
    _filter = ScanFilter(config);
    _openReads.clear();
    notifyListeners();
  }

  /// Feeds one camera frame. [elapsed] comes from a monotonic clock and drives
  /// the filter; [atUtc] is only recorded as the wall-clock time of each read.
  /// Returns the reads it accepted (usually 0 or 1).
  List<ScanRead> onFrame(List<String> codes, Duration elapsed, DateTime atUtc) {
    framesWithCodes++;
    final last = _lastFrameAt;
    if (last != null && elapsed - last < config.rearmAbsence) {
      _inViewIntervals++;
      _inViewTime += elapsed - last;
    }
    _lastFrameAt = elapsed;
    final accepted = <ScanRead>[];
    for (final code in codes.toSet()) {
      final prev = _lastSeen[code];
      final away = prev == null ? null : elapsed - prev;
      // Same rule as the filter: an absence ≥ rearmAbsence starts a new
      // appearance.
      if (away == null || away >= config.rearmAbsence) _absence[code] = away;
      _lastSeen[code] = elapsed;

      final result = _filter.offer(code, elapsed);
      // A new appearance closes the previous read's gap tracking.
      if (result.gap == null || result.rearmed) _openReads.remove(code);
      if (result.suspiciousRearm) suspiciousRearms++;
      switch (result.outcome) {
        case ScanOutcome.accepted:
          final read = _record(
            code,
            atUtc,
            ScanSource.camera,
            latency: result.latency,
            afterSuspiciousRearm: result.afterSuspiciousRearm,
            absence: _absence[code],
          );
          if (read.afterSuspiciousRearm) extraReads++;
          _openReads[code] = read;
          accepted.add(read);
        case ScanOutcome.stillVisible || ScanOutcome.coolingDown:
          ignoredRepeats++;
        case ScanOutcome.awaitingConfirmation:
          break;
      }
      _openReads[code]?.maxGap = result.maxGap;
    }
    notifyListeners();
    return accepted;
  }

  /// Typed code or keyboard-wedge reader: deliberate, so no camera filter.
  ScanRead? addManual(String code, DateTime at) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    final read = _record(trimmed, at, ScanSource.manual);
    notifyListeners();
    return read;
  }

  ScanRead _record(
    String code,
    DateTime at,
    ScanSource source, {
    Duration? latency,
    bool afterSuspiciousRearm = false,
    Duration? absence,
  }) {
    final read = ScanRead(
      code: code,
      at: at,
      units: _multiplier,
      source: source,
      latency: latency,
      afterSuspiciousRearm: afterSuspiciousRearm,
      absence: absence,
    );
    _reads.add(read);
    _tally[code] = (_tally[code] ?? 0) + _multiplier;
    _multiplier = 1;
    return read;
  }

  void clear() {
    _reads.clear();
    _tally.clear();
    _multiplier = 1;
    framesWithCodes = 0;
    ignoredRepeats = 0;
    suspiciousRearms = 0;
    extraReads = 0;
    _openReads.clear();
    _lastSeen.clear();
    _absence.clear();
    _lastFrameAt = null;
    _inViewIntervals = 0;
    _inViewTime = Duration.zero;
    _filter.reset();
    notifyListeners();
  }

  /// Frames with at least one code per second, counting only the time a code
  /// was in view.
  double? get detectionFps {
    final us = _inViewTime.inMicroseconds;
    return us == 0 ? null : _inViewIntervals * 1e6 / us;
  }

  /// Largest gap of any camera read, or of [code]'s reads when given.
  Duration? maxGap([String? code]) {
    Duration? max;
    for (final r in _reads) {
      final g = r.maxGap;
      if (g == null || (code != null && r.code != code)) continue;
      if (max == null || g > max) max = g;
    }
    return max;
  }

  List<Duration> get _latencies => [for (final r in _reads) ?r.latency]..sort();

  Duration? get averageLatency {
    final l = _latencies;
    if (l.isEmpty) return null;
    return l.reduce((a, b) => a + b) ~/ l.length;
  }

  /// Nearest-rank percentile, [p] in (0, 100].
  Duration? latencyPercentile(int p) {
    final l = _latencies;
    if (l.isEmpty) return null;
    final rank = (p / 100 * l.length).ceil().clamp(1, l.length);
    return l[rank - 1];
  }

  /// Evidence for docs/informes/fase-0.md.
  String toCsv() {
    String ms(Duration? d) => d?.inMilliseconds.toString() ?? '';
    final fps = detectionFps;
    final buffer = StringBuffer()
      ..writeln('# Spike 1 — escaneo con cámara')
      ..writeln(
        '# confirm_ms=${config.confirmWindow.inMilliseconds} '
        'cooldown_ms=${config.cooldown.inMilliseconds} '
        'rearm_ms=${config.rearmAbsence.inMilliseconds} '
        'suspicious_ms=${config.suspiciousRearmLimit.inMilliseconds} '
        'qr=${_includeQr ? 'on' : 'off'}',
      )
      ..writeln(
        '# reads=${_reads.length} units=$totalUnits '
        'ignored_repeats=$ignoredRepeats frames=$framesWithCodes '
        'fps=${fps?.toStringAsFixed(1) ?? ''}',
      )
      ..writeln(
        '# latency_ms avg=${ms(averageLatency)} '
        'p50=${ms(latencyPercentile(50))} p95=${ms(latencyPercentile(95))}',
      )
      ..writeln(
        '# max_gap_ms=${ms(maxGap())} suspicious_rearms=$suspiciousRearms '
        'extra_reads=$extraReads',
      )
      ..writeln(
        'n,code,units,source,at_utc,latency_ms,max_gap_ms,'
        'after_suspicious_rearm,absence_ms',
      );
    for (final (i, r) in _reads.indexed) {
      buffer.writeln(
        '${i + 1},${_csvField(r.code)},${r.units},${r.source.name},'
        '${r.at.toIso8601String()},${ms(r.latency)},${ms(r.maxGap)},'
        '${r.afterSuspiciousRearm ? 1 : 0},${ms(r.absence)}',
      );
    }
    return buffer.toString();
  }

  /// QR codes may contain commas, quotes or newlines.
  static String _csvField(String value) => value.contains(RegExp(r'[",\r\n]'))
      ? '"${value.replaceAll('"', '""')}"'
      : value;
}
