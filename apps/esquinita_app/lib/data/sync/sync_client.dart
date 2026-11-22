import 'dart:async';
import 'dart:math';

import 'package:esquinita_core/esquinita_core.dart';

import 'outbox_store.dart';

/// How commands reach the server.
abstract interface class PushTransport {
  /// One result per command. Throws [SyncException] when there is no answer.
  /// [pendingOps]: what the device still has to send after these.
  Future<List<PushResult>> push(
    List<SyncCommand> commands, {
    required int pendingOps,
  });
}

/// No verdict from the server (offline, timeout, server error).
final class SyncException implements Exception {
  const SyncException(this.message, {this.detail, this.needsPassword = false});

  /// Spanish (Peru), for the UI.
  final String message;
  final String? detail;

  /// The saved login no longer works on the server: retrying is useless
  /// until a password login (the PIN still works offline).
  final bool needsPassword;

  @override
  String toString() => 'SyncException($message, $detail)';
}

/// Wait before retry number [failures] (1-based): 5 s, 10 s, 20 s, 40 s,
/// then 60 s at most, so a device back on the Wi-Fi sends within a minute
/// (user, 2026-11-22: no connectivity package).
Duration retryDelay(int failures) => Duration(
  seconds: min(60, 5 * pow(2, min(10, max(0, failures - 1))).toInt()),
);

/// Pushes the outbox in batches and stores each verdict.
class SyncClient {
  SyncClient(
    this.store,
    this.transport, {
    this.batchSize = 100,
    this.batchPause = Duration.zero,
  });

  final OutboxStore store;
  final PushTransport transport;

  /// Commands per request (max 100, the server's limit).
  int batchSize;

  /// Test page only: slows a sync down so it can be interrupted on purpose.
  Duration batchPause;

  /// Sends everything pending ([resendAll]: every command, to check the
  /// server answers `duplicate`). Returns how many got a verdict. On a
  /// failure, earlier batches keep their verdicts and the rest stay pending.
  Future<int> sync({bool resendAll = false}) async {
    final commands = await store.commands(limit: 1 << 30, all: resendAll);
    var done = 0;
    for (var i = 0; i < commands.length; i += batchSize) {
      if (i > 0 && batchPause > Duration.zero) {
        await Future<void>.delayed(batchPause);
      }
      final batch = commands.sublist(i, min(i + batchSize, commands.length));
      final List<PushResult> results;
      try {
        // Pending ones outside this batch (a new operation counts too).
        final others = max(0, await store.pendingCount() - batch.length);
        results = await transport.push(batch, pendingOps: others);
        final sent = [for (final c in batch) c.opId];
        if (results.map((r) => r.opId).join() != sent.join()) {
          throw const SyncException('Respuesta del servidor inválida.');
        }
      } on SyncException catch (e) {
        await store.saveFailure(batch.map((c) => c.opId), e.message);
        rethrow;
      }
      await store.saveResults(results);
      done += results.length;
    }
    return done;
  }
}

/// Runs a sync round (push, then [pull]) on demand, every [interval] while
/// something is pending, and after a failure with a growing wait
/// ([retryDelay]). One round at a time; asked again during one, it runs once
/// more right after, so an operation recorded meanwhile is not left waiting.
class SyncScheduler {
  SyncScheduler(
    this.client, {
    this.pull,
    this.interval = const Duration(seconds: 30),
  });

  final SyncClient client;

  /// Downloads master data after the push (replicas).
  final Future<void> Function()? pull;
  final Duration interval;

  final _state = StreamController<SyncRunState>.broadcast();
  Timer? _timer;
  Future<void>? _running;
  bool _again = false;
  bool _disposed = false;
  int failures = 0;
  SyncException? lastError;

  Stream<SyncRunState> get states => _state.stream;
  bool get running => _running != null;

  void start() => unawaited(syncNow());

  /// Runs now; during a round, schedules one more right after it.
  Future<void> syncNow({bool resendAll = false}) {
    if (_running case final r?) {
      _again = true;
      return r;
    }
    return _running = _run(resendAll).whenComplete(() {
      _running = null;
      if (_again && !_disposed) {
        _again = false;
        start();
      }
    });
  }

  Future<void> _run(bool resendAll) async {
    _timer?.cancel();
    _emit(const SyncRunState(running: true));
    try {
      await client.sync(resendAll: resendAll);
      await pull?.call();
      failures = 0;
      lastError = null;
    } on SyncException catch (e) {
      failures++;
      lastError = e;
    }
    final Duration? wait;
    if (lastError?.needsPassword ?? false) {
      wait = null; // until a password login asks again
    } else if (failures > 0) {
      wait = retryDelay(failures);
    } else {
      wait = await client.store.pendingCount() > 0 ? interval : null;
    }
    if (wait != null && !_disposed) _timer = Timer(wait, start);
    _emit(SyncRunState(running: false, error: lastError, nextIn: wait));
  }

  void _emit(SyncRunState s) {
    if (!_disposed) _state.add(s);
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_state.close());
  }
}

final class SyncRunState {
  const SyncRunState({required this.running, this.error, this.nextIn});

  final bool running;
  final SyncException? error;
  final Duration? nextIn;
}
