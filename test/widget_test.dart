import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:scout_ml/app.dart';
import 'package:scout_ml/state/compare_provider.dart';
import 'package:scout_ml/state/player_provider.dart';
import 'package:scout_ml/state/scouting_provider.dart';
import 'package:scout_ml/state/shortlist_provider.dart';

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
        ],
        child: const ScoutApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Hello, Scout'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Find by Tactic'), findsWidgets);
  });
}
