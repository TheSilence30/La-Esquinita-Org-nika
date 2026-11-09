import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Camera scanning is only available on Android (mobile_scanner has no
/// Windows implementation; the PC uses a USB keyboard-wedge reader).
bool get isCameraScanSupported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Monotonic clock shared by every camera view: the scan filter must not see
/// wall-clock jumps (NTP sync, manual time change).
final _monotonic = Stopwatch()..start();

/// Retail formats only: fewer formats → faster ML Kit decoding. QR is off by
/// default (in sales it stays off; see CLAUDE.md §6.11).
const retailFormats = [
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.code128,
  BarcodeFormat.code39,
];

List<BarcodeFormat> scanFormats({required bool includeQr}) => [
  ...retailFormats,
  if (includeQr) BarcodeFormat.qrCode,
];

/// Live camera preview that reports every frame's decoded codes, unfiltered.
/// De-duplication is the caller's job (see `ScanFilter` in esquinita_core).
class CameraScanView extends StatefulWidget {
  const CameraScanView({
    super.key,
    required this.onCodes,
    this.includeQr = false,
    this.overlay,
  });

  /// Fixed for the life of the view (the controller takes the formats at
  /// creation): give the view a new key to change it.
  final bool includeQr;

  /// Called once per analyzed frame that contained at least one code, with
  /// the monotonic elapsed time (for filtering) and the UTC time (for logs).
  final void Function(List<String> codes, Duration elapsed, DateTime atUtc)
  onCodes;

  final Widget? overlay;

  @override
  State<CameraScanView> createState() => CameraScanViewState();
}

class CameraScanViewState extends State<CameraScanView> {
  late final _controller = MobileScannerController(
    formats: scanFormats(includeQr: widget.includeQr),
    // Every frame, no plugin-side de-dup: our filter needs to see the code
    // keep appearing to know it is still in view.
    detectionSpeed: DetectionSpeed.unrestricted,
  );

  Future<void> toggleTorch() => _controller.toggleTorch();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      onDetect: (capture) {
        final elapsed = _monotonic.elapsed;
        final atUtc = DateTime.now().toUtc();
        final codes = [
          for (final b in capture.barcodes)
            if (b.rawValue case final v? when v.isNotEmpty) v,
        ];
        if (codes.isNotEmpty) widget.onCodes(codes, elapsed, atUtc);
      },
      errorBuilder: (context, error) => _CameraError(error),
      overlayBuilder: widget.overlay == null
          ? null
          : (context, constraints) => widget.overlay!,
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError(this.error);

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final message = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Permiso de cámara denegado. Actívalo en Ajustes › Aplicaciones.',
      MobileScannerErrorCode.unsupported =>
        'Este equipo no tiene cámara compatible.',
      _ =>
        'Error de cámara: ${error.errorDetails?.message ?? error.errorCode.name}',
    };
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
