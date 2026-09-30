import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFEFF6FF);

  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF047857);
  static const Color successLight = Color(0xFFDCFCE7);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFB45309);
  static const Color warningLight = Color(0xFFFEF3C7);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerDark = Color(0xFFB91C1C);
  static const Color dangerLight = Color(0xFFFEE2E2);

  // Neutrals
  static const Color darkNeutral = Color(0xFF1E293B);
  static const Color lightNeutral = Color(0xFF64748B);
  static const Color bg = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color borderColor = Color(0xFFE2E8F0);

  // Sidebar colors
  static const Color sidebarBg = Color(0xFF111C2D);
  static const Color sidebarText = Color(0xFF94A3B8);
  static const Color sidebarActiveText = Colors.white;
  static const Color sidebarActiveBg = Color(0xFF2563EB);

  // Radii
  static double radius = 12.0;
  static double radiusLg = 16.0;

  // Box Shadow helpers
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    )
  ];

  static List<BoxShadow> shadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 6,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    )
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 15,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 6,
      offset: const Offset(0, 4),
    )
  ];

  // Font family config
  static const String fontFamily = 'Cairo';

  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: bg,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primaryDark,
        background: bg,
        surface: cardBg,
        error: danger,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: darkNeutral, fontSize: 14, fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(color: lightNeutral, fontSize: 13, fontWeight: FontWeight.normal),
        titleLarge: TextStyle(color: darkNeutral, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: borderColor),
        ),
      ),
    );
  }
}
