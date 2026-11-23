import 'dart:math' as math;

import '../mock/mock_players.dart';
import '../mock/mock_tactics.dart';
import '../models/best_fit.dart';
import '../models/compare_report.dart';
import '../models/explain_response.dart';
import '../models/feature_catalog.dart';
import '../models/feature_contribution.dart';
import '../models/player.dart';
import '../models/player_feature.dart';
import '../models/player_query.dart';
import '../models/scout_response.dart';
import '../models/scouting_criteria.dart';
import '../models/scouting_result.dart';
import '../models/similar_response.dart';
import '../models/tactic_fit.dart';
import '../models/tactics_catalog.dart';
import 'scouting_service.dart';

/// Nama tampilan arketipe. Disalin dari `GET /meta/features` karena data
/// contoh tidak memuat metadata backend.
const Map<String, String> _archetypeLabels = {
  'GK': 'Kiper',
  'CB': 'Bek tengah',
  'FB': 'Bek sayap',
  'DM': 'Gelandang bertahan',
  'CM': 'Gelandang tengah',
  'AM': 'Gelandang serang',
  'W': 'Pemain sayap',
  'ST': 'Striker',
};

/// Pemetaan sementara preset contoh ke kode arketipe backend.
const Map<String, String> _presetArchetype = {
  'poacher': 'ST',
  'target_man': 'ST',
  'creative_fwd': 'AM',
  'inverted_winger': 'W',
};

/// Implementasi [ScoutingService] memakai data contoh.
///
/// Perhitungan KNN di bawah ini hanya *tiruan* agar tampilan punya data,
/// tetapi bentuk balasannya sama dengan backend: skor kemiripan 0-100,
/// profil target, dan alasan `why`. Saat backend FastAPI siap, ganti ke
/// `ApiScoutingService` (lihat `AppConfig.useMockData`).
class MockScoutingService implements ScoutingService {
  MockScoutingService({this.latency = const Duration(milliseconds: 600)});

  /// Jeda buatan supaya indikator loading terlihat.
  final Duration latency;

  /// Jarak yang dianggap "tipikal" antar pemain searketipe, dipakai supaya
  /// skor kemiripan jatuh di sekitar 37 seperti rumus backend.
  static const double _typicalDistance = 0.35;

  @override
  Future<List<Player>> fetchPlayers({PlayerQuery? filter}) async {
    await Future<void>.delayed(latency);
    return List<Player>.unmodifiable(_filterPlayers(filter));
  }

  /// Meniru filter `GET /players` pada data contoh.
  List<Player> _filterPlayers(PlayerQuery? filter) {
    if (filter == null) return mockPlayers;

    var items = mockPlayers.where((player) {
      if (filter.archetype != null && player.archetype != filter.archetype) {
        return false;
      }
      if (filter.league != null &&
          !player.league.toLowerCase().contains(filter.league!.toLowerCase())) {
        return false;
      }
      if (filter.minAge != null && player.age < filter.minAge!) return false;
      if (filter.maxAge != null && player.age > filter.maxAge!) return false;
      if (filter.maxValueEur != null &&
          player.marketValueEur > filter.maxValueEur!) {
        return false;
      }
      if (filter.search != null) {
        final needle = filter.search!.toLowerCase();
        final matchesName = player.name.toLowerCase().contains(needle);
        final matchesClub = player.club.toLowerCase().contains(needle);
        if (!matchesName && !matchesClub) return false;
      }
      return true;
    }).toList();

    final offset = filter.offset ?? 0;
    if (offset > 0) {
      items = items.skip(offset).toList();
    }
    if (filter.limit != null) {
      items = items.take(filter.limit!).toList();
    }
    return items;
  }

  @override
  Future<Player> fetchPlayer(String id) async {
    await Future<void>.delayed(latency);
    return mockPlayers.firstWhere((player) => player.id == id);
  }

