import 'dart:async';

import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';

import '../../app/form_factor.dart';
import '../../app/theme.dart';
import '../../devices/feedback/scan_feedback.dart';
import '../../devices/scanner/camera_scan_view.dart';
import '../demo_data.dart';
import '../demo_store.dart';
import '../inventory/inventory_page.dart';
import '../widgets/common.dart';
import '../widgets/notice.dart';

/// "Registrar producto" scan context: read a code, show the product if it
/// exists, otherwise fill a short form. No QR (store codes only).
class RegisterProductPage extends StatefulWidget {
  const RegisterProductPage({super.key, this.initialCode});

  /// Code to start with (an unknown code from the sales scanner).
  final String? initialCode;

  @override
  State<RegisterProductPage> createState() => _RegisterProductPageState();
}

class _RegisterProductPageState extends State<RegisterProductPage> {
  final _filter = ScanFilter();
  final _manual = TextEditingController();
  late String? _code = widget.initialCode;
  late bool _scanning = widget.initialCode == null;

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  /// Keeps the half-filled form when rotating: it moves between the single
  /// column and the side panel, and without a GlobalKey it was rebuilt empty.
  GlobalKey _formKey = GlobalKey();

  void _useCode(String code) => setState(() {
    _code = code.trim();
    _scanning = false;
    _formKey = GlobalKey();
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
                unawaited(ScanFeedback.success());
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
                key: _formKey,
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
              overlay: const ScanFrame(),
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
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.inventory_2_outlined),
          title: Text(
            'Stock local: ${Quantity(product.totalStockMilli)}'
            '${product.tracksLots ? ' en ${product.lots.length} lotes' : ''}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showProductStock(context, product),
        ),
        const SizedBox(height: 12),
        // Same product again with another lot/expiry (e.g. a new delivery).
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () => showNewLot(context, product),
          icon: const Icon(Icons.add_box_outlined),
          label: const Text('Agregar lote nuevo'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: onAgain,
          child: const Text('Escanear otro'),
        ),
      ],
    );
  }
}

/// Long press in Inventario (Administrador): edit the product's data, with
/// a way to its stock and lots.
Future<void> showEditProduct(BuildContext context, DemoProduct p) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (page) => Scaffold(
          appBar: AppBar(title: const Text('Editar producto')),
          body: _NewProductForm(
            code: p.base.barcode ?? '',
            product: p,
            onSaved: () => Navigator.pop(page),
            onCancel: () => Navigator.pop(page),
          ),
        ),
      ),
    );

class _NewProductForm extends StatefulWidget {
  const _NewProductForm({
    super.key,
    required this.code,
    required this.onSaved,
    required this.onCancel,
    this.product,
  });

  final String code;

  /// Set: edit this product instead of registering a new one.
  final DemoProduct? product;
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
  late final _barcode = TextEditingController(text: widget.code);
  String _category = categories.first;
  bool _byWeight = false;
  bool _tracksLots = false;
  bool _withBox = false;
  String? _error;

  DemoProduct? get _editing => widget.product;

  @override
  void initState() {
    super.initState();
    final p = _editing;
    if (p == null) return;
    String soles(int cents) => (cents / 100).toStringAsFixed(2);
    final box = p.presentations.length > 1 ? p.presentations[1] : null;
    _name.text = p.name;
    _price.text = soles(p.base.retailCents);
    _minStock.text = '${p.minStockMilli ~/ 1000}';
    _category = p.category;
    _byWeight = p.byWeight;
    _withBox = box != null;
    if (box != null) {
      _boxFactor.text = '${box.factorMilli ~/ 1000}';
      _boxPrice.text = soles(box.retailCents);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _price,
      _boxFactor,
      _boxPrice,
      _minStock,
      _barcode,
    ]) {
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
    if (_editing case final p?) {
      final failed = store.updateProduct(
        p,
        name: _name.text,
        category: _category,
        retailCents: price!,
        barcode: _barcode.text,
        minStockMilli: (int.tryParse(_minStock.text) ?? 0) * 1000,
        boxUnits: _withBox ? factor : null,
        boxCents: _withBox ? boxPrice : null,
      );
      setState(() => _error = failed);
      if (failed != null) return;
      showNotice(context, '${p.name}: datos guardados (solo en memoria).');
      widget.onSaved();
      return;
    }
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
    showNotice(context, '${_name.text.trim()} registrado (solo en memoria).');
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final generated = widget.code.startsWith('29');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_editing case final p?) ...[
          // Stock and lots live in the stock sheet (same as a tap).
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            icon: const Icon(Icons.inventory_2_outlined),
            label: Text(
              'Stock y lotes · ${Quantity(p.totalStockMilli)} '
              '${p.byWeight ? 'kg' : 'und'}',
            ),
            onPressed: () => showProductStock(context, p),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _barcode,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Código de barras',
              border: OutlineInputBorder(),
            ),
          ),
        ] else ...[
          Text('Nuevo producto', style: t.titleLarge),
          Text(
            generated
                ? 'Código interno generado: ${widget.code}'
                : 'Código: ${widget.code}',
            style: t.bodyMedium!.merge(tabular),
          ),
        ],
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
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Categoría',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final c in {...categories, _category})
              DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: (v) => setState(() => _category = v!),
        ),
        // Not editable: the existing stock and sales are in this unit.
        if (_editing == null)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Se vende por peso (kg)'),
            value: _byWeight,
            onChanged: (v) => setState(() => _byWeight = v),
          )
        else
          const SizedBox(height: 12),
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
        if (_editing == null)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Controla lotes y vencimientos'),
            subtitle: const Text('Se piden al recibir la mercadería'),
            value: _tracksLots,
            onChanged: (v) => setState(() => _tracksLots = v),
          )
        else
          const SizedBox(height: 12),
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
                child: Text(
                  _editing == null ? 'Guardar producto' : 'Guardar cambios',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
