import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:esquinita_app/app/providers.dart';
import 'package:esquinita_app/data/local/database.dart';
import 'package:esquinita_app/devices/scanner/camera_scan_view.dart';
import 'package:esquinita_app/main.dart';
import 'package:esquinita_app/prototype/demo_store.dart';
import 'package:esquinita_app/prototype/pos/pos_page.dart';
import 'package:esquinita_app/prototype/widgets/keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final _today = DateTime(2026, 11, 17, 15);

/// The in-memory local database of the last [pumpApp].
late AppDatabase _db;

Future<DemoStore> pumpApp(WidgetTester tester, Size size) async {
  debugDisableCameraScan = true;
  addTearDown(() => debugDisableCameraScan = false);
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final store = DemoStore(clock: () => _today);
  // Synchronous streams: the fake clock drives everything.
  final db = _db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: EsquinitaApp(store: store),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Future<void> go(WidgetTester tester, String path) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
  await tester.pumpAndSettle();
}

Future<void> searchAndTap(
  WidgetTester tester,
  String query,
  String name,
) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Buscar producto o código'),
    query,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).first);
  await tester.pumpAndSettle();
}

Future<void> pad(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    final key = find.descendant(
      of: find.byType(NumberPad),
      matching: find.text(d),
    );
    await tester.ensureVisible(key);
    await tester.tap(key);
    await tester.pump();
  }
}

