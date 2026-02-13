import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand palette (integrated from new AppTheme)
  static const primaryColor = Color(0xFF219653); // Ana yeşil
  static const secondaryColor = Color(0xFF27AE60); // Canlı yeşil
  static const accentGreen = Color.fromARGB(255, 111, 206, 150); // Açık yeşil
  static const Color dietPurple = Color(0xFF8C7BFF);

  static const successDeep = Color(0xFF14532D); // Daha koyu yeşil
  static const warning = Color(0xFFF2994A); // Uyarı - turuncu
  static const error = Color.fromARGB(255, 224, 20, 20); // Hata - kırmızı
  static const infoBlue = Color(0xFF2F80ED); // Bilgi - mavi

  static const iconBlue = Color(0xFF2F80ED);
  static const iconWhite = Color.fromARGB(255, 255, 255, 255);

  // Surfaces & background
  static const backgroundLight = Colors.white; // Açık gri-beyaz
  static const cardBackground = Colors.white;
  static const loginBg = Color(0xFFE8F5E9); // Açık yeşilimsi arka plan
  static const loginInputBg = Color(0xFFF1F4F6); // input arka planı

  // Text colors
  static const textPrimary = Colors.black87;
  static const textSecondary = Color(0xFF64748B);
  static const textLight = Colors.white;

  // Additional accents
  static const blue = Color(0xFF2F80ED);
  static const orange = Color.fromARGB(255, 224, 118, 41);
  static const purple = Color(0xFF6366F1);
  static const pink = Color(0xFFEC4899);
  static const greenDeep = Color(0xFF1B5E20);
  static const white = Color.fromARGB(255, 255, 255, 255);
  static const grey = Color(0xFF64748B);
  static const purpleDeep = Color.fromARGB(255, 52, 14, 118);
  static const black = Colors.black87;

  // Legacy neutrals kept for layout tokens
  static const seed = primaryColor; // use brand primary as seed
  static const accent = blue; // legacy accent maps to brand blue

  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray300 = Color(0xFFE5E7EB);
  static const gray700 = Color(0xFF374151);
  static const gray800 = Color(0xFF1F2937);
  static const gray900 = Color(0xFF111827);

  static const success = Color(0xFF16A34A); // lighter success (kept)

  static final ColorScheme lightScheme =
      ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ).copyWith(
        // Brand mappings
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: const Color.fromRGBO(47, 128, 237, 1),
        error: error,

        // Surfaces
        surface: cardBackground,
        //onSurface: Colors.amberAccent,
        surfaceContainerHighest: gray100,
        outline: gray300,
      );

  static final ColorScheme darkScheme =
      ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
        surface: const Color(0xFF0B1220),
      ).copyWith(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: blue,
        error: error,

        surfaceContainerHighest: gray800,
        outline: gray700,
      );
}
