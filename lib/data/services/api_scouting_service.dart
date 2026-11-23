import '../../core/constants/api_endpoints.dart';
import '../models/api_exception.dart';
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
import 'api_client.dart';
import 'scouting_service.dart';

/// Implementasi [ScoutingService] yang memanggil backend FastAPI.
class ApiScoutingService implements ScoutingService {
  ApiScoutingService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<List<Player>> fetchPlayers({PlayerQuery? filter}) async {
    final json = await _client.getJson(
      ApiEndpoints.players,
      query: filter?.toQuery(),
    );
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
    // Persentil 0-100 hanya diterima `/scout/tactic`; `/scout` menuntut
    // statistik per-90 nyata.
    if (criteria.isTacticSearch) {
      final json = await _client.postJson(
        ApiEndpoints.scoutTactic,
        criteria.toTacticJson(),
      );
      return ScoutResponse.fromJson(json);
    }

    final json = await _client.postJson(ApiEndpoints.scout, criteria.toJson());
    return ScoutResponse.fromJson(json);
  }

  @override
  Future<PlayerExplain> explain(String id) async {
    final json = await _client.getJson(ApiEndpoints.playerExplain(id));
    return PlayerExplain.fromJson(json);
  }

  @override
  Future<SimilarPlayers> similarPlayers(String id, {int limit = 10}) async {
    final json = await _client.getJson(
      ApiEndpoints.playerSimilar(id),
      query: {'limit': limit},
    );
    return SimilarPlayers.fromJson(json);
  }

  @override
  Future<TacticFit> tacticFit(
    String id, {
    String? tactic,
    Map<PlayerFeature, double>? sliders,
  }) async {
    final json = await _client.getJson(
      ApiEndpoints.playerFit(id),
      query: {
        'tactic': tactic,
        // Backend menerima seluruh slider pada satu parameter berformat
        // "stat=persentil,stat=persentil".
        'sliders': sliders == null || sliders.isEmpty
            ? null
            : sliders.entries
                  .map((entry) => '${entry.key.jsonKey}=${entry.value}')
                  .join(','),
      },
    );
    return TacticFit.fromJson(json);
  }

  @override
  Future<BestFit> bestFit(
    String id, {
    int topK = 5,
    List<String>? needs,
    double improveWeight = 0.5,
  }) async {
    final json = await _client.getJson(
      ApiEndpoints.bestFit(id),
      query: {
        'top_k': topK,
        'needs': needs == null || needs.isEmpty ? null : needs.join(','),
        'improve_weight': improveWeight,
      },
    );
    return BestFit.fromJson(json);
  }

  @override
  Future<CompareReport> compare(String a, String b) async {
    final json = await _client.postJson(ApiEndpoints.compare, {
      'a': a,
      'b': b,
    });
    return CompareReport.fromJson(json);
  }

  @override
  Future<TacticsCatalog> fetchTactics() async {
    final json = await _client.getJson(ApiEndpoints.tactics);
    return TacticsCatalog.fromJson(json);
  }

  @override
  Future<FeatureCatalog> fetchFeatures() async {
    final json = await _client.getJson(ApiEndpoints.features);
    return FeatureCatalog.fromJson(json);
  }
}
