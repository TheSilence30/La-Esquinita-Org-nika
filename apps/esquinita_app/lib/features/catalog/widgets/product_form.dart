import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../data/local/catalog_store.dart';
import '../../../data/local/database.dart';
import '../../auth/application/auth_providers.dart';
import '../application/catalog_providers.dart';
import '../application/product_draft.dart';

/// "Nuevo producto" for [code] (scanned, typed or a generated `29…`): base
/// unit (und, kg, l) priced per unit, more presentations with their factor
/// ("Caja" 12 und, "Bolsa 500 g" 0,5 kg), and the initial stock.
class ProductForm extends ConsumerStatefulWidget {
  const ProductForm({
    super.key,
    required this.code,
    required this.generated,
    required this.onSaved,
    required this.onCancel,
  });

  final String code;
  final bool generated;
  final ValueChanged<String> onSaved;
  final VoidCallback onCancel;

  @override
  ConsumerState<ProductForm> createState() => _ProductFormState();
}

class _Extra {
  final name = TextEditingController();
  final factor = TextEditingController();
  final price = TextEditingController();
  final barcode = TextEditingController();

  List<TextEditingController> get all => [name, factor, price, barcode];
}

class _ProductFormState extends ConsumerState<ProductForm> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _wholesale = TextEditingController();
  final _wholesaleMin = TextEditingController();
  final _cost = TextEditingController();
  final _minStock = TextEditingController();
  final _initial = TextEditingController();
  final _lot = TextEditingController();
  final _extras = <_Extra>[];
  String? _categoryId;
  String? _brandId;
  String? _unitId;
  bool _tracksLots = false;
  DateTime? _expires;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _price,
      _wholesale,
      _wholesaleMin,
      _cost,
      _minStock,
      _initial,
      _lot,
      for (final x in _extras) ...x.all,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Empty → [empty]; otherwise the parsed value or a [FormatException]
  /// with [what] for the screen.
  int _num(
    int? Function(String) parse,
    TextEditingController c,
    String what, {
    int empty = 0,
  }) => c.text.trim().isEmpty
      ? empty
      : parse(c.text) ?? (throw FormatException('Revisa $what.'));

  Future<void> _save(ReplicaUnit unit) async {
    final session = ref.read(currentSessionProvider);
    if (session == null) return;
    final ProductDraft draft;
    try {
      final price = _num(parseCents, _price, 'el precio', empty: -1);
      if (price < 0) throw const FormatException('Escribe el precio.');
      final wholesale = _wholesale.text.trim().isEmpty
          ? null
          : _num(parseCents, _wholesale, 'el precio mayorista');
      draft = ProductDraft(
        name: _name.text,
        categoryId: _categoryId ?? '',
        brandId: _brandId,
        unitId: unit.id,
        base: PresentationDraft(
          name: unit.name,
          factorMilli: 1000,
          priceCents: price,
          wholesaleCents: wholesale,
          wholesaleMinMilli: wholesale == null
              ? null
              : _num(
                  parseMilli,
                  _wholesaleMin,
                  'el mínimo mayorista',
                  empty: 1000,
                ),
          barcode: widget.code,
          generatedBarcode: widget.generated,
        ),
        extras: [
          for (final x in _extras)
            PresentationDraft(
              name: x.name.text,
              factorMilli: _num(
                parseMilli,
                x.factor,
                'cuánto contiene «${x.name.text.trim()}» (por ejemplo 12 o 0,5)',
                empty: -1,
              ),
              priceCents: _num(
                parseCents,
                x.price,
                'el precio de «${x.name.text.trim()}»',
                empty: -1,
              ),
              barcode: x.barcode.text,
            ),
        ],
        tracksLots: _tracksLots,
        minStockMilli: _num(parseMilli, _minStock, 'el stock mínimo'),
        costCents: _num(parseCents, _cost, 'el costo'),
        initialMilli: _num(parseMilli, _initial, 'el stock inicial'),
        lotCode: _lot.text,
        expiresOn: _expires?.toIso8601String().substring(0, 10),
      );
    } on FormatException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = await registerProduct(
        ref.read(catalogStoreProvider),
        draft,
        userId: session.userId,
      );
      if (mounted) widget.onSaved(id);
    } on CatalogException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(catalogOptionsProvider).value;
    final session = ref.watch(currentSessionProvider);
    if (options == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (options.categories.isEmpty || options.units.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Faltan las categorías y unidades. Sincroniza una vez con conexión.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final unit = options.units.firstWhere(
      (u) => u.id == _unitId,
      orElse: () => options.units.firstWhere(
        (u) => u.code == 'und',
        orElse: () => options.units.first,
      ),
    );
    final per = unit.name.toLowerCase();
    final t = Theme.of(context).textTheme;
    InputDecoration box(String label) =>
        InputDecoration(labelText: label, border: const OutlineInputBorder());
    const money = TextInputType.numberWithOptions(decimal: true);
    const gap = SizedBox(height: 12);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Nuevo producto', style: t.titleLarge),
        Text(
          widget.generated
              ? 'Código interno generado: ${widget.code}'
              : 'Código: ${widget.code}',
          style: t.bodyMedium!.merge(tabular),
        ),
        gap,
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: box('Nombre'),
        ),
        gap,
        DropdownButtonFormField<String>(
          initialValue: _categoryId ??= options.categories.first.id,
          isExpanded: true,
          decoration: box('Categoría'),
          items: [
            for (final c in options.categories)
              DropdownMenuItem(value: c.id, child: Text(c.name)),
          ],
          onChanged: (v) => setState(() => _categoryId = v),
        ),
        gap,
        DropdownButtonFormField<String?>(
          initialValue: _brandId,
          isExpanded: true,
          decoration: box('Marca'),
          items: [
            const DropdownMenuItem(child: Text('Sin marca')),
            for (final b in options.brands)
              DropdownMenuItem(value: b.id, child: Text(b.name)),
          ],
          onChanged: (v) => setState(() => _brandId = v),
        ),
        gap,
        DropdownButtonFormField<String>(
          key: const Key('product-unit'),
          initialValue: unit.id,
          isExpanded: true,
          decoration: box('Se vende por'),
          items: [
            for (final u in options.units)
              DropdownMenuItem(
                value: u.id,
                child: Text('${u.name} (${u.code})'),
              ),
          ],
          onChanged: (v) => setState(() => _unitId = v),
        ),
        gap,
        TextField(
          controller: _price,
          keyboardType: money,
          decoration: box('Precio por $per (S/)'),
        ),
        gap,
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _wholesale,
                keyboardType: money,
                decoration: box('Precio mayorista (S/)'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _wholesaleMin,
                keyboardType: money,
                decoration: box('Mayorista desde (${unit.code})'),
              ),
            ),
          ],
        ),
        gap,
        Text('Otras presentaciones', style: t.titleMedium),
        for (final (i, x) in _extras.indexed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: x.name,
                    decoration: box('Nombre (Caja, Bolsa 500 g…)'),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: x.factor,
                    keyboardType: money,
                    decoration: box('Contiene (${unit.code})'),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: x.price,
                    keyboardType: money,
                    decoration: box('Precio (S/)'),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: x.barcode,
                    keyboardType: TextInputType.number,
                    decoration: box('Su código (opcional)'),
                  ),
                ),
                IconButton(
                  tooltip: 'Quitar presentación',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() {
                    for (final c in _extras.removeAt(i).all) {
                      c.dispose();
                    }
                  }),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => setState(() => _extras.add(_Extra())),
            icon: const Icon(Icons.add),
            label: const Text('Agregar presentación (caja, paquete, bolsa…)'),
          ),
        ),
        if (session?.can('catalog.view_cost') ?? false) ...[
          gap,
          TextField(
            key: const Key('product-cost-field'),
            controller: _cost,
            keyboardType: money,
            decoration: box('Costo por $per (S/)'),
          ),
        ],
        gap,
        TextField(
          controller: _minStock,
          keyboardType: money,
          decoration: box('Stock mínimo (${unit.code})'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Controla lotes y vencimientos'),
          value: _tracksLots,
          onChanged: (v) => setState(() => _tracksLots = v),
        ),
        TextField(
          controller: _initial,
          keyboardType: money,
          decoration: box('Stock inicial (${unit.code})'),
        ),
        if (_tracksLots) ...[
          gap,
          TextField(controller: _lot, decoration: box('Código de lote')),
          gap,
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            icon: const Icon(Icons.event_outlined),
            label: Text(
              _expires == null
                  ? 'Vencimiento: no vence (tocar para elegir)'
                  : 'Vence ${MaterialLocalizations.of(context).formatCompactDate(_expires!)}',
            ),
            onPressed: () async {
              final now = DateTime.now();
              final d = await showDatePicker(
                context: context,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 10),
                initialDate: _expires ?? now,
              );
              setState(() => _expires = d);
            },
          ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              key: const Key('product-form-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
              onPressed: widget.onCancel,
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                onPressed: _saving || session == null
                    ? null
                    : () => _save(unit),
                child: const Text('Guardar producto'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
