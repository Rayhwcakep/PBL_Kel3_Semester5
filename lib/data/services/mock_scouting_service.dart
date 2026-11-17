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
/// Perhitungan KNN di bawah ini hanya *tiruan* agar tampilan punya data,
/// tetapi bentuk balasannya sama dengan backend: skor kemiripan 0-100,
/// profil target, dan alasan `why`. Saat backend FastAPI siap, ganti ke
/// `ApiScoutingService` (lihat `AppConfig.useMockData`).
class MockScoutingService implements ScoutingService {
  MockScoutingService({this.latency = const Duration(milliseconds: 600)});

  /// Jeda buatan supaya indikator loading terlihat.
  final Duration latency;

  /// Jarak yang dianggap "tipikal" antar pemain searketipe, dipakai supaya
  /// skor kemiripan jatuh di sekitar 37 seperti rumus backend.
  static const double _typicalDistance = 0.35;

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

    final features = PlayerFeature.forArchetype(criteria.archetype);
    // Slider taktik memakai persentil, pencarian biasa memakai per-90 nyata.
    final byPercentile = criteria.isTacticSearch;
    final targets = byPercentile ? (criteria.sliders ?? {}) : criteria.values;

    final candidates = mockPlayers.where((player) {
      if (player.archetype != criteria.archetype) return false;
      if (criteria.basePlayerId != null && player.id == criteria.basePlayerId) {
        return false;
      }
      if (criteria.league != null && player.league != criteria.league) {
        return false;
      }
      if (criteria.minAge != null && player.age < criteria.minAge!) {
        return false;
      }
      if (criteria.maxAge != null && player.age > criteria.maxAge!) {
        return false;
      }
      if (criteria.maxValue != null && player.marketValue > criteria.maxValue!) {
        return false;
      }
      return true;
    }).toList();

    double valueOf(Player player, PlayerFeature feature) => byPercentile
        ? player.percentile(feature)
        : player.stat(feature);

    final targetVector = features
        .map((feature) => targets[feature] ?? 0)
        .toList(growable: false);

    final scored = <(Player, double)>[];
    for (final player in candidates) {
      final vector = features
          .map((feature) => valueOf(player, feature))
          .toList(growable: false);
      scored.add((player, _euclidean(targetVector, vector)));
    }
    scored.sort((a, b) => a.$2.compareTo(b.$2));

    final results = <ScoutingResult>[];
    final top = scored.take(criteria.topK).toList();
    for (var i = 0; i < top.length; i++) {
      final (player, distance) = top[i];
      results.add(
        ScoutingResult(
          player: player,
          similarity: 100 * math.exp(-distance / _typicalDistance),
          distance: distance,
          rank: i + 1,
          why: _reason(features, targets, player, valueOf),
          contributions: _fakeShap(features, targets, player, valueOf),
        ),
      );
    }

    return ScoutResponse(
      archetype: criteria.archetype,
      tactic: criteria.tactic,
      k: criteria.topK,
      target: {
        for (final feature in features)
          feature: byPercentile
              ? _medianOf(feature)
              : (targets[feature] ?? 0),
      },
      targetPercentiles: {
        for (final feature in features)
          feature: byPercentile
              ? (targets[feature] ?? 0)
              : _percentileOf(feature, targets[feature] ?? 0),
      },
      results: results,
    );
  }

  /// Median statistik arketipe (dipakai saat target persentil).
  double _medianOf(PlayerFeature feature) {
    final values = mockPlayers
        .where((player) => player.stats.containsKey(feature))
        .map((player) => player.stat(feature))
        .toList()
      ..sort();
    if (values.isEmpty) return 0;
    return values[values.length ~/ 2];
  }

  /// Persentil sebuah nilai di antara pemain contoh.
  double _percentileOf(PlayerFeature feature, double value) {
    final values = mockPlayers
        .where((player) => player.stats.containsKey(feature))
        .map((player) => player.stat(feature))
        .toList();
    if (values.isEmpty) return 50;
    final below = values.where((v) => v < value).length;
    final equal = values.where((v) => v == value).length;
    return 100 * (below + 0.5 * equal) / values.length;
  }

  /// Ringkasan satu baris, meniru `short_reason` backend.
  String _reason(
    List<PlayerFeature> features,
    Map<PlayerFeature, double> targets,
    Player player,
    double Function(Player, PlayerFeature) valueOf,
  ) {
    final over = <String>[];
    final under = <String>[];
    for (final feature in features) {
      final target = targets[feature];
      if (target == null) continue;
      // Arah logika dihormati: makin kecil makin baik berarti dibalik.
      final gap = feature.isInverted
          ? target - valueOf(player, feature)
          : valueOf(player, feature) - target;
      final label = '${feature.label} ${gap.toStringAsFixed(0)}';
      if (gap > 3) over.add(label);
      if (gap < -3) under.add(label);
    }
    if (over.isEmpty && under.isEmpty) return 'sesuai target';
    final parts = <String>[];
    if (over.isNotEmpty) parts.add('lebih: ${over.take(2).join(', ')}');
    if (under.isNotEmpty) parts.add('kurang: ${under.take(2).join(', ')}');
    return parts.join(' | ');
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
    List<PlayerFeature> features,
    Map<PlayerFeature, double> targets,
    Player player,
    double Function(Player, PlayerFeature) valueOf,
  ) {
    final raw = <PlayerFeature, double>{};
    var total = 0.0;
    for (final feature in features) {
      final diff = valueOf(player, feature) - (targets[feature] ?? 0);
      raw[feature] = diff;
      total += diff.abs();
    }

    return [
      for (final feature in features)
        FeatureContribution(
          feature: feature,
          value: player.stat(feature),
          shapValue: total == 0 ? 0 : (raw[feature]! / total) * 0.35,
        ),
    ];
  }
}
