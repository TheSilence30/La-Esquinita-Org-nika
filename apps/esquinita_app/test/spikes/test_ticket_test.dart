import 'dart:typed_data';

import 'package:esquinita_app/devices/printer/raster.dart';
import 'package:esquinita_app/spikes/test_ticket.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lines of the ESC/POS output as text (code page bytes ≥ 0x80 kept).
List<List<int>> printedLines(Uint8List bytes) {
  final lines = <List<int>>[];
  var current = <int>[];
  for (var i = 0; i < bytes.length; i++) {
    final b = bytes[i];
    // Skip ESC/GS commands this encoder emits (3 bytes each, ESC @ is 2).
    if (b == 0x1B || b == 0x1D) {
      i += bytes[i + 1] == 0x40 ? 1 : 2;
      continue;
    }
    if (b == 0x0A) {
      lines.add(current);
      current = [];
    } else {
      current.add(b);
    }
  }
  return lines;
}

void main() {
  final now = DateTime(2026, 11, 9, 18, 5);

  test('the test ticket has exactly 40 lines, none wider than 32', () {
    final doc = buildTestTicket(now: now);
    expect(countTextLines(doc), 40);
    final lines = printedLines(const EscPosEncoder().encode(doc));
    expect(lines, hasLength(40));
    expect(lines.every((l) => l.length <= 32), isTrue);
  });

  test('it carries accents, ñ, S/, the legend and a numbered last line', () {
    final doc = buildTestTicket(now: now);
    final text = [
      for (final b in doc.blocks)
        switch (b) {
          PrintText(:final text) => text,
          PrintRow(:final left, :final right) => '$left $right',
          _ => '',
        },
    ].join('\n');
    for (final s in [
      'á',
      'é',
      'í',
      'ó',
      'ú',
      'Á',
      'Ú',
      'ñ',
      'Ñ',
      '¿',
      '¡',
      'S/ ',
    ]) {
      expect(text, contains(s), reason: s);
    }
    expect(text, contains('Constancia de venta – no es comprobante de pago'));
    expect(text, contains('Línea 40 de 40 – fin'));
    expect(text, contains('09/11/2026 18:05'));
    // 51.80 + 6.50 + 12.60 + 11.80 + 11.00 + 16.90 + 38.90 + 14.00 + 7.20 + 14.70
    expect(text, contains('TOTAL S/ 185.40'));
  });

  test('with PC850 every Spanish letter is sent as itself', () {
    final bytes = const EscPosEncoder(codePage: CodePage.pc850)
        .encode(buildTestTicket(now: now));
    expect(bytes, contains(0xB5)); // Á
    expect(bytes, contains(0xA4)); // ñ
  });

  test('the logo goes first, as a centered image', () {
    final logo = MonoBitmap(16, 2, Uint8List(4)..fillRange(0, 4, 0xFF));
    final doc = buildTestTicket(now: now, logo: logo);
    expect(doc.blocks.first, isA<PrintImage>());
    expect(countTextLines(doc), 40);
  });

  test('code-page sheet: one ESC t section per page', () {
    final bytes = buildCodePageSheet();
    for (final page in CodePage.values) {
      expect(
        String.fromCharCodes(bytes),
        contains(String.fromCharCodes([0x1B, 0x74, page.escPosId])),
      );
    }
  });

  test('luminance composites transparent pixels over white paper', () {
    final rgba = Uint8List.fromList([
      0, 0, 0, 255, // black
      255, 255, 255, 255, // white
      0, 0, 0, 0, // transparent → paper
      0, 0, 0, 128, // half-transparent black: 255 - 128
    ]);
    expect(luminanceFromRgba(rgba), [0, 255, 255, 127]);
  });

  testWidgets('the ticket renders as one 384-dot image', (tester) async {
    final bmp = (await tester.runAsync(
      () => renderDocumentImage(buildTestTicket(now: now)),
    ))!;
    expect(bmp.width, 384);
    expect(bmp.height, greaterThan(600)); // 40 lines of ~27 px
    var black = 0;
    for (final b in bmp.bits) {
      if (b != 0) black++;
    }
    expect(black, greaterThan(0));
  });
}
