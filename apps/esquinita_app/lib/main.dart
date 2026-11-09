import 'package:flutter/material.dart';

import 'app/theme.dart';
import 'spikes/scan_spike_page.dart';

void main() => runApp(const EsquinitaApp());

class EsquinitaApp extends StatelessWidget {
  const EsquinitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'La Esquinita Orgánika',
      theme: buildTheme(),
      debugShowCheckedModeBanner: false,
      home: const SpikesHomePage(),
    );
  }
}

/// Fase 0 entry point: one tile per hardware spike.
class SpikesHomePage extends StatelessWidget {
  const SpikesHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('La Esquinita · Fase 0')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Spike 1 — Escaneo con cámara'),
            subtitle: const Text('Escaneo continuo, filtro de duplicados'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ScanSpikePage()),
            ),
          ),
        ],
      ),
    );
  }
}
