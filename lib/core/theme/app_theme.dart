import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6C63FF),
        secondary: Color(0xFF3B82F6),
        surface: Colors.white,
        background: Color(0xFFF8F7FF),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1F2937),
        onBackground: Color(0xFF1F2937),
        error: Color(0xFFEF4444),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F7FF),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF8A82FF), // slightly lighter for dark mode
        secondary: Color(0xFF60A5FA),
        surface: Color(0xFF1E1E2C), // Dark surface
        background: Color(0xFF121212), // Very dark background
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFE0E0E0),
        onBackground: Color(0xFFE0E0E0),
        error: Color(0xFFF87171),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E2C),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E2C),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
