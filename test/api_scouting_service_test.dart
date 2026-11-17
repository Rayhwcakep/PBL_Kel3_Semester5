import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scout_ml/data/models/player_feature.dart';
import 'package:scout_ml/data/services/api_client.dart';
import 'package:scout_ml/data/services/api_scouting_service.dart';

/// Adapter Dio palsu: mencatat permintaan dan membalas JSON contoh.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final Map<String, dynamic> Function(RequestOptions options) respond;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(respond(options)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Pemain ringkas dengan bentuk yang sama seperti `PlayerOut` backend.
Map<String, dynamic> _playerJson(String id, String name) => {
  'id': id,
  'name': name,
  'club': 'Nantes',
  'league': 'Ligue 1',
  'position': 'Centre-Forward',
  'position_group': 'FW',
  'archetype': 'ST',
  'age': 22,
  'minutes': 2584.0,
  'market_value_eur': 20000000.0,
  'value_growth_1y': 0.111,
  'foot': 'right',
  'contract_until': '2028-06-30 00:00:00',
  'context': {'start_rate': 0.8485, 'plus_p90': -0.8362, 'crd_p90': 0.2091},
  'stats': {'npg_p90': 0.2091, 'sh_p90': 2.9268},
  'percentiles': {'npg_p90': 27.9, 'sh_p90': 74.2},
};

/// Satu baris `ContributionOut`.
Map<String, dynamic> _contributionJson({
  required String feature,
  required String label,
  required String verdict,
  double percentile = 27.9,
  double shapValue = -0.1189,
}) => {
  'feature': feature,
  'label': label,
  'value': 0.2091,
  'percentile': percentile,
  'better_than_pct': percentile,
  'shap_value': shapValue,
  'effect_pct': -11.21,
  'verdict': verdict,
};

/// Satu baris `CompareRowOut`.
Map<String, dynamic> _compareRowJson() => {
  'feature': 'sh_p90',
  'label': 'Tembakan',
  'a': 2.9268,
  'b': 2.233,
  'pct_a': 74.2,
  'pct_b': 36.6,
  'gap_pct': 37.6,
  'gap_good': 37.6,
  'winner': 'A',
  'rel_diff': 0.2371,
  'd_effect': 0.0574,
};

/// Satu baris `NeighborReasonOut`.
Map<String, dynamic> _reasonJson({double share = 0.0081}) => {
  'feature': 'fld_p90',
  'label': 'Pelanggaran diterima',
  'a': 1.4634,
  'b': 1.3592,
  'pct_a': 60.9,
  'pct_b': 55.0,
  'contribution': 0.0238,
  'share': share,
};

/// Membuat service yang diarahkan ke [respond] tanpa jaringan.
(ApiScoutingService, _FakeAdapter) _service(
  Map<String, dynamic> Function(RequestOptions options) respond,
) {
  final adapter = _FakeAdapter(respond);
  final dio = Dio(BaseOptions(baseUrl: 'http://uji.local/api/v1'))
    ..httpClientAdapter = adapter;
  return (ApiScoutingService(client: ApiClient(dio: dio)), adapter);
}

