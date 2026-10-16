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

  /// Metadata fitur yang dipakai model.
  static const String features = '/meta/features';

  /// Endpoint utama: pencarian pemain dengan KNN + penjelasan SHAP.
  static const String scout = '/scout';
}
