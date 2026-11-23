import '../models/best_fit.dart';
import '../models/compare_report.dart';
import '../models/explain_response.dart';
import '../models/feature_catalog.dart';
import '../models/player.dart';
import '../models/player_feature.dart';
import '../models/player_query.dart';
import '../models/scout_response.dart';
import '../models/scouting_criteria.dart';
import '../models/similar_response.dart';
import '../models/tactic_fit.dart';
import '../models/tactics_catalog.dart';

/// Kontrak layanan scouting.
///
/// Ada dua implementasi:
/// - `ApiScoutingService`  -> memanggil backend FastAPI (JSON).
/// - `MockScoutingService` -> data contoh lokal, untuk mengerjakan UI dulu.
abstract class ScoutingService {
  /// Mengambil daftar pemain pada dataset (`GET /players`).
  ///
  /// [filter] diteruskan sebagai query string sehingga penyaringan
  /// (arketipe, liga, umur, nilai pasar, pencarian) dikerjakan backend.
  Future<List<Player>> fetchPlayers({PlayerQuery? filter});

  /// Mengambil detail satu pemain.
  Future<Player> fetchPlayer(String id);

  /// Menjalankan pencarian KNN dan mengambil penjelasan SHAP.
  Future<ScoutResponse> scout(ScoutingCriteria criteria);

  /// Kelebihan dan kekurangan pemain hasil SHAP
  /// (`GET /players/{id}/explain`).
  Future<PlayerExplain> explain(String id);

  /// Pemain paling mirip beserta alasannya (`GET /players/{id}/similar`).
  Future<SimilarPlayers> similarPlayers(String id, {int limit = 10});

  /// Kecocokan pemain dengan sebuah taktik (`GET /players/{id}/fit`).
  ///
  /// Pakai [tactic] (kunci preset) atau [sliders] (persentil 0-100), boleh
  /// keduanya; slider menimpa target preset.
  Future<TacticFit> tacticFit(
    String id, {
    String? tactic,
    Map<PlayerFeature, double>? sliders,
  });

  /// Rekomendasi pengganti yang menutup kekurangan pemain acuan
  /// (`GET /best-fit/{id}`).
  ///
  /// [needs] berisi kunci statistik yang ingin ditutup; kosong berarti
  /// backend memakai kekurangan SHAP.
  Future<BestFit> bestFit(
    String id, {
    int topK = 5,
    List<String>? needs,
    double improveWeight = 0.5,
  });

  /// Membandingkan dua pemain (`POST /compare`).
  Future<CompareReport> compare(String a, String b);

  /// Katalog preset taktik per arketipe (`GET /meta/tactics`).
  Future<TacticsCatalog> fetchTactics();

  /// Metadata statistik tiap arketipe (`GET /meta/features`).
  Future<FeatureCatalog> fetchFeatures();
}
