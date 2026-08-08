import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  static TextStyle get displayLarge => GoogleFonts.vazirmatn(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle get headlineLg => GoogleFonts.vazirmatn(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 40 / 32,
  );

  static TextStyle get headlineMd => GoogleFonts.vazirmatn(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 32 / 24,
  );

  static TextStyle get bodyLg => GoogleFonts.vazirmatn(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 24 / 16,
  );

  static TextStyle get bodyMd => GoogleFonts.vazirmatn(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 20 / 14,
  );

  static TextStyle get labelMd => GoogleFonts.vazirmatn(
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
