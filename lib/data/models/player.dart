import 'player_feature.dart';
import 'radar_metric.dart';

/// Data mentah statistik per-90 menit untuk satu pemain.
class SeasonMetrics {
  const SeasonMetrics({
    this.goals = 0,
    this.assists = 0,
    this.shots = 0,
    this.onTarget = 0,
    this.crossing = 0,
    this.tackles = 0,
    this.interceptions = 0,
    this.xgPer90 = 0,
    this.xaPer90 = 0,
  });

  final double goals;
  final double assists;
  final double shots;
  final double onTarget;
  final double crossing;
  final double tackles;
  final double interceptions;
  final double xgPer90;
  final double xaPer90;

  /// Jumlah gol + assist per 90 menit.
  double get goalContribution => goals + assists;

  double valueOf(RadarMetric metric) {
    switch (metric) {
      case RadarMetric.goals:
        return goals;
      case RadarMetric.assists:
        return assists;
      case RadarMetric.shots:
        return shots;
      case RadarMetric.crossing:
        return crossing;
      case RadarMetric.tackles:
        return tackles;
      case RadarMetric.interceptions:
        return interceptions;
    }
  }

  factory SeasonMetrics.fromJson(Map<String, dynamic> json) => SeasonMetrics(
        goals: _d(json['goals']),
        assists: _d(json['assists']),
        shots: _d(json['shots']),
        onTarget: _d(json['on_target']),
        crossing: _d(json['crossing']),
        tackles: _d(json['tackles']),
        interceptions: _d(json['interceptions']),
        xgPer90: _d(json['xg_per90']),
        xaPer90: _d(json['xa_per90']),
      );

  static double _d(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}

/// Representasi satu pemain beserta seluruh atribut scouting-nya.
class Player {
  const Player({
    required this.id,
    required this.name,
    required this.club,
    required this.position,
    required this.age,
    required this.stats,
    this.league = '',
    this.positionShort = '',
    this.nationality = '',
    this.height = 0,
    this.foot = 'Right',
    this.contractUntil = '',
    this.marketValue = 0,
    this.trendPercent = 0,
    this.minutesPlayed = 0,
    this.matches = 0,
    this.metrics = const SeasonMetrics(),
    this.percentiles = const {},
    this.imageUrl,
  });

  final String id;
  final String name;
  final String club;

  /// Posisi lengkap, mis. "Right Winger".
  final String position;

  /// Kode posisi singkat, mis. "RW".
  final String positionShort;

  final String league;
  final String nationality;
  final int age;
  final int height;

  /// Kaki dominan: "Left" / "Right" / "Both".
  final String foot;

  /// Kontrak berakhir, mis. "June 2030".
  final String contractUntil;

  /// Nilai pasar dalam juta Euro.
  final double marketValue;

  /// Perubahan nilai pasar (persen), mis. 25 berarti +25%.
  final double trendPercent;

  final int minutesPlayed;
  final int matches;

  /// Nilai tiap fitur (0-100) untuk perhitungan KNN.
  final Map<PlayerFeature, double> stats;

  /// Statistik per-90 mentah.
  final SeasonMetrics metrics;

  /// Persentil tiap sumbu radar (0-100).
  final Map<RadarMetric, double> percentiles;

  /// Foto pemain (opsional). Bila kosong, UI memakai inisial.
  final String? imageUrl;

  double stat(PlayerFeature feature) => stats[feature] ?? 0;

  double percentile(RadarMetric metric) => percentiles[metric] ?? 0;

  /// Rata-rata seluruh fitur, dipakai sebagai "overall".
  double get overall {
    if (stats.isEmpty) return 0;
    final total = stats.values.reduce((a, b) => a + b);
    return total / stats.length;
  }

  /// Inisial nama, mis. "Lamine Yamal" -> "LY".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Label nilai pasar, mis. 150 -> "€150M", 0.5 -> "€500K".
  String get marketValueLabel {
    if (marketValue <= 0) return '-';
    if (marketValue >= 1) return '€${marketValue.toStringAsFixed(0)}M';
    return '€${(marketValue * 1000).toStringAsFixed(0)}K';
  }

  /// Label tren, mis. "+25%".
  String get trendLabel {
    final sign = trendPercent >= 0 ? '+' : '';
    return '$sign${trendPercent.toStringAsFixed(0)}%';
  }

