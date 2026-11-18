import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../demo_store.dart';

/// Touch "Más" tab.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return ListView(
      children: [
        if (store.isAdmin)
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () => context.go('/dashboard'),
          ),
        ListTile(
          leading: const Icon(Icons.point_of_sale),
          title: const Text('Caja: arqueo y cierre'),
          onTap: () => context.go('/caja'),
        ),
        ListTile(
          leading: const Icon(Icons.science_outlined),
          title: const Text('Ajustes de demostración'),
          subtitle: const Text('Pagos mixtos, rol, estado de sincronización'),
          onTap: () => context.go('/demo'),
        ),
        ListTile(
          leading: const Icon(Icons.build_outlined),
          title: const Text('Spikes de hardware (Fase 0)'),
          onTap: () => context.go('/spikes'),
        ),
      ],
    );
  }
}

/// Prototype switches; none of this exists in the real app.
class DemoSettingsPage extends StatelessWidget {
  const DemoSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        SwitchListTile(
          title: const Text('Pagos mixtos habilitados'),
          subtitle: const Text('Ajuste sales.mixed_payments'),
          value: store.mixedPayments,
          onChanged: (v) => store.update(() => store.mixedPayments = v),
        ),
        const ListTile(title: Text('Rol del usuario (vistas)')),
        RadioGroup<DemoRole>(
          groupValue: store.role,
          onChanged: (v) => store.update(() => store.role = v!),
          child: Column(
            children: [
              for (final r in DemoRole.values)
                RadioListTile<DemoRole>(
                  value: r,
                  title: Text(r.label),
                  subtitle: Text(
                    r == DemoRole.admin
                        ? 'Ve todo: dashboard, reportes, costos'
                        : 'Solo vender, escanear, stock, pedidos, clientes y caja',
                  ),
                ),
            ],
          ),
        ),
        const ListTile(title: Text('Estado de sincronización (simulado)')),
        RadioGroup<DemoSyncState>(
          groupValue: store.syncState,
          onChanged: (v) => store.update(() => store.syncState = v!),
          child: const Column(
            children: [
              RadioListTile(
                value: DemoSyncState.synced,
                title: Text('Sincronizado'),
              ),
              RadioListTile(
                value: DemoSyncState.pending,
                title: Text('Pendientes'),
              ),
              RadioListTile(value: DemoSyncState.error, title: Text('Error')),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.devices_other),
          title: const Text('Simular ventas sin enviar en la PC'),
          subtitle: Text('Ahora: ${store.devices[1].pendingSales}'),
          onTap: () => store.update(() => store.devices[1].pendingSales += 2),
        ),
      ],
    );
  }
}
