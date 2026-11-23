import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:scout_ml/app.dart';
import 'package:scout_ml/state/compare_provider.dart';
import 'package:scout_ml/state/feature_catalog_provider.dart';
import 'package:scout_ml/state/player_provider.dart';
import 'package:scout_ml/state/scouting_provider.dart';
import 'package:scout_ml/state/shortlist_provider.dart';
import 'package:scout_ml/state/theme_provider.dart';

Widget _app() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ChangeNotifierProvider(create: (_) => ScoutingProvider()),
      ChangeNotifierProvider(create: (_) => FeatureCatalogProvider()),
      ChangeNotifierProvider(create: (_) => ShortlistProvider()),
      ChangeNotifierProvider(create: (_) => CompareProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ],
    child: const ScoutApp(),
  );
}

Future<void> _openQuickAction(WidgetTester tester, String label) async {
  await tester.pumpWidget(_app());
  await tester.pump(const Duration(seconds: 1));
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Find Similar Player membuka layar pencarian, bukan Home', (
    tester,
  ) async {
    await _openQuickAction(tester, 'Find Similar Player');

    expect(find.text('Find Similar'), findsOneWidget);
    expect(find.text('Pilih pemain acuan'), findsOneWidget);
    expect(find.text('Hello, Scout'), findsNothing);

    await tester.ensureVisible(find.text('Pilih Pemain'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih Pemain'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Pemain Acuan'), findsOneWidget);

    await tester.tap(find.text('Lamine Yamal').first);
    await tester.pumpAndSettle();

    expect(find.text('Find Similar'), findsOneWidget);
    expect(find.text('Hello, Scout'), findsNothing);
  });

  testWidgets('Compare Players membuka layar Compare dan tetap di sana', (
    tester,
  ) async {
    await _openQuickAction(tester, 'Compare Players');

    expect(find.text('Compare'), findsOneWidget);
    expect(find.text('Pemain A'), findsOneWidget);
    expect(find.text('Hello, Scout'), findsNothing);

    await tester.tap(find.text('Pemain A'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Pemain A'), findsOneWidget);

    await tester.tap(find.text('Lamine Yamal').first);
    await tester.pumpAndSettle();

    expect(find.text('Compare'), findsOneWidget);
    expect(find.text('Lamine Yamal'), findsOneWidget);
    expect(find.text('Hello, Scout'), findsNothing);
  });

  testWidgets('Similar Player di Find by Tactic menampilkan pesan dan tetap', (
    tester,
  ) async {
    await _openQuickAction(tester, 'Find by Tactic');
    expect(find.text('Find by Tactic'), findsOneWidget);

    await tester.tap(find.text('Similar Player'));
    await tester.pump();

    expect(
      find.textContaining('Atur taktik dan kriteria dulu'),
      findsOneWidget,
    );
    expect(find.text('Find by Tactic'), findsOneWidget);
    expect(find.text('Hello, Scout'), findsNothing);
    expect(find.text('Find Similar'), findsNothing);
  });
}
