import 'dart:async';

import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/local/database.dart';
import '../data/sync/outbox_store.dart';
import '../data/sync/sync_client.dart';

/// Spike 6 (Fase 0): operations recorded offline in SQLite (drift) survive
/// a restart and reach the local server exactly once.
class SyncSpikePage extends StatefulWidget {
  const SyncSpikePage({super.key, required this.db, this.transportFor});

  /// The app's encrypted local database.
  final AppDatabase db;

  /// Overrides the HTTP transport (widget tests).
  final PushTransport Function(String url)? transportFor;

  @override
  State<SyncSpikePage> createState() => _SyncSpikePageState();
}

class _SyncSpikePageState extends State<SyncSpikePage> {
  late final AppDatabase _db = widget.db;
  late final _store = OutboxStore(_db);
  late final _pending = _store.watchPendingCount();
  late final _outbox = _store.watchOutbox();
  final _url = TextEditingController();
  SyncScheduler? _scheduler;
  StreamSubscription<SyncRunState>? _stateSub;
  SyncRunState _state = const SyncRunState(running: false);
  String _deviceId = '';
  bool _slow = false;
  int _created = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    final id = await _store.deviceId();
    final saved = await _store.serverUrl();
    if (!mounted) return;
    setState(() => _deviceId = id);
    _url.text =
        saved ??
        (defaultTargetPlatform == TargetPlatform.windows
            ? 'http://127.0.0.1:8080'
            : 'http://192.168.1.');
    if (saved != null) _restartScheduler();
  }

  /// A new scheduler per URL or pace; it syncs right away (app start or
  /// change) and then every 30 s, with growing waits after failures.
  void _restartScheduler() {
    unawaited(_stateSub?.cancel());
    _scheduler?.dispose();
    final url = _url.text.trim();
    final scheduler = SyncScheduler(
      SyncClient(
        _store,
        widget.transportFor?.call(url) ?? HttpPushTransport(url),
        batchSize: _slow ? 1 : 100,
        batchPause: _slow ? const Duration(milliseconds: 300) : Duration.zero,
      ),
    );
    _stateSub = scheduler.states.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    _scheduler = scheduler..start();
  }

  Future<void> _saveUrl() async {
    final url = _url.text.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dirección inválida. Ej.: http://192.168.1.50:8080'),
        ),
      );
      return;
    }
    await _store.setServerUrl(url);
    _restartScheduler();
  }

  Future<void> _create(int count) async {
    for (var i = 0; i < count; i++) {
      _created++;
      await _store.recordSpikeOperation(
        SpikeOperation(note: 'Prueba $_created', amountCents: _created * 100),
      );
    }
  }

  @override
  void dispose() {
    unawaited(_stateSub?.cancel());
    _scheduler?.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduler = _scheduler;
    final busy = _state.running;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spike 6 · Sincronización'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StreamBuilder<int>(
              stream: _pending,
              builder: (context, snap) =>
                  _StatusChip(pending: snap.data, state: _state),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Servidor', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _url,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Dirección del servidor',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _saveUrl(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _saveUrl, child: const Text('Guardar')),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Equipo: ${_deviceId.isEmpty ? '…' : _deviceId}',
              style: theme.textTheme.bodySmall,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Envío lento'),
              subtitle: const Text(
                '1 operación por solicitud y 300 ms de pausa, para cortar la '
                'conexión a la mitad',
              ),
              value: _slow,
              onChanged: busy
                  ? null
                  : (v) {
                      setState(() => _slow = v);
                      if (scheduler != null) _restartScheduler();
                    },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _create(1),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear operación'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _create(30),
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Crear 30'),
                ),
                FilledButton.icon(
                  onPressed: scheduler == null || busy
                      ? null
                      : () => scheduler.syncNow(),
                  icon: const Icon(Icons.sync),
                  label: const Text('Sincronizar'),
                ),
                OutlinedButton.icon(
                  onPressed: scheduler == null || busy
                      ? null
                      : () => scheduler.syncNow(resendAll: true),
                  icon: const Icon(Icons.replay),
                  label: const Text('Reenviar todo'),
                ),
              ],
            ),
            if (scheduler == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Guarda la dirección del servidor para sincronizar.',
                ),
              ),
            if (_state.error case final e?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${e.message} Reintento en ${_state.nextIn?.inSeconds ?? '-'} s.',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            Text('Operaciones', style: theme.textTheme.titleMedium),
            StreamBuilder<List<OutboxData>>(
              stream: _outbox,
              builder: (context, snap) {
                final rows = snap.data ?? const <OutboxData>[];
                if (rows.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Todavía no hay operaciones.'),
                  );
                }
                return Column(children: [for (final o in rows) _OutboxTile(o)]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.pending, required this.state});

  final int? pending;
  final SyncRunState state;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch ((state, pending)) {
      (SyncRunState(running: true), _) => (Icons.sync, 'Sincronizando…'),
      (SyncRunState(error: _?), final n) => (
        Icons.sync_problem,
        'Error · pendientes ${n ?? '-'}',
      ),
      (_, 0) => (Icons.cloud_done_outlined, 'Sincronizado'),
      (_, final n) => (Icons.cloud_upload_outlined, 'Pendientes ${n ?? '-'}'),
    };
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}

class _OutboxTile extends StatelessWidget {
  const _OutboxTile(this.o);

  final OutboxData o;

  @override
  Widget build(BuildContext context) {
    final status = switch (o.status) {
      'pending' => 'pendiente',
      'applied' => 'aplicada',
      'rejected' => 'rechazada',
      'conflict' => 'conflicto',
      final s => s,
    };
    final extra = [
      if (o.lastResponse == 'duplicate') 'respuesta: duplicado',
      if (o.attempts > 0) 'intentos fallidos: ${o.attempts}',
      if (o.lastError != null) o.lastError!,
      if (o.message != null) o.message!,
    ].join(' · ');
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        o.status == 'pending' ? Icons.schedule : Icons.check_circle_outline,
      ),
      title: Text('${o.opId.substring(24)} · $status'),
      subtitle: extra.isEmpty ? null : Text(extra),
    );
  }
}
