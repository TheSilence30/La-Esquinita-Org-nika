import 'dart:typed_data';

/// 1-bit image for thermal printers: rows of packed bits, most significant
/// bit first, 1 = black dot. Same layout as ESC/POS `GS v 0`.
final class MonoBitmap {
  MonoBitmap(this.width, this.height, this.bits) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Empty bitmap: ${width}x$height');
    }
    if (bits.length != bytesPerRow * height) {
      throw ArgumentError(
        'Expected ${bytesPerRow * height} bytes, got ${bits.length}',
      );
    }
  }

  /// Converts 8-bit luminance (0 = black, 255 = white, row-major) to dots.
  ///
  /// With [dither], Floyd–Steinberg spreads the rounding error to neighbours
  /// so photos keep their shading; without it, a plain [threshold] gives
  /// crisp text and flat logos.
  factory MonoBitmap.fromLuminance(
    int width,
    int height,
    Uint8List luminance, {
    bool dither = true,
    int threshold = 128,
  }) {
    if (luminance.length != width * height) {
      throw ArgumentError(
        'Expected ${width * height} luminance values, got ${luminance.length}',
      );
    }
    final bytesPerRow = (width + 7) >> 3;
    final bits = Uint8List(bytesPerRow * height);
    // Error buffer in 1/16ths so the diffusion stays in integers.
    final level = Int32List.fromList([for (final v in luminance) v * 16]);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        final old = level[i];
        final black = old < threshold * 16;
        if (black) bits[y * bytesPerRow + (x >> 3)] |= 0x80 >> (x & 7);
        if (!dither) continue;
        final err = old - (black ? 0 : 255 * 16);
        if (x + 1 < width) level[i + 1] += err * 7 ~/ 16;
        if (y + 1 < height) {
          if (x > 0) level[i + width - 1] += err * 3 ~/ 16;
          level[i + width] += err * 5 ~/ 16;
          if (x + 1 < width) level[i + width + 1] += err ~/ 16;
        }
      }
    }
    return MonoBitmap(width, height, bits);
  }

  final int width;
  final int height;
  final Uint8List bits;

  int get bytesPerRow => (width + 7) >> 3;

  bool isBlack(int x, int y) =>
      bits[y * bytesPerRow + (x >> 3)] & (0x80 >> (x & 7)) != 0;
}
