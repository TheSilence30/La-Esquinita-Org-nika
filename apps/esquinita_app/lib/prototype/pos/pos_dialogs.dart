import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../demo_data.dart';
import '../demo_store.dart';
import '../widgets/common.dart';
import '../widgets/keypad.dart';

/// Grams to sell and the price per kg to charge. Two directions: weight →
/// price and amount → weight (docs/modelo-datos.md §3.1). The price per kg
/// starts at the presentation's and can be changed for this sale.
typedef WeightPick = ({int grams, int perKgCents});

/// 300 → "300 g", 1500 → "1.500 kg", 2000 → "2 kg".
String weightLabel(int grams) =>
    grams >= 1000 ? '${Quantity(grams)} kg' : '$grams g';

Future<WeightPick?> showWeightCalculator(
  BuildContext context,
  DemoProduct product, {
  int initialGrams = 0,
  int? initialPerKgCents,
}) => showAdaptiveSheet<WeightPick>(
  context,
  builder: (_) => WeightCalculator(
    product: product,
    initialGrams: initialGrams,
    initialPerKgCents: initialPerKgCents,
  ),
);

class WeightCalculator extends StatefulWidget {
  const WeightCalculator({
    super.key,
    required this.product,
    this.initialGrams = 0,
    this.initialPerKgCents,
  });

  final DemoProduct product;
  final int initialGrams;
  final int? initialPerKgCents;

  @override
  State<WeightCalculator> createState() => _WeightCalculatorState();
}

class _WeightCalculatorState extends State<WeightCalculator> {
  late int _grams = widget.initialGrams;
  late int _perKgCents =
      widget.initialPerKgCents ?? widget.product.base.retailCents;
  int _amountCents = 0;
  bool _byAmount = false;

  /// The keypad edits the price per kg instead of the weight/amount.
  bool _editingPrice = false;

  /// Weight typed in kg ("1.5" = 1.500 kg) instead of grams ("500").
  late bool _inKg = widget.initialGrams >= 1000;

  int get _defaultPerKg => widget.product.base.retailCents;
  Money get _perKg => Money(_perKgCents);

  int get _resultGrams => !_byAmount
      ? _grams
      : _perKgCents > 0
      ? weightForAmount(Money(_amountCents), _perKg).milli
      : 0;

  int get _resultCents => priceForWeight(Quantity(_resultGrams), _perKg).cents;

  Widget _field({
    required Key key,
    required String label,
    required String value,
    required bool focused,
    required VoidCallback onTap,
    TextStyle? style,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: InputDecorator(
      isFocused: focused,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      child: Text(value, key: key, style: style),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final big = t.headlineSmall!.merge(tabular);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.product.name, style: t.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Peso → precio'),
                icon: Icon(Icons.scale),
              ),
              ButtonSegment(
                value: true,
                label: Text('Monto → peso'),
                icon: Icon(Icons.payments_outlined),
              ),
            ],
            selected: {_byAmount},
            onSelectionChanged: (s) => setState(() {
              _byAmount = s.single;
              _editingPrice = false;
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  key: const Key('calc-input'),
                  label: _byAmount ? 'Monto que pide' : 'Peso',
                  value: _byAmount
                      ? soles(_amountCents)
                      : _inKg
                      ? '${Quantity(_grams)} kg'
                      : '$_grams g',
                  focused: !_editingPrice,
                  onTap: () => setState(() => _editingPrice = false),
                  style: big,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _field(
                  key: const Key('calc-price'),
                  label: 'Precio por kg',
                  value: soles(_perKgCents),
                  focused: _editingPrice,
                  onTap: () => setState(() => _editingPrice = true),
                  style: big.copyWith(
                    color: _perKgCents == _defaultPerKg
                        ? null
                        : EsquinitaColors.wood,
                  ),
                ),
              ),
            ],
          ),
          if (_perKgCents != _defaultPerKg)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _perKgCents = _defaultPerKg),
                child: Text('Usar precio de lista (${soles(_defaultPerKg)})'),
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: EsquinitaColors.leaf.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _byAmount
                  ? 'Pesar ${weightLabel(_resultGrams)}  ·  '
                        'cobrar ${soles(_resultCents)}'
                  : 'Precio: ${soles(_resultCents)}',
              key: const Key('calc-result'),
              textAlign: TextAlign.center,
              style: t.titleMedium!
                  .merge(tabular)
                  .copyWith(color: EsquinitaColors.forest),
            ),
          ),
          const SizedBox(height: 8),
          if (!_byAmount && !_editingPrice)
            // One scrolling row: a second row pushed the keypad off 640 dp.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8,
                children: [
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: true, label: Text('kg')),
                      ButtonSegment(value: false, label: Text('g')),
                    ],
                    selected: {_inKg},
                    onSelectionChanged: (s) => setState(() => _inKg = s.single),
                  ),
                  for (final g in const [250, 300, 500, 1000, 2000])
                    ActionChip(
                      label: Text(weightLabel(g)),
                      onPressed: () => setState(() => _grams = g),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          NumberPad(
            value: _editingPrice
                ? _perKgCents
                : _byAmount
                ? _amountCents
                : _grams,
            decimals: _editingPrice || _byAmount
                ? 2
                : _inKg
                ? 3
                : 0,
            max: _editingPrice || _byAmount ? 99999 : 50000,
            compact: true,
            onChanged: (v) => setState(() {
              if (_editingPrice) {
                _perKgCents = v;
              } else if (_byAmount) {
                _amountCents = v;
              } else {
                _grams = v;
              }
            }),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: _resultGrams > 0 && _perKgCents > 0
                ? () => Navigator.pop<WeightPick>(context, (
                    grams: _resultGrams,
                    perKgCents: _perKgCents,
                  ))
                : null,
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(
              'Agregar ${weightLabel(_resultGrams)} · ${soles(_resultCents)}',
            ),
          ),
        ],
      ),
    );
  }
}

