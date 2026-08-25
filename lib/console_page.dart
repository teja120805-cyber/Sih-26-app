import 'package:flutter/material.dart';

import 'state/console_state.dart';
import 'theme/app_theme.dart';
import 'widgets/activity_card.dart';
import 'widgets/alerts_card.dart';
import 'widgets/common.dart';
import 'widgets/demo_bar.dart';
import 'widgets/environment_card.dart';
import 'widgets/fall_check_card.dart';
import 'widgets/hero_card.dart';
import 'widgets/route_map_card.dart';
import 'widgets/sleep_card.dart';
import 'widgets/strain_chart.dart';
import 'widgets/transparency_card.dart';
import 'widgets/vitals_row.dart';

/// The whole console — one continuous scroll of cards, exactly like the web
/// dashboard, driven by a single [ConsoleState].
class ConsolePage extends StatelessWidget {
  const ConsolePage({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);

    if (s.loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: c.accent),
              const SizedBox(height: 16),
              Text('Loading sensor data & models…',
                  style: TextStyle(color: c.muted)),
            ],
          ),
        ),
      );
    }

    if (s.loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: c.critical, size: 40),
                const SizedBox(height: 12),
                Text('Could not load bundled data.',
                    style: TextStyle(
                        color: c.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('${s.loadError}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.muted, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _AppHeader(
              online: s.network,
              themeMode: themeMode,
              onToggleTheme: onToggleTheme,
            ),
            const DemoBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
                children: const [
                  HeroCard(),
                  _Gap(),
                  StrainChart(),
                  _Gap(),
                  VitalsRow(),
                  _Gap(),
                  ActivityCard(),
                  _Gap(),
                  SleepCard(),
                  _Gap(),
                  EnvironmentCard(),
                  _Gap(),
                  RouteMapCard(),
                  _Gap(),
                  AlertsCard(),
                  _Gap(),
                  FallCheckCard(),
                  _Gap(),
                  TransparencyCard(),
                  _Gap(),
                  _FooterNote(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Gap extends StatelessWidget {
  const _Gap();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 14);
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({
    required this.online,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final bool online;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: c.accentSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.favorite, color: c.accent, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Companion Console',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                    height: 1.1),
              ),
              Text('band + phone · on-device',
                  style: TextStyle(fontSize: 11, color: c.muted)),
            ],
          ),
          const Spacer(),
          Pill(
            online ? 'Online' : 'Offline',
            fg: online ? c.ok : c.advisory,
            bg: online ? c.okSoft : c.advisorySoft,
            icon: online ? Icons.wifi : Icons.wifi_off,
          ),
          IconButton(
            onPressed: onToggleTheme,
            tooltip: 'Toggle theme',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: c.muted,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: c.warning, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow('Not a medical device', color: c.warning),
          const SizedBox(height: 6),
          Text(
            'This proves the computation pipeline and interaction design. It '
            'has not been clinically validated, and none of the training data '
            'came from this exact hardware. Treat every number as a demo of '
            'the approach, not a diagnosis.',
            style: TextStyle(fontSize: 12.5, height: 1.45, color: c.muted),
          ),
        ],
      ),
    );
  }
}
