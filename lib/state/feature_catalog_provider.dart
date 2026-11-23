import 'package:flutter/foundation.dart';

import '../data/models/api_exception.dart';
import '../data/models/feature_catalog.dart';
import '../data/models/player.dart';
import '../data/models/player_feature.dart';
import '../data/repositories/scouting_repository.dart';

/// Memuat metadata model dari `GET /meta/features`.
///
/// Metadata ini memberi tahu statistik apa saja yang dinilai untuk tiap
/// arketipe, arah baik/buruknya, serta sumbu radar versi backend. Dipakai
/// layar Discover supaya label dan sumbu grafik selalu sama dengan model.
class FeatureCatalogProvider extends ChangeNotifier {
  FeatureCatalogProvider({ScoutingRepository? repository})
    : _repository = repository ?? ScoutingRepository();

  final ScoutingRepository _repository;

  FeatureCatalog? _catalog;
  bool _isLoading = false;
  String? _error;

  FeatureCatalog? get catalog => _catalog;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isReady => _catalog != null;

  /// Memuat metadata sekali saja; pemanggilan berikutnya tidak mengulang
  /// permintaan kecuali sebelumnya gagal.
  Future<void> load() async {
    if (_isLoading || _catalog != null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _catalog = await _repository.getFeatures();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Metadata arketipe, mis. `ST`. `null` bila belum dimuat.
  ArchetypeInfo? archetype(String key) => _catalog?.archetype(key);

  /// Label dan nilai radar pemain sesuai sumbu backend.
  ///
  /// Nilai tetap 0-100 dan statistik yang "makin kecil makin baik" sudah
  /// dibalik, jadi bentuk grafik sama dengan sumbu yang dipakai model.
  ({List<String> labels, List<double> values})? radarFor(Player player) {
    final catalog = _catalog;
    if (catalog == null) return null;

    final axes = catalog.hexagonAxes[player.isGoalkeeper ? 'GK' : 'outfield'];
    if (axes == null || axes.isEmpty) return null;

    final labels = <String>[];
    final values = <double>[];
    for (final axis in axes) {
      labels.add(axis.label);
      final feature = PlayerFeature.fromJsonKey(axis.feature);
      if (feature == null) {
        values.add(0);
        continue;
      }
      final percentile = player.percentile(feature).clamp(0, 100).toDouble();
      values.add(axis.invert ? 100 - percentile : percentile);
    }
    return (labels: labels, values: values);
  }
}
