import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografi Scoutify.
///
/// - **Newsreader** (serif) untuk judul editorial, nama pemain, dan angka besar.
/// - **Plus Jakarta Sans** untuk teks isi, label, dan kontrol.
class AppTypography {
  const AppTypography._();

  static TextStyle _newsreader({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFontsnewsreader(
      fontSize: size,
      fontWeight: weight,
      height: height == null ? null : height / size,
      letterSpacing: letterSpacing,
      color: color ?? AppColors.ink,
    );
  }

  static TextStyle _jakarta({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      height: height == null ? null : height / size,
      letterSpacing: letterSpacing,
      color: color ?? AppColors.onSurface,
    );
  }

  // --- Editorial (Newsreader) -------------------------------------------
  static TextStyle displayLg({Color? color}) => _newsreader(
    size: 40,
    weight: FontWeight.w600,
    height: 48,
    letterSpacing: -0.8,
    color: color ?? AppColors.ink,
  );

  static TextStyle headlineLg({Color? color}) => _newsreader(
    size: 28,
    weight: FontWeight.w600,
    height: 34,
    letterSpacing: -0.42,
    color: color ?? AppColors.ink,
  );

  static TextStyle headlineMd({Color? color}) => _newsreader(
    size: 22,
    weight: FontWeight.w600,
    height: 28,
    letterSpacing: -0.22,
    color: color ?? AppColors.ink,
  );

  static TextStyle statXl({Color? color}) => _newsreader(
    size: 36,
    weight: FontWeight.w500,
    height: 40,
    letterSpacing: -1.08,
    color: color ?? AppColors.ink,
  );

  static TextStyle statMd({Color? color}) => _newsreader(
    size: 24,
    weight: FontWeight.w500,
    height: 28,
    letterSpacing: -0.48,
    color: color ?? AppColors.ink,
  );

  // --- Fungsional (Plus Jakarta Sans) -----------------------------------
  static TextStyle titleLg({Color? color}) => _jakarta(
    size: 18,
    weight: FontWeight.w700,
    height: 24,
    color: color ?? AppColors.ink,
  );

  static TextStyle titleMd({Color? color}) => _jakarta(
    size: 16,
    weight: FontWeight.w600,
    height: 22,
    color: color ?? AppColors.ink,
  );

  static TextStyle bodyLg({Color? color}) => _jakarta(
    size: 15,
    weight: FontWeight.w400,
    height: 22,
    color: color ?? AppColors.onSurface,
  );

  static TextStyle bodyMd({Color? color}) => _jakarta(
    size: 14,
    weight: FontWeight.w400,
    height: 20,
    color: color ?? AppColors.onSurface,
  );

  static TextStyle bodySm({Color? color}) => _jakarta(
    size: 12,
    weight: FontWeight.w400,
    height: 16,
    color: color ?? AppColors.onSurfaceVariant,
  );

  static TextStyle labelLg({Color? color}) => _jakarta(
    size: 13,
    weight: FontWeight.w700,
    height: 18,
    letterSpacing: 0.26,
    color: color ?? AppColors.ink,
  );

  static TextStyle labelMd({Color? color}) => _jakarta(
    size: 11,
    weight: FontWeight.w600,
    height: 14,
    letterSpacing: 0.44,
    color: color ?? AppColors.sageSoft,
  );

  /// Label kecil huruf kapital untuk header metrik.
  static TextStyle overline({Color? color}) => _jakarta(
    size: 10.5,
    weight: FontWeight.w700,
    height: 14,
    letterSpacing: 0.8,
    color: color ?? AppColors.sageSoft,
  );
}
