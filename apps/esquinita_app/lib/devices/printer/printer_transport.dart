import 'dart:typed_data';

/// How bytes reach a printer (Bluetooth SPP on the tablet, USB on the PC).
/// Ticket generation (`EscPosEncoder` in esquinita_core) never depends on
/// it, so transports can be swapped freely.
abstract interface class PrinterTransport {
  /// Asks for the OS permissions the transport needs. False if denied.
  Future<bool> ensurePermissions();

  /// Printers already paired with this device.
  Future<List<PrinterDevice>> pairedDevices();

  /// Opens a link to [address]; returns how long it took.
  Future<Duration> connect(String address, {required Duration timeout});

  /// Sends [bytes] in [chunkSize] pieces, pausing [chunkDelay] between them
  /// (cheap printers corrupt long tickets and images sent in one go).
  Future<WriteResult> write(
    Uint8List bytes, {
    required int chunkSize,
    required Duration chunkDelay,
  });

  Future<void> disconnect();

  Future<bool> isConnected();
}

final class PrinterDevice {
  const PrinterDevice({required this.name, required this.address});

  final String name;
  final String address;

  @override
  bool operator ==(Object other) =>
      other is PrinterDevice && other.address == address;

  @override
  int get hashCode => address.hashCode;
}

final class WriteResult {
  const WriteResult({required this.bytes, required this.elapsed});

  final int bytes;
  final Duration elapsed;
}

enum PrinterErrorKind {
  unavailable,
  bluetoothOff,
  permissionDenied,
  notPaired,
  connectTimeout,
  connectFailed,
  notConnected,
  writeFailed,
  busy,
  unknown,
}

/// A printing failure with a message ready to show to the cashier.
final class PrinterException implements Exception {
  const PrinterException(
    this.kind,
    this.message, {
    this.bytesSent = 0,
    this.detail,
  });

  final PrinterErrorKind kind;

  /// Spanish (Peru), for the UI.
  final String message;

  /// Bytes that reached the printer before a write failed.
  final int bytesSent;

  /// Technical detail for logs.
  final String? detail;

  @override
  String toString() => 'PrinterException($kind, $message, $detail)';
}
