/// Fitur (atribut) yang dipakai untuk menilai dan membandingkan pemain.
///
/// [jsonKey] adalah nama field pada payload JSON backend FastAPI.
/// Urutan enum ini juga menentukan urutan vektor saat model KNN dihitung,
/// jadi jangan ubah urutannya tanpa menyesuaikan backend.
enum PlayerFeature {
  pace('pace', 'Pace', 'Kecepatan lari pemain'),
  shooting('shooting', 'Shooting', 'Kualitas penyelesaian akhir'),
  passing('passing', 'Passing', 'Akurasi dan kualitas umpan'),
  dribbling('dribbling', 'Dribbling', 'Kemampuan menggiring bola'),
  defending('defending', 'Defending', 'Kemampuan bertahan dan merebut bola'),
  physical('physical', 'Physical', 'Kekuatan dan duel fisik'),
  vision('vision', 'Vision', 'Visi bermain dan kreativitas'),
  stamina('stamina', 'Stamina', 'Daya tahan selama pertandingan');

  const PlayerFeature(this.jsonKey, this.label, this.description);

  /// Kunci pada JSON backend.
  final String jsonKey;

  /// Label singkat untuk UI.
  final String label;

  /// Penjelasan singkat fitur (bahasa Indonesia).
  final String description;

  /// Semua fitur dalam urutan tetap.
  static List<PlayerFeature> get all => PlayerFeature.values;

  /// Mencari fitur dari [jsonKey]. Mengembalikan `null` bila tidak ada.
  static PlayerFeature? fromJsonKey(String key) {
    for (final feature in PlayerFeature.values) {
      if (feature.jsonKey == key) return feature;
    }
    return null;
  }
}
