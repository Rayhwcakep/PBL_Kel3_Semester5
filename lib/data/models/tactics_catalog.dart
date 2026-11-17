import 'json_value.dart';

/// Satu preset taktik beserta target persentilnya.
class TacticPreset {
  const TacticPreset({
    required this.key,
    required this.label,
    required this.description,
    this.targets = const {},
  });

  final String key;
  final String label;
  final String description;

  /// Target persentil per statistik (0-100), kunci = [PlayerFeature.jsonKey].
  final Map<String, double> targets;

  factory TacticPreset.fromJson(Map<String, dynamic> json) {
    return TacticPreset(
      key: asString(json['key']),
      label: asString(json['label']),
      description: asString(json['description']),
      targets: asNumberMap(json['targets']),
    );
  }
}

/// Satu arketipe beserta preset taktik yang tersedia.
class TacticArchetypeInfo {
  const TacticArchetypeInfo({
    required this.archetype,
    required this.label,
    this.presets = const [],
  });

  /// Kode arketipe: `GK`, `CB`, `FB`, `DM`, `CM`, `AM`, `W`, `ST`.
  final String archetype;

  /// Nama tampilan, mis. "Striker".
  final String label;

  final List<TacticPreset> presets;

  /// Mencari preset berdasarkan [key]. `null` bila tidak ada.
  TacticPreset? preset(String key) {
    for (final preset in presets) {
      if (preset.key == key) return preset;
    }
    return null;
  }

  factory TacticArchetypeInfo.fromJson(Map<String, dynamic> json) {
    return TacticArchetypeInfo(
      archetype: asString(json['archetype']),
      label: asString(json['label']),
      presets: [
        for (final item in asJsonList(json['presets']))
          TacticPreset.fromJson(item),
      ],
    );
  }
}

/// R² dan keandalan model nilai pasar sebuah arketipe.
class ValueModelInfo {
  const ValueModelInfo({
    this.r2Test = 0,
    this.reliability = '',
    this.count = 0,
    this.baseValueEur = 0,
  });

  /// R² pada data uji.
  final double r2Test;

  /// Tingkat keandalan menurut backend, mis. "baik".
  final String reliability;

  /// Jumlah pemain yang dipakai melatih model.
  final int count;

  /// Titik awal model (nilai pasar rata-rata arketipe) dalam Euro.
  final double baseValueEur;

  factory ValueModelInfo.fromJson(Map<String, dynamic> json) {
    return ValueModelInfo(
      r2Test: asDouble(json['r2_test']),
      reliability: asString(json['reliability']),
      count: asInt(json['n']),
      baseValueEur: asDouble(json['base_value_eur']),
    );
  }
}

/// Balasan `GET /meta/tactics` (`TacticsResponse` di backend).
class TacticsCatalog {
  const TacticsCatalog({
    this.archetypes = const [],
    this.valueModels = const {},
  });

  final List<TacticArchetypeInfo> archetypes;

  /// Info model nilai pasar per kode arketipe.
  final Map<String, ValueModelInfo> valueModels;

  /// Mencari arketipe berdasarkan [key]. `null` bila tidak ada.
  TacticArchetypeInfo? archetype(String key) {
    for (final item in archetypes) {
      if (item.archetype == key) return item;
    }
    return null;
  }

  factory TacticsCatalog.fromJson(Map<String, dynamic> json) {
    final models = <String, ValueModelInfo>{};
    for (final entry in asJsonMap(json['value_models']).entries) {
      models[entry.key] = ValueModelInfo.fromJson(asJsonMap(entry.value));
    }

    return TacticsCatalog(
      archetypes: [
        for (final item in asJsonList(json['archetypes']))
          TacticArchetypeInfo.fromJson(item),
      ],
      valueModels: models,
    );
  }
}
