import 'player_feature.dart';

/// Satu baris penjelasan SHAP: seberapa besar sebuah fitur mendorong
/// (atau menahan) skor kecocokan seorang pemain.
///
/// Contoh payload JSON dari backend:
/// ```json
/// { "feature": "pace", "value": 88, "shap_value": 0.12 }
/// ```
class FeatureContribution {
  const FeatureContribution({
    required this.feature,
    required this.value,
    required this.shapValue,
  });

  final PlayerFeature feature;

  /// Nilai fitur pemain pada skala 0 - 100.
  final double value;

  /// Kontribusi SHAP. Positif menaikkan skor, negatif menurunkan.
  final double shapValue;

  bool get isPositive => shapValue >= 0;

  /// Besaran absolut untuk keperluan pengurutan / panjang bar.
  double get magnitude => shapValue.abs();

  factory FeatureContribution.fromJson(Map<String, dynamic> json) {
    final feature = PlayerFeature.fromJsonKey(json['feature'] as String? ?? '');
    return FeatureContribution(
      feature: feature ?? PlayerFeature.pace,
      value: (json['value'] as num?)?.toDouble() ?? 0,
      shapValue: (json['shap_value'] as num?)?.toDouble() ?? 0,
    );
  }
}
