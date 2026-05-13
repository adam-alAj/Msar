import 'package:flutter/material.dart';

class AppTheme {
  // WCAG AA-compliant status colors for dark surfaces (#1C1C1E)
  // Green #66BB6A on #1C1C1E → 5.2:1
  // Orange #FFA726 on #1C1C1E → 6.8:1
  // Red   #EF5350 on #1C1C1E → 4.6:1
  static const Color darkOpenColor = Color(0xFF66BB6A);
  static const Color darkCrowdedColor = Color(0xFFFFA726);
  static const Color darkClosedColor = Color(0xFFEF5350);

  // Light mode status colors (original)
  static const Color lightOpenColor = Color(0xFF4CAF50);
  static const Color lightCrowdedColor = Color(0xFFFFA726);
  static const Color lightClosedColor = Color(0xFFE53935);

  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: Colors.green,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.green.shade700,
      foregroundColor: Colors.white,
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: Colors.green,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1C1C1E),
      foregroundColor: Colors.white,
    ),
    cardColor: const Color(0xFF1E1E1E),
  );

  /// Returns the appropriate status color based on brightness
  static Color statusColor(String status, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (status) {
      case 'OPEN':
        return isDark ? darkOpenColor : lightOpenColor;
      case 'CROWDED':
        return isDark ? darkCrowdedColor : lightCrowdedColor;
      case 'CLOSED':
        return isDark ? darkClosedColor : lightClosedColor;
      default:
        return isDark ? darkOpenColor : lightOpenColor;
    }
  }
}
