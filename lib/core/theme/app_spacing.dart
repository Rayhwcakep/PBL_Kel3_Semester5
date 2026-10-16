import 'package:flutter/material.dart';

/// Radius sudut mengikuti design system Pitch Naturalism.
class AppRadius {
  const AppRadius._();

  /// Kartu, sheet, dan modul metrik.
  static const double card = 24;

  /// Kontrol kecil (chip, input ringkas).
  static const double control = 16;

  /// Pill penuh untuk tombol, chip, dan navigasi.
  static const double pill = 9999;

  static const BorderRadius cardBorder = BorderRadius.all(Radius.circular(card));
  static const BorderRadius controlBorder =
      BorderRadius.all(Radius.circular(control));
  static const BorderRadius pillBorder =
      BorderRadius.all(Radius.circular(pill));
}

/// Ritme spasi 8pt.
class AppSpacing {
  const AppSpacing._();

  static const double gutter = 16;
  static const double margin = 20;

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Ruang bawah agar konten tidak tertutup nav island.
  static const double navClearance = 110;
}
