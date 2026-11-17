import 'dart:typed_data';

import 'package:esquinita_core/esquinita_core.dart';

/// Spike 3 test ticket: logo, accents, ñ, "S/", and exactly [totalLines]
/// text lines on 32 columns (filler lines are numbered so a cut-off ticket
/// shows where it stopped).
PrintDocument buildTestTicket({
  required DateTime now,
  MonoBitmap? logo,
  int totalLines = 40,
}) {
  const items = [
    ('Café orgánico Villa Rica 250 g', 2, 2590),
    ('Piña golden', 1, 650),
    ('Azúcar rubia 1 kg', 3, 420),
    ('Cañihua 500 g', 1, 1180),
    ('Maní con miel', 2, 550),
    ('Quinua roja 1 kg', 1, 1690),
    ('Miel de abeja de Oxapampa 1 kg', 1, 3890),
    ('Té de muña', 4, 350),
    ('Ñuña tostada 200 g', 1, 720),
    ('Jabón de sábila', 3, 490),
  ];
  var total = Money.zero;
  final lines = <PrintBlock>[];
  for (final (name, qty, cents) in items) {
    final amount = Money(cents * qty);
    total += amount;
    lines.add(PrintRow('$qty x $name', amount.format()));
  }

  String two(int n) => n.toString().padLeft(2, '0');
  final date =
      '${two(now.day)}/${two(now.month)}/${now.year} '
      '${two(now.hour)}:${two(now.minute)}';

  final blocks = <PrintBlock>[
    if (logo != null) PrintImage(logo),
    const PrintText(
      'La Esquinita Orgánika',
      align: PrintAlign.center,
      bold: true,
    ),
    const PrintText(
      'Av. Famesa Mz. C Lt. 3, Paradero Famesa, Puente Piedra – Lima',
      align: PrintAlign.center,
    ),
    const PrintText(
      'Constancia de venta – no es comprobante de pago',
      align: PrintAlign.center,
      bold: true,
    ),
    const PrintDivider(),
    PrintRow('Ticket T1-000123', date),
    const PrintText('Cliente: Público en general'),
    const PrintText('Atendió: María Ñahui'),
    const PrintDivider(),
    ...lines,
    const PrintDivider(),
    PrintRow('TOTAL', total.format(), bold: true),
    PrintRow('Pago: Yape', total.format()),
    const PrintDivider(),
    const PrintText('Prueba: áéíóú ÁÉÍÓÚ ñÑ üÜ ¿? ¡! °'),
    const PrintText(
      '¡Gracias por su compra! ¿Algún problema? Escríbenos.',
      align: PrintAlign.center,
    ),
  ];

  final used = countTextLines(PrintDocument(blocks));
  for (var n = used + 1; n <= totalLines; n++) {
    blocks.add(
      PrintText(n == totalLines ? 'Línea $n de $totalLines – fin' : 'Línea $n'),
    );
  }
  return PrintDocument(blocks);
}

/// Text lines [document] takes on paper with [encoder] (images excluded).
int countTextLines(
  PrintDocument document, [
  EscPosEncoder encoder = const EscPosEncoder(),
]) {
  var n = 0;
  for (final block in document.blocks) {
    n += switch (block) {
      PrintText(:final text, :final large) => EscPosEncoder.wrap(
        text,
        large ? encoder.columns ~/ 2 : encoder.columns,
      ).length,
      PrintRow(:final left, :final right) => encoder.row(left, right).length,
      PrintDivider() => 1,
      PrintImage() || PrintFeed() => 0,
    };
  }
  return n;
}

/// One section per code page: `ESC t n` and then the same Spanish sample
/// encoded for that page. The section that prints every letter correctly is
/// the page the Éterma supports.
Uint8List buildCodePageSheet() {
  const sample = 'áéíóú ÁÉÍÓÚ ñÑ üÜ ¿? ¡! ° Ñandú cañihua piña S/ 1,234.50';
  final out = BytesBuilder(copy: false);
  for (final page in CodePage.values) {
    out.add(
      EscPosEncoder(codePage: page).encode(
        PrintDocument([
          PrintText('ESC t ${page.escPosId} = ${page.name}', bold: true),
          const PrintText(sample),
          const PrintDivider(),
        ]),
      ),
    );
  }
  out.add(
    const EscPosEncoder().encode(
      const PrintDocument([
        PrintText('Fin de la prueba de páginas de códigos'),
        PrintFeed(4),
      ]),
    ),
  );
  return out.takeBytes();
}
