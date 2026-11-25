import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/lima_time.dart';
import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../application/admin_client.dart';
import '../application/admin_providers.dart';
import 'admin_page.dart';

/// This device's id (to mark it and keep it out of "Dar de baja").
final _thisDevice = FutureProvider.autoDispose<String>(
  (ref) => ref.watch(outboxStoreProvider).deviceId(),
);

/// Registered devices. A device that has not connected for a while is still
/// in service (user, 2026-11-25): only "Dar de baja" blocks one.
class DevicesView extends ConsumerWidget {
  const DevicesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(_thisDevice).value;
    final showInactive = ref.watch(adminShowInactiveProvider);
    return AsyncSection(
      value: ref.watch(adminDevicesProvider),
      onRetry: () => ref.invalidate(adminDevicesProvider),
      builder: (devices) => AdminWidth(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                '«Dar de baja» es para un equipo perdido o que ya no se usa: '
                'el servidor lo rechaza hasta que lo reactives. Lo que guarda '
                'el equipo no se borra, y al reactivarlo vuelve a sincronizar '
                'solo.',
              ),
            ),
            ShowInactiveSwitch(
              inactive: devices.where((d) => !d.active).length,
            ),
            for (final d in devices)
              if (d.active || showInactive)
                _DeviceTile(device: d, isMe: d.id == me),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends ConsumerWidget {
  const _DeviceTile({required this.device, required this.isMe});

  final AdminDevice device;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = device;
    final details = [
      'Serie ${d.seriesPrefix}',
      if (!d.active) 'Dado de baja',
      switch (d.lastSeenAt) {
        null => 'Sin conexión registrada',
        final at => 'Última conexión: ${limaDateTime(at)}',
      },
      if (d.pendingOps > 0) 'Pendientes: ${d.pendingOps}',
    ];
    return ListTile(
      key: Key('device-${d.seriesPrefix}'),
      leading: Icon(
        d.platform == 'windows' ? Icons.desktop_windows_outlined : Icons.tablet,
        color: d.active ? EsquinitaColors.forest : Colors.grey,
      ),
      title: Text(isMe ? '${d.name} (este equipo)' : d.name),
      subtitle: Text(details.join(' · ')),
      onTap: () => _rename(context, ref),
      trailing: isMe
          ? null
          : d.active
          ? TextButton(
              style: TextButton.styleFrom(foregroundColor: EsquinitaColors.red),
              onPressed: () => _setActive(context, ref, active: false),
              child: const Text('Dar de baja'),
            )
          : OutlinedButton(
              onPressed: () => _setActive(context, ref, active: true),
              child: const Text('Reactivar'),
            ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(current: device.name),
    );
    if (name == null || name == device.name || !context.mounted) return;
    final ok = await runChange(
      context,
      () => ref.read(adminClientProvider).renameDevice(device.id, name),
      done: 'Nombre del equipo cambiado.',
    );
    if (ok) ref.invalidate(adminDevicesProvider);
  }

  Future<void> _setActive(
    BuildContext context,
    WidgetRef ref, {
    required bool active,
  }) async {
    if (!active && !await _confirm(context)) return;
    if (!context.mounted) return;
    final ok = await runChange(
      context,
      () => ref
          .read(adminClientProvider)
          .setDeviceActive(device.id, active: active),
      done: active ? 'Equipo reactivado.' : 'Equipo dado de baja.',
    );
    if (ok) ref.invalidate(adminDevicesProvider);
  }

  Future<bool> _confirm(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text('¿Dar de baja «${device.name}»?'),
          content: Text(
            'El servidor lo rechazará hasta que lo reactives. Lo que guarda '
            'el equipo no se borra'
            '${device.pendingOps > 0 ? ', pero sus ${device.pendingOps} operaciones pendientes no llegarán mientras esté de baja' : ''}. '
            'Al reactivarlo vuelve a sincronizar solo, sin contraseña.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: EsquinitaColors.red,
              ),
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Dar de baja'),
            ),
          ],
        ),
      ) ??
      false;
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.current});

  final String current;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.current);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _ok() {
    if (_form.currentState!.validate()) {
      Navigator.pop(context, _name.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nombre del equipo'),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _name,
        autofocus: true,
        maxLength: 60,
        decoration: const InputDecoration(
          labelText: 'Nombre',
          helperText: 'Por ejemplo: Tablet caja 2',
        ),
        validator: (v) =>
            (v ?? '').trim().isEmpty ? 'Escribe un nombre.' : null,
        onFieldSubmitted: (_) => _ok(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _ok, child: const Text('Guardar')),
    ],
  );
}
