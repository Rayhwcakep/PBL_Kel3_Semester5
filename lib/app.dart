import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/main_shell.dart';

/// Akar aplikasi Scoutify.
class ScoutApp extends StatelessWidget {
  const ScoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scoutify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainShell(),
    );
  }
}
