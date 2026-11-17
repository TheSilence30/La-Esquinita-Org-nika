import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:esquinita_core/esquinita_core.dart';
import 'package:http/http.dart' as http;

import 'outbox_store.dart';

/// How commands reach the server.
abstract interface class PushTransport {
  /// One result per command. Throws [SyncException] when there is no answer.
  Future<List<PushResult>> push(List<SyncCommand> commands);
}

/// No verdict from the server (offline, timeout, server error).
final class SyncException implements Exception {
  const SyncException(this.message, {this.detail});

  /// Spanish (Peru), for the UI.
  final String message;
  final String? detail;

  @override
  String toString() => 'SyncException($message, $detail)';
}

/// `POST {baseUrl}/sync/push`.
class HttpPushTransport implements PushTransport {
  HttpPushTransport(
    this.baseUrl, {
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _client;

  @override
  Future<List<PushResult>> push(List<SyncCommand> commands) async {
    final http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('$baseUrl/sync/push'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'commands': [for (final c in commands) c.toJson()],
            }),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const SyncException('El servidor no respondió a tiempo.');
    } on Exception catch (e) {
      throw SyncException(
        'Sin conexión con el servidor. Revisa el Wi‑Fi y la dirección.',
        detail: '$e',
      );
    }
    if (res.statusCode != 200) {
      throw SyncException(
        'El servidor respondió con un error (${res.statusCode}).',
        detail: res.body,
      );
    }
    final body = jsonDecode(res.body) as Map<String, Object?>;
    return [
      for (final r in body['results']! as List<Object?>)
        PushResult.fromJson(r! as Map<String, Object?>),
    ];
  }
}

/// Wait before retry number [failures] (1-based): 5 s, 10 s, 20 s … 5 min.
Duration retryDelay(int failures) =>
    Duration(seconds: min(300, 5 * pow(2, max(0, failures - 1)).toInt()));

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
  final int batchSize;

  /// Spike only: slows a sync down so it can be interrupted on purpose.
  final Duration batchPause;

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
        results = await transport.push(batch);
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

/// Runs [SyncClient.sync] at start, every [interval], on demand, and after
/// a failure with a growing wait ([retryDelay]). One run at a time.
class SyncScheduler {
  SyncScheduler(this.client, {this.interval = const Duration(seconds: 30)});

  final SyncClient client;
  final Duration interval;

  final _state = StreamController<SyncRunState>.broadcast();
  Timer? _timer;
  Future<void>? _running;
  int failures = 0;
  SyncException? lastError;

  Stream<SyncRunState> get states => _state.stream;
  bool get running => _running != null;

  void start() => unawaited(syncNow());

  /// Runs now unless a run is in progress (then waits for that one).
  Future<void> syncNow({bool resendAll = false}) =>
      _running ??= _run(resendAll).whenComplete(() => _running = null);

  Future<void> _run(bool resendAll) async {
    _timer?.cancel();
    _state.add(const SyncRunState(running: true));
    try {
      await client.sync(resendAll: resendAll);
      failures = 0;
      lastError = null;
    } on SyncException catch (e) {
      failures++;
      lastError = e;
    }
    final wait = failures == 0 ? interval : retryDelay(failures);
    _timer = Timer(wait, start);
    _state.add(SyncRunState(running: false, error: lastError, nextIn: wait));
  }

  void dispose() {
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
