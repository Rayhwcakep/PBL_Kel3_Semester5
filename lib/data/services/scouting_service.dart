import '../models/player.dart';
import '../models/scout_response.dart';
import '../models/scouting_criteria.dart';

/// Kontrak layanan scouting.
///
/// Ada dua implementasi:
/// - `ApiScoutingService`  -> memanggil backend FastAPI (JSON).
/// - `MockScoutingService` -> data contoh lokal, untuk mengerjakan UI dulu.
abstract class ScoutingService {
  /// Mengambil seluruh pemain pada dataset.
  Future<List<Player>> fetchPlayers();

  /// Mengambil detail satu pemain.
  Future<Player> fetchPlayer(String id);

  /// Menjalankan pencarian KNN dan mengambil penjelasan SHAP.
  Future<ScoutResponse> scout(ScoutingCriteria criteria);
}
