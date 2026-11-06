import 'package:flutter/material.dart';

class AppTheme {
  // Deep Void Studio Palette
  static const Color background = Color(0xFF07090E);
  static const Color surface = Color(0xFF101622);
  static const Color surfaceElevated = Color(0xFF172033);
  static const Color surfaceBorder = Color(0xFF222F48);

  // Accents
  static const Color gold = Color(0xFFFFB300);
  static const Color goldLight = Color(0xFFFFCA28);
  static const Color goldDark = Color(0xFFFF8F00);

  // In-tune / Detected Green
  static const Color emerald = Color(0xFF00E676);
  static const Color emeraldGlow = Color(0x3300E676);

  // Scales / Auxiliary Cyan
  static const Color cyan = Color(0xFF00E5FF);

  // Critical / Flat Red
  static const Color red = Color(0xFFFF5252);

  // Wood & Fretboard tones
  static const Color rosewoodDark = Color(0xFF1E1612);
  static const Color rosewoodLight = Color(0xFF2B1F1A);
  static const Color fretWire = Color(0xFF8A9BA8);
  static const Color fretInlay = Color(0xFFE2E8F0);
  static const Color brassNut = Color(0xFFD4AF37);
  static const Color bronzeString = Color(0xFFCD7F32);
  static const Color silverString = Color(0xFFC0C0C0);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: gold,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: cyan,
        surface: surface,
        error: red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: gold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: gold,
        unselectedItemColor: Color(0xFF7A889B),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: surfaceBorder, width: 1),
        ),
      ),
    );
  }
}