  @override
  Future<ScoutResponse> scout(ScoutingCriteria criteria) async {
    await Future<void>.delayed(latency);

    final features = PlayerFeature.forArchetype(criteria.archetype);
    // Slider taktik memakai persentil, pencarian biasa memakai per-90 nyata.
    final byPercentile = criteria.isTacticSearch;
    final targets = byPercentile ? (criteria.sliders ?? {}) : criteria.values;

    final candidates = mockPlayers.where((player) {
      if (player.archetype != criteria.archetype) return false;
      if (criteria.basePlayerId != null && player.id == criteria.basePlayerId) {
        return false;
      }
      if (criteria.league != null && player.league != criteria.league) {
        return false;
      }
      if (criteria.minAge != null && player.age < criteria.minAge!) {
        return false;
      }
      if (criteria.maxAge != null && player.age > criteria.maxAge!) {
        return false;
      }
      if (criteria.maxValue != null && player.marketValue > criteria.maxValue!) {
        return false;
      }
      return true;
    }).toList();

    double valueOf(Player player, PlayerFeature feature) => byPercentile
        ? player.percentile(feature)
        : player.stat(feature);

    final targetVector = features
        .map((feature) => targets[feature] ?? 0)
        .toList(growable: false);

    final scored = <(Player, double)>[];
    for (final player in candidates) {
      final vector = features
          .map((feature) => valueOf(player, feature))
          .toList(growable: false);
      scored.add((player, _euclidean(targetVector, vector)));
    }
    scored.sort((a, b) => a.$2.compareTo(b.$2));

    final results = <ScoutingResult>[];
    final top = scored.take(criteria.topK).toList();
    for (var i = 0; i < top.length; i++) {
      final (player, distance) = top[i];
      results.add(
        ScoutingResult(
          player: player,
          similarity: 100 * math.exp(-distance / _typicalDistance),
          distance: distance,
          rank: i + 1,
          why: _reason(features, targets, player, valueOf),
          contributions: _fakeShap(features, targets, player, valueOf),
        ),
      );
    }

    return ScoutResponse(
      archetype: criteria.archetype,
      tactic: criteria.tactic,
      k: criteria.topK,
      target: {
        for (final feature in features)
          feature: byPercentile
              ? _medianOf(feature)
              : (targets[feature] ?? 0),
      },
      targetPercentiles: {
        for (final feature in features)
          feature: byPercentile
              ? (targets[feature] ?? 0)
              : _percentileOf(feature, targets[feature] ?? 0),
      },
      results: results,
    );
  }

  @override
  Future<PlayerExplain> explain(String id) async {
    await Future<void>.delayed(latency);
    final player = _player(id);

    final fixture = _explainFixture(player);
    if (fixture != null) return fixture;

    final rows = [
      for (final feature in player.radarAxes) _explainRow(player, feature),
    ]..sort((a, b) => b.shapValue.compareTo(a.shapValue));

    final strengths = rows.where((row) => row.isStrength).take(3).toList();
    final weaknesses = rows.where((row) => row.isWeakness).toList()
      ..sort((a, b) => a.shapValue.compareTo(b.shapValue));

    return PlayerExplain(
      player: player,
      strengths: strengths,
      weaknesses: weaknesses.take(3).toList(),
      // Data contoh tidak punya SHAP variabel konteks, jadi daftarnya kosong.
      summary: _explainSummary(player, strengths, weaknesses),
    );
  }

  /// Pemain contoh yang punya potret balasan SHAP asli dari backend.
  ///
  /// Dicocokkan lewat [Player.id], bukan teks nama, supaya fixture tidak
  /// diam-diam berhenti terpakai saat nama di `mockPlayers` berubah.
  static const String explainFixturePlayerId = 'p001';

