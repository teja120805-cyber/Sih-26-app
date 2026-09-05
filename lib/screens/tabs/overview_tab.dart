import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/common.dart';
import '../../widgets/demo_bar.dart';
import '../../widgets/fx.dart';
import '../../widgets/live_vitals_grid.dart';
import '../../widgets/smart_insights.dart';
import '../../widgets/status_hero.dart';
import '../../widgets/strain_chart.dart';
import '../../widgets/transparency_card.dart';
import '../../widgets/watch_status_card.dart';
import '../../widgets/waterfall_card.dart';
import '../fall_screen.dart';
import '../report_screen.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      const WatchStatusCard(),
      const DemoControls(),
      const StatusHero(),
      const LiveVitalsGrid(),
      const SmartInsights(),
      const WaterfallCard(),
      const ActivityCard(),
      const StrainChart(),
      _FallRow(),
      _ReportButton(),
      const TransparencyCard(),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          EntranceCard(index: i, child: cards[i]),
          if (i != cards.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _FallRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const FallScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.panel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.line),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: c.criticalSoft, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.emergency_outlined, color: c.critical, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fall & distress check',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
                  Text('Test the no-response countdown',
                      style: TextStyle(fontSize: 12.5, color: c.muted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.faint),
          ],
        ),
      ),
    );
  }
}

class _ReportButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GradientButton(
      label: 'Generate doctor report',
      icon: Icons.description_outlined,
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ReportScreen())),
    );
  }
}
