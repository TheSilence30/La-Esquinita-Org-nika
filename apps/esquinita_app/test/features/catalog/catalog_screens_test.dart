import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:esquinita_app/app/providers.dart';
import 'package:esquinita_app/data/local/database.dart';
import 'package:esquinita_app/data/sync/outbox_store.dart';
import 'package:esquinita_app/data/sync/replica_store.dart';
import 'package:esquinita_app/devices/scanner/camera_scan_view.dart';
import 'package:esquinita_app/features/auth/application/auth_providers.dart';
import 'package:esquinita_app/features/auth/application/local_auth.dart';
import 'package:esquinita_app/main.dart';
import 'package:esquinita_app/prototype/demo_store.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _und = '019abb00-0000-7000-8000-000000000001';
const _kg = '019abb00-0000-7000-8000-000000000002';
const _cat = '019abb00-0000-7000-8000-000000000011';

const _tablet = Size(533, 893);
const _phone = Size(360, 640);
const _pc = Size(1280, 800);

late AppDatabase _db;

/// The app on [size] with the catalog masters and a logged-in user with
/// [permissions].
Future<void> pumpCatalog(
  WidgetTester tester,
  Size size, {
  Set<String> permissions = const {'catalog.create', 'catalog.view_cost'},
}) async {
  debugDisableCameraScan = true;
  addTearDown(() => debugDisableCameraScan = false);
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = _db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(db.close);
  final device = await OutboxStore(db).deviceId();
  Map<String, Object?> unit(String id, String code, String name, String k) => {
    'id': id,
    'code': code,
    'name': name,
    'kind': k,
    'active': true,
    'version': 1,
  };
  await ReplicaStore(db).apply({
    'cursor': 5,
    'changes': {
      'devices': [
        {
          'id': device,
          'name': 'Tablet',
          'platform': 'android',
          'series_prefix': 'T1',
          'barcode_digit': 1,
          'active': true,
          'version': 1,
        },
      ],
      'units': [
        unit(_und, 'und', 'Unidad', 'count'),
        unit(_kg, 'kg', 'Kilogramo', 'weight'),
      ],
      'categories': [
        {
          'id': _cat,
          'name': 'Orgánicos',
          'sort_order': 1,
          'active': true,
          'version': 1,
        },
      ],
    },
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: EsquinitaApp(store: DemoStore()),
    ),
  );
  ProviderScope.containerOf(tester.element(find.byType(EsquinitaApp)))
      .read(currentSessionProvider.notifier)
      .open(
        AppSession(
          userId: uuidV7(),
          username: 'ana',
          fullName: 'Ana',
          permissions: permissions,
          homeView: 'dashboard',
        ),
      );
  await tester.pumpAndSettle();
}

Future<void> go(WidgetTester tester, String path) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
  await tester.pumpAndSettle();
}

Future<void> typeCode(WidgetTester tester, String code) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Código de barras'),
    code,
  );
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester, String label, String text) async {
  final f = find.widgetWithText(TextField, label);
  await tester.ensureVisible(f);
  await tester.enterText(f, text);
  await tester.pump();
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) => tapText(tester, 'Guardar producto');

String? formError(WidgetTester tester) =>
    find.byKey(const Key('product-form-error')).evaluate().isEmpty
    ? null
    : tester.widget<Text>(find.byKey(const Key('product-form-error'))).data;

