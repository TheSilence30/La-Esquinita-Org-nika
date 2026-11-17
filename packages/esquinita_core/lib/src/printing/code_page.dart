/// ESC/POS character tables that matter for Spanish (Peru). [escPosId] is the
/// `n` of `ESC t n` in the Epson numbering; cheap firmwares mostly follow it,
/// which is what the Spike 3 code-page test sheet checks on the Éterma
/// (default: PC437).
enum CodePage {
  pc437(0, _pc437),
  pc850(2, _pc850),
  pc858(19, _pc858),
  wpc1252(16, _wpc1252);

  const CodePage(this.escPosId, this._table);

  final int escPosId;
  final Map<String, int> _table;

  /// Bytes for [text]. ASCII passes through; a character missing from this
  /// page falls back to its unaccented letter (`Á` → `A` on PC437) or `?`.
  List<int> encode(String text) {
    final out = <int>[];
    for (final rune in text.runes) {
      if (rune < 0x80) {
        out.add(rune);
        continue;
      }
      final char = String.fromCharCode(rune);
      out.add(_table[char] ?? _fallback[char]?.codeUnitAt(0) ?? 0x3F);
    }
    return out;
  }

  /// Whether every character of [text] prints as itself on this page.
  bool supports(String text) => text.runes.every(
    (r) => r < 0x80 || _table.containsKey(String.fromCharCode(r)),
  );
}

// Shared by PC437 and PC850 (same positions for these characters).
const _dosCommon = {
  'Ç': 0x80, 'ü': 0x81, 'é': 0x82, 'â': 0x83, 'ä': 0x84, 'à': 0x85, //
  'ç': 0x87, 'ê': 0x88, 'è': 0x8A, 'ï': 0x8B, 'î': 0x8C, 'É': 0x90,
  'ô': 0x93, 'ö': 0x94, 'û': 0x96, 'ù': 0x97, 'Ü': 0x9A,
  'á': 0xA0, 'í': 0xA1, 'ó': 0xA2, 'ú': 0xA3, 'ñ': 0xA4, 'Ñ': 0xA5,
  'ª': 0xA6, 'º': 0xA7, '¿': 0xA8, '¡': 0xAD,
};

const _pc437 = {..._dosCommon, '°': 0xF8};

const _pc850 = {
  ..._dosCommon,
  'Á': 0xB5, 'Í': 0xD6, 'Ó': 0xE0, 'Ú': 0xE9, '°': 0xF8, //
};

// PC850 with the euro sign in place of the dotless i.
const _pc858 = {..._pc850, '€': 0xD5};

const _wpc1252 = {
  '€': 0x80, '¡': 0xA1, 'ª': 0xAA, '°': 0xB0, 'º': 0xBA, '¿': 0xBF, //
  'Á': 0xC1, 'Ç': 0xC7, 'É': 0xC9, 'Í': 0xCD, 'Ñ': 0xD1, 'Ó': 0xD3,
  'Ú': 0xDA, 'Ü': 0xDC, 'à': 0xE0, 'á': 0xE1, 'â': 0xE2, 'ä': 0xE4,
  'ç': 0xE7, 'è': 0xE8, 'é': 0xE9, 'ê': 0xEA, 'í': 0xED, 'ï': 0xEF,
  'ñ': 0xF1, 'ó': 0xF3, 'ô': 0xF4, 'ö': 0xF6, 'ú': 0xFA, 'ü': 0xFC,
};

const _fallback = {
  'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ü': 'U', 'Ñ': 'N', //
  'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
  '¿': '?', '¡': '!', '°': 'o', 'º': 'o', 'ª': 'a', '€': 'E',
  '–': '-', '—': '-', '‘': "'", '’': "'", '“': '"', '”': '"', '…': '.',
  '·': '.', '×': 'x',
};
