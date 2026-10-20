import 'package:flutter/material.dart';

/// Palet warna design system "Pitch Naturalism" (Scoutify).
///
/// Nama diambil langsung dari DESIGN.md agar mudah ditelusuri.
class AppColors {
  const AppColors._();

  // --- Kanvas & permukaan ------------------------------------------------
  /// Latar utama aplikasi (Pastel Mint).
  static const Color canvas = Color(0xFFEFFEE0);

  /// Permukaan kartu (Crisp White).
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFEAF9DB);
  static const Color surfaceContainer = Color(0xFFE4F3D5);
  static const Color surfaceHigh = Color(0xFFDEEDD0);
  static const Color surfaceHighest = Color(0xFFD8E7CA);

  // --- Warna struktural --------------------------------------------------
  /// Teks judul & ikon bertekanan tinggi (hampir hitam hijau).
  static const Color ink = Color(0xFF001905);

  /// Dark Forest: tombol solid, kartu hero, penanda navigasi aktif.
  static const Color forest = Color(0xFF102F15);

  /// Varian teks di atas Dark Forest.
  static const Color onForestMuted = Color(0xFF769976);

  /// Sage: teks sekunder, ikon non-aktif, garis mikro.
  static const Color sage = Color(0xFF4D6537);
  static const Color sageSoft = Color(0xFF728C5A);

  /// Pale Lime: sorotan, badge persentil, filter aktif.
  static const Color lime = Color(0xFFEAF1B1);

  /// Hijau pastel untuk avatar & aksen lembut.
  static const Color primaryFixed = Color(0xFFC7ECC5);
  static const Color secondaryFixed = Color(0xFFCFECB2);
  static const Color secondaryContainer = Color(0xFFCCE9AF);

  // --- Teks --------------------------------------------------------------
  static const Color onSurface = Color(0xFF131F0D);
  static const Color onSurfaceVariant = Color(0xFF424841);

  // --- Status ------------------------------------------------------------
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color success = Color(0xFF2E7D32);

  /// Warna grafik SHAP.
  static const Color shapPositive = Color(0xFF2E7D32);
  static const Color shapNegative = Color(0xFFBA1A1A);

  // --- Garis -------------------------------------------------------------
  static const Color outline = Color(0xFF737970);
  static const Color outlineVariant = Color(0xFFC2C8BE);

  /// Garis Sage tipis untuk batas kartu (25% alpha).
  static const Color cardBorder = Color(0x40728C5A);

  // --- Identitas pemain (A vs B) ----------------------------------------
  /// Pemain A: garis radar, bar, dan badge.
  static const Color playerA = forest;

  /// Pemain B: lebih terang dari A agar kontras di radar & bar.
  static const Color playerB = sageSoft;

  /// Isi polygon radar (semi-transparan).
  static const Color playerAFill = Color(0x24102F15); // forest ~14%
  static const Color playerBFill = Color(0x66EAF1B1); // lime ~40%

  // --- Komponen grafik ---------------------------------------------------
  /// Garis grid & sumbu radar.
  static const Color chartGrid = Color(0x33728C5A); // sageSoft ~20%

  /// Track bar perbandingan (latar bar kosong).
  static const Color barTrack = surfaceContainer;

  /// Bar pemain yang kalah pada satu metrik.
  static const Color barLoser = outlineVariant;

  /// Teks angka metrik yang tidak menang.
  static const Color valueMuted = sageSoft;

  // --- Gradient ----------------------------------------------------------
  /// Kartu AI Verdict: tint lime halus menuju putih.
  static const LinearGradient verdictGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xBFEAF1B1), surface], // lime ~75% -> putih
  );

  /// Kartu hero / kotak kesimpulan gelap.
  static const LinearGradient forestGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A4220), forest],
  );

  /// Fade di belakang CTA melayang agar konten tidak bertabrakan.
  static const LinearGradient bottomFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00EFFEE0), canvas],
  );

  // --- Bayangan (ambient herbal) ----------------------------------------
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0F102F15),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> islandShadow = [
    BoxShadow(
      color: Color(0x29102F15),
      blurRadius: 36,
      offset: Offset(0, 16),
      spreadRadius: -6,
    ),
  ];

  /// Bayangan tombol solid (CTA).
  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x4D102F15),
      blurRadius: 20,
      offset: Offset(0, 10),
      spreadRadius: -6,
    ),
  ];
}

/// Pembantu transparansi: `AppColors.forest.a(0.1)`.
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

