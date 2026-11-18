import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../demo_store.dart';

/// Read-only local stock with lots and expiry warnings ("stock local":
/// pending operations may not be counted yet, CLAUDE.md §7).
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
          'Puede no incluir operaciones de otros equipos aún sin sincronizar.',
        ),
        const SizedBox(height: 8),
        for (final p in store.catalog)
          Card(
            color: Colors.white,
            child: ListTile(
              title: Text(p.name),
              subtitle: p.tracksLots
                  ? Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final l in p.lots)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              '${l.code} · ${Quantity(l.qtyMilli)} · '
                              '${l.isExpired(store.now) ? 'VENCIDO' : 'vence ${l.expiresOn.day}/${l.expiresOn.month}/${l.expiresOn.year}'}',
                            ),
                            backgroundColor: l.isExpired(store.now)
                                ? EsquinitaColors.red.withValues(alpha: 0.12)
                                : l.expiresWithin(store.now, 30)
                                ? EsquinitaColors.amber.withValues(alpha: 0.15)
                                : null,
                          ),
                      ],
                    )
                  : Text(p.category),
              trailing: Text(
                p.byWeight
                    ? '${Quantity(p.totalStockMilli)} kg'
                    : '${Quantity(p.totalStockMilli)} und',
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
