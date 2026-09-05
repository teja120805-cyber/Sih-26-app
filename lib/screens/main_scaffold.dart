import 'package:flutter/material.dart';

import '../models/health_status.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import '../widgets/sos_flash_bar.dart';
import 'pages/activity_controls_page.dart';
import 'pages/hydration_controls_page.dart';
import 'pages/menu_page.dart';
import 'pages/patient_health_page.dart';
import 'pages/vitals_page.dart';

/// The main app: five horizontally-swipeable screens. Starts on the middle
/// (menu). Left two = health/vitals, right two = smartwatch-style controls.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  static const _start = 2;
  final _controller = PageController(initialPage: _start);
  int _index = _start;

  static const _labels = ['Health', 'Vitals', 'Menu', 'Activity', 'Water'];

  void _jump(int i) => _controller.animateToPage(i,
      duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final status = computeStatus(s.cursor, s.day!, s.medical);
    final media = MediaQuery.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Clean top normally; flashing SOS + emergency numbers on critical.
          if (status.isCritical)
            SosFlashBar(active: true, reason: status.title)
          else
            SizedBox(height: media.padding.top),
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                const PatientHealthPage(),
                const VitalsPage(),
                MenuPage(onJump: _jump),
                const ActivityControlsPage(),
                const HydrationControlsPage(),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_labels[_index],
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: c.accent)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 5; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _index ? 20 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _index ? c.accent : c.lineStrong,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared page header (title + subtitle) used across the five pages.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, required this.subtitle, this.trailing});
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: c.ink)),
                Text(subtitle, style: TextStyle(fontSize: 13, color: c.muted)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
