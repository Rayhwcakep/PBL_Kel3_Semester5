/// Sumbu radar untuk profil pemain (persentil 0-100).
///
/// [jsonKey] harus sama dengan kunci di payload backend.
enum RadarMetric {
  goals('goals', 'Goals'),
  assists('assists', 'Assists'),
  shots('shots', 'Shots'),
  crossing('crossing', 'Crossing'),
  tackles('tackles', 'Tackles'),
  interceptions('interceptions', 'Interceptions');

  const RadarMetric(this.jsonKey, this.label);

  final String jsonKey;
  final String label;

  static List<RadarMetric> get all => RadarMetric.values;

  static RadarMetric? fromJsonKey(String key) {
    for (final metric in RadarMetric.values) {
      if (metric.jsonKey == key) return metric;
    }
    return null;
  }
}
