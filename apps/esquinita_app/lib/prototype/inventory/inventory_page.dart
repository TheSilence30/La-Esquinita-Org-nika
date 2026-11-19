import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../demo_data.dart';
import '../demo_store.dart';
import '../widgets/keypad.dart';
import '../widgets/notice.dart';

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _qty(DemoProduct p, int milli) =>
    p.byWeight ? '${Quantity(milli)} kg' : '${Quantity(milli)} und';

/// What the inventory list can be narrowed to.
enum StockFilter {
  all('Todos'),
  out('Agotados'),
  low('Stock bajo'),
  expiring('Por vencer (30 días)'),
  expired('Vencidos');

  const StockFilter(this.label);

  final String label;

  bool matches(DemoProduct p, DateTime today) => switch (this) {
    all => true,
    out => p.sellableStockMilli(today) <= 0,
    low =>
      p.sellableStockMilli(today) > 0 && p.totalStockMilli <= p.minStockMilli,
    expiring => p.lots.any((l) => l.qtyMilli > 0 && l.expiresWithin(today, 30)),
    expired => p.lots.any((l) => l.qtyMilli > 0 && l.isExpired(today)),
  };
}

/// Opens the stock sheet of [p] (Administrador: inventory.adjust). Trabajo
/// can still receive a new lot from here (user decision, 2026-11-19).
void showProductStock(BuildContext context, DemoProduct p) {
  if (!DemoScope.read(context).isAdmin) {
    showNotice(
      context,
      'Ajustar stock requiere el rol Administrador.',
      level: NoticeLevel.warn,
      actionLabel: 'Agregar lote',
      onAction: () => showNewLot(context, p),
    );
    return;
  }
  showAdaptiveSheet<void>(
    context,
    maxWidth: 520,
    builder: (_) => ProductStockSheet(product: p),
  );
}

/// Receives a new lot of [p]: code, expiry and quantity. Both roles:
/// Trabajo receives goods without seeing costs (CLAUDE.md §9; the sheet
/// shows no costs).
Future<void> showNewLot(BuildContext context, DemoProduct p) async {
  await showAdaptiveSheet<void>(
    context,
    builder: (_) => NewLotSheet(product: p),
  );
}

/// Local stock with lots and expiry warnings ("stock local": pending
/// operations may not be counted yet, CLAUDE.md §7). Tap a product to see
/// its lots, adjust it and see its movements.
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  StockFilter _filter = StockFilter.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final t = Theme.of(context).textTheme;
    final today = store.now;
    final q = _query.toLowerCase();
    final products = [
      for (final p in store.catalog)
        if (_filter.matches(p, today) &&
            (q.isEmpty ||
                p.name.toLowerCase().contains(q) ||
                p.presentations.any((pr) => pr.barcode == _query) ||
                p.lots.any((l) => l.code.toLowerCase() == q)))
          p,
    ];
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Stock local', style: t.titleLarge),
        const Text(
          'Puede no incluir operaciones de otros equipos aún sin sincronizar.',
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Buscar producto, código o lote',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 6,
            children: [
              for (final f in StockFilter.values)
                ChoiceChip(
                  label: Text(
                    f == StockFilter.all
                        ? f.label
                        : '${f.label} · ${store.catalog.where((p) => f.matches(p, today)).length}',
                  ),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (products.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Nada que mostrar con este filtro.'),
          ),
        for (final p in products) _ProductStockCard(p, today),
      ],
    );
  }
}

class _ProductStockCard extends StatelessWidget {
  const _ProductStockCard(this.product, this.today);

  final DemoProduct product;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final t = Theme.of(context).textTheme;
    final sellable = p.sellableStockMilli(today);
    return Card(
      color: Colors.white,
      child: ListTile(
        onTap: () => showProductStock(context, p),
        title: Text(p.name),
        subtitle: p.tracksLots
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final l in p.lots)
                      if (l.qtyMilli > 0) _LotChip(l, today),
                    if (p.stockMilli > 0)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text('Sin lote · ${Quantity(p.stockMilli)}'),
                      ),
                  ],
                ),
              )
            : Text('${p.category} · sin lotes'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _qty(p, p.totalStockMilli),
              style: t.titleMedium!
                  .merge(tabular)
                  .copyWith(
                    color: p.totalStockMilli <= p.minStockMilli
                        ? EsquinitaColors.red
                        : null,
                  ),
            ),
            if (sellable != p.totalStockMilli)
              Text(
                'vendible ${Quantity(sellable)}',
                style: t.bodySmall!.merge(tabular),
              ),
          ],
        ),
      ),
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
    backgroundColor: _lotColor(lot, today),
  );
}

