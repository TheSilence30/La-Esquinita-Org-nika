import 'dart:async';

import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../devices/feedback/scan_feedback.dart';
import '../../../devices/scanner/camera_scan_view.dart';
import '../../auth/application/auth_providers.dart';
import '../application/catalog_providers.dart';
import '../widgets/product_sheet.dart';
import '../widgets/register_view.dart';

/// Tablet and phone "Escanear": camera on top or at the side; in portrait
/// the form takes the screen once a code is read.
class TabletRegisterPage extends StatelessWidget {
  const TabletRegisterPage({super.key, this.initialCode});

  final String? initialCode;

  @override
  Widget build(BuildContext context) => RegisterView(
    initialCode: initialCode,
    camera: isCameraScanSupported,
    layout: (entry, result) => LayoutBuilder(
      builder: (context, box) => box.maxWidth >= 840
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 420, child: entry),
                const VerticalDivider(width: 1),
                Expanded(
                  child:
                      result ??
                      const Center(
                        child: Text(
                          'Escanea o escribe un código para empezar.',
                        ),
                      ),
                ),
              ],
            )
          : result ?? entry,
    ),
  );
}

/// Más → Productos: search by name, code or the camera; tap for the sheet.
class TabletProductsPage extends ConsumerStatefulWidget {
  const TabletProductsPage({super.key});

  @override
  ConsumerState<TabletProductsPage> createState() => _TabletProductsPageState();
}

class _TabletProductsPageState extends ConsumerState<TabletProductsPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final code = await showModalBottomSheet<String>(
      context: context,
      builder: (sheet) {
        final filter = ScanFilter();
        return AspectRatio(
          aspectRatio: 4 / 3,
          child: CameraScanView(
            overlay: const ScanFrame(),
            onCodes: (codes, elapsed, _) {
              for (final c in codes) {
                if (filter.offer(c, elapsed).isAccepted) {
                  unawaited(ScanFeedback.success());
                  Navigator.pop(sheet, c);
                  return;
                }
              }
            },
          ),
        );
      },
    );
    if (code != null) setState(() => _query = _search.text = code);
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(productSearchProvider(_query)).value;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre o código',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              if (isCameraScanSupported)
                IconButton(
                  tooltip: 'Buscar escaneando',
                  iconSize: 32,
                  onPressed: _scan,
                  icon: const Icon(Icons.qr_code_scanner),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => context.go('/escanear'),
            icon: const Icon(Icons.add),
            label: const Text('Registrar producto'),
          ),
        ),
        Expanded(
          child: rows == null
              ? const Center(child: CircularProgressIndicator())
              : rows.isEmpty
              ? const Center(child: Text('Ningún producto con esa búsqueda.'))
              : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = rows[i];
                    return ListTile(
                      minTileHeight: 56,
                      title: Text(r.product.name),
                      subtitle: Text(
                        r.product.internalCode +
                            (r.product.active ? '' : ' · desactivado'),
                      ),
                      trailing: Text(
                        '${r.localStock ? 'local ' : ''}'
                        '${qtyText(r.stockMilli, r.unitCode)}',
                        style: tabular,
                      ),
                      onTap: () => context.go('/productos/${r.product.id}'),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// The product sheet, full screen inside the shell.
class TabletProductPage extends ConsumerWidget {
  const TabletProductPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(productDetailProvider(productId));
    final session = ref.watch(currentSessionProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: () => context.go('/productos'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Productos'),
        ),
        Expanded(
          child: switch (detail) {
            AsyncData(value: final d?) => ProductSheet(
              detail: d,
              canViewCost: session?.can('catalog.view_cost') ?? false,
            ),
            AsyncData() => const Center(child: Text('Producto no encontrado.')),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }
}
