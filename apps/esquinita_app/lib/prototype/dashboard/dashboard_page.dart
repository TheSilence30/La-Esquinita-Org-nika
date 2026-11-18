import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../checkout.dart';
import '../demo_store.dart';
import '../widgets/common.dart';

/// Administrador home: today at a glance. Sales ≠ money in ≠ profit.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final t = Theme.of(context).textTheme;
    final today = store.todaySales;
    final total = today.fold(0, (s, x) => s + x.totalCents);
    final cash = store.methodTotal(PayMethod.cash, today);
    final credit = today
        .where((s) => s.credit)
        .fold(0, (s, x) => s + x.totalCents);
    final digital = total - cash - credit;
    final low = [
      for (final p in store.catalog)
        if (p.totalStockMilli <= p.minStockMilli) p,
    ];
    final expiring = [
      for (final p in store.catalog)
        for (final l in p.lots)
          if (l.qtyMilli > 0 &&
              (l.isExpired(store.now) || l.expiresWithin(store.now, 30)))
            (p, l),
    ];
    final cards = <Widget>[
      _Stat(
        'Ventas de hoy',
        soles(total),
        '${today.length} ventas',
        Icons.trending_up,
      ),
      _Stat(
        'Efectivo (cajón)',
        soles(cash),
        'Entra al arqueo',
        Icons.payments_outlined,
      ),
      _Stat(
        'Yape, Plin y otros',
        soles(digital),
        'No entra al cajón',
        Icons.phone_android,
      ),
      _Stat('A crédito', soles(credit), 'Por cobrar', Icons.person_outline),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 1100
            ? 4
            : box.maxWidth >= 600
            ? 2
            : 1;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Hoy', style: t.headlineSmall),
                const CashChip(),
                const SyncChip(),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: cols == 1 ? 3.4 : 2.4,
              children: cards,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _ListCard(
                  width: cols == 1
                      ? box.maxWidth - 32
                      : (box.maxWidth - 48) / 2,
                  title: 'Stock bajo o agotado',
                  icon: Icons.warning_amber_rounded,
                  color: EsquinitaColors.amber,
                  rows: [
                    for (final p in low)
                      (
                        p.name,
                        p.byWeight
                            ? '${Quantity(p.totalStockMilli)} kg'
                            : '${Quantity(p.totalStockMilli)} und',
                      ),
                  ],
                ),
                _ListCard(
                  width: cols == 1
                      ? box.maxWidth - 32
                      : (box.maxWidth - 48) / 2,
                  title: 'Lotes vencidos o por vencer (30 días)',
                  icon: Icons.event_busy_outlined,
                  color: EsquinitaColors.red,
                  rows: [
                    for (final (p, l) in expiring)
                      (
                        '${p.name} · ${l.code}',
                        l.isExpired(store.now)
                            ? 'VENCIDO (bloqueado)'
                            : 'vence ${l.expiresOn.day}/${l.expiresOn.month}',
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('/vender'),
                  icon: const Icon(Icons.shopping_basket_outlined),
                  label: const Text('Ir a vender'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/caja'),
                  icon: const Icon(Icons.point_of_sale),
                  label: const Text('Caja y cierre'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.title, this.value, this.caption, this.icon);

  final String title;
  final String value;
  final String caption;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: EsquinitaColors.leaf, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.labelLarge),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: t.headlineSmall!
                          .merge(tabular)
                          .copyWith(
                            fontWeight: FontWeight.w700,
                            color: EsquinitaColors.forest,
                          ),
                    ),
                  ),
                  Text(caption, style: t.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.width,
    required this.title,
    required this.icon,
    required this.color,
    required this.rows,
  });

  final double width;
  final String title;
  final IconData icon;
  final Color color;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (rows.isEmpty) const Text('Nada por ahora.'),
            for (final (a, b) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(a, overflow: TextOverflow.ellipsis)),
                    Text(b, style: tabular),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
