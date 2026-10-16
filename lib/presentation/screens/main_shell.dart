import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../widgets/floating_nav_bar.dart';
import 'compare_screen.dart';
import 'dashboard_screen.dart';
import 'discover_screen.dart';
import 'profile_screen.dart';
import 'shortlist_screen.dart';

/// Kerangka aplikasi dengan navigasi bawah mengambang (floating nav island).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const List<ScoutNavItem> _items = [
    ScoutNavItem(
      icon: Icons.sports_soccer_outlined,
      activeIcon: Icons.sports_soccer,
      label: 'Home',
    ),
    ScoutNavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Discover',
    ),
    ScoutNavItem(
      icon: Icons.balance_outlined,
      activeIcon: Icons.balance,
      label: 'Compare',
    ),
    ScoutNavItem(
      icon: Icons.bookmark_border,
      activeIcon: Icons.bookmark,
      label: 'Shortlist',
    ),
    ScoutNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(),
          DiscoverScreen(),
          CompareScreen(),
          ShortlistScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.margin,
          0,
          AppSpacing.margin,
          AppSpacing.md,
        ),
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: FloatingNavBar(
            items: _items,
            currentIndex: _index,
            onSelected: (value) => setState(() => _index = value),
          ),
        ),
      ),
    );
  }
}
