import 'player_feature.dart';
import 'radar_metric.dart';

/// Variabel konteks pemain: keadaan tim dan menit bermain, bukan kemampuan.
///
/// Dipakai model nilai pasar di backend untuk menyesuaikan statistik dengan
/// situasi pemain, jadi ditampilkan terpisah dari statistik permainan.
class PlayerContext {
  const PlayerContext({
    this.startRate = 0,
    this.plusP90 = 0,
    this.cardP90 = 0,
  });

  /// Porsi pertandingan sebagai pemain inti (0-1).
  final double startRate;

  /// Selisih gol tim selama pemain bermain, per 90 menit.
  final double plusP90;

  /// Kartu per 90 menit.
  final double cardP90;

  factory PlayerContext.fromJson(Map<String, dynamic> json) => PlayerContext(
    startRate: _toDouble(json['start_rate']),
    plusP90: _toDouble(json['plus_p90']),
    cardP90: _toDouble(json['crd_p90']),
  );

  Map<String, dynamic> toJson() => {
    'start_rate': startRate,
    'plus_p90': plusP90,
    'crd_p90': cardP90,
  };
}

/// Statistik per-90 menit yang tampil pada kartu dan grafik.
///
/// Nama field dipertahankan agar layar Compare dan Player Detail tidak perlu
/// berubah; nilainya diisi dari statistik nyata backend.
class SeasonMetrics {
  const SeasonMetrics({
    this.goals = 0,
    this.assists = 0,
    this.shots = 0,
    this.onTarget = 0,
    this.crossing = 0,
    this.tackles = 0,
    this.interceptions = 0,
  });

  /// Gol non-penalti per 90 menit (`npg_p90`).
  final double goals;

  /// Assist per 90 menit (`ast_p90`).
  final double assists;

  /// Tembakan per 90 menit (`sh_p90`).
  final double shots;

  /// Tembakan on target per 90 menit (`sot_p90`).
  final double onTarget;

  /// Umpan silang per 90 menit (`crs_p90`).
  final double crossing;

  /// Tekel berhasil per 90 menit (`tklw_p90`).
  final double tackles;

  /// Intersep per 90 menit (`int_p90`).
  final double interceptions;

  /// Jumlah gol + assist per 90 menit.
  double get goalContribution => goals + assists;
}

/// Representasi satu pemain beserta seluruh statistik scouting-nya.
class Player {
  const Player({
    required this.id,
    required this.name,
    required this.club,
    required this.position,
    required this.age,
    required this.stats,
    this.archetype = '',
    this.positionGroup = '',
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
    this.percentiles = const {},
    this.context = const PlayerContext(),
    this.imageUrl,
  });

  final String id;
  final String name;
  final String club;

  /// Posisi lengkap, mis. "Right Winger".
  final String position;

  /// Kode arketipe dari backend: `GK`, `CB`, `FB`, `DM`, `CM`, `AM`, `W`,
  /// atau `ST`.
  final String archetype;

  /// Kelompok posisi: `GK`, `DF`, `MF`, atau `FW`.
  final String positionGroup;

  /// Kode posisi singkat, mis. "RW". Tidak dikirim backend, jadi boleh kosong.
  final String positionShort;

  final String league;
  final String nationality;
  final int age;
  final int height;

  /// Kaki dominan: "Left" / "Right" / "Both".
  final String foot;

  /// Kontrak berakhir, mis. "Jun 2028".
  final String contractUntil;

  /// Nilai pasar dalam juta Euro.
  final double marketValue;

  /// Perubahan nilai pasar satu tahun terakhir (persen), mis. 25 = +25%.
  final double trendPercent;

  final int minutesPlayed;
  final int matches;

  /// Statistik per-90 mentah, kunci mengikuti [PlayerFeature].
  final Map<PlayerFeature, double> stats;

  /// Persentil tiap statistik di antara pemain searketipe (0-100).
  final Map<PlayerFeature, double> percentiles;

  /// Variabel konteks dari backend.
  final PlayerContext context;

  /// Foto pemain (opsional). Bila kosong, UI memakai inisial.
  final String? imageUrl;

  bool get isGoalkeeper => archetype == 'GK' || positionGroup == 'GK';

  /// Statistik ringkas untuk kartu dan tabel Compare. Diturunkan dari
  /// [stats] supaya hanya ada satu sumber angka.
  SeasonMetrics get metrics => SeasonMetrics(
    goals: stat(PlayerFeature.npgP90),
    assists: stat(PlayerFeature.astP90),
    shots: stat(PlayerFeature.shP90),
    onTarget: stat(PlayerFeature.sotP90),
    crossing: stat(PlayerFeature.crsP90),
    tackles: stat(PlayerFeature.tklwP90),
    interceptions: stat(PlayerFeature.intP90),
  );

