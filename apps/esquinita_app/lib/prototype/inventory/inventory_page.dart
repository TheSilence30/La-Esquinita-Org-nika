import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../demo_data.dart';
import '../demo_store.dart';
import '../widgets/keypad.dart';
import '../widgets/notice.dart';

String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

String _qty(DemoProduct p, int milli) =>
    p.byWeight ? '${Quantity(milli)} kg' : '${Quantity(milli)} und';

/// Local stock with lots and expiry warnings ("stock local": pending
/// operations may not be counted yet, CLAUDE.md §7). Tap a product to
/// adjust it (Administrador).
class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Stock local', style: t.titleLarge),
        const Text(
          'Puede no incluir operaciones de otros equipos aún sin sincronizar. '
          'Toca un producto para ajustar su stock.',
        ),
        const SizedBox(height: 8),
        for (final p in store.catalog)
          Card(
            color: Colors.white,
            child: ListTile(
              onTap: () => store.isAdmin
                  ? showAdaptiveSheet<void>(
                      context,
                      builder: (_) => StockAdjustSheet(product: p),
                    )
                  : showNotice(
                      context,
                      'Ajustar stock requiere el rol Administrador.',
                      level: NoticeLevel.warn,
                    ),
              title: Text(p.name),
              subtitle: p.tracksLots
                  ? Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final l in p.lots) _LotChip(l, store.now),
                      ],
                    )
                  : Text(p.category),
              trailing: Text(
                _qty(p, p.totalStockMilli),
                style: t.titleMedium!
                    .merge(tabular)
                    .copyWith(
                      color: p.totalStockMilli <= p.minStockMilli
                          ? EsquinitaColors.red
                          : null,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LotChip extends StatelessWidget {
  const _LotChip(this.lot, this.today);

  final DemoLot lot;
  final DateTime today;

  @override
  Widget build(BuildContext context) => Chip(
    visualDensity: VisualDensity.compact,
    label: Text(
      '${lot.code} · ${Quantity(lot.qtyMilli)} · '
      '${lot.isExpired(today) ? 'VENCIDO' : 'vence ${_date(lot.expiresOn)}'}',
    ),
    backgroundColor: lot.isExpired(today)
        ? EsquinitaColors.red.withValues(alpha: 0.12)
        : lot.expiresWithin(today, 30)
        ? EsquinitaColors.amber.withValues(alpha: 0.15)
        : null,
  );
}

/// Add or remove stock (per lot when the product has lots), change a lot's
/// expiry or add a lot. Prototype: in memory, no reason or audit yet.
class StockAdjustSheet extends StatefulWidget {
  const StockAdjustSheet({super.key, required this.product});

  final DemoProduct product;

  @override
  State<StockAdjustSheet> createState() => _StockAdjustSheetState();
}

class _StockAdjustSheetState extends State<StockAdjustSheet> {
  late DemoLot? _lot = widget.product.lots.firstOrNull;
  bool _add = true;

  /// Grams (by weight) or whole units.
  int _amount = 0;

  DemoProduct get _p => widget.product;
  int get _deltaMilli => _p.byWeight ? _amount : _amount * 1000;

  Future<DateTime?> _pickDate(DateTime initial) {
    final now = DemoScope.read(context).now;
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      helpText: 'Fecha de vencimiento',
    );
  }

  void _apply() {
    final store = DemoScope.read(context);
    store.adjustStock(_p, _add ? _deltaMilli : -_deltaMilli, lot: _lot);
    showNotice(
      context,
      '${_p.name}: ${_add ? '+' : '−'}${_qty(_p, _deltaMilli)} · '
      'stock ${_qty(_p, _p.totalStockMilli)}',
    );
    setState(() => _amount = 0);
  }

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final t = Theme.of(context).textTheme;
    final lot = _lot;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_p.name, style: t.titleMedium),
          Text(
            'Stock local: ${_qty(_p, _p.totalStockMilli)} · '
            'mínimo ${_qty(_p, _p.minStockMilli)}',
            key: const Key('adjust-stock'),
            style: t.bodyMedium!.merge(tabular),
          ),
          if (_p.tracksLots) ...[
            const SizedBox(height: 8),
            Text('Lote', style: t.labelLarge),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final l in _p.lots)
                  ChoiceChip(
                    label: Text(
                      '${l.code} · ${Quantity(l.qtyMilli)} · '
                      '${l.isExpired(store.now) ? 'VENCIDO' : _date(l.expiresOn)}',
                    ),
                    selected: l == lot,
                    onSelected: (_) => setState(() => _lot = l),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add),
                  label: const Text('Nuevo lote'),
                  onPressed: () async {
                    final d = await _pickDate(
                      store.now.add(const Duration(days: 90)),
                    );
                    if (d == null || !mounted) return;
                    final l = store.addLot(_p, d, 0);
                    setState(() {
                      _lot = l;
                      _add = true;
                    });
                  },
                ),
              ],
            ),
            if (lot != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.event_outlined),
                  label: Text('Cambiar vencimiento de ${lot.code}'),
                  onPressed: () async {
                    final d = await _pickDate(lot.expiresOn);
                    if (d != null) store.setLotExpiry(lot, d);
                  },
                ),
              ),
          ],
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Entrada'),
                icon: Icon(Icons.add),
              ),
              ButtonSegment(
                value: false,
                label: Text('Salida'),
                icon: Icon(Icons.remove),
              ),
            ],
            selected: {_add},
            onSelectionChanged: (s) => setState(() => _add = s.single),
          ),
          const SizedBox(height: 8),
          InputDecorator(
            isFocused: true,
            decoration: InputDecoration(
              labelText: _p.byWeight ? 'Cantidad (kg)' : 'Cantidad (und)',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            child: Text(
              _qty(_p, _deltaMilli),
              key: const Key('adjust-qty'),
              style: t.headlineSmall!.merge(tabular),
            ),
          ),
          const SizedBox(height: 8),
          NumberPad(
            value: _amount,
            decimals: _p.byWeight ? 3 : 0,
            max: _p.byWeight ? 500000 : 9999,
            compact: true,
            onChanged: (v) => setState(() => _amount = v),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: _add
                  ? EsquinitaColors.leaf
                  : EsquinitaColors.red,
            ),
            onPressed: _amount > 0 ? _apply : null,
            child: Text(
              '${_add ? 'Sumar' : 'Restar'} ${_qty(_p, _deltaMilli)}'
              '${lot == null ? '' : ' en ${lot.code}'}',
            ),
          ),
        ],
      ),
    );
  }
}