  /// Potret balasan backend asli untuk [explainFixturePlayerId]
  /// (notebook Langkah 15).
  ///
  /// Angka effect_pct tidak bisa diturunkan dari persentil saja karena berasal
  /// dari model nilai pasar, jadi disalin apa adanya agar layar Insight
  /// menampilkan kalimat yang sama dengan `GET /players/1959/explain`.
  PlayerExplain? _explainFixture(Player player) {
    if (player.id != explainFixturePlayerId) return null;

    ExplainContribution row({
      required String feature,
      required String label,
      required double value,
      required double percentile,
      required double betterThanPct,
      required double effectPct,
      required String verdict,
    }) {
      return ExplainContribution(
        feature: feature,
        label: label,
        value: value,
        percentile: percentile,
        betterThanPct: betterThanPct,
        shapValue: math.log(1 + effectPct / 100),
        effectPct: effectPct,
        verdict: verdict,
      );
    }

    ExplainContribution context({
      required String feature,
      required String label,
      required double effectPct,
    }) {
      return row(
        feature: feature,
        label: label,
        value: 0,
        percentile: 0,
        betterThanPct: 0,
        effectPct: effectPct,
        verdict: 'konteks',
      );
    }

    return PlayerExplain(
      player: player,
      strengths: [
        row(
          feature: 'sh_p90',
          label: 'Tembakan',
          value: 4.66,
          percentile: 100,
          betterThanPct: 100,
          effectPct: 77,
          verdict: 'kelebihan',
        ),
        row(
          feature: 'npg_p90',
          label: 'Gol non-penalti',
          value: 0.52,
          percentile: 96,
          betterThanPct: 96,
          effectPct: 33,
          verdict: 'kelebihan',
        ),
        row(
          feature: 'ast_p90',
          label: 'Assist',
          value: 0.44,
          percentile: 98,
          betterThanPct: 98,
          effectPct: 11,
          verdict: 'kelebihan',
        ),
        row(
          feature: 'fld_p90',
          label: 'Pelanggaran diterima',
          value: 2.07,
          percentile: 82,
          betterThanPct: 82,
          effectPct: 4,
          verdict: 'kelebihan',
        ),
        row(
          feature: 'sot_p90',
          label: 'Tembakan on target',
          value: 1.47,
          percentile: 96,
          betterThanPct: 96,
          effectPct: 4,
          verdict: 'kelebihan',
        ),
      ],
      context: [
        context(feature: 'Age', label: 'Usia', effectPct: 54),
        context(feature: 'Min', label: 'Menit main', effectPct: 18),
        context(
          feature: 'start_rate',
          label: 'Rasio jadi starter',
          effectPct: 35,
        ),
        context(
          feature: 'plus_p90',
          label: 'Plus/minus per 90',
          effectPct: 123,
        ),
        context(feature: 'ctx_liga', label: 'Liga', effectPct: -22),
      ],
      summary:
          '${player.name} (${player.position}, ${player.age} tahun, '
          '${player.marketValueLabel}). '
          'Kelebihan: Tembakan (+77%), Gol non-penalti (+33%). '
          'Kekurangan: tidak ada yang menonjol. '
          'Keandalan model nilai pasar: baik (R² uji 0.57).',
    );
  }

