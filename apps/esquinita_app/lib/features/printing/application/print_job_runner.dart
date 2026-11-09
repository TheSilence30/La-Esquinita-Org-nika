import 'dart:typed_data';

import '../../../devices/printer/printer_transport.dart';

/// Pacing and timeouts for one printer. Defaults are a starting point; the
/// Spike 3 measures what the Éterma really needs.
final class PrintSettings {
  const PrintSettings({
    this.chunkSize = 256,
    this.chunkDelay = const Duration(milliseconds: 20),
    this.connectTimeout = const Duration(seconds: 8),
  });

  final int chunkSize;
  final Duration chunkDelay;
  final Duration connectTimeout;
}

final class PrintJobResult {
  const PrintJobResult({
    required this.bytes,
    required this.send,
    this.connect,
    this.reconnected = false,
  });

  final int bytes;

  /// Null when the link was already open.
  final Duration? connect;
  final Duration send;

  /// The printer had gone away (switched off, out of range) and the job
  /// reconnected before anything was printed.
  final bool reconnected;
}

/// Sends one encoded ticket: connects when needed, one job at a time, and
/// recovers from a printer that was switched off since the last job.
class PrintJobRunner {
  PrintJobRunner(this.transport);

  final PrinterTransport transport;
  String? _connectedTo;
  bool _busy = false;

  bool get busy => _busy;

  Future<PrintJobResult> run(
    String address,
    Uint8List bytes, {
    PrintSettings settings = const PrintSettings(),
  }) async {
    if (_busy) {
      throw const PrinterException(
        PrinterErrorKind.busy,
        'Ya se está imprimiendo. Espera a que termine.',
      );
    }
    _busy = true;
    try {
      if (!await transport.ensurePermissions()) {
        throw const PrinterException(
          PrinterErrorKind.permissionDenied,
          'Sin el permiso «Dispositivos cercanos» no se puede imprimir. '
          'Actívalo en Ajustes › Aplicaciones › La Esquinita › Permisos.',
        );
      }
      Duration? connect;
      if (_connectedTo != address || !await transport.isConnected()) {
        connect = await _open(address, settings);
      }
      try {
        final w = await _write(bytes, settings);
        return PrintJobResult(
          bytes: w.bytes,
          connect: connect,
          send: w.elapsed,
        );
      } on PrinterException catch (e) {
        // Resend only when nothing reached the printer: once part of a ticket
        // has printed, a retry would print it twice.
        final retryable =
            e.bytesSent == 0 &&
            (e.kind == PrinterErrorKind.writeFailed ||
                e.kind == PrinterErrorKind.notConnected);
        if (!retryable) {
          _connectedTo = null;
          rethrow;
        }
        connect = await _open(address, settings);
        final w = await _write(bytes, settings);
        return PrintJobResult(
          bytes: w.bytes,
          connect: connect,
          send: w.elapsed,
          reconnected: true,
        );
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> disconnect() async {
    _connectedTo = null;
    await transport.disconnect();
  }

  Future<Duration> _open(String address, PrintSettings settings) async {
    _connectedTo = null;
    final took = await transport.connect(
      address,
      timeout: settings.connectTimeout,
    );
    _connectedTo = address;
    return took;
  }

  Future<WriteResult> _write(Uint8List bytes, PrintSettings settings) =>
      transport.write(
        bytes,
        chunkSize: settings.chunkSize,
        chunkDelay: settings.chunkDelay,
      );
}
