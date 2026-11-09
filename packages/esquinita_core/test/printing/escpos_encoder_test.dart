import 'dart:typed_data';

import 'package:esquinita_core/esquinita_core.dart';
import 'package:test/test.dart';

/// Index of [needle] inside [bytes], or -1.
int indexOf(List<int> bytes, List<int> needle) {
  for (var i = 0; i + needle.length <= bytes.length; i++) {
    var match = true;
    for (var j = 0; j < needle.length; j++) {
      if (bytes[i + j] != needle[j]) {
        match = false;
        break;
      }
    }
    if (match) return i;
  }
  return -1;
}

void main() {
  group('code pages', () {
    const spanish = 'Ñandú: ¿Café? ¡Sí! ÁÉÍÓÚ áéíóú ñ ü';

    test('PC850 has every Spanish letter, uppercase accents included', () {
      expect(CodePage.pc850.supports(spanish), isTrue);
      expect(CodePage.pc850.encode('ÁÉÍÓÚ'), [0xB5, 0x90, 0xD6, 0xE0, 0xE9]);
      expect(CodePage.pc850.encode('áéíóúñÑ¿¡'), [
        0xA0, 0x82, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA8, 0xAD, //
      ]);
    });

    test('PC437 (Éterma default) lacks Á Í Ó Ú and falls back to A I O U', () {
      expect(CodePage.pc437.supports(spanish), isFalse);
      expect(
        CodePage.pc437.encode('ÁÉÍÓÚ'),
        'A'.codeUnits + [0x90] + 'IOU'.codeUnits,
      );
      expect(CodePage.pc437.encode('ñ'), [0xA4]);
    });

    test('WPC1252 is Latin-1 for Spanish, plus the euro', () {
      expect(CodePage.wpc1252.supports(spanish), isTrue);
      expect(CodePage.wpc1252.encode('ñÑ€'), [0xF1, 0xD1, 0x80]);
    });

    test('ASCII passes through; unknown characters become ?', () {
      expect(CodePage.pc858.encode('S/ 12.50'), 'S/ 12.50'.codeUnits);
      expect(CodePage.pc858.encode('€'), [0xD5]);
      expect(CodePage.pc850.encode('–'), '-'.codeUnits);
      expect(CodePage.pc850.encode('漢'), [0x3F]);
    });

    test('ESC t ids follow the Epson numbering', () {
      expect([for (final c in CodePage.values) c.escPosId], [0, 2, 19, 16]);
    });
  });

  group('wrapping and rows (32 columns)', () {
    const enc = EscPosEncoder();

    test('wraps at word boundaries and cuts words longer than a line', () {
      expect(EscPosEncoder.wrap('Av. Famesa Mz. C Lt. 3 Paradero Famesa', 20), [
        'Av. Famesa Mz. C Lt.',
        '3 Paradero Famesa',
      ]);
      expect(EscPosEncoder.wrap('x' * 45, 20), ['x' * 20, 'x' * 20, 'x' * 5]);
      expect(EscPosEncoder.wrap('', 32), ['']);
      expect(EscPosEncoder.wrap('a\nb', 32), ['a', 'b']);
    });

    test('a row puts the amount flush right on exactly 32 columns', () {
      final lines = enc.row('2 x Café orgánico', 'S/ 25.00');
      expect(lines, ['${'2 x Café orgánico'.padRight(24)}S/ 25.00']);
      expect(lines.single.length, 32);
    });

    test('a long label wraps and keeps the amount on its last line', () {
      final lines = enc.row(
        'Miel de abeja multifloral de Oxapampa 1 kg',
        'S/ 38.90',
      );
      expect(lines.length, 2);
      expect(lines.last, endsWith('S/ 38.90'));
      expect(lines.every((l) => l.length <= 32), isTrue);
    });

    test('when they cannot share a line, the amount gets its own line', () {
      final lines = enc.row('x' * 30, 'S/ 1,234.50');
      expect(lines, ['x' * 30, 'S/ 1,234.50'.padLeft(32)]);
    });
  });

  group('ESC/POS bytes', () {
    test('starts with reset and the code page', () {
      final bytes = const EscPosEncoder(codePage: CodePage.pc850)
          .encode(const PrintDocument([]));
      expect(bytes, [0x1B, 0x40, 0x1B, 0x74, 2]);
    });

    test('text sets alignment, bold and size, then resets them', () {
      final bytes = const EscPosEncoder().encode(
        const PrintDocument([
          PrintText('Ñ', align: PrintAlign.center, bold: true, large: true),
        ]),
      );
      expect(bytes.sublist(5), [
        0x1B, 0x61, 1, 0x1B, 0x45, 1, 0x1D, 0x21, 0x11, // center, bold, 2x
        0xA5, 0x0A, // Ñ in PC850 + LF
        0x1B, 0x45, 0, 0x1D, 0x21, 0, 0x1B, 0x61, 0, // reset
      ]);
    });

    test('large text wraps at 16 columns', () {
      final bytes = const EscPosEncoder().encode(
        PrintDocument([PrintText('a' * 20, large: true)]),
      );
      expect(bytes.where((b) => b == 0x0A).length, 2);
    });

    test('divider spans the paper and feed uses ESC d', () {
      final bytes = const EscPosEncoder().encode(
        const PrintDocument([PrintDivider('='), PrintFeed(4)]),
      );
      expect(indexOf(bytes, [...('=' * 32).codeUnits, 0x0A]), 5);
      expect(bytes.sublist(bytes.length - 3), [0x1B, 0x64, 4]);
    });

    test('images are centered and sent in GS v 0 bands', () {
      // 8×100, all black: 2 bands (64 + 36 rows), 48 bytes per row.
      final bitmap = MonoBitmap(
        8,
        100,
        Uint8List(100)..fillRange(0, 100, 0xFF),
      );
      final bytes = const EscPosEncoder().encode(
        PrintDocument([PrintImage(bitmap)]),
      );
      final first = indexOf(bytes, [0x1D, 0x76, 0x30, 0, 48, 0, 64, 0]);
      expect(first, 5);
      final row = bytes.sublist(first + 8, first + 8 + 48);
      // 384 dots wide, 8-dot image → starts at dot 188 (byte 23, bit 4).
      expect(row[23], 0x0F);
      expect(row[24], 0xF0);
      expect(row.where((b) => b != 0).length, 2);
      expect(
        indexOf(bytes, [0x1D, 0x76, 0x30, 0, 48, 0, 36, 0]),
        greaterThan(first),
      );
      expect(bytes.length, 5 + 2 * 8 + 48 * 100);
    });

    test('images wider than the paper are rejected', () {
      final wide = MonoBitmap(400, 1, Uint8List(50));
      expect(
        () => const EscPosEncoder().encode(PrintDocument([PrintImage(wide)])),
        throwsArgumentError,
      );
    });
  });

  group('MonoBitmap', () {
    test('threshold: dark pixels become dots, packed MSB first', () {
      final lum = Uint8List.fromList([0, 255, 0, 255, 0, 255, 0, 255, 0, 0]);
      final bmp = MonoBitmap.fromLuminance(10, 1, lum, dither: false);
      expect(bmp.bits, [0xAA, 0xC0]);
      expect(bmp.isBlack(0, 0), isTrue);
      expect(bmp.isBlack(1, 0), isFalse);
    });

    test('dithering a flat 50% gray gives about half the dots', () {
      const w = 64, h = 64;
      final bmp = MonoBitmap.fromLuminance(
        w,
        h,
        Uint8List(w * h)..fillRange(0, w * h, 128),
      );
      var black = 0;
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          if (bmp.isBlack(x, y)) black++;
        }
      }
      expect(black / (w * h), closeTo(0.5, 0.05));
    });

    test('pure white and pure black stay pure when dithered', () {
      final white = MonoBitmap.fromLuminance(
        9,
        3,
        Uint8List(27)..fillRange(0, 27, 255),
      );
      expect(white.bits.every((b) => b == 0), isTrue);
      final black = MonoBitmap.fromLuminance(8, 2, Uint8List(16));
      expect(black.bits, [0xFF, 0xFF]);
    });

    test('rejects mismatched sizes', () {
      expect(() => MonoBitmap(8, 2, Uint8List(1)), throwsArgumentError);
      expect(
        () => MonoBitmap.fromLuminance(2, 2, Uint8List(3)),
        throwsArgumentError,
      );
    });
  });
}
