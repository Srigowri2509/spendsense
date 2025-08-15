// lib/theme.dart
import 'package:flutter/material.dart';

class Palette {
  static const primary  = Color(0xFF2B90B8);
  static const secondary = Color(0xFF67C587);
  static const accent   = Color(0xFFF2B84B);
  static const warn     = Color(0xFFEC6B64);
  static const bg       = Color(0xFFF7F8FA);
  static const darkBg   = Color(0xFF0F1418);
}

class AppTheme {
  static ThemeData get light {
    final card = CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Palette.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Palette.bg,
      cardTheme: card,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static ThemeData get dark {
    final card = CardThemeData(
      color: const Color(0xFF151A1F),
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Palette.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Palette.darkBg,
      cardTheme: card,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A2026),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
