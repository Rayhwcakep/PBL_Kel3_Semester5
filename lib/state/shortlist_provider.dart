import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/player.dart';

/// Menyimpan daftar pantau (shortlist) pemain secara persisten ke perangkat.
class ShortlistProvider extends ChangeNotifier {
  static const String _storageKey = 'scoutify_shortlist_v1';
  final List<Player> _players = [];
  bool _isLoading = true;

  ShortlistProvider() {
    _loadFromDisk();
  }

  List<Player> get players => List.unmodifiable(_players);
  int get count => _players.length;
  bool get isLoading => _isLoading;

  bool contains(String playerId) =>
      _players.any((player) => player.id == playerId);

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey) ?? [];
      _players.clear();
      for (final item in rawList) {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          _players.add(Player.fromJson(decoded));
        } else if (decoded is Map) {
          _players.add(Player.fromJson(decoded.cast<String, dynamic>()));
        }
      }
    } catch (e) {
      debugPrint('Gagal memuat shortlist dari local storage: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = _players.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList(_storageKey, rawList);
    } catch (e) {
      debugPrint('Gagal menyimpan shortlist ke local storage: $e');
    }
  }

  void toggle(Player player) {
    if (contains(player.id)) {
      _players.removeWhere((p) => p.id == player.id);
    } else {
      _players.add(player);
    }
    notifyListeners();
    _saveToDisk();
  }

  void remove(String playerId) {
    _players.removeWhere((p) => p.id == playerId);
    notifyListeners();
    _saveToDisk();
  }

  void clear() {
    _players.clear();
    notifyListeners();
    _saveToDisk();
  }
}
