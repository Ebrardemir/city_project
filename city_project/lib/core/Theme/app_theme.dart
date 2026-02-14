import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  /// Light Theme
  static ThemeData get light {
    final scheme = AppColors.lightScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: AppTextStyles.buildTextTheme(scheme),

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: AppTextStyles.buildTextTheme(scheme).titleLarge,
        surfaceTintColor: scheme.surface,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: scheme.surface,
        elevation: 8,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        showUnselectedLabels: false,
        selectedIconTheme: const IconThemeData(size: 24),
        unselectedIconTheme: const IconThemeData(size: 22),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.brMd),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.brMd),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.brMd),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(borderRadius: AppSpacing.brMd),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.brMd,
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.brMd,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.brMd,
          borderSide: BorderSide(color: scheme.error),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.brLg),
      ),

      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(color: scheme.onSurface),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: AppSpacing.md,
      ),

      iconTheme: IconThemeData(color: scheme.onSurface),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? scheme.primaryContainer
              : scheme.outlineVariant,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        iconColor: scheme.onSurfaceVariant,
      ),
    );
  }

  /// Dark Theme
  static ThemeData get dark {
    final scheme = AppColors.darkScheme;

    return light.copyWith(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: AppTextStyles.buildTextTheme(scheme).titleLarge,
        surfaceTintColor: scheme.surface,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: scheme.surface,
        elevation: 8,
        selectedItemColor: scheme.secondary, // dark’ta biraz aksan vurgusu
        unselectedItemColor: scheme.onSurfaceVariant,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        showUnselectedLabels: false,
        selectedIconTheme: const IconThemeData(size: 24),
        unselectedIconTheme: const IconThemeData(size: 22),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.brMd),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.brMd),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.brMd),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(borderRadius: AppSpacing.brMd),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.brMd,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.brMd,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.brMd,
          borderSide: BorderSide(color: scheme.error),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: AppSpacing.md,
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(color: scheme.onSurface),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        iconColor: scheme.onSurfaceVariant,
      ),
      textTheme: AppTextStyles.buildTextTheme(scheme),
    );
  }
}
