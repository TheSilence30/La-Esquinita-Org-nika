import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/form_factor.dart';
import '../../app/theme.dart';
import '../../devices/scanner/camera_scan_view.dart';
import '../checkout/checkout_view.dart';
import '../demo_data.dart';
import '../demo_store.dart';
import '../widgets/common.dart';
import 'pos_dialogs.dart';

/// Point of sale. Independent layouts per form factor (CLAUDE.md §2):
/// phone (one hand, list + bottom bar), tablet portrait (grid + bottom
/// bar), tablet landscape (two panels), PC (dense table + shortcuts).
class PosPage extends StatelessWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final camera = isCameraScanSupported;
    return switch (FormFactor.of(context)) {
      FormFactor.desktop => const _DesktopPos(),
      FormFactor.phone => _CompactPos(phone: true, camera: camera),
      FormFactor.tablet =>
        MediaQuery.sizeOf(context).width >= 840
            ? _TwoPanelPos(camera: camera)
            : _CompactPos(phone: false, camera: camera),
    };
  }
}

void _goToCheckout(BuildContext context) {
  if (DemoScope.read(context).cart.isEmpty) return;
  if (FormFactor.of(context) == FormFactor.desktop) {
    showCheckoutDialog(context);
  } else {
    context.push('/cobro');
  }
}

// ---------------------------------------------------------------------------
// Catalog (touch)

class _Catalog extends StatefulWidget {
  const _Catalog({required this.asList, this.columns = 3});

  final bool asList;
  final int columns;

  @override
  State<_Catalog> createState() => _CatalogState();
}

class _CatalogState extends State<_Catalog> {
  String _query = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final q = _query.toLowerCase();
    final products = [
      for (final p in store.catalog)
        if ((_category == null || p.category == _category) &&
            (q.isEmpty ||
                p.name.toLowerCase().contains(q) ||
                p.presentations.any((pr) => pr.barcode == _query)))
          p,
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar producto o código',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final c in [null, ...categories])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(c ?? 'Todos'),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: widget.asList
              ? ListView.separated(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _ProductRow(products[i]),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: widget.columns,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    mainAxisExtent: 118,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, i) => _ProductCard(products[i]),
                ),
        ),
      ],
    );
  }
}

String _priceLabel(DemoProduct p) => p.byWeight
    ? '${soles(p.base.retailCents)} / kg'
    : soles(p.base.retailCents);

Widget _stockBadge(BuildContext context, DemoProduct p) {
  final store = DemoScope.of(context);
  final sellable = p.sellableStockMilli(store.now);
  if (sellable <= 0) {
    return const _Badge('Agotado', EsquinitaColors.red);
  }
  if (p.totalStockMilli <= p.minStockMilli) {
    return const _Badge('Stock bajo', EsquinitaColors.amber);
  }
  return const SizedBox.shrink();
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard(this.product);

  final DemoProduct product;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: Colors.white,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => addProductFlow(context, product),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.name,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _priceLabel(product),
                    style: const TextStyle(
                      color: EsquinitaColors.forest,
                      fontWeight: FontWeight.w700,
                    ).merge(tabular),
                  ),
                ),
                if (product.byWeight)
                  const Icon(
                    Icons.scale,
                    size: 18,
                    color: EsquinitaColors.wood,
                  ),
                if (product.tracksLots)
                  const Icon(
                    Icons.event_outlined,
                    size: 18,
                    color: EsquinitaColors.wood,
                  ),
                if (product.presentations.length > 1)
                  const Icon(
                    Icons.layers_outlined,
                    size: 18,
                    color: EsquinitaColors.wood,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            _stockBadge(context, product),
          ],
        ),
      ),
    ),
  );
}

class _ProductRow extends StatelessWidget {
  const _ProductRow(this.product);

  final DemoProduct product;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 64,
    title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
    subtitle: Row(
      children: [
        Text(_priceLabel(product), style: tabular),
        const SizedBox(width: 8),
        _stockBadge(context, product),
      ],
    ),
    trailing: Icon(
      product.byWeight
          ? Icons.scale
          : product.presentations.length > 1
          ? Icons.layers_outlined
          : Icons.add_circle,
      color: EsquinitaColors.leaf,
      size: 30,
    ),
    onTap: () => addProductFlow(context, product),
  );
}

// ---------------------------------------------------------------------------
// Cart (touch)