Color? _lotColor(DemoLot lot, DateTime today) => lot.isExpired(today)
    ? EsquinitaColors.red.withValues(alpha: 0.12)
    : lot.expiresWithin(today, 30)
    ? EsquinitaColors.amber.withValues(alpha: 0.15)
    : null;

enum _Mode { add, remove, count }

/// Why stock goes in or out (Fase 2: `stock_movements.reason`).
const _reasonsIn = ['Recepción de compra', 'Devolución de cliente', 'Ajuste'];
const _reasonsOut = ['Merma / vencido', 'Dañado', 'Consumo interno', 'Ajuste'];

/// Lots (with expiry), stock without lot, entries/exits/counts with a
/// reason, minimum stock and the product's movements (kardex).
/// shortcut: in memory, no audit; Fase 2 makes these real operations.
class ProductStockSheet extends StatefulWidget {
  const ProductStockSheet({super.key, required this.product});

  final DemoProduct product;

  @override
  State<ProductStockSheet> createState() => _ProductStockSheetState();
}

class _ProductStockSheetState extends State<ProductStockSheet> {
  /// Null: the stock without lot.
  late DemoLot? _lot = _firstUsable();
  _Mode _mode = _Mode.add;
  String _reason = _reasonsIn.first;

  /// Grams (by weight) or whole units.
  int _amount = 0;

  DemoProduct get _p => widget.product;
  int get _milli => _p.byWeight ? _amount : _amount * 1000;
  int get _current => _lot?.qtyMilli ?? _p.stockMilli;

  DemoLot? _firstUsable() {
    final now = DemoScope.read(context).now;
    final lots = _p.lots.where((l) => !l.isExpired(now)).toList()
      ..sort((a, b) => a.expiresOn.compareTo(b.expiresOn));
    return lots.firstOrNull ?? _p.lots.firstOrNull;
  }

  void _apply() {
    final store = DemoScope.read(context);
    final where = _lot?.code ?? 'sin lote';
    switch (_mode) {
      case _Mode.add:
        store.adjustStock(_p, _milli, lot: _lot, reason: _reason);
      case _Mode.remove:
        store.adjustStock(_p, -_milli, lot: _lot, reason: _reason);
      case _Mode.count:
        store.countStock(_p, _milli, lot: _lot);
    }
    showNotice(
      context,
      '${_p.name} ($where): stock ${_qty(_p, _p.totalStockMilli)}',
      level: _p.totalStockMilli <= _p.minStockMilli
          ? NoticeLevel.warn
          : NoticeLevel.ok,
    );
    setState(() => _amount = 0);
  }

