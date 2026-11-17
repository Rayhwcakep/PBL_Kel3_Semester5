import 'json_value.dart';
import 'player.dart';

/// Satu calon pengganti pada `GET /best-fit/{id}`.
class BestFitCandidate {
  const BestFitCandidate({
    required this.player,
    required this.similarity,
    required this.fit,
    required this.gain,
    required this.loss,
    required this.why,
  });

  final Player player;

  /// Skor kemiripan dengan pemain acuan (0-100).
  final double similarity;

  /// Skor kecocokan 0-100: gabungan kemiripan dan perbaikan bersih.
  final double fit;

  /// Porsi kebutuhan acuan yang berhasil ditutup (0-1).
  final double gain;

  /// Porsi kelebihan acuan yang harus dikorbankan (0-1).
  final double loss;

  /// Ringkasan siap tampil, mis. "Menutup: Gol non-penalti (+45) |
  /// Mengorbankan: -".
  final String why;

  factory BestFitCandidate.fromJson(Map<String, dynamic> json) {
    return BestFitCandidate(
      player: Player.fromJson(asJsonMap(json['player'])),
      similarity: asDouble(json['similarity']),
      fit: asDouble(json['fit']),
      gain: asDouble(json['gain']),
      loss: asDouble(json['loss']),
      why: asString(json['why']),
    );
  }
}

/// Balasan `GET /best-fit/{id}`: rekomendasi pemain yang menutup kekurangan
/// pemain acuan tanpa membuang kelebihannya.
class BestFit {
  const BestFit({
    required this.player,
    this.needs = const {},
    this.keep = const {},
    this.candidates = const [],
  });

  /// Pemain acuan.
  final Player player;

  /// Kekurangan acuan beserta bobotnya, kunci = [PlayerFeature.jsonKey].
  final Map<String, double> needs;

  /// Kelebihan acuan yang harus dijaga, kunci = [PlayerFeature.jsonKey].
  final Map<String, double> keep;

  /// Calon pengganti, sudah terurut dari skor kecocokan tertinggi.
  final List<BestFitCandidate> candidates;

  factory BestFit.fromJson(Map<String, dynamic> json) {
    return BestFit(
      player: Player.fromJson(asJsonMap(json['player'])),
      needs: asNumberMap(json['needs']),
      keep: asNumberMap(json['keep']),
      candidates: [
        for (final item in asJsonList(json['candidates']))
          BestFitCandidate.fromJson(item),
      ],
    );
  }
}
