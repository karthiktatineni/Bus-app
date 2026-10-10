import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF0F4C81);
  static const Color onPrimaryColor = Color(0xFFFFFFFF);
  
  static const Color background = Color(0xFFF6F7F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEF0F3);
  
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF5B6472);
  
  static const Color border = Color(0xFFE2E5EA);

  // Status Colors
  static const Color success = Color(0xFF157347);
  static const Color warning = Color(0xFFB26A00);
  static const Color danger = Color(0xFFB42318);
  static const Color info = Color(0xFF175CD3);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        onPrimary: onPrimaryColor,
        background: background,
        surface: surface,
        surfaceContainerHighest: surfaceMuted,
        error: danger,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.hankenGroteskTextTheme().copyWith(
        displayLarge: GoogleFonts.hankenGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary),
        displayMedium: GoogleFonts.hankenGrotesk(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
        displaySmall: GoogleFonts.hankenGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: GoogleFonts.hankenGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: GoogleFonts.hankenGrotesk(fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium: GoogleFonts.hankenGrotesk(fontSize: 13, fontWeight: FontWeight.w400, color: textPrimary),
        bodySmall: GoogleFonts.hankenGrotesk(fontSize: 11, fontWeight: FontWeight.w400, color: textPrimary),
        // JetBrains Mono mappings for data/labels
        labelLarge: GoogleFonts.jetbrainsMono(fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary),
        labelMedium: GoogleFonts.jetbrainsMono(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
        labelSmall: GoogleFonts.jetbrainsMono(fontSize: 10, fontWeight: FontWeight.w500, color: textSecondary),
      ),
      cardTheme: const CardTheme(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    // Basic dark theme placeholder - to be refined in later milestone
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
      ),
    );
  }
}
