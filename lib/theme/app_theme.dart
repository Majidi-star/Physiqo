import 'package:flutter/material.dart';

/// Physiqo Design System — Single source of truth for all visual tokens.
/// Extracted from DESIGN.md and Google Stitch reference screens.
///
/// Rules:
///   • No glow, bloom, blur, neon, or soft shadow — ever.
///   • Orange is accent-only — never a large background fill.
///   • Error red is for negative/decline values only.
///   • All layout is RTL (Persian/Farsi).
class AppTheme {
  AppTheme._();

  static const List<Map<String, dynamic>> muscleCategories = [
    {'label': 'muscle_chest', 'svg': 'assets/icons/muscles/chest.svg'},
    {'label': 'muscle_back', 'svg': 'assets/icons/muscles/back.svg'},
    {'label': 'muscle_legs', 'svg': 'assets/icons/muscles/legs.svg'},
    {'label': 'muscle_abs', 'svg': 'assets/icons/muscles/abs.svg'},
    {'label': 'muscle_arms', 'svg': 'assets/icons/muscles/arms.svg'},
    {'label': 'muscle_shoulders', 'svg': 'assets/icons/muscles/shoulders.svg'},
  ];

  // ─── Colors ────────────────────────────────────────────────────────
  static const Color background      = Color(0xFF1C1C1E);
  static const Color surface         = Color(0xFF2A2A2C);
  static const Color surfaceHigh     = Color(0xFF3A3A3C);
  static const Color textPrimary     = Color(0xFFFFFFFF);
  static const Color textSecondary   = Color(0xFF8E8E93);
  static const Color primary         = Color(0xFFFF6B2C);
  static const Color onPrimary       = Color(0xFFFFFFFF);
  static const Color outline         = Color(0xFF3A3A3C);
  static const Color error           = Color(0xFFFF3B30);

  // ─── Background Gradient ───────────────────────────────────────────
  /// Subtle radial gradient — lighter near center, darker toward edges.
  /// Strictly grayscale, no color tint.
  static const RadialGradient backgroundGradient = RadialGradient(
    center: Alignment.center,
    radius: 1.2,
    colors: [
      Color(0xFF2A2A2C), // lighter center
      Color(0xFF1C1C1E), // darker edges
    ],
  );

  // ─── Spacing ───────────────────────────────────────────────────────
  static const double spacingXs     = 4;
  static const double spacingSm     = 8;
  static const double spacingMd     = 16;
  static const double spacingLg     = 24;
  static const double spacingXl     = 32;
  static const double gutter        = 16;

  // ─── Border Radius ─────────────────────────────────────────────────
  static const double radiusSm      = 8;
  static const double radiusMd      = 12;  // Card standard
  static const double radiusLg      = 16;
  static const double radiusXl      = 20;
  static const double radiusFull    = 9999;

  // ─── Card Decoration ──────────────────────────────────────────────
  static BoxDecoration cardDecoration({bool active = false}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radiusMd),
      border: Border.all(
        color: active ? primary : outline,
        width: 1,
      ),
    );
  }

  // ─── Typography (Vazirmatn for Farsi support) ─────────────────────
  static TextStyle get displayLarge => const TextStyle(
    fontFamily: 'Vazirmatn',
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle get headlineLg => const TextStyle(
    fontFamily: 'Vazirmatn',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 40 / 32,
  );

  static TextStyle get headlineMd => const TextStyle(
    fontFamily: 'Vazirmatn',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 32 / 24,
  );

  static TextStyle get bodyLg => const TextStyle(
    fontFamily: 'Vazirmatn',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 24 / 16,
  );

  static TextStyle get bodyMd => const TextStyle(
    fontFamily: 'Vazirmatn',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 20 / 14,
  );

  static TextStyle get labelMd => const TextStyle(
    fontFamily: 'Vazirmatn',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 16 / 12,
  );

  // ─── ThemeData ────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: onPrimary,
        surface: surface,
        onSurface: textPrimary,
        error: error,
      ),
      // Remove all ink splash / highlight for flat look
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: headlineMd,
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      // Bottom navigation — transparent, no elevation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }
}
