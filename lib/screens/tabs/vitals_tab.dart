import 'package:flutter/material.dart';

import '../../state/console_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/fx.dart';
import '../../widgets/health_risk_scores.dart';
import '../../widgets/mini_line_chart.dart';
import '../../widgets/rhr_trend_card.dart';

class VitalsTab extends StatelessWidget {
  const VitalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final i = s.cursor;

    final cards = <Widget>[
      SectionCard(
        eyebrow: 'Heart rate',
        title: '${day.hr[i].toStringAsFixed(0)} bpm',
        trailing: _rangePill(context, '${day.stats.minHR.toStringAsFixed(0)}–${day.stats.maxHR.toStringAsFixed(0)}'),
        child: MiniLineChart(
          values: day.hr,
          cursor: i,
          color: c.accent,
          warn: 130,
          critical: 160,
          minY: 45,
          maxY: 175,
        ),
      ),
      SectionCard(
        eyebrow: 'Heart-rate variability',
        title: '${day.hrv[i].toStringAsFixed(0)} ms',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Higher is generally better — reflects autonomic recovery.',
                style: TextStyle(fontSize: 12.5, color: c.muted)),
            const SizedBox(height: 10),
            MiniLineChart(values: day.hrv, cursor: i, color: c.accent2, fill: true),
          ],
        ),
      ),
      Row(
        children: [
          Expanded(
            child: _BigStat(
              label: 'Respiratory rate',
              value: day.respRate[i].toStringAsFixed(0),
              unit: '/min',
              icon: Icons.waves,
              color: c.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _BigStat(
              label: 'Core temp (est.)',
              value: day.coreTemp[i].toStringAsFixed(1),
              unit: '°C',
              icon: Icons.thermostat,
              color: c.tempTrace,
            ),
          ),
        ],
      ),
      const HealthRiskScores(),
      const RhrTrendCard(),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      children: [
        for (var k = 0; k < cards.length; k++) ...[
          EntranceCard(index: k, child: cards[k]),
          if (k != cards.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _rangePill(BuildContext context, String text) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: c.paper, borderRadius: BorderRadius.circular(20)),
      child: MonoText(text, size: 12, color: c.muted),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });
  final String label, value, unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 12, color: c.faint)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              MonoText(value, size: 26, weight: FontWeight.w800, color: c.ink),
              const SizedBox(width: 3),
              Text(unit, style: TextStyle(fontSize: 12, color: c.faint)),
            ],
          ),
        ],
      ),
    );
  }
}
