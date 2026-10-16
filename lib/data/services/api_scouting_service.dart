import '../../core/constants/api_endpoints.dart';
import '../models/api_exception.dart';
import '../models/player.dart';
import '../models/scout_response.dart';
import '../models/scouting_criteria.dart';
import 'api_client.dart';
import 'scouting_service.dart';

/// Implementasi [ScoutingService] yang memanggil backend FastAPI.
class ApiScoutingService implements ScoutingService {
  ApiScoutingService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<List<Player>> fetchPlayers() async {
    final json = await _client.getJson(ApiEndpoints.players);
    final items = (json['players'] as List?) ?? (json as List?);
    if (items == null) {
      throw const ApiException('Daftar pemain tidak ditemukan pada balasan.');
    }
    return items
        .map((item) => Player.fromJson((item as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  @override
  Future<Player> fetchPlayer(String id) async {
    final json = await _client.getJson(ApiEndpoints.player(id));
    return Player.fromJson(json);
  }

  @override
  Future<ScoutResponse> scout(ScoutingCriteria criteria) async {
    final json = await _client.postJson(ApiEndpoints.scout, criteria.toJson());
    return ScoutResponse.fromJson(json);
  }
}
