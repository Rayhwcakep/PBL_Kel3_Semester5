import 'package:flutter/material.dart';

/// Palet warna design system "Pitch Naturalism" (Scoutify) — varian **Dark**.
///
/// Struktur token sengaja dipertahankan sama dengan versi light agar seluruh
/// widget tinggal mengikuti. Versi gelap memakai kanvas hijau-arang pekat,
/// permukaan bertingkat (elevation), dan aksen lime instrumen.
class AppColors {
  const AppColors._();

  // --- Kanvas & permukaan ------------------------------------------------
  /// Latar utama aplikasi (Charcoal Pitch).
  static const Color canvas = Color(0xFF080C09);

  /// Permukaan kartu (Elevated Moss).
  static const Color surface = Color(0xFF111813);
  static const Color surfaceLow = Color(0xFF0C120D);
  static const Color surfaceContainer = Color(0xFF18221A);
  static const Color surfaceHigh = Color(0xFF1E2A20);
  static const Color surfaceHighest = Color(0xFF243126);

  // --- Warna struktural --------------------------------------------------
  /// Teks judul & ikon bertekanan tinggi (hampir putih hangat).
  static const Color ink = Color(0xFFF3F8EC);

  /// Dark Forest: blok hero, sheet gelap, tombol solid.
  static const Color forest = Color(0xFF17231A);

  /// Teks utama di atas Dark Forest.
  static const Color onForest = Color(0xFFF3F8EC);

  /// Varian teks redup di atas Dark Forest.
  static const Color onForestMuted = Color(0xFF9AB394);

  /// Sage: teks sekunder, ikon non-aktif, garis mikro.
  static const Color sage = Color(0xFFA8BFA2);
  static const Color sageSoft = Color(0xFF8DA687);

  /// Pale Lime: aksen utama, sorotan, badge persentil, filter aktif.
  static const Color lime = Color(0xFFC8F26C);

  /// Teks/ikon di atas [lime] dan permukaan aksen terang.
  static const Color onAccent = Color(0xFF0A120B);

  /// Hijau gelap untuk avatar & aksen lembut.
  static const Color primaryFixed = Color(0xFF22331F);
  static const Color secondaryFixed = Color(0xFF1E3A21);
  static const Color secondaryContainer = Color(0xFF1B2A1D);

  // --- Teks --------------------------------------------------------------
  static const Color onSurface = Color(0xFFDFE8D9);
  static const Color onSurfaceVariant = Color(0xFFAAB9A5);

  // --- Status ------------------------------------------------------------
  static const Color error = Color(0xFFFF9E97);
  static const Color errorContainer = Color(0xFF3B1512);
  static const Color success = Color(0xFF7EDC8C);

  /// Warna grafik SHAP.
  static const Color shapPositive = Color(0xFF7EDC8C);
  static const Color shapNegative = Color(0xFFFF9E97);

  // --- Garis -------------------------------------------------------------
  static const Color outline = Color(0xFF6F816C);
  static const Color outlineVariant = Color(0xFF2B382C);

  /// Garis tipis untuk batas kartu di atas permukaan gelap.
  static const Color cardBorder = Color(0xFF27352A);

  // --- Identitas pemain (A vs B) ----------------------------------------
  /// Pemain A: garis radar, bar, dan badge (aksen lime).
  static const Color playerA = lime;

  /// Pemain B: teal terang agar kontras di atas kanvas gelap.
  static const Color playerB = Color(0xFF6FD8C8);

  /// Isi polygon radar (semi-transparan).
  static const Color playerAFill = Color(0x2EC8F26C); // lime ~18%
  static const Color playerBFill = Color(0x4D6FD8C8); // teal ~30%

  // --- Komponen grafik ---------------------------------------------------
  /// Garis grid & sumbu radar.
  static const Color chartGrid = Color(0x1FFFFFFF); // putih ~12%

  /// Track bar perbandingan (latar bar kosong).
  static const Color barTrack = surfaceContainer;

  /// Bar pemain yang kalah pada satu metrik.
  static const Color barLoser = Color(0xFF3A4A3B);

  /// Teks angka metrik yang tidak menang.
  static const Color valueMuted = sageSoft;

  // --- Gradient ----------------------------------------------------------
  /// Kartu AI Verdict: tint lime halus di atas permukaan gelap.
  static const LinearGradient verdictGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1FC8F26C), surface], // lime ~12% -> surface
  );

  /// Kartu hero / kotak kesimpulan gelap.
  static const LinearGradient forestGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D2F22), Color(0xFF0E1711)],
  );

  /// Fade di belakang CTA melayang agar konten tidak bertabrakan.
  static const LinearGradient bottomFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00080C09), canvas],
  );

  /// Sorotan aksen untuk tombol utama.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD8FF8A), lime],
  );

  // --- Bayangan (ambient gelap) ------------------------------------------
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> islandShadow = [
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
  ];

  /// Bayangan tombol solid (CTA) — pendaran aksen.
  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x4DC8F26C),
      blurRadius: 24,
      offset: Offset(0, 10),
      spreadRadius: -6,
    ),
  ];
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
