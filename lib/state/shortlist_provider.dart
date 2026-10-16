import 'package:flutter/foundation.dart';

import '../data/models/player.dart';

/// Menyimpan daftar pantau (shortlist) pemain di memori.
class ShortlistProvider extends ChangeNotifier {
  final List<Player> _players = [];

  List<Player> get players => List.unmodifiable(_players);
  int get count => _players.length;

  bool contains(String playerId) =>
      _players.any((player) => player.id == playerId);

  void toggle(Player player) {
    if (contains(player.id)) {
      _players.removeWhere((p) => p.id == player.id);
    } else {
      _players.add(player);
    }
    notifyListeners();
  }

  void remove(String playerId) {
    _players.removeWhere((p) => p.id == playerId);
    notifyListeners();
  }

  void clear() {
    _players.clear();
    notifyListeners();
  }
}
