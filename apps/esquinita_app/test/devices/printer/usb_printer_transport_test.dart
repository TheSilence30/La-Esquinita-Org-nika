import 'dart:typed_data';

import 'package:esquinita_app/devices/printer/printer_transport.dart';
import 'package:esquinita_app/devices/printer/usb_printer_transport.dart';
import 'package:esquinita_app/features/printing/application/print_job_runner.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simulated USB stack: a cable that can be unplugged and re-plugged into
/// another port (new device path, same hardware id).
class FakeUsbApi implements UsbPrintApi {
  FakeUsbApi() {
    plug('usb#vid_0483&pid_5743#5&6542b1d&0&2');
  }

  final printers = <UsbPrinterInfo>[];
  final opened = <String>[];
  final writes = <(int, int)>[]; // (handle, bytes)
  final received = BytesBuilder();
  final _live = <int>{};
  var _nextHandle = 100;

  /// Accept only this many bytes per write before failing (null = all).
  int? failAfter;
  bool openFails = false;

  void plug(String path) => printers.add(
    UsbPrinterInfo(
      name: 'Printer POS-58-P504A',
      hardwareId: etermaUsbHardwareId,
      devicePath: path,
    ),
  );

  void unplug() {
    printers.clear();
    _live.clear(); // open handles die with the device
  }

  @override
  Future<List<UsbPrinterInfo>> list() async => [...printers];

  @override
  Future<int> open(String devicePath) async {
    if (openFails) throw const UsbPrintException('CreateFile', 5);
    if (!printers.any((p) => p.devicePath == devicePath)) {
      throw const UsbPrintException('CreateFile', 2);
    }
    opened.add(devicePath);
    return _live.add(++_nextHandle) ? _nextHandle : -1;
  }

  @override
  Future<int> write(int handle, Uint8List bytes) async {
    if (!_live.contains(handle))
      throw const UsbPrintException('WriteFile', 1167);
    final limit = failAfter;
    if (limit != null && received.length + bytes.length > limit) {
      final n = limit - received.length;
      received.add(bytes.sublist(0, n));
      writes.add((handle, n));
      return n;
    }
    received.add(bytes);
    writes.add((handle, bytes.length));
    return bytes.length;
  }

  @override
  Future<void> close(int handle) async {
    if (!_live.remove(handle)) throw const UsbPrintException('CloseHandle', 6);
  }
}

Uint8List ticket(int n) => Uint8List.fromList(List.generate(n, (i) => i % 251));

void main() {
  const timeout = Duration(seconds: 8);

  test('lists printers once per hardware id, addressed by it', () async {
    final api = FakeUsbApi()..plug('usb#vid_0483&pid_5743#other');
    final devices = await UsbPrinterTransport(api).pairedDevices();
    expect(devices, hasLength(1));
    expect(devices.single.address, etermaUsbHardwareId);
    expect(devices.single.name, 'Printer POS-58-P504A');
  });

  test('connects by hardware id and sends in paced chunks', () async {
    final api = FakeUsbApi();
    final t = UsbPrinterTransport(api);
    await t.connect('vid_0483&pid_5743', timeout: timeout); // case-insensitive
    final r = await t.write(
      ticket(9010),
      chunkSize: 4096,
      chunkDelay: const Duration(milliseconds: 1),
    );
    expect(r.bytes, 9010);
    expect(api.writes.map((w) => w.$2), [4096, 4096, 818]);
    expect(api.received.toBytes(), ticket(9010));
  });

  test('a missing printer gives a clear Spanish message', () async {
    final api = FakeUsbApi()..unplug();
    await expectLater(
      UsbPrinterTransport(api).connect(etermaUsbHardwareId, timeout: timeout),
      throwsA(
        isA<PrinterException>()
            .having((e) => e.kind, 'kind', PrinterErrorKind.notPaired)
            .having((e) => e.message, 'message', contains('cable')),
      ),
    );
  });

  test('a printer held by another program fails to open', () async {
    final api = FakeUsbApi()..openFails = true;
    await expectLater(
      UsbPrinterTransport(api).connect(etermaUsbHardwareId, timeout: timeout),
      throwsA(
        isA<PrinterException>()
            .having((e) => e.kind, 'kind', PrinterErrorKind.connectFailed)
            .having((e) => e.message, 'message', contains('otro programa')),
      ),
    );
  });

  test('writing before connecting is refused', () async {
    await expectLater(
      UsbPrinterTransport(FakeUsbApi())
          .write(ticket(10), chunkSize: 4, chunkDelay: Duration.zero),
      throwsA(
        isA<PrinterException>().having(
          (e) => e.kind,
          'kind',
          PrinterErrorKind.notConnected,
        ),
      ),
    );
  });

  test('a write cut mid-ticket reports the bytes that got through', () async {
    final api = FakeUsbApi()..failAfter = 5000;
    final t = UsbPrinterTransport(api);
    await t.connect(etermaUsbHardwareId, timeout: timeout);
    await expectLater(
      t.write(ticket(9010), chunkSize: 4096, chunkDelay: Duration.zero),
      throwsA(
        isA<PrinterException>()
            .having((e) => e.kind, 'kind', PrinterErrorKind.writeFailed)
            .having((e) => e.bytesSent, 'bytesSent', 5000)
            .having((e) => e.message, 'message', contains('incompleto')),
      ),
    );
    expect(await t.isConnected(), isFalse);
  });

  group('unplug and re-plug the cable', () {
    late FakeUsbApi api;
    late PrintJobRunner runner;

    setUp(() async {
      api = FakeUsbApi();
      runner = PrintJobRunner(UsbPrinterTransport(api));
      await runner.run(etermaUsbHardwareId, ticket(100));
      api.received.clear();
    });

    test('re-plugged into another port between tickets: prints once, '
        'via the new device path', () async {
      api
        ..unplug()
        ..plug('usb#vid_0483&pid_5743#5&6542b1d&0&7');
      final r = await runner.run(etermaUsbHardwareId, ticket(9010));
      expect(r.reconnected, isTrue);
      expect(api.opened.last, 'usb#vid_0483&pid_5743#5&6542b1d&0&7');
      expect(api.received.toBytes(), ticket(9010)); // exactly one copy
    });

    test(
      'still unplugged: clear message; after re-plugging it prints',
      () async {
        api.unplug();
        await expectLater(
          runner.run(etermaUsbHardwareId, ticket(9010)),
          throwsA(
            isA<PrinterException>()
                .having((e) => e.kind, 'kind', PrinterErrorKind.notPaired)
                .having((e) => e.message, 'message', contains('cable')),
          ),
        );
        expect(runner.busy, isFalse);

        api.plug('usb#vid_0483&pid_5743#5&6542b1d&0&7');
        final r = await runner.run(etermaUsbHardwareId, ticket(9010));
        expect(r.bytes, 9010);
        expect(r.connect, isNotNull);
        expect(api.received.toBytes(), ticket(9010));
      },
    );
  });
}
