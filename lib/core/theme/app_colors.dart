import 'package:flutter/material.dart';

/// Palet warna design system "Pitch Naturalism" (Scoutify).
///
/// Aplikasi mendukung dua mode: **gelap modern** (default) dan **terang**.
/// Widget cukup memakai token seperti `AppColors.canvas` / `AppColors.ink`;
/// nilai token otomatis mengikuti mode yang sedang aktif.
class AppColors {
  const AppColors._();

  static Brightness _brightness = Brightness.dark;

  /// Dipanggil sekali saat aplikasi membangun tema.
  static void use(Brightness brightness) => _brightness = brightness;

  static bool get isDark => _brightness == Brightness.dark;

  static _Palette get _p => isDark ? _dark : _light;

  // --- Kanvas & permukaan ------------------------------------------------
  static Color get canvas => _p.canvas;
  static Color get surface => _p.surface;
  static Color get surfaceLow => _p.surfaceLow;
  static Color get surfaceContainer => _p.surfaceContainer;
  static Color get surfaceHigh => _p.surfaceHigh;
  static Color get surfaceHighest => _p.surfaceHighest;

  // --- Warna struktural --------------------------------------------------
  static Color get ink => _p.ink;
  static Color get forest => _p.forest;
  static Color get onForest => _p.onForest;
  static Color get onForestMuted => _p.onForestMuted;
  static Color get sage => _p.sage;
  static Color get sageSoft => _p.sageSoft;
  static Color get lime => _p.lime;
  static Color get onAccent => _p.onAccent;
  static Color get primaryFixed => _p.primaryFixed;
  static Color get secondaryFixed => _p.secondaryFixed;
  static Color get secondaryContainer => _p.secondaryContainer;

  // --- Teks --------------------------------------------------------------
  static Color get onSurface => _p.onSurface;
  static Color get onSurfaceVariant => _p.onSurfaceVariant;

  // --- Status ------------------------------------------------------------
  static Color get error => _p.error;
  static Color get errorContainer => _p.errorContainer;
  static Color get success => _p.success;
  static Color get shapPositive => _p.shapPositive;
  static Color get shapNegative => _p.shapNegative;

  // --- Garis -------------------------------------------------------------
  static Color get outline => _p.outline;
  static Color get outlineVariant => _p.outlineVariant;
  static Color get cardBorder => _p.cardBorder;

  // --- Identitas pemain (A vs B) ----------------------------------------
  static Color get playerA => lime;
  static Color get playerB => _p.playerB;
  static Color get playerAFill => _p.playerAFill;
  static Color get playerBFill => _p.playerBFill;

  // --- Komponen grafik ---------------------------------------------------
  static Color get chartGrid => _p.chartGrid;
  static Color get barTrack => surfaceContainer;
  static Color get barLoser => _p.barLoser;
  static Color get valueMuted => sageSoft;

  // --- Gradient ----------------------------------------------------------
  static LinearGradient get verdictGradient => _p.verdictGradient;
  static LinearGradient get forestGradient => _p.forestGradient;
  static LinearGradient get bottomFade => _p.bottomFade;
  static LinearGradient get accentGradient => _p.accentGradient;

  // --- Bayangan ----------------------------------------------------------
  static List<BoxShadow> get cardShadow => _p.cardShadow;
  static List<BoxShadow> get islandShadow => _p.islandShadow;
  static List<BoxShadow> get buttonShadow => _p.buttonShadow;