  @override
  Future<SimilarPlayers> similarPlayers(String id, {int limit = 10}) async {
    await Future<void>.delayed(latency);
    final base = _player(id);
    final features = base.radarAxes;

    final scored = [
      for (final other in mockPlayers)
        if (other.id != base.id && other.archetype == base.archetype)
          (other, _percentileDistance(base, other, features)),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    final top = scored.take(limit).toList();

    final neighbors = <SimilarNeighbor>[
      for (var i = 0; i < top.length; i++)
        SimilarNeighbor(
          player: top[i].$1,
          similarity: 100 * math.exp(-top[i].$2 / _typicalDistance),
          distance: top[i].$2,
          rank: i + 1,
          closerThanPct: 100 *
              (1 - (i + 1) / math.max(mockPlayers.length - 1, 1)),
        ),
    ];

    final reasons = _reasons(base, top.isEmpty ? null : top.first.$1, features);
    return SimilarPlayers(
      player: base,
      sameArchetype: true,
      neighbors: neighbors,
      similarBecause: reasons.$1,
      differentBecause: reasons.$2,
    );
  }

  @override
  Future<TacticFit> tacticFit(
    String id, {
    String? tactic,
    Map<PlayerFeature, double>? sliders,
  }) async {
    await Future<void>.delayed(latency);
    final player = _player(id);
    final features = player.radarAxes;

    final targets = <PlayerFeature, double>{};
    if (sliders != null && sliders.isNotEmpty) {
      targets.addAll(sliders);
    } else if (tactic != null) {
      final preset = _presetTargets(tactic);
      if (preset != null) targets.addAll(preset);
    }
    for (final feature in features) {
      targets.putIfAbsent(feature, () => 50);
    }

    // Kontribusi setiap statistik dihitung dulu agar porsinya bisa dibagi.
    final gaps = <PlayerFeature, (double, double)>{};
    for (final feature in features) {
      final goodTarget = feature.isInverted
          ? 100 - targets[feature]!
          : targets[feature]!;
      gaps[feature] = (player.radarValue(feature), goodTarget);
    }
    final total = gaps.values
        .map((gap) => math.pow((gap.$1 - gap.$2) / 100, 2))
        .fold(0.0, (sum, value) => sum + value);

    final rows = [
      for (final feature in features) _fitRow(player, feature, targets, total),
    ]..sort((a, b) => b.contribution.compareTo(a.contribution));

    final distance = total == 0 ? 0.0 : math.sqrt(total / features.length);
    return TacticFit(
      player: player,
      tactic: tactic,
      similarity: 100 * math.exp(-distance / _typicalDistance),
      isOnTarget: rows.any((row) => row.verdict == 'sesuai'),
      targetPercentiles: {
        for (final entry in targets.entries) entry.key.jsonKey: entry.value,
      },
      rows: rows,
      over: _gaps(
        rows.where((row) => row.verdict == 'kelebihan').toList()
          ..sort((a, b) => b.deltaGood.compareTo(a.deltaGood)),
      ),
      under: _gaps(
        rows.where((row) => row.verdict == 'kekurangan').toList()
          ..sort((a, b) => a.deltaGood.compareTo(b.deltaGood)),
      ),
    );
  }

  @override
  Future<BestFit> bestFit(
    String id, {
    int topK = 5,
    List<String>? needs,
    double improveWeight = 0.5,
    int? maxAge,
    double? maxValueEur,
  }) async {
    await Future<void>.delayed(latency);
    final base = _player(id);
    final features = base.radarAxes;

    // Kebutuhan: statistik yang diminta, atau persentil terendah pemain.
    final wanted = <PlayerFeature>[
      if (needs != null)
        for (final key in needs)
          if (PlayerFeature.fromJsonKey(key) != null)
            PlayerFeature.fromJsonKey(key)!,
    ];
    if (wanted.isEmpty) {
      final sortedByPercentile = [...features]
        ..sort((a, b) => base.percentile(a).compareTo(base.percentile(b)));
      wanted.add(sortedByPercentile.first);
    }
    final kept = [
      for (final feature in features)
        if (base.percentile(feature) >= 60) feature,
    ];

    // Ambil semua tetangga lalu saring dulu, seperti backend yang menerapkan
    // filter umur/harga sebelum memeringkat. Meminta `topK` lebih dulu akan
    // menyisakan kandidat lebih sedikit dari yang diminta.
    final similar = await similarPlayers(id, limit: mockPlayers.length);
    final eligible = [
      for (final neighbor in similar.neighbors)
        if ((maxAge == null || neighbor.player.age <= maxAge) &&
            (maxValueEur == null ||
                neighbor.player.marketValueEur <= maxValueEur))
          neighbor,
    ];
    final candidates = <BestFitCandidate>[];
    for (final neighbor in eligible.take(topK)) {
      final others = neighbor.player;
      double closeUp(PlayerFeature feature) {
        final gain = others.percentile(feature) - base.percentile(feature);
        return gain <= 0 ? 0 : gain / 100;
      }

      double sacrifice(PlayerFeature feature) {
        final loss = base.percentile(feature) - others.percentile(feature);
        return loss <= 0 ? 0 : loss / 100;
      }

      final gain =
          wanted.map(closeUp).fold(0.0, (sum, value) => sum + value) /
          wanted.length;
      final loss = kept.isEmpty
          ? 0.0
          : kept.map(sacrifice).fold(0.0, (sum, value) => sum + value) /
                kept.length;
      final fit =
          neighbor.similarity * (1 - improveWeight) + gain * 100 * improveWeight;

      final closed = [
        for (final feature in wanted)
          if (others.percentile(feature) > base.percentile(feature))
            '${feature.label} '
                '(+${(others.percentile(feature) - base.percentile(feature)).round()})',
      ];
      final dropped = [
        for (final feature in kept)
          if (base.percentile(feature) - others.percentile(feature) > 10)
            feature.label,
      ];

      candidates.add(
        BestFitCandidate(
          player: others,
          similarity: neighbor.similarity,
          fit: fit,
          gain: gain,
          loss: loss,
          why: 'Menutup: '
              '${closed.isEmpty ? '-' : closed.take(2).join(', ')} | '
              'Mengorbankan: ${dropped.isEmpty ? '-' : dropped.take(2).join(', ')}',
        ),
      );
    }
    candidates.sort((a, b) => b.fit.compareTo(a.fit));

    return BestFit(
      player: base,
      needs: {
        for (final feature in wanted)
          feature.jsonKey: math.max(0, 50 - base.percentile(feature)) / 100,
      },
      keep: {
        for (final feature in kept) feature.jsonKey: base.percentile(feature),
      },
      candidates: candidates,
    );
  }

  @override
  Future<CompareReport> compare(String aId, String bId) async {
    await Future<void>.delayed(latency);
    final a = _player(aId);
    final b = _player(bId);
    final sameArchetype = a.archetype == b.archetype;
    // Beda arketipe tidak punya sumbu bersama, jadi backend membandingkan
    // statistik yang muncul di kedua arketipe saja.
    final features = sameArchetype
        ? a.radarAxes
        : [
            for (final feature in a.radarAxes)
              if (b.radarAxes.contains(feature)) feature,
          ];

    final rows = [
      for (final feature in features)
        _compareRow(a, b, feature, sameArchetype: sameArchetype),
    ]..sort((x, y) => y.gapGood.abs().compareTo(x.gapGood.abs()));
    final aBetter = rows.where((row) => row.aWins).toList();
    final bBetter = rows.where((row) => row.bWins).toList();

    return CompareReport(
      a: a,
      b: b,
      sameArchetype: sameArchetype,
      warning: sameArchetype
          ? null
          : 'Arketipe ${a.archetype} dan ${b.archetype} berbeda, '
                'angka statistiknya tidak sebanding.',
      similarity: sameArchetype
          ? 100 *
                math.exp(
                  -_percentileDistance(a, b, features) / _typicalDistance,
                )
          : null,
      neighborRank: sameArchetype ? _neighborRank(a, b) : null,
      rows: rows,
      aBetter: aBetter,
      bBetter: bBetter,
      // Data contoh tidak punya model nilai pasar, jadi tidak ada baris
      // "angka beda tapi arah model berlawanan".
      summary: _compareSummary(a, b, aBetter, bBetter),
    );
  }

  @override
  Future<TacticsCatalog> fetchTactics() async {
    await Future<void>.delayed(latency);
    final presets = <String, List<TacticPreset>>{};
    for (final archetype in mockArchetypes) {
      final code = _presetArchetype[archetype.id];
      if (code == null) continue;
      presets.putIfAbsent(code, () => []).add(
        TacticPreset(
          key: archetype.id,
          label: archetype.name,
          description: archetype.description,
          targets: {
            for (final entry in archetype.toFeatureValues().entries)
              entry.key.jsonKey: entry.value,
          },
        ),
      );
    }

    return TacticsCatalog(
      archetypes: [
        for (final entry in presets.entries)
          TacticArchetypeInfo(
            archetype: entry.key,
            label: _archetypeLabels[entry.key] ?? entry.key,
            presets: entry.value,
          ),
      ],
      // Data contoh tidak memuat R² model nilai pasar.
    );
  }

  @override
  Future<FeatureCatalog> fetchFeatures() async {
    await Future<void>.delayed(latency);
    final archetypes = <ArchetypeInfo>[];
    for (final entry in _archetypeLabels.entries) {
      final players = mockPlayers
          .where((player) => player.archetype == entry.key)
          .toList();
      if (players.isEmpty) continue;
      archetypes.add(
        ArchetypeInfo(
          key: entry.key,
          label: entry.value,
          players: players.length,
          features: [
            for (final feature in players.first.radarAxes)
              ArchetypeFeature(
                key: feature.jsonKey,
                label: feature.label,
                goodDir: _goodDir(feature),
                invert: feature.isInverted,
              ),
          ],
        ),
      );
    }

    return FeatureCatalog(
      archetypes: archetypes,
      contextLabels: const {
        'Age': 'Usia',
        'Min': 'Menit main',
        'start_rate': 'Rasio jadi starter',
        'plus_p90': 'Plus/minus per 90',
        'crd_p90': 'Kartu kuning per 90',
        'ctx_liga': 'Liga',
      },
      hexagonAxes: {
        'outfield': [for (final feature in PlayerFeature.outfield) _axis(feature)],
        'GK': [for (final feature in PlayerFeature.goalkeeper) _axis(feature)],
      },
    );
  }

  Player _player(String id) =>
      mockPlayers.firstWhere((player) => player.id == id);

  /// Satu baris SHAP tiruan: simpangan persentil dari rata-rata arketipe.
  ExplainContribution _explainRow(Player player, PlayerFeature feature) {
    final percentile = player.percentile(feature);
    final shap = (player.radarValue(feature) - 50) / 100 * 0.4;
    return ExplainContribution(
      feature: feature.jsonKey,
      label: feature.label,
      value: player.stat(feature),
      percentile: percentile,
      betterThanPct: player.radarValue(feature),
      shapValue: shap,
      effectPct: shap * 100,
      verdict: percentile >= 65
          ? 'kelebihan'
          : (percentile <= 35 ? 'kekurangan' : 'netral'),
    );
  }

  String _explainSummary(
    Player player,
    List<ExplainContribution> strengths,
    List<ExplainContribution> weaknesses,
  ) {
    final good = strengths.isEmpty
        ? 'tidak ada yang menonjol'
        : strengths.map((row) => row.label).join(', ');
    final bad = weaknesses.isEmpty
        ? 'tidak ada'
        : weaknesses
              .map(
                (row) => '${row.label} (${row.effectPct.toStringAsFixed(0)}%)',
              )
              .join(', ');
    return '${player.name} (${player.position}, ${player.age} tahun). '
        'Kelebihan: $good. Kekurangan: $bad.';
  }

  /// Jarak antar dua pemain pada persentil 0-100, dinormalkan ke 0-1.
  double _percentileDistance(
    Player a,
    Player b,
    List<PlayerFeature> features,
  ) {
    if (features.isEmpty) return 0;
    var sum = 0.0;
    for (final feature in features) {
      final diff = (a.radarValue(feature) - b.radarValue(feature)) / 100;
      sum += diff * diff;
    }
    return math.sqrt(sum / features.length);
  }

  /// Statistik yang paling menyamakan dan paling membedakan dua pemain.
  (List<NeighborReason>, List<NeighborReason>) _reasons(
    Player base,
    Player? neighbor,
    List<PlayerFeature> features,
  ) {
    if (neighbor == null) return (const [], const []);

    final diffs = {
      for (final feature in features)
        feature: (base.radarValue(feature) - neighbor.radarValue(feature)) / 100,
    };
    final total = diffs.values
        .map((diff) => diff * diff)
        .fold(0.0, (sum, value) => sum + value);

    final rows = [
      for (final feature in features)
        NeighborReason(
          feature: feature.jsonKey,
          label: feature.label,
          a: base.stat(feature),
          b: neighbor.stat(feature),
          pctA: base.percentile(feature),
          pctB: neighbor.percentile(feature),
          contribution: diffs[feature]! * diffs[feature]!,
          share: total == 0 ? 0 : diffs[feature]! * diffs[feature]! / total,
        ),
    ];

    final closest = [...rows]..sort((a, b) => a.share.compareTo(b.share));
    final farthest = [...rows]..sort((a, b) => b.share.compareTo(a.share));
    return (closest.take(3).toList(), farthest.take(3).toList());
  }

  /// Target persentil sebuah preset contoh. `null` bila preset tidak ada.
  Map<PlayerFeature, double>? _presetTargets(String tactic) {
    for (final archetype in mockArchetypes) {
      if (archetype.id == tactic) return archetype.toFeatureValues();
    }
    return null;
  }

  TacticFitRow _fitRow(
    Player player,
    PlayerFeature feature,
    Map<PlayerFeature, double> targets,
    double total,
  ) {
    final pctPlayer = player.percentile(feature);
    final pctTarget = targets[feature] ?? 50;
    final goodPlayer = player.radarValue(feature);
    final goodTarget = feature.isInverted ? 100 - pctTarget : pctTarget;
    final deltaGood = goodPlayer - goodTarget;
    final diff = deltaGood / 100;
    final contribution = diff * diff;

    // Aturan yang sama dengan `verdict()` backend: penyimpangan hanya
    // disebut kelebihan/kekurangan bila taktik meminta nilai tinggi.
    final verdict = goodTarget >= 60
        ? (deltaGood >= 10
              ? 'kelebihan'
              : (deltaGood <= -10 ? 'kekurangan' : 'sesuai'))
        : (deltaGood >= 10 ? 'beda profil' : 'sesuai');

    return TacticFitRow(
      feature: feature.jsonKey,
      label: feature.label,
      value: player.stat(feature),
      targetValue: pctTarget,
      pctPlayer: pctPlayer,
      pctTarget: pctTarget,
      goodPlayer: goodPlayer,
      goodTarget: goodTarget,
      deltaGood: deltaGood,
      contribution: contribution,
      share: total == 0 ? 0 : contribution / total,
      verdict: verdict,
    );
  }

  List<TacticFitGap> _gaps(List<TacticFitRow> rows) => [
    for (final row in rows)
      TacticFitGap(
        feature: row.feature,
        label: row.label,
        pctPlayer: row.pctPlayer,
        pctTarget: row.pctTarget,
        deltaGood: row.deltaGood,
      ),
  ];

  CompareRow _compareRow(
    Player a,
    Player b,
    PlayerFeature feature, {
    bool sameArchetype = true,
  }) {
    final rawA = a.stat(feature);
    final rawB = b.stat(feature);
    final pctA = a.percentile(feature);
    final pctB = b.percentile(feature);
    final gapGood = a.radarValue(feature) - b.radarValue(feature);
    final scale = math.max(rawA, rawB);

    return CompareRow(
      feature: feature.jsonKey,
      label: feature.label,
      a: rawA,
      b: rawB,
      pctA: pctA,
      pctB: pctB,
      gapPct: pctA - pctB,
      gapGood: gapGood,
      // Beda arketipe tidak punya model bersama, jadi tidak ada pemenang.
      winner: sameArchetype
          ? (gapGood.abs() < 5 ? 'seimbang' : (gapGood > 0 ? 'A' : 'B'))
          : 'seimbang',
      relDiff: sameArchetype
          ? (scale == 0 ? 0 : (rawA - rawB).abs() / scale)
          : (pctA - pctB).abs() / 100,
      // Tiruan dorongan nilai pasar: seperlima selisih persentil.
      dEffect: sameArchetype ? gapGood / 100 * 0.15 : 0,
    );
  }

  int _neighborRank(Player a, Player b) {
    if (a.id == b.id) return 0;
    final features = a.radarAxes;
    final distance = _percentileDistance(a, b, features);
    var rank = 1;
    for (final other in mockPlayers) {
      if (other.archetype != a.archetype) continue;
      if (other.id == a.id || other.id == b.id) continue;
      if (_percentileDistance(a, other, features) < distance) rank++;
    }
    return rank;
  }

  String _compareSummary(
    Player a,
    Player b,
    List<CompareRow> aBetter,
    List<CompareRow> bBetter,
  ) {
    final left = aBetter.map((row) => row.label).take(2).join(', ');
    final right = bBetter.map((row) => row.label).take(2).join(', ');
    if (left.isEmpty && right.isEmpty) {
      return '${a.name} dan ${b.name} seimbang pada statistik arketipe.';
    }
    final parts = <String>[
      if (left.isNotEmpty) '${a.name} unggul di: $left',
      if (right.isNotEmpty) '${b.name} unggul di: $right',
    ];
    return '${parts.join('. ')}.';
  }

  int _goodDir(PlayerFeature feature) {
    switch (feature.direction) {
      case FeatureDirection.higherIsBetter:
        return 1;
      case FeatureDirection.lowerIsBetter:
        return -1;
      case FeatureDirection.neutral:
        return 0;
    }
  }

  HexagonAxis _axis(PlayerFeature feature) => HexagonAxis(
    label: feature.label,
    feature: feature.jsonKey,
    invert: feature.isInverted,
  );

  /// Median statistik arketipe (dipakai saat target persentil).
  double _medianOf(PlayerFeature feature) {
    final values = mockPlayers
        .where((player) => player.stats.containsKey(feature))
        .map((player) => player.stat(feature))
        .toList()
      ..sort();
    if (values.isEmpty) return 0;
    return values[values.length ~/ 2];
  }

  /// Persentil sebuah nilai di antara pemain contoh.
  double _percentileOf(PlayerFeature feature, double value) {
    final values = mockPlayers
        .where((player) => player.stats.containsKey(feature))
        .map((player) => player.stat(feature))
        .toList();
    if (values.isEmpty) return 50;
    final below = values.where((v) => v < value).length;
    final equal = values.where((v) => v == value).length;
    return 100 * (below + 0.5 * equal) / values.length;
  }

  /// Ringkasan satu baris, meniru `short_reason` backend.
  String _reason(
    List<PlayerFeature> features,
    Map<PlayerFeature, double> targets,
    Player player,
    double Function(Player, PlayerFeature) valueOf,
  ) {
    final over = <String>[];
    final under = <String>[];
    for (final feature in features) {
      final target = targets[feature];
      if (target == null) continue;
      // Arah logika dihormati: makin kecil makin baik berarti dibalik.
      final gap = feature.isInverted
          ? target - valueOf(player, feature)
          : valueOf(player, feature) - target;
      final label = '${feature.label} ${gap.toStringAsFixed(0)}';
      if (gap > 3) over.add(label);
      if (gap < -3) under.add(label);
    }
    if (over.isEmpty && under.isEmpty) return 'sesuai target';
    final parts = <String>[];
    if (over.isNotEmpty) parts.add('lebih: ${over.take(2).join(', ')}');
    if (under.isNotEmpty) parts.add('kurang: ${under.take(2).join(', ')}');
    return parts.join(' | ');
  }

  double _euclidean(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }
    return math.sqrt(sum / a.length);
  }

  /// Menghasilkan kontribusi "mirip SHAP" agar grafik bisa diuji.
  List<FeatureContribution> _fakeShap(
    List<PlayerFeature> features,
    Map<PlayerFeature, double> targets,
    Player player,
    double Function(Player, PlayerFeature) valueOf,
  ) {
    final raw = <PlayerFeature, double>{};
    var total = 0.0;
    for (final feature in features) {
      final diff = valueOf(player, feature) - (targets[feature] ?? 0);
      raw[feature] = diff;
      total += diff.abs();
    }

    return [
      for (final feature in features) () {
        final shap = total == 0 ? 0.0 : (raw[feature]! / total) * 0.35;
        final effect = (math.exp(shap) - 1.0) * 100;
        return FeatureContribution(
          feature: feature,
          value: player.stat(feature),
          shapValue: shap,
          effectPct: effect,
          label: feature.label,
        );
      }(),
    ];
  }
}
