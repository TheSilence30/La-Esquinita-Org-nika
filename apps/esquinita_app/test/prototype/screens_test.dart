import 'package:esquinita_app/devices/scanner/camera_scan_view.dart';
import 'package:esquinita_app/main.dart';
import 'package:esquinita_app/prototype/demo_store.dart';
import 'package:esquinita_app/prototype/widgets/keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final _today = DateTime(2026, 11, 17, 15);

Future<DemoStore> pumpApp(WidgetTester tester, Size size) async {
  debugDisableCameraScan = true;
  addTearDown(() => debugDisableCameraScan = false);
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final store = DemoStore(clock: () => _today);
  await tester.pumpWidget(EsquinitaApp(store: store));
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
    await tester.tap(
      find.descendant(of: find.byType(NumberPad), matching: find.text(d)),
    );
    await tester.pump();
  }
}

void main() {
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
        await pad(tester, '500');
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
        await pad(tester, '1000');
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
      }
      await go(tester, '/vender');
      await searchAndTap(tester, 'miel', 'Miel de abeja Oxapampa 1 kg');
      expect(
        store.cart.single.lots.first.lot.code,
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
