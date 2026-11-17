import 'package:esquinita_app/devices/printer/bluetooth_spp_transport.dart';
import 'package:esquinita_app/devices/printer/printer_transport.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('pe.esquinita/bt_spp');
  final calls = <MethodCall>[];

  void answer(Object? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return handler(call);
        });
  }

  setUp(calls.clear);
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('lists paired printers', () async {
    answer(
      (_) => [
        {'name': 'Printer001-C9E2', 'address': 'C0:2B:F3:AB:C9:E2'},
      ],
    );
    final devices = await BluetoothSppTransport().pairedDevices();
    expect(devices.single.name, 'Printer001-C9E2');
    expect(devices.single.address, 'C0:2B:F3:AB:C9:E2');
  });

  test('connect and write pass timeout, chunk size and pause', () async {
    answer(
      (call) => switch (call.method) {
        'connect' => {'elapsedMs': 850},
        'write' => {'bytes': 3, 'elapsedMs': 40},
        _ => null,
      },
    );
    final t = BluetoothSppTransport();
    expect(
      await t.connect('C0:2B', timeout: const Duration(seconds: 5)),
      const Duration(milliseconds: 850),
    );
    final w = await t.write(
      Uint8List.fromList([1, 2, 3]),
      chunkSize: 128,
      chunkDelay: const Duration(milliseconds: 15),
    );
    expect(w.bytes, 3);
    expect(calls[0].arguments, {'address': 'C0:2B', 'timeoutMs': 5000});
    final args = calls[1].arguments as Map<Object?, Object?>;
    expect(args['chunkSize'], 128);
    expect(args['chunkDelayMs'], 15);
    expect(args['bytes'], [1, 2, 3]);
  });

  test('rejects invalid pacing before calling native code', () {
    final t = BluetoothSppTransport();
    expect(
      () => t.write(Uint8List(1), chunkSize: 0, chunkDelay: Duration.zero),
      throwsArgumentError,
    );
    expect(calls, isEmpty);
  });

  group('native errors become Spanish messages', () {
    for (final (code, kind, fragment) in [
      ('BT_OFF', PrinterErrorKind.bluetoothOff, 'Bluetooth está apagado'),
      (
        'PERMISSION_DENIED',
        PrinterErrorKind.permissionDenied,
        'Dispositivos cercanos',
      ),
      ('NOT_PAIRED', PrinterErrorKind.notPaired, 'no está emparejada'),
      ('CONNECT_TIMEOUT', PrinterErrorKind.connectTimeout, 'encendida y cerca'),
      ('CONNECT_FAILED', PrinterErrorKind.connectFailed, 'Aqp Print'),
      ('WAT', PrinterErrorKind.unknown, 'inesperado'),
    ]) {
      test(code, () async {
        answer((_) => throw PlatformException(code: code, message: 'x'));
        await expectLater(
          BluetoothSppTransport().connect('A', timeout: Duration.zero),
          throwsA(
            isA<PrinterException>()
                .having((e) => e.kind, 'kind', kind)
                .having((e) => e.message, 'message', contains(fragment)),
          ),
        );
      });
    }

    test('a write that fails midway says the ticket may be incomplete', () {
      final e = BluetoothSppTransport.toPrinterException(
        PlatformException(code: 'WRITE_FAILED', details: {'bytesSent': 512}),
      );
      expect(e.bytesSent, 512);
      expect(e.message, contains('incompleto'));
      final none = BluetoothSppTransport.toPrinterException(
        PlatformException(code: 'WRITE_FAILED', details: {'bytesSent': 0}),
      );
      expect(none.message, isNot(contains('incompleto')));
    });
  });
}
