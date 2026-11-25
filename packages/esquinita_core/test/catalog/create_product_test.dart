import 'package:esquinita_core/esquinita_core.dart';
import 'package:test/test.dart';

void main() {
  final cat = uuidV7();
  final und = uuidV7();

  CreateProduct quinua({
    bool lots = false,
    List<NewPresentation>? presentations,
    List<InitialStock>? stock,
  }) => CreateProduct(
    productId: uuidV7(),
    internalCode: 'T2-000001',
    name: 'Quinua orgánica 500 g',
    categoryId: cat,
    baseUnitId: und,
    tracksLots: lots,
    unitCostCents: 850,
    presentations:
        presentations ??
        [
          NewPresentation(
            id: uuidV7(),
            name: 'Unidad',
            factorMilli: 1000,
            isBase: true,
            retailPriceCents: 1200,
            barcodes: const [
              NewBarcode(code: '4006381333931', format: BarcodeFormat.ean13),
            ],
          ),
          NewPresentation(
            id: uuidV7(),
            name: 'Caja x12',
            factorMilli: 12000,
            isBase: false,
            retailPriceCents: 13200,
            wholesalePriceCents: 12600,
            wholesaleMinMilli: 2000,
          ),
        ],
    initialStock:
        stock ?? [InitialStock(movementId: uuidV7(), qtyMilli: 24000)],
  );

  test('a valid product survives the payload round trip', () {
    final p = quinua();
    expect(p.problems(), isEmpty);
    final back = CreateProduct.fromPayload(p.toPayload());
    expect(back.toPayload(), p.toPayload());
  });

  test('exactly one base presentation, equal to one base unit', () {
    final noBase = quinua(
      presentations: [
        NewPresentation(
          id: uuidV7(),
          name: 'Caja',
          factorMilli: 12000,
          isBase: false,
          retailPriceCents: 1,
        ),
      ],
    );
    expect(noBase.problems(), contains(contains('exactamente una')));
    final wrongBase = quinua(
      presentations: [
        NewPresentation(
          id: uuidV7(),
          name: 'Unidad',
          factorMilli: 500,
          isBase: true,
          retailPriceCents: 1,
        ),
      ],
    );
    expect(wrongBase.problems(), contains(contains('equivale a 1')));
  });

  test('presentations: names and codes not repeated, factor > 0, prices '
      'not negative, a valid code', () {
    NewPresentation pres(
      String name, {
      int factor = 2000,
      int price = 100,
      List<NewBarcode> codes = const [],
    }) => NewPresentation(
      id: uuidV7(),
      name: name,
      factorMilli: factor,
      isBase: false,
      retailPriceCents: price,
      barcodes: codes,
    );
    const code = NewBarcode(code: '96385074', format: BarcodeFormat.ean8);
    final p = quinua(
      presentations: [
        NewPresentation(
          id: uuidV7(),
          name: 'Unidad',
          factorMilli: 1000,
          isBase: true,
          retailPriceCents: 1200,
          barcodes: const [code],
        ),
        pres('Pack', codes: const [code]),
        pres('PACK'),
        pres('Cero', factor: 0),
        pres('Gratis', price: -1),
        pres(
          'Dañado',
          codes: const [
            NewBarcode(code: '4006381333932', format: BarcodeFormat.ean13),
          ],
        ),
      ],
    );
    final problems = p.problems().join('\n');
    expect(problems, contains('El código 96385074 está repetido'));
    expect(problems, contains('«PACK» está repetida'));
    expect(problems, contains('«Cero» necesita'));
    expect(problems, contains('Precio de «Gratis»'));
    expect(problems, contains('Dígito verificador incorrecto (EAN-13)'));
  });

  test('initial stock > 0; with lots, a lot code; without lots, no lot', () {
    expect(
      quinua(stock: [InitialStock(movementId: uuidV7(), qtyMilli: 0)])
          .problems(),
      contains(contains('mayor que 0')),
    );
    expect(
      quinua(
        lots: true,
        stock: [InitialStock(movementId: uuidV7(), qtyMilli: 1000)],
      ).problems(),
      contains(contains('escribe el lote')),
    );
    final lot = InitialStock(
      movementId: uuidV7(),
      qtyMilli: 1000,
      lotId: uuidV7(),
      lotCode: 'L2026-10',
      expiresOn: '2027-05-30',
    );
    expect(quinua(lots: true, stock: [lot]).problems(), isEmpty);
    expect(
      quinua(stock: [lot]).problems(),
      contains('Este producto no controla lotes.'),
    );
    expect(
      quinua(
        lots: true,
        stock: [
          lot,
          InitialStock(
            movementId: uuidV7(),
            qtyMilli: 1000,
            lotId: uuidV7(),
            lotCode: 'L2026-10',
            expiresOn: '2027-05-30',
          ),
        ],
      ).problems(),
      contains(contains('repetido')),
    );
    // A product registered without stock is fine.
    expect(quinua(stock: []).problems(), isEmpty);
  });

  test('a malformed payload is a FormatException', () {
    final ok = quinua().toPayload();
    for (final bad in [
      {...ok, 'name': 5},
      {...ok, 'presentations': 'x'},
      {...ok, 'tracks_lots': null},
      {...ok, 'name': ''},
    ]) {
      expect(() => CreateProduct.fromPayload(bad), throwsFormatException);
    }
  });
}
