import 'player_feature.dart';

/// Satu baris penjelasan SHAP: seberapa besar sebuah fitur mendorong
/// (atau menahan) skor kecocokan seorang pemain.
///
/// Contoh payload JSON dari backend:
/// ```json
/// { "feature": "npg_p90", "value": 0.52, "shap_value": 0.12 }
/// ```
class FeatureContribution {
  const FeatureContribution({
    required this.feature,
    required this.value,
    required this.shapValue,
  });

  final PlayerFeature feature;

  /// Nilai statistik pemain, dalam satuan aslinya (per 90 menit).
  final double value;

  /// Kontribusi SHAP. Positif menaikkan skor, negatif menurunkan.
  final double shapValue;

  bool get isPositive => shapValue >= 0;

  /// Besaran absolut untuk keperluan pengurutan / panjang bar.
  double get magnitude => shapValue.abs();

  factory FeatureContribution.fromJson(Map<String, dynamic> json) {
    final feature = PlayerFeature.fromJsonKey(json['feature'] as String? ?? '');
    return FeatureContribution(
      feature: feature ?? PlayerFeature.npgP90,
      value: (json['value'] as num?)?.toDouble() ?? 0,
      shapValue: (json['shap_value'] as num?)?.toDouble() ?? 0,
    );
  }
}
