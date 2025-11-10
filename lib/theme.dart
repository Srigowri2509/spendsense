import 'package:flutter/material.dart';

/// Lavender–teal palette (top-left swatch vibe)
class AppTheme {
  // Brand colors
  static const Color lilac     = Color(0xFFC9A8E3);
  static const Color mauve     = Color(0xFF8B7AAE);
  static const Color aqua      = Color(0xFF66C6CA);
  static const Color teal      = Color(0xFF0B9790);
  static const Color deepTeal  = Color(0xFF055B5C);

  // Build light/dark color schemes from a seed, then override surfaces.
  static ColorScheme _lightScheme() =>
      ColorScheme.fromSeed(seedColor: teal, brightness: Brightness.light)
          .copyWith(
            primary: teal,
            secondary: mauve,
            tertiary: aqua,
            surface: const Color(0xFFF6F4FA),
            background: const Color(0xFFF6F4FA),
          );

  static ColorScheme _darkScheme() =>
      ColorScheme.fromSeed(seedColor: deepTeal, brightness: Brightness.dark)
          .copyWith(
            primary: aqua,
            secondary: lilac,
            tertiary: teal,
            surface: const Color(0xFF1E2225),
            background: const Color(0xFFf0e7ce),
          );

  static ThemeData light() => _base(_lightScheme());
  static ThemeData dark()  => _base(_darkScheme());

  static ThemeData _base(ColorScheme cs) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.background,

      appBarTheme: AppBarTheme(
        backgroundColor: cs.background,
        foregroundColor: cs.onBackground,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: const CardThemeData(
  // color: inherit from theme.cardColor (keeps scheme-consistent)
  elevation: 0,
  margin: EdgeInsets.symmetric(vertical: 6),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  ),
),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.primary.withOpacity(.35)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Use a broadly compatible surface for fill (avoids newer M3 fields)
        fillColor: cs.surfaceVariant.withOpacity(cs.brightness == Brightness.light ? .6 : .25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.4),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: cs.secondaryContainer,
        contentTextStyle: TextStyle(color: cs.onSecondaryContainer),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surface,
        indicatorColor: cs.primary.withOpacity(.14),
        labelTextStyle: MaterialStatePropertyAll(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: cs.primary),
    );
  }
}