  /// Contoh "RW · 18y" untuk badge kartu.
  String get shortBadge => '$positionShort · ${age}y';

  /// Kelompok posisi: GK, DF, MF, atau FW. Dipakai untuk filter cepat.
  String get positionGroup {
    final code = positionShort.toUpperCase();
    if (code.startsWith('GK') || position.toLowerCase().contains('goalkeeper')) {
      return 'GK';
    }
    if (code.startsWith('CB') ||
        code.startsWith('LB') ||
        code.startsWith('RB') ||
        code.startsWith('DF') ||
        position.toLowerCase().contains('back')) {
      return 'DF';
    }
    if (code.startsWith('ST') ||
        code.startsWith('CF') ||
        code.startsWith('LW') ||
        code.startsWith('RW') ||
        code.startsWith('FW') ||
        position.toLowerCase().contains('winger') ||
        position.toLowerCase().contains('forward') ||
        position.toLowerCase().contains('striker')) {
      return 'FW';
    }
    return 'MF';
  }

  /// Nilai xG + xA per 90 menit.
  double get xgXaPer90 => metrics.xgPer90 + metrics.xaPer90;

  List<double> toVector(List<PlayerFeature> features) =>
      features.map(stat).toList(growable: false);

  Player copyWith({
    String? name,
    String? club,
    String? position,
    String? positionShort,
    String? league,
    int? age,
    double? marketValue,
    Map<PlayerFeature, double>? stats,
    Map<RadarMetric, double>? percentiles,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      club: club ?? this.club,
      position: position ?? this.position,
      positionShort: positionShort ?? this.positionShort,
      league: league ?? this.league,
      nationality: nationality,
      age: age ?? this.age,
      height: height,
      foot: foot,
      contractUntil: contractUntil,
      marketValue: marketValue ?? this.marketValue,
      trendPercent: trendPercent,
      minutesPlayed: minutesPlayed,
      matches: matches,
      stats: stats ?? this.stats,
      metrics: metrics,
      percentiles: percentiles ?? this.percentiles,
      imageUrl: imageUrl,
    );
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    final rawStats = (json['stats'] as Map?)?.cast<String, dynamic>() ?? {};
    final stats = <PlayerFeature, double>{};
    for (final entry in rawStats.entries) {
      final feature = PlayerFeature.fromJsonKey(entry.key);
      if (feature != null) stats[feature] = _d(entry.value);
    }

    final rawPercentiles =
        (json['percentiles'] as Map?)?.cast<String, dynamic>() ?? {};
    final percentiles = <RadarMetric, double>{};
    for (final entry in rawPercentiles.entries) {
      final metric = RadarMetric.fromJsonKey(entry.key);
      if (metric != null) percentiles[metric] = _d(entry.value);
    }

    return Player(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Tanpa Nama',
      club: json['club'] as String? ?? '-',
      position: json['position'] as String? ?? '-',
      positionShort: json['position_short'] as String? ?? '',
      league: json['league'] as String? ?? '',
      nationality: json['nationality'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      foot: json['foot'] as String? ?? 'Right',
      contractUntil: json['contract_until'] as String? ?? '',
      marketValue: _d(json['market_value']),
      trendPercent: _d(json['trend_percent']),
      minutesPlayed: (json['minutes_played'] as num?)?.toInt() ?? 0,
      matches: (json['matches'] as num?)?.toInt() ?? 0,
      stats: stats,
      metrics: SeasonMetrics.fromJson(
        (json['metrics'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      percentiles: percentiles,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'club': club,
        'position': position,
        'position_short': positionShort,
        'league': league,
        'nationality': nationality,
        'age': age,
        'height': height,
        'foot': foot,
        'contract_until': contractUntil,
        'market_value': marketValue,
        'trend_percent': trendPercent,
        'minutes_played': minutesPlayed,
        'matches': matches,
        'stats': {
          for (final entry in stats.entries) entry.key.jsonKey: entry.value,
        },
        'percentiles': {
          for (final entry in percentiles.entries) entry.key.jsonKey: entry.value,
        },
        'image_url': imageUrl,
      };

  static double _d(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  @override
  String toString() => 'Player($id, $name)';
}
