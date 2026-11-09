import 'dart:async';

import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../devices/printer/bluetooth_spp_transport.dart';
import '../devices/printer/printer_transport.dart';
import '../devices/printer/raster.dart';
import '../features/printing/application/print_job_runner.dart';
import 'test_ticket.dart';

/// Spike 3 (Fase 0): thermal printing on the Éterma over Bluetooth SPP.
/// Measures which chunk size and pause print long tickets and the logo
/// without corruption, and compares text vs. image tickets.
class PrintSpikePage extends StatefulWidget {
  const PrintSpikePage({super.key, this.transport, this.loadLogo});

  /// Overrides the Bluetooth transport (widget tests).
  final PrinterTransport? transport;

  /// Overrides logo loading (widget tests have no image codecs).
  final Future<MonoBitmap> Function({required bool dither})? loadLogo;

  @override
  State<PrintSpikePage> createState() => _PrintSpikePageState();
}

enum _Job {
  codePages('Página de códigos'),
  text('Ticket como texto'),
  image('Ticket como imagen');

  const _Job(this.label);
  final String label;
}

class _LogEntry {
  _LogEntry(this.job, this.settings, this.codePage, {this.result, this.error})
    : at = DateTime.now().toUtc();

  final DateTime at;
  final _Job job;
  final PrintSettings settings;
  final CodePage codePage;
  final PrintJobResult? result;
  final PrinterException? error;
}

class _PrintSpikePageState extends State<PrintSpikePage> {
  static const _chunkSizes = [32, 64, 128, 256, 512, 1024, 4096];
  static const _delaysMs = [0, 5, 10, 20, 50, 100];
  static const _logoWidth = 320;

  late final PrinterTransport _transport =
      widget.transport ?? BluetoothSppTransport();
  late final _runner = PrintJobRunner(_transport);

  List<PrinterDevice> _devices = const [];
  PrinterDevice? _selected;
  String? _deviceError;
  bool _loadingDevices = true;

  int _chunkSize = 256;
  int _delayMs = 20;
  CodePage _codePage = CodePage.pc850;
  bool _ditherLogo = false;
  _Job? _running;
  final _log = <_LogEntry>[];
  final _logos = <bool, MonoBitmap>{};

  @override
  void initState() {
    super.initState();
    unawaited(_loadDevices());
  }

