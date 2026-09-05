import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';

/// The whole app in three screens: Home, Profile, Report.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          _Padded(ProfileScreen()),
          ReportScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
            NavigationDestination(
                icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'Report'),
          ],
        ),
      ),
    );
  }
}

/// Adds a SafeArea top for tab screens that don't manage their own.
class _Padded extends StatelessWidget {
  const _Padded(this.child);
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(bottom: false, child: child);
}
