// Prototype only (Fase 0): in-memory sample data. No drift, no sync.
// Real models come from docs/modelo-datos.md in Fase 1–2.

/// A lot of a lot-tracked product.
class DemoLot {
  DemoLot(this.code, this.expiresOn, this.qtyMilli);

  final String code;
  DateTime expiresOn;
  int qtyMilli;

  bool isExpired(DateTime today) => expiresOn.isBefore(_day(today));

  bool expiresWithin(DateTime today, int days) =>
      !isExpired(today) &&
      !expiresOn.isAfter(_day(today).add(Duration(days: days)));
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

class DemoPresentation {
  const DemoPresentation({
    required this.name,
    required this.factorMilli,
    required this.retailCents,
    this.wholesaleCents,
    this.wholesaleMinMilli,
    this.barcode,
  });

  final String name;

  /// Base units × 1000 (docs/modelo-datos.md §3.1).
  final int factorMilli;
  final int retailCents;
  final int? wholesaleCents;
  final int? wholesaleMinMilli;
  final String? barcode;
}

class DemoProduct {
  DemoProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.presentations,
    required this.avgCostCents,
    this.byWeight = false,
    this.lots = const [],
    this.stockMilli = 0,
    this.minStockMilli = 0,
  });

  final String id;
  final String name;
  final String category;

  /// First one is the base presentation.
  final List<DemoPresentation> presentations;

  /// Average cost per base unit (hidden from the Trabajo role).
  final int avgCostCents;

  /// Sold by kg: quantities are grams, prices are per kg.
  final bool byWeight;
  final List<DemoLot> lots;

  /// Stock in base units × 1000 when the product has no lots.
  int stockMilli;
  final int minStockMilli;

  bool get tracksLots => lots.isNotEmpty;
  DemoPresentation get base => presentations.first;

  int get totalStockMilli =>
      tracksLots ? lots.fold(0, (s, l) => s + l.qtyMilli) : stockMilli;

  /// Sellable stock: expired lots are blocked (docs/modelo-datos.md §3.2).
  int sellableStockMilli(DateTime today) => tracksLots
      ? lots.where((l) => !l.isExpired(today)).fold(0, (s, l) => s + l.qtyMilli)
      : stockMilli;
}

class DemoCustomer {
  const DemoCustomer(this.id, this.name, this.doc);

  final String id;
  final String name;
  final String doc;
}

const categories = [
  'Granos y cereales',
  'Endulzantes',
  'Bebidas',
  'Superalimentos',
  'Frescos',
  'Cuidado personal',
];