/// Presentation and quantity for products with several presentations.
Future<(DemoPresentation, int)?> showPresentationPicker(
  BuildContext context,
  DemoProduct product,
) => showAdaptiveSheet<(DemoPresentation, int)>(
  context,
  builder: (_) => _PresentationPicker(product),
);

class _PresentationPicker extends StatefulWidget {
  const _PresentationPicker(this.product);

  final DemoProduct product;

  @override
  State<_PresentationPicker> createState() => _PresentationPickerState();
}

class _PresentationPickerState extends State<_PresentationPicker> {
  late DemoPresentation _selected = widget.product.base;
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.product.name, style: t.titleMedium),
          const SizedBox(height: 8),
          RadioGroup<DemoPresentation>(
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v!),
            child: Column(
              children: [
                for (final p in widget.product.presentations)
                  RadioListTile<DemoPresentation>(
                    value: p,
                    contentPadding: EdgeInsets.zero,
                    title: Text(p.name),
                    subtitle: Text(
                      [
                        if (p.factorMilli != 1000)
                          '${Quantity(p.factorMilli)} unidades',
                        if (p.wholesaleCents != null)
                          'Mayorista ${soles(p.wholesaleCents!)} desde ${Quantity(p.wholesaleMinMilli!)}',
                      ].join(' · '),
                    ),
                    secondary: MoneyText(p.retailCents, style: t.titleMedium),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                tooltip: 'Menos',
                onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  '$_qty',
                  textAlign: TextAlign.center,
                  style: t.headlineSmall!.merge(tabular),
                ),
              ),
              IconButton.outlined(
                tooltip: 'Más',
                onPressed: () => setState(() => _qty++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => Navigator.pop(context, (_selected, _qty * 1000)),
            child: Text('Agregar $_qty × ${_selected.name}'),
          ),
        ],
      ),
    );
  }
}

/// Registered customers only (credit sales need one).
Future<DemoCustomer?> showCustomerPicker(BuildContext context) =>
    showAdaptiveSheet<DemoCustomer>(
      context,
      builder: (context) {
        final customers = DemoScope.read(context).customers;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Cliente registrado',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final c in customers)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(c.name),
                subtitle: Text(c.doc),
                onTap: () => Navigator.pop(context, c),
              ),
            const SizedBox(height: 12),
          ],
        );
      },
    );

/// Adds [product] to the cart, asking for weight or presentation first.
Future<void> addProductFlow(BuildContext context, DemoProduct product) async {
  final store = DemoScope.read(context);
  final messenger = ScaffoldMessenger.of(context);
  String? error;
  if (product.byWeight) {
    final pick = await showWeightCalculator(context, product);
    if (pick == null) return;
    error = store.addToCart(
      product,
      product.base,
      pick.grams,
      perKgCents: pick.perKgCents,
    );
  } else if (product.presentations.length > 1) {
    final picked = await showPresentationPicker(context, product);
    if (picked == null) return;
    error = store.addToCart(product, picked.$1, picked.$2);
  } else {
    error = store.addToCart(product, product.base, 1000);
  }
  if (error != null) {
    messenger.showSnackBar(SnackBar(content: Text(error)));
  }
}
