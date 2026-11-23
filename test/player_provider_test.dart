import 'package:flutter_test/flutter_test.dart';

import 'package:scout_ml/data/mock/mock_players.dart';
import 'package:scout_ml/data/models/player_query.dart';
import 'package:scout_ml/data/repositories/scouting_repository.dart';
import 'package:scout_ml/data/services/mock_scouting_service.dart';
import 'package:scout_ml/state/player_provider.dart';

PlayerProvider _provider() => PlayerProvider(
  repository: ScoutingRepository(
    service: MockScoutingService(latency: Duration.zero),
  ),
);

void main() {
  test('loadPlayers meneruskan filter ke GET /players', () async {
    final provider = _provider();
    const filter = PlayerQuery(archetype: 'ST', maxAge: 23);

    await provider.loadPlayers(filter: filter);

    expect(provider.players, isNotEmpty);
    expect(provider.players.every((p) => p.archetype == 'ST'), isTrue);
    expect(provider.players.every((p) => p.age <= 23), isTrue);
  });

  test('searchPlayers tidak mengubah daftar utama', () async {
    final provider = _provider();
    await provider.loadPlayers();
    final before = provider.players.length;

    final results = await provider.searchPlayers(
      const PlayerQuery(search: 'a', limit: 3),
    );

    expect(results.length, lessThanOrEqualTo(3));
    expect(provider.players.length, before);
  });

  test('filter max_value_eur membatasi nilai pasar', () async {
    final provider = _provider();
    const limit = 50000000.0;

    final results = await provider.searchPlayers(
      const PlayerQuery(maxValueEur: limit),
    );

    expect(results, isNotEmpty);
    expect(results.every((p) => p.marketValueEur <= limit), isTrue);
    expect(results.length, lessThan(mockPlayers.length));
  });
}
