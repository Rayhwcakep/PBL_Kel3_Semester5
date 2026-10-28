import 'package:flutter/foundation.dart';

import '../data/models/api_exception.dart';
import '../data/models/player.dart';
import '../data/models/player_feature.dart';
import '../data/models/scout_response.dart';
import '../data/models/scouting_criteria.dart';
import '../data/repositories/scouting_repository.dart';

/// Menyimpan keadaan form pencarian dan hasil KNN + SHAP.
class ScoutingProvider extends ChangeNotifier {
  ScoutingProvider({ScoutingRepository? repository})
    : _repository = repository ?? ScoutingRepository();

  final ScoutingRepository _repository;

  ScoutingCriteria _criteria = ScoutingCriteria();
  Player? _basePlayer;
  ScoutResponse? _response;
  bool _isLoading = false;
  String? _error;

  ScoutingCriteria get criteria => _criteria;
  Player? get basePlayer => _basePlayer;
  ScoutResponse? get response => _response;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasResult => _response != null && _response!.results.isNotEmpty;

  /// Menetapkan pemain acuan (anchor) dan menyalin atributnya ke kriteria.
  void setBasePlayer(Player player) {
    _basePlayer = player;
    final values = <PlayerFeature, double>{
      for (final feature in PlayerFeature.values) feature: player.stat(feature),
    };
    _criteria = _criteria.copyWith(values: values, basePlayerId: player.id);
    notifyListeners();
  }

  void clearBasePlayer() {
    _basePlayer = null;
    _criteria = _criteria.copyWith(clearBasePlayer: true);
    notifyListeners();
  }

  void updateFeature(PlayerFeature feature, double value) {
    final values = Map<PlayerFeature, double>.from(_criteria.values);
    values[feature] = value;
    _criteria = _criteria.copyWith(values: values, clearBasePlayer: true);
    _basePlayer = null;
    notifyListeners();
  }

  void setPosition(String? position) {
    _criteria = position == null
        ? _criteria.copyWith(clearPosition: true)
        : _criteria.copyWith(position: position);
    notifyListeners();
  }

  void setLeague(String? league) {
    _criteria = league == null
        ? _criteria.copyWith(clearLeague: true)
        : _criteria.copyWith(league: league);
    notifyListeners();
  }

  void setMaxAge(int? maxAge) {
    _criteria = maxAge == null
        ? _criteria.copyWith(clearMaxAge: true)
        : _criteria.copyWith(maxAge: maxAge);
    notifyListeners();
  }

  void setMaxValue(double? maxValue) {
    _criteria = maxValue == null
        ? _criteria.copyWith(clearMaxValue: true)
        : _criteria.copyWith(maxValue: maxValue);
    notifyListeners();
  }

  void setSortBy(ScoutSortBy sortBy) {
    _criteria = _criteria.copyWith(sortBy: sortBy);
    notifyListeners();
  }

  void setTopK(int topK) {
    _criteria = _criteria.copyWith(topK: topK);
    notifyListeners();
  }

  /// Menetapkan kriteria sekaligus, dipakai oleh halaman Find by Tactic.
  void applyCriteria({
    Map<PlayerFeature, double>? values,
    String? position,
    String? league,
    int? maxAge,
    double? maxValue,
  }) {
    _criteria = _criteria.copyWith(
      values: values,
      position: position,
      clearPosition: position == null,
      league: league,
      clearLeague: league == null,
      maxAge: maxAge,
      clearMaxAge: maxAge == null,
      maxValue: maxValue,
      clearMaxValue: maxValue == null,
      clearBasePlayer: true,
    );
    _basePlayer = null;
    notifyListeners();
  }

  /// Mengembalikan form ke nilai awal.
  void resetForm() {
    _criteria = ScoutingCriteria();
    _basePlayer = null;
    notifyListeners();
  }

  /// Menjalankan pencarian. UI menampilkan indikator loading lalu hasil.
  Future<void> runScout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _response = await _repository.scout(_criteria);
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
