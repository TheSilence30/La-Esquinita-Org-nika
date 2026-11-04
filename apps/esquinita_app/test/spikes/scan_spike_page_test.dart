import 'package:esquinita_app/app/form_factor.dart';
import 'package:esquinita_app/app/theme.dart';
import 'package:esquinita_app/spikes/scan_spike_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Logical (dp) sizes the spike must fit without overflow.
const sizes = {
  'phone portrait 360×740': Size(360, 740),
  'phone landscape 740×360': Size(740, 360),
  'Tab A11 portrait ~600×1005': Size(600, 1005),
  'Tab A11 landscape ~1005×600': Size(1005, 600),
  'PC 1366×768': Size(1366, 768),
  'PC small window 800×600': Size(800, 600),
};

Future<void> pumpAt(WidgetTester tester, Size size) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(),
      home: const ScanSpikePage(cameraSupported: false),
    ),
  );
}

void main() {
  for (final MapEntry(key: name, value: size) in sizes.entries) {
    testWidgets('lays out without overflow: $name', (tester) async {
      await pumpAt(tester, size);
      expect(tester.takeException(), isNull);
      // Side-by-side when wider than tall, stacked otherwise.
      final camera = tester.getRect(
        find.textContaining('Cámara no disponible'),
      );
      final stats = tester.getRect(find.text('Lecturas'));
      if (size.width > size.height) {
        expect(stats.left, greaterThan(camera.right));
      } else {
        expect(stats.top, greaterThan(camera.bottom));
      }
      // Short screens scroll the panel instead of overflowing.
      await tester.scrollUntilVisible(
        find.text('× cantidad'),
        100,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('manual reads honor × cantidad and reset it', (tester) async {
    await pumpAt(tester, const Size(1005, 600));
    await tester.tap(find.text('×3'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, 'Código manual / lector USB'),
      '7750000000011',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('× 3'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Código manual / lector USB'),
      '7750000000011',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('× 4'), findsOneWidget);
    // Let the flash timer finish.
    await tester.pump(const Duration(seconds: 1));
  });

  test('form factor resolution', () {
    expect(
      FormFactor.resolve(TargetPlatform.android, const Size(360, 740)),
      FormFactor.phone,
    );
    expect(
      FormFactor.resolve(TargetPlatform.android, const Size(560, 933)),
      FormFactor.tablet,
    );
    expect(
      FormFactor.resolve(TargetPlatform.windows, const Size(360, 740)),
      FormFactor.desktop,
    );
  });
}
