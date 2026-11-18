import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';

import '../../app/form_factor.dart';
import '../../app/theme.dart';
import '../../devices/scanner/camera_scan_view.dart';
import '../demo_data.dart';
import '../demo_store.dart';
import '../widgets/common.dart';

/// "Registrar producto" scan context: read a code, show the product if it
/// exists, otherwise fill a short form. No QR (store codes only).
class RegisterProductPage extends StatefulWidget {
  const RegisterProductPage({super.key});

  @override
  State<RegisterProductPage> createState() => _RegisterProductPageState();
}

class _RegisterProductPageState extends State<RegisterProductPage> {
  final _filter = ScanFilter();
  final _manual = TextEditingController();
  String? _code;
  bool _scanning = true;

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  void _useCode(String code) => setState(() {
    _code = code.trim();
    _scanning = false;
  });

  void _reset() => setState(() {
    _code = null;
    _scanning = true;
    _manual.clear();
  });

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final camera =
        isCameraScanSupported && FormFactor.of(context) != FormFactor.desktop;
    final code = _code;
    final hit = code == null ? null : store.findByBarcode(code);
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 840;
        final entry = _CodeEntry(
          camera: camera && _scanning,
          manual: _manual,
          onCameraCodes: (codes, elapsed) {
            for (final c in codes) {
              if (_filter.offer(c, elapsed).isAccepted) {
                _useCode(c);
                break;
              }
            }
          },
          onSubmit: _useCode,
          onNoCode: () => _useCode(store.nextInternalBarcode()),
        );
        final result = code == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Escanea o escribe un código para empezar.'),
                ),
              )
            : hit != null
            ? _Existing(
                product: hit.product,
                presentation: hit.presentation,
                onAgain: _reset,
              )
            : _NewProductForm(
                key: ValueKey(code),
                code: code,
                onSaved: _reset,
                onCancel: _reset,
              );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 420, child: entry),
              const VerticalDivider(width: 1),
              Expanded(child: result),
            ],
          );
        }
        // Phone and tablet portrait: one column; the camera gives way to the
        // form once a code is read.
        return code == null ? entry : result;
      },
    );
  }
}

class _CodeEntry extends StatelessWidget {
  const _CodeEntry({
    required this.camera,
    required this.manual,
    required this.onCameraCodes,
    required this.onSubmit,
    required this.onNoCode,
  });

  final bool camera;
  final TextEditingController manual;
  final void Function(List<String>, Duration) onCameraCodes;
  final ValueChanged<String> onSubmit;
  final VoidCallback onNoCode;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('Registrar producto', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      if (camera)
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: CameraScanView(
              onCodes: (codes, elapsed, _) => onCameraCodes(codes, elapsed),
            ),
          ),
        )
      else
        Container(
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E0D0)),
          ),
          child: const Text(
            'Usa el lector de códigos o escribe el código.',
            textAlign: TextAlign.center,
          ),
        ),
      const SizedBox(height: 12),
      TextField(
        controller: manual,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Código de barras',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.keyboard_return),
        ),
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) onSubmit(v);
        },
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: onNoCode,
        icon: const Icon(Icons.qr_code_2),
        label: const Text('Producto sin código: generar código interno'),
      ),
    ],
  );
}

class _Existing extends StatelessWidget {
  const _Existing({
    required this.product,
    required this.presentation,
    required this.onAgain,
  });

  final DemoProduct product;
  final DemoPresentation presentation;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Icon(
          Icons.inventory_2_outlined,
          size: 40,
          color: EsquinitaColors.forest,
        ),
        Text('Ya registrado', style: t.titleLarge),
        Text(product.name, style: t.titleMedium),
        Text('${product.category} · código ${presentation.barcode}'),
        const Divider(),
        for (final p in product.presentations)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(p.name),
            subtitle: Text(
              p.factorMilli == 1000
                  ? 'Unidad base'
                  : '${Quantity(p.factorMilli)} unidades',
            ),
            trailing: MoneyText(p.retailCents),
          ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: onAgain,
          child: const Text('Escanear otro'),
        ),
      ],
    );
  }
}

class _NewProductForm extends StatefulWidget {
  const _NewProductForm({
    super.key,
    required this.code,
    required this.onSaved,
    required this.onCancel,
  });

  final String code;
  final VoidCallback onSaved;
  final VoidCallback onCancel;

  @override
  State<_NewProductForm> createState() => _NewProductFormState();
}

class _NewProductFormState extends State<_NewProductForm> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _boxFactor = TextEditingController();
  final _boxPrice = TextEditingController();
  final _minStock = TextEditingController(text: '5');
  String _category = categories.first;
  bool _byWeight = false;
  bool _tracksLots = false;
  bool _withBox = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _price, _boxFactor, _boxPrice, _minStock]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _cents(String s) {
    final v = double.tryParse(s.replaceAll(',', '.'));
    return v == null ? null : (v * 100).round();
  }

  void _save() {
    final price = _cents(_price.text);
    final factor = int.tryParse(_boxFactor.text);
    final boxPrice = _cents(_boxPrice.text);
    final error = _name.text.trim().isEmpty
        ? 'Escribe el nombre.'
        : price == null || price <= 0
        ? 'Escribe un precio válido.'
        : _withBox && (factor == null || factor < 2)
        ? 'La caja/paquete necesita cuántas unidades contiene (2 o más).'
        : _withBox && (boxPrice == null || boxPrice <= 0)
        ? 'Escribe el precio de la caja/paquete.'
        : null;
    setState(() => _error = error);
    if (error != null) return;
    final store = DemoScope.read(context);
    store.registerProduct(
      DemoProduct(
        id: widget.code,
        name: _name.text.trim(),
        category: _category,
        avgCostCents: 0,
        byWeight: _byWeight,
        minStockMilli: (int.tryParse(_minStock.text) ?? 0) * 1000,
        presentations: [
          DemoPresentation(
            name: _byWeight ? 'kg' : 'Unidad',
            factorMilli: 1000,
            retailCents: price!,
            barcode: widget.code,
          ),
          if (_withBox && !_byWeight)
            DemoPresentation(
              name: 'Caja x$factor',
              factorMilli: factor! * 1000,
              retailCents: boxPrice!,
            ),
        ],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_name.text.trim()} registrado (solo en memoria).'),
      ),
    );
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final generated = widget.code.startsWith('29');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Nuevo producto', style: t.titleLarge),
        Text(
          generated
              ? 'Código interno generado: ${widget.code}'
              : 'Código: ${widget.code}',
          style: t.bodyMedium!.merge(tabular),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: const InputDecoration(
            labelText: 'Categoría',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final c in categories)
              DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: (v) => setState(() => _category = v!),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Se vende por peso (kg)'),
          value: _byWeight,
          onChanged: (v) => setState(() => _byWeight = v),
        ),
        TextField(
          controller: _price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: _byWeight
                ? 'Precio por kg (S/)'
                : 'Precio por unidad (S/)',
            border: const OutlineInputBorder(),
          ),
        ),
        if (!_byWeight) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('También se vende en caja o paquete'),
            value: _withBox,
            onChanged: (v) => setState(() => _withBox = v),
          ),
          if (_withBox)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _boxFactor,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Unidades por caja',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _boxPrice,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Precio caja (S/)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Controla lotes y vencimientos'),
          subtitle: const Text('Se piden al recibir la mercadería'),
          value: _tracksLots,
          onChanged: (v) => setState(() => _tracksLots = v),
        ),
        TextField(
          controller: _minStock,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Stock mínimo',
            border: OutlineInputBorder(),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
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
                onPressed: _save,
                child: const Text('Guardar producto'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
