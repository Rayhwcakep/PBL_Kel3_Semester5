import 'player_feature.dart';
import 'scouting_result.dart';

/// Paket lengkap balasan endpoint `POST /scout` dan `POST /scout/tactic`.
///
/// Struktur JSON dari `backend/app/schemas/scouting.py`:
/// ```json
/// {
///   "archetype": "ST",
///   "tactic": null,
///   "k": 5,
///   "target": { "npg_p90": 0.62, "sh_p90": 3.5 },
///   "target_percentiles": { "npg_p90": 78.4, "sh_p90": 71.0 },
///   "results": [
///     {
///       "rank": 1,
///       "similarity": 62.7,
///       "distance": 0.48,
///       "player": { "id": "7", "name": "...", "stats": { } },
///       "why": "lebih: Tembakan +14 | kurang: Tekel -11"
///     }
///   ]
/// }
/// ```
class ScoutResponse {
  const ScoutResponse({
    required this.archetype,
    required this.k,
    required this.results,
    this.tactic,
    this.target = const {},
    this.targetPercentiles = const {},
  });

  /// Arketipe yang dipakai backend saat mencari.
  final String archetype;

  /// Preset taktik, hanya terisi bila memakai `/scout/tactic`.
  final String? tactic;

  /// Jumlah kandidat yang diminta.
  final int k;

  /// Profil target dalam satuan per-90 nyata.
  final Map<PlayerFeature, double> target;

  /// Profil target dalam persentil 0-100.
  final Map<PlayerFeature, double> targetPercentiles;

  /// Daftar pemain hasil pencarian, sudah terurut dari yang paling mirip.
  final List<ScoutingResult> results;

  ScoutResponse copyWith({List<ScoutingResult>? results}) => ScoutResponse(
    archetype: archetype,
    k: k,
    tactic: tactic,
    target: target,
    targetPercentiles: targetPercentiles,
    results: results ?? this.results,
  );

  factory ScoutResponse.fromJson(Map<String, dynamic> json) {
    final results = <ScoutingResult>[];
    for (final item in (json['results'] as List? ?? const [])) {
      results.add(
        ScoutingResult.fromJson((item as Map).cast<String, dynamic>()),
      );
    }

    return ScoutResponse(
      archetype: json['archetype'] as String? ?? '',
      tactic: json['tactic'] as String?,
      k: (json['k'] as num?)?.toInt() ?? results.length,
      target: _features(json['target']),
      targetPercentiles: _features(json['target_percentiles']),
      results: results,
    );
  }

  static Map<PlayerFeature, double> _features(Object? raw) {
    final map = <PlayerFeature, double>{};
    if (raw is! Map) return map;
    for (final entry in raw.cast<String, dynamic>().entries) {
      final feature = PlayerFeature.fromJsonKey(entry.key);
      if (feature == null) continue;
      final value = entry.value;
      map[feature] = value is num ? value.toDouble() : 0;
    }
    return map;
  }
}
