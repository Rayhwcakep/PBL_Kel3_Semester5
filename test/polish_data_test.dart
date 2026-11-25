import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scout_ml/core/theme/app_theme.dart';
import 'package:scout_ml/data/mock/mock_players.dart';
import 'package:scout_ml/data/models/explain_response.dart';
import 'package:scout_ml/data/models/feature_contribution.dart';
import 'package:scout_ml/data/models/player.dart';
import 'package:scout_ml/data/models/player_feature.dart';
import 'package:scout_ml/data/services/mock_scouting_service.dart';
import 'package:scout_ml/presentation/widgets/match_score_badge.dart';
import 'package:scout_ml/presentation/widgets/shap_contribution_chart.dart';

void main() {
  group('Player marketValueLabel & market_value_eur', () {
    test('marketValueLabel format "EUR 200 jt" untuk 200 juta Euro', () {
      const player = Player(
        id: '1',
        name: 'Test Player',
        club: 'Test Club',
        position: 'FW',
        age: 20,
        stats: {},
        marketValue: 200,
      );

      expect(player.marketValue, 200);
      expect(player.marketValueEur, 200000000);
      expect(player.marketValueLabel, 'EUR 200 jt');
    });

    test('Player.fromJson membaca market_value_eur mentah (200000000)', () {
      final json = {
        'id': '10',
        'name': 'Lamine Yamal',
        'market_value_eur': 200000000.0,
      };

      final player = Player.fromJson(json);
      expect(player.marketValue, 200);
      expect(player.marketValueEur, 200000000);
      expect(player.marketValueLabel, 'EUR 200 jt');
    });

    test('Player.fromJson membaca market_value_eur dalam jutaan (200)', () {
      final json = {
        'id': '11',
        'name': 'Lamine Yamal',
        'market_value_eur': 200,
      };

      final player = Player.fromJson(json);
      expect(player.marketValue, 200);
      expect(player.marketValueLabel, 'EUR 200 jt');
    });

    test('marketValueLabel menangani nilai ribuan (di bawah 1 jt)', () {
      const player = Player(
        id: '2',
        name: 'Junior Player',
        club: 'Test Club',
        position: 'MF',
        age: 17,
        stats: {},
        marketValue: 0.5,
      );

      expect(player.marketValueLabel, 'EUR 500 rb');
    });

    test('marketValueLabel menangani nilai <= 0', () {
      const player = Player(
        id: '3',
        name: 'Free Agent',
        club: 'None',
        position: 'GK',
        age: 35,
        stats: {},
        marketValue: 0,
      );

      expect(player.marketValueLabel, '-');
    });
  });

  group('MatchScoreBadge skala 0-100 dan tema', () {
    testWidgets('menampilkan angka persentase sesuai skala 0-100', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: MatchScoreBadge(similarity: 88))),
        ),
      );

      expect(find.text('88'), findsOneWidget);
      expect(find.text('MATCH'), findsOneWidget);
    });

    testWidgets('skor kecil pada skala 0-100 tidak dibaca sebagai skala 0-1', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: MatchScoreBadge(similarity: 0.88)),
          ),
        ),
      );

      // 0.88 adalah skor mentah 0-100 yang dibulatkan jadi 1, bukan 88.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('88'), findsNothing);
    });

    testWidgets('tampil konsisten pada tema gelap dan tema terang', (
      tester,
    ) async {
      // Tema Gelap
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: Center(child: MatchScoreBadge(similarity: 95)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('95'), findsOneWidget);
      expect(find.text('MATCH'), findsOneWidget);

      // Tema Terang
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Center(child: MatchScoreBadge(similarity: 95)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('95'), findsOneWidget);
      expect(find.text('MATCH'), findsOneWidget);
    });
  });

  group('FeatureContribution & ShapContributionChart data asli /explain', () {
    test(
      'FeatureContribution membaca shap_value dan effect_pct dari /explain',
      () {
        final json = {
          'feature': 'crs_p90',
          'label': 'Umpan silang',
          'value': 2.16,
          'percentile': 93.0,
          'better_than_pct': 93.0,
          'shap_value': 0.08,
          'effect_pct': 9.1,
          'verdict': 'kelebihan',
        };

        final contribution = FeatureContribution.fromJson(json);
        expect(contribution.feature, PlayerFeature.crsP90);
        expect(contribution.label, 'Umpan silang');
        expect(contribution.shapValue, 0.08);
        expect(contribution.effectPct, 9.1);
        expect(contribution.isPositive, isTrue);
        expect(contribution.magnitude, 9.1);
      },
    );

    test('FeatureContribution.fromExplain mengonversi ExplainContribution', () {
      const explain = ExplainContribution(
        feature: 'npg_p90',
        label: 'Gol non-penalti',
        value: 0.2091,
        percentile: 27.9,
        betterThanPct: 27.9,
        shapValue: -0.1189,
        effectPct: -11.21,
        verdict: 'kekurangan',
      );

      final contribution = FeatureContribution.fromExplain(explain);
      expect(contribution.feature, PlayerFeature.npgP90);
      expect(contribution.label, 'Gol non-penalti');
      expect(contribution.shapValue, -0.1189);
      expect(contribution.effectPct, -11.21);
      expect(contribution.isPositive, isFalse);
      expect(contribution.magnitude, 11.21);
    });

    testWidgets(
      'ShapContributionChart menampilkan nama statistik Indonesia dari /meta/features',
      (tester) async {
        final contributions = [
          const FeatureContribution(
            feature: PlayerFeature.crsP90,
            value: 2.16,
            shapValue: 0.08,
            effectPct: 9.1,
            label: 'Umpan silang',
          ),
          const FeatureContribution(
            feature: PlayerFeature.npgP90,
            value: 0.21,
            shapValue: -0.12,
            effectPct: -11.2,
            label: 'Gol non-penalti',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ShapContributionChart(contributions: contributions),
            ),
          ),
        );

        expect(find.text('Umpan silang'), findsOneWidget);
        expect(find.text('Gol non-penalti'), findsOneWidget);
        expect(find.text('+9.1%'), findsOneWidget);
        expect(find.text('-11.2%'), findsOneWidget);
      },
    );

    testWidgets('Bar divergen membedakan positif dan negatif dengan benar', (
      tester,
    ) async {
      final positive = const FeatureContribution(
        feature: PlayerFeature.astP90,
        value: 0.45,
        shapValue: 0.15,
        effectPct: 16.2,
        label: 'Assist',
      );
      final negative = const FeatureContribution(
        feature: PlayerFeature.flsP90,
        value: 1.8,
        shapValue: -0.10,
        effectPct: -9.5,
        label: 'Pelanggaran dibuat',
      );

      expect(positive.isPositive, isTrue);
      expect(negative.isPositive, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShapContributionChart(contributions: [positive, negative]),
          ),
        ),
      );

      expect(find.text('Assist'), findsOneWidget);
      expect(find.text('Pelanggaran dibuat'), findsOneWidget);
      expect(find.text('+16.2%'), findsOneWidget);
      expect(find.text('-9.5%'), findsOneWidget);
      expect(find.text('Menaikkan skor'), findsOneWidget);
      expect(find.text('Menurunkan skor'), findsOneWidget);
    });

    testWidgets('daftar panjang bisa diperluas tanpa memotong data', (
      tester,
    ) async {
      final contributions = [
        for (var i = 0; i < 10; i++)
          FeatureContribution(
            feature: PlayerFeature.outfield[i],
            value: 1,
            shapValue: i == 0 ? -0.2 : 0.1,
            effectPct: i == 0 ? -20 : 10,
            label: 'Fitur $i',
          ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShapContributionChart(
                contributions: contributions,
                maxRows: 8,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Fitur 9'), findsNothing);
      await tester.tap(find.text('Tampilkan 2 fitur lain'));
      await tester.pumpAndSettle();
      expect(find.text('Fitur 9'), findsOneWidget);
    });
  });

  group('Mock explain konsisten dengan arah statistik', () {
    final service = MockScoutingService(latency: Duration.zero);

    test('verdict mengikuti arah baik, bukan persentil mentah', () async {
      // João Neves: offside persentil rendah (baik) dan pelanggaran tinggi
      // (buruk). Keduanya statistik terbalik.
      final explain = await service.explain('p004');

      expect(
        explain.strengths.every((row) => row.effectPct > 0),
        isTrue,
        reason: 'Kelebihan tidak boleh berisi pengaruh negatif',
      );
      expect(
        explain.weaknesses.every((row) => row.effectPct < 0),
        isTrue,
        reason: 'Kekurangan tidak boleh berisi pengaruh positif',
      );
      expect(explain.strengths.map((row) => row.feature), contains('off_p90'));
    });

    test('persentil fixture Yamal sama dengan data radar', () async {
      final explain = await service.explain('p001');
      final shooting = explain.strengths.firstWhere(
        (row) => row.feature == 'sh_p90',
      );
      final yamal = mockPlayers.firstWhere((player) => player.id == 'p001');

      expect(shooting.percentile, yamal.percentile(PlayerFeature.shP90));
      expect(shooting.betterThanPct, yamal.radarValue(PlayerFeature.shP90));
    });

    test('pemain non-fixture tetap punya variabel konteks', () async {
      final explain = await service.explain('p004');
      final labels = explain.context.map((row) => row.label).toList();

      expect(explain.context, isNotEmpty);
      expect(labels, containsAll(['Usia', 'Menit main', 'Liga']));
      expect(explain.context.every((row) => row.verdict == 'konteks'), isTrue);
    });
  });
}
