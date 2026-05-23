// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Cricket Green Color Palette
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color lightGreen = Color(0xFF2E7D32);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color pitchGreen = Color(0xFF388E3C);
  static const Color darkBg = Color(0xFF0A1628);
  static const Color cardBg = Color(0xFF0D2137);
  static const Color cardBorder = Color(0xFF1E3A5F);
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color redAccent = Color(0xFFE53935);
  static const Color blueAccent = Color(0xFF1565C0);
  static const Color orangeAccent = Color(0xFFFF6F00);
  static const Color white = Colors.white;

  // Ball Colors
  static const Color wideBall = Color(0xFFFF8F00);
  static const Color noBall = Color(0xFFD32F2F);
  static const Color byeBall = Color(0xFF1565C0);
  static const Color legByeBall = Color(0xFF2E7D32);
  static const Color deadBall = Color(0xFF616161);
  static const Color wicketBall = Color(0xFF7B1FA2);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: primaryGreen,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: accentGreen,
        surface: cardBg,
        error: redAccent,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: accentGreen,
        ),
        iconTheme: const IconThemeData(color: accentGreen),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightGreen,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      cardTheme: CardTheme(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: cardBorder, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF071524),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: cardBorder, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: cardBorder, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentGreen, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF6B8FA6)),
        hintStyle: const TextStyle(color: Color(0xFF6B8FA6)),
      ),
    );
  }
}

// ============================================================
// Reusable Gradient Box Decoration
// ============================================================
BoxDecoration get cricketGradient => const BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF0A1628)],
    stops: [0.0, 0.5, 1.0],
  ),
);
