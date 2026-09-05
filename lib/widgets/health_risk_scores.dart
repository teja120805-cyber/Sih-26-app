import 'package:flutter/material.dart';

import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// The five model outputs as labelled indicators with mini progress bars.
class HealthRiskScores extends StatelessWidget {
  const HealthRiskScores({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final i = s.cursor;

    final rows = <_Row>[
      _Row('Isolation Forest', day.anomaly[i] / 10, '${day.anomaly[i].toStringAsFixed(1)}/10',
          day.anomaly[i] > 7 ? c.critical : day.anomaly[i] > 4 ? c.warning : c.ok),
      _Row('Vitals risk', day.vitalsRisk[i], '${(day.vitalsRisk[i] * 100).round()}%',
          day.vitalsRisk[i] > 0.6 ? c.critical : day.vitalsRisk[i] > 0.4 ? c.warning : c.ok),
      _Row('Cardio (live)', day.cardioLive[i], '${(day.cardioLive[i] * 100).round()}%',
          day.cardioLive[i] > 0.5 ? c.critical : day.cardioLive[i] > 0.3 ? c.warning : c.ok),
      _Row('Sleep quality', day.stats.sleepQuality / 100, '${day.stats.sleepQuality}/100',
          day.stats.sleepQuality >= 70 ? c.ok : day.stats.sleepQuality >= 50 ? c.warning : c.critical),
      _Row('Readiness', day.stats.readiness / 100, '${day.stats.readiness}/100',
          day.stats.readiness >= 66 ? c.ok : day.stats.readiness >= 40 ? c.warning : c.critical),
    ];

    return SectionCard(
      eyebrow: 'Model readings',
      title: 'Health risk scores',
      child: Column(
        children: [
          for (var k = 0; k < rows.length; k++) ...[
            _Indicator(row: rows[k]),
            if (k != rows.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _Row {
  _Row(this.label, this.frac, this.value, this.color);
  final String label;
  final double frac;
  final String value;
  final Color color;
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.row});
  final _Row row;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(row.label,
                    style: TextStyle(fontSize: 13, color: c.ink))),
            MonoText(row.value, size: 13.5, weight: FontWeight.w700, color: row.color),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(children: [
            Container(height: 7, color: c.line),
            FractionallySizedBox(
              widthFactor: row.frac.clamp(0.0, 1.0),
              child: Container(height: 7, color: row.color),
            ),
          ]),
        ),
      ],
    );
  }
}
