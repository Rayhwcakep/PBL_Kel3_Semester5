import 'package:flutter_test/flutter_test.dart';

import 'package:scout_ml/data/cache/explain_cache.dart';
import 'package:scout_ml/data/models/explain_response.dart';
import 'package:scout_ml/data/repositories/scouting_repository.dart';
import 'package:scout_ml/data/services/mock_scouting_service.dart';

class _CountingService extends MockScoutingService {
  _CountingService({super.latency = Duration.zero});

  int explainCalls = 0;

  @override
  Future<PlayerExplain> explain(String id) {
    explainCalls++;
    return super.explain(id);
  }
}

void main() {
  group('ExplainCache /players/{id}/explain', () {
    test('permintaan kedua memakai cache tanpa memanggil backend', () async {
      final service = _CountingService();
      final repository = ScoutingRepository(
        service: service,
        explainCache: ExplainCache(),
      );

      final first = await repository.explain('p001');
      final second = await repository.explain('p001');

      expect(service.explainCalls, 1);
      expect(identical(first, second), isTrue);
    });

    test('permintaan bersamaan untuk pemain yang sama digabung', () async {
      final service = _CountingService(
        latency: const Duration(milliseconds: 20),
      );
      final repository = ScoutingRepository(
        service: service,
        explainCache: ExplainCache(),
      );

      final results = await Future.wait([
        repository.explain('p001'),
        repository.explain('p001'),
      ]);

      expect(service.explainCalls, 1);
      expect(identical(results[0], results[1]), isTrue);
    });

    test('refresh memaksa backend dipanggil lagi', () async {
      final service = _CountingService();
      final repository = ScoutingRepository(
        service: service,
        explainCache: ExplainCache(),
      );

      await repository.explain('p001');
      await repository.explain('p001', refresh: true);

      expect(service.explainCalls, 2);
    });

    test('cache kedaluwarsa setelah TTL', () async {
      var now = DateTime(2026, 1, 1, 12);
      final service = _CountingService();
      final repository = ScoutingRepository(
        service: service,
        explainCache: ExplainCache(
          ttl: const Duration(minutes: 5),
          now: () => now,
        ),
      );

      await repository.explain('p001');
      now = now.add(const Duration(minutes: 1));
      await repository.explain('p001');
      expect(service.explainCalls, 1, reason: 'masih dalam TTL');

      now = now.add(const Duration(minutes: 5));
      await repository.explain('p001');
      expect(service.explainCalls, 2, reason: 'sudah lewat TTL');
    });

    test('pemain berbeda punya entri cache sendiri', () async {
      final service = _CountingService();
      final repository = ScoutingRepository(
        service: service,
        explainCache: ExplainCache(),
      );

      await repository.explain('p001');
      await repository.explain('p004');
      await repository.explain('p001');

      expect(service.explainCalls, 2);
    });

    test('invalidate menghapus entri pemain', () async {
      final service = _CountingService();
      final cache = ExplainCache();
      final repository = ScoutingRepository(
        service: service,
        explainCache: cache,
      );

      await repository.explain('p001');
      expect(cache.length, 1);

      cache.invalidate('p001');
      expect(cache.length, 0);

      await repository.explain('p001');
      expect(service.explainCalls, 2);
    });
  });
}
