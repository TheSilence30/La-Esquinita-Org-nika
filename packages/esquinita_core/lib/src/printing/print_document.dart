import 'mono_bitmap.dart';

/// Device-neutral document (CLAUDE.md §8). Renderers turn it into ESC/POS,
/// PDF, etc. Only what tickets need so far.
final class PrintDocument {
  const PrintDocument(this.blocks);

  final List<PrintBlock> blocks;
}

enum PrintAlign { left, center, right }

sealed class PrintBlock {
  const PrintBlock();
}

/// Text that wraps at word boundaries to the paper width.
final class PrintText extends PrintBlock {
  const PrintText(
    this.text, {
    this.align = PrintAlign.left,
    this.bold = false,
    this.large = false,
  });

  final String text;
  final PrintAlign align;
  final bool bold;

  /// Double width and height: half as many columns.
  final bool large;
}

/// Label on the left, value flush right (item lines, totals).
final class PrintRow extends PrintBlock {
  const PrintRow(this.left, this.right, {this.bold = false});

  final String left;
  final String right;
  final bool bold;
}

/// A full-width line of [char].
final class PrintDivider extends PrintBlock {
  const PrintDivider([this.char = '-']);

  final String char;
}

/// 1-bit image, centered.
final class PrintImage extends PrintBlock {
  const PrintImage(this.bitmap);

  final MonoBitmap bitmap;
}

/// Blank lines (e.g. room to tear the paper off).
final class PrintFeed extends PrintBlock {
  const PrintFeed(this.lines);

  final int lines;
}
