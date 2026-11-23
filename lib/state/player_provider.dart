import 'package:flutter/foundation.dart';

import '../data/models/api_exception.dart';
import '../data/models/player.dart';
import '../data/models/player_query.dart';
import '../data/repositories/scouting_repository.dart';

/// Memuat dan menyimpan daftar pemain pada dataset.
class PlayerProvider extends ChangeNotifier {
  PlayerProvider({ScoutingRepository? repository})
    : _repository = repository ?? ScoutingRepository();

  final ScoutingRepository _repository;

  List<Player> _players = const [];
  PlayerQuery _filter = const PlayerQuery();
  bool _isLoading = false;
  String? _error;

  List<Player> get players => _players;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Daftar posisi unik dari dataset, dipakai untuk dropdown filter.
  List<String> get positions {
    final unique = _players.map((p) => p.position).toSet().toList()..sort();
    return unique;
  }

  /// Daftar liga unik dari dataset.
  List<String> get leagues {
    final unique =
        _players
            .map((p) => p.league)
            .where((l) => l.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return unique;
  }

  /// Pemain dengan pertumbuhan nilai pasar tertinggi (untuk "Rising Value").
  List<Player> get risingValue {
    final sorted = [..._players];
    sorted.sort((a, b) => b.trendPercent.compareTo(a.trendPercent));
    return sorted;
  }

  /// Pemain dengan kontribusi gol (gol + assist) per 90 tertinggi
  /// (untuk "Top Performers").
  List<Player> topPerformers({String? positionGroup, int limit = 5}) {
    final filtered = _players.where((p) {
      if (positionGroup == null) return true;
      return p.positionGroup == positionGroup;
    }).toList()..sort(
      (a, b) =>
          b.metrics.goalContribution.compareTo(a.metrics.goalContribution),
    );
    return filtered.take(limit).toList();
  }

  Player? findById(String id) {
    for (final player in _players) {
      if (player.id == id) return player;
    }
    return null;
  }

  /// Memuat daftar pemain dari `GET /players`.
  ///
  /// Bila [filter] diisi, filter tersebut disimpan dan dipakai untuk
  /// permintaan berikutnya (mis. saat pull-to-refresh).
  Future<void> loadPlayers({PlayerQuery? filter}) async {
    if (_isLoading) return;
    if (filter != null) _filter = filter;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _players = await _repository.getPlayers(filter: _filter);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mencari pemain lewat `GET /players` tanpa mengubah daftar utama.
  ///
  /// Dipakai filter Discover agar penyaringan dikerjakan backend dan tidak
  /// mengganggu data yang sudah dimuat untuk halaman lain.
  Future<List<Player>> searchPlayers(PlayerQuery query) =>
      _repository.getPlayers(filter: query);
}
