import 'package:flutter/material.dart';

import '../state/console_state.dart';
import '../theme/app_theme.dart';
import '../widgets/alerts_card.dart';
import '../widgets/demo_bar.dart';
import '../widgets/fx.dart';
import '../widgets/status_hero.dart';
import '../widgets/strain_chart.dart';
import '../widgets/vitals_row.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hour = s.cursorMinute ~/ 60;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : hour < 21
                ? 'Good evening'
                : 'Good night';

    final cards = <Widget>[
      const StatusHero(),
      const VitalsRow(),
      const StrainChart(),
      const _QuickAlerts(),
      const DemoControls(),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        // Greeting header
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 14),
          child: Row(
            children: [
              _RiskAvatar(level: s.medical.riskLevel),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting,
                        style: TextStyle(fontSize: 13, color: c.muted)),
                    Text('Your health, right now',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: c.ink)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onToggleTheme,
                tooltip: 'Toggle theme',
                icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: c.muted),
              ),
            ],
          ),
        ),
        for (var i = 0; i < cards.length; i++) ...[
          EntranceCard(index: i, child: cards[i]),
          if (i != cards.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _RiskAvatar extends StatelessWidget {
  const _RiskAvatar({required this.level});
  final String level;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: c.heroGradient),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.favorite, color: Colors.white, size: 22),
    );
  }
}

/// Compact alert summary for the Today screen (severity counts + latest).
class _QuickAlerts extends StatelessWidget {
  const _QuickAlerts();

  @override
  Widget build(BuildContext context) {
    // Reuse the full alerts card — it already summarizes counts + list.
    return const AlertsCard();
  }
}
