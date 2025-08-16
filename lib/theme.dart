import 'package:flutter/material.dart';

class Palette {
  static const primary = Color(0xFF2B90B8);
  static const secondary = Color(0xFF67C587);
  static const accent = Color(0xFFF2B84B);
  static const warn = Color(0xFFEC6B64);

  // New: soft warm background like the mock
  static const bgTint = Color(0xFFFFF7EC); // pale creamy peach
  static const darkBg = Color(0xFF0F1418);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Palette.primary, brightness: Brightness.light),
        scaffoldBackgroundColor: Palette.bgTint,
        cardTheme: const CardThemeData(
          color: Colors.white,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide.none),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Palette.primary, brightness: Brightness.dark),
        scaffoldBackgroundColor: Palette.darkBg,
        cardTheme: const CardThemeData(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide.none),
        ),
      );
}
