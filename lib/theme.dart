import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JC {
  // ─── Core palette ───
  static const Color primary = Color(0xFFFF7A1A);
  static const Color primaryDark = Color(0xFFE56A1F);
  static const Color primaryLight = Color(0xFFFF9F5A);
  static const Color creamPeach = Color(0xFFFFE8D6);
  static const Color peachSoft = Color(0xFFFFF1E6);

  // ─── Neutrals ───
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFAFAFA);
  static const Color charcoal = Color(0xFF1A1F2E);
  static const Color grey = Color(0xFF6B7280);
  static const Color greyLight = Color(0xFFE5E7EB);

  // ─── Status ───
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softGradient = LinearGradient(
    colors: [peachSoft, white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Shadows ───
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: primary.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: charcoal.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

// Backward-compat alias (সব পুরনো স্ক্রিনে JajColors কাজ করবে)
class JajColors {
  static const Color primary = JC.primary;
  static const Color primaryDark = JC.primaryDark;
  static const Color accentLight = JC.creamPeach;
  static const Color background = JC.white;
  static const Color surfaceLight = JC.peachSoft;
  static const Color textDark = JC.charcoal;
  static const Color textLight = JC.grey;
  static const Color success = JC.success;
  static const Color error = JC.error;
  static const Color warning = JC.warning;
}

// ─── Text styles ───
class JText {
  static TextStyle display(BuildContext c) => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: JC.charcoal,
        height: 1.2,
      );

  static TextStyle h1(BuildContext c) => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: JC.charcoal,
      );

  static TextStyle h2(BuildContext c) => GoogleFonts.hindSiliguri(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: JC.charcoal,
      );

  static TextStyle body(BuildContext c) => GoogleFonts.hindSiliguri(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: JC.charcoal,
      );

  static TextStyle bodyGrey(BuildContext c) => GoogleFonts.hindSiliguri(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: JC.grey,
      );

  static TextStyle label(BuildContext c) => GoogleFonts.hindSiliguri(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: JC.grey,
        letterSpacing: 0.3,
      );

  static TextStyle number(BuildContext c) => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: JC.charcoal,
      );
}

// ─── Theme ───
ThemeData buildJajTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: JC.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: JC.primary,
      brightness: Brightness.light,
      primary: JC.primary,
      surface: JC.white,
    ),
    splashFactory: InkRipple.splashFactory,
  );

  return base.copyWith(
    textTheme: GoogleFonts.hindSiliguriTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: JC.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: JC.charcoal,
      titleTextStyle: GoogleFonts.hindSiliguri(
        color: JC.charcoal,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: JC.primary,
        foregroundColor: JC.white,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
        textStyle: GoogleFonts.hindSiliguri(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: JC.primary,
        side: const BorderSide(color: JC.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: GoogleFonts.hindSiliguri(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: JC.peachSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      hintStyle: GoogleFonts.hindSiliguri(color: JC.grey, fontSize: 14),
      labelStyle: GoogleFonts.hindSiliguri(color: JC.grey, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: JC.primary, width: 2),
      ),
    ),
    cardTheme: CardTheme(
      color: JC.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: JC.white,
      indicatorColor: JC.creamPeach,
      elevation: 0,
      labelTextStyle: MaterialStateProperty.all(
        GoogleFonts.hindSiliguri(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    ),
  );
}
