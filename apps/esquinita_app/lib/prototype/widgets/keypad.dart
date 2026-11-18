import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

/// Shows [child] as a full-height bottom sheet on narrow screens (one-hand
/// use on phones) and as a centered dialog on tablets and the PC.
Future<T?> showAdaptiveSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext) builder,
  double maxWidth = 460,
}) {
  final narrow = MediaQuery.sizeOf(context).width < 600;
  if (narrow) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true, // above the bottom bar
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: builder,
    );
  }
  return showDialog<T>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: builder(context),
        ),
      ),
    ),
  );
}

/// Integer entry typed digit by digit: amounts in cents ("5", "0", "0" →
/// S/ 5.00) or grams. Physical keyboards work too (PC).
class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.value,
    required this.onChanged,
    this.max = 99999999,
    this.compact = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int max;
  final bool compact;

  void _digit(int d) {
    final next = value * 10 + d;
    if (next <= max) onChanged(next);
  }

  void _double0() {
    final next = value * 100;
    if (next <= max) onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final h = compact ? 48.0 : 56.0;
    Widget key(String label, VoidCallback onTap, {IconData? icon}) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: SizedBox(
          height: h,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onTap,
            child: icon != null
                ? Icon(icon, semanticLabel: label)
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: EsquinitaColors.forest,
                    ).merge(tabular),
                  ),
          ),
        ),
      ),
    );
    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final c = event.character;
        if (c != null && RegExp(r'^\d$').hasMatch(c)) {
          _digit(int.parse(c));
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.backspace) {
          onChanged(value ~/ 10);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in const [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
          ])
            Row(children: [for (final d in row) key('$d', () => _digit(d))]),
          Row(
            children: [
              key('00', _double0),
              key('0', () => _digit(0)),
              key(
                'Borrar',
                () => onChanged(value ~/ 10),
                icon: Icons.backspace_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
