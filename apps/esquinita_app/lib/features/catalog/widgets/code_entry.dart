import 'dart:async';

import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';

import '../../../devices/feedback/scan_feedback.dart';
import '../../../devices/scanner/camera_scan_view.dart';

/// "Registrar" scan context: camera (store codes only, never QR), the USB
/// reader or the keyboard into the field, or "sin código".
class CodeEntry extends StatefulWidget {
  const CodeEntry({
    super.key,
    required this.camera,
    required this.onCode,
    required this.onNoCode,
  });

  final bool camera;
  final ValueChanged<String> onCode;
  final VoidCallback onNoCode;

  @override
  State<CodeEntry> createState() => _CodeEntryState();
}

class _CodeEntryState extends State<CodeEntry> {
  final _filter = ScanFilter();
  final _manual = TextEditingController();

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  void _submit(String v) {
    if (v.trim().isEmpty) return;
    widget.onCode(v.trim());
    _manual.clear();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('Registrar producto', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      if (widget.camera)
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: CameraScanView(
              onCodes: (codes, elapsed, _) {
                for (final c in codes) {
                  if (_filter.offer(c, elapsed).isAccepted) {
                    unawaited(ScanFeedback.success());
                    widget.onCode(c);
                    return;
                  }
                }
              },
              overlay: const ScanFrame(),
            ),
          ),
        )
      else
        Container(
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E0D0)),
          ),
          child: const Text(
            'Usa el lector de códigos o escribe el código.',
            textAlign: TextAlign.center,
          ),
        ),
      const SizedBox(height: 12),
      TextField(
        controller: _manual,
        autofocus: !widget.camera, // the USB reader types here
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Código de barras',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.keyboard_return),
        ),
        onSubmitted: _submit,
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: widget.onNoCode,
        icon: const Icon(Icons.qr_code_2),
        label: const Text('Producto sin código: generar código interno'),
      ),
    ],
  );
}
