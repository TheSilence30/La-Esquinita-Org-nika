import 'dart:async';

import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/form_factor.dart';
import '../app/theme.dart';
import '../devices/scanner/camera_scan_view.dart';
import '../features/scanning/application/scan_session.dart';

/// Spike 1 (Fase 0): continuous camera scanning on the Tab A11.
///
/// Adapts to any aspect ratio: side-by-side when the screen is wider than
/// tall (tablet landscape, PC), stacked otherwise (tablet/phone portrait).
class ScanSpikePage extends StatefulWidget {
  const ScanSpikePage({super.key, this.cameraSupported});

  /// Overrides platform detection (widget tests have no camera).
  final bool? cameraSupported;

  @override
  State<ScanSpikePage> createState() => _ScanSpikePageState();
}

class _ScanSpikePageState extends State<ScanSpikePage> {
  final _session = ScanSession();
  final _cameraKey = GlobalKey<CameraScanViewState>();
  final _manualController = TextEditingController();
  final _manualFocus = FocusNode();

  bool _vibrate = true;
  bool _sound = true;
  bool _flash = false;
  Timer? _flashTimer;
  String? _lastCode;

  bool get _camera => widget.cameraSupported ?? isCameraScanSupported;

  @override
  void dispose() {
    _flashTimer?.cancel();
    _session.dispose();
    _manualController.dispose();
    _manualFocus.dispose();
    super.dispose();
  }

  void _onCodes(List<String> codes, DateTime at) {
    final accepted = _session.onFrame(codes, at);
    if (accepted.isNotEmpty) _feedback(accepted.last);
  }

  void _submitManual() {
    final read = _session.addManual(
      _manualController.text,
      DateTime.now().toUtc(),
    );
    _manualController.clear();
    _manualFocus.requestFocus();
    if (read != null) _feedback(read);
  }