void main() {
  testWidgets('leaving the app warns about operations not sent yet', (
    tester,
  ) async {
    await pumpApp(tester, const Size(533, 893));
    for (final id in ['op-1', 'op-2']) {
      await _db
          .into(_db.outbox)
          .insert(
            OutboxCompanion.insert(
              opId: id,
              deviceId: 'd',
              userId: 'u',
              createdAt: DateTime.utc(2026, 11, 20),
              type: 'Test',
              payload: '{}',
            ),
          );
    }
    await tester.binding.handlePopRoute(); // Android back on the home screen
    await tester.pumpAndSettle();
    expect(find.text('¿Salir de la app?'), findsOneWidget);
    expect(
      find.text('Quedan 2 operaciones sin enviar al servidor.'),
      findsOneWidget,
    );
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
  });

  for (final size in const [Size(533, 893), Size(893, 533)]) {
    testWidgets('Atrás $size: Más page → Más → home → asks to exit', (
      tester,
    ) async {
      await pumpApp(tester, size);
      String where() =>
          GoRouter.of(tester.element(find.byType(Scaffold).first))
              .state
              .uri
              .path;
      await go(tester, '/caja');
      await tester.binding.handlePopRoute(); // Android back key
      await tester.pumpAndSettle();
      expect(where(), '/mas');
      await tester.tap(find.byTooltip('Atrás')); // on-screen button
      await tester.pumpAndSettle();
      expect(where(), '/dashboard');
      expect(find.byTooltip('Atrás'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('¿Salir de la app?'), findsOneWidget);
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      expect(find.text('¿Salir de la app?'), findsNothing);
      expect(where(), '/dashboard');
      expect(tester.takeException(), isNull);
    });
  }

  // Phone: designed for one hand at 360 dp (not a shrunk tablet).
  for (final size in const [Size(360, 640), Size(360, 800)]) {
    group('phone $size', () {
      testWidgets('every screen lays out without overflow', (tester) async {
        await pumpApp(tester, size);
        for (final path in [
          '/dashboard',
          '/vender',
          '/escanear',
          '/inventario',
          '/caja',
          '/mas',
          '/demo',
        ]) {
          await go(tester, path);
          expect(tester.takeException(), isNull, reason: path);
        }
      });

      testWidgets('weight calculator (amount → weight) and cash checkout', (
        tester,
      ) async {
        final store = await pumpApp(tester, size);
        await go(tester, '/vender');
        await searchAndTap(tester, 'kion', 'Kion fresco (por kg)');
        expect(find.text('Peso → precio'), findsOneWidget);
        await tester.tap(find.text('Monto → peso'));
        await tester.pump();
        await pad(tester, '5'); // S/ 5.00: whole soles first
        expect(find.textContaining('Pesar 417 g'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.textContaining('Agregar 417 g'));
        await tester.pumpAndSettle();
        expect(store.cart.single.qtyMilli, 417);

        await tester.tap(find.text('Cobrar S/ 5.00'));
        await tester.pumpAndSettle();
        expect(find.text('Total a cobrar'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('S/ 10.00'));
        await tester.pump();
        expect(find.byKey(const Key('change')), findsOneWidget);
        expect(find.text('S/ 5.00').evaluate().length, greaterThan(0));
        await tester.tap(find.text('Confirmar venta'));
        await tester.pumpAndSettle();
        expect(find.text('Venta registrada'), findsOneWidget);
        expect(
          find.textContaining('no es'),
          findsWidgets,
        ); // internal-document legend
        expect(tester.takeException(), isNull);
        expect(store.sales.last.changeCents, 500);
      });

      testWidgets('weight calculator: 300 g at a price per kg typed in', (
        tester,
      ) async {
        final store = await pumpApp(tester, size);
        await go(tester, '/vender');
        await searchAndTap(tester, 'kion', 'Kion fresco (por kg)');
        await tester.tap(find.text('300 g'));
        await tester.pump();
        expect(find.text('Precio: S/ 3.60'), findsOneWidget); // list S/ 12.00
        await tester.tap(find.byKey(const Key('calc-price')));
        await tester.pump();
        for (var i = 0; i < 4; i++) {
          await tester.tap(find.byIcon(Icons.backspace_outlined));
          await tester.pump();
        }
        await pad(tester, '10');
        expect(find.text('S/ 10.00'), findsOneWidget);
        expect(find.text('Precio: S/ 3.00'), findsOneWidget);
        expect(find.textContaining('Usar precio de lista'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.textContaining('Agregar 300 g'));
        await tester.pumpAndSettle();
        final line = store.cart.single;
        expect(line.qtyMilli, 300);
        expect(line.priceOverrideCents, 1000);
        expect(line.totalCents, 300);
      });

      testWidgets('weight calculator in kg: 1.5 → 1.500 kg', (tester) async {
        final store = await pumpApp(tester, size);
        await go(tester, '/vender');
        await searchAndTap(tester, 'kion', 'Kion fresco (por kg)');
        await tester.tap(find.text('kg').first);
        await tester.pump();
        await pad(tester, '1.5');
        expect(find.text('1.500 kg'), findsOneWidget);
        expect(find.text('Precio: S/ 18.00'), findsOneWidget); // S/ 12.00 / kg
        expect(tester.takeException(), isNull);
        await tester.tap(find.textContaining('Agregar 1.500 kg'));
        await tester.pumpAndSettle();
        expect(store.cart.single.qtyMilli, 1500);
      });

      testWidgets('credit sale needs a registered customer, no payment', (
        tester,
      ) async {
        final store = await pumpApp(tester, size);
        final cashBefore = store.expectedCashCents;
        await go(tester, '/vender');
        await searchAndTap(tester, 'panela', 'Panela granulada 1 kg');
        await tester.tap(find.textContaining('Cobrar S/'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Venta a crédito'));
        await tester.pump();
        expect(find.byKey(const Key('problem')), findsOneWidget);
        await tester.tap(find.text('Elegir cliente registrado'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Rosa Huamán Quispe'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('problem')), findsNothing);
        await tester.tap(find.text('Registrar venta a crédito'));
        await tester.pumpAndSettle();
        expect(store.sales.last.credit, isTrue);
        expect(store.sales.last.payments, isEmpty);
        expect(store.expectedCashCents, cashBefore);
      });

      testWidgets('register a new product by code; a known code shows it', (
        tester,
      ) async {
        final store = await pumpApp(tester, size);
        await go(tester, '/escanear');
        await tester.enterText(
          find.widgetWithText(TextField, 'Código de barras'),
          '7750543400036',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.text('Ya registrado'), findsOneWidget);
        await tester.tap(find.text('Escanear otro'));
        await tester.pumpAndSettle();

        await tester.tap(find.textContaining('Producto sin código'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Código interno generado: 291'),
          findsOneWidget,
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Nombre'),
          'Mermelada de aguaymanto',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Precio por unidad (S/)'),
          '12.90',
        );
        await tester.scrollUntilVisible(
          find.text('Guardar producto'),
          300,
          scrollable: find
              .byType(Scrollable)
              .first, // the page list, not a TextField
        );
        await tester.tap(find.text('Guardar producto'));
        await tester.pumpAndSettle();
        expect(store.catalog.last.name, 'Mermelada de aguaymanto');
        expect(store.catalog.last.base.retailCents, 1290);
        expect(tester.takeException(), isNull);
      });

      testWidgets('cash close warns about unsent sales on the PC', (
        tester,
      ) async {
        await pumpApp(tester, size);
        await go(tester, '/caja');
        expect(find.textContaining('2 ventas sin enviar'), findsWidgets);
        await tester.scrollUntilVisible(
          find.text('Cerrar de todos modos'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Cerrar de todos modos'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }

  // Remove one line, swipe another away, then empty the sale (confirmed).
  for (final size in const [Size(360, 640), Size(893, 533)]) {
    testWidgets('cart $size: delete a line, swipe one, empty the sale', (
      tester,
    ) async {
      final store = await pumpApp(tester, size);
      await go(tester, '/vender');
      for (final (q, name) in const [
        ('panela', 'Panela granulada 1 kg'),
        ('chía', 'Semillas de chía 500 g'),
        ('avena', 'Avena integral 900 g'),
      ]) {
        await searchAndTap(tester, q, name);
      }
      expect(store.cart, hasLength(3));
      if (size.width < 840) {
        await tester.tap(find.text('3 ítems'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip('Eliminar producto').first);
      await tester.pumpAndSettle();
      expect(store.cart, hasLength(2));

      await tester.drag(
        find.text('Semillas de chía 500 g').last,
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();
      expect(store.cart, hasLength(1));

      await tester.tap(find.text('Vaciar venta'));
      await tester.pumpAndSettle();
      expect(find.text('¿Vaciar la venta?'), findsOneWidget);
      await tester.tap(find.text('Vaciar'));
      await tester.pumpAndSettle();
      expect(store.cart, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  // SM-A576B sideways: 891 × 411 dp. No green bar; sync status still shown.
  testWidgets('landscape phone: no top bar, sync visible, cash typed 30.5', (
    tester,
  ) async {
    final store = await pumpApp(tester, const Size(891, 411));
    for (final path in ['/vender', '/escanear', '/inventario', '/caja']) {
      await go(tester, path);
      expect(tester.takeException(), isNull, reason: path);
      expect(find.byType(AppBar), findsNothing, reason: path);
      expect(find.text('Sincronizado'), findsOneWidget, reason: path);
    }
    await go(tester, '/vender');
    await searchAndTap(tester, 'panela', 'Panela granulada 1 kg');
    await tester.tap(find.textContaining('Cobrar S/'));
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);
    expect(tester.takeException(), isNull); // keypad used to overflow 47 px
    expect(find.text('Volver'), findsOneWidget);
    await pad(tester, '30.5');
    expect(store.cart, isNotEmpty);
    expect(
      find.descendant(
        of: find.byKey(const Key('tendered')),
        matching: find.text('S/ 30.50'),
      ),
      findsOneWidget,
    );
  });

  for (final size in const [Size(360, 640), Size(893, 533)]) {
    testWidgets('inventory $size: take stock to zero, then add it back', (
      tester,
    ) async {
      final store = await pumpApp(tester, size);
      final cafe = store.catalog.firstWhere((p) => p.id == 'cafe'); // 18
      await go(tester, '/inventario');
      await tester.scrollUntilVisible(
        find.text('Café orgánico Villa Rica 250 g'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Café orgánico Villa Rica 250 g'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Café orgánico Villa Rica 250 g'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Salida'));
      await tester.tap(find.text('Salida'));
      await tester.pump();
      await pad(tester, '18');
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Restar 18 und de sin lote'));
      await tester.tap(find.text('Restar 18 und de sin lote'));
      await tester.pump();
      expect(cafe.totalStockMilli, 0);
      expect(find.textContaining('Stock local 0 und'), findsOneWidget);
      expect(store.movementsOf(cafe).single.reason, 'Merma / vencido');
      await tester.pump(const Duration(seconds: 4)); // the notice goes away
      await tester.ensureVisible(find.text('Entrada'));
      await tester.tap(find.text('Entrada'));
      await tester.pump();
      await pad(tester, '5');
      await tester.ensureVisible(find.text('Sumar 5 und en sin lote'));
      await tester.tap(find.text('Sumar 5 und en sin lote'));
      await tester.pump();
      expect(cafe.totalStockMilli, 5000);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in const [Size(360, 640), Size(893, 533)]) {
    testWidgets('inventory $size: long press edits; assign lot to no-lot', (
      tester,
    ) async {
      final store = await pumpApp(tester, size);
      final cafe = store.catalog.firstWhere((p) => p.id == 'cafe'); // 18
      await go(tester, '/inventario');
      final name = find.text('Café orgánico Villa Rica 250 g');
      await tester.scrollUntilVisible(
        name,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(name);
      await tester.pumpAndSettle();
      await tester.longPress(name);
      await tester.pumpAndSettle();
      expect(find.text('Editar producto'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre'),
        'Café Villa Rica',
      );
      await tester.scrollUntilVisible(
        find.text('Guardar cambios'),
        200,
        scrollable: find
            .ancestor(
              of: find.widgetWithText(TextField, 'Nombre'),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(cafe.name, 'Café Villa Rica');
      expect(find.text('Editar producto'), findsNothing);
      expect(tester.takeException(), isNull);
      // Assign 10 of the 18 without lot to a new lot.
      await tester.pump(const Duration(seconds: 4)); // the notice goes away
      await tester.pumpAndSettle();
      final renamed = find.text('Café Villa Rica');
      await tester.scrollUntilVisible(
        renamed,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(renamed);
      await tester.pumpAndSettle();
      await tester.tap(renamed);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Asignar lote'));
      await tester.tap(find.text('Asignar lote'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.backspace_outlined).last);
      await tester.tap(find.byIcon(Icons.backspace_outlined).last);
      for (final d in ['1', '0']) {
        await tester.tap(
          find
              .descendant(
                of: find.byType(NumberPad).last,
                matching: find.text(d),
              )
              .first,
        );
        await tester.pump();
      }
      expect(find.text('10 und'), findsOneWidget);
      await tester.tap(find.text('Siguiente: datos del lote'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Código de lote'),
        'LOT34',
      );
      await tester.tap(find.text('Fecha de vencimiento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Guardar lote'));
      await tester.tap(find.text('Guardar lote'));
      await tester.pumpAndSettle();
      expect(cafe.lots.single.qtyMilli, 10000);
      expect(cafe.stockMilli, 8000);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in const [Size(360, 640), Size(893, 533)]) {
    testWidgets('inventory $size: retire an expired lot', (tester) async {
      final store = await pumpApp(tester, size);
      final miel = store.catalog.firstWhere((p) => p.id == 'miel');
      await go(tester, '/inventario');
      final name = find.text(miel.name);
      await tester.scrollUntilVisible(
        name,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(name);
      await tester.pumpAndSettle();
      await tester.tap(name);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Dar de baja L-2403'));
      await tester.pumpAndSettle();
      expect(find.text('¿Dar de baja el lote L-2403?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Dar de baja'));
      await tester.pumpAndSettle();
      expect(miel.lots.map((l) => l.code), isNot(contains('L-2403')));
      expect(find.byTooltip('Dar de baja L-2403'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Vender: long press a product opens its stock sheet', (
    tester,
  ) async {
    await pumpApp(tester, const Size(533, 893));
    await go(tester, '/vender');
    final name = find.text('Café orgánico Villa Rica 250 g');
    await tester.scrollUntilVisible(
      name,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.longPress(name);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('adjust-stock')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(360, 640), Size(533, 893)]) {
    testWidgets('scan a known product $size → new lot; asks about no-lot', (
      tester,
    ) async {
      final store = await pumpApp(tester, size);
      final cafe = store.catalog.firstWhere((p) => p.id == 'cafe'); // 18
      await go(tester, '/escanear');
      await tester.enterText(
        find.widgetWithText(TextField, 'Código de barras'),
        '7752345600018',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Ya registrado'), findsOneWidget);
      await tester.ensureVisible(find.text('Agregar lote nuevo'));
      await tester.tap(find.text('Agregar lote nuevo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar lote'));
      await tester.pump();
      expect(find.byKey(const Key('lot-error')), findsOneWidget); // no code
      await tester.enterText(
        find.widgetWithText(TextField, 'Código de lote'),
        'LOT36',
      );
      await tester.tap(find.text('Fecha de vencimiento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACEPTAR')); // Spanish date picker
      await tester.pumpAndSettle();
      expect(find.textContaining('Vence '), findsOneWidget);
      await pad(tester, '3');
      await tester.ensureVisible(find.text('Guardar lote'));
      await tester.tap(find.text('Guardar lote'));
      await tester.pumpAndSettle();
      expect(find.text('Stock sin lote'), findsOneWidget); // 18 und without lot
      await tester.tap(find.text('Pasar al lote'));
      await tester.pumpAndSettle();
      final lot = cafe.lots.single;
      expect((lot.code, lot.qtyMilli, cafe.stockMilli), ('LOT36', 21000, 0));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Trabajo: can receive a lot, cannot adjust stock', (
    tester,
  ) async {
    final store = await pumpApp(tester, const Size(533, 893));
    store.update(() => store.role = DemoRole.staff);
    await go(tester, '/inventario');
    await tester.tap(find.text('Quinua blanca orgánica 1 kg'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notice-warn')), findsOneWidget);
    expect(find.text('Entrada'), findsNothing); // no adjust sheet
    await tester.tap(find.text('Agregar lote'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Código de lote'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('register form keeps what was typed when rotating', (
    tester,
  ) async {
    await pumpApp(tester, const Size(533, 893));
    await go(tester, '/escanear');
    await tester.enterText(
      find.widgetWithText(TextField, 'Código de barras'),
      '7799999999999',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre'),
      'Mermelada de aguaymanto',
    );
    for (final size in const [Size(893, 533), Size(533, 893)]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(find.text('Mermelada de aguaymanto'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  // Sales scanner: camera + live cart, traffic-light notices on top of it.
  for (final size in const [
    Size(360, 640),
    Size(891, 411),
    Size(533, 893),
    Size(893, 533),
  ]) {
    testWidgets('sales scanner $size: notices visible, Registrar', (
      tester,
    ) async {
      final store = await pumpApp(tester, size);
      await go(tester, '/escanear-venta');
      expect(tester.takeException(), isNull);
      Future<void> scan(String code) async {
        final state = tester.state<SaleScannerPageState>(
          find.byType(SaleScannerPage),
        );
        await state.handleSaleScan(state.context, code);
        await tester.pump();
      }

      // Through the camera path: confirmed on the 2nd frame (ScanFilter).
      final scanner = tester.state<SaleScannerPageState>(
        find.byType(SaleScannerPage),
      );
      for (final ms in const [0, 100]) {
        await scanner.onCameraCodes([
          '7750543400036',
        ], Duration(milliseconds: ms));
      }
      await tester.pump();
      expect(find.byKey(const Key('notice-ok')), findsOneWidget);
      expect(find.text('Quinua blanca orgánica 1 kg ×1'), findsOneWidget);
      expect(find.text('Venta · 1 ítems'), findsOneWidget); // live cart
      // Almendras, 0 in stock: asks first; "Sí" adds it in amber.
      final asked = scanner.handleSaleScan(scanner.context, '7750123400016');
      await tester.pump();
      expect(find.text('Sin stock'), findsOneWidget);
      await tester.tap(find.text('Sí, agregar'));
      await tester.pumpAndSettle();
      await asked;
      await tester.pump();
      expect(find.byKey(const Key('notice-warn')), findsOneWidget);
      await scan('999');
      expect(find.byKey(const Key('notice-error')), findsOneWidget);
      expect(find.text('Código 999 no registrado'), findsOneWidget);
      expect(store.cart, hasLength(2));
      expect(tester.takeException(), isNull);
      // Red stays until acted on; Registrar opens the form with the code.
      await tester.pump(const Duration(seconds: 10));
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('notice-error')), findsNothing);
      expect(find.byType(SaleScannerPage), findsNothing);
      expect(find.textContaining('999'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  // Tab A11 at 240 dpi: 533 × 893 dp (portrait) and 893 × 533 (landscape).
  for (final size in const [Size(533, 893), Size(893, 533)]) {
    testWidgets('tablet $size: screens fit; FEFO lot shown in the cart', (
      tester,
    ) async {
      final store = await pumpApp(tester, size);
      for (final path in [
        '/dashboard',
        '/vender',
        '/escanear',
        '/inventario',
        '/caja',
      ]) {
        await go(tester, path);
        expect(tester.takeException(), isNull, reason: path);
        // Landscape: no green bar; cash and sync still visible.
        expect(
          find.byType(AppBar),
          size.width > size.height ? findsNothing : findsOneWidget,
          reason: path,
        );
        expect(find.text('Sincronizado'), findsWidgets, reason: path);
      }
      await go(tester, '/vender');
      await searchAndTap(tester, 'miel', 'Miel de abeja Oxapampa 1 kg');
      expect(
        store.cart.single.lots.first.lot?.code,
        'L-2410',
      ); // not the expired L-2403
      if (size.width < 840) {
        await tester.tap(find.text('1 ítems'));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('L-2410'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in const [Size(1280, 800), Size(1024, 700)]) {
    testWidgets('PC $size: search + Enter, F12 checkout, Enter confirms', (
      tester,
    ) async {
      final store = await pumpApp(tester, size);
      expect(find.text('Ventas de hoy'), findsOneWidget); // Administrador home
      await go(tester, '/vender');
      await tester.enterText(
        find.byType(TextField).first,
        '7752345600018',
      ); // café, via reader
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(store.cart.single.product.id, 'cafe');
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await tester.pumpAndSettle();
      expect(find.text('Total a cobrar'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Venta registrada'), findsOneWidget);
      expect(store.cart, isEmpty);
      await tester.tap(find.text('Nueva venta'));
      await tester.pumpAndSettle();
      for (final path in [
        '/dashboard',
        '/caja',
        '/inventario',
        '/escanear',
        '/demo',
      ]) {
        await go(tester, path);
        expect(tester.takeException(), isNull, reason: path);
      }
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  }

  testWidgets('Trabajo role: no Dashboard in the menu, home is Vender', (
    tester,
  ) async {
    final store = await pumpApp(tester, const Size(1280, 800));
    store.update(() => store.role = DemoRole.staff);
    await go(tester, '/dashboard'); // redirected
    expect(find.text('Ventas de hoy'), findsNothing);
    expect(find.text('Dashboard'), findsNothing);
    expect(find.text('Reportes'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
