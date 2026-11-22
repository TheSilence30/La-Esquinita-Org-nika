import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../devices/feedback/scan_feedback.dart';
import '../../features/auth/application/auth_providers.dart';

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
        const Divider(),
        ...sessionTiles(context),
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
        SwitchListTile(
          title: const Text('Sonido al escanear'),
          subtitle: const Text('Pitido con el volumen multimedia'),
          value: ScanFeedback.sound,
          onChanged: (v) => store.update(() => ScanFeedback.sound = v),
        ),
        SwitchListTile(
          title: const Text('Vibración al escanear'),
          value: ScanFeedback.vibrate,
          onChanged: (v) => store.update(() => ScanFeedback.vibrate = v),
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

/// "Cambiar usuario" keeps the saved login (the PIN still works);
/// "Cerrar sesión" ends it here and on the server.
List<Widget> sessionTiles(BuildContext context) {
  final session = ProviderScope.containerOf(context)
      .read(currentSessionProvider.notifier);
  return [
    ListTile(
      leading: const Icon(Icons.switch_account_outlined),
      title: const Text('Cambiar usuario'),
      onTap: session.lock,
    ),
    ListTile(
      leading: const Icon(Icons.logout),
      title: const Text('Cerrar sesión'),
      subtitle: const Text('Para volver a entrar hará falta la contraseña'),
      onTap: session.logout,
    ),
  ];
}
