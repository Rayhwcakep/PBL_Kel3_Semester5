import 'json_value.dart';
import 'player.dart';

/// Satu baris tabel kecocokan pemain dengan taktik.
class TacticFitRow {
  const TacticFitRow({
    required this.feature,
    required this.label,
    required this.value,
    required this.targetValue,
    required this.pctPlayer,
    required this.pctTarget,
    required this.goodPlayer,
    required this.goodTarget,
    required this.deltaGood,
    required this.contribution,
    required this.share,
    required this.verdict,
  });

  final String feature;
  final String label;

  /// Statistik pemain per-90.
  final double value;

  /// Statistik target per-90 (hasil terjemahan persentil).
  final double targetValue;

  /// Persentil pemain (0-100).
  final double pctPlayer;

  /// Persentil target (0-100).
  final double pctTarget;

  /// Persentil pemain setelah arah logika diterapkan.
  final double goodPlayer;

  /// Persentil target setelah arah logika diterapkan.
  final double goodTarget;

  /// Selisih setelah arah logika diterapkan (positif = melebihi target).
  final double deltaGood;

  /// Kontribusi statistik ini ke jarak terhadap target.
  final double contribution;

  /// Porsi terhadap total jarak (0-1).
  final double share;

  /// `kelebihan`, `kekurangan`, `sesuai`, `beda profil`, atau `netral`.
  final String verdict;

  factory TacticFitRow.fromJson(Map<String, dynamic> json) {
    return TacticFitRow(
      feature: asString(json['feature']),
      label: asString(json['label']),
      value: asDouble(json['value']),
      targetValue: asDouble(json['target_value']),
      pctPlayer: asDouble(json['pct_player']),
      pctTarget: asDouble(json['pct_target']),
      goodPlayer: asDouble(json['good_player']),
      goodTarget: asDouble(json['good_target']),
      deltaGood: asDouble(json['delta_good']),
      contribution: asDouble(json['contrib']),
      share: asDouble(json['share']),
      verdict: asString(json['verdict']),
    );
  }
}

/// Entri daftar `over` / `under`: statistik yang melebihi atau kurang dari
/// target. Backend hanya mengirim kolom yang perlu ditampilkan.
class TacticFitGap {
  const TacticFitGap({
    required this.feature,
    required this.label,
    required this.pctPlayer,
    required this.pctTarget,
    required this.deltaGood,
  });

  final String feature;
  final String label;
  final double pctPlayer;
  final double pctTarget;
  final double deltaGood;

  factory TacticFitGap.fromJson(Map<String, dynamic> json) {
    return TacticFitGap(
      feature: asString(json['feature']),
      label: asString(json['label']),
      pctPlayer: asDouble(json['pct_player']),
      pctTarget: asDouble(json['pct_target']),
      deltaGood: asDouble(json['delta_good']),
    );
  }
}

/// Balasan `GET /players/{id}/fit`: seberapa cocok seorang pemain dengan
/// sebuah taktik.
///
/// Endpoint ini mengembalikan objek tanpa skema Pydantic, jadi bentuknya
/// mengikuti `tactic_service.fit_report` di backend.
class TacticFit {
  const TacticFit({
    required this.player,
    required this.similarity,
    required this.isOnTarget,
    this.tactic,
    this.targetPercentiles = const {},
    this.rows = const [],
    this.over = const [],
    this.under = const [],
  });

  final Player player;

  /// Skor kecocokan 0-100.
  final double similarity;

  /// `true` bila minimal satu statistik sudah sesuai target.
  final bool isOnTarget;

  /// Preset taktik yang dipakai, `null` bila memakai slider manual.
  final String? tactic;

  /// Target persentil per statistik (0-100), kunci = [PlayerFeature.jsonKey].
  final Map<String, double> targetPercentiles;

  /// Rincian semua statistik arketipe, terurut dari kontribusi terbesar.
  final List<TacticFitRow> rows;

  /// Statistik yang melebihi target.
  final List<TacticFitGap> over;

  /// Statistik yang kurang dari target.
  final List<TacticFitGap> under;

  factory TacticFit.fromJson(Map<String, dynamic> json) {
    List<TacticFitGap> gaps(Object? raw) => [
      for (final item in asJsonList(raw)) TacticFitGap.fromJson(item),
    ];

    return TacticFit(
      player: Player.fromJson(asJsonMap(json['player'])),
      similarity: asDouble(json['similarity']),
      isOnTarget: json['tepat_sasaran'] == true,
      tactic: json['tactic'] as String?,
      targetPercentiles: asNumberMap(json['target_percentiles']),
      rows: [
        for (final item in asJsonList(json['rows'])) TacticFitRow.fromJson(item),
      ],
      over: gaps(json['over']),
      under: gaps(json['under']),
    );
  }
}
