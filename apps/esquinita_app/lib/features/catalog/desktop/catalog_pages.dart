import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../auth/application/auth_providers.dart';
import '../application/catalog_providers.dart';
import '../widgets/product_sheet.dart';
import '../widgets/register_view.dart';

/// PC "Registrar producto": the USB reader or the keyboard on the left,
/// the sheet or the form on the right.
class DesktopRegisterPage extends StatelessWidget {
  const DesktopRegisterPage({super.key, this.initialCode});

  final String? initialCode;

  @override
  Widget build(BuildContext context) => RegisterView(
    initialCode: initialCode,
    camera: false,
    layout: (entry, result) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 380, child: entry),
        const VerticalDivider(width: 1),
        Expanded(
          child:
              result ??
              const Center(
                child: Text('Escanea con el lector o escribe un código.'),
              ),
        ),
      ],
    ),
  );
}

/// PC "Productos": a dense table with the sheet of [selectedId] beside it.
/// F2 goes to the search (CLAUDE.md §10).
class DesktopProductsPage extends ConsumerStatefulWidget {
  const DesktopProductsPage({super.key, this.selectedId});

  final String? selectedId;

  @override
  ConsumerState<DesktopProductsPage> createState() =>
      _DesktopProductsPageState();
}

class _DesktopProductsPageState extends ConsumerState<DesktopProductsPage> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  String _query = '';

  /// F2 from anywhere on the page, also when nothing has the focus.
  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent || e.logicalKey != LogicalKeyboardKey.f2) {
      return false;
    }
    _focus.requestFocus();
    return true;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(productSearchProvider(_query)).value;
    final selected = widget.selectedId;
    final detail = selected == null
        ? null
        : ref.watch(productDetailProvider(selected)).value;
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        focusNode: _focus,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Buscar por nombre o código (F2)',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => context.go('/escanear'),
                      icon: const Icon(Icons.add),
                      label: const Text('Registrar producto'),
                    ),
                  ],
                ),
              ),
              Container(
                color: EsquinitaColors.forest.withValues(alpha: 0.06),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  child: const Row(
                    children: [
                      Expanded(flex: 5, child: Text('Producto')),
                      Expanded(flex: 2, child: Text('Código')),
                      Expanded(
                        flex: 2,
                        child: Text('Stock', textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: rows == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: rows.length,
                        itemExtent: 36,
                        itemBuilder: (_, i) {
                          final r = rows[i];
                          return InkWell(
                            onTap: () =>
                                context.go('/productos/${r.product.id}'),
                            child: Container(
                              color: r.product.id == selected
                                  ? EsquinitaColors.leaf.withValues(alpha: 0.15)
                                  : null,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      r.product.name +
                                          (r.product.active
                                              ? ''
                                              : ' (desactivado)'),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      r.product.internalCode,
                                      style: tabular,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${r.localStock ? 'local ' : ''}'
                                      '${qtyText(r.stockMilli, r.unitCode)}',
                                      textAlign: TextAlign.end,
                                      style: tabular,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 2,
          child: detail == null
              ? Center(
                  child: Text(
                    selected == null
                        ? 'Elige un producto.'
                        : 'Producto no encontrado.',
                    style: t.bodyLarge,
                  ),
                )
              : ProductSheet(
                  detail: detail,
                  canViewCost:
                      ref
                          .watch(currentSessionProvider)
                          ?.can('catalog.view_cost') ??
                      false,
                ),
        ),
      ],
    );
  }
}
