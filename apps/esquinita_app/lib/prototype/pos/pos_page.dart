import 'dart:async';

import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/form_factor.dart';
import '../../app/theme.dart';
import '../../devices/feedback/scan_feedback.dart';
import '../../devices/scanner/camera_scan_view.dart';
import '../checkout/checkout_view.dart';
import '../demo_data.dart';
import '../demo_store.dart';
import '../widgets/common.dart';
import '../widgets/keypad.dart';
import '../widgets/notice.dart';
import 'pos_dialogs.dart';

/// Point of sale. Independent layouts per form factor (CLAUDE.md §2):
/// phone (one hand, list + bottom bar), tablet portrait (grid + bottom
/// bar), tablet landscape (two panels), PC (dense table + shortcuts).
class PosPage extends StatelessWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final camera = isCameraScanSupported;
    // Phone and tablet look alike sideways: two panels once there is room.
    return switch (FormFactor.of(context)) {
      FormFactor.desktop => const _DesktopPos(),
      _ when MediaQuery.sizeOf(context).width >= 840 => _TwoPanelPos(
        camera: camera,
      ),
      final f => _CompactPos(phone: f == FormFactor.phone, camera: camera),
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
  const _Catalog({required this.asList});

  final bool asList;

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
                  // Columns follow the space left by the cart, so names get
                  // a readable width on every tablet orientation.
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 210,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    // Phone sideways (~410 dp tall): 2-line names, so more
                    // than one row of cards fits.
                    mainAxisExtent: MediaQuery.sizeOf(context).height < 500
                        ? 112
                        : 150,
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
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
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
  const _CartList({this.newestFirst = false});

  /// Scanner: the line just added shows at the top, in view.
  final bool newestFirst;

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
      itemBuilder: (context, i) {
        final line = store.cart[newestFirst ? store.cart.length - 1 - i : i];
        return Dismissible(
          key: ObjectKey(line),
          direction: DismissDirection.endToStart,
          background: Container(
            color: EsquinitaColors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) => store.setQty(line, 0),
          child: _CartLineTile(line),
        );
      },
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
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  p.name,
                  style: t.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  soles(line.totalCents),
                  style: t.titleMedium!.merge(tabular),
                ),
              ),
            ],
          ),
          Text(
            p.byWeight
                ? '${weightLabel(line.qtyMilli)} × ${soles(line.unitPriceCents)}/kg'
                : '${line.presentation.name} · ${soles(line.unitPriceCents)} c/u',
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
              if (p.tracksLots)
                for (final take in line.lots)
                  InkWell(
                    onTap: () => _showLotPicker(context, line),
                    child: _Badge(
                      '${_takeLabel(take)} · ${Quantity(take.qtyMilli)}'
                      '${line.pinnedLot != null || line.pinnedNoLot ? ' (elegido)' : ''}'
                      '  ✎',
                      EsquinitaColors.wood,
                    ),
                  ),
              if (line.stockWarning)
                const _Badge(
                  'Sin stock local: se registra con aviso',
                  EsquinitaColors.amber,
                ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (p.byWeight)
                TextButton.icon(
                  onPressed: () async {
                    final g = await showWeightCalculator(
                      context,
                      p,
                      initialGrams: line.qtyMilli,
                      initialPerKgCents: line.unitPriceCents,
                    );
                    if (g != null && context.mounted) {
                      await changeLineQty(
                        context,
                        line,
                        g.grams,
                        perKgCents: g.perKgCents,
                      );
                    }
                  },
                  icon: const Icon(Icons.scale),
                  label: const Text('Cambiar peso'),
                )
              else ...[
                IconButton(
                  tooltip: 'Quitar uno',
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => store.setQty(line, line.qtyMilli - 1000),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    Quantity(line.qtyMilli).toString(),
                    textAlign: TextAlign.center,
                    style: t.titleMedium!.merge(tabular),
                  ),
                ),
                IconButton(
                  tooltip: 'Agregar uno',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () =>
                      changeLineQty(context, line, line.qtyMilli + 1000),
                ),
              ],
              IconButton(
                tooltip: 'Eliminar producto',
                icon: const Icon(
                  Icons.delete_outline,
                  color: EsquinitaColors.red,
                ),
                onPressed: () => store.setQty(line, 0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Empties the sale after a confirmation (it cannot be undone).
class _ClearCartButton extends StatelessWidget {
  const _ClearCartButton();

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return TextButton.icon(
      style: TextButton.styleFrom(foregroundColor: EsquinitaColors.red),
      onPressed: store.cart.isEmpty
          ? null
          : () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (dialog) => AlertDialog(
                  title: const Text('¿Vaciar la venta?'),
                  content: Text(
                    'Se quitarán los ${store.cartItems} productos del carrito.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: EsquinitaColors.red,
                      ),
                      onPressed: () => Navigator.pop(dialog, true),
                      child: const Text('Vaciar'),
                    ),
                  ],
                ),
              );
              if (ok ?? false) store.clearCart();
            },
      icon: const Icon(Icons.remove_shopping_cart_outlined),
      label: const Text('Vaciar venta'),
    );
  }
}

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _takeLabel(LotTake t) => switch (t.lot) {
  final lot? => '${lot.code} · vence ${_date(lot.expiresOn)}',
  null => 'Sin lote',
};

