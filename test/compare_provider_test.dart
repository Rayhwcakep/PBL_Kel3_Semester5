import 'package:flutter_test/flutter_test.dart';

import 'package:scout_ml/data/mock/mock_players.dart';
import 'package:scout_ml/data/repositories/scouting_repository.dart';
import 'package:scout_ml/data/services/mock_scouting_service.dart';
import 'package:scout_ml/state/compare_provider.dart';

CompareProvider _provider() => CompareProvider(
  repository: ScoutingRepository(
    service: MockScoutingService(latency: Duration.zero),
  ),
);

void main() {
  test('report terisi dari POST /compare saat dua pemain dipilih', () async {
    final provider = _provider();
    final a = mockPlayers[0];
    final b = mockPlayers[1];

    provider.add(a);
    expect(provider.report, isNull);

    provider.add(b);
    await provider.runCompare();

    final report = provider.report;
    expect(report, isNotNull);
    expect(report!.a.id, a.id);
    expect(report.b.id, b.id);
    expect(provider.isLoading, isFalse);
    expect(provider.error, isNull);
  });

  test('swap memuat ulang report dengan urutan pemain terbalik', () async {
    final provider = _provider();
    final a = mockPlayers[0];
    final b = mockPlayers[1];

    provider.add(a);
    provider.add(b);
    await provider.runCompare();
    expect(provider.report!.a.id, a.id);

    provider.swap();
    await provider.runCompare();

    expect(provider.report!.a.id, b.id);
    expect(provider.report!.b.id, a.id);
  });

  test('menghapus satu pemain mengosongkan report', () async {
    final provider = _provider();
    provider.add(mockPlayers[0]);
    provider.add(mockPlayers[1]);
    await provider.runCompare();
    expect(provider.report, isNotNull);

    provider.removeRight();

    expect(provider.isReady, isFalse);
    expect(provider.report, isNull);
  });
}
