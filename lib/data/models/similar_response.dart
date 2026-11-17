import 'json_value.dart';
import 'player.dart';

/// Satu tetangga terdekat pada `GET /players/{id}/similar`.
class SimilarNeighbor {
  const SimilarNeighbor({
    required this.player,
    required this.similarity,
    required this.distance,
    required this.rank,
    required this.closerThanPct,
  });

  final Player player;

  /// Skor kemiripan 0-100 dari backend.
  final double similarity;

  /// Jarak KNN. Semakin kecil semakin mirip.
  final double distance;

  /// Peringkat tetangga (1 = paling mirip).
  final int rank;

  /// Lebih dekat dari berapa persen pemain searketipe (0-100).
  final double closerThanPct;

  factory SimilarNeighbor.fromJson(Map<String, dynamic> json) {
    return SimilarNeighbor(
      player: Player.fromJson(asJsonMap(json['player'])),
      similarity: asDouble(json['similarity']),
      distance: asDouble(json['distance']),
      rank: asInt(json['rank']),
      closerThanPct: asDouble(json['closer_than_pct']),
    );
  }
}

/// Selisih satu statistik yang menjelaskan mengapa dua pemain mirip atau
/// berbeda.
class NeighborReason {
  const NeighborReason({
    required this.feature,
    required this.label,
    required this.a,
    required this.b,
    required this.pctA,
    required this.pctB,
    required this.contribution,
    required this.share,
  });

  final String feature;
  final String label;

  /// Nilai statistik pada pemain acuan.
  final double a;

  /// Nilai statistik pada tetangga.
  final double b;

  /// Persentil statistik pada pemain acuan (0-100).
  final double pctA;

  /// Persentil statistik pada tetangga (0-100).
  final double pctB;

  /// Kontribusi ke jarak kuadrat.
  final double contribution;

  /// Porsi terhadap total jarak (0-1).
  final double share;

  factory NeighborReason.fromJson(Map<String, dynamic> json) {
    return NeighborReason(
      feature: asString(json['feature']),
      label: asString(json['label']),
      a: asDouble(json['a']),
      b: asDouble(json['b']),
      pctA: asDouble(json['pct_a']),
      pctB: asDouble(json['pct_b']),
      contribution: asDouble(json['contribution']),
      share: asDouble(json['share']),
    );
  }
}

/// Balasan `GET /players/{id}/similar` (`SimilarResponse` di backend).
class SimilarPlayers {
  const SimilarPlayers({
    required this.player,
    required this.sameArchetype,
    this.neighbors = const [],
    this.similarBecause = const [],
    this.differentBecause = const [],
  });

  /// Pemain acuan.
  final Player player;

  final bool sameArchetype;

  /// Tetangga terdekat, sudah terurut dari yang paling mirip.
  final List<SimilarNeighbor> neighbors;

  /// Statistik yang paling menyamakan pemain acuan dengan tetangga terdekat.
  final List<NeighborReason> similarBecause;

  /// Statistik yang paling membedakan keduanya.
  final List<NeighborReason> differentBecause;

  factory SimilarPlayers.fromJson(Map<String, dynamic> json) {
    List<NeighborReason> reasons(Object? raw) => [
      for (final item in asJsonList(raw)) NeighborReason.fromJson(item),
    ];

    return SimilarPlayers(
      player: Player.fromJson(asJsonMap(json['player'])),
      sameArchetype: json['same_archetype'] == true,
      neighbors: [
        for (final item in asJsonList(json['neighbors']))
          SimilarNeighbor.fromJson(item),
      ],
      similarBecause: reasons(json['similar_because']),
      differentBecause: reasons(json['different_because']),
    );
  }
}