  Future<void> _editMin() async {
    final store = DemoScope.read(context);
    var v = _p.byWeight ? _p.minStockMilli : _p.minStockMilli ~/ 1000;
    final ok = await showAdaptiveSheet<bool>(
      context,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, set) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Stock mínimo de ${_p.name}'),
              Text(
                _qty(_p, _p.byWeight ? v : v * 1000),
                style: Theme.of(sheet).textTheme.headlineSmall,
              ),
              NumberPad(
                value: v,
                decimals: _p.byWeight ? 3 : 0,
                max: _p.byWeight ? 500000 : 9999,
                compact: true,
                onChanged: (x) => set(() => v = x),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.pop(sheet, true),
                child: const Text('Guardar mínimo'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok ?? false) store.setMinStock(_p, _p.byWeight ? v : v * 1000);
  }

  Widget _source({
    required DemoLot? lot,
    required String title,
    required String subtitle,
    required int qtyMilli,
    Color? color,
  }) {
    final selected = lot == _lot;
    return Material(
      color: color ?? Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        dense: true,
        selected: selected,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Quantity(qtyMilli).toString(),
              style: Theme.of(context).textTheme.titleMedium!.merge(tabular),
            ),
            if (lot != null)
              IconButton(
                tooltip: 'Cambiar vencimiento de ${lot.code}',
                icon: const Icon(Icons.edit_calendar_outlined),
                onPressed: () async {
                  final store = DemoScope.read(context);
                  final d = await _pickExpiry(context, lot.expiresOn);
                  if (d != null) store.setLotExpiry(lot, d);
                },
              ),
          ],
        ),
        onTap: () => setState(() => _lot = lot),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final t = Theme.of(context).textTheme;
    final today = store.now;
    final lots = [..._p.lots]
      ..sort((a, b) => a.expiresOn.compareTo(b.expiresOn));
    final reasons = _mode == _Mode.add ? _reasonsIn : _reasonsOut;
    if (_mode != _Mode.count && !reasons.contains(_reason)) {
      _reason = reasons.first;
    }
    final where = _lot?.code ?? 'sin lote';
    final moves = store.movementsOf(_p).take(8).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_p.name, style: t.titleMedium),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Stock local ${_qty(_p, _p.totalStockMilli)} · '
                  'vendible ${Quantity(_p.sellableStockMilli(today))} · '
                  'mínimo ${Quantity(_p.minStockMilli)}',
                  key: const Key('adjust-stock'),
                  style: t.bodyMedium!.merge(tabular),
                ),
              ),
              TextButton(onPressed: _editMin, child: const Text('Mínimo')),
            ],
          ),
          const SizedBox(height: 4),
          Text('Lotes', style: t.labelLarge),
          for (final l in lots)
            _source(
              lot: l,
              title: l.code,
              subtitle: l.isExpired(today)
                  ? 'VENCIDO ${_date(l.expiresOn)}: no se vende'
                  : 'Vence ${_date(l.expiresOn)}',
              qtyMilli: l.qtyMilli,
              color: _lotColor(l, today),
            ),
          if (_p.stockMilli > 0 || lots.isEmpty)
            _source(
              lot: null,
              title: 'Sin lote',
              subtitle: lots.isEmpty
                  ? 'Este producto aún no tiene lotes'
                  : 'Stock sin lote ni vencimiento',
              qtyMilli: _p.stockMilli,
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Nuevo lote'),
              onPressed: () async {
                final before = _p.lots.length;
                await showNewLot(context, _p);
                if (_p.lots.length > before && mounted) {
                  setState(() => _lot = _p.lots.last);
                }
              },
            ),
          ),
          const Divider(),
          SegmentedButton<_Mode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _Mode.add, label: Text('Entrada')),
              ButtonSegment(value: _Mode.remove, label: Text('Salida')),
              ButtonSegment(value: _Mode.count, label: Text('Conteo')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() {
              _mode = s.single;
              _amount = 0;
            }),
          ),
          const SizedBox(height: 6),
          if (_mode == _Mode.count)
            Text(
              'Escribe lo que contaste en $where (hoy ${Quantity(_current)}); '
              'la diferencia queda como ajuste.',
              style: t.bodySmall,
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final r in reasons)
                  ChoiceChip(
                    label: Text(r),
                    selected: _reason == r,
                    onSelected: (_) => setState(() => _reason = r),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          InputDecorator(
            isFocused: true,
            decoration: InputDecoration(
              labelText: _mode == _Mode.count
                  ? 'Cantidad contada'
                  : _p.byWeight
                  ? 'Cantidad (kg)'
                  : 'Cantidad (und)',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            child: Text(
              _qty(_p, _milli),
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
              backgroundColor: _mode == _Mode.remove
                  ? EsquinitaColors.red
                  : EsquinitaColors.leaf,
            ),
            onPressed: _amount > 0 || _mode == _Mode.count ? _apply : null,
            child: Text(switch (_mode) {
              _Mode.add => 'Sumar ${_qty(_p, _milli)} en $where',
              _Mode.remove => 'Restar ${_qty(_p, _milli)} de $where',
              _Mode.count =>
                'Fijar $where en ${_qty(_p, _milli)} '
                    '(${_milli - _current >= 0 ? '+' : ''}${Quantity(_milli - _current)})',
            }),
          ),
          const SizedBox(height: 12),
          Text('Últimos movimientos', style: t.labelLarge),
          if (moves.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Sin movimientos en esta sesión.'),
            ),
          for (final m in moves)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(m.reason),
              subtitle: Text(
                '${_date(m.at)} ${m.at.hour.toString().padLeft(2, '0')}:'
                '${m.at.minute.toString().padLeft(2, '0')} · '
                '${m.lotCode ?? 'sin lote'}',
              ),
              trailing: Text(
                '${m.deltaMilli > 0 ? '+' : ''}${Quantity(m.deltaMilli)}',
                style: t.titleSmall!
                    .merge(tabular)
                    .copyWith(
                      color: m.deltaMilli > 0
                          ? EsquinitaColors.forest
                          : EsquinitaColors.red,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<DateTime?> _pickExpiry(BuildContext context, DateTime initial) {
  final now = DemoScope.read(context).now;
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 6),
    helpText: 'Fecha de vencimiento',
  );
}

/// New lot: the code printed on the package, its expiry and how much came.
/// If the product has stock without lot, asks whether it belongs to this
/// lot (user decision, 2026-11-19).
class NewLotSheet extends StatefulWidget {
  const NewLotSheet({super.key, required this.product});

  final DemoProduct product;

  @override
  State<NewLotSheet> createState() => _NewLotSheetState();
}

class _NewLotSheetState extends State<NewLotSheet> {
  final _code = TextEditingController();
  DateTime? _expires;
  int _amount = 0;
  String? _error;

  DemoProduct get _p => widget.product;
  int get _milli => _p.byWeight ? _amount : _amount * 1000;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final store = DemoScope.read(context);
    final error =
        store.checkLotCode(_p, _code.text) ??
        (_expires == null ? 'Elige la fecha de vencimiento.' : null) ??
        (_amount <= 0 && _p.stockMilli <= 0
            ? 'Escribe cuánto llegó de este lote.'
            : null);
    setState(() => _error = error);
    if (error != null) return;
    var move = false;
    if (_p.stockMilli > 0) {
      final answer = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: const Text('Stock sin lote'),
          content: Text(
            '${_p.name} tiene ${_qty(_p, _p.stockMilli)} sin lote. '
            '¿Son del lote ${_code.text.trim()}? Así quedan con su fecha de '
            'vencimiento.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Dejar sin lote'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Pasar al lote'),
            ),
          ],
        ),
      );
      if (answer == null) return;
      move = answer;
    }
    final lot = store.addLot(
      _p,
      _code.text,
      _expires!,
      _milli,
      moveUnlotted: move,
    );
    if (!mounted) return;
    showNotice(
      context,
      '${_p.name}: lote ${lot.code} con ${_qty(_p, lot.qtyMilli)} · '
      'stock ${_qty(_p, _p.totalStockMilli)}',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nuevo lote · ${_p.name}', style: t.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Código de lote',
              hintText: 'Ej. LOT36 (viene en el empaque)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            icon: const Icon(Icons.event_outlined),
            label: Text(
              _expires == null
                  ? 'Fecha de vencimiento'
                  : 'Vence ${_date(_expires!)}',
            ),
            onPressed: () async {
              final now = DemoScope.read(context).now;
              final d = await _pickExpiry(
                context,
                _expires ?? now.add(const Duration(days: 90)),
              );
              if (d != null) setState(() => _expires = d);
            },
          ),
          const SizedBox(height: 8),
          InputDecorator(
            isFocused: true,
            decoration: InputDecoration(
              labelText: _p.byWeight
                  ? 'Cantidad que llegó (kg)'
                  : 'Cantidad que llegó (und)',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            child: Text(
              _qty(_p, _milli),
              key: const Key('lot-qty'),
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
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                key: const Key('lot-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: _save,
            child: const Text('Guardar lote'),
          ),
        ],
      ),
    );
  }
}
