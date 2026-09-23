import 'package:flutter/material.dart';

class JajColors {
  static const Color primary = Color(0xFFFF8A3D);
  static const Color primaryDark = Color(0xFFE56A1F);
  static const Color accentLight = Color(0xFFFFE8D6);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFF8F2);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textLight = Color(0xFF6B6B6B);
  static const Color success = Color(0xFF2EB872);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
}

ThemeData buildJajTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: JajColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: JajColors.primary,
      brightness: Brightness.light,
      primary: JajColors.primary,
      surface: JajColors.background,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: JajColors.background,
      elevation: 0,
      centerTitle: false,
      foregroundColor: JajColors.textDark,
      titleTextStyle: TextStyle(
        color: JajColors.textDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: JajColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: JajColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: JajColors.primary, width: 2),
      ),
    ),
  );
}
