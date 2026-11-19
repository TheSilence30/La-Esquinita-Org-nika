import 'dart:math';

import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/widgets.dart';

import 'checkout.dart';
import 'demo_data.dart';
import 'widgets/notice.dart';

/// What a sales scan did. [weigh]: open the weight calculator for it.
/// [unknownCode]: offer to register it.
typedef ScanOutcome = ({
  NoticeLevel level,
  String message,
  DemoProduct? weigh,
  String? unknownCode,
});

enum DemoRole {
  admin('Administrador'),
  staff('Trabajo');

  const DemoRole(this.label);
  final String label;
}

enum DemoSyncState { synced, pending, error }

class LotTake {
  const LotTake(this.lot, this.qtyMilli);

  final DemoLot lot;
  final int qtyMilli;
}

class CartLine {
  CartLine(this.product, this.presentation, this.qtyMilli);

  final DemoProduct product;
  final DemoPresentation presentation;

  /// In the presentation; grams for products sold by weight.
  int qtyMilli;

  int get baseQtyMilli => qtyMilli * presentation.factorMilli ~/ 1000;

  bool get isWholesale =>
      presentation.wholesaleCents != null &&
      presentation.wholesaleMinMilli != null &&
      qtyMilli >= presentation.wholesaleMinMilli!;

  /// Price per kg typed in the weight calculator for this sale (Fase 3:
  /// needs `sales.change_price` and is audited, CLAUDE.md §6.13).
  int? priceOverrideCents;

  int get unitPriceCents =>
      priceOverrideCents ??
      (isWholesale ? presentation.wholesaleCents! : presentation.retailCents);

  int get totalCents => Money(unitPriceCents).times(Quantity(qtyMilli)).cents;

  /// FEFO split for lot-tracked products (empty otherwise).
  List<LotTake> lots = const [];

  /// Sold beyond the sellable local stock: recorded with a warning.
  bool stockWarning = false;
}

class DemoSale {
  DemoSale({
    required this.number,
    required this.at,
    required this.totalCents,
    required this.lines,
    required this.payments,
    this.credit = false,
    this.customer,
    this.changeCents = 0,
  });

  final int number;
  final DateTime at;
  final int totalCents;
  final List<(String name, String qty, int totalCents)> lines;

  /// Method → cents (empty for credit sales).
  final Map<PayMethod, int> payments;
  final bool credit;
  final DemoCustomer? customer;
  final int changeCents;

  String get code => 'T1-${number.toString().padLeft(6, '0')}';
}

class DeviceStatus {
  DeviceStatus(this.name, this.lastSync, this.pendingSales);

  final String name;
  DateTime lastSync;
  int pendingSales;
}