List<DemoProduct> sampleCatalog(DateTime today) {
  DateTime inDays(int d) => _day(today).add(Duration(days: d));
  int units(int n) => n * 1000;
  return [
    DemoProduct(
      id: 'quinua',
      name: 'Quinua blanca orgánica 1 kg',
      category: 'Granos y cereales',
      avgCostCents: 980,
      stockMilli: units(46),
      minStockMilli: units(12),
      presentations: [
        DemoPresentation(
          name: 'Unidad',
          factorMilli: 1000,
          retailCents: 1450,
          wholesaleCents: 1300,
          wholesaleMinMilli: units(6),
          barcode: '7750543400036',
        ),
        DemoPresentation(
          name: 'Caja x12',
          factorMilli: 12000,
          retailCents: 15600,
          barcode: '7750543401200',
        ),
      ],
    ),
    DemoProduct(
      id: 'kion',
      name: 'Kion fresco (por kg)',
      category: 'Frescos',
      avgCostCents: 700,
      byWeight: true,
      stockMilli: 8400, // 8.4 kg
      minStockMilli: 2000,
      presentations: const [
        DemoPresentation(name: 'kg', factorMilli: 1000, retailCents: 1200),
      ],
    ),
    DemoProduct(
      id: 'quinua-granel',
      name: 'Quinua roja a granel (por kg)',
      category: 'Granos y cereales',
      avgCostCents: 900,
      byWeight: true,
      stockMilli: 15250,
      minStockMilli: 5000,
      presentations: const [
        DemoPresentation(name: 'kg', factorMilli: 1000, retailCents: 1350),
      ],
    ),
    DemoProduct(
      id: 'miel',
      name: 'Miel de abeja Oxapampa 1 kg',
      category: 'Endulzantes',
      avgCostCents: 2400,
      minStockMilli: units(6),
      lots: [
        DemoLot('L-2403', inDays(-12), units(2)), // expired: blocked
        DemoLot('L-2410', inDays(18), units(3)), // expiring soon: FEFO first
        DemoLot('L-2502', inDays(240), units(10)),
      ],
      presentations: const [
        DemoPresentation(
          name: 'Unidad',
          factorMilli: 1000,
          retailCents: 3890,
          barcode: '7751234500017',
        ),
      ],
    ),
    DemoProduct(
      id: 'cafe',
      name: 'Café orgánico Villa Rica 250 g',
      category: 'Bebidas',
      avgCostCents: 1700,
      stockMilli: units(18),
      minStockMilli: units(6),
      presentations: const [
        DemoPresentation(
          name: 'Unidad',
          factorMilli: 1000,
          retailCents: 2590,
          wholesaleCents: 2350,
          wholesaleMinMilli: 6000,
          barcode: '7752345600018',
        ),
      ],
    ),
    _simple(
      'chia',
      'Semillas de chía 500 g',
      'Superalimentos',
      1290,
      760,
      22,
      6,
      '7753456700019',
    ),
    _simple(
      'cacao',
      'Cacao en polvo 100% 250 g',
      'Superalimentos',
      1890,
      1150,
      9,
      6,
      '7754567800010',
    ),
    _simple(
      'maca',
      'Maca negra gelatinizada 500 g',
      'Superalimentos',
      3290,
      2100,
      4,
      5,
      '7755678900011',
    ),
    _simple(
      'panela',
      'Panela granulada 1 kg',
      'Endulzantes',
      990,
      610,
      30,
      10,
      '7756789000012',
    ),
    _simple(
      'avena',
      'Avena integral 900 g',
      'Granos y cereales',
      890,
      540,
      25,
      8,
      '7757890100013',
    ),
    _simple(
      'granola',
      'Granola con kiwicha 400 g',
      'Granos y cereales',
      1590,
      980,
      14,
      6,
      '7758901200014',
    ),
    _simple(
      'coco',
      'Aceite de coco extra virgen 500 ml',
      'Superalimentos',
      2990,
      1850,
      7,
      4,
      '7759012300015',
    ),
    _simple(
      'almendras',
      'Leche de almendras 1 L',
      'Bebidas',
      1490,
      920,
      0,
      6,
      '7750123400016',
    ),
    _simple(
      'kombucha',
      'Kombucha de maracuyá 500 ml',
      'Bebidas',
      1100,
      650,
      16,
      8,
      '7751357900017',
    ),
    _simple(
      'muna',
      'Té de muña 25 bolsitas',
      'Bebidas',
      700,
      380,
      20,
      6,
      '7752468000018',
    ),
    _simple(
      'sabila',
      'Jabón de sábila artesanal',
      'Cuidado personal',
      490,
      250,
      35,
      10,
      '7753579100019',
    ),
    DemoProduct(
      id: 'huevos',
      name: 'Huevos de corral',
      category: 'Frescos',
      avgCostCents: 75,
      stockMilli: units(150),
      minStockMilli: units(30),
      presentations: const [
        DemoPresentation(name: 'Unidad', factorMilli: 1000, retailCents: 100),
        DemoPresentation(
          name: 'Paquete x15',
          factorMilli: 15000,
          retailCents: 1400,
          barcode: '7754680200010',
        ),
      ],
    ),
  ];
}

DemoProduct _simple(
  String id,
  String name,
  String category,
  int priceCents,
  int costCents,
  int stockUnits,
  int minUnits,
  String barcode,
) => DemoProduct(
  id: id,
  name: name,
  category: category,
  avgCostCents: costCents,
  stockMilli: stockUnits * 1000,
  minStockMilli: minUnits * 1000,
  presentations: [
    DemoPresentation(
      name: 'Unidad',
      factorMilli: 1000,
      retailCents: priceCents,
      barcode: barcode,
    ),
  ],
);

const sampleCustomers = [
  DemoCustomer('c1', 'Rosa Huamán Quispe', 'DNI 45871236'),
  DemoCustomer('c2', 'Bodega Don Lucho', 'RUC 10458712361'),
  DemoCustomer('c3', 'Carmen Ríos Paredes', 'DNI 70125489'),
  DemoCustomer('c4', 'Restaurante Sabor Andino', 'RUC 20601234567'),
];
