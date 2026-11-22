import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'print_spike_page.dart';
import 'scan_spike_page.dart';
import 'sync_spike_page.dart';

/// Fase 0 entry point: one tile per hardware spike.
class SpikesHomePage extends ConsumerWidget {
  const SpikesHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.qr_code_scanner),
          title: const Text('Spike 1 — Escaneo con cámara'),
          subtitle: const Text('Escaneo continuo, filtro de duplicados'),
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute<void>(builder: (_) => const ScanSpikePage()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.print_outlined),
          title: const Text('Spikes 3 y 4 — Impresión térmica'),
          subtitle: const Text(
            'Éterma por Bluetooth (tablet) o USB (PC): ticket, logo, tildes',
          ),
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute<void>(builder: (_) => const PrintSpikePage()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.sync),
          title: const Text('Sincronización'),
          subtitle: const Text(
            'Operaciones de prueba sin conexión contra el servidor',
          ),
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute<void>(builder: (_) => const SyncSpikePage()),
          ),
        ),
      ],
    );
  }
}
