import 'feature_contribution.dart';
import 'player_feature.dart';
import 'scouting_result.dart';

/// Paket lengkap balasan endpoint `POST /scout`.
///
/// Struktur JSON yang diharapkan dari backend FastAPI:
/// ```json
/// {
///   "k": 5,
///   "query": { "pace": 85, "shooting": 80, "...": 0 },
///   "results": [
///     {
///       "rank": 1,
///       "similarity": 0.93,
///       "distance": 0.07,
///       "player": { "id": "p001", "name": "...", "stats": { } }
///     }
///   ],
///   "explanations": [
///     {
///       "player_id": "p001",
///       "base_value": 0.42,
///       "prediction": 0.93,
///       "contributions": [
///         { "feature": "pace", "value": 88, "shap_value": 0.12 }
///       ]
///     }
///   ]
/// }
/// ```
class ScoutResponse {
  const ScoutResponse({
    required this.k,
    required this.results,
    this.query = const {},
  });

  /// Jumlah kandidat yang diminta.
  final int k;

  /// Nilai query yang dikembalikan backend (untuk validasi).
  final Map<PlayerFeature, double> query;

  /// Daftar pemain hasil pencarian, sudah terurut.
  final List<ScoutingResult> results;

  factory ScoutResponse.fromJson(Map<String, dynamic> json) {
    final explanations = <String, Map<String, dynamic>>{};
    for (final item in (json['explanations'] as List? ?? const [])) {
      final map = (item as Map).cast<String, dynamic>();
      final id = map['player_id'] as String?;
      if (id != null) explanations[id] = map;
    }

    final results = <ScoutingResult>[];
    for (final item in (json['results'] as List? ?? const [])) {
      final map = (item as Map).cast<String, dynamic>();
      final playerId = (map['player'] as Map?)?['id'] as String?;
      final explanation = playerId != null ? explanations[playerId] : null;

      final contributions = <FeatureContribution>[];
      for (final c in (explanation?['contributions'] as List? ?? const [])) {
        contributions.add(
          FeatureContribution.fromJson((c as Map).cast<String, dynamic>()),
        );
      }

      results.add(
        ScoutingResult.fromJson(
          map,
          contributions: contributions,
          baseValue: (explanation?['base_value'] as num?)?.toDouble() ?? 0,
          prediction: (explanation?['prediction'] as num?)?.toDouble() ?? 0,
        ),
      );
    }

    final query = <PlayerFeature, double>{};
    final rawQuery = (json['query'] as Map?)?.cast<String, dynamic>() ?? {};
    for (final entry in rawQuery.entries) {
      final feature = PlayerFeature.fromJsonKey(entry.key);
      if (feature != null) {
        query[feature] = (entry.value as num?)?.toDouble() ?? 0;
      }
    }

    return ScoutResponse(
      k: (json['k'] as num?)?.toInt() ?? results.length,
      query: query,
      results: results,
    );
  }
}
