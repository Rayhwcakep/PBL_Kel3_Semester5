import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Tema Material 3 "Pitch Naturalism" �?" varian gelap & terang.
class AppTheme {
  const AppTheme._();

  /// Tema gelap modern (default).
  static ThemeData get dark {
    AppColors.use(Brightness.dark);
    return _build(Brightness.dark);
  }

  /// Tema terang.
  static ThemeData get light {
    AppColors.use(Brightness.light);
    return _build(Brightness.light);
  }

  /// Bangun tema untuk brightness tertentu tanpa mengubah palet global.
  static ThemeData build(Brightness brightness) {
    AppColors.use(brightness);
    return _build(brightness);
  }

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.lime,
      brightness: brightness,
      primary: AppColors.lime,
      onPrimary: AppColors.onAccent,
      primaryContainer: AppColors.forest,
      onPrimaryContainer: AppColors.onForest,
      secondary: AppColors.sage,
      onSecondary: isDark ? AppColors.onAccent : Colors.white,
      tertiary: AppColors.playerB,
      onTertiary: AppColors.onAccent,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerLowest: AppColors.surfaceLow,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceHigh,
      surfaceContainerHighest: AppColors.surfaceHighest,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      error: AppColors.error,
      onError: isDark ? AppColors.onAccent : Colors.white,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.error,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.canvas,
      canvasColor: AppColors.canvas,
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
      iconTheme: IconThemeData(color: AppColors.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
          side: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainer,
        hintStyle: AppTypography.bodyMd(color: AppColors.sageSoft),
        prefixIconColor: AppColors.sageSoft,
        suffixIconColor: AppColors.sageSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.pillBorder,
          borderSide: BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.pillBorder,
          borderSide: BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.pillBorder,
          borderSide: BorderSide(color: AppColors.lime, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lime,
          foregroundColor: AppColors.onAccent,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.pillBorder,
          ),
          textStyle: AppTypography.titleMd(color: AppColors.onAccent),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: AppColors.cardBorder, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.pillBorder,
          ),
          textStyle: AppTypography.titleMd(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lime,
          textStyle: AppTypography.labelLg(color: AppColors.lime),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.onSurface),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: AppTypography.bodyMd(color: AppColors.onSurface),
        actionTextColor: AppColors.lime,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.controlBorder,
          side: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        modalBarrierColor: isDark
            ? const Color(0xB3000000)
            : const Color(0x66000000),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.lime,
        linearTrackColor: AppColors.barTrack,
        circularTrackColor: AppColors.barTrack,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.lime,
        inactiveTrackColor: AppColors.barTrack,
        thumbColor: AppColors.lime,
        overlayColor: AppColors.lime.withValues(alpha: 0.12),
        valueIndicatorColor: AppColors.lime,
        valueIndicatorTextStyle: TextStyle(color: AppColors.onAccent),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.lime,
        selectionColor: AppColors.lime.withValues(alpha: 0.3),
        selectionHandleColor: AppColors.lime,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          AppColors.sage.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
