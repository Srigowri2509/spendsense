import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFFF4F1DE);
  static const ink = Color(0xFF3D405B);
  static const accent = Color(0xFFE07A5F);
  static const mint = Color(0xFF81B29A);
  static const card = Colors.white;
  static const chipBg = Color(0xFFFFE8E1);
}

ThemeData zenTheme() {
  final theme = ThemeData.light(
    useMaterial3: true,
  );
  return theme.copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accent),
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: GoogleFonts.poppinsTextTheme(theme.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        fontSize: 22,
        color: AppColors.ink,
      ),
      iconTheme: const IconThemeData(color: AppColors.ink),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      shape: StadiumBorder(),
    ),
  );
}

String two(int n) => n.toString().padLeft(2, '0');