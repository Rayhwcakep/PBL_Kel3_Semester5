import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/main_shell.dart';
import 'state/theme_provider.dart';

/// Akar aplikasi Scoutify.
class ScoutApp extends StatelessWidget {
  const ScoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final brightness = themeProvider.isDark
        ? Brightness.dark
        : Brightness.light;
    final themeData = AppTheme.build(brightness);

    return MaterialApp(
      title: 'Scoutify',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      darkTheme: themeData,
      themeMode: themeProvider.mode,
      // Key berubah saat mode berganti agar seluruh pohon widget
      // membangun ulang dengan palet warna terbaru.
      home: MainShell(key: ValueKey(brightness)),
    );
  }
}
