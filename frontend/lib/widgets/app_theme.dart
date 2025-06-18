import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF18332B);
  static const Color background = Color(0xFFF5F3EC);
  static const Color accent = Color(0xFF4CAF50);
  static const Color card = Colors.white;

  static ThemeData get themeData => ThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: accent,
      primary: primary,
    ),
    cardColor: card,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
      bodyMedium: TextStyle(fontSize: 16, color: primary),
    ),
  );
}
