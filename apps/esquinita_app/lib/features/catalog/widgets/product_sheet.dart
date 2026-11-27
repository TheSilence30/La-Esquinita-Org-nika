import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../data/local/catalog_store.dart';

/// `24 und`, `1.500 kg`.
String qtyText(int milli, String unitCode) => '${Quantity(milli)} $unitCode';

/// The product sheet (both shells): data, presentations with their codes
/// and prices, and stock by lot. Costs only with `catalog.view_cost`.
class ProductSheet extends StatelessWidget {
  const ProductSheet({
    super.key,
    required this.detail,
    required this.canViewCost,
    this.footer = const [],
  });

  final ProductDetail detail;
  final bool canViewCost;

  /// Buttons fixed under the sheet ("Escanear otro").
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = detail.product;
    final unit = detail.unit.code;
    final sheet = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(p.name, style: t.titleLarge),
        Text(
          [
            p.internalCode,
            ?detail.categoryName,
            ?detail.brandName,
            if (!p.active) 'Desactivado',
          ].join(' · '),
          style: t.bodyMedium!.merge(tabular),
        ),
        if (detail.rejectedMessage case final why?)
          _Banner(
            key: const Key('product-rejected'),
            color: EsquinitaColors.red,
            icon: Icons.error_outline,
            text:
                'El servidor rechazó este producto: $why. '
                'Solo está en este equipo.',
          ),
        const SizedBox(height: 12),
        Text(
          '${detail.localStock ? 'Stock local' : 'Stock'}: '
          '${qtyText(detail.stockMilli, unit)}',
          style: t.titleMedium!.merge(tabular),
        ),
        if (detail.localStock)
          Text(
            'Incluye operaciones de este equipo que el servidor aún no '
            'confirma en su stock.',
            style: t.bodySmall,
          ),
        if (p.tracksLots || detail.stock.any((s) => s.lot != null))
          for (final s in detail.stock)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.layers_outlined),
              title: Text(s.lot?.lotCode ?? 'Sin lote'),
              subtitle: Text(switch (s.lot) {
                null => 'Vendido antes de registrar un lote',
                final l =>
                  l.expiresOn == null
                      ? 'No vence'
                      : 'Vence ${_date(l.expiresOn!)}',
              }),
              trailing: Text(qtyText(s.qtyMilli, unit), style: tabular),
            ),
        Text(
          'Stock mínimo: ${qtyText(p.minStockMilli, unit)}',
          style: t.bodyMedium!.merge(tabular),
        ),
        const Divider(height: 24),
        Text('Presentaciones', style: t.titleMedium),
        for (final (:presentation, :barcodes) in detail.presentations)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(presentation.name),
            subtitle: Text(
              [
                if (presentation.isBase)
                  'Unidad base ($unit)'
                else
                  'Contiene ${qtyText(presentation.factorMilli, unit)}',
                if (presentation.wholesalePriceCents case final w?)
                  'Mayorista ${Money(w)}'
                      '${presentation.wholesaleMinMilli == null ? '' : ' desde ${Quantity(presentation.wholesaleMinMilli!)}'}',
                for (final b in barcodes) b.code,
              ].join('\n'),
              style: tabular,
            ),
            trailing: Text(
              Money(presentation.retailPriceCents).format(),
              style: t.titleMedium!.merge(tabular),
            ),
          ),
        if (canViewCost && detail.cost != null) ...[
          const Divider(height: 24),
          Text(
            'Costo promedio: ${Money(detail.cost!.avgCostCents)} por $unit · '
            'último: ${Money(detail.cost!.lastCostCents)}',
            key: const Key('product-cost'),
            style: t.bodyMedium!.merge(tabular),
          ),
        ],
      ],
    );
    if (footer.isEmpty) return sheet;
    return Column(
      children: [
        Expanded(child: sheet),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(children: footer),
        ),
      ],
    );
  }
}

/// `2027-03-15` → `15/03/2027`.
String _date(String iso) {
  final [y, m, d] = iso.split('-');
  return '$d/$m/$y';
}

class _Banner extends StatelessWidget {
  const _Banner({
    super.key,
    required this.color,
    required this.icon,
    required this.text,
  });

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color),
    ),
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
