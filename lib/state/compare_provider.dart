import 'package:flutter/foundation.dart';

import '../data/models/player.dart';

/// Menyimpan dua pemain yang sedang dibandingkan (head-to-head).
class CompareProvider extends ChangeNotifier {
  Player? _left;
  Player? _right;

  Player? get left => _left;
  Player? get right => _right;
  bool get isReady => _left != null && _right != null;

  /// Menetapkan pemain ke slot kiri/kanan. Bila sudah terisi, digantikan.
  void setPlayer(Player player, {bool left = true}) {
    if (left) {
      _left = player;
    } else {
      _right = player;
    }
    notifyListeners();
  }

  /// Menambahkan pemain ke slot kosong berikutnya.
  void add(Player player) {
    if (_left == null) {
      _left = player;
    } else if (_right == null) {
      _right = player;
    } else {
      _right = player;
    }
    notifyListeners();
  }

  void removeLeft() {
    _left = null;
    notifyListeners();
  }

  void removeRight() {
    _right = null;
    notifyListeners();
  }

  /// Menukar posisi kedua pemain.
  void swap() {
    final temp = _left;
    _left = _right;
    _right = temp;
    notifyListeners();
  }

  void clear() {
    _left = null;
    _right = null;
    notifyListeners();
  }
}
