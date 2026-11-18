import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../demo_data.dart';
import '../demo_store.dart';
import '../widgets/common.dart';
import '../widgets/keypad.dart';

/// Grams to sell. Two directions: weight → price and amount → weight
/// (docs/modelo-datos.md §3.1), with the presentation's price per kg.
Future<int?> showWeightCalculator(
  BuildContext context,
  DemoProduct product, {
  int initialGrams = 0,
}) => showAdaptiveSheet<int>(
  context,
  builder: (_) =>
      WeightCalculator(product: product, initialGrams: initialGrams),
);

class WeightCalculator extends StatefulWidget {
  const WeightCalculator({
    super.key,
    required this.product,
    this.initialGrams = 0,
  });

  final DemoProduct product;
  final int initialGrams;

  @override
  State<WeightCalculator> createState() => _WeightCalculatorState();
}

class _WeightCalculatorState extends State<WeightCalculator> {
  late int _grams = widget.initialGrams;
  int _amountCents = 0;
  bool _byAmount = false;

  Money get _perKg => Money(widget.product.base.retailCents);

  int get _resultGrams =>
      _byAmount ? weightForAmount(Money(_amountCents), _perKg).milli : _grams;

  int get _resultCents => priceForWeight(Quantity(_resultGrams), _perKg).cents;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.product.name, style: t.titleMedium),
          Text('${soles(_perKg.cents)} por kg', style: t.bodyMedium),
          const SizedBox(height: 12),
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
            onSelectionChanged: (s) => setState(() => _byAmount = s.single),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE6E0D0)),
            ),
            child: Column(
              children: [
                Text(
                  _byAmount
                      ? 'Monto que pide el cliente'
                      : 'Peso en la balanza',
                  style: t.labelLarge,
                ),
                Text(
                  _byAmount ? soles(_amountCents) : '$_grams g',
                  key: const Key('calc-input'),
                  style: t.headlineMedium!.merge(tabular),
                ),
                const Divider(),
                Text(
                  _byAmount
                      ? 'Pesar $_resultGrams g  ·  cobrar ${soles(_resultCents)}'
                      : 'Precio: ${soles(_resultCents)}',
                  key: const Key('calc-result'),
                  textAlign: TextAlign.center,
                  style: t.titleMedium!
                      .merge(tabular)
                      .copyWith(color: EsquinitaColors.forest),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (!_byAmount)
            Wrap(
              spacing: 8,
              children: [
                for (final g in const [250, 500, 1000])
                  ActionChip(
                    label: Text(g == 1000 ? '1 kg' : '$g g'),
                    onPressed: () => setState(() => _grams = g),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          NumberPad(
            value: _byAmount ? _amountCents : _grams,
            max: _byAmount ? 99999 : 50000,
            compact: true,
            onChanged: (v) =>
                setState(() => _byAmount ? _amountCents = v : _grams = v),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: _resultGrams > 0
                ? () => Navigator.pop(context, _resultGrams)
                : null,
            icon: const Icon(Icons.add_shopping_cart),
            label: Text('Agregar $_resultGrams g · ${soles(_resultCents)}'),
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
    final grams = await showWeightCalculator(context, product);
    if (grams == null) return;
    error = store.addToCart(product, product.base, grams);
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
