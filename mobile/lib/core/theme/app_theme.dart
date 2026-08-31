import 'package:flutter/material.dart';

/// Single source of truth for app theming, so screens never hard-code
/// colors/text styles (spec section 49: avoid hard-coded values scattered
/// through the UI).
class AppTheme {
  const AppTheme._();

  static const Color _seedColor = Color(0xFF0F7A5C);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
        brightness: Brightness.light,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
      );
}
