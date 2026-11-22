import 'dart:async';

import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../data/local/database.dart';
import '../data/sync/outbox_store.dart';
import '../data/sync/sync_client.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/sync/application/sync_providers.dart';
import '../features/sync/widgets/sync_chip.dart';

/// Sync test page (Spike 6, now on the real engine): test operations
/// recorded offline survive a restart and reach the server exactly once.
/// They never touch sales or stock (plan Fase 1 §B).
class SyncSpikePage extends ConsumerStatefulWidget {
  const SyncSpikePage({super.key});

  @override
  ConsumerState<SyncSpikePage> createState() => _SyncSpikePageState();
}

class _SyncSpikePageState extends ConsumerState<SyncSpikePage> {
  late final OutboxStore _store = ref.read(outboxStoreProvider);
  late final _outbox = _store.watchOutbox();
  late final SyncScheduler _engine = ref.read(syncEngineProvider);
  String _deviceId = '';
  String? _url;
  bool _slow = false;
  int _created = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    final id = await _store.deviceId();
    final url = await _store.serverUrl();
    if (mounted) {
      setState(() {
        _deviceId = id;
        _url = url;
      });
    }
  }

  void _setSlow(bool slow) {
    setState(() => _slow = slow);
    _engine.client
      ..batchSize = slow ? 1 : 100
      ..batchPause = slow ? const Duration(milliseconds: 300) : Duration.zero;
  }

  Future<void> _create(int count) async {
    final userId = ref.read(currentSessionProvider)?.userId;
    if (userId == null) return;
    for (var i = 0; i < count; i++) {
      _created++;
      await _store.recordSpikeOperation(
        SpikeOperation(note: 'Prueba $_created', amountCents: _created * 100),
        userId: userId,
      );
    }
  }

  @override
  void dispose() {
    if (_slow) _setSlowQuietly();
    super.dispose();
  }

  // Back to normal batches when leaving the page.
  void _setSlowQuietly() => _engine.client
    ..batchSize = 100
    ..batchPause = Duration.zero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ref.watch(syncStatusProvider);
    final busy = status.run.running;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pruebas · Sincronización'),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 12), child: SyncChip()),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Servidor: ${_url ?? '…'} · Equipo: '
              '${_deviceId.isEmpty ? '…' : _deviceId}',
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
              onChanged: busy ? null : _setSlow,
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
                  onPressed: busy ? null : () => _engine.syncNow(),
                  icon: const Icon(Icons.sync),
                  label: const Text('Sincronizar'),
                ),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => _engine.syncNow(resendAll: true),
                  icon: const Icon(Icons.replay),
                  label: const Text('Reenviar todo'),
                ),
              ],
            ),
            if (status.run.error case final e?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(switch (status.run.nextIn) {
                  final d? => '${e.message} Reintento en ${d.inSeconds} s.',
                  null => e.message,
                }, style: TextStyle(color: theme.colorScheme.error)),
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