  // ======================================================================
  // Palet gelap (default)
  // ======================================================================
  static const _Palette _dark = _Palette(
    canvas: Color(0xFF080C09),
    surface: Color(0xFF111813),
    surfaceLow: Color(0xFF0C120D),
    surfaceContainer: Color(0xFF18221A),
    surfaceHigh: Color(0xFF1E2A20),
    surfaceHighest: Color(0xFF243126),
    ink: Color(0xFFF3F8EC),
    forest: Color(0xFF17231A),
    onForest: Color(0xFFF3F8EC),
    onForestMuted: Color(0xFF9AB394),
    sage: Color(0xFFA8BFA2),
    sageSoft: Color(0xFF8DA687),
    lime: Color(0xFFC8F26C),
    onAccent: Color(0xFF0A120B),
    primaryFixed: Color(0xFF22331F),
    secondaryFixed: Color(0xFF1E3A21),
    secondaryContainer: Color(0xFF1B2A1D),
    onSurface: Color(0xFFDFE8D9),
    onSurfaceVariant: Color(0xFFAAB9A5),
    error: Color(0xFFFF9E97),
    errorContainer: Color(0xFF3B1512),
    success: Color(0xFF7EDC8C),
    shapPositive: Color(0xFF7EDC8C),
    shapNegative: Color(0xFFFF9E97),
    outline: Color(0xFF6F816C),
    outlineVariant: Color(0xFF2B382C),
    cardBorder: Color(0xFF27352A),
    playerB: Color(0xFF6FD8C8),
    playerAFill: Color(0x2EC8F26C),
    playerBFill: Color(0x4D6FD8C8),
    chartGrid: Color(0x1FFFFFFF),
    barLoser: Color(0xFF3A4A3B),
    verdictGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x1FC8F26C), Color(0xFF111813)],
    ),
    forestGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1D2F22), Color(0xFF0E1711)],
    ),
    bottomFade: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00080C09), Color(0xFF080C09)],
    ),
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD8FF8A), Color(0xFFC8F26C)],
    ),
    cardShadow: [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 24,
        offset: Offset(0, 8),
        spreadRadius: -4,
      ),
    ],
    islandShadow: [
      BoxShadow(
        color: Color(0x8C000000),
        blurRadius: 36,
        offset: Offset(0, 16),
        spreadRadius: -6,
      ),
      BoxShadow(
        color: Color(0x14C8F26C),
        blurRadius: 24,
        offset: Offset(0, -2),
        spreadRadius: -8,
      ),
    ],
    buttonShadow: [
      BoxShadow(
        color: Color(0x4DC8F26C),
        blurRadius: 24,
        offset: Offset(0, 10),
        spreadRadius: -6,
      ),
    ],
  );

  // ======================================================================
  // Palet terang
  // ======================================================================
  static const _Palette _light = _Palette(
    canvas: Color(0xFFF2F7EA),
    surface: Color(0xFFFFFFFF),
    surfaceLow: Color(0xFFE9F1E1),
    surfaceContainer: Color(0xFFE3ECDB),
    surfaceHigh: Color(0xFFD7E3CE),
    surfaceHighest: Color(0xFFC9D9BF),
    ink: Color(0xFF10210F),
    forest: Color(0xFF1E3A1F),
    onForest: Color(0xFFF3F8EC),
    onForestMuted: Color(0xFFC3D8BA),
    sage: Color(0xFF4F6650),
    sageSoft: Color(0xFF6C816C),
    lime: Color(0xFFB9E85B),
    onAccent: Color(0xFF0A120B),
    primaryFixed: Color(0xFFDDEBCF),
    secondaryFixed: Color(0xFFCFE4C9),
    secondaryContainer: Color(0xFFE4EFDD),
    onSurface: Color(0xFF172518),
    onSurfaceVariant: Color(0xFF4E6250),
    error: Color(0xFFB3261E),
    errorContainer: Color(0xFFF9DEDC),
    success: Color(0xFF2E7D32),
    shapPositive: Color(0xFF2E7D32),
    shapNegative: Color(0xFFB3261E),
    outline: Color(0xFF7C8E7C),
    outlineVariant: Color(0xFFC9D6C3),
    cardBorder: Color(0xFFD5E0CF),
    playerB: Color(0xFF178C7A),
    playerAFill: Color(0x2E9BCC3F),
    playerBFill: Color(0x4D2AA391),
    chartGrid: Color(0x1F10210F),
    barLoser: Color(0xFFC2D0BB),
    verdictGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x269BCC3F), Color(0xFFFFFFFF)],
    ),
    forestGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2B4D2C), Color(0xFF1B341D)],
    ),
    bottomFade: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00F2F7EA), Color(0xFFF2F7EA)],
    ),
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD8FF8A), Color(0xFFB9E85B)],
    ),
    cardShadow: [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 20,
        offset: Offset(0, 8),
        spreadRadius: -6,
      ),
    ],
    islandShadow: [
      BoxShadow(
        color: Color(0x22000000),
        blurRadius: 30,
        offset: Offset(0, 14),
        spreadRadius: -8,
      ),
    ],
    buttonShadow: [
      BoxShadow(
        color: Color(0x339BCC3F),
        blurRadius: 20,
        offset: Offset(0, 8),
        spreadRadius: -8,
      ),
    ],
  );
}

class _Palette {
  const _Palette({
    required this.canvas,
    required this.surface,
    required this.surfaceLow,
    required this.surfaceContainer,
    required this.surfaceHigh,
    required this.surfaceHighest,
    required this.ink,
    required this.forest,
    required this.onForest,
    required this.onForestMuted,
    required this.sage,
    required this.sageSoft,
    required this.lime,
    required this.onAccent,
    required this.primaryFixed,
    required this.secondaryFixed,
    required this.secondaryContainer,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.error,
    required this.errorContainer,
    required this.success,
    required this.shapPositive,
    required this.shapNegative,
    required this.outline,
    required this.outlineVariant,
    required this.cardBorder,
    required this.playerB,
    required this.playerAFill,
    required this.playerBFill,
    required this.chartGrid,
    required this.barLoser,
    required this.verdictGradient,
    required this.forestGradient,
    required this.bottomFade,
    required this.accentGradient,
    required this.cardShadow,
    required this.islandShadow,
    required this.buttonShadow,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceLow;
  final Color surfaceContainer;
  final Color surfaceHigh;
  final Color surfaceHighest;
  final Color ink;
  final Color forest;
  final Color onForest;
  final Color onForestMuted;
  final Color sage;
  final Color sageSoft;
  final Color lime;
  final Color onAccent;
  final Color primaryFixed;
  final Color secondaryFixed;
  final Color secondaryContainer;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color error;
  final Color errorContainer;
  final Color success;
  final Color shapPositive;
  final Color shapNegative;
  final Color outline;
  final Color outlineVariant;
  final Color cardBorder;
  final Color playerB;
  final Color playerAFill;
  final Color playerBFill;
  final Color chartGrid;
  final Color barLoser;
  final LinearGradient verdictGradient;
  final LinearGradient forestGradient;
  final LinearGradient bottomFade;
  final LinearGradient accentGradient;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> islandShadow;
  final List<BoxShadow> buttonShadow;
}

/// Pembantu transparansi: `AppColors.lime.a(0.1)`.
/// Memakai withAlpha agar aman di semua versi Flutter.
extension ColorAlpha on Color {
  Color a(double opacity) => withAlpha((opacity.clamp(0, 1) * 255).round());
}

/// Durasi animasi.
class AppMotion {
  const AppMotion._();
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration chart = Duration(milliseconds: 700);
  static const Duration reveal = Duration(milliseconds: 900);
}
