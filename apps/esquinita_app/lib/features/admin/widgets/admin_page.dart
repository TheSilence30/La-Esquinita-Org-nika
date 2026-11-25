import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../prototype/widgets/notice.dart';
import '../../auth/application/auth_providers.dart';
import '../application/admin_client.dart';
import 'business_view.dart';
import 'devices_view.dart';
import 'users_view.dart';

/// "Ajustes" (Administrador only): business data for the ticket, users and
/// devices. The same page on the PC, the tablet and phones; each section is
/// shown only with its permission (the server checks it too).
class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    bool can(String p) => session?.can(p) ?? false;
    final sections = [
      if (can(Permissions.settingsManage))
        ('Negocio', Icons.storefront_outlined, const BusinessView()),
      if (can(Permissions.usersManage))
        ('Usuarios', Icons.people_outline, const UsersView()),
      if (can(Permissions.settingsManage))
        ('Equipos', Icons.devices_outlined, const DevicesView()),
    ];
    if (sections.isEmpty) {
      return const Center(child: Text('Solo un Administrador entra aquí.'));
    }
    return DefaultTabController(
      length: sections.length,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              tabs: [
                for (final (label, icon, _) in sections)
                  Tab(icon: Icon(icon), text: label),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [for (final (_, _, view) in sections) view],
            ),
          ),
        ],
      ),
    );
  }
}

/// Runs an Administrador change: [done] on success, the reason otherwise.
/// True when it went through.
Future<bool> runChange(
  BuildContext context,
  Future<void> Function() change, {
  required String done,
}) async {
  try {
    await change();
    if (context.mounted) showNotice(context, done);
    return true;
  } on AdminFailure catch (e) {
    if (context.mounted) {
      showNotice(context, e.message, level: NoticeLevel.error);
    }
    return false;
  }
}

/// Loading, error with "Reintentar", or the data.
class AsyncSection<T> extends StatelessWidget {
  const AsyncSection({
    super.key,
    required this.value,
    required this.onRetry,
    required this.builder,
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) => switch (value) {
    AsyncData(:final value) => builder(value),
    AsyncError(:final error) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error is AdminFailure
                  ? error.message
                  : 'No se pudo cargar. Intenta de nuevo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    ),
    _ => const Center(child: CircularProgressIndicator()),
  };
}

/// Keeps forms and lists readable on a wide PC window.
class AdminWidth extends StatelessWidget {
  const AdminWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: child,
    ),
  );
}
