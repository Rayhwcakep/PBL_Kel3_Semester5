import 'package:flutter/foundation.dart';

import '../data/models/api_exception.dart';
import '../data/models/player.dart';
import '../data/repositories/scouting_repository.dart';

/// Memuat dan menyimpan daftar pemain pada dataset.
class PlayerProvider extends ChangeNotifier {
  PlayerProvider({ScoutingRepository? repository})
    : _repository = repository ?? ScoutingRepository();

  final ScoutingRepository _repository;

  List<Player> _players = const [];
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

  /// Pemain dengan nilai xG+xA per 90 tertinggi (untuk "Top Performers").
  List<Player> topPerformers({String? positionGroup, int limit = 5}) {
    final filtered = _players.where((p) {
      if (positionGroup == null) return true;
      return p.positionGroup == positionGroup;
    }).toList()..sort((a, b) => b.xgXaPer90.compareTo(a.xgXaPer90));
    return filtered.take(limit).toList();
  }

  Player? findById(String id) {
    for (final player in _players) {
      if (player.id == id) return player;
    }
    return null;
  }

  Future<void> loadPlayers() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _players = await _repository.getPlayers();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
