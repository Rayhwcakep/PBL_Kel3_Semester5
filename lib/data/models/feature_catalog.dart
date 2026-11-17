import 'json_value.dart';

/// Metadata satu statistik yang dipakai model pada sebuah arketipe.
class ArchetypeFeature {
  const ArchetypeFeature({
    required this.key,
    required this.label,
    required this.goodDir,
    this.unit = 'per90',
    this.invert = false,
    this.weight = 1,
  });

  /// Kunci JSON statistik, mis. `npg_p90`.
  final String key;

  /// Nama tampilan statistik.
  final String label;

  /// Satuan: `per90` atau `percent`.
  final String unit;

  /// 1 = makin tinggi makin baik, -1 = makin tinggi makin buruk, 0 = netral.
  final int goodDir;

  /// `true` bila grafik harus dibalik (`good_dir = -1`).
  final bool invert;

  /// Bobot statistik ini pada jarak KNN arketipe.
  final double weight;

  factory ArchetypeFeature.fromJson(Map<String, dynamic> json) {
    return ArchetypeFeature(
      key: asString(json['key']),
      label: asString(json['label']),
      unit: asString(json['unit']).isEmpty ? 'per90' : asString(json['unit']),
      goodDir: asInt(json['good_dir']),
      invert: json['invert'] == true,
      weight: json['weight'] == null ? 1 : asDouble(json['weight']),
    );
  }
}

/// Satu sumbu grafik radar versi backend (`hexagon_axes`).
class HexagonAxis {
  const HexagonAxis({
    required this.label,
    required this.feature,
    this.invert = false,
  });

  final String label;

  /// Kunci JSON statistik, mis. `npg_p90`.
  final String feature;

  /// `true` bila nilai harus dibalik sebelum digambar.
  final bool invert;

  factory HexagonAxis.fromJson(Map<String, dynamic> json) {
    return HexagonAxis(
      label: asString(json['label']),
      feature: asString(json['feature']),
      invert: json['invert'] == true,
    );
  }
}

/// Satu arketipe pada `GET /meta/features`.
class ArchetypeInfo {
  const ArchetypeInfo({
    required this.key,
    required this.label,
    required this.players,
    this.features = const [],
  });

  /// Kode arketipe: `GK`, `CB`, `FB`, `DM`, `CM`, `AM`, `W`, `ST`.
  final String key;

  /// Nama tampilan, mis. "Striker".
  final String label;

  /// Jumlah pemain pada arketipe ini.
  final int players;

  final List<ArchetypeFeature> features;

  /// Nama tampilan sebuah statistik. Bila tidak dikenal, kuncinya
  /// dikembalikan apa adanya.
  String labelFor(String featureKey) {
    for (final feature in features) {
      if (feature.key == featureKey) return feature.label;
    }
    return featureKey;
  }

  factory ArchetypeInfo.fromJson(Map<String, dynamic> json) {
    return ArchetypeInfo(
      key: asString(json['key']),
      label: asString(json['label']),
      players: asInt(json['players']),
      features: [
        for (final item in asJsonList(json['features']))
          ArchetypeFeature.fromJson(item),
      ],
    );
  }
}

/// Balasan `GET /meta/features` (`MetadataResponse` di backend).
class FeatureCatalog {
  const FeatureCatalog({
    this.archetypes = const [],
    this.contextLabels = const {},
    this.minEffect = 0.03,
    this.minPctGap = 10,
    this.hexagonAxes = const {},
  });

  final List<ArchetypeInfo> archetypes;

  /// Nama tampilan variabel konteks, mis. `Age` -> "Usia".
  final Map<String, String> contextLabels;

  /// Ambang pengaruh SHAP agar disebut bermakna.
  final double minEffect;

  /// Ambang selisih persentil agar dua pemain disebut beda.
  final double minPctGap;

  /// Sumbu radar versi backend, mis. kunci `outfield` dan `GK`.
  final Map<String, List<HexagonAxis>> hexagonAxes;

  /// Mencari arketipe berdasarkan [key]. `null` bila tidak ada.
  ArchetypeInfo? archetype(String key) {
    for (final item in archetypes) {
      if (item.key == key) return item;
    }
    return null;
  }

  factory FeatureCatalog.fromJson(Map<String, dynamic> json) {
    final axes = <String, List<HexagonAxis>>{};
    for (final entry in asJsonMap(json['hexagon_axes']).entries) {
      axes[entry.key] = [
        for (final item in asJsonList(entry.value)) HexagonAxis.fromJson(item),
      ];
    }

    return FeatureCatalog(
      archetypes: [
        for (final item in asJsonList(json['archetypes']))
          ArchetypeInfo.fromJson(item),
      ],
      contextLabels: asStringMap(json['context_labels']),
      minEffect: json['min_effect'] == null ? 0.03 : asDouble(json['min_effect']),
      minPctGap: json['min_pct_gap'] == null
          ? 10
          : asDouble(json['min_pct_gap']),
      hexagonAxes: axes,
    );
  }
}
