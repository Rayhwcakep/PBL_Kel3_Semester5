import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'state/compare_provider.dart';
import 'state/player_provider.dart';
import 'state/scouting_provider.dart';
import 'state/shortlist_provider.dart';
import 'state/theme_provider.dart';

void main() {
  runApp(
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
}
