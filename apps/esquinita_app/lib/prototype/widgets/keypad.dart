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

/// Key for deleting the last typed character.
const padBackspace = '⌫';

/// Applies one key to the typed [text]. Digits are whole units first and
/// "." starts the fraction, up to [decimals] digits: soles (2: "25" →
/// S/ 25.00, "25.5" → S/ 25.50), kg (3: "1.5" → 1500 g) or a plain integer
/// (0: grams, with a "00" key). Returns null when the key is rejected
/// (second ".", too many decimals, or over [max]).
String? padInput(
  String text,
  String key, {
  required int decimals,
  required int max,
}) {
  final String next;
  if (key == padBackspace) {
    next = text.isEmpty ? '' : text.substring(0, text.length - 1);
  } else if (key == '.') {
    if (decimals == 0 || text.contains('.')) return null;
    next = text.isEmpty ? '0.' : '$text.';
  } else if (key == '00' &&
      (decimals > 0 || padValue(text, decimals: 0) == 0)) {
    return null;
  } else {
    final dot = text.indexOf('.');
    if (dot >= 0 && text.length - dot - 1 + key.length > decimals) return null;
    next = text == '0' ? key : text + key; // no leading zeros
  }
  return padValue(next, decimals: decimals) <= max ? next : null;
}

int _pow10(int n) => n == 0 ? 1 : 10 * _pow10(n - 1);

/// Typed text as an integer in the smallest unit (céntimos, grams).
int padValue(String text, {required int decimals}) {
  final dot = text.indexOf('.');
  final whole = dot < 0 ? text : text.substring(0, dot);
  final frac = dot < 0 ? '' : text.substring(dot + 1);
  return (int.tryParse(whole) ?? 0) * _pow10(decimals) +
      (int.tryParse(frac.padRight(decimals, '0')) ?? 0);
}

/// Text that types [value] (used when it is set from outside the pad,
/// e.g. a quick-amount chip): 2500 → "25", 2550 → "25.50".
String padText(int value, {required int decimals}) {
  if (value == 0) return '';
  final unit = _pow10(decimals);
  final frac = value % unit;
  return frac == 0
      ? '${value ~/ unit}'
      : '${value ~/ unit}.${frac.toString().padLeft(decimals, '0')}';
}

/// On-screen keypad typed like a calculator, whole units first. [value] is
/// in the smallest unit: céntimos with [decimals] 2 (default), grams typed
/// as kg with 3, or a plain integer with 0. Physical keyboards work too (PC).
class NumberPad extends StatefulWidget {
  const NumberPad({
    super.key,
    required this.value,
    required this.onChanged,
    this.decimals = 2,
    this.max = 99999999,
    this.compact = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int decimals;
  final int max;
  final bool compact;

  @override
  State<NumberPad> createState() => _NumberPadState();
}

class _NumberPadState extends State<NumberPad> {
  late String _text = padText(widget.value, decimals: widget.decimals);

  @override
  void didUpdateWidget(NumberPad old) {
    super.didUpdateWidget(old);
    // Value set from outside, or another field/unit: restart from it.
    if (widget.decimals != old.decimals ||
        widget.value != padValue(_text, decimals: widget.decimals)) {
      _text = padText(widget.value, decimals: widget.decimals);
    }
  }

  void _press(String key) {
    final next = padInput(
      _text,
      key,
      decimals: widget.decimals,
      max: widget.max,
    );
    if (next == null) return;
    _text = next;
    widget.onChanged(padValue(next, decimals: widget.decimals));
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.compact ? 48.0 : 56.0;
    Widget key(String label, {IconData? icon}) => Expanded(
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
            onPressed: () => _press(label),
            child: icon != null
                ? Icon(icon, semanticLabel: 'Borrar')
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
          _press(c);
          return KeyEventResult.handled;
        }
        if (widget.decimals > 0 && (c == '.' || c == ',')) {
          _press('.');
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.backspace) {
          _press(padBackspace);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(children: [for (final d in row) key(d)]),
          Row(
            children: [
              key(widget.decimals > 0 ? '.' : '00'),
              key('0'),
              key(padBackspace, icon: Icons.backspace_outlined),
            ],
          ),
        ],
      ),
    );
  }
}
