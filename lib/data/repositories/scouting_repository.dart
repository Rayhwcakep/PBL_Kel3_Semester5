import '../../core/config/app_config.dart';
import '../models/best_fit.dart';
import '../models/compare_report.dart';
import '../models/explain_response.dart';
import '../models/feature_catalog.dart';
import '../models/player.dart';
import '../models/player_query.dart';
import '../models/scout_response.dart';
import '../models/scouting_criteria.dart';
import '../services/api_scouting_service.dart';
import '../services/mock_scouting_service.dart';
import '../services/scouting_service.dart';

/// Satu pintu akses data untuk lapisan UI.
///
/// Secara otomatis memilih backend asli atau data contoh berdasarkan
/// [AppConfig.useMockData]. Saat backend FastAPI siap, cukup set
/// `useMockData = false`.
class ScoutingRepository {
  ScoutingRepository({ScoutingService? service})
    : _service =
          service ??
          (AppConfig.useMockData
              ? MockScoutingService()
              : ApiScoutingService());

  final ScoutingService _service;

  Future<List<Player>> getPlayers({PlayerQuery? filter}) =>
      _service.fetchPlayers(filter: filter);

  Future<Player> getPlayer(String id) => _service.fetchPlayer(id);

  /// Kelebihan dan kekurangan pemain hasil SHAP
  /// (`GET /players/{id}/explain`).
  Future<PlayerExplain> explain(String id) => _service.explain(id);

  Future<ScoutResponse> scout(ScoutingCriteria criteria) =>
      _service.scout(criteria);

  Future<CompareReport> compare(String a, String b) => _service.compare(a, b);

  /// Kandidat pengganti yang menutup kekurangan pemain acuan
  /// (`GET /best-fit/{id}`).
  Future<BestFit> bestFit(
    String id, {
    int topK = 5,
    List<String>? needs,
    double improveWeight = 0.5,
    int? maxAge,
    double? maxValueEur,
  }) => _service.bestFit(
    id,
    topK: topK,
    needs: needs,
    improveWeight: improveWeight,
    maxAge: maxAge,
    maxValueEur: maxValueEur,
  );

  Future<FeatureCatalog> getFeatures() => _service.fetchFeatures();
}
