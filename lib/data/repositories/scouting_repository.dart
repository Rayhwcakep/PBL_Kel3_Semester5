import '../../core/config/app_config.dart';
import '../cache/explain_cache.dart';
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
  ScoutingRepository({ScoutingService? service, ExplainCache? explainCache})
    : _service =
          service ??
          (AppConfig.useMockData
              ? MockScoutingService()
              : ApiScoutingService()),
      _explainCache = explainCache ?? ExplainCache.shared;

  final ScoutingService _service;
  final ExplainCache _explainCache;

  Future<List<Player>> getPlayers({PlayerQuery? filter}) =>
      _service.fetchPlayers(filter: filter);

  Future<Player> getPlayer(String id) => _service.fetchPlayer(id);

  /// Kelebihan dan kekurangan pemain hasil SHAP
  /// (`GET /players/{id}/explain`).
  ///
  /// Hasil disimpan sementara di [ExplainCache] agar membuka layar yang sama
  /// berulang kali tidak memanggil backend terus-menerus. Set [refresh] ke
  /// `true` (mis. dari pull-to-refresh) untuk memaksa data baru.
  Future<PlayerExplain> explain(String id, {bool refresh = false}) {
    if (refresh) _explainCache.invalidate(id);
    return _explainCache.load(id, () => _service.explain(id));
  }

  Future<ScoutResponse> scout(ScoutingCriteria criteria) =>
      _service.scout(criteria);

  Future<CompareReport> compare(String a, String b) => _service.compare(a, b);

  Future<FeatureCatalog> getFeatures() => _service.fetchFeatures();
}
