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

  /// Null: from the stock without lot.
  final DemoLot? lot;
  final int qtyMilli;
}

/// One stock change (kardex). shortcut: in memory; Fase 2 stores them as
/// `stock_movements`, the only way stock changes (CLAUDE.md §6.1).
class DemoMovement {
  const DemoMovement(
    this.at,
    this.product,
    this.lotCode,
    this.deltaMilli,
    this.reason,
  );

  final DateTime at;
  final DemoProduct product;

  /// Null: stock without lot.
  final String? lotCode;
  final int deltaMilli;
  final String reason;
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

  /// Where the quantity comes from: FEFO over lots, then stock without lot.
  List<LotTake> lots = const [];

  /// Lot chosen by hand (taken first, the rest by FEFO), or [pinnedNoLot]
  /// for the stock without lot. Neither: automatic FEFO.
  DemoLot? pinnedLot;
  bool pinnedNoLot = false;

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

  /// Per sale, the answer to "¿Agregar de todas formas?" for a product that
  /// goes past its sellable local stock: true sells anyway (amber), false
  /// keeps rejecting it (red) until the cart is emptied.
  final _oversell = <DemoProduct, bool>{};

  int _inCartMilli(DemoProduct p) =>
      cart.where((l) => l.product == p).fold(0, (s, l) => s + l.baseQtyMilli);

  /// Adding [addBaseMilli] of [p] goes past the sellable stock and nobody
  /// has answered yet for this sale: the UI asks, then [decideOversell].
  bool needsOversellAnswer(DemoProduct p, int addBaseMilli) =>
      !_oversell.containsKey(p) && _wouldOversell(p, addBaseMilli);

  void decideOversell(DemoProduct p, {required bool sell}) =>
      _oversell[p] = sell;

  bool _wouldOversell(DemoProduct p, int addBaseMilli) =>
      _inCartMilli(p) + addBaseMilli > p.sellableStockMilli(now);

  String? _oversellError(DemoProduct p, int addBaseMilli) =>
      _wouldOversell(p, addBaseMilli) && _oversell[p] != true
      ? 'Sin stock: ${p.name} (quedan ${Quantity(max(0, p.sellableStockMilli(now) - _inCartMilli(p)))})'
      : null;
  int get cartItems => cart.length;

