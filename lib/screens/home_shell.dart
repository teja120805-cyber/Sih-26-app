import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'profile_screen.dart';
import 'report_screen.dart';
import 'today_screen.dart';
import 'trends_screen.dart';

/// Root scaffold with a bottom NavigationBar. Screens are kept alive in an
/// IndexedStack so each tab preserves its scroll position and local state.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final screens = [
      TodayScreen(
        themeMode: widget.themeMode,
        onToggleTheme: widget.onToggleTheme,
      ),
      const TrendsScreen(),
      const ReportScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: screens),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.monitor_heart_outlined),
              selectedIcon: Icon(Icons.monitor_heart),
              label: 'Today',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Trends',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description),
              label: 'Report',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
