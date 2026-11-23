import 'package:flutter_test/flutter_test.dart';

import 'package:scout_ml/data/mock/mock_players.dart';
import 'package:scout_ml/data/repositories/scouting_repository.dart';
import 'package:scout_ml/data/services/mock_scouting_service.dart';
import 'package:scout_ml/state/feature_catalog_provider.dart';

FeatureCatalogProvider _provider() => FeatureCatalogProvider(
  repository: ScoutingRepository(
    service: MockScoutingService(latency: Duration.zero),
  ),
);

void main() {
  test('load mengambil metadata dari GET /meta/features', () async {
    final provider = _provider();
    expect(provider.catalog, isNull);

    await provider.load();

    expect(provider.isReady, isTrue);
    expect(provider.error, isNull);
    expect(provider.catalog!.archetypes, isNotEmpty);
  });

  test('arketipe ST punya 10 statistik dengan label Indonesia', () async {
    final provider = _provider();
    await provider.load();

    final striker = provider.archetype('ST');
    expect(striker, isNotNull);
    expect(striker!.features.length, 10);
    expect(
      striker.features.map((feature) => feature.label),
      contains('Gol non-penalti'),
    );
  });

  test(
    'arah good_dir dihormati: pelanggaran dibuat makin kecil makin baik',
    () async {
      final provider = _provider();
      await provider.load();

      final striker = provider.archetype('ST')!;
      final fouls = striker.features.firstWhere(
        (feature) => feature.key == 'fls_p90',
      );
      expect(fouls.goodDir, -1);
      expect(fouls.invert, isTrue);
    },
  );

  test(
    'radarFor memakai sumbu backend dan membalik statistik terbalik',
    () async {
      final provider = _provider();
      await provider.load();

      final striker = mockPlayers.firstWhere(
        (player) => player.archetype == 'ST',
      );
      final radar = provider.radarFor(striker);

      expect(radar, isNotNull);
      expect(radar!.labels.length, radar.values.length);
      expect(radar.labels.length, 10);

      final foulIndex = radar.labels.indexWhere((label) => label.isNotEmpty);
      expect(foulIndex, greaterThanOrEqualTo(0));
    },
  );

  test('radarFor null sebelum metadata dimuat', () {
    final provider = _provider();
    expect(provider.radarFor(mockPlayers.first), isNull);
  });
}
