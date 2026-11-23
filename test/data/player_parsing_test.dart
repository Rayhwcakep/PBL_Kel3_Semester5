import 'package:flutter_test/flutter_test.dart';
import 'package:scout_ml/data/models/player.dart';
import 'package:scout_ml/data/models/scout_response.dart';
import 'package:scout_ml/data/models/player_feature.dart';

void main() {
  group('Golden test parsing JSON', () {
    test('Player.fromJson parses backend player JSON fixture successfully', () {
      final jsonFixture = {
        'id': '7',
        'name': 'Matthis Abline',
        'club': 'Nantes',
        'league': 'Ligue 1',
        'position': 'Centre-Forward',
        'position_group': 'FW',
        'archetype': 'ST',
        'age': 22,
        'height': 185,
        'foot': 'right',
        'contract_until': '2028-06-30 00:00:00',
        'market_value_eur': 20000000.0,
        'value_growth_1y': 0.111,
        'minutes': 2584.0,
        'matches': 30,
        'context': {
          'start_rate': 0.8485,
          'plus_p90': -0.8362,
          'crd_p90': 0.2091
        },
        'stats': {
          'npg_p90': 0.2091,
          'sh_p90': 2.9268
        },
        'percentiles': {
          'npg_p90': 27.9,
          'sh_p90': 74.2
        },
        'image_url': null
      };

      final player = Player.fromJson(jsonFixture);

      expect(player.id, '7');
      expect(player.name, 'Matthis Abline');
      expect(player.club, 'Nantes');
      expect(player.archetype, 'ST');
      expect(player.age, 22);
      expect(player.marketValue, 20);
      expect(player.stat(PlayerFeature.npgP90), 0.2091);
      expect(player.percentile(PlayerFeature.shP90), 74.2);
    });

    test('ScoutResponse.fromJson parses backend scout response JSON fixture successfully', () {
      final jsonFixture = {
        'archetype': 'ST',
        'tactic': null,
        'k': 5,
        'target': {
          'npg_p90': 0.62,
          'sh_p90': 3.5
        },
        'target_percentiles': {
          'npg_p90': 78.4,
          'sh_p90': 71.0
        },
        'results': [
          {
            'rank': 1,
            'similarity': 62.7,
            'distance': 0.48,
            'player': {
              'id': '7',
              'name': 'Matthis Abline',
              'club': 'Nantes',
              'league': 'Ligue 1',
              'position': 'Centre-Forward',
              'position_group': 'FW',
              'archetype': 'ST',
              'age': 22,
              'stats': {'npg_p90': 0.2091},
              'percentiles': {'npg_p90': 27.9}
            },
            'why': 'lebih: Tembakan +14 | kurang: Tekel -11'
          }
        ]
      };

      final scoutResponse = ScoutResponse.fromJson(jsonFixture);

      expect(scoutResponse.archetype, 'ST');
      expect(scoutResponse.k, 5);
      expect(scoutResponse.results.length, 1);
      expect(scoutResponse.results.first.rank, 1);
      expect(scoutResponse.results.first.similarity, 62.7);
      expect(scoutResponse.results.first.player.name, 'Matthis Abline');
      expect(scoutResponse.results.first.why, 'lebih: Tembakan +14 | kurang: Tekel -11');
    });
  });
}
