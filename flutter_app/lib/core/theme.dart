import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const background = Color(0xFFFFFCF7);
  const surface = Color(0xFFFFF7EF);
  const peach = Color(0xFFFFCDB2);
  const coral = Color(0xFFFFAFA3);
  const mint = Color(0xFFB8E0D2);
  const text = Color(0xFF4A3F35);

  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: coral,
        brightness: Brightness.light,
        surface: surface,
      ).copyWith(
        primary: coral,
        secondary: mint,
        tertiary: peach,
        onSurface: text,
        onPrimary: Colors.white,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: text),
      titleLarge: TextStyle(fontWeight: FontWeight.w700, color: text),
      bodyLarge: TextStyle(color: text),
      bodyMedium: TextStyle(color: text),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: coral, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: coral,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
