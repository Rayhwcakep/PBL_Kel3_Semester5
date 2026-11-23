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

  /// Jumlah sumbu yang diharapkan untuk tiap kelompok pemain.
  static const int outfieldAxisCount = 10;
  static const int goalkeeperAxisCount = 5;

  /// Label ringkas agar sepuluh sumbu tetap terbaca tanpa saling menimpa.
  static const Map<PlayerFeature, String> _compactLabels = {
    PlayerFeature.npgP90: 'Gol',
    PlayerFeature.astP90: 'Assist',
    PlayerFeature.shP90: 'Tembakan',
    PlayerFeature.sotP90: 'On Target',
    PlayerFeature.crsP90: 'Silang',
    PlayerFeature.intP90: 'Intersep',
    PlayerFeature.tklwP90: 'Tekel',
    PlayerFeature.flsP90: 'Pelanggaran',
    PlayerFeature.fldP90: 'Dilanggar',
    PlayerFeature.offP90: 'Offside',
    PlayerFeature.savePct: 'Save %',
    PlayerFeature.gaP90: 'Kebobolan',
    PlayerFeature.csPct: 'Clean Sheet',
    PlayerFeature.savesP90: 'Penyelamatan',
    PlayerFeature.sotaP90: 'Tembakan Dihadapi',
  };

  /// `true` bila pemain memakai sumbu kiper.
  ///
  /// Selain kode arketipe `GK`, kelompok posisi `GK` juga dikenali supaya
  /// pemain dari payload lama/parsial tetap memakai lima sumbu kiper dan
  /// tidak menghasilkan sumbu kosong.
  static bool isGoalkeeper(String archetype, {String positionGroup = ''}) {
    final key = archetype.trim().toUpperCase();
    if (key == 'GK') return true;
    return positionGroup.trim().toUpperCase() == 'GK';
  }

  /// Sumbu sesuai arketipe pemain: 10 untuk pemain lapangan, 5 untuk kiper.
  static List<PlayerFeature> axesFor(
    String archetype, {
    String positionGroup = '',
  }) {
    return isGoalkeeper(archetype, positionGroup: positionGroup)
        ? goalkeeper
        : outfield;
  }

  /// Label satu fitur. [compact] memakai label pendek untuk grafik radar.
  static String labelFor(PlayerFeature feature, {bool compact = false}) {
    if (!compact) return feature.label;
    return _compactLabels[feature] ?? feature.label;
  }

  /// Label untuk seluruh [axes], urut sesuai sumbu.
  static List<String> labelsFor(
    Iterable<PlayerFeature> axes, {
    bool compact = false,
  }) {
    return [for (final feature in axes) labelFor(feature, compact: compact)];
  }
}
