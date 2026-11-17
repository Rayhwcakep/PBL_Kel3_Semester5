import 'dart:math' as math;

import 'explain_response.dart';
import 'player_feature.dart';

/// Satu baris penjelasan SHAP: seberapa besar sebuah fitur mendorong
/// (atau menahan) skor kecocokan atau nilai pasar seorang pemain.
///
/// Mendukung payload asli dari `/explain`:
/// ```json
/// {
///   "feature": "npg_p90",
///   "label": "Gol non-penalti",
///   "value": 0.52,
///   "shap_value": 0.12,
///   "effect_pct": 12.75
/// }
/// ```
class FeatureContribution {
  const FeatureContribution({
    required this.feature,
    required this.value,
    required this.shapValue,
    this.effectPct = 0,
    String? label,
  }) : _label = label;

  final PlayerFeature feature;
  final String? _label;

  /// Nilai statistik pemain, dalam satuan aslinya (per 90 menit).
  final double value;

  /// Kontribusi SHAP pada log nilai pasar (dari `/explain`).
  /// Positif menaikkan skor/nilai pasar, negatif menurunkan.
  final double shapValue;

  /// Pengaruh ke nilai pasar dalam persen (dari `/explain` `effect_pct`).
  final double effectPct;

  /// Nama statistik Indonesia dari `/meta/features` atau bawaan [PlayerFeature].
  String get label => _label ?? feature.label;

  /// `true` jika kontribusi positif (menaikkan skor/nilai),
  /// `false` jika negatif (menurunkan skor/nilai).
  bool get isPositive => shapValue != 0 ? shapValue > 0 : effectPct >= 0;

  /// Besaran absolut untuk keperluan pengurutan dan panjang bar divergen.
  double get magnitude =>
      effectPct != 0 ? effectPct.abs() : shapValue.abs();

  factory FeatureContribution.fromJson(Map<String, dynamic> json) {
    final rawFeature = json['feature'] as String? ?? '';
    final feature = PlayerFeature.fromJsonKey(rawFeature);
    final shap = (json['shap_value'] as num?)?.toDouble() ?? 0.0;
    final effect = (json['effect_pct'] as num?)?.toDouble() ??
        (shap != 0 ? (math.exp(shap) - 1.0) * 100 : 0.0);
    final label = json['label'] as String?;

    return FeatureContribution(
      feature: feature ?? PlayerFeature.npgP90,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      shapValue: shap,
      effectPct: effect,
      label: label,
    );
  }

  /// Membuat [FeatureContribution] dari [ExplainContribution] hasil `GET /players/{id}/explain`.
  factory FeatureContribution.fromExplain(ExplainContribution explain) {
    final feature = PlayerFeature.fromJsonKey(explain.feature);
    return FeatureContribution(
      feature: feature ?? PlayerFeature.npgP90,
      value: explain.value,
      shapValue: explain.shapValue,
      effectPct: explain.effectPct,
      label: explain.label.isNotEmpty ? explain.label : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'feature': feature.jsonKey,
    'label': label,
    'value': value,
    'shap_value': shapValue,
    'effect_pct': effectPct,
  };
}
