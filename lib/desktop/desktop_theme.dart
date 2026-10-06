import 'package:flutter/material.dart';

/// DTheme defines the Boltz-style light desktop design tokens for Hisab Premium:
/// - Background: #F4F6FB (soft blue-gray)
/// - Sidebar: #FFFFFF (clean white)
/// - Cards: #FFFFFF with radius 16 and subtle soft shadow (black 6% opacity, blur 16, offset 0,4)
/// - Ink: #1A2233
/// - Muted: #8A94A6
/// - Borders: #E8ECF3
/// - Accent: #4F46E5 (Indigo)
/// - Success: #22C55E (Income)
/// - Danger: #EF4444 (Expense)
/// - Pastels: Indigo, Green, Red, Amber, Sky, Violet
class DTheme {
  DTheme._();

  // Core background & structural colors
  static const Color background = Color(0xFFF4F6FB);
  static const Color sidebarBg = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color surfaceHover = Color(0xFFF8FAFC);
  static const Color ink = Color(0xFF1A2233);
  static const Color muted = Color(0xFF8A94A6);
  static const Color borders = Color(0xFFE8ECF3);

  // Semantic & accent colors
  static const Color accent = Color(0xFF4F46E5); // Indigo
  static const Color successGreen = Color(0xFF22C55E); // Income
  static const Color dangerRed = Color(0xFFEF4444); // Expense
  static const Color amber = Color(0xFFF59E0B);
  static const Color sky = Color(0xFF0EA5E9);
  static const Color violet = Color(0xFF8B5CF6);

  // Pastel tinted backgrounds for stat cards and badges
  static const Color pastelIndigo = Color(0xFFEEF2FF);
  static const Color pastelGreen = Color(0xFFF0FDF4);
  static const Color pastelRed = Color(0xFFFEF2F2);
  static const Color pastelAmber = Color(0xFFFFFBEB);
  static const Color pastelSky = Color(0xFFF0F9FF);
  static const Color pastelViolet = Color(0xFFF5F3FF);

  // Corner radii
  static const double cardRadius = 16.0;
  static final BorderRadius borderRadius24 = BorderRadius.circular(24.0);
  static final BorderRadius borderRadius16 = BorderRadius.circular(16.0);
  static final BorderRadius borderRadius12 = BorderRadius.circular(12.0);
  static final BorderRadius borderRadius10 = BorderRadius.circular(10.0);
  static final BorderRadius borderRadius8 = BorderRadius.circular(8.0);

  // Soft shadows
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x0F000000), // black 6%
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  static const BoxShadow cardHoverShadow = BoxShadow(
    color: Color(0x1A000000), // black 10%
    blurRadius: 20,
    offset: Offset(0, 6),
  );

  static BoxDecoration cardDecoration({
    Color color = cardBg,
    BorderRadius? borderRadius,
    Border? border,
    bool isHovered = false,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius ?? borderRadius16,
      border: border ?? Border.all(color: borders, width: 1.0),
      boxShadow: [isHovered ? cardHoverShadow : cardShadow],
    );
  }

  // Text Styles (Headings w700, body w400/w500)
  static const TextStyle heading1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: ink,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: ink,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: ink,
    letterSpacing: -0.2,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: ink,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ink,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ink,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: muted,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: muted,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: muted,
    letterSpacing: 0.8,
  );

  /// Light ThemeData for desktop embedding
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: accent,
        surface: cardBg,
        error: dangerRed,
        onPrimary: Colors.white,
        onSurface: ink,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius16,
          side: const BorderSide(color: borders),
        ),
      ),
      dividerColor: borders,
      dividerTheme: const DividerThemeData(
        color: borders,
        thickness: 1,
      ),
    );
  }
}
