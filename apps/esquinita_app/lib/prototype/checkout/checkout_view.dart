import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../checkout.dart';
import '../demo_store.dart';
import '../pos/pos_dialogs.dart';
import '../widgets/common.dart';
import '../widgets/keypad.dart';
import 'sale_done.dart';

/// Touch devices: full-screen checkout (route `/cobro`).
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cobrar')),
    body: CheckoutView(
      onDone: (sale) => context.go('/venta', extra: sale),
      onCancel: () => context.pop(),
    ),
  );
}

/// PC: checkout as a keyboard-friendly dialog.
Future<void> showCheckoutDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (dialog) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
      child: CheckoutView(
        onDone: (sale) {
          Navigator.pop(dialog);
          showSaleDoneDialog(context, sale);
        },
        onCancel: () => Navigator.pop(dialog),
      ),
    ),
  ),
);

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key, required this.onDone, required this.onCancel});

  final ValueChanged<DemoSale> onDone;
  final VoidCallback onCancel;

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

/// Which number the keypad is editing.
enum _Field { amount, tendered }

class _CheckoutViewState extends State<CheckoutView> {
  late final DemoStore _store = DemoScope.read(context);
  late final CheckoutDraft _draft = CheckoutDraft(
    _store.cartTotalCents,
    mixedAllowed: _store.mixedPayments,
  )..customer = _store.cartCustomer;

  int _editingPart = 0;
  _Field _field = _Field.tendered;

  PaymentPart get _part => _draft.parts[_editingPart];

  int get _editingValue =>
      _field == _Field.amount ? _part.amountCents : (_part.tenderedCents ?? 0);

  void _setEditing(int v) => setState(() {
    if (_field == _Field.amount) {
      _part.amountCents = v;
    } else {
      _part.tenderedCents = v;
    }
  });

  void _confirm() {
    if (_draft.problem != null) return;
    widget.onDone(_store.confirmSale(_draft));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final problem = _draft.problem;
    final showPad =
        !_draft.credit && (_draft.isMixed || _part.method == PayMethod.cash);
    final details = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Total a cobrar', style: t.labelLarge),
        MoneyText(
          _draft.totalCents,
          style: t.displaySmall!.copyWith(
            color: EsquinitaColors.forest,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Venta a crédito'),
          subtitle: const Text(
            'Solo a clientes registrados. No pide medio de pago ni suma a la caja.',
          ),
          value: _draft.credit,
          onChanged: (v) => setState(() => _draft.credit = v),
        ),
        if (_draft.credit)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline),
            title: Text(_draft.customer?.name ?? 'Elegir cliente registrado'),
            subtitle: Text(_draft.customer?.doc ?? 'Obligatorio para crédito'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final c = await showCustomerPicker(context);
              if (c != null) setState(() => _draft.customer = c);
            },
          )
        else ...[
          if (!_draft.isMixed) ...[
            Text('Medio de pago', style: t.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in PayMethod.values)
                  ChoiceChip(
                    label: Text(m.label),
                    selected: _part.method == m,
                    onSelected: (_) => setState(() {
                      _draft.choose(m);
                      _editingPart = 0;
                      _field = _Field.tendered;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _PartDetails(
              part: _part,
              editingTendered: _field == _Field.tendered,
              onTapTendered: () => setState(() => _field = _Field.tendered),
              onQuick: (c) => setState(() => _part.tenderedCents = c),
              total: _draft.totalCents,
              onReference: () => setState(() {}),
            ),
          ] else ...[
            Text('Pago mixto', style: t.labelLarge),
            for (var i = 0; i < _draft.parts.length; i++)
              _MixedRow(
                index: i,
                part: _draft.parts[i],
                selectedField: i == _editingPart ? _field : null,
                onSelect: (f) => setState(() {
                  _editingPart = i;
                  _field = f;
                }),
                onMethod: (m) => setState(() => _draft.parts[i].method = m),
                onRemove: () => setState(() {
                  _draft.removePart(i);
                  _editingPart = 0;
                  _field = _Field.amount;
                }),
              ),
            Text(
              _draft.remainingCents == 0
                  ? 'Pagos completos'
                  : _draft.remainingCents > 0
                  ? 'Falta ${soles(_draft.remainingCents)}'
                  : 'Sobra ${soles(-_draft.remainingCents)}',
              style: t.bodyMedium!.merge(tabular),
            ),
          ],
          if (_draft.mixedAllowed)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _draft.addPart(PayMethod.yape);
                  _editingPart = _draft.parts.length - 1;
                  _field = _Field.amount;
                }),
                icon: const Icon(Icons.add),
                label: const Text('Agregar otro medio (pago mixto)'),
              ),
            ),
          if (_draft.changeCents > 0)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EsquinitaColors.leaf.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text('Vuelto', style: t.titleMedium),
                  const Spacer(),
                  MoneyText(
                    _draft.changeCents,
                    key: const Key('change'),
                    style: t.headlineSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: EsquinitaColors.forest,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
    final pad = showPad
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: NumberPad(
              value: _editingValue,
              onChanged: _setEditing,
              compact: !wide,
            ),
          )
        : const SizedBox.shrink();
    final footer = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (problem != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                problem,
                key: const Key('problem'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Row(
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
                onPressed: widget.onCancel,
                child: const Text('Volver'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    backgroundColor: EsquinitaColors.leaf,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: problem == null ? _confirm : null,
                  child: Text(
                    _draft.credit
                        ? 'Registrar venta a crédito'
                        : 'Confirmar venta',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _confirm,
        const SingleActivator(LogicalKeyboardKey.escape): widget.onCancel,
      },
      child: wide
          ? Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: details),
                      if (showPad)
                        SizedBox(
                          width: 300,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: pad,
                          ),
                        ),
                    ],
                  ),
                ),
                footer,
              ],
            )
          : Column(
              children: [
                Expanded(child: details),
                pad,
                footer,
              ],
            ),
    );
  }
}

