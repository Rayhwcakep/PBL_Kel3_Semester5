import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:scout_ml/app.dart';
import 'package:scout_ml/core/theme/app_theme.dart';
import 'package:scout_ml/presentation/screens/find_by_tactic_screen.dart';
import 'package:scout_ml/state/compare_provider.dart';
import 'package:scout_ml/state/player_provider.dart';
import 'package:scout_ml/state/scouting_provider.dart';
import 'package:scout_ml/state/shortlist_provider.dart';
import 'package:scout_ml/state/theme_provider.dart';

void main() {
  testWidgets('Beranda Scoutify menampilkan sapaan dan nav island', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PlayerProvider()),
          ChangeNotifierProvider(create: (_) => ScoutingProvider()),
          ChangeNotifierProvider(create: (_) => ShortlistProvider()),
          ChangeNotifierProvider(create: (_) => CompareProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const ScoutApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Hello, Scout'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Find by Tactic'), findsWidgets);
  });

  testWidgets('Tombol tema mengganti mode gelap ke terang', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PlayerProvider()),
          ChangeNotifierProvider(create: (_) => ScoutingProvider()),
          ChangeNotifierProvider(create: (_) => ShortlistProvider()),
          ChangeNotifierProvider(create: (_) => CompareProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const ScoutApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(find.text('Hello, Scout'), findsOneWidget);
  });

  testWidgets('Dashboard tidak overflow pada lebar ponsel', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PlayerProvider()),
          ChangeNotifierProvider(create: (_) => ScoutingProvider()),
          ChangeNotifierProvider(create: (_) => ShortlistProvider()),
          ChangeNotifierProvider(create: (_) => CompareProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const ScoutApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('SCOUTIFY'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Hello, Scout'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
  });

  testWidgets('Find by Tactic aman pada tema gelap dan terang', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const FindByTacticScreen()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Find by Tactic'), findsOneWidget);
    expect(find.text('By Tactic'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const FindByTacticScreen()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Find by Tactic'), findsOneWidget);
  });
}
