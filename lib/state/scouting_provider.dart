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

  /// Menetapkan pemain acuan (anchor) dan menyalin statistiknya ke kriteria.
  ///
  /// Hanya statistik arketipe pemain ini yang dikirim, karena backend menolak
  /// statistik yang tidak dipakai arketipe tersebut.
  void setBasePlayer(Player player) {
    _basePlayer = player;
    final values = <PlayerFeature, double>{
      for (final feature in player.radarAxes) feature: player.stat(feature),
    };
    _criteria = _criteria.copyWith(
      values: values,
      clearSliders: true,
      clearTactic: true,
      archetype: player.archetype,
      basePlayerId: player.id,
    );
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

  /// Mengganti urutan hasil. Backend selalu mengurutkan dari yang paling
  /// mirip, jadi urutan lain diterapkan di sini tanpa memanggil ulang API.
  void setSortBy(ScoutSortBy sortBy) {
    _criteria = _criteria.copyWith(sortBy: sortBy);
    _applySort();
    notifyListeners();
  }

  void setTopK(int topK) {
    _criteria = _criteria.copyWith(topK: topK);
    notifyListeners();
  }

  /// Menetapkan kriteria sekaligus, dipakai oleh halaman Find by Tactic.
  ///
  /// [sliders] berisi persentil 0-100 sehingga pencarian memakai
  /// `POST /scout/tactic`.
  void applyCriteria({
    Map<PlayerFeature, double>? values,
    Map<PlayerFeature, double>? sliders,
    String? archetype,
    String? league,
    int? maxAge,
    double? maxValue,
  }) {
    _criteria = _criteria.copyWith(
      values: values,
      sliders: sliders,
      clearSliders: sliders == null,
      archetype: archetype,
      clearLeague: league == null,
      league: league,
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
    _response = null;
    notifyListeners();
  }

  /// Menjalankan pencarian. UI menampilkan indikator loading lalu hasil.
  Future<void> runScout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _response = await _repository.scout(_criteria);
      _applySort();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applySort() {
    final response = _response;
    if (response == null || response.results.length < 2) return;

    final sorted = [...response.results];
    switch (_criteria.sortBy) {
      case ScoutSortBy.similarity:
        sorted.sort((a, b) => b.similarity.compareTo(a.similarity));
      case ScoutSortBy.value:
        sorted.sort(
          (a, b) => b.player.marketValue.compareTo(a.player.marketValue),
        );
      case ScoutSortBy.age:
        sorted.sort((a, b) => a.player.age.compareTo(b.player.age));
    }

    _response = response.copyWith(
      results: [
        for (var i = 0; i < sorted.length; i++)
          sorted[i].copyWith(rank: i + 1),
      ],
    );
  }
}
