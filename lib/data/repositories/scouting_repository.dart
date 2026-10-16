import '../../core/config/app_config.dart';
import '../models/player.dart';
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
      : _service = service ??
            (AppConfig.useMockData
                ? MockScoutingService()
                : ApiScoutingService());

  final ScoutingService _service;

  Future<List<Player>> getPlayers() => _service.fetchPlayers();

  Future<Player> getPlayer(String id) => _service.fetchPlayer(id);

  Future<ScoutResponse> scout(ScoutingCriteria criteria) =>
      _service.scout(criteria);
}