/// Cart line: change the lot it is taken from (FEFO by default).
Future<void> _showLotPicker(BuildContext context, CartLine line) =>
    showAdaptiveSheet<void>(
      context,
      builder: (sheet) {
        final store = DemoScope.read(context);
        final p = line.product;
        void pick({DemoLot? lot, bool noLot = false}) {
          store.pinLot(line, lot: lot, noLot: noLot);
          Navigator.pop(sheet);
        }

        final auto = line.pinnedLot == null && !line.pinnedNoLot;
        final lots = [...p.lots]
          ..sort((a, b) => a.expiresOn.compareTo(b.expiresOn));
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          children: [
            ListTile(
              title: Text(
                '¿De qué lote sale ${p.name}?',
                style: Theme.of(sheet).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: Icon(
                auto ? Icons.radio_button_checked : Icons.radio_button_off,
              ),
              title: const Text('Automático: primero el que vence antes'),
              onTap: () => pick(),
            ),
            for (final l in lots)
              ListTile(
                enabled: !l.isExpired(store.now),
                leading: Icon(
                  line.pinnedLot == l
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(l.code),
                subtitle: Text(
                  l.isExpired(store.now)
                      ? 'Vencido: bloqueado'
                      : 'Vence ${_date(l.expiresOn)}',
                ),
                trailing: Text(Quantity(l.qtyMilli).toString(), style: tabular),
                onTap: () => pick(lot: l),
              ),
            if (p.stockMilli > 0)
              ListTile(
                leading: Icon(
                  line.pinnedNoLot
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: const Text('Sin lote'),
                trailing: Text(
                  Quantity(p.stockMilli).toString(),
                  style: tabular,
                ),
                onTap: () => pick(noLot: true),
              ),
          ],
        );
      },
    );

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
  const _ChargeButton();

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: EsquinitaColors.leaf,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      onPressed: store.cart.isEmpty ? null : () => _goToCheckout(context),
      // Big totals shrink instead of pushing other buttons off screen.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text('Cobrar ${soles(store.cartTotalCents)}', style: tabular),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Layouts (touch)

class _TwoPanelPos extends StatelessWidget {
  const _TwoPanelPos({required this.camera});

  final bool camera;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(flex: 3, child: _Catalog(asList: false)),
        const VerticalDivider(width: 1),
        SizedBox(
          width: (MediaQuery.sizeOf(context).width * 0.38).clamp(320.0, 420.0),
          child: ColoredBox(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Venta',
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (camera) const _ScanButton(),
                      const _ClearCartButton(),
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
        Expanded(child: _Catalog(asList: phone)),
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
                    flex: 2,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                      ),
                      onPressed: () => _showCartSheet(context),
                      child: Text(
                        store.cart.isEmpty
                            ? '0 ítems' // "Carrito vacío" was cut at 360 dp
                            : '${store.cartItems} ítems',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(flex: 3, child: _ChargeButton()),
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
              const _ClearCartButton(),
            ],
          ),
        ),
        const Align(alignment: Alignment.centerLeft, child: _CustomerButton()),
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

void _showSaleScanner(BuildContext context) => context.push('/escanear-venta');

/// Sales scanner, full screen: camera with a frame on one half, the live
/// cart on the other (top/bottom in portrait, left/right in landscape).
/// Each read shows a traffic-light notice above the camera.
class SaleScannerPage extends StatefulWidget {
  const SaleScannerPage({super.key});

  @override
  State<SaleScannerPage> createState() => SaleScannerPageState();
}

class SaleScannerPageState extends State<SaleScannerPage> {
  final _filter = ScanFilter();

  /// A dialog (weight calculator, "Sin stock") is open: ignore the camera.
  bool _paused = false;

  /// Camera frames. Public for tests. Each code goes through the filter
  /// exactly once per frame: a lazy `where` here re-ran it, the second call
  /// hit the cooldown and every accepted read was lost ("No element").
  Future<void> onCameraCodes(List<String> codes, Duration elapsed) async {
    if (_paused) return;
    final accepted = [
      for (final c in codes)
        if (_filter.offer(c, elapsed).isAccepted) c,
    ];
    if (accepted.isEmpty) return;
    await handleSaleScan(context, accepted.first);
  }

  /// Public for tests (no camera there).
  Future<void> handleSaleScan(BuildContext context, String code) async {
    final store = DemoScope.read(context);
    final hit = store.findByBarcode(code);
    if (hit != null && !hit.product.byWeight) {
      _paused = true; // the camera keeps reading behind the dialog
      await askOversell(context, hit.product, hit.presentation.factorMilli);
      _paused = false;
      if (!context.mounted) return;
    }
    final r = store.scanForSale(code);
    unawaited(
      r.level == NoticeLevel.error
          ? ScanFeedback.error()
          : ScanFeedback.success(),
    );
    final unknown = r.unknownCode;
    showNotice(
      context,
      r.message,
      level: r.level,
      sticky: r.level == NoticeLevel.error, // until tapped or the next read
      actionLabel: unknown == null ? null : 'Registrar',
      onAction: unknown == null
          ? null
          : () => context.go('/escanear?code=$unknown'),
    );
    final weigh = r.weigh;
    if (weigh == null) return;
    _paused = true;
    final pick = await showWeightCalculator(context, weigh);
    if (pick != null && context.mounted) {
      await askOversell(context, weigh, pick.grams);
    }
    _paused = false;
    if (pick == null || !context.mounted) return;
    final error = store.addToCart(
      weigh,
      weigh.base,
      pick.grams,
      perKgCents: pick.perKgCents,
    );
    showNotice(
      context,
      error ?? '${weigh.name} ${weightLabel(pick.grams)}',
      level: error == null ? NoticeLevel.ok : NoticeLevel.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final size = MediaQuery.sizeOf(context);
    final camera = Stack(
      fit: StackFit.expand,
      children: [
        if (isCameraScanSupported)
          CameraScanView(
            onCodes: (codes, elapsed, _) => onCameraCodes(codes, elapsed),
            overlay: const ScanFrame(),
          )
        else
          const ColoredBox(
            color: Colors.black,
            child: Stack(
              children: [
                ScanFrame(),
                Center(
                  child: Text(
                    'Cámara no disponible',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        // Bottom corner: the top is where notices appear.
        Positioned(
          right: 12,
          bottom: 12,
          child: IconButton.filled(
            tooltip: 'Cerrar escáner',
            iconSize: 28,
            style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
    final cart = ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    store.cart.isEmpty
                        ? 'Venta'
                        : 'Venta · ${store.cartItems} ítems',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const _ClearCartButton(),
              ],
            ),
          ),
          const Divider(height: 1),
          const Expanded(child: _CartList(newestFirst: true)),
          const Divider(height: 1),
          const Padding(padding: EdgeInsets.all(12), child: _ChargeButton()),
        ],
      ),
    );
    return AnnotatedRegion(
      value: SystemUiOverlayStyle.light, // white icons over the camera
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Flex(
            direction: size.width > size.height
                ? Axis.horizontal
                : Axis.vertical,
            children: [
              Expanded(child: camera),
              Expanded(child: cart),
            ],
          ),
        ),
      ),
    );
  }
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
    if (hit != null && hit.product.byWeight) {
      unawaited(ScanFeedback.success());
      await addProductFlow(context, hit.product);
    } else if (hit != null) {
      // Same traffic light as the camera scanner.
      await askOversell(context, hit.product, hit.presentation.factorMilli);
      if (!mounted) return;
      final r = store.scanForSale(_query);
      unawaited(
        r.level == NoticeLevel.error
            ? ScanFeedback.error()
            : ScanFeedback.success(),
      );
      showNotice(context, r.message, level: r.level);
    } else if (_results(store).firstOrNull case final p?) {
      await addProductFlow(context, p);
    } else if (_query.isNotEmpty && mounted) {
      unawaited(ScanFeedback.error());
      showNotice(
        context,
        'Sin resultados para "$_query"',
        level: NoticeLevel.error,
      );
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
        const SingleActivator(LogicalKeyboardKey.f9): () => showNotice(
          context,
          'Nota de pedido: fuera del prototipo (Fase 3).',
          level: NoticeLevel.warn,
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: _ClearCartButton(),
                  ),
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
                if (l.product.tracksLots)
                  for (final take in l.lots) _takeLabel(take),
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
                          ? weightLabel(l.qtyMilli)
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
                                if (g != null && context.mounted) {
                                  await changeLineQty(
                                    context,
                                    l,
                                    g.grams,
                                    perKgCents: g.perKgCents,
                                  );
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
                                  changeLineQty(context, l, l.qtyMilli + 1000),
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
