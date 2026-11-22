import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../prototype/widgets/common.dart';
import '../application/sync_providers.dart';

/// Always-visible sync indicator (CLAUDE.md §7, §10): synced, pending N or
/// error. A tap syncs now and says how it went.
class SyncChip extends ConsumerWidget {
  const SyncChip({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(syncStatusProvider);
    final n = s.pending;
    final (icon, label, color) = switch (s.run) {
      _ when s.run.running => (
        Icons.sync,
        'Sincronizando…',
        EsquinitaColors.leaf,
      ),
      final r when r.error?.needsPassword ?? false => (
        Icons.lock_clock_outlined,
        'Contraseña · pendientes ${n ?? '-'}',
        EsquinitaColors.red,
      ),
      final r when r.error != null => (
        Icons.sync_problem,
        'Error · pendientes ${n ?? '-'}',
        EsquinitaColors.red,
      ),
      _ when n == 0 => (
        Icons.cloud_done_outlined,
        'Sincronizado',
        EsquinitaColors.leaf,
      ),
      _ => (
        Icons.cloud_upload_outlined,
        'Pendientes ${n ?? '-'}',
        EsquinitaColors.amber,
      ),
    };
    return Semantics(
      button: true,
      label: '$label. Toca para sincronizar.',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _syncNow(context, ref),
        child: StatusPill(
          icon: icon,
          label: label,
          color: color,
          onDark: onDark,
        ),
      ),
    );
  }

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    final engine = ref.read(syncEngineProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    await engine.syncNow();
    final e = engine.lastError;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          e == null
              ? 'Sincronizado.'
              : e.needsPassword
              ? e.message
              : '${e.message} Se reintenta solo.',
        ),
      ),
    );
  }
}

/// Starts a sync round when someone logs in (this widget is built once per
/// login) and when the app comes back to the foreground (user, 2026-11-22).
class SyncTriggers extends ConsumerStatefulWidget {
  const SyncTriggers({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SyncTriggers> createState() => _SyncTriggersState();
}

class _SyncTriggersState extends ConsumerState<SyncTriggers> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _sync);
    _sync();
  }

  void _sync() => unawaited(ref.read(syncEngineProvider).syncNow());

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
