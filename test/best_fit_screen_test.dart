import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scout_ml/core/theme/app_theme.dart';
import 'package:scout_ml/data/mock/mock_players.dart';
import 'package:scout_ml/data/repositories/scouting_repository.dart';
import 'package:scout_ml/data/services/mock_scouting_service.dart';
import 'package:scout_ml/presentation/screens/best_fit_screen.dart';
import 'package:scout_ml/presentation/screens/player_detail_screen.dart';
import 'package:scout_ml/state/compare_provider.dart';
import 'package:scout_ml/state/player_provider.dart';
import 'package:scout_ml/state/shortlist_provider.dart';

void main() {
  final yamal = mockPlayers.firstWhere((player) => player.id == 'p001');
  final repository = ScoutingRepository(
    service: MockScoutingService(latency: Duration.zero),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpBestFit(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: BestFitScreen(player: yamal, repository: repository),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Best Fit', () {
    testWidgets('menampilkan kandidat pengganti dari backend', (tester) async {
      await pumpBestFit(tester);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Kandidat pengganti'), findsOneWidget);
      expect(find.textContaining('FIT '), findsWidgets);
      expect(find.text('Kemiripan'), findsWidgets);
    });

    testWidgets('filter umur maksimum benar-benar menyaring kandidat', (
      tester,
    ) async {
      await pumpBestFit(tester);

      await tester.enterText(find.byType(TextField).first, '1');
      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tidak ada kandidat'), findsOneWidget);
      expect(find.textContaining('FIT '), findsNothing);
    });

    testWidgets('tombol dari Player Dossier membuka layar Best Fit', (
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
            home: PlayerDetailScreen(player: yamal),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final entry = find.text('Cari Pengganti (Best Fit)');
      await tester.scrollUntilVisible(
        entry,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();

      expect(find.text('Cari Pengganti'), findsOneWidget);
      expect(find.textContaining('Kandidat pengganti'), findsOneWidget);
    });
  });
}
