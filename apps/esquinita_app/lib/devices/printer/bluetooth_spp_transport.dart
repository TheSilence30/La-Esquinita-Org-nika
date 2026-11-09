import 'package:flutter/services.dart';

import 'printer_transport.dart';

/// Bluetooth Classic (SPP) printer link, backed by `BtSppChannel.kt`. All
/// Bluetooth work runs on a native background thread.
class BluetoothSppTransport implements PrinterTransport {
  BluetoothSppTransport({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('pe.esquinita/bt_spp');

  final MethodChannel _channel;

  @override
  Future<bool> ensurePermissions() async =>
      await _call<bool>('ensurePermissions') ?? false;

  @override
  Future<List<PrinterDevice>> pairedDevices() async {
    final list = await _call<List<Object?>>('pairedDevices') ?? const [];
    return [
      for (final item in list.cast<Map<Object?, Object?>>())
        PrinterDevice(
          name: item['name']! as String,
          address: item['address']! as String,
        ),
    ];
  }

  @override
  Future<Duration> connect(String address, {required Duration timeout}) async {
    final r = await _call<Map<Object?, Object?>>('connect', {
      'address': address,
      'timeoutMs': timeout.inMilliseconds,
    });
    return Duration(milliseconds: (r!['elapsedMs']! as num).toInt());
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
    final r = await _call<Map<Object?, Object?>>('write', {
      'bytes': bytes,
      'chunkSize': chunkSize,
      'chunkDelayMs': chunkDelay.inMilliseconds,
    });
    return WriteResult(
      bytes: (r!['bytes']! as num).toInt(),
      elapsed: Duration(milliseconds: (r['elapsedMs']! as num).toInt()),
    );
  }

  @override
  Future<void> disconnect() => _call<void>('disconnect');

  @override
  Future<bool> isConnected() async => await _call<bool>('isConnected') ?? false;

  Future<T?> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw toPrinterException(e);
    } on MissingPluginException {
      throw const PrinterException(
        PrinterErrorKind.unavailable,
        'La impresión por Bluetooth solo está disponible en Android.',
      );
    }
  }

  /// Native error codes → messages for the cashier.
  static PrinterException toPrinterException(PlatformException e) {
    final details = e.details;
    final sent = details is Map
        ? (details['bytesSent'] as num?)?.toInt()
        : null;
    final (kind, message) = switch (e.code) {
      'BT_UNAVAILABLE' => (
        PrinterErrorKind.unavailable,
        'Este equipo no tiene Bluetooth.',
      ),
      'BT_OFF' => (
        PrinterErrorKind.bluetoothOff,
        'El Bluetooth está apagado. Actívalo e inténtalo de nuevo.',
      ),
      'PERMISSION_DENIED' => (
        PrinterErrorKind.permissionDenied,
        'Falta el permiso «Dispositivos cercanos». Actívalo en Ajustes › '
            'Aplicaciones › La Esquinita › Permisos.',
      ),
      'NOT_PAIRED' => (
        PrinterErrorKind.notPaired,
        'La impresora no está emparejada. Emparéjala en Ajustes › Bluetooth.',
      ),
      'CONNECT_TIMEOUT' => (
        PrinterErrorKind.connectTimeout,
        'La impresora no respondió. Revisa que esté encendida y cerca.',
      ),
      'CONNECT_FAILED' => (
        PrinterErrorKind.connectFailed,
        'No se pudo conectar con la impresora. Revisa que esté encendida y '
            'que otra app (por ejemplo, Aqp Print) no la esté usando.',
      ),
      'NOT_CONNECTED' => (
        PrinterErrorKind.notConnected,
        'La impresora no está conectada.',
      ),
      'WRITE_FAILED' when (sent ?? 0) == 0 => (
        PrinterErrorKind.writeFailed,
        'Se perdió la conexión con la impresora.',
      ),
      'WRITE_FAILED' => (
        PrinterErrorKind.writeFailed,
        'Se cortó la conexión mientras se imprimía: el ticket puede haber '
            'salido incompleto.',
      ),
      'BUSY' => (
        PrinterErrorKind.busy,
        'Ya hay una solicitud de permiso abierta.',
      ),
      _ => (PrinterErrorKind.unknown, 'Error inesperado de la impresora.'),
    };
    return PrinterException(
      kind,
      message,
      bytesSent: sent ?? 0,
      detail: '${e.code}: ${e.message}',
    );
  }
}