  /// Adds [qtyMilli] of [presentation]. Same presentation (not by weight)
  /// increments the existing line. Returns an error message or null.
  String? addToCart(
    DemoProduct product,
    DemoPresentation presentation,
    int qtyMilli, {
    int? perKgCents,
  }) {
    if (product.tracksLots &&
        product.stockMilli <= 0 &&
        product.lots.every((l) => l.isExpired(now))) {
      return 'Todos los lotes de ${product.name} están vencidos: no se puede vender.';
    }
    final over = _oversellError(
      product,
      qtyMilli * presentation.factorMilli ~/ 1000,
    );
    if (over != null) return over;
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
  /// look (past the local stock and the user said "Sí", or low stock) or
  /// sold by weight (the caller opens the calculator); red not registered,
  /// blocked (expired lots) or past the stock without a "Sí".
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
    final inCart = _inCartMilli(p);
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

  // --- Inventory (prototype: lets the user try stock-outs and expiry) -----
  // shortcut: edits the in-memory stock directly; Fase 2 records each
  // change as a stock_movement with reason and user (CLAUDE.md §6.1).

  final movements = <DemoMovement>[];

  /// Latest first.
  List<DemoMovement> movementsOf(DemoProduct p) => [
    for (final m in movements.reversed)
      if (m.product == p) m,
  ];

  /// Adds (+) or removes (−) stock in [lot], or in the stock without lot.
  /// Never below zero; records what really changed.
  void adjustStock(
    DemoProduct p,
    int deltaMilli, {
    DemoLot? lot,
    required String reason,
  }) {
    final before = lot?.qtyMilli ?? p.stockMilli;
    final after = max(0, before + deltaMilli);
    if (lot != null) {
      lot.qtyMilli = after;
    } else {
      p.stockMilli = after;
    }
    if (after != before) {
      movements.add(DemoMovement(now, p, lot?.code, after - before, reason));
    }
    notifyListeners();
  }

  /// Physical count: sets [lot] (or the stock without lot) to [countedMilli].
  void countStock(DemoProduct p, int countedMilli, {DemoLot? lot}) =>
      adjustStock(
        p,
        countedMilli - (lot?.qtyMilli ?? p.stockMilli),
        lot: lot,
        reason: 'Conteo físico',
      );

  void setLotExpiry(DemoLot lot, DateTime expiresOn) {
    lot.expiresOn = expiresOn;
    notifyListeners();
  }

  void setMinStock(DemoProduct p, int minMilli) {
    p.minStockMilli = minMilli;
    notifyListeners();
  }

  /// Error message, or null when [code] can be a new lot of [p].
  String? checkLotCode(DemoProduct p, String code) => code.trim().isEmpty
      ? 'Escribe el código del lote (viene en el empaque).'
      : [
          ...p.lots,
          ...p.retiredLots,
        ].any((l) => l.code.toLowerCase() == code.trim().toLowerCase())
      ? 'Ya existe el lote ${code.trim()} para este producto.'
      : null;

  /// New lot with [qtyMilli] received. [moveUnlotted]: the stock without
  /// lot goes into it as well (the user is asked when there is some).
  DemoLot addLot(
    DemoProduct p,
    String code,
    DateTime expiresOn,
    int qtyMilli, {
    bool moveUnlotted = false,
  }) {
    final lot = DemoLot(code.trim(), expiresOn, 0);
    p.lots.add(lot);
    if (moveUnlotted) assignLot(p, lot, p.stockMilli);
    if (qtyMilli > 0) {
      lot.qtyMilli += qtyMilli;
      movements.add(
        DemoMovement(now, p, lot.code, qtyMilli, 'Ingreso de lote nuevo'),
      );
    }
    notifyListeners();
    return lot;
  }

  /// Returns an error message (past the stock without a "Sí") or null.
  String? setQty(CartLine line, int qtyMilli) {
    final more =
        (qtyMilli - line.qtyMilli) * line.presentation.factorMilli ~/ 1000;
    if (more > 0) {
      final over = _oversellError(line.product, more);
      if (over != null) return over;
    }
    if (qtyMilli <= 0) {
      cart.remove(line);
    } else {
      line.qtyMilli = qtyMilli;
      _allocate(line);
    }
    notifyListeners();
    return null;
  }

  /// Weight line edited in the calculator: new grams and price per kg.
  String? setWeight(CartLine line, int grams, int perKgCents) {
    final error = setQty(line, grams);
    if (error == null) {
      line.priceOverrideCents = perKgCents == line.presentation.retailCents
          ? null
          : perKgCents;
      notifyListeners();
    }
    return error;
  }

  void clearCart() {
    cart.clear();
    _oversell.clear();
    cartCustomer = null;
    notifyListeners();
  }

  /// The lot picked by hand first, then FEFO over non-expired lots, then the
  /// stock without lot. A shortfall goes to the last source used and the
  /// line is flagged (sold anyway, docs/modelo-datos.md §3.2).
  void _allocate(CartLine line) {
    final p = line.product;
    var need = line.baseQtyMilli;
    final fefo = p.lots.where((l) => !l.isExpired(now)).toList()
      ..sort((a, b) => a.expiresOn.compareTo(b.expiresOn));
    final pinned = line.pinnedLot;
    final sources = <DemoLot?>[
      if (line.pinnedNoLot) null else ?pinned,
      ...fefo.where((l) => l != pinned),
      if (!line.pinnedNoLot) null,
    ];
    final takes = <LotTake>[];
    for (final src in sources) {
      if (need == 0) break;
      final take = min(need, max(0, src?.qtyMilli ?? p.stockMilli));
      if (take > 0) {
        takes.add(LotTake(src, take));
        need -= take;
      }
    }
    line.stockWarning = need > 0;
    if (need > 0) {
      final last = takes.isEmpty ? null : takes.removeLast();
      takes.add(
        LotTake(
          last?.lot ?? pinned ?? fefo.lastOrNull,
          (last?.qtyMilli ?? 0) + need,
        ),
      );
    }
    line.lots = takes;
  }

  /// From the cart: take this line from [lot] (or the stock without lot
  /// when [noLot]); both unset = automatic FEFO.
  void pinLot(CartLine line, {DemoLot? lot, bool noLot = false}) {
    line
      ..pinnedLot = lot
      ..pinnedNoLot = noLot;
    _allocate(line);
    notifyListeners();
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
      for (final t in l.lots) {
        if (t.lot case final lot?) {
          lot.qtyMilli -= t.qtyMilli;
        } else {
          l.product.stockMilli -= t.qtyMilli;
        }
        movements.add(
          DemoMovement(
            now,
            l.product,
            t.lot?.code,
            -t.qtyMilli,
            'Venta ${sale.code}',
          ),
        );
      }
    }
    sales.add(sale);
    cart.clear();
    _oversell.clear();
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

  /// "Dar de baja" (e.g. an expired lot): what is left goes out as
  /// "Merma / vencido" and the lot stops showing. Not deleted (§6.3).
  void retireLot(DemoProduct p, DemoLot lot) {
    adjustStock(p, -lot.qtyMilli, lot: lot, reason: 'Merma / vencido');
    p.lots.remove(lot);
    p.retiredLots.add(lot);
    for (final l in cart.where((l) => l.product == p)) {
      if (l.pinnedLot == lot) l.pinnedLot = null;
      _allocate(l);
    }
    notifyListeners();
  }

  /// Moves [qtyMilli] of the stock without lot into [lot] (capped at what
  /// there is): e.g. 10 of the 18 coffees without lot are LOT34.
  void assignLot(DemoProduct p, DemoLot lot, int qtyMilli) {
    final moved = min(qtyMilli, p.stockMilli);
    if (moved <= 0) return;
    p.stockMilli -= moved;
    lot.qtyMilli += moved;
    movements
      ..add(DemoMovement(now, p, null, -moved, 'Pasado al lote ${lot.code}'))
      ..add(DemoMovement(now, p, lot.code, moved, 'Desde stock sin lote'));
    notifyListeners();
  }

  /// Edits the product data (Administrador). [boxUnits] null: no box.
  /// Returns an error message or null. The barcode is unique across all
  /// presentations (CLAUDE.md §6.12).
  String? updateProduct(
    DemoProduct p, {
    required String name,
    required String category,
    required int retailCents,
    required String? barcode,
    required int minStockMilli,
    int? boxUnits,
    int? boxCents,
  }) {
    final code = barcode?.trim();
    final taken = code == null || code.isEmpty ? null : findByBarcode(code);
    if (taken != null && taken.product != p) {
      return 'El código $code ya es de ${taken.product.name}.';
    }
    final box = p.presentations.length > 1 ? p.presentations[1] : null;
    p
      ..name = name.trim()
      ..category = category
      ..minStockMilli = minStockMilli
      ..presentations = [
        p.base.copyWith(
          retailCents: retailCents,
          barcode: code == null || code.isEmpty ? null : code,
        ),
        if (boxUnits != null && boxCents != null && !p.byWeight)
          box == null || box.factorMilli != boxUnits * 1000
              ? DemoPresentation(
                  name: 'Caja x$boxUnits',
                  factorMilli: boxUnits * 1000,
                  retailCents: boxCents,
                  barcode: box?.barcode,
                )
              : box.copyWith(retailCents: boxCents),
        ...p.presentations.skip(2),
      ];
    notifyListeners();
    return null;
  }

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
