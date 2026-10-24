import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Tema Material 3 "Pitch Naturalism" — varian gelap modern.
class AppTheme {
  const AppTheme._();

  /// Tema default aplikasi (dark).
  static ThemeData get dark => _build();

  /// Alias agar pemanggilan lama `AppTheme.light` tetap berjalan.
  static ThemeData get light => _build();

  static ThemeData _build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.lime,
      brightness: Brightness.dark,
      primary: AppColors.lime,
      onPrimary: AppColors.onAccent,
      primaryContainer: AppColors.forest,
      onPrimaryContainer: AppColors.onForest,
      secondary: AppColors.sage,
      onSecondary: AppColors.onAccent,
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
      onError: AppColors.onAccent,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
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
      iconTheme: const IconThemeData(color: AppColors.onSurface),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
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
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.pillBorder,
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: const OutlineInputBorder(
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
          side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
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
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: AppTypography.bodyMd(color: AppColors.onSurface),
        actionTextColor: AppColors.lime,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.controlBorder,
          side: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        modalBarrierColor: Color(0xB3000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.lime,
        linearTrackColor: AppColors.barTrack,
        circularTrackColor: AppColors.barTrack,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.lime,
        inactiveTrackColor: AppColors.barTrack,
        thumbColor: AppColors.lime,
        overlayColor: Color(0x1FC8F26C),
        valueIndicatorColor: AppColors.lime,
        valueIndicatorTextStyle: TextStyle(color: AppColors.onAccent),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.lime,
        selectionColor: Color(0x4DC8F26C),
        selectionHandleColor: AppColors.lime,
      ),
      scrollbarTheme: const ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(Color(0x4DA8BFA2)),
      ),
    );
  }
}
