import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/painting.dart';

/// Decodes a PNG/JPEG scaled to [width] dots and converts it to 1 bit.
/// Flat black-and-white art (the logo) prints best with a threshold; photos
/// need [dither].
Future<MonoBitmap> decodeMonoBitmap(
  Uint8List encoded, {
  required int width,
  bool dither = false,
  int threshold = 128,
}) async {
  final codec = await ui.instantiateImageCodec(encoded, targetWidth: width);
  final image = (await codec.getNextFrame()).image;
  try {
    return await _toMono(image, dither: dither, threshold: threshold);
  } finally {
    image.dispose();
    codec.dispose();
  }
}

/// 8-bit luminance from RGBA bytes, composited over white paper.
Uint8List luminanceFromRgba(Uint8List rgba) {
  final out = Uint8List(rgba.length ~/ 4);
  for (var i = 0, p = 0; i < out.length; i++, p += 4) {
    // Rec. 601 weights ×1000, integer math.
    final l = (299 * rgba[p] + 587 * rgba[p + 1] + 114 * rgba[p + 2]) ~/ 1000;
    final a = rgba[p + 3];
    out[i] = 255 - (a * (255 - l)) ~/ 255;
  }
  return out;
}

Future<MonoBitmap> _toMono(
  ui.Image image, {
  required bool dither,
  required int threshold,
}) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return MonoBitmap.fromLuminance(
    image.width,
    image.height,
    luminanceFromRgba(data!.buffer.asUint8List()),
    dither: dither,
    threshold: threshold,
  );
}

/// Draws [document] as one tall image, the way apps like Aqp Print do: any
/// character prints (no code page involved) at the cost of more bytes.
Future<MonoBitmap> renderDocumentImage(
  PrintDocument document, {
  int width = 384,
  double fontSize = 22,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final black = Paint()..color = const Color(0xFF000000);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), 100000),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  var y = 0.0;
  final lineHeight = fontSize * 1.25;

  TextPainter paint(String text, {bool bold = false, bool large = false}) =>
      TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: const Color(0xFF000000),
            fontSize: large ? fontSize * 1.8 : fontSize,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            height: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

  for (final block in document.blocks) {
    switch (block) {
      case PrintText(:final text, :final align, :final bold, :final large):
        final tp = paint(text, bold: bold, large: large)
          ..textAlign = switch (align) {
            PrintAlign.left => TextAlign.left,
            PrintAlign.center => TextAlign.center,
            PrintAlign.right => TextAlign.right,
          }
          ..layout(minWidth: width.toDouble(), maxWidth: width.toDouble());
        tp.paint(canvas, Offset(0, y));
        y += tp.height;
        tp.dispose();
      case PrintRow(:final left, :final right, :final bold):
        final r = paint(right, bold: bold)..layout();
        final l = paint(left, bold: bold)
          ..layout(maxWidth: width - r.width - fontSize / 2);
        l.paint(canvas, Offset(0, y));
        r.paint(canvas, Offset(width - r.width, y + l.height - r.height));
        y += l.height;
        l.dispose();
        r.dispose();
      case PrintDivider():
        y += lineHeight / 2;
        canvas.drawRect(Rect.fromLTWH(0, y - 1, width.toDouble(), 2), black);
        y += lineHeight / 2;
      case PrintImage(:final bitmap):
        final left = ((width - bitmap.width) / 2).floorToDouble();
        for (var row = 0; row < bitmap.height; row++) {
          // Merge runs of dots into one rectangle each.
          var x = 0;
          while (x < bitmap.width) {
            if (!bitmap.isBlack(x, row)) {
              x++;
              continue;
            }
            final start = x;
            while (x < bitmap.width && bitmap.isBlack(x, row)) {
              x++;
            }
            canvas.drawRect(
              Rect.fromLTWH(left + start, y + row, (x - start).toDouble(), 1),
              black,
            );
          }
        }
        y += bitmap.height;
      case PrintFeed(:final lines):
        y += lineHeight * lines;
    }
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, y.ceil().clamp(1, 100000));
  picture.dispose();
  try {
    return await _toMono(image, dither: false, threshold: 160);
  } finally {
    image.dispose();
  }
}
