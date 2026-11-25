/// Helper format angka agar tampilan konsisten.
class NumberFormatUtil {
  const NumberFormatUtil._();

  /// Membulatkan ke [fractionDigits] desimal sebagai teks.
  static String fixed(double value, {int fractionDigits = 0}) =>
      value.toStringAsFixed(fractionDigits);

  /// Mengubah skor 0-1 menjadi persentase, contoh `0.923` -> `92%`.
  static String percent(double value, {int fractionDigits = 0}) =>
      '${(value * 100).toStringAsFixed(fractionDigits)}%';

  /// Menampilkan angka dengan tanda plus untuk nilai positif.
  /// Dipakai pada grafik SHAP, contoh `+0.12` / `-0.08`.
  static String signed(double value, {int fractionDigits = 3}) {
    final text = value.toStringAsFixed(fractionDigits);
    return value > 0 ? '+$text' : text;
  }

  /// Persentase bertanda untuk pengaruh SHAP, contoh `+9.1%` / `-11.2%`.
  ///
  /// Satu format dipakai grafik SHAP dan layar Player Insight supaya angka
  /// yang sama tidak tampil berbeda di dua tempat.
  static String signedPercent(double value, {int fractionDigits = 1}) {
    final text = value.abs().toStringAsFixed(fractionDigits);
    return '${value < 0 ? '-' : '+'}$text%';
  }

  /// Skor SHAP bertanda, contoh `+0.12` / `-0.08`.
  static String signedShap(double value, {int fractionDigits = 2}) {
    final text = value.abs().toStringAsFixed(fractionDigits);
    return '${value < 0 ? '-' : '+'}$text';
  }
}
