/// Konfigurasi global aplikasi.
///
/// Ubah [baseUrl] sesuai alamat backend FastAPI yang kamu jalankan.
/// - Emulator Android  -> http://10.0.2.2:8000
/// - iOS Simulator     -> http://localhost:8000
/// - Device fisik      -> `http://<IP_LAN_KAMU>:8000`
class AppConfig {
  const AppConfig._();

  /// Alamat dasar backend FastAPI (tanpa trailing slash).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Prefix versi API. Samakan dengan yang kamu daftarkan di FastAPI.
  static const String apiPrefix = '/api/v1';

  /// Timeout permintaan HTTP.
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Bila `true`, aplikasi memakai data contoh lokal dan tidak memanggil
  /// backend. Berguna saat fokus mengerjakan tampilan (frontend).
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: true,
  );
}
