import 'dart:typed_data';

import 'package:esquinita_app/app/theme.dart';
import 'package:esquinita_app/devices/printer/printer_transport.dart';
import 'package:esquinita_app/spikes/print_spike_page.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTransport implements PrinterTransport {
  FakeTransport({this.devices = const [], this.permission = true});

  final List<PrinterDevice> devices;
  final bool permission;
  bool connected = false;
  final sent = <Uint8List>[];
  final pacing = <(int, Duration)>[];
  PrinterException? failWith;

  @override
  Future<bool> ensurePermissions() async => permission;

  @override
  Future<List<PrinterDevice>> pairedDevices() async => devices;

  @override
  Future<Duration> connect(String address, {required Duration timeout}) async {
    connected = true;
    return const Duration(milliseconds: 900);
  }

  @override
  Future<WriteResult> write(
    Uint8List bytes, {
    required int chunkSize,
    required Duration chunkDelay,
  }) async {
    if (failWith case final e?) throw e;
    sent.add(bytes);
    pacing.add((chunkSize, chunkDelay));
    return WriteResult(
      bytes: bytes.length,
      elapsed: const Duration(seconds: 2),
    );
  }

  @override
  Future<void> disconnect() async => connected = false;

  @override
  Future<bool> isConnected() async => connected;
}

const eterma = PrinterDevice(
  name: 'Printer001-C9E2',
  address: 'C0:2B:F3:AB:C9:E2',
);

Future<void> pump(WidgetTester tester, FakeTransport t, Size size) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(),
      home: PrintSpikePage(
        transport: t,
        loadLogo: ({required dither}) async =>
            MonoBitmap(16, 2, Uint8List(4)..fillRange(0, 4, 0xFF)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final size in const [Size(893, 533), Size(533, 893), Size(360, 740)]) {
    testWidgets('lays out without overflow at $size', (tester) async {
      await pump(tester, FakeTransport(devices: const [eterma]), size);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Printer001-C9E2'), findsOneWidget);
    });
  }

  testWidgets('prints the text ticket with the chosen pacing', (tester) async {
    final t = FakeTransport(
      devices: const [
        PrinterDevice(name: 'LG-PM5', address: 'AA'),
        eterma,
      ],
    );
    await pump(tester, t, const Size(1340, 800));
    // The Éterma is preselected over other paired devices.
    expect(find.textContaining('Printer001-C9E2'), findsOneWidget);
    await tester.tap(find.text('Ticket como texto'));
    await tester.pumpAndSettle();
    expect(t.sent, hasLength(1));
    expect(t.sent.single.sublist(0, 5), [0x1B, 0x40, 0x1B, 0x74, 2]);
    expect(t.pacing.single, (256, const Duration(milliseconds: 20)));
    expect(find.textContaining('conexión 900 ms'), findsOneWidget);
  });

  testWidgets('a failure shows the Spanish message', (tester) async {
    final t = FakeTransport(devices: const [eterma])
      ..failWith = const PrinterException(
        PrinterErrorKind.writeFailed,
        'Se cortó la conexión mientras se imprimía: el ticket puede haber '
        'salido incompleto.',
        bytesSent: 300,
      );
    await pump(tester, t, const Size(1340, 800));
    await tester.tap(find.text('Página de códigos'));
    await tester.pumpAndSettle();
    expect(find.textContaining('incompleto'), findsWidgets);
  });

  testWidgets('no permission: explains how to grant it', (tester) async {
    await pump(tester, FakeTransport(permission: false), const Size(1340, 800));
    expect(find.textContaining('Dispositivos cercanos'), findsOneWidget);
  });
}
