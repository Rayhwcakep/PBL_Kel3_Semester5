import 'package:flutter/material.dart';

import 'player_feature.dart';

/// Satu baris "Tactical DNA Matrix" pada halaman Find by Tactic.
class TacticalDnaMetric {
  const TacticalDnaMetric({
    required this.label,
    required this.value,
    required this.level,
    required this.feature,
  });

  final String label;

  /// Nilai 0-100.
  final double value;

  /// Tingkat kualitatif: "High", "Medium", "Low".
  final String level;

  /// Fitur KNN yang diwakili metrik ini.
  final PlayerFeature feature;

  bool get isHigh => level.toLowerCase() == 'high';
  bool get isLow => level.toLowerCase() == 'low';
}

/// Arsitektur taktik yang bisa dipilih sebagai target pencarian.
class TacticalArchetype {
  const TacticalArchetype({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.dna,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;

  /// Bobot DNA taktik (0-100) yang dipakai untuk menyusun vektor KNN.
  final List<TacticalDnaMetric> dna;

  /// Mengubah DNA taktik menjadi kriteria KNN (rata-rata per fitur).
  Map<PlayerFeature, double> toFeatureValues() {
    final totals = <PlayerFeature, double>{};
    final counts = <PlayerFeature, int>{};
    for (final metric in dna) {
      totals.update(
        metric.feature,
        (value) => value + metric.value,
        ifAbsent: () => metric.value,
      );
      counts.update(metric.feature, (value) => value + 1, ifAbsent: () => 1);
    }
    return {
      for (final entry in totals.entries)
        entry.key: entry.value / (counts[entry.key] ?? 1),
    };
  }
}
