import 'package:flutter/material.dart';

import '../main.dart' show ThemeScope;
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'fall_screen.dart';
import 'report_screen.dart';
import 'tabs/activity_tab.dart';
import 'tabs/alerts_tab.dart';
import 'tabs/environment_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/sleep_tab.dart';
import 'tabs/vitals_tab.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = s.medical.name.trim();
    final greeting = name.isEmpty ? 'Welcome back' : 'Hi, ${name.split(' ').first}';

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: c.panel,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 16,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('COMPANION CONSOLE',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: c.accent)),
              Text(greeting,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: c.ink)),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Fall detection',
              icon: Icon(Icons.emergency_outlined, color: c.critical),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FallScreen())),
            ),
            IconButton(
              tooltip: 'Report',
              icon: Icon(Icons.description_outlined, color: c.muted),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportScreen())),
            ),
            IconButton(
              tooltip: 'Toggle theme',
              icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: c.muted),
              onPressed: () => ThemeScope.of(context).toggle(),
            ),
            IconButton(
              tooltip: 'Log out',
              icon: Icon(Icons.logout, color: c.muted),
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
            const SizedBox(width: 4),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: c.accent,
            unselectedLabelColor: c.muted,
            indicatorColor: c.accent,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Vitals'),
              Tab(text: 'Activity'),
              Tab(text: 'Sleep'),
              Tab(text: 'Environment'),
              Tab(text: 'Alerts'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OverviewTab(),
            VitalsTab(),
            ActivityTab(),
            SleepTab(),
            EnvironmentTab(),
            AlertsTab(),
          ],
        ),
      ),
    );
  }
}
