import 'dart:typed_data';

import 'code_page.dart';
import 'mono_bitmap.dart';
import 'print_document.dart';

/// Renders a [PrintDocument] as ESC/POS bytes for a 58 mm printer
/// (384 dots, 32 columns with font A). Transport-agnostic: the caller sends
/// the bytes over Bluetooth or USB.
final class EscPosEncoder {
  const EscPosEncoder({
    this.codePage = CodePage.pc850,
    this.columns = 32,
    this.dotsWidth = 384,
    this.imageBandHeight = 64,
  });

  final CodePage codePage;
  final int columns;
  final int dotsWidth;

  /// Rows per `GS v 0` command: smaller bands keep cheap printers from
  /// overflowing their receive buffer on large images.
  final int imageBandHeight;

  static const _esc = 0x1B, _gs = 0x1D, _lf = 0x0A;

  Uint8List encode(PrintDocument document) {
    final out = BytesBuilder(copy: false)
      ..add([_esc, 0x40]) // ESC @: reset
      ..add([_esc, 0x74, codePage.escPosId]); // ESC t n: code page
    for (final block in document.blocks) {
      switch (block) {
        case PrintText(:final text, :final align, :final bold, :final large):
          out
            ..add([_esc, 0x61, align.index]) // ESC a: alignment
            ..add([_esc, 0x45, bold ? 1 : 0]) // ESC E: bold
            ..add([_gs, 0x21, large ? 0x11 : 0x00]); // GS !: size
          for (final line in wrap(text, large ? columns ~/ 2 : columns)) {
            _line(out, line);
          }
          out
            ..add([_esc, 0x45, 0])
            ..add([_gs, 0x21, 0])
            ..add([_esc, 0x61, 0]);
        case PrintRow(:final left, :final right, :final bold):
          if (bold) out.add([_esc, 0x45, 1]);
          for (final line in row(left, right)) {
            _line(out, line);
          }
          if (bold) out.add([_esc, 0x45, 0]);
        case PrintDivider(:final char):
          _line(out, char * columns);
        case PrintImage(:final bitmap):
          _image(out, bitmap);
        case PrintFeed(:final lines):
          if (lines > 0) out.add([_esc, 0x64, lines.clamp(1, 255)]);
      }
    }
    return out.takeBytes();
  }

  void _line(BytesBuilder out, String line) =>
      out.add([...codePage.encode(line), _lf]);

  /// Centers [bitmap] on the paper and sends it in bands.
  void _image(BytesBuilder out, MonoBitmap bitmap) {
    if (bitmap.width > dotsWidth) {
      throw ArgumentError(
        'Image is ${bitmap.width} dots wide; the paper fits $dotsWidth',
      );
    }
    final rowBytes = dotsWidth >> 3;
    final offset = (dotsWidth - bitmap.width) ~/ 2;
    for (var top = 0; top < bitmap.height; top += imageBandHeight) {
      final rows = (bitmap.height - top).clamp(1, imageBandHeight);
      final band = Uint8List(rowBytes * rows);
      for (var y = 0; y < rows; y++) {
        for (var x = 0; x < bitmap.width; x++) {
          if (bitmap.isBlack(x, top + y)) {
            final px = x + offset;
            band[y * rowBytes + (px >> 3)] |= 0x80 >> (px & 7);
          }
        }
      }
      // GS v 0 m xL xH yL yH: width in bytes, height in dots.
      out
        ..add([_gs, 0x76, 0x30, 0, rowBytes & 0xFF, rowBytes >> 8])
        ..add([rows & 0xFF, rows >> 8])
        ..add(band);
    }
  }

  /// Word-wraps [text] to [width] columns; words longer than a line are cut.
  /// One character = one column (true for the code pages we print).
  static List<String> wrap(String text, int width) {
    final lines = <String>[];
    for (final paragraph in text.split('\n')) {
      var current = '';
      for (var word in paragraph.split(' ')) {
        while (word.length > width) {
          if (current.isNotEmpty) {
            lines.add(current);
            current = '';
          }
          lines.add(word.substring(0, width));
          word = word.substring(width);
        }
        if (current.isEmpty) {
          current = word;
        } else if (current.length + 1 + word.length <= width) {
          current = '$current $word';
        } else {
          lines.add(current);
          current = word;
        }
      }
      lines.add(current);
    }
    return lines;
  }

  /// [left] wrapped, with [right] flush right on its last line (or on a line
  /// of its own when they do not fit together).
  List<String> row(String left, String right) {
    final lines = wrap(left, columns);
    final last = lines.removeLast();
    if (last.length + 1 + right.length <= columns) {
      lines.add(last.padRight(columns - right.length) + right);
    } else {
      lines
        ..add(last)
        ..add(right.padLeft(columns));
    }
    return lines;
  }
}