class _CartList extends StatelessWidget {
  const _CartList();

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    if (store.cart.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Escanea o toca un producto para empezar la venta.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: store.cart.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) => _CartLineTile(store.cart[i]),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile(this.line);

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.read(context);
    final t = Theme.of(context).textTheme;
    final p = line.product;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: t.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  p.byWeight
                      ? '${line.qtyMilli} g × ${soles(line.unitPriceCents)}/kg'
                      : '${line.presentation.name} · ${soles(line.unitPriceCents)}',
                  style: t.bodySmall!.merge(tabular),
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    if (line.priceOverrideCents != null)
                      const _Badge('Precio editado', EsquinitaColors.wood),
                    if (line.isWholesale)
                      const _Badge('Mayorista', EsquinitaColors.forest),
                    for (final take in line.lots)
                      _Badge(
                        '${take.lot.code} · vence ${_date(take.lot.expiresOn)} · ${Quantity(take.qtyMilli)}',
                        EsquinitaColors.wood,
                      ),
                    if (line.stockWarning)
                      const _Badge(
                        'Sin stock local: se registra con aviso',
                        EsquinitaColors.amber,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (p.byWeight)
            IconButton(
              tooltip: 'Cambiar peso',
              icon: const Icon(Icons.scale),
              onPressed: () async {
                final g = await showWeightCalculator(
                  context,
                  p,
                  initialGrams: line.qtyMilli,
                  initialPerKgCents: line.unitPriceCents,
                );
                if (g != null) store.setWeight(line, g.grams, g.perKgCents);
              },
            )
          else ...[
            IconButton(
              tooltip: 'Quitar uno',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => store.setQty(line, line.qtyMilli - 1000),
            ),
            Text(
              Quantity(line.qtyMilli).toString(),
              style: t.titleMedium!.merge(tabular),
            ),
            IconButton(
              tooltip: 'Agregar uno',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => store.setQty(line, line.qtyMilli + 1000),
            ),
          ],
          SizedBox(
            width: 84,
            child: Text(
              soles(line.totalCents),
              textAlign: TextAlign.right,
              style: t.titleSmall!.merge(tabular),
            ),
          ),
        ],
      ),
    );
  }
}

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class _CustomerButton extends StatelessWidget {
  const _CustomerButton();

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return TextButton.icon(
      onPressed: () async {
        final c = await showCustomerPicker(context);
        if (c != null) store.update(() => store.cartCustomer = c);
      },
      icon: const Icon(Icons.person_outline),
      label: Text(
        store.cartCustomer?.name ?? 'Público en general',
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ChargeButton extends StatelessWidget {
  const _ChargeButton({this.expand = true});

  final bool expand;

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final button = FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: EsquinitaColors.leaf,
        foregroundColor: Colors.white,
        minimumSize: const Size(140, 56),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      onPressed: store.cart.isEmpty ? null : () => _goToCheckout(context),
      child: Text('Cobrar ${soles(store.cartTotalCents)}', style: tabular),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

// ---------------------------------------------------------------------------
// Layouts (touch)

class _TwoPanelPos extends StatelessWidget {
  const _TwoPanelPos({required this.camera});

  final bool camera;

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _Catalog(
            asList: false,
            columns: MediaQuery.sizeOf(context).width >= 1200 ? 4 : 3,
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(
          width: 400,
          child: ColoredBox(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
                  child: Row(
                    children: [
                      Text(
                        'Venta',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      if (camera) const _ScanButton(),
                      IconButton(
                        tooltip: 'Vaciar venta',
                        onPressed: store.cart.isEmpty ? null : store.clearCart,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: _CustomerButton(),
                ),
                const Divider(height: 1),
                const Expanded(child: _CartList()),
                const Divider(height: 1),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: _ChargeButton(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Phone (one hand) and tablet portrait: catalog on top, cart summary and
/// the Cobrar button at the bottom, within thumb reach.
class _CompactPos extends StatelessWidget {
  const _CompactPos({required this.phone, required this.camera});

  final bool phone;
  final bool camera;

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return Column(
      children: [
        Expanded(child: _Catalog(asList: phone, columns: 3)),
        Material(
          elevation: 8,
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  if (camera) ...[
                    const _ScanButton(big: true),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                      ),
                      onPressed: () => _showCartSheet(context),
                      child: Text(
                        store.cart.isEmpty
                            ? 'Carrito vacío'
                            : '${store.cartItems} ítems',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _ChargeButton(expand: false),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void _showCartSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true, // above the bottom bar
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.75,
    maxChildSize: 0.95,
    builder: (context, _) => Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text('Venta', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              const Flexible(child: _CustomerButton()),
            ],
          ),
        ),
        const Divider(height: 1),
        const Expanded(child: _CartList()),
        const Padding(padding: EdgeInsets.all(12), child: _ChargeButton()),
      ],
    ),
  ),
);

/// Sales-context camera scan: retail formats only, QR off (CLAUDE.md §6.11).
class _ScanButton extends StatelessWidget {
  const _ScanButton({this.big = false});

  final bool big;

  @override
  Widget build(BuildContext context) => big
      ? IconButton.filled(
          tooltip: 'Escanear para vender',
          iconSize: 28,
          style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
          onPressed: () => _showSaleScanner(context),
          icon: const Icon(Icons.qr_code_scanner),
        )
      : IconButton(
          tooltip: 'Escanear para vender',
          onPressed: () => _showSaleScanner(context),
          icon: const Icon(Icons.qr_code_scanner),
        );
}

void _showSaleScanner(BuildContext context) {
  final store = DemoScope.read(context);
  final filter = ScanFilter();
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true, // above the bottom bar
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheet) => SizedBox(
      height: MediaQuery.sizeOf(sheet).height * 0.6,
      child: Stack(
        children: [
          Positioned.fill(
            child: CameraScanView(
              onCodes: (codes, elapsed, _) {
                for (final code in codes) {
                  if (!filter.offer(code, elapsed).isAccepted) continue;
                  final hit = store.findByBarcode(code);
                  final msg = hit == null
                      ? 'Código $code no registrado'
                      : hit.product.byWeight
                      ? '${hit.product.name} se vende por peso: tócalo en la lista para pesarlo'
                      : store.addToCart(hit.product, hit.presentation, 1000) ??
                            '${hit.product.name} agregado';
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        duration: const Duration(milliseconds: 1200),
                      ),
                    );
                }
              },
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: IconButton.filled(
              tooltip: 'Cerrar',
              onPressed: () => Navigator.pop(sheet),
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Desktop

class _DesktopPos extends StatefulWidget {
  const _DesktopPos();

  @override
  State<_DesktopPos> createState() => _DesktopPosState();
}

class _DesktopPosState extends State<_DesktopPos> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<DemoProduct> _results(DemoStore store) {
    final q = _query.toLowerCase();
    if (q.isEmpty) return const [];
    return [
      for (final p in store.catalog)
        if (p.name.toLowerCase().contains(q)) p,
    ].take(8).toList();
  }

  /// Enter: a barcode (USB reader types it + Enter) or the first result.
  Future<void> _submit(DemoStore store) async {
    final hit = store.findByBarcode(_query);
    if (hit != null) {
      if (hit.product.byWeight) {
        await addProductFlow(context, hit.product);
      } else {
        final err = store.addToCart(hit.product, hit.presentation, 1000);
        if (err != null && mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(err)));
        }
      }
    } else if (_results(store).firstOrNull case final p?) {
      await addProductFlow(context, p);
    } else if (_query.isNotEmpty && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sin resultados para "$_query"')));
      return;
    }
    _search.clear();
    setState(() => _query = '');
    _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final t = Theme.of(context).textTheme;
    final results = _results(store);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f2): _searchFocus.requestFocus,
        const SingleActivator(LogicalKeyboardKey.f4): () async {
          final c = await showCustomerPicker(context);
          if (c != null) store.update(() => store.cartCustomer = c);
        },
        const SingleActivator(LogicalKeyboardKey.f9): () =>
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nota de pedido: fuera del prototipo (Fase 3).'),
              ),
            ),
        const SingleActivator(LogicalKeyboardKey.f12): () =>
            _goToCheckout(context),
        const SingleActivator(LogicalKeyboardKey.escape): () {
          _search.clear();
          setState(() => _query = '');
        },
      },
      child: Focus(
        autofocus: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _search,
                      focusNode: _searchFocus,
                      autofocus: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar (F2) o escanear con el lector',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _query = v.trim()),
                      onSubmitted: (_) => _submit(store),
                    ),
                    if (results.isNotEmpty)
                      Card(
                        color: Colors.white,
                        child: Column(
                          children: [
                            for (final p in results)
                              ListTile(
                                dense: true,
                                title: Text(p.name),
                                trailing: Text(_priceLabel(p), style: tabular),
                                onTap: () async {
                                  await addProductFlow(context, p);
                                  _search.clear();
                                  setState(() => _query = '');
                                },
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Card(
                        margin: EdgeInsets.zero,
                        color: Colors.white,
                        child: store.cart.isEmpty
                            ? const Center(
                                child: Text(
                                  'Escanea con el lector o busca un producto (F2).',
                                ),
                              )
                            : _DesktopCartTable(store: store),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 320,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Cliente (F4)', style: t.labelLarge),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: _CustomerButton(),
                  ),
                  const Divider(),
                  Text('${store.cartItems} ítems', style: t.bodyMedium),
                  const SizedBox(height: 4),
                  Text('Total', style: t.titleMedium),
                  MoneyText(
                    store.cartTotalCents,
                    style: t.displaySmall!.copyWith(
                      color: EsquinitaColors.forest,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const _ShortcutHelp(),
                  const SizedBox(height: 12),
                  const _ChargeButton(),
                  const SizedBox(height: 4),
                  const Text('F12', textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutHelp extends StatelessWidget {
  const _ShortcutHelp();

  @override
  Widget build(BuildContext context) => const Text(
    'F2 buscar · F4 cliente · F9 nota de pedido · F12 cobrar · Esc cancelar',
    style: TextStyle(fontSize: 12, color: EsquinitaColors.wood),
  );
}

/// Dense cart rows: fixed numeric columns, flexible product name.
class _DesktopCartTable extends StatelessWidget {
  const _DesktopCartTable({required this.store});

  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget num(String s, double w, {TextStyle? style}) => SizedBox(
      width: w,
      child: Text(
        s,
        textAlign: TextAlign.right,
        style: (style ?? t.bodyMedium!).merge(tabular),
      ),
    );
    final header = t.labelMedium!.copyWith(color: EsquinitaColors.wood);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
          child: Row(
            children: [
              Expanded(child: Text('Producto', style: header)),
              num('Cant.', 72, style: header),
              num('P. unit.', 88, style: header),
              num('Importe', 96, style: header),
              const SizedBox(width: 148),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: store.cart.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final l = store.cart[i];
              final notes = [
                l.isWholesale
                    ? '${l.presentation.name} (mayorista)'
                    : l.presentation.name,
                for (final take in l.lots)
                  '${take.lot.code} (vence ${_date(take.lot.expiresOn)})',
                if (l.priceOverrideCents != null) 'precio editado',
                if (l.stockWarning) 'sin stock local',
              ].join(' · ');
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.product.name, overflow: TextOverflow.ellipsis),
                          Text(
                            notes,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall!.copyWith(
                              color: EsquinitaColors.wood,
                            ),
                          ),
                        ],
                      ),
                    ),
                    num(
                      l.product.byWeight
                          ? '${l.qtyMilli} g'
                          : Quantity(l.qtyMilli).toString(),
                      72,
                    ),
                    num(soles(l.unitPriceCents), 88),
                    num(soles(l.totalCents), 96, style: t.titleSmall),
                    SizedBox(
                      width: 148,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (l.product.byWeight)
                            IconButton(
                              tooltip: 'Cambiar peso',
                              icon: const Icon(Icons.scale),
                              onPressed: () async {
                                final g = await showWeightCalculator(
                                  context,
                                  l.product,
                                  initialGrams: l.qtyMilli,
                                  initialPerKgCents: l.unitPriceCents,
                                );
                                if (g != null) {
                                  store.setWeight(l, g.grams, g.perKgCents);
                                }
                              },
                            )
                          else ...[
                            IconButton(
                              tooltip: 'Quitar uno',
                              icon: const Icon(Icons.remove),
                              onPressed: () =>
                                  store.setQty(l, l.qtyMilli - 1000),
                            ),
                            IconButton(
                              tooltip: 'Agregar uno',
                              icon: const Icon(Icons.add),
                              onPressed: () =>
                                  store.setQty(l, l.qtyMilli + 1000),
                            ),
                          ],
                          IconButton(
                            tooltip: 'Quitar línea',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => store.setQty(l, 0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
