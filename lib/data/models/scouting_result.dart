import 'feature_contribution.dart';
import 'player.dart';

/// Hasil pencocokan satu pemain beserta skor dan alasannya.
///
/// Cocok untuk `ScoutingResultOut` pada `backend/app/schemas/scouting.py`.
class ScoutingResult {
  const ScoutingResult({
    required this.player,
    required this.similarity,
    required this.distance,
    required this.rank,
    this.why,
    this.contributions = const [],
  });

  final Player player;

  /// Skor kemiripan **0-100**: `100 × exp(−jarak / jarak_tipikal)`.
  /// Sekitar 37 pada jarak tipikal, mendekati 100 untuk pemain sangat mirip.
  final double similarity;

  /// Jarak KNN. Semakin kecil semakin mirip.
  final double distance;

  /// Peringkat hasil (dimulai dari 1).
  final int rank;

  /// Ringkasan selisih terhadap target, mis.
  /// `"lebih: Assist +14 | kurang: Tekel -11"`.
  final String? why;

  /// Kontribusi tiap statistik (SHAP) bila tersedia.
  ///
  /// `POST /scout` tidak mengirimkannya, jadi kosong untuk hasil pencarian;
  /// `GET /players/{id}/explain` yang mengisinya.
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
    String? why,
    List<FeatureContribution>? contributions,
  }) {
    return ScoutingResult(
      player: player,
      similarity: similarity ?? this.similarity,
      distance: distance,
      rank: rank ?? this.rank,
      why: why ?? this.why,
      contributions: contributions ?? this.contributions,
    );
  }

  factory ScoutingResult.fromJson(
    Map<String, dynamic> json, {
    List<FeatureContribution> contributions = const [],
  }) {
    return ScoutingResult(
      player: Player.fromJson((json['player'] as Map).cast<String, dynamic>()),
      similarity: (json['similarity'] as num?)?.toDouble() ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      why: json['why'] as String?,
      contributions: contributions,
    );
  }
}