  void _feedback(ScanRead read) {
    if (_vibrate) unawaited(HapticFeedback.mediumImpact());
    if (_sound) unawaited(SystemSound.play(SystemSoundType.click));
    _flashTimer?.cancel();
    setState(() {
      _lastCode = read.code;
      _flash = true;
    });
    _flashTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _flash = false);
    });
  }

  Future<void> _copyCsv() async {
    await Clipboard.setData(ClipboardData(text: _session.toCsv()));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Resultados copiados (CSV)')));
  }

  Future<void> _openSettings() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SettingsSheet(
      session: _session,
      vibrate: _vibrate,
      sound: _sound,
      onVibrate: (v) => setState(() => _vibrate = v),
      onSound: (v) => setState(() => _sound = v),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spike 1 · Escaneo'),
        actions: [
          if (_camera)
            IconButton(
              tooltip: 'Linterna',
              icon: const Icon(Icons.flashlight_on_outlined),
              onPressed: () => _cameraKey.currentState?.toggleTorch(),
            ),
          IconButton(
            tooltip: 'Ajustes del filtro',
            icon: const Icon(Icons.tune),
            onPressed: _openSettings,
          ),
          IconButton(
            tooltip: 'Copiar resultados (CSV)',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: _copyCsv,
          ),
          IconButton(
            tooltip: 'Reiniciar',
            icon: const Icon(Icons.restart_alt),
            onPressed: () {
              _session.clear();
              setState(() => _lastCode = null);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final side = c.maxWidth > c.maxHeight;
            final camera = _CameraArea(
              supported: _camera,
              cameraKey: _cameraKey,
              onCodes: _onCodes,
              flash: _flash,
              lastCode: _lastCode,
            );
            final panel = ListenableBuilder(
              listenable: _session,
              builder: (context, _) => _Panel(
                session: _session,
                lastCode: _lastCode,
                manualController: _manualController,
                manualFocus: _manualFocus,
                autofocusManual: !_camera,
                onSubmitManual: _submitManual,
              ),
            );
            if (side) {
              final panelWidth = (c.maxWidth * 0.4).clamp(300.0, 460.0);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: camera),
                  SizedBox(width: panelWidth, child: panel),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: c.maxHeight * 0.42, child: camera),
                Expanded(child: panel),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CameraArea extends StatelessWidget {
  const _CameraArea({
    required this.supported,
    required this.cameraKey,
    required this.onCodes,
    required this.flash,
    required this.lastCode,
  });

  final bool supported;
  final GlobalKey<CameraScanViewState> cameraKey;
  final void Function(List<String>, DateTime) onCodes;
  final bool flash;
  final String? lastCode;

  @override
  Widget build(BuildContext context) {
    if (!supported) {
      return const ColoredBox(
        color: Colors.black87,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Cámara no disponible en esta plataforma.\n'
              'Usa el ingreso manual o el lector USB (Spike 2).',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraScanView(key: cameraKey, onCodes: onCodes),
        IgnorePointer(
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.7,
              heightFactor: 0.4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: flash ? EsquinitaColors.leaf : Colors.white70,
                    width: flash ? 6 : 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        if (flash)
          const IgnorePointer(child: ColoredBox(color: Color(0x557CB342))),
        if (lastCode != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                lastCode!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.session,
    required this.lastCode,
    required this.manualController,
    required this.manualFocus,
    required this.autofocusManual,
    required this.onSubmitManual,
  });

  final ScanSession session;
  final String? lastCode;
  final TextEditingController manualController;
  final FocusNode manualFocus;
  final bool autofocusManual;
  final VoidCallback onSubmitManual;

  @override
  Widget build(BuildContext context) {
    String ms(Duration? d) => d == null ? '—' : '${d.inMilliseconds} ms';
    final fps = session.detectionFps;
    final size = MediaQuery.sizeOf(context);
    final tally = session.tally.entries.toList().reversed.toList();

    // One scrollable column: fits short screens (phone landscape, small PC
    // windows) as well as the tablet.
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Stat('Lecturas', '${session.reads.length}'),
            _Stat('Unidades', '${session.totalUnits}'),
            _Stat('Repetidas ignoradas', '${session.ignoredRepeats}'),
            _Stat('Cuadros/s', fps == null ? '—' : fps.toStringAsFixed(1)),
            _Stat('Latencia prom.', ms(session.averageLatency)),
            _Stat('p50', ms(session.latencyPercentile(50))),
            _Stat('p95', ms(session.latencyPercentile(95))),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Pantalla: ${FormFactor.of(context).name} · '
          '${size.width.round()}×${size.height.round()} dp · '
          '${MediaQuery.devicePixelRatioOf(context).toStringAsFixed(2)}x',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        _MultiplierRow(session: session),
        const SizedBox(height: 8),
        TextField(
          controller: manualController,
          focusNode: manualFocus,
          autofocus: autofocusManual,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmitManual(),
          decoration: InputDecoration(
            labelText: 'Código manual / lector USB',
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: IconButton(
              tooltip: 'Agregar',
              icon: const Icon(Icons.keyboard_return),
              onPressed: onSubmitManual,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (tally.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Escanea un producto')),
          ),
        for (final e in tally) ...[
          ListTile(
            dense: true,
            selected: e.key == lastCode,
            title: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(
              '× ${e.value}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
        ],
      ],
    );
  }
}

class _MultiplierRow extends StatefulWidget {
  const _MultiplierRow({required this.session});

  final ScanSession session;

  @override
  State<_MultiplierRow> createState() => _MultiplierRowState();
}

class _MultiplierRowState extends State<_MultiplierRow> {
  late final _controller = TextEditingController(
    text: '${widget.session.multiplier}',
  );

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_sync);
  }

  /// Reflects the session value (it resets to 1 after each read). An empty
  /// field while typing counts as 1 and is left alone.
  void _sync() {
    final m = widget.session.multiplier;
    final typed = int.tryParse(_controller.text);
    if (typed == m || (_controller.text.isEmpty && m == 1)) return;
    _controller.text = '$m';
  }

  @override
  void dispose() {
    widget.session.removeListener(_sync);
    _controller.dispose();
    super.dispose();
  }

  void _set(int value) {
    widget.session.multiplier = value;
    _controller.text = '${widget.session.multiplier}';
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.session.multiplier;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        Text('× cantidad', style: Theme.of(context).textTheme.titleSmall),
        IconButton.outlined(
          tooltip: 'Menos',
          icon: const Icon(Icons.remove),
          onPressed: m > 1 ? () => _set(m - 1) : null,
        ),
        SizedBox(
          width: 72,
          child: TextField(
            controller: _controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (t) => widget.session.multiplier = int.tryParse(t) ?? 1,
          ),
        ),
        IconButton.outlined(
          tooltip: 'Más',
          icon: const Icon(Icons.add),
          onPressed: () => _set(m + 1),
        ),
        for (final n in const [2, 3, 6, 12])
          ChoiceChip(
            label: Text('×$n'),
            selected: m == n,
            onSelected: (_) => _set(n),
          ),
        Text(
          'Se aplica a la siguiente lectura',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: t.labelSmall),
          Text(
            value,
            style: t.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({
    required this.session,
    required this.vibrate,
    required this.sound,
    required this.onVibrate,
    required this.onSound,
  });

  final ScanSession session;
  final bool vibrate;
  final bool sound;
  final ValueChanged<bool> onVibrate;
  final ValueChanged<bool> onSound;

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late var _config = widget.session.config;
  late var _vibrate = widget.vibrate;
  late var _sound = widget.sound;

  void _apply(ScanFilterConfig config) {
    setState(() => _config = config);
    widget.session.updateConfig(config);
  }

  Widget _slider(
    String label,
    Duration value,
    int min,
    int max,
    int step,
    ScanFilterConfig Function(Duration) copy,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.inMilliseconds} ms'),
        Slider(
          value: value.inMilliseconds.clamp(min, max).toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: (max - min) ~/ step,
          onChanged: (v) => _apply(copy(Duration(milliseconds: v.round()))),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _config;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Filtro de escaneo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _slider(
            'Confirmación (2 cuadros dentro de)',
            c.confirmWindow,
            50,
            1000,
            50,
            (d) => ScanFilterConfig(
              confirmWindow: d,
              cooldown: c.cooldown,
              rearmAbsence: c.rearmAbsence,
            ),
          ),
          _slider(
            'Enfriamiento del mismo código',
            c.cooldown,
            300,
            5000,
            100,
            (d) => ScanFilterConfig(
              confirmWindow: c.confirmWindow,
              cooldown: d,
              rearmAbsence: c.rearmAbsence,
            ),
          ),
          _slider(
            'Ausencia mínima para volver a contar',
            c.rearmAbsence,
            100,
            2000,
            50,
            (d) => ScanFilterConfig(
              confirmWindow: c.confirmWindow,
              cooldown: c.cooldown,
              rearmAbsence: d,
            ),
          ),
          TextButton(
            onPressed: () => _apply(const ScanFilterConfig()),
            child: const Text('Restablecer (300 / 1500 / 500 ms)'),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Vibrar al leer'),
            value: _vibrate,
            onChanged: (v) {
              setState(() => _vibrate = v);
              widget.onVibrate(v);
            },
          ),
          SwitchListTile(
            title: const Text('Sonido al leer'),
            subtitle: const Text('Usa el sonido de toque del sistema'),
            value: _sound,
            onChanged: (v) {
              setState(() => _sound = v);
              widget.onSound(v);
            },
          ),
        ],
      ),
    );
  }
}
