import 'package:flutter_test/flutter_test.dart';
import 'package:scout_ml/data/mock/mock_players.dart';
import 'package:scout_ml/data/models/player_feature.dart';
import 'package:scout_ml/data/models/scouting_criteria.dart';
import 'package:scout_ml/data/services/mock_scouting_service.dart';

/// Kontribusi pada hasil pencarian harus mengikuti **kedekatan ke target**,
/// bukan besar nilainya. Statistik yang jauh di atas target sama-sama
/// menurunkan skor kecocokan seperti statistik yang jauh di bawah target.
void main() {
  final service = MockScoutingService(latency: Duration.zero);
  final vinicius = mockPlayers.firstWhere((player) => player.id == 'p010');

  ScoutingCriteria search({
    required double shootingTarget,
    bool byPercentile = false,
  }) {
    return ScoutingCriteria(
      archetype: 'W',
      values: byPercentile
          ? null
          : {
              for (final feature in PlayerFeature.outfield)
                feature: feature == PlayerFeature.shP90
                    ? shootingTarget
                    : vinicius.stat(feature),
            },
      sliders: byPercentile
          ? {
              for (final feature in PlayerFeature.outfield)
                feature: feature == PlayerFeature.shP90
                    ? shootingTarget
                    : vinicius.percentile(feature),
            }
          : null,
      basePlayerId: 'p001',
      topK: 10,
    );
  }

  Future<void> expectShootingIsNegative({
    required double shootingTarget,
    required bool byPercentile,
  }) async {
    final response = await service.scout(
      search(shootingTarget: shootingTarget, byPercentile: byPercentile),
    );
    final result = response.results.firstWhere(
      (result) => result.player.id == 'p010',
    );
    final shooting = result.contributions.firstWhere(
      (contribution) => contribution.feature == PlayerFeature.shP90,
    );

    expect(
      shooting.shapValue,
      lessThan(0),
      reason:
          'Tembakan $shootingTarget menyimpang dari target, '
          'jadi harus menurunkan skor kecocokan.',
    );
    expect(shooting.isPositive, isFalse);
    expect(shooting.effectPct, lessThan(0));
  }

  test(
    'tembakan di atas target menurunkan skor kecocokan (statistik nyata)',
    () async {
      await expectShootingIsNegative(shootingTarget: 1.0, byPercentile: false);
    },
  );

  test('tembakan di bawah target juga menurunkan skor kecocokan', () async {
    await expectShootingIsNegative(shootingTarget: 10.0, byPercentile: false);
  });

  test(
    'target persentil rendah tidak membuat persentil tinggi hijau',
    () async {
      // Kasus yang dilaporkan: target tembakan rendah, pemain menembak tinggi.
      await expectShootingIsNegative(shootingTarget: 30, byPercentile: true);
    },
  );

  test(
    'fitur yang tepat di target menaikkan skor dan total kontribusi nol',
    () async {
      final perfect = await service.scout(
        search(shootingTarget: vinicius.stat(PlayerFeature.shP90)),
      );
      final perfectRows = perfect.results
          .firstWhere((result) => result.player.id == 'p010')
          .contributions;

      // Seluruh statistik persis di target: tidak ada yang menyimpang, jadi
      // semua kontribusi nol.
      expect(
        perfectRows.every((contribution) => contribution.shapValue == 0),
        isTrue,
      );

      final skewed = await service.scout(search(shootingTarget: 1.0));
      final skewedRows = skewed.results
          .firstWhere((result) => result.player.id == 'p010')
          .contributions;
      final total = skewedRows.fold<double>(
        0,
        (sum, contribution) => sum + contribution.shapValue,
      );

      expect(total, closeTo(0, 1e-9));
      final assist = skewedRows.firstWhere(
        (contribution) => contribution.feature == PlayerFeature.astP90,
      );
      expect(assist.shapValue, greaterThan(0));
    },
  );
}
