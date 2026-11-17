import 'dart:typed_data';

import 'printer_transport.dart';

/// USB hardware id of the Éterma 58 mm (Windows reports it as
/// "Printer POS-58-P504A").
const etermaUsbHardwareId = 'VID_0483&PID_5743';

/// A USB printer as the OS sees it right now. [devicePath] changes when the
/// cable is re-plugged; [hardwareId] (`VID_xxxx&PID_xxxx`) does not.
final class UsbPrinterInfo {
  const UsbPrinterInfo({
    required this.name,
    required this.hardwareId,
    required this.devicePath,
  });

  final String name;
  final String hardwareId;
  final String devicePath;
}

/// An OS call failed; [code] is the platform error (Win32 `GetLastError`).
final class UsbPrintException implements Exception {
  const UsbPrintException(this.operation, this.code);

  final String operation;
  final int code;

  @override
  String toString() => 'UsbPrintException($operation, error $code)';
}

/// Raw access to USB printers. Windows implementation: `WinUsbPrintApi`.
abstract interface class UsbPrintApi {
  Future<List<UsbPrinterInfo>> list();

  /// Returns an opaque handle.
  Future<int> open(String devicePath);

  /// Returns how many bytes the printer accepted.
  Future<int> write(int handle, Uint8List bytes);

  Future<void> close(int handle);
}

/// Prints over USB (PC). The printer is found by its hardware id on every
/// connect, never by port or device path, so a re-plugged cable still works.
class UsbPrinterTransport implements PrinterTransport {
  UsbPrinterTransport(this._api);

  final UsbPrintApi _api;
  int? _handle;

  @override
  Future<bool> ensurePermissions() async => true;

  /// One entry per hardware id; [PrinterDevice.address] is the hardware id.
  @override
  Future<List<PrinterDevice>> pairedDevices() async {
    final seen = <String>{};
    return [
      for (final p in await _guard('list', _api.list))
        if (seen.add(p.hardwareId))
          PrinterDevice(name: p.name, address: p.hardwareId),
    ];
  }

  @override
  Future<Duration> connect(String address, {required Duration timeout}) async {
    final sw = Stopwatch()..start();
    await disconnect();
    final match = (await _guard('list', _api.list))
        .where((p) => p.hardwareId.toUpperCase() == address.toUpperCase())
        .firstOrNull;
    if (match == null) {
      throw const PrinterException(
        PrinterErrorKind.notPaired,
        'No se encontró la impresora USB. Revisa que el cable esté conectado '
        'y que la impresora esté encendida.',
      );
    }
    _handle = await _guard('open', () => _api.open(match.devicePath));
    return sw.elapsed;
  }

  @override
  Future<WriteResult> write(
    Uint8List bytes, {
    required int chunkSize,
    required Duration chunkDelay,
  }) async {
    if (chunkSize < 1) throw ArgumentError.value(chunkSize, 'chunkSize');
    if (chunkDelay.isNegative) {
      throw ArgumentError.value(chunkDelay, 'chunkDelay');
    }
    final handle = _handle;
    if (handle == null) {
      throw const PrinterException(
        PrinterErrorKind.notConnected,
        'La impresora no está conectada.',
      );
    }
    final sw = Stopwatch()..start();
    var sent = 0;
    while (sent < bytes.length) {
      final want = (bytes.length - sent).clamp(0, chunkSize);
      int n;
      try {
        n = await _api.write(
          handle,
          Uint8List.sublistView(bytes, sent, sent + want),
        );
      } on UsbPrintException catch (e) {
        throw _lost(sent, e.toString());
      }
      sent += n;
      if (n < want) throw _lost(sent, 'short write: $n of $want bytes');
      if (sent < bytes.length && chunkDelay > Duration.zero) {
        await Future<void>.delayed(chunkDelay);
      }
    }
    return WriteResult(bytes: sent, elapsed: sw.elapsed);
  }

  @override
  Future<void> disconnect() async {
    final handle = _handle;
    _handle = null;
    if (handle == null) return;
    try {
      await _api.close(handle);
    } on UsbPrintException {
      // Unplugged printers fail to close; the handle is gone either way.
    }
  }

  @override
  Future<bool> isConnected() async => _handle != null;

  /// The link died after [sent] bytes; same wording as Bluetooth so the
  /// cashier sees one message per situation.
  PrinterException _lost(int sent, String detail) {
    _handle = null;
    return PrinterException(
      PrinterErrorKind.writeFailed,
      sent == 0
          ? 'Se perdió la conexión con la impresora.'
          : 'Se cortó la conexión mientras se imprimía: el ticket puede haber '
                'salido incompleto.',
      bytesSent: sent,
      detail: detail,
    );
  }

  static Future<T> _guard<T>(String op, Future<T> Function() call) async {
    try {
      return await call();
    } on UsbPrintException catch (e) {
      throw PrinterException(
        op == 'open'
            ? PrinterErrorKind.connectFailed
            : PrinterErrorKind.unavailable,
        op == 'open'
            ? 'No se pudo abrir la impresora USB. Revisa que esté encendida y '
                  'que otro programa no la esté usando.'
            : 'No se pudo consultar las impresoras USB de este equipo.',
        detail: e.toString(),
      );
    }
  }
}
