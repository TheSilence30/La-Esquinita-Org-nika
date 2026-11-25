import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/application/local_auth.dart';

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
        'PIN · pendientes ${n ?? '-'}',
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
    if (engine.lastError?.needsPassword ?? false) {
      final message = await renewWithPin(context, ref);
      if (message != null) {
        messenger?.showSnackBar(SnackBar(content: Text(message)));
        return;
      }
    }
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

/// Asks the PIN of the user on screen to get a new saved login (ADR-0005).
/// Null when it went through (then sync); otherwise what to tell them.
Future<String?> renewWithPin(BuildContext context, WidgetRef ref) async {
  final userId = ref.read(currentSessionProvider)?.userId;
  if (userId == null) return null;
  final pin = await showDialog<String>(
    context: context,
    builder: (_) => const _PinDialog(),
  );
  if (pin == null) return 'Sin el PIN no se puede sincronizar.';
  final r = await ref.read(localAuthProvider).loginWithPin(userId, pin);
  return switch (r) {
    PinOk() => null,
    WrongPin(:final attemptsLeft) =>
      attemptsLeft == 1
          ? 'PIN incorrecto. Te queda 1 intento.'
          : 'PIN incorrecto. Te quedan $attemptsLeft intentos.',
    PinNeedsPassword(:final reason) => reason,
  };
}

class _PinDialog extends StatefulWidget {
  const _PinDialog();

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _ok() => Navigator.pop(context, _pin.text);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Escribe tu PIN'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Para volver a sincronizar con el servidor.'),
        TextField(
          key: const Key('renew-pin'),
          controller: _pin,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'PIN', counterText: ''),
          onSubmitted: (_) => _ok(),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _ok, child: const Text('Sincronizar')),
    ],
  );
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
