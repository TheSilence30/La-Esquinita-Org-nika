import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../demo_store.dart';

String soles(int cents) => Money(cents).format();

/// `S/ 1,234.50` with tabular figures.
class MoneyText extends StatelessWidget {
  const MoneyText(this.cents, {super.key, this.style});

  final int cents;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text(
    soles(cents),
    style: (style ?? DefaultTextStyle.of(context).style).merge(tabular),
  );
}

/// The store logo, tinted (white on the green bar, green on cream).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 36, this.color});

  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/branding/logo-mark.png',
    height: height,
    color: color ?? EsquinitaColors.forest,
    colorBlendMode: BlendMode.srcIn,
    semanticLabel: 'La Esquinita Orgánika',
  );
}

class CashChip extends StatelessWidget {
  const CashChip({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final open = DemoScope.of(context).cashOpen;
    return StatusPill(
      icon: open ? Icons.point_of_sale : Icons.lock_outline,
      label: open ? 'Caja abierta' : 'Caja cerrada',
      color: open ? EsquinitaColors.leaf : EsquinitaColors.amber,
      onDark: onDark,
    );
  }
}

/// A rounded status label (sync, cash) for the top bars.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onDark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : EsquinitaColors.forest;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder for modules outside the prototype.
class ComingSoon extends StatelessWidget {
  const ComingSoon(this.title, {super.key, this.phase});

  final String title;
  final String? phase;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.construction_outlined,
            size: 48,
            color: EsquinitaColors.wood,
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Próximamente${phase == null ? '' : ' ($phase)'}. Fuera del prototipo.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
