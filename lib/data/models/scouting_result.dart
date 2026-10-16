import 'feature_contribution.dart';
import 'player.dart';

/// Hasil pencocokan satu pemain beserta skor dan penjelasan SHAP-nya.
class ScoutingResult {
  const ScoutingResult({
    required this.player,
    required this.similarity,
    required this.distance,
    required this.rank,
    this.baseValue = 0,
    this.prediction = 0,
    this.contributions = const [],
  });

  final Player player;

  /// Skor kemiripan 0 - 1 (semakin besar semakin cocok).
  final double similarity;

  /// Jarak KNN. Semakin kecil semakin mirip.
  final double distance;

  /// Peringkat hasil (dimulai dari 1).
  final int rank;

  /// Nilai dasar model (rata-rata prediksi) untuk perhitungan SHAP.
  final double baseValue;

  /// Nilai prediksi akhir model.
  final double prediction;

  /// Kontribusi tiap fitur terhadap skor (SHAP).
  final List<FeatureContribution> contributions;

  /// Kontribusi diurutkan dari yang paling berpengaruh.
  List<FeatureContribution> get sortedContributions {
    final list = [...contributions];
    list.sort((a, b) => b.magnitude.compareTo(a.magnitude));
    return list;
  }

  ScoutingResult copyWith({
    double? similarity,
    int? rank,
    double? baseValue,
    double? prediction,
    List<FeatureContribution>? contributions,
  }) {
    return ScoutingResult(
      player: player,
      similarity: similarity ?? this.similarity,
      distance: distance,
      rank: rank ?? this.rank,
      baseValue: baseValue ?? this.baseValue,
      prediction: prediction ?? this.prediction,
      contributions: contributions ?? this.contributions,
    );
  }

  factory ScoutingResult.fromJson(
    Map<String, dynamic> json, {
    List<FeatureContribution> contributions = const [],
    double baseValue = 0,
    double prediction = 0,
  }) {
    return ScoutingResult(
      player: Player.fromJson(
        (json['player'] as Map).cast<String, dynamic>(),
      ),
      similarity: (json['similarity'] as num?)?.toDouble() ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      baseValue: baseValue,
      prediction: prediction,
      contributions: contributions,
    );
  }
}
