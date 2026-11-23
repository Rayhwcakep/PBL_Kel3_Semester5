import 'package:flutter/foundation.dart';

import '../data/models/api_exception.dart';
import '../data/models/compare_report.dart';
import '../data/models/player.dart';
import '../data/repositories/scouting_repository.dart';

/// Menyimpan dua pemain yang sedang dibandingkan (head-to-head).
///
/// Hasil analisis diambil dari backend lewat `POST /compare`; selama
/// menunggu balasan [report] masih kosong dan [isLoading] bernilai `true`.
class CompareProvider extends ChangeNotifier {
  CompareProvider({ScoutingRepository? repository})
    : _repository = repository ?? ScoutingRepository();

  final ScoutingRepository _repository;

  Player? _left;
  Player? _right;
  CompareReport? _report;
  bool _isLoading = false;
  String? _error;
  int _requestId = 0;

  Player? get left => _left;
  Player? get right => _right;
  bool get isReady => _left != null && _right != null;

  /// Hasil `POST /compare` untuk pasangan pemain saat ini.
  CompareReport? get report => _report;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Menetapkan pemain ke slot kiri/kanan. Bila sudah terisi, digantikan.
  void setPlayer(Player player, {bool left = true}) {
    if (left) {
      _left = player;
    } else {
      _right = player;
    }
    _resetReport();
    notifyListeners();
    _maybeCompare();
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
    _resetReport();
    notifyListeners();
    _maybeCompare();
  }

  void removeLeft() {
    _left = null;
    _resetReport();
    notifyListeners();
  }

  void removeRight() {
    _right = null;
    _resetReport();
    notifyListeners();
  }

  /// Menukar posisi kedua pemain.
  void swap() {
    final temp = _left;
    _left = _right;
    _right = temp;
    _resetReport();
    notifyListeners();
    _maybeCompare();
  }

  void clear() {
    _left = null;
    _right = null;
    _resetReport();
    notifyListeners();
  }

  /// Memanggil ulang `POST /compare` untuk pasangan saat ini.
  Future<void> runCompare() async {
    final a = _left;
    final b = _right;
    if (a == null || b == null) {
      _resetReport();
      notifyListeners();
      return;
    }

    final requestId = ++_requestId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final report = await _repository.compare(a.id, b.id);
      if (requestId != _requestId) return;
      _report = report;
    } on ApiException catch (e) {
      if (requestId != _requestId) return;
      _error = e.message;
    } catch (e) {
      if (requestId != _requestId) return;
      _error = 'Terjadi kesalahan: $e';
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _maybeCompare() {
    if (!isReady) return;
    runCompare();
  }

  void _resetReport() {
    _requestId++;
    _report = null;
    _error = null;
    _isLoading = false;
  }
}