  @override
  void dispose() {
    unawaited(_runner.disconnect().catchError((Object _) {}));
    super.dispose();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _loadingDevices = true;
      _deviceError = null;
    });
    try {
      if (!await _transport.ensurePermissions()) {
        throw const PrinterException(
          PrinterErrorKind.permissionDenied,
          'Sin el permiso «Dispositivos cercanos» no se pueden listar las '
          'impresoras. Actívalo en Ajustes › Aplicaciones › La Esquinita.',
        );
      }
      final devices = await _transport.pairedDevices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _selected = devices.contains(_selected)
            ? _selected
            : devices
                  .where((d) => d.name.startsWith('Printer001'))
                  .followedBy(devices)
                  .firstOrNull;
        if (devices.isEmpty) {
          _deviceError = 'No hay impresoras emparejadas. Emparéjala en Ajustes › Bluetooth.';
        }
      });
    } on PrinterException catch (e) {
      if (mounted) setState(() => _deviceError = e.message);
    } finally {
      if (mounted) setState(() => _loadingDevices = false);
    }
  }

  Future<MonoBitmap> _logo() async {
    final cached = _logos[_ditherLogo];
    if (cached != null) return cached;
    final dither = _ditherLogo;
    final logo = widget.loadLogo != null
        ? await widget.loadLogo!(dither: dither)
        : await decodeMonoBitmap(
            (await rootBundle.load('assets/branding/logo-ticket.png')).buffer
                .asUint8List(),
            width: _logoWidth,
            dither: dither,
          );
    return _logos[dither] = logo;
  }

  Future<Uint8List> _bytesFor(_Job job) async {
    const tear = PrintFeed(4); // no cutter: room to tear the paper off
    switch (job) {
      case _Job.codePages:
        return buildCodePageSheet();
      case _Job.text:
        final doc = buildTestTicket(now: DateTime.now(), logo: await _logo());
        return EscPosEncoder(codePage: _codePage)
            .encode(PrintDocument([...doc.blocks, tear]));
      case _Job.image:
        final doc = buildTestTicket(now: DateTime.now(), logo: await _logo());
        final image = await renderDocumentImage(doc);
        return const EscPosEncoder().encode(
          PrintDocument([PrintImage(image), tear]),
        );
    }
  }

  Future<void> _print(_Job job) async {
    final device = _selected;
    if (device == null || _running != null) return;
    final settings = PrintSettings(
      chunkSize: _chunkSize,
      chunkDelay: Duration(milliseconds: _delayMs),
    );
    setState(() => _running = job);
    _LogEntry entry;
    try {
      final bytes = await _bytesFor(job);
      final result = await _runner.run(
        device.address,
        bytes,
        settings: settings,
      );
      entry = _LogEntry(job, settings, _codePage, result: result);
    } on PrinterException catch (e) {
      entry = _LogEntry(job, settings, _codePage, error: e);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
    if (!mounted) return;
    setState(() {
      _running = null;
      _log.insert(0, entry);
    });
  }

  Future<void> _copyCsv() async {
    String ms(Duration? d) => d?.inMilliseconds.toString() ?? '';
    final buffer = StringBuffer()
      ..writeln('# Spike 3 — impresión Bluetooth (${_selected?.name ?? '-'})')
      ..writeln(
        'at_utc,job,bytes,connect_ms,send_ms,chunk,delay_ms,code_page,'
        'reconnected,error',
      );
    for (final e in _log.reversed) {
      final r = e.result;
      buffer.writeln(
        [
          e.at.toIso8601String(),
          e.job.name,
          r?.bytes ?? e.error?.bytesSent ?? '',
          ms(r?.connect),
          ms(r?.send),
          e.settings.chunkSize,
          e.settings.chunkDelay.inMilliseconds,
          e.job == _Job.text ? e.codePage.name : '',
          (r?.reconnected ?? false) ? 1 : 0,
          e.error == null ? '' : '"${e.error!.kind.name}: ${e.error!.detail}"',
        ].join(','),
      );
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Resultados copiados (CSV)')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _running != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spike 3 · Impresión'),
        actions: [
          IconButton(
            tooltip: 'Actualizar impresoras',
            icon: const Icon(Icons.refresh),
            onPressed: busy || _loadingDevices ? null : _loadDevices,
          ),
          IconButton(
            tooltip: 'Copiar resultados (CSV)',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: _log.isEmpty ? null : _copyCsv,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Impresora', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_loadingDevices)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<PrinterDevice>(
                initialValue: _selected,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Impresora emparejada',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final d in _devices)
                    DropdownMenuItem(
                      value: d,
                      child: Text('${d.name} · ${d.address}'),
                    ),
                ],
                onChanged: busy ? null : (d) => setState(() => _selected = d),
              ),
            if (_deviceError != null) ...[
              const SizedBox(height: 8),
              Text(
                _deviceError!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Text('Envío', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Picker<int>(
                  label: 'Bloque',
                  value: _chunkSize,
                  values: _chunkSizes,
                  text: (v) => '$v bytes',
                  onChanged: busy
                      ? null
                      : (v) => setState(() => _chunkSize = v),
                ),
                _Picker<int>(
                  label: 'Pausa entre bloques',
                  value: _delayMs,
                  values: _delaysMs,
                  text: (v) => '$v ms',
                  onChanged: busy ? null : (v) => setState(() => _delayMs = v),
                ),
                _Picker<CodePage>(
                  label: 'Página de códigos (texto)',
                  value: _codePage,
                  values: CodePage.values,
                  text: (v) => '${v.name} (ESC t ${v.escPosId})',
                  onChanged: busy ? null : (v) => setState(() => _codePage = v),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Difuminar el logo'),
              subtitle: const Text(
                'Apagado: umbral simple, mejor para el logo en blanco y negro',
              ),
              value: _ditherLogo,
              onChanged: busy ? null : (v) => setState(() => _ditherLogo = v),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final job in _Job.values)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: busy || _selected == null
                        ? null
                        : () => _print(job),
                    icon: _running == job
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print_outlined),
                    label: Text(job.label),
                  ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: busy
                      ? null
                      : () => unawaited(
                          _runner.disconnect().catchError((Object _) {}),
                        ),
                  child: const Text('Desconectar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Resultados', style: theme.textTheme.titleMedium),
            if (_log.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Todavía no se imprimió nada.'),
              ),
            for (final e in _log) _LogTile(e),
          ],
        ),
      ),
    );
  }
}

class _Picker<T> extends StatelessWidget {
  const _Picker({
    required this.label,
    required this.value,
    required this.values,
    required this.text,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) text;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          for (final v in values)
            DropdownMenuItem(value: v, child: Text(text(v))),
        ],
        onChanged: onChanged == null ? null : (v) => onChanged!(v as T),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile(this.entry);

  final _LogEntry entry;

  @override
  Widget build(BuildContext context) {
    String ms(Duration d) => d.inMilliseconds < 1000
        ? '${d.inMilliseconds} ms'
        : '${(d.inMilliseconds / 1000).toStringAsFixed(1)} s';
    final r = entry.result;
    final error = entry.error;
    final pacing =
        '${entry.settings.chunkSize} B / ${entry.settings.chunkDelay.inMilliseconds} ms';
    final local = entry.at.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        error == null ? Icons.check_circle_outline : Icons.error_outline,
        color: error == null
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
      ),
      title: Text('$time · ${entry.job.label}'),
      subtitle: Text(
        error != null
            ? '${error.message} · $pacing'
            : [
                '${(r!.bytes / 1024).toStringAsFixed(1)} KB',
                if (r.connect != null) 'conexión ${ms(r.connect!)}',
                'envío ${ms(r.send)}',
                pacing,
                if (r.reconnected) 'reconectó',
              ].join(' · '),
      ),
    );
  }
}
