import 'package:flutter/material.dart';

/// Centralized application theme configuration.
/// Provides both Light and Dark Material 3 themes using the same color seed.
class AppTheme {
  /// Light mode theme
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        // This color is used by Material to generate the entire colorScheme.
        colorSchemeSeed: const Color(0xFF6750A4),
        brightness: Brightness.light,
        visualDensity: VisualDensity.comfortable,

        // Optional: Customize typography for better readability in light mode
        textTheme: Typography.blackMountainView,
      );

  /// Dark mode theme
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6750A4),
        brightness: Brightness.dark,
        visualDensity: VisualDensity.comfortable,

        // Optional: Use proper dark mode typography
        textTheme: Typography.whiteMountainView,
      );
}
