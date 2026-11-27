import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/catalog_store.dart';
import '../../../prototype/widgets/notice.dart';
import '../../auth/application/auth_providers.dart';
import '../application/catalog_providers.dart';
import 'code_entry.dart';
import 'product_form.dart';
import 'product_sheet.dart';

/// "Registrar producto": read a code; a known one opens its sheet, an
/// unknown one (or "sin código", with a new `29…`) the form. Each shell
/// places [entry] and [result] with [layout].
class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({
    super.key,
    required this.camera,
    required this.layout,
    this.initialCode,
  });

  final bool camera;
  final String? initialCode;

  /// [result] is null until a code is read.
  final Widget Function(Widget entry, Widget? result) layout;

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  String? _code;
  bool _generated = false;

  /// The product that already has [_code]; null while looking or unknown.
  String? _productId;
  bool _looking = false;

  /// Keeps the half-filled form when the tablet rotates (it moves between
  /// one column and the side panel).
  GlobalKey _formKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.initialCode case final c?) _use(c);
  }

  Future<void> _use(String code, {bool generated = false}) async {
    setState(() {
      _code = code;
      _generated = generated;
      _productId = null;
      _looking = true;
      _formKey = GlobalKey();
    });
    final hit = await ref.read(catalogStoreProvider).findBarcode(code);
    if (mounted && _code == code) {
      setState(() {
        _productId = hit?.productId;
        _looking = false;
      });
    }
  }

  Future<void> _noCode() async {
    try {
      final code = await ref.read(catalogStoreProvider).nextGeneratedBarcode();
      await _use(code, generated: true);
    } on CatalogException catch (e) {
      if (mounted) showNotice(context, e.message, level: NoticeLevel.warn);
    }
  }

  void _reset() => setState(() {
    _code = null;
    _productId = null;
  });

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final entry = CodeEntry(
      camera: widget.camera && _code == null,
      onCode: _use,
      onNoCode: _noCode,
    );
    final code = _code;
    final Widget? result;
    if (code == null) {
      result = null;
    } else if (_looking) {
      result = const Center(child: CircularProgressIndicator());
    } else if (_productId case final id?) {
      result = _Known(
        productId: id,
        canViewCost: session?.can('catalog.view_cost') ?? false,
        onAgain: _reset,
      );
    } else if (!(session?.can('catalog.create') ?? false)) {
      result = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'El código $code no está registrado. Tu usuario no puede dar de '
            'alta productos.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      result = ProductForm(
        key: _formKey,
        code: code,
        generated: _generated,
        onCancel: _reset,
        onSaved: (id) {
          showNotice(context, 'Producto guardado en este equipo.');
          setState(() => _productId = id);
        },
      );
    }
    return widget.layout(entry, result);
  }
}

class _Known extends ConsumerWidget {
  const _Known({
    required this.productId,
    required this.canViewCost,
    required this.onAgain,
  });

  final String productId;
  final bool canViewCost;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(productDetailProvider(productId)).value;
    if (detail == null) return const Center(child: CircularProgressIndicator());
    return ProductSheet(
      detail: detail,
      canViewCost: canViewCost,
      footer: [
        // shortcut: "Agregar lote nuevo" of the prototype comes back with
        // AdjustStock (Fase 2, task 6) and with receptions (Fase 4).
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
