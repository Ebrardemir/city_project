import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  /// Tema scheme bilgisi burada tutulacak
  static late ColorScheme _scheme;

  /// Uygulama açıldığında ThemeData oluşturulurken çağrılacak
  static void init(ColorScheme scheme) {
    _scheme = scheme;
  }

  // ---- CUSTOM SHORTCUT STYLES ----

  static TextStyle get headline => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: _scheme.onSurface,
  );

  static TextStyle get cardTitle => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: _scheme.onSurface,
  );

  static TextStyle get meta => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: _scheme.onSurface.withOpacity(.7),
  );

  static TextStyle get body => TextStyle(
    fontSize: 14,
    height: 1.45,
    color: _scheme.onSurface.withOpacity(.9),
  );

  // ---- MATERIAL3 TEXT THEME ----
  static TextTheme buildTextTheme(ColorScheme scheme) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        height: 1.08,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      // titleXlarge: TextStyle(
      //   fontSize: 22,
      //   fontWeight: FontWeight.w600,
      //   color: scheme.onSurface.withValues(alpha: 0.9),
      // ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface.withValues(alpha: 0.9),
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface.withValues(alpha: 0.9),
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface.withValues(alpha: 0.9),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface.withValues(alpha: 0.95),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface.withValues(alpha: 0.9),
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface.withValues(alpha: 0.8),
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: scheme.onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