void main() {
  for (final size in const [_phone, _tablet]) {
    testWidgets('$size: a new code → form with a box presentation and '
        'initial stock → the sheet; the same code again opens it', (
      tester,
    ) async {
      await pumpCatalog(tester, size);
      await go(tester, '/escanear');
      await typeCode(tester, '7751234000016');
      expect(find.text('Código: 7751234000016'), findsOneWidget);
      await fill(tester, 'Nombre', 'Mermelada de aguaymanto');
      await fill(tester, 'Precio por unidad (S/)', '12,90');
      await tapText(tester, 'Agregar presentación (caja, paquete, bolsa…)');
      await fill(tester, 'Nombre (Caja, Bolsa 500 g…)', 'Caja');
      await fill(tester, 'Contiene (und)', '12');
      await fill(tester, 'Precio (S/)', '140');
      await fill(tester, 'Su código (opcional)', '7751234000023');
      await fill(tester, 'Stock inicial (und)', '24');
      await save(tester);
      expect(formError(tester), isNull);
      expect(find.text('Stock local: 24 und'), findsOneWidget);
      expect(find.text('S/ 12.90'), findsOneWidget);
      expect(find.text('S/ 140.00'), findsOneWidget);

      final cmd = (await OutboxStore(_db).pending()).single;
      expect(cmd.type, CreateProduct.type);
      final p = CreateProduct.fromPayload(cmd.payload);
      expect(p.internalCode, 'T1-000001');
      expect(
        [for (final x in p.presentations) (x.name, x.factorMilli)],
        [('Unidad', 1000), ('Caja', 12000)],
      );

      await tapText(tester, 'Escanear otro');
      await typeCode(tester, '7751234000023'); // the box's code
      expect(find.text('Mermelada de aguaymanto'), findsOneWidget);
      expect(find.text('Escanear otro'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('by weight: price per kg and a «Bolsa 500 g» of 0,5 kg', (
    tester,
  ) async {
    await pumpCatalog(tester, _tablet);
    await go(tester, '/escanear');
    await typeCode(tester, '7751234000030');
    await fill(tester, 'Nombre', 'Kion');
    await tester.ensureVisible(find.byKey(const Key('product-unit')));
    await tester.tap(find.byKey(const Key('product-unit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kilogramo (kg)').last);
    await tester.pumpAndSettle();
    await fill(tester, 'Precio por kilogramo (S/)', '8');
    await tapText(tester, 'Agregar presentación (caja, paquete, bolsa…)');
    await fill(tester, 'Nombre (Caja, Bolsa 500 g…)', 'Bolsa 500 g');
    await fill(tester, 'Contiene (kg)', '0,5');
    await fill(tester, 'Precio (S/)', '4.50');
    await fill(tester, 'Stock inicial (kg)', '2,750');
    await save(tester);
    expect(formError(tester), isNull);
    expect(find.text('Stock local: 2.750 kg'), findsOneWidget);
    final p = CreateProduct.fromPayload(
      (await OutboxStore(_db).pending()).single.payload,
    );
    expect(p.baseUnitId, _kg);
    expect(
      [
        for (final x in p.presentations)
          (x.name, x.factorMilli, x.retailPriceCents),
      ],
      [('Kilogramo', 1000, 800), ('Bolsa 500 g', 500, 450)],
    );
    expect(p.initialStock.single.qtyMilli, 2750);
  });

  testWidgets('without a code a 29… is generated; a product with lots needs '
      'its lot code', (tester) async {
    await pumpCatalog(tester, _tablet);
    await go(tester, '/escanear');
    await tapText(tester, 'Producto sin código: generar código interno');
    expect(find.textContaining('Código interno generado: 291'), findsOneWidget);
    await fill(tester, 'Nombre', 'Granola casera');
    await fill(tester, 'Precio por unidad (S/)', '15');
    await tapText(tester, 'Controla lotes y vencimientos');
    await fill(tester, 'Stock inicial (und)', '5');
    await save(tester);
    expect(formError(tester), contains('escribe el lote'));
    await fill(tester, 'Código de lote', 'L-01');
    await save(tester);
    expect(formError(tester), isNull);
    expect(find.text('L-01'), findsOneWidget);
    final p = CreateProduct.fromPayload(
      (await OutboxStore(_db).pending()).single.payload,
    );
    final code = p.presentations.single.barcodes.single;
    expect((code.code.startsWith('291'), code.generated), (true, true));
    expect(p.initialStock.single.lotCode, 'L-01');
  });

  testWidgets('a code another product has here is refused before saving, '
      'in Spanish', (tester) async {
    await pumpCatalog(tester, _tablet);
    await go(tester, '/escanear');
    await typeCode(tester, '7751234000016');
    await fill(tester, 'Nombre', 'Quinua');
    await fill(tester, 'Precio por unidad (S/)', '10');
    await save(tester);
    await tapText(tester, 'Escanear otro');

    await typeCode(tester, '7751234000030');
    await fill(tester, 'Nombre', 'Quinua roja');
    await fill(tester, 'Precio por unidad (S/)', '11');
    await tapText(tester, 'Agregar presentación (caja, paquete, bolsa…)');
    await fill(tester, 'Nombre (Caja, Bolsa 500 g…)', 'Caja');
    await fill(tester, 'Contiene (und)', '6');
    await fill(tester, 'Precio (S/)', '60');
    await fill(tester, 'Su código (opcional)', '7751234000016');
    await save(tester);
    expect(formError(tester), 'El código 7751234000016 ya es de «Quinua».');
    expect(await OutboxStore(_db).pending(), hasLength(1));

    await fill(tester, 'Su código (opcional)', '7751234000017'); // bad digit
    await save(tester);
    expect(formError(tester), startsWith('7751234000017:'));
    expect(await OutboxStore(_db).pending(), hasLength(1));
  });

  testWidgets('Trabajo registers without seeing or typing costs', (
    tester,
  ) async {
    await pumpCatalog(tester, _tablet, permissions: {'catalog.create'});
    await go(tester, '/escanear');
    await typeCode(tester, '7751234000016');
    expect(find.byKey(const Key('product-cost-field')), findsNothing);
    await fill(tester, 'Nombre', 'Quinua');
    await fill(tester, 'Precio por unidad (S/)', '10');
    await save(tester);
    expect(find.text('Quinua'), findsOneWidget);
    expect(find.byKey(const Key('product-cost')), findsNothing);
  });

  testWidgets('the form keeps what was typed when the tablet rotates', (
    tester,
  ) async {
    await pumpCatalog(tester, _tablet);
    await go(tester, '/escanear');
    await typeCode(tester, '7751234000016');
    await fill(tester, 'Nombre', 'Mermelada de aguaymanto');
    for (final size in const [Size(893, 533), _tablet]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(find.text('Mermelada de aguaymanto'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  Future<void> registerQuinua(WidgetTester tester) async {
    await go(tester, '/escanear');
    await typeCode(tester, '7751234000016');
    await fill(tester, 'Nombre', 'Quinua');
    await fill(tester, 'Precio por unidad (S/)', '10');
    await fill(tester, 'Stock inicial (und)', '3');
    await save(tester);
  }

  testWidgets('tablet: Más → Productos, search by code, open the sheet', (
    tester,
  ) async {
    await pumpCatalog(tester, _tablet);
    await registerQuinua(tester);
    await go(tester, '/mas');
    await tapText(tester, 'Productos');
    await tester.enterText(
      find.widgetWithText(TextField, 'Buscar por nombre o código'),
      '7751234000016',
    );
    await tester.pumpAndSettle();
    expect(find.text('local 3 und'), findsOneWidget);
    await tapText(tester, 'Quinua');
    expect(find.text('Stock local: 3 und'), findsOneWidget);
    expect(find.byKey(const Key('product-cost')), findsOneWidget);
    await tapText(tester, 'Productos'); // back to the list
    expect(find.text('local 3 und'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PC: table with the sheet beside it; F2 goes to the search', (
    tester,
  ) async {
    await pumpCatalog(tester, _pc);
    await registerQuinua(tester);
    await go(tester, '/productos');
    expect(find.text('Elige un producto.'), findsOneWidget);
    await tester.tap(find.text('T1-000001'));
    await tester.pumpAndSettle();
    expect(find.text('Stock local: 3 und'), findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();
    final search = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Buscar por nombre o código (F2)'),
    );
    expect(search.focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
