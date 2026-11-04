import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/foundation.dart';

enum ScanSource { camera, manual }

class ScanRead {
  const ScanRead({
    required this.code,
    required this.at,
    required this.units,
    required this.source,
    this.latency,
  });

  final String code;
  final DateTime at;
  final int units;
  final ScanSource source;

  /// First detection → acceptance (camera only).
  final Duration? latency;
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

  int framesWithCodes = 0;
  int ignoredRepeats = 0;
  DateTime? _firstFrameAt;
  DateTime? _lastFrameAt;

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
    notifyListeners();
  }

  /// Feeds one camera frame. Returns the reads it accepted (usually 0 or 1).
  List<ScanRead> onFrame(List<String> codes, DateTime at) {
    framesWithCodes++;
    _firstFrameAt ??= at;
    _lastFrameAt = at;
    final accepted = <ScanRead>[];
    for (final code in codes.toSet()) {
      final result = _filter.offer(code, at);
      switch (result.outcome) {
        case ScanOutcome.accepted:
          accepted.add(
            _record(code, at, ScanSource.camera, latency: result.latency),
          );
        case ScanOutcome.stillVisible || ScanOutcome.coolingDown:
          ignoredRepeats++;
        case ScanOutcome.awaitingConfirmation:
          break;
      }
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
  }) {
    final read = ScanRead(
      code: code,
      at: at,
      units: _multiplier,
      source: source,
      latency: latency,
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
    _firstFrameAt = null;
    _lastFrameAt = null;
    _filter.reset();
    notifyListeners();
  }

  /// Frames with at least one code per second, while codes were in view.
  double? get detectionFps {
    final first = _firstFrameAt, last = _lastFrameAt;
    if (first == null || last == null || framesWithCodes < 2) return null;
    final ms = last.difference(first).inMilliseconds;
    return ms == 0 ? null : (framesWithCodes - 1) * 1000 / ms;
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
        'rearm_ms=${config.rearmAbsence.inMilliseconds}',
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
      ..writeln('n,code,units,source,at_utc,latency_ms');
    for (final (i, r) in _reads.indexed) {
      buffer.writeln(
        '${i + 1},${_csvField(r.code)},${r.units},${r.source.name},'
        '${r.at.toIso8601String()},${ms(r.latency)}',
      );
    }
    return buffer.toString();
  }

  /// QR codes may contain commas, quotes or newlines.
  static String _csvField(String value) => value.contains(RegExp(r'[",\r\n]'))
      ? '"${value.replaceAll('"', '""')}"'
      : value;
}
