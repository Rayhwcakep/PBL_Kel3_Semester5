/// Daftar endpoint backend FastAPI.
///
/// Semua path di sini harus sama persis dengan yang ada di
/// `backend/app/api/routes/`.
class ApiEndpoints {
  const ApiEndpoints._();

  static const String health = '/health';

  /// Daftar seluruh pemain pada dataset.
  static const String players = '/players';

  /// Detail satu pemain: `/players/{id}`.
  static String player(String id) => '$players/$id';

  /// Kelebihan dan kekurangan pemain hasil SHAP: `/players/{id}/explain`.
  static String playerExplain(String id) => '${player(id)}/explain';

  /// Pemain paling mirip beserta alasannya: `/players/{id}/similar`.
  static String playerSimilar(String id) => '${player(id)}/similar';

  /// Kecocokan pemain dengan sebuah taktik: `/players/{id}/fit`.
  static String playerFit(String id) => '${player(id)}/fit';

  /// Rekomendasi pengganti yang menutup kekurangan: `/best-fit/{id}`.
  static String bestFit(String id) => '/best-fit/$id';

  /// Perbandingan dua pemain.
  static const String compare = '/compare';

  /// Metadata fitur yang dipakai model.
  static const String features = '/meta/features';

  /// Preset taktik per arketipe.
  static const String tactics = '/meta/tactics';

  /// Endpoint utama: pencarian pemain dengan KNN + penjelasan SHAP.
  static const String scout = '/scout';

  /// Pencarian dengan preset taktik atau slider persentil 0-100.
  static const String scoutTactic = '/scout/tactic';
}
