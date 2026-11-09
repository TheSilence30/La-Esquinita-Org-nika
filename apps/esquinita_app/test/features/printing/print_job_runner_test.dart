import 'dart:async';
import 'dart:typed_data';

import 'package:esquinita_app/devices/printer/printer_transport.dart';
import 'package:esquinita_app/features/printing/application/print_job_runner.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTransport implements PrinterTransport {
  bool permission = true;
  bool connected = false;
  int connects = 0;
  final writes = <(int chunk, Duration delay)>[];

  /// Next writes fail with these errors, in order.
  final failures = <PrinterException>[];
  Completer<void>? holdWrite;

  @override
  Future<bool> ensurePermissions() async => permission;

  @override
  Future<List<PrinterDevice>> pairedDevices() async => const [];

  @override
  Future<Duration> connect(String address, {required Duration timeout}) async {
    connects++;
    connected = true;
    return const Duration(milliseconds: 700);
  }

  @override
  Future<WriteResult> write(
    Uint8List bytes, {
    required int chunkSize,
    required Duration chunkDelay,
  }) async {
    writes.add((chunkSize, chunkDelay));
    await holdWrite?.future;
    if (failures.isNotEmpty) {
      connected = false;
      throw failures.removeAt(0);
    }
    return WriteResult(
      bytes: bytes.length,
      elapsed: const Duration(seconds: 1),
    );
  }

  @override
  Future<void> disconnect() async => connected = false;

  @override
  Future<bool> isConnected() async => connected;
}

PrinterException lost({int sent = 0}) =>
    PrinterException(PrinterErrorKind.writeFailed, 'x', bytesSent: sent);

void main() {
  final ticket = Uint8List(1000);
  const addr = 'C0:2B:F3:AB:C9:E2';

  test('connects on the first job and reuses the link afterwards', () async {
    final t = FakeTransport();
    final r = PrintJobRunner(t);
    final first = await r.run(addr, ticket);
    final second = await r.run(addr, ticket);
    expect(t.connects, 1);
    expect(first.connect, const Duration(milliseconds: 700));
    expect(second.connect, isNull);
    expect(second.bytes, 1000);
  });

  test('passes chunk size and pause from the settings', () async {
    final t = FakeTransport();
    await PrintJobRunner(t).run(
      addr,
      ticket,
      settings: const PrintSettings(
        chunkSize: 64,
        chunkDelay: Duration(milliseconds: 30),
      ),
    );
    expect(t.writes.single, (64, const Duration(milliseconds: 30)));
  });

  test(
    'printer switched off since the last job: reconnects and prints',
    () async {
      final t = FakeTransport();
      final r = PrintJobRunner(t);
      await r.run(addr, ticket);
      t.failures.add(lost()); // nothing reached the printer
      final res = await r.run(addr, ticket);
      expect(res.reconnected, isTrue);
      expect(t.connects, 2);
      expect(t.writes, hasLength(3));
    },
  );

  test('never resends a ticket that partly printed', () async {
    final t = FakeTransport();
    final r = PrintJobRunner(t);
    t.failures.add(lost(sent: 512));
    await expectLater(
      r.run(addr, ticket),
      throwsA(isA<PrinterException>().having((e) => e.bytesSent, 'sent', 512)),
    );
    expect(t.writes, hasLength(1));
    // The next job starts with a fresh connection.
    await r.run(addr, ticket);
    expect(t.connects, 2);
  });

  test('retries at most once', () async {
    final t = FakeTransport()..failures.addAll([lost(), lost()]);
    await expectLater(
      PrintJobRunner(t).run(addr, ticket),
      throwsA(isA<PrinterException>()),
    );
    expect(t.writes, hasLength(2));
  });

  test(
    'without the Bluetooth permission it explains how to grant it',
    () async {
      final t = FakeTransport()..permission = false;
      await expectLater(
        PrintJobRunner(t).run(addr, ticket),
        throwsA(
          isA<PrinterException>()
              .having((e) => e.kind, 'kind', PrinterErrorKind.permissionDenied)
              .having((e) => e.message, 'message', contains('Ajustes')),
        ),
      );
      expect(t.connects, 0);
    },
  );

  test('one job at a time', () async {
    final t = FakeTransport()..holdWrite = Completer<void>();
    final r = PrintJobRunner(t);
    final first = r.run(addr, ticket);
    await Future<void>.delayed(Duration.zero);
    expect(r.busy, isTrue);
    await expectLater(
      r.run(addr, ticket),
      throwsA(
        isA<PrinterException>().having(
          (e) => e.kind,
          'kind',
          PrinterErrorKind.busy,
        ),
      ),
    );
    t.holdWrite!.complete();
    await first;
    expect(r.busy, isFalse);
  });

  test('switching printers reconnects', () async {
    final t = FakeTransport();
    final r = PrintJobRunner(t);
    await r.run(addr, ticket);
    await r.run('AA:BB', ticket);
    expect(t.connects, 2);
  });
}
