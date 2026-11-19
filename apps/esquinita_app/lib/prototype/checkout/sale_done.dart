import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../demo_store.dart';
import '../widgets/common.dart';
import '../widgets/notice.dart';

class SaleDonePage extends StatelessWidget {
  const SaleDonePage({super.key, required this.sale});

  final DemoSale sale;

  @override
  Widget build(BuildContext context) => PopScope(
    // Reached with go(): without this, "Atrás" would close the app.
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) context.go('/vender');
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text('Venta ${sale.code}'),
        leading: BackButton(onPressed: () => context.go('/vender')),
      ),
      body: _SaleDone(sale: sale, onNew: () => context.go('/vender')),
    ),
  );
}

Future<void> showSaleDoneDialog(BuildContext context, DemoSale sale) =>
    showDialog<void>(
      context: context,
      builder: (dialog) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 760),
          child: _SaleDone(sale: sale, onNew: () => Navigator.pop(dialog)),
        ),
      ),
    );

class _SaleDone extends StatelessWidget {
  const _SaleDone({required this.sale, required this.onNew});

  final DemoSale sale;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Icon(
                Icons.check_circle,
                size: 56,
                color: EsquinitaColors.leaf,
              ),
              Text(
                'Venta registrada',
                textAlign: TextAlign.center,
                style: t.headlineSmall,
              ),
              if (sale.changeCents > 0)
                Text(
                  'Vuelto: ${soles(sale.changeCents)}',
                  textAlign: TextAlign.center,
                  style: t.titleLarge!
                      .merge(tabular)
                      .copyWith(color: EsquinitaColors.forest),
                ),
              const SizedBox(height: 16),
              Center(child: _ReceiptPreview(sale)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
                onPressed: () => showNotice(
                  context,
                  'Impresión: fuera del prototipo (spikes 3 y 4 ya probados).',
                  level: NoticeLevel.warn,
                ),
                icon: const Icon(Icons.print_outlined),
                label: const Text('Imprimir'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
                  onPressed: onNew,
                  child: const Text('Nueva venta'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 58 mm ticket look (32 columns): internal document, never a boleta.
class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview(this.sale);

  final DemoSale sale;

  @override
  Widget build(BuildContext context) {
    const mono = TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.35);
    String two(String a, String b) {
      const width = 32;
      final space = width - a.length - b.length;
      return space >= 1
          ? '$a${' ' * space}$b'
          : '$a\n${' ' * (width - b.length)}$b';
    }

    final lines = <String>[
      '      La Esquinita Orgánika',
      ' Av. Famesa Mz. C Lt. 3, P. Piedra',
      '--------------------------------',
      'Constancia de venta – no es',
      'comprobante de pago',
      '--------------------------------',
      two('Ticket ${sale.code}', _time(sale.at)),
      if (sale.customer != null) 'Cliente: ${sale.customer!.name}',
      '--------------------------------',
      for (final (name, qty, cents) in sale.lines) ...[
        name.length > 32 ? name.substring(0, 32) : name,
        two('  $qty', soles(cents)),
      ],
      '--------------------------------',
      two('TOTAL', soles(sale.totalCents)),
      if (sale.credit)
        'Venta a CRÉDITO'
      else
        for (final e in sale.payments.entries) two(e.key.label, soles(e.value)),
      if (sale.changeCents > 0) two('Vuelto', soles(sale.changeCents)),
      '--------------------------------',
      '   ¡Gracias por su compra!',
    ];
    return Container(
      width: 320,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE6E0D0)),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Color(0x14000000))],
      ),
      child: Column(
        children: [
          const BrandLogo(height: 56, color: Colors.black),
          const SizedBox(height: 8),
          Text(lines.join('\n'), style: mono),
        ],
      ),
    );
  }
}

String _time(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
