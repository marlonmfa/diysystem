import 'package:flutter/material.dart';

abstract final class DiyColors {
  static const ink = Color(0xFF111A24);
  static const slate = Color(0xFF4B5A69);
  static const mist = Color(0xFFEEF3F5);
  static const paper = Color(0xFFF9FBFC);
  static const cobalt = Color(0xFF3457D5);
  static const orange = Color(0xFFFF7A45);
  static const algae = Color(0xFF1A8E74);
  static const line = Color(0xFFD5DEE3);
}

ThemeData buildTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: DiyColors.cobalt,
        brightness: Brightness.light,
        surface: DiyColors.paper,
      ).copyWith(
        primary: DiyColors.cobalt,
        secondary: DiyColors.orange,
        tertiary: DiyColors.algae,
        onSurface: DiyColors.ink,
        outline: DiyColors.line,
      );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: DiyColors.mist,
    textTheme: base.textTheme.copyWith(
      displaySmall: const TextStyle(
        fontFamily: 'Space Grotesk',
        fontFamilyFallback: [
          'Segoe UI Variable',
          'SF Pro Display',
          'Noto Sans',
        ],
        fontSize: 42,
        height: 1.02,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.8,
        color: DiyColors.ink,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'Space Grotesk',
        fontFamilyFallback: [
          'Segoe UI Variable',
          'SF Pro Display',
          'Noto Sans',
        ],
        fontSize: 30,
        height: 1.08,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        color: DiyColors.ink,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: DiyColors.ink,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        height: 1.5,
        color: DiyColors.ink,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        height: 1.45,
        color: DiyColors.slate,
      ),
      labelSmall: const TextStyle(
        fontFamily: 'IBM Plex Mono',
        fontFamilyFallback: ['Cascadia Mono', 'SF Mono', 'monospace'],
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: DiyColors.slate,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: DiyColors.paper,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        side: BorderSide(color: DiyColors.line),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: DiyColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: DiyColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: DiyColors.cobalt, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: DiyColors.line),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: DiyColors.paper,
      indicatorColor: Color(0xFFDCE4FF),
      elevation: 0,
    ),
  );
}
