import 'package:flutter/material.dart';

/// Brand palette (CLAUDE.md §10).
abstract final class EsquinitaColors {
  static const forest = Color(0xFF1F4D2E);
  static const leaf = Color(0xFF7CB342);
  static const cream = Color(0xFFFAF6EC);
  static const wood = Color(0xFF8B5A2B);
  static const amber = Color(0xFFD99A1E);
  static const red = Color(0xFFC0392B);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: EsquinitaColors.forest,
    primary: EsquinitaColors.forest,
    secondary: EsquinitaColors.leaf,
    tertiary: EsquinitaColors.wood,
    error: EsquinitaColors.red,
    surface: EsquinitaColors.cream,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: EsquinitaColors.cream,
    // Touch targets ≥ 48 dp everywhere, also on desktop.
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    appBarTheme: const AppBarTheme(
      backgroundColor: EsquinitaColors.forest,
      foregroundColor: Colors.white,
    ),
  );
}