  /// Sumbu radar pemain ini: 10 untuk pemain lapangan, 5 untuk kiper.
  List<PlayerFeature> get radarAxes => RadarMetric.axesFor(archetype);

  double stat(PlayerFeature feature) => stats[feature] ?? 0;

  double percentile(PlayerFeature feature) => percentiles[feature] ?? 0;

  /// Nilai sumbu radar 0-100. Statistik yang makin kecil makin baik
  /// (pelanggaran, offside, kebobolan) dibalik supaya jarak dari pusat
  /// grafik selalu berarti "makin baik".
  double radarValue(PlayerFeature feature) {
    final value = percentile(feature).clamp(0, 100).toDouble();
    return feature.isInverted ? 100 - value : value;
  }

  /// Rata-rata persentil pada sumbu pemain ini (0-100).
  double get overall {
    final axes = radarAxes;
    if (axes.isEmpty) return 0;
    final total = axes.map(percentile).reduce((a, b) => a + b);
    return total / axes.length;
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
  String get shortBadge =>
      positionShort.isEmpty ? '${age}y' : '$positionShort · ${age}y';

  List<double> toVector(List<PlayerFeature> features) =>
      features.map(stat).toList(growable: false);

  Player copyWith({
    String? name,
    String? club,
    String? position,
    String? archetype,
    String? positionGroup,
    String? positionShort,
    String? league,
    int? age,
    double? marketValue,
    Map<PlayerFeature, double>? stats,
    Map<PlayerFeature, double>? percentiles,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      club: club ?? this.club,
      position: position ?? this.position,
      archetype: archetype ?? this.archetype,
      positionGroup: positionGroup ?? this.positionGroup,
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
      percentiles: percentiles ?? this.percentiles,
      context: context,
      imageUrl: imageUrl,
    );
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    final rawStats = _asMap(json['stats']);
    final stats = <PlayerFeature, double>{};
    for (final entry in rawStats.entries) {
      final feature = PlayerFeature.fromJsonKey(entry.key);
      if (feature != null) stats[feature] = _toDouble(entry.value);
    }

    final rawPercentiles = _asMap(json['percentiles']);
    final percentiles = <PlayerFeature, double>{};
    for (final entry in rawPercentiles.entries) {
      final feature = PlayerFeature.fromJsonKey(entry.key);
      if (feature != null) percentiles[feature] = _toDouble(entry.value);
    }

    return Player(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Tanpa Nama',
      club: json['club'] as String? ?? '-',
      position: json['position'] as String? ?? '-',
      archetype: json['archetype'] as String? ?? '',
      positionGroup: json['position_group'] as String? ?? '',
      positionShort: json['position_short'] as String? ?? '',
      league: json['league'] as String? ?? '',
      nationality: json['nationality'] as String? ?? '',
      age: (json['age'] as num?)?.round() ?? 0,
      height: (json['height'] as num?)?.round() ?? 0,
      foot: json['foot'] as String? ?? 'Right',
      contractUntil: _contractLabel(json['contract_until']),
      marketValue: _toDouble(json['market_value_eur']) / 1e6,
      trendPercent: _toDouble(json['value_growth_1y']) * 100,
      minutesPlayed: (json['minutes'] as num?)?.round() ?? 0,
      stats: stats,
      percentiles: percentiles,
      context: PlayerContext.fromJson(_asMap(json['context'])),
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'club': club,
    'position': position,
    'position_group': positionGroup,
    'archetype': archetype,
    'league': league,
    'age': age,
    'foot': foot,
    'contract_until': contractUntil,
    'market_value_eur': marketValue * 1e6,
    'value_growth_1y': trendPercent / 100,
    'minutes': minutesPlayed,
    'context': context.toJson(),
    'stats': {
      for (final entry in stats.entries) entry.key.jsonKey: entry.value,
    },
    'percentiles': {
      for (final entry in percentiles.entries) entry.key.jsonKey: entry.value,
    },
    'image_url': imageUrl,
  };

  @override
  String toString() => 'Player($id, $name)';
}

const List<String> _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// Mengubah "2028-06-30 00:00:00" menjadi "Jun 2028" agar enak dibaca.
String _contractLabel(Object? value) {
  if (value is! String || value.isEmpty) return '';
  final match = RegExp(r'^(\d{4})-(\d{2})').firstMatch(value);
  if (match == null) return value;
  final month = int.tryParse(match.group(2)!);
  if (month == null || month < 1 || month > 12) return value;
  return '${_monthNames[month - 1]} ${match.group(1)}';
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map) return value.cast<String, dynamic>();
  return const {};
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
