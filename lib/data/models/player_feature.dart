/// Arah hubungan sebuah statistik dengan kualitas permainan.
///
/// Diambil dari `good_dir` pada
/// `backend/app/ml/artifacts/feature_names.json`, sehingga UI dan backend
/// memakai arah yang sama.
enum FeatureDirection {
  /// Makin tinggi makin baik, mis. gol per 90 menit.
  higherIsBetter,

  /// Makin tinggi makin buruk, mis. pelanggaran dan kebobolan.
  lowerIsBetter,

  /// Tidak dinilai baik atau buruk, mis. jumlah penyelamatan.
  neutral,
}

/// Statistik per-90 menit yang benar-benar dipakai model backend.
///
/// [jsonKey] harus sama dengan kunci pada `stats` dan `percentiles` di
/// respons FastAPI (`backend/app/schemas/player.py`). Sepuluh nilai pertama
/// adalah statistik pemain lapangan, lima nilai terakhir khusus kiper.
enum PlayerFeature {
  npgP90(
    'npg_p90',
    'Gol non-penalti',
    'gol tanpa penalti per 90 menit',
    FeatureDirection.higherIsBetter,
  ),
  astP90(
    'ast_p90',
    'Assist',
    'assist per 90 menit',
    FeatureDirection.higherIsBetter,
  ),
  shP90(
    'sh_p90',
    'Tembakan',
    'tembakan per 90 menit',
    FeatureDirection.higherIsBetter,
  ),
  sotP90(
    'sot_p90',
    'Tembakan on target',
    'tembakan tepat sasaran per 90 menit',
    FeatureDirection.higherIsBetter,
  ),
  crsP90(
    'crs_p90',
    'Umpan silang',
    'umpan silang per 90 menit',
    FeatureDirection.higherIsBetter,
  ),
  intP90(
    'int_p90',
    'Intersep',
    'intersep per 90 menit',
    FeatureDirection.higherIsBetter,
  ),
  tklwP90(
    'tklw_p90',
    'Tekel berhasil',
    'tekel berhasil per 90 menit',
    FeatureDirection.higherIsBetter,
  ),
  flsP90(
    'fls_p90',
    'Pelanggaran dibuat',
    'pelanggaran yang dibuat per 90 menit',
    FeatureDirection.lowerIsBetter,
  ),
  fldP90(
    'fld_p90',
    'Pelanggaran diterima',
    'pelanggaran yang diterima per 90 menit',
    FeatureDirection.higherIsBetter,
  ),
  offP90(
    'off_p90',
    'Offside',
    'kali terjebak offside per 90 menit',
    FeatureDirection.lowerIsBetter,
  ),
  savePct(
    'save_pct',
    'Save %',
    'persentase tembakan yang diselamatkan',
    FeatureDirection.higherIsBetter,
  ),
  gaP90(
    'ga_p90',
    'Kebobolan',
    'gol kemasukan per 90 menit',
    FeatureDirection.lowerIsBetter,
  ),
  csPct(
    'cs_pct',
    'Clean sheet %',
    'persentase laga tanpa kebobolan',
    FeatureDirection.higherIsBetter,
  ),
  savesP90(
    'saves_p90',
    'Penyelamatan',
    'penyelamatan per 90 menit',
    FeatureDirection.neutral,
  ),
  sotaP90(
    'sota_p90',
    'Tembakan dihadapi',
    'tembakan yang dihadapi per 90 menit',
    FeatureDirection.neutral,
  );

  const PlayerFeature(
    this.jsonKey,
    this.label,
    this.description,
    this.direction,
  );

  /// Kunci pada JSON backend.
  final String jsonKey;

  /// Label singkat untuk UI (bahasa Indonesia).
  final String label;

  /// Penjelasan singkat fitur, dipakai pada kalimat dossier.
  final String description;

  /// Arah nilai terhadap kualitas permainan.
  final FeatureDirection direction;

  /// Sepuluh statistik pemain lapangan, urut seperti sumbu radar.
  static const List<PlayerFeature> outfield = [
    npgP90,
    astP90,
    shP90,
    sotP90,
    crsP90,
    intP90,
    tklwP90,
    flsP90,
    fldP90,
    offP90,
  ];

  /// Lima statistik kiper, urut seperti sumbu radar.
  static const List<PlayerFeature> goalkeeper = [
    savePct,
    gaP90,
    csPct,
    savesP90,
    sotaP90,
  ];

  /// Semua fitur dalam urutan tetap.
  static List<PlayerFeature> get all => PlayerFeature.values;

  /// `true` bila statistik ini hanya dipakai untuk kiper.
  bool get isGoalkeeperStat => goalkeeper.contains(this);

  /// `true` bila nilai kecil justru lebih baik.
  bool get isInverted => direction == FeatureDirection.lowerIsBetter;

  /// Statistik yang dipakai arketipe [archetype] (`'GK'` atau kode lain).
  static List<PlayerFeature> forArchetype(String archetype) =>
      archetype == 'GK' ? goalkeeper : outfield;

  /// Mencari fitur dari [jsonKey]. Mengembalikan `null` bila tidak ada.
  static PlayerFeature? fromJsonKey(String key) {
    for (final feature in PlayerFeature.values) {
      if (feature.jsonKey == key) return feature;
    }
    return null;
  }
}
