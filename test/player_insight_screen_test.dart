import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scout_ml/core/theme/app_theme.dart';
import 'package:scout_ml/data/cache/explain_cache.dart';
import 'package:scout_ml/data/mock/mock_players.dart';
import 'package:scout_ml/data/models/explain_response.dart';
import 'package:scout_ml/data/repositories/scouting_repository.dart';
import 'package:scout_ml/data/services/mock_scouting_service.dart';
import 'package:scout_ml/presentation/screens/player_detail_screen.dart';
import 'package:scout_ml/presentation/screens/player_insight_screen.dart';
import 'package:scout_ml/state/compare_provider.dart';
import 'package:scout_ml/state/player_provider.dart';
import 'package:scout_ml/state/shortlist_provider.dart';

/// Layanan hitung panggilan agar cache `/explain` bisa diverifikasi.
class _CountingExplainService extends MockScoutingService {
  _CountingExplainService() : super(latency: Duration.zero);

  int explainCalls = 0;

  @override
  Future<PlayerExplain> explain(String id) {
    explainCalls++;
    return super.explain(id);
  }
}

void main() {
  final yamal = mockPlayers.firstWhere(
    (player) => player.id == MockScoutingService.explainFixturePlayerId,
  );
  final repository = ScoutingRepository(
    service: MockScoutingService(latency: Duration.zero),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpInsight(WidgetTester tester, ThemeData theme) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: PlayerInsightScreen(player: yamal, repository: repository),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Player Insight Lamine Yamal', () {
    testWidgets('tema gelap menampilkan kontribusi SHAP dari backend', (
      tester,
    ) async {
      await pumpInsight(tester, AppTheme.dark);

      expect(tester.takeException(), isNull);
      expect(find.text('Tembakan'), findsOneWidget);
      expect(find.text('+77.0%'), findsOneWidget);
      expect(find.text('Gol non-penalti'), findsOneWidget);
      expect(find.text('+33.0%'), findsOneWidget);
      expect(find.textContaining('Tembakan (+77%)'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Konteks'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Konteks'), findsOneWidget);
      expect(find.text('-22.0%'), findsOneWidget);
    });

    testWidgets('tema terang tetap menampilkan nilai yang sama', (
      tester,
    ) async {
      await pumpInsight(tester, AppTheme.light);

      expect(tester.takeException(), isNull);
      expect(find.text('Tembakan'), findsOneWidget);
      expect(find.text('+77.0%'), findsOneWidget);
      expect(find.text('Gol non-penalti'), findsOneWidget);
      expect(find.text('+33.0%'), findsOneWidget);
    });

    testWidgets('grafik SHAP muncul tanpa hasil pencarian (mode API)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => PlayerProvider()),
            ChangeNotifierProvider(create: (_) => ShortlistProvider()),
            ChangeNotifierProvider(create: (_) => CompareProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: PlayerDetailScreen(player: yamal, repository: repository),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final header = find.text('Mengapa Pemain Ini?');
      await tester.scrollUntilVisible(
        header,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(header, findsOneWidget);
      expect(
        find.text('Kontribusi tiap atribut terhadap nilai pasar (SHAP)'),
        findsOneWidget,
      );
      expect(find.text('Tembakan'), findsOneWidget);
    });

    testWidgets('tombol dari Player Dossier membuka layar Insight', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => PlayerProvider()),
            ChangeNotifierProvider(create: (_) => ShortlistProvider()),
            ChangeNotifierProvider(create: (_) => CompareProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: PlayerDetailScreen(player: yamal, repository: repository),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final entry = find.text('Player Insight (SHAP)');
      await tester.scrollUntilVisible(
        entry,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();

      expect(find.text('Player Insight'), findsOneWidget);
      expect(find.text('+77.0%'), findsOneWidget);
    });
  });

  group('Cache penjelasan SHAP', () {
    testWidgets('membuka ulang layar tidak memanggil backend lagi', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = _CountingExplainService();
      final repository = ScoutingRepository(
        service: service,
        explainCache: ExplainCache(),
      );

      Future<void> pumpScreen() async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: PlayerInsightScreen(player: yamal, repository: repository),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpScreen();
      expect(service.explainCalls, 1);
      expect(find.text('Tembakan'), findsOneWidget);

      // Tutup layar lalu buka kembali: instance state baru, tetapi cache
      // seharusnya mencegah panggilan backend kedua.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await pumpScreen();

      expect(service.explainCalls, 1, reason: 'layar kedua memakai cache');
      expect(find.text('Tembakan'), findsOneWidget);
    });

    testWidgets('tombol muat ulang memaksa data baru', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = _CountingExplainService();
      final repository = ScoutingRepository(
        service: service,
        explainCache: ExplainCache(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: PlayerInsightScreen(player: yamal, repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.explainCalls, 1);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(service.explainCalls, 2);
      expect(find.text('Tembakan'), findsOneWidget);
    });
  });
}
