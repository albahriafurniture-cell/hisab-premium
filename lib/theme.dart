import 'package:flutter/material.dart';

/// AppTheme defines the premium dark fintech design system for Hisab Premium.
class AppTheme {
  AppTheme._();

  // Core Brand & Palette Colors
  static const Color background = Color(0xFF0A0E1A);
  static const Color backgroundSecondary = Color(0xFF0D1220);
  static const Color card = Color(0xFF141B2E);
  static const Color cardBorder = Color(0x33C9A227); // #C9A227 at 20% opacity

  static const Color gold = Color(0xFFC9A227);
  static const Color primary = gold;

  static const Color teal = Color(0xFF2DD4BF);
  static const Color income = teal;

  static const Color rose = Color(0xFFFB7185);
  static const Color expense = rose;

  // Additional Supporting Colors
  static const Color surfaceElevated = Color(0xFF1A233D);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color dividerColor = Color(0x1FFFFFFF);

  // Radius
  static const double cornerRadius = 20.0;
  static final BorderRadius borderRadius20 = BorderRadius.circular(cornerRadius);

  // Subtle Card Gradient
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF18223B),
      Color(0xFF141B2E),
    ],
  );

  // Glassmorphic / Premium Card Decoration
  static BoxDecoration cardDecoration({
    BorderRadius? borderRadius,
    Gradient? gradient,
    Border? border,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      gradient: gradient ?? cardGradient,
      borderRadius: borderRadius ?? borderRadius20,
      border: border ?? Border.all(color: cardBorder, width: 1.0),
      boxShadow: shadows ??
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
    );
  }

  // Typography with tabular figures for numbers & letter-spaced section labels
  static TextStyle displayBoldNumber({
    double fontSize = 28,
    Color color = textPrimary,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: -0.5,
    );
  }

  static TextStyle sectionLabel({
    Color color = textSecondary,
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 1.5,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // Dark ThemeData
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: gold,
      onPrimary: Color(0xFF0A0E1A),
      secondary: teal,
      onSecondary: Colors.black,
      error: rose,
      onError: Colors.white,
      surface: card,
      onSurface: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: dividerColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius20,
          side: const BorderSide(color: cardBorder, width: 1.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius20,
          side: const BorderSide(color: cardBorder, width: 1.0),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: backgroundSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(cornerRadius)),
          side: BorderSide(color: cardBorder, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: const Color(0xFF0A0E1A),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius20,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: gold,
          side: const BorderSide(color: gold, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius20,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: gold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: borderRadius20,
          borderSide: const BorderSide(color: Color(0x22FFFFFF), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius20,
          borderSide: const BorderSide(color: Color(0x22FFFFFF), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius20,
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textSecondary),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        displayMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        displaySmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: textSecondary,
        ),
      ),
    );
  }
}