class _PartDetails extends StatelessWidget {
  const _PartDetails({
    required this.part,
    required this.editingTendered,
    required this.onTapTendered,
    required this.onQuick,
    required this.total,
    required this.onReference,
  });

  final PaymentPart part;
  final bool editingTendered;
  final VoidCallback onTapTendered;
  final ValueChanged<int> onQuick;
  final int total;
  final VoidCallback onReference;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (part.method == PayMethod.cash) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTapTendered,
            child: InputDecorator(
              isFocused: editingTendered,
              decoration: const InputDecoration(
                labelText: 'Efectivo recibido',
                border: OutlineInputBorder(),
              ),
              child: MoneyText(
                part.tenderedCents ?? 0,
                key: const Key('tendered'),
                style: t.titleLarge,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final c in quickCashAmounts(total))
                ActionChip(
                  label: Text(c == total ? 'Exacto' : soles(c)),
                  onPressed: () => onQuick(c),
                ),
            ],
          ),
        ],
      );
    }
    if (!part.method.needsReference) return const SizedBox.shrink();
    return TextField(
      decoration: InputDecoration(
        labelText: 'N.º de operación ${part.method.label} (opcional)',
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      onChanged: (v) {
        part.reference = v;
        onReference();
      },
    );
  }
}

class _MixedRow extends StatelessWidget {
  const _MixedRow({
    required this.index,
    required this.part,
    required this.selectedField,
    required this.onSelect,
    required this.onMethod,
    required this.onRemove,
  });

  final int index;
  final PaymentPart part;
  final _Field? selectedField;
  final ValueChanged<_Field> onSelect;
  final ValueChanged<PayMethod> onMethod;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        DropdownButton<PayMethod>(
          value: part.method,
          onChanged: (m) => onMethod(m!),
          items: [
            for (final m in PayMethod.values)
              DropdownMenuItem(value: m, child: Text(m.label)),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () => onSelect(_Field.amount),
            child: InputDecorator(
              isFocused: selectedField == _Field.amount,
              decoration: const InputDecoration(
                labelText: 'Monto',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              child: MoneyText(part.amountCents, key: Key('part-$index')),
            ),
          ),
        ),
        if (part.method == PayMethod.cash) ...[
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => onSelect(_Field.tendered),
              child: InputDecorator(
                isFocused: selectedField == _Field.tendered,
                decoration: const InputDecoration(
                  labelText: 'Recibido',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: MoneyText(part.tenderedCents ?? 0),
              ),
            ),
          ),
        ],
        IconButton(
          tooltip: 'Quitar medio',
          onPressed: onRemove,
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );
}
