import 'dart:math' as math;

import '../mock/mock_players.dart';
import '../models/feature_contribution.dart';
import '../models/player.dart';
import '../models/player_feature.dart';
import '../models/scout_response.dart';
import '../models/scouting_criteria.dart';
import '../models/scouting_result.dart';
import 'scouting_service.dart';

/// Implementasi [ScoutingService] memakai data contoh.
///
/// Perhitungan KNN & SHAP di bawah ini hanya *tiruan* agar tampilan punya
/// data. Saat backend FastAPI siap, ganti ke `ApiScoutingService`
/// (lihat `AppConfig.useMockData`).
class MockScoutingService implements ScoutingService {
  MockScoutingService({this.latency = const Duration(milliseconds: 600)});

  /// Jeda buatan supaya indikator loading terlihat.
  final Duration latency;

  @override
  Future<List<Player>> fetchPlayers() async {
    await Future<void>.delayed(latency);
    return List<Player>.unmodifiable(mockPlayers);
  }

  @override
  Future<Player> fetchPlayer(String id) async {
    await Future<void>.delayed(latency);
    return mockPlayers.firstWhere((player) => player.id == id);
  }

  @override
  Future<ScoutResponse> scout(ScoutingCriteria criteria) async {
    await Future<void>.delayed(latency);

    final features = PlayerFeature.all;
    final queryValues = _resolveQuery(criteria);

    final candidates = mockPlayers.where((player) {
      if (criteria.basePlayerId != null && player.id == criteria.basePlayerId) {
        return false;
      }
      if (criteria.position != null && player.position != criteria.position) {
        return false;
      }
      if (criteria.league != null && player.league != criteria.league) {
        return false;
      }
      if (criteria.maxAge != null && player.age > criteria.maxAge!) return false;
      if (criteria.maxValue != null && player.marketValue > criteria.maxValue!) {
        return false;
      }
      return true;
    }).toList();

    final queryVector =
        features.map((f) => (queryValues[f] ?? 0) / 100).toList(growable: false);

    final scored = <ScoutingResult>[];
    for (final player in candidates) {
      final playerVector =
          player.toVector(features).map((v) => v / 100).toList(growable: false);
      final distance = _euclidean(queryVector, playerVector);
      final similarity = 1 / (1 + distance);
      scored.add(
        ScoutingResult(
          player: player,
          similarity: similarity,
          distance: distance,
          rank: 0,
        ),
      );
    }

    _sortScored(scored, criteria.sortBy);
    final top = scored.take(criteria.topK).toList();

    final base = scored.isEmpty
        ? 0.0
        : scored.map((r) => r.similarity).reduce((a, b) => a + b) / scored.length;

    final results = <ScoutingResult>[];
    for (var i = 0; i < top.length; i++) {
      final result = top[i];
      results.add(
        result.copyWith(
          rank: i + 1,
          baseValue: base,
          prediction: result.similarity,
          contributions: _fakeShap(result.player, queryValues, features),
        ),
      );
    }

    return ScoutResponse(k: criteria.topK, query: queryValues, results: results);
  }

  Map<PlayerFeature, double> _resolveQuery(ScoutingCriteria criteria) {
    if (criteria.basePlayerId != null) {
      for (final player in mockPlayers) {
        if (player.id == criteria.basePlayerId) {
          return {for (final f in PlayerFeature.values) f: player.stat(f)};
        }
      }
    }
    return criteria.values;
  }

  void _sortScored(List<ScoutingResult> scored, ScoutSortBy sortBy) {
    switch (sortBy) {
      case ScoutSortBy.similarity:
        scored.sort((a, b) => b.similarity.compareTo(a.similarity));
      case ScoutSortBy.value:
        scored.sort(
          (a, b) => b.player.marketValue.compareTo(a.player.marketValue),
        );
      case ScoutSortBy.age:
        scored.sort((a, b) => a.player.age.compareTo(b.player.age));
    }
  }

  double _euclidean(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }
    return math.sqrt(sum / a.length);
  }

  /// Menghasilkan kontribusi "mirip SHAP" agar grafik bisa diuji.
  List<FeatureContribution> _fakeShap(
    Player player,
    Map<PlayerFeature, double> queryValues,
    List<PlayerFeature> features,
  ) {
    final raw = <PlayerFeature, double>{};
    var total = 0.0;
    for (final feature in features) {
      final diff = (player.stat(feature) - (queryValues[feature] ?? 0)) / 100;
      raw[feature] = diff;
      total += diff.abs();
    }

    final contributions = <FeatureContribution>[];
    for (final feature in features) {
      final normalized = total == 0 ? 0.0 : (raw[feature]! / total) * 0.35;
      contributions.add(
        FeatureContribution(
          feature: feature,
          value: player.stat(feature),
          shapValue: normalized,
        ),
      );
    }
    return contributions;
  }
}
