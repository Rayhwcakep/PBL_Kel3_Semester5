import 'player_feature.dart';

/// Sumbu grafik radar profil pemain (persentil 0-100).
///
/// Jumlah sumbu mengikuti arketipe: 10 statistik untuk pemain lapangan dan
/// 5 statistik untuk kiper. Backend menyebut pilihan ini `hexagon_axes`;
/// di aplikasi seluruh statistik arketipe dipakai supaya tidak ada data
/// yang dibuang.
class RadarMetric {
  const RadarMetric._();

  /// Sepuluh sumbu pemain lapangan.
  static const List<PlayerFeature> outfield = PlayerFeature.outfield;

  /// Lima sumbu kiper.
  static const List<PlayerFeature> goalkeeper = PlayerFeature.goalkeeper;

  /// Sumbu sesuai arketipe pemain. `'GK'` memakai sumbu kiper.
  static List<PlayerFeature> axesFor(String archetype) =>
      PlayerFeature.forArchetype(archetype);
}
