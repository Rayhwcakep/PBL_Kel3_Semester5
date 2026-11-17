import 'json_value.dart';
import 'player.dart';

/// Satu baris penilaian statistik hasil SHAP.
class ExplainContribution {
  const ExplainContribution({
    required this.feature,
    required this.label,
    required this.value,
    required this.percentile,
    required this.betterThanPct,
    required this.shapValue,
    required this.effectPct,
    required this.verdict,
  });

  /// Kunci statistik (`npg_p90`) atau variabel konteks (`Age`, `ctx_liga`).
  final String feature;

  /// Nama tampilan dari backend, mis. "Gol non-penalti".
  final String label;

  /// Nilai statistik per-90. Variabel konteks mengirim 0 karena satuannya
  /// berbeda dan tidak ditampilkan sebagai angka statistik.
  final double value;

  /// Persentil di antara pemain searketipe (0-100).
  final double percentile;

  /// Lebih baik dari berapa persen pemain searketipe (0-100).
  final double betterThanPct;

  /// Kontribusi SHAP pada log nilai pasar.
  final double shapValue;

  /// Pengaruh ke nilai pasar dalam persen.
  final double effectPct;

  /// `kelebihan`, `kekurangan`, `netral`, `diabaikan`, atau `konteks`.
  final String verdict;

  bool get isStrength => verdict == 'kelebihan';
  bool get isWeakness => verdict == 'kekurangan';

  factory ExplainContribution.fromJson(Map<String, dynamic> json) {
    return ExplainContribution(
      feature: asString(json['feature']),
      label: asString(json['label']),
      value: asDouble(json['value']),
      percentile: asDouble(json['percentile']),
      betterThanPct: asDouble(json['better_than_pct']),
      shapValue: asDouble(json['shap_value']),
      effectPct: asDouble(json['effect_pct']),
      verdict: asString(json['verdict']),
    );
  }
}

/// Balasan `GET /players/{id}/explain`.
///
/// Struktur JSON dari `backend/app/schemas/scouting.py` (`ExplainResponse`):
/// ```json
/// {
///   "player": { "id": "7", "name": "...", "stats": { } },
///   "strengths": [
///     { "feature": "crs_p90", "label": "Umpan silang", "value": 2.16,
///       "percentile": 93.0, "better_than_pct": 93.0, "shap_value": 0.08,
///       "effect_pct": 9.1, "verdict": "kelebihan" }
///   ],
///   "weaknesses": [ ],
///   "context": [ { "feature": "Age", "verdict": "konteks" } ],
///   "summary": "Matthis Abline (Striker, 22 tahun). ..."
/// }
/// ```
class PlayerExplain {
  const PlayerExplain({
    required this.player,
    required this.summary,
    this.strengths = const [],
    this.weaknesses = const [],
    this.context = const [],
  });

  final Player player;

  /// Statistik yang mendorong nilai pasar ke atas.
  final List<ExplainContribution> strengths;

  /// Statistik yang menahan nilai pasar.
  final List<ExplainContribution> weaknesses;

  /// Pengaruh usia, menit main, dan liga. Bukan kemampuan bermain.
  final List<ExplainContribution> context;

  /// Ringkasan satu paragraf siap tampil.
  final String summary;

  factory PlayerExplain.fromJson(Map<String, dynamic> json) {
    List<ExplainContribution> rows(Object? raw) => [
      for (final item in asJsonList(raw)) ExplainContribution.fromJson(item),
    ];

    return PlayerExplain(
      player: Player.fromJson(asJsonMap(json['player'])),
      strengths: rows(json['strengths']),
      weaknesses: rows(json['weaknesses']),
      context: rows(json['context']),
      summary: asString(json['summary']),
    );
  }
}
