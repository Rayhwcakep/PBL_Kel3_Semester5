import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Tema Material 3 yang mengikuti design system Scoutify.
class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      primary: AppColors.forest,
      onPrimary: AppColors.canvas,
      secondary: AppColors.sage,
      onSecondary: Colors.white,
      tertiary: AppColors.lime,
      onTertiary: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      error: AppColors.error,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      splashFactory: InkRipple.splashFactory,
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLg(),
        headlineLarge: AppTypography.headlineLg(),
        headlineMedium: AppTypography.headlineMd(),
        titleLarge: AppTypography.titleLg(),
        titleMedium: AppTypography.titleMd(),
        bodyLarge: AppTypography.bodyLg(),
        bodyMedium: AppTypography.bodyMd(),
        bodySmall: AppTypography.bodySm(),
        labelLarge: AppTypography.labelLg(),
        labelMedium: AppTypography.labelMd(),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppTypography.bodyMd(color: AppColors.sageSoft),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.pillBorder,
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.pillBorder,
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.pillBorder,
          borderSide: BorderSide(color: AppColors.forest, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: AppColors.canvas,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.pillBorder,
          ),
          textStyle: AppTypography.titleMd(color: AppColors.canvas),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.pillBorder,
          ),
          textStyle: AppTypography.titleMd(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.sage,
          textStyle: AppTypography.labelLg(color: AppColors.sage),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.forest,
        contentTextStyle: AppTypography.bodyMd(color: AppColors.canvas),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.controlBorder),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.forest,
        inactiveTrackColor: Color(0x26728C5A),
        thumbColor: AppColors.forest,
        overlayColor: Color(0x1F102F15),
      ),
    );
  }
}
