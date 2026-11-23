import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scout_ml/core/theme/app_theme.dart';
import 'package:scout_ml/data/mock/mock_players.dart';
import 'package:scout_ml/data/repositories/scouting_repository.dart';
import 'package:scout_ml/data/services/mock_scouting_service.dart';
import 'package:scout_ml/presentation/screens/player_detail_screen.dart';
import 'package:scout_ml/presentation/screens/player_insight_screen.dart';
import 'package:scout_ml/state/compare_provider.dart';
import 'package:scout_ml/state/player_provider.dart';
import 'package:scout_ml/state/shortlist_provider.dart';

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
      expect(find.text('+77%'), findsOneWidget);
      expect(find.text('Gol non-penalti'), findsOneWidget);
      expect(find.text('+33%'), findsOneWidget);
      expect(find.textContaining('Tembakan (+77%)'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Konteks'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Konteks'), findsOneWidget);
      expect(find.text('-22%'), findsOneWidget);
    });

    testWidgets('tema terang tetap menampilkan nilai yang sama', (
      tester,
    ) async {
      await pumpInsight(tester, AppTheme.light);

      expect(tester.takeException(), isNull);
      expect(find.text('Tembakan'), findsOneWidget);
      expect(find.text('+77%'), findsOneWidget);
      expect(find.text('Gol non-penalti'), findsOneWidget);
      expect(find.text('+33%'), findsOneWidget);
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
            home: PlayerDetailScreen(player: yamal),
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
      expect(find.text('+77%'), findsOneWidget);
    });
  });
}
