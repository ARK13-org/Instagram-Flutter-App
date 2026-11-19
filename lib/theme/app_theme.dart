import 'package:flutter/material.dart';

class Brand {
  Brand._();

  static const Color purple = Color(0xFF833AB4);
  static const Color red = Color(0xFFFD1D1D);
  static const Color orange = Color(0xFFFCB045);

  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [orange, red, purple],
  );

  static const List<Color> avatarColors = [
    Color(0xFF6C5CE7),
    Color(0xFF0984E3),
    Color(0xFF00A896),
    Color(0xFFE17055),
    Color(0xFFD63384),
    Color(0xFF5F6CAF),
    Color(0xFF2E9E6B),
    Color(0xFFB5651D),
  ];
}

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.purple,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF0C0C10)
        : const Color(0xFFFFFFFF),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
