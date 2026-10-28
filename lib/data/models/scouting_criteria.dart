import 'player_feature.dart';

/// Cara mengurutkan hasil pencarian.
enum ScoutSortBy {
  similarity('Similarity'),
  value('Value'),
  age('Age');

  const ScoutSortBy(this.label);

  final String label;
}

/// Kriteria pencarian pemain yang diisi pengguna pada form scouting.
///
/// Dikirim sebagai body JSON ke endpoint `POST /scout`.
class ScoutingCriteria {
  ScoutingCriteria({
    Map<PlayerFeature, double>? values,
    this.basePlayerId,
    this.position,
    this.league,
    this.maxAge,
    this.maxValue,
    this.sortBy = ScoutSortBy.similarity,
    this.topK = 5,
  }) : values =
           values ??
           {for (final feature in PlayerFeature.values) feature: 60.0};

  /// Nilai target tiap fitur (0 - 100).
  final Map<PlayerFeature, double> values;

  /// Pemain acuan (anchor) bila mencari pemain yang mirip.
  final String? basePlayerId;

  /// Filter posisi, `null` = semua posisi.
  final String? position;

  /// Filter liga, `null` = semua liga.
  final String? league;

  /// Filter umur maksimal, `null` = tanpa batas.
  final int? maxAge;

  /// Filter nilai pasar maksimal (juta Euro), `null` = tanpa batas.
  final double? maxValue;

  final ScoutSortBy sortBy;

  /// Jumlah kandidat terdekat yang diminta dari KNN.
  final int topK;

  double valueOf(PlayerFeature feature) => values[feature] ?? 0;

  ScoutingCriteria copyWith({
    Map<PlayerFeature, double>? values,
    String? basePlayerId,
    bool clearBasePlayer = false,
    String? position,
    bool clearPosition = false,
    String? league,
    bool clearLeague = false,
    int? maxAge,
    bool clearMaxAge = false,
    double? maxValue,
    bool clearMaxValue = false,
    ScoutSortBy? sortBy,
    int? topK,
  }) {
    return ScoutingCriteria(
      values: values ?? this.values,
      basePlayerId: clearBasePlayer
          ? null
          : (basePlayerId ?? this.basePlayerId),
      position: clearPosition ? null : (position ?? this.position),
      league: clearLeague ? null : (league ?? this.league),
      maxAge: clearMaxAge ? null : (maxAge ?? this.maxAge),
      maxValue: clearMaxValue ? null : (maxValue ?? this.maxValue),
      sortBy: sortBy ?? this.sortBy,
      topK: topK ?? this.topK,
    );
  }

  Map<String, dynamic> toJson() => {
    'criteria': {
      for (final entry in values.entries) entry.key.jsonKey: entry.value,
    },
    'base_player_id': basePlayerId,
    'position': position,
    'league': league,
    'max_age': maxAge,
    'max_value': maxValue,
    'sort_by': sortBy.name,
    'top_k': topK,
  };
}