/// Everything the prototype shows, in memory. Fase 1 replaces this with
/// drift, the outbox and Riverpod.
class DemoStore extends ChangeNotifier {
  DemoStore({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    final now = _clock();
    catalog = sampleCatalog(now);
    cashOpenedAt = DateTime(now.year, now.month, now.day, 8);
    devices = [
      DeviceStatus('Tablet (este equipo)', now, 0),
      DeviceStatus('PC caja', now.subtract(const Duration(minutes: 3)), 2),
    ];
    _seedSales(now);
  }

  final DateTime Function() _clock;
  DateTime get now => _clock();

  late final List<DemoProduct> catalog;
  final customers = List<DemoCustomer>.of(sampleCustomers);

  // --- Demo settings (Más › Ajustes de demostración) ---------------------
  bool mixedPayments = true;
  DemoRole role = DemoRole.admin;
  DemoSyncState syncState = DemoSyncState.synced;

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  bool get isAdmin => role == DemoRole.admin;

  // --- Cart ----------------------------------------------------------------
  final cart = <CartLine>[];
  DemoCustomer? cartCustomer;

  int get cartTotalCents => cart.fold(0, (s, l) => s + l.totalCents);
  int get cartItems => cart.length;

  /// Adds [qtyMilli] of [presentation]. Same presentation (not by weight)
  /// increments the existing line. Returns an error message or null.
  String? addToCart(
    DemoProduct product,
    DemoPresentation presentation,
    int qtyMilli, {
    int? perKgCents,
  }) {
    if (product.tracksLots && product.lots.every((l) => l.isExpired(now))) {
      return 'Todos los lotes de ${product.name} están vencidos: no se puede vender.';
    }
    final existing = product.byWeight
        ? null
        : cart
              .where(
                (l) => l.product == product && l.presentation == presentation,
              )
              .firstOrNull;
    final line = existing ?? CartLine(product, presentation, 0);
    line.qtyMilli += qtyMilli;
    if (perKgCents != null && perKgCents != presentation.retailCents) {
      line.priceOverrideCents = perKgCents;
    }
    if (existing == null) cart.add(line);
    _allocate(line);
    notifyListeners();
    return null;
  }

  /// Sales scan, as a traffic light: green added; amber added but needs a
  /// look (no local stock — still sold, docs/modelo-datos.md — or low
  /// stock) or sold by weight (the caller opens the calculator); red not
  /// registered or blocked (expired lots).
  ScanOutcome scanForSale(String code) {
    final hit = findByBarcode(code);
    if (hit == null) {
      return (
        level: NoticeLevel.error,
        message: 'Código $code no registrado',
        weigh: null,
        unknownCode: code,
      );
    }
    final p = hit.product;
    if (p.byWeight) {
      return (
        level: NoticeLevel.warn,
        message: '${p.name}: se vende por peso',
        weigh: p,
        unknownCode: null,
      );
    }
    final error = addToCart(p, hit.presentation, 1000);
    if (error != null) {
      return (
        level: NoticeLevel.error,
        message: error,
        weigh: null,
        unknownCode: null,
      );
    }
    final inCart = cart
        .where((l) => l.product == p)
        .fold(0, (s, l) => s + l.baseQtyMilli);
    final line = cart.firstWhere(
      (l) => l.product == p && l.presentation == hit.presentation,
    );
    final added = '${p.name} ×${Quantity(line.qtyMilli)}';
    final (level, note) = line.stockWarning
        ? (NoticeLevel.warn, ' · sin stock local')
        : p.totalStockMilli - inCart <= p.minStockMilli
        ? (NoticeLevel.warn, ' · stock bajo')
        : (NoticeLevel.ok, '');
    return (
      level: level,
      message: added + note,
      weigh: null,
      unknownCode: null,
    );
  }

  void setQty(CartLine line, int qtyMilli) {
    if (qtyMilli <= 0) {
      cart.remove(line);
    } else {
      line.qtyMilli = qtyMilli;
      _allocate(line);
    }
    notifyListeners();
  }

  /// Weight line edited in the calculator: new grams and price per kg.
  void setWeight(CartLine line, int grams, int perKgCents) {
    line.priceOverrideCents = perKgCents == line.presentation.retailCents
        ? null
        : perKgCents;
    setQty(line, grams);
  }

  void clearCart() {
    cart.clear();
    cartCustomer = null;
    notifyListeners();
  }

  /// FEFO over non-expired lots; the shortfall goes to the lot that expires
  /// last and the line is flagged (docs/modelo-datos.md §3.2).
  void _allocate(CartLine line) {
    final p = line.product;
    var need = line.baseQtyMilli;
    if (!p.tracksLots) {
      line.stockWarning = need > p.stockMilli;
      return;
    }
    final usable = p.lots.where((l) => !l.isExpired(now)).toList()
      ..sort((a, b) => a.expiresOn.compareTo(b.expiresOn));
    final takes = <LotTake>[];
    for (final lot in usable) {
      if (need == 0) break;
      final take = min(need, max(0, lot.qtyMilli));
      if (take > 0) {
        takes.add(LotTake(lot, take));
        need -= take;
      }
    }
    line.stockWarning = need > 0;
    if (need > 0) takes.add(LotTake(usable.last, need));
    line.lots = takes;
  }

  ({DemoProduct product, DemoPresentation presentation})? findByBarcode(
    String code,
  ) {
    for (final p in catalog) {
      for (final pr in p.presentations) {
        if (pr.barcode == code) return (product: p, presentation: pr);
      }
    }
    return null;
  }

  // --- Sales -----------------------------------------------------------------
  final sales = <DemoSale>[];
  int _nextNumber = 120;

  DemoSale confirmSale(CheckoutDraft draft) {
    final sale = DemoSale(
      number: _nextNumber++,
      at: now,
      totalCents: draft.totalCents,
      credit: draft.credit,
      customer: draft.credit ? draft.customer : cartCustomer,
      changeCents: draft.credit ? 0 : draft.changeCents,
      lines: [
        for (final l in cart)
          (
            l.product.name,
            l.product.byWeight
                ? '${l.qtyMilli} g'
                : '${Quantity(l.qtyMilli)} × ${l.presentation.name}',
            l.totalCents,
          ),
      ],
      payments: draft.credit
          ? const {}
          : {for (final p in draft.parts) p.method: p.amountCents},
    );
    for (final l in cart) {
      if (l.product.tracksLots) {
        for (final t in l.lots) {
          t.lot.qtyMilli -= t.qtyMilli;
        }
      } else {
        l.product.stockMilli -= l.baseQtyMilli;
      }
    }
    sales.add(sale);
    cart.clear();
    cartCustomer = null;
    devices.first.lastSync = now;
    notifyListeners();
    return sale;
  }

  List<DemoSale> get todaySales => [
    for (final s in sales)
      if (_sameDay(s.at, now)) s,
  ];

  int methodTotal(PayMethod m, Iterable<DemoSale> from) =>
      from.fold(0, (s, x) => s + (x.payments[m] ?? 0));

  // --- Cash (one shared drawer, docs/modelo-datos.md §3.5) -----------------
  bool cashOpen = true;
  late DateTime cashOpenedAt;
  int openingFloatCents = 10000;
  late final List<DeviceStatus> devices;

  Iterable<DemoSale> get sessionSales =>
      sales.where((s) => !s.at.isBefore(cashOpenedAt));

  int get expectedCashCents =>
      openingFloatCents + methodTotal(PayMethod.cash, sessionSales);

  int get pendingSalesOnOtherDevices =>
      devices.skip(1).fold(0, (s, d) => s + d.pendingSales);

  void openCash(int floatCents) {
    cashOpen = true;
    cashOpenedAt = now;
    openingFloatCents = floatCents;
    notifyListeners();
  }

  void closeCash() {
    cashOpen = false;
    notifyListeners();
  }

  /// "Esperar": the other devices finish sending (simulated).
  void simulateDevicesSynced() {
    for (final d in devices) {
      d
        ..pendingSales = 0
        ..lastSync = now;
    }
    notifyListeners();
  }

  // --- Registration ----------------------------------------------------------
  int _nextBarcodeSeq = 1;

  /// Internal EAN-13 for products without a code (prefix 29, device 1).
  String nextInternalBarcode() =>
      internalEan13(deviceDigit: 1, sequence: _nextBarcodeSeq++);

  void registerProduct(DemoProduct product) {
    catalog.add(product);
    notifyListeners();
  }

  // --- Seed --------------------------------------------------------------------
  void _seedSales(DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    final seeds = <(int hour, int min, int cents, PayMethod?, bool credit)>[
      (8, 42, 2590, PayMethod.cash, false),
      (9, 15, 4340, PayMethod.yape, false),
      (9, 58, 1450, PayMethod.cash, false),
      (10, 31, 15600, PayMethod.transfer, false),
      (11, 5, 3890, PayMethod.plin, false),
      (11, 47, 980, PayMethod.cash, false),
      (12, 20, 6720, null, true),
      (13, 10, 2790, PayMethod.yape, false),
    ];
    for (final (h, m, cents, method, credit) in seeds) {
      final at = day.add(Duration(hours: h, minutes: m));
      if (at.isAfter(now)) continue;
      sales.add(
        DemoSale(
          number: _nextNumber++,
          at: at,
          totalCents: cents,
          credit: credit,
          customer: credit ? customers[1] : null,
          lines: const [],
          payments: method == null ? const {} : {method: cents},
        ),
      );
    }
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Gives the screens access to the [DemoStore] and rebuilds them on change.
class DemoScope extends InheritedNotifier<DemoStore> {
  const DemoScope({super.key, required DemoStore store, required super.child})
    : super(notifier: store);

  static DemoStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DemoScope>()!.notifier!;

  /// For callbacks: no rebuild dependency.
  static DemoStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DemoScope>()!.notifier!;
}
