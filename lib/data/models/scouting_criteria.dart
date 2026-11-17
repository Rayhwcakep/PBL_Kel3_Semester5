import 'player_feature.dart';

/// Cara mengurutkan hasil pencarian.
///
/// Backend hanya mengurutkan berdasarkan jarak terdekat, jadi urutan lain
/// diterapkan di aplikasi setelah balasan diterima.
enum ScoutSortBy {
  similarity('Similarity'),
  value('Value'),
  age('Age');

  const ScoutSortBy(this.label);

  final String label;
}

/// Kriteria pencarian pemain yang diisi pengguna pada form scouting.
///
/// Ada dua bentuk target, sesuai dua endpoint backend:
///
/// - [values] berisi statistik **per-90 nyata** untuk `POST /scout`
///   (`ScoutRequest.criteria`).
/// - [sliders] berisi **persentil 0-100** untuk `POST /scout/tactic`
///   (`TacticScoutRequest.sliders`). Backend yang mengubah persentil menjadi
///   angka per-90 memakai sebaran arketipe.
///
/// Mengirim persentil ke `POST /scout` akan salah: backend membacanya sebagai
/// angka per-90 sehingga jarak menjadi sangat jauh dan semua skor jatuh ke 0.
class ScoutingCriteria {
  ScoutingCriteria({
    Map<PlayerFeature, double>? values,
    this.sliders,
    this.tactic,
    this.archetype = 'ST',
    this.basePlayerId,
    this.league,
    this.minAge,
    this.maxAge,
    this.maxValue,
    this.sortBy = ScoutSortBy.similarity,
    this.topK = 10,
  }) : values = values ?? {};

  /// Target statistik per-90 nyata. Hanya statistik yang diisi yang dinilai
  /// backend; sisanya memakai median arketipe.
  final Map<PlayerFeature, double> values;

  /// Target persentil 0-100. Bila diisi, pencarian memakai
  /// `POST /scout/tactic`.
  final Map<PlayerFeature, double>? sliders;

  /// Preset taktik dari `/meta/tactics` (opsional).
  final String? tactic;

  /// Kode arketipe pencarian: `GK`, `CB`, `FB`, `DM`, `CM`, `AM`, `W`, `ST`.
  /// Wajib ada karena backend menolak permintaan tanpanya.
  final String archetype;

  /// Pemain acuan (anchor) bila mencari pemain yang mirip.
  final String? basePlayerId;

  /// Filter liga, `null` = semua liga.
  final String? league;

  /// Filter umur minimal, `null` = tanpa batas.
  final int? minAge;

  /// Filter umur maksimal, `null` = tanpa batas.
  final int? maxAge;

  /// Filter nilai pasar maksimal (juta Euro), `null` = tanpa batas.
  final double? maxValue;

  final ScoutSortBy sortBy;

  /// Jumlah kandidat terdekat yang diminta dari KNN.
  final int topK;

  /// `true` bila pencarian memakai persentil taktik, bukan statistik nyata.
  bool get isTacticSearch => sliders != null || tactic != null;

  double valueOf(PlayerFeature feature) => values[feature] ?? 0;

  /// Arketipe untuk kelompok posisi pada layar Find by Tactic.
  ///
  /// Kelompok posisi hanya punya empat pilihan, sedangkan backend memakai
  /// delapan arketipe, jadi dipilih satu wakil yang paling umum.
  static String archetypeForPositionGroup(String? positionGroup) {
    switch (positionGroup) {
      case 'GK':
        return 'GK';
      case 'DF':
        return 'CB';
      case 'MF':
        return 'CM';
      case 'FW':
        return 'ST';
      default:
        return 'ST';
    }
  }

  ScoutingCriteria copyWith({
    Map<PlayerFeature, double>? values,
    Map<PlayerFeature, double>? sliders,
    bool clearSliders = false,
    String? tactic,
    bool clearTactic = false,
    String? archetype,
    String? basePlayerId,
    bool clearBasePlayer = false,
    String? league,
    bool clearLeague = false,
    int? minAge,
    bool clearMinAge = false,
    int? maxAge,
    bool clearMaxAge = false,
    double? maxValue,
    bool clearMaxValue = false,
    ScoutSortBy? sortBy,
    int? topK,
  }) {
    return ScoutingCriteria(
      values: values ?? this.values,
      sliders: clearSliders ? null : (sliders ?? this.sliders),
      tactic: clearTactic ? null : (tactic ?? this.tactic),
      archetype: archetype ?? this.archetype,
      basePlayerId: clearBasePlayer
          ? null
          : (basePlayerId ?? this.basePlayerId),
      league: clearLeague ? null : (league ?? this.league),
      minAge: clearMinAge ? null : (minAge ?? this.minAge),
      maxAge: clearMaxAge ? null : (maxAge ?? this.maxAge),
      maxValue: clearMaxValue ? null : (maxValue ?? this.maxValue),
      sortBy: sortBy ?? this.sortBy,
      topK: topK ?? this.topK,
    );
  }

  /// Body JSON untuk `POST /scout`.
  ///
  /// `sort_by` dan `base_player_id` tidak dikirim karena tidak dikenal
  /// backend; pemain acuan dikirim sebagai `exclude_id` supaya tidak muncul
  /// pada hasilnya sendiri.
  Map<String, dynamic> toJson() => {
    'archetype': archetype,
    'criteria': {
      for (final entry in values.entries) entry.key.jsonKey: entry.value,
    },
    'top_k': topK,
    ..._filters(),
  };

  /// Body JSON untuk `POST /scout/tactic`.
  Map<String, dynamic> toTacticJson() => {
    'archetype': archetype,
    'tactic': tactic,
    'sliders': {
      for (final entry in (sliders ?? const {}).entries)
        entry.key.jsonKey: entry.value,
    },
    'top_k': topK,
    'explain': true,
    ..._filters(),
  };

  /// Filter yang sama dipakai kedua endpoint.
  Map<String, dynamic> _filters() => {
    'league': league,
    'min_age': minAge,
    'max_age': maxAge,
    'max_value_eur': maxValue == null ? null : maxValue! * 1e6,
    'exclude_id': basePlayerId,
  };
}