void main() {
  test('explain memanggil /players/{id}/explain dan membaca hasilnya', () async {
    final (service, adapter) = _service(
      (_) => {
        'player': _playerJson('7', 'Matthis Abline'),
        'strengths': [
          _contributionJson(
            feature: 'crs_p90',
            label: 'Umpan silang',
            verdict: 'kelebihan',
            percentile: 93.0,
            shapValue: 0.08,
          ),
        ],
        'weaknesses': [
          _contributionJson(
            feature: 'npg_p90',
            label: 'Gol non-penalti',
            verdict: 'kekurangan',
          ),
        ],
        'context': [
          _contributionJson(
            feature: 'Age',
            label: 'Usia',
            verdict: 'konteks',
            percentile: 0,
            shapValue: 0.3349,
          ),
        ],
        'summary': 'Matthis Abline (Striker, 22 tahun).',
      },
    );

    final explain = await service.explain('7');

    expect(adapter.requests.single.path, '/players/7/explain');
    expect(explain.player.name, 'Matthis Abline');
    expect(explain.player.archetype, 'ST');
    expect(explain.player.stats[PlayerFeature.shP90], closeTo(2.9268, 1e-4));
    expect(explain.strengths.single.label, 'Umpan silang');
    expect(explain.strengths.single.isStrength, isTrue);
    expect(explain.weaknesses.single.isWeakness, isTrue);
    expect(explain.context.single.feature, 'Age');
    expect(explain.summary, contains('22 tahun'));
  });

  test('similarPlayers memanggil /players/{id}/similar dan membaca tetangga',
      () async {
    final (service, adapter) = _service(
      (_) => {
        'player': _playerJson('7', 'Matthis Abline'),
        'same_archetype': true,
        'neighbors': [
          {
            'player': _playerJson('663', 'Ignatius Ganago'),
            'similarity': 66.41,
            'distance': 1.7114,
            'rank': 1,
            'closer_than_pct': 99.6,
          },
        ],
        'similar_because': [_reasonJson()],
        'different_because': [_reasonJson(share: 0.4669)],
      },
    );

    final similar = await service.similarPlayers('7', limit: 3);

    expect(adapter.requests.single.path, '/players/7/similar');
    expect(adapter.requests.single.queryParameters['limit'], 3);
    expect(similar.sameArchetype, isTrue);
    expect(similar.neighbors.single.player.name, 'Ignatius Ganago');
    expect(similar.neighbors.single.rank, 1);
    expect(similar.neighbors.single.similarity, closeTo(66.41, 1e-4));
    expect(similar.similarBecause.single.share, closeTo(0.0081, 1e-4));
    expect(similar.differentBecause.single.share, closeTo(0.4669, 1e-4));
  });

  test('tacticFit mengirim slider sebagai "stat=persentil"', () async {
    final (service, adapter) = _service(
      (_) => {
        'player': _playerJson('7', 'Matthis Abline'),
        'tactic': 'poacher',
        'similarity': 37.02,
        'tepat_sasaran': true,
        'target_percentiles': {'npg_p90': 90.0, 'sh_p90': 80.0},
        'rows': [
          {
            'feature': 'npg_p90',
            'label': 'Gol non-penalti',
            'value': 0.2091,
            'target_value': 0.5647,
            'pct_player': 27.9,
            'pct_target': 90.0,
            'good_player': 27.9,
            'good_target': 90.0,
            'delta_good': -62.1,
            'contrib': 8.1387,
            'share': 0.4714,
            'verdict': 'kekurangan',
          },
        ],
        'over': <Map<String, dynamic>>[],
        'under': [
          {
            'feature': 'npg_p90',
            'label': 'Gol non-penalti',
            'pct_player': 27.9,
            'pct_target': 90.0,
            'delta_good': -62.1,
          },
        ],
      },
    );

    final fit = await service.tacticFit(
      '7',
      tactic: 'poacher',
      sliders: {PlayerFeature.npgP90: 90, PlayerFeature.shP90: 80},
    );

    final query = adapter.requests.single.queryParameters;
    expect(adapter.requests.single.path, '/players/7/fit');
    expect(query['tactic'], 'poacher');
    expect(query['sliders'], 'npg_p90=90.0,sh_p90=80.0');    expect(fit.isOnTarget, isTrue);
    expect(fit.similarity, closeTo(37.02, 1e-4));
    expect(fit.targetPercentiles['npg_p90'], 90.0);
    expect(fit.rows.single.verdict, 'kekurangan');
    expect(fit.rows.single.contribution, closeTo(8.1387, 1e-4));
    expect(fit.over, isEmpty);
    expect(fit.under.single.deltaGood, closeTo(-62.1, 1e-4));
  });

  test('tacticFit tidak mengirim parameter yang kosong', () async {
    final (service, adapter) = _service(
      (_) => {
        'player': _playerJson('7', 'Matthis Abline'),
        'similarity': 37.02,
        'tepat_sasaran': false,
        'target_percentiles': {'npg_p90': 90.0},
        'rows': <Map<String, dynamic>>[],
        'over': <Map<String, dynamic>>[],
        'under': <Map<String, dynamic>>[],
      },
    );

    await service.tacticFit('7', tactic: 'poacher');

    // `sliders` kosong tidak boleh jadi `?sliders` di URL: backend bisa
    // membacanya sebagai daftar slider yang tidak valid.
    final query = adapter.requests.single.queryParameters;
    expect(query['tactic'], 'poacher');
    expect(query.containsKey('sliders'), isFalse);
  });

  test('bestFit memanggil /best-fit/{id} dengan filter dan membaca kandidat',
      () async {
    final (service, adapter) = _service(
      (_) => {
        'player': _playerJson('7', 'Matthis Abline'),
        'needs': {'npg_p90': 0.1189},
        'keep': <String, double>{},
        'candidates': [
          {
            'player': _playerJson('181', 'Maximilian Beier'),
            'similarity': 54.2558,
            'fit': 74.6,
            'gain': 0.45,
            'loss': 0.0,
            'why': 'Menutup: Gol non-penalti (+45) | Mengorbankan: -',
          },
        ],
      },
    );

    final bestFit = await service.bestFit(
      '7',
      topK: 2,
      needs: ['npg_p90'],
      improveWeight: 0.5,
    );

    final query = adapter.requests.single.queryParameters;
    expect(adapter.requests.single.path, '/best-fit/7');
    expect(query['top_k'], 2);
    expect(query['needs'], 'npg_p90');
    expect(query['improve_weight'], 0.5);
    expect(bestFit.needs['npg_p90'], closeTo(0.1189, 1e-4));
    expect(bestFit.candidates.single.player.name, 'Maximilian Beier');
    expect(bestFit.candidates.single.fit, closeTo(74.6, 1e-4));
    expect(bestFit.candidates.single.gain, closeTo(0.45, 1e-4));
    expect(bestFit.candidates.single.why, startsWith('Menutup:'));
  });

  test('compare mengirim dua id ke POST /compare dan membaca tabelnya',
      () async {
    final (service, adapter) = _service(
      (_) => {
        'a': _playerJson('7', 'Matthis Abline'),
        'b': _playerJson('663', 'Ignatius Ganago'),
        'same_archetype': true,
        'warning': null,
        'similarity': 66.41,
        'neighbor_rank': 1,
        'rows': [_compareRowJson()],
        'a_better': [_compareRowJson()],
        'b_better': <Map<String, dynamic>>[],
        'raw_only': <Map<String, dynamic>>[],
        'summary': 'Matthis Abline unggul di: Tembakan.',
      },
    );

    final report = await service.compare('7', '663');

    final request = adapter.requests.single;
    expect(request.path, '/compare');
    expect(request.method, 'POST');
    expect((request.data as Map)['a'], '7');
    expect((request.data as Map)['b'], '663');
    expect(report.sameArchetype, isTrue);
    expect(report.warning, isNull);
    expect(report.similarity, closeTo(66.41, 1e-4));
    expect(report.neighborRank, 1);
    expect(report.rows.single.gapGood, closeTo(37.6, 1e-4));
    expect(report.rows.single.aWins, isTrue);
    expect(report.aBetter.single.label, 'Tembakan');
    expect(report.bBetter, isEmpty);
    expect(report.summary, contains('Tembakan'));
  });

  test('fetchTactics memanggil /meta/tactics dan membaca preset', () async {
    final (service, adapter) = _service(
      (_) => {
        'archetypes': [
          {
            'archetype': 'ST',
            'label': 'Striker',
            'presets': [
              {
                'key': 'poacher',
                'label': 'Poacher',
                'description': 'Banyak tembakan di kotak penalti.',
                'targets': {'npg_p90': 90.0, 'sh_p90': 80.0},
              },
            ],
          },
        ],
        'value_models': {
          'ST': {
            'r2_test': 0.561,
            'reliability': 'baik',
            'n': 242,
            'base_value_eur': 9191828,
          },
        },
      },
    );

    final catalog = await service.fetchTactics();

    expect(adapter.requests.single.path, '/meta/tactics');
    expect(catalog.archetypes.single.label, 'Striker');
    expect(catalog.archetypes.single.presets.single.key, 'poacher');
    expect(catalog.archetypes.single.preset('poacher')?.targets['npg_p90'], 90.0);
    expect(catalog.valueModels['ST']?.r2Test, closeTo(0.561, 1e-4));
    expect(catalog.valueModels['ST']?.reliability, 'baik');
    expect(catalog.valueModels['ST']?.count, 242);
  });

  test('fetchFeatures memanggil /meta/features dan membaca metadata', () async {
    final (service, adapter) = _service(
      (_) => {
        'archetypes': [
          {
            'key': 'ST',
            'label': 'Striker',
            'players': 242,
            'features': [
              {
                'key': 'npg_p90',
                'label': 'Gol non-penalti',
                'unit': 'per90',
                'good_dir': 1,
                'invert': false,
                'weight': 1.0,
              },
              {
                'key': 'off_p90',
                'label': 'Offside',
                'unit': 'per90',
                'good_dir': -1,
                'invert': true,
                'weight': 1.0,
              },
            ],
          },
        ],
        'context_labels': {'Age': 'Usia', 'Min': 'Menit main'},
        'min_effect': 0.03,
        'min_pct_gap': 10.0,
        'hexagon_axes': {
          'outfield': [
            {'label': 'Gol non-penalti', 'feature': 'npg_p90', 'invert': false},
          ],
          'GK': [
            {'label': 'Kebobolan', 'feature': 'ga_p90', 'invert': true},
          ],
        },
      },
    );

    final catalog = await service.fetchFeatures();

    expect(adapter.requests.single.path, '/meta/features');
    expect(catalog.archetypes.single.players, 242);
    expect(catalog.archetypes.single.labelFor('off_p90'), 'Offside');
    expect(catalog.archetypes.single.features.last.invert, isTrue);
    expect(catalog.archetypes.single.features.last.goodDir, -1);
    expect(catalog.contextLabels['Age'], 'Usia');
    expect(catalog.minEffect, closeTo(0.03, 1e-4));
    expect(catalog.minPctGap, closeTo(10, 1e-4));
    expect(catalog.hexagonAxes['outfield']?.single.feature, 'npg_p90');
    expect(catalog.hexagonAxes['GK']?.single.invert, isTrue);
  });
}
