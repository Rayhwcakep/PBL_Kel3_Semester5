import 'json_value.dart';
import 'player.dart';

/// Satu baris tabel perbandingan dua pemain.
class CompareRow {
  const CompareRow({
    required this.feature,
    required this.label,
    required this.a,
    required this.b,
    required this.pctA,
    required this.pctB,
    required this.gapPct,
    required this.gapGood,
    required this.winner,
    required this.relDiff,
    required this.dEffect,
  });

  final String feature;
  final String label;

  /// Statistik pemain A per-90.
  final double a;

  /// Statistik pemain B per-90.
  final double b;

  final double pctA;
  final double pctB;

  /// Selisih persentil (A - B).
  final double gapPct;

  /// Selisih setelah arah logika diterapkan (positif = A lebih baik).
  final double gapGood;

  /// `A`, `B`, `seimbang`, atau `tidak didukung model`.
  final String winner;

  /// Selisih relatif angka mentah (0-1).
  final double relDiff;

  /// Selisih dorongan nilai pasar (A - B).
  final double dEffect;

  bool get aWins => winner == 'A';
  bool get bWins => winner == 'B';
  bool get isTie => winner == 'seimbang';

  factory CompareRow.fromJson(Map<String, dynamic> json) {
    return CompareRow(
      feature: asString(json['feature']),
      label: asString(json['label']),
      a: asDouble(json['a']),
      b: asDouble(json['b']),
      pctA: asDouble(json['pct_a']),
      pctB: asDouble(json['pct_b']),
      gapPct: asDouble(json['gap_pct']),
      gapGood: asDouble(json['gap_good']),
      winner: asString(json['winner']),
      relDiff: asDouble(json['rel_diff']),
      dEffect: asDouble(json['d_effect']),
    );
  }
}

/// Balasan `POST /compare` (`CompareResponse` di backend).
class CompareReport {
  const CompareReport({
    required this.a,
    required this.b,
    required this.sameArchetype,
    this.warning,
    this.similarity,
    this.neighborRank,
    this.rows = const [],
    this.aBetter = const [],
    this.bBetter = const [],
    this.rawOnly = const [],
    this.summary = '',
  });

  final Player a;
  final Player b;

  /// `false` bila kedua pemain beda arketipe sehingga angkanya tidak
  /// sebanding.
  final bool sameArchetype;

  /// Peringatan backend saat arketipe berbeda.
  final String? warning;

  /// Kemiripan kedua pemain (0-100). Kosong bila arketipe berbeda.
  final double? similarity;

  /// Peringkat B sebagai tetangga A (0 = pemain yang sama).
  final int? neighborRank;

  /// Semua statistik yang dibandingkan.
  final List<CompareRow> rows;

  /// Statistik yang dimenangkan A.
  final List<CompareRow> aBetter;

  /// Statistik yang dimenangkan B.
  final List<CompareRow> bBetter;

  /// Selisih angka besar yang arahnya berlawanan dengan model nilai pasar,
  /// jadi jangan disebut keunggulan mutlak.
  final List<CompareRow> rawOnly;

  /// Ringkasan satu paragraf siap tampil.
  final String summary;

  factory CompareReport.fromJson(Map<String, dynamic> json) {
    List<CompareRow> rows(Object? raw) => [
      for (final item in asJsonList(raw)) CompareRow.fromJson(item),
    ];

    return CompareReport(
      a: Player.fromJson(asJsonMap(json['a'])),
      b: Player.fromJson(asJsonMap(json['b'])),
      sameArchetype: json['same_archetype'] == true,
      warning: json['warning'] as String?,
      similarity: json['similarity'] == null
          ? null
          : asDouble(json['similarity']),
      neighborRank: json['neighbor_rank'] == null
          ? null
          : asInt(json['neighbor_rank']),
      rows: rows(json['rows']),
      aBetter: rows(json['a_better']),
      bBetter: rows(json['b_better']),
      rawOnly: rows(json['raw_only']),
      summary: asString(json['summary']),
    );
  }
}
