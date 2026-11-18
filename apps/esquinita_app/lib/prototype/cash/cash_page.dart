import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../checkout.dart';
import '../demo_store.dart';
import '../widgets/common.dart';
import '../widgets/keypad.dart';

/// One shared cash drawer (docs/modelo-datos.md §3.5): expected by method,
/// counted cash, difference, and each device's sync state before closing.
class CashPage extends StatefulWidget {
  const CashPage({super.key});

  @override
  State<CashPage> createState() => _CashPageState();
}

class _CashPageState extends State<CashPage> {
  int _counted = 0;
  int _float = 10000;
  bool _waiting = false;
  Timer? _wait;

  @override
  void dispose() {
    _wait?.cancel();
    super.dispose();
  }

  /// "Esperar": the screen refreshes until the devices report 0 pending
  /// (simulated: they finish in 3 s).
  void _startWaiting(DemoStore store) {
    setState(() => _waiting = true);
    _wait = Timer(const Duration(seconds: 3), () {
      store.simulateDevicesSynced();
      if (mounted) setState(() => _waiting = false);
    });
  }

  Future<void> _close(DemoStore store) async {
    if (store.pendingSalesOnOtherDevices > 0) {
      final reason = await showDialog<String>(
        context: context,
        builder: (_) => const _OverrideDialog(),
      );
      if (reason == null || !mounted) return;
    }
    store.closeCash();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Caja cerrada. Diferencia: ${soles(_counted - store.expectedCashCents)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final t = Theme.of(context).textTheme;
    if (!store.cashOpen) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('La caja está cerrada', style: t.headlineSmall),
          const SizedBox(height: 8),
          const Text('Fondo inicial para abrir:'),
          MoneyText(_float, style: t.headlineMedium),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: NumberPad(
              value: _float,
              onChanged: (v) => setState(() => _float = v),
              compact: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => store.openCash(_float),
            icon: const Icon(Icons.lock_open),
            label: const Text('Abrir caja'),
          ),
        ],
      );
    }
    final session = store.sessionSales;
    final expected = store.expectedCashCents;
    final diff = _counted - expected;
    final pending = store.pendingSalesOnOtherDevices;
    final summary = Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Caja abierta desde las ${store.cashOpenedAt.hour.toString().padLeft(2, '0')}:${store.cashOpenedAt.minute.toString().padLeft(2, '0')}',
              style: t.titleMedium,
            ),
            const SizedBox(height: 8),
            _row('Fondo inicial', soles(store.openingFloatCents)),
            for (final m in PayMethod.values)
              _row(
                m.affectsCashDrawer
                    ? '${m.label} (cajón)'
                    : '${m.label} (no entra al cajón)',
                soles(store.methodTotal(m, session)),
              ),
            const Divider(),
            _row('Efectivo esperado', soles(expected), bold: true),
            const Text(
              'Calculado por el servidor con las ventas de todos los equipos.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
    final devices = Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estado de los equipos', style: t.titleMedium),
            for (final d in store.devices)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  d.pendingSales == 0
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_upload_outlined,
                  color: d.pendingSales == 0
                      ? EsquinitaColors.leaf
                      : EsquinitaColors.amber,
                ),
                title: Text(d.name),
                subtitle: Text(
                  'Última sincronización: hace ${_ago(store.now.difference(d.lastSync))}'
                  '${d.pendingSales == 0 ? ' · sin pendientes' : ' · ${d.pendingSales} ventas sin enviar'}',
                ),
              ),
            if (pending > 0)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: EsquinitaColors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: EsquinitaColors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hay $pending ventas sin enviar en otro equipo. El esperado puede cambiar.',
                      ),
                    ),
                    TextButton(
                      onPressed: _waiting ? null : () => _startWaiting(store),
                      child: _waiting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Esperar'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
    final count = Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Arqueo: efectivo contado', style: t.titleMedium),
            MoneyText(
              _counted,
              key: const Key('counted'),
              style: t.headlineMedium,
            ),
            Text(
              diff == 0
                  ? 'Cuadra'
                  : diff > 0
                  ? 'Sobra ${soles(diff)}'
                  : 'Falta ${soles(-diff)}',
              key: const Key('difference'),
              style: t.titleMedium!.copyWith(
                color: diff == 0 ? EsquinitaColors.leaf : EsquinitaColors.red,
              ),
            ),
            const SizedBox(height: 8),
            NumberPad(
              value: _counted,
              onChanged: (v) => setState(() => _counted = v),
              compact: true,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () => _close(store),
              icon: const Icon(Icons.lock_outline),
              label: Text(
                pending > 0 ? 'Cerrar de todos modos' : 'Cerrar caja',
              ),
            ),
          ],
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= 900
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [summary, const SizedBox(height: 12), devices],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(width: 380, child: count),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                devices,
                const SizedBox(height: 12),
                summary,
                const SizedBox(height: 12),
                count,
              ],
            ),
    );
  }
}

Widget _row(String a, String b, {bool bold = false}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 2),
  child: Row(
    children: [
      Expanded(
        child: Text(
          a,
          style: TextStyle(fontWeight: bold ? FontWeight.w700 : null),
        ),
      ),
      Text(
        b,
        style: tabular.copyWith(fontWeight: bold ? FontWeight.w700 : null),
      ),
    ],
  ),
);

String _ago(Duration d) =>
    d.inSeconds < 60 ? '${d.inSeconds} s' : '${d.inMinutes} min';

class _OverrideDialog extends StatefulWidget {
  const _OverrideDialog();

  @override
  State<_OverrideDialog> createState() => _OverrideDialogState();
}

class _OverrideDialogState extends State<_OverrideDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Cerrar con ventas sin enviar'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Escribe el motivo. Quedará en la auditoría y las ventas que lleguen después irán a la siguiente caja.',
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reason,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _reason.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, _reason.text.trim()),
        child: const Text('Cerrar caja'),
      ),
    ],
  );
}
