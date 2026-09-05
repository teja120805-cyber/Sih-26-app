import 'package:flutter/material.dart';

import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// The "Live Vitals" card — 9 metric tiles in a 3-column grid, each with a
/// value, a mini progress bar, and a red highlight when flagged.
class LiveVitalsGrid extends StatelessWidget {
  const LiveVitalsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final i = s.cursor;

    final metrics = <_Metric>[
      _Metric('Heart rate', day.hr[i].toStringAsFixed(0), 'bpm', Icons.favorite,
          ((day.hr[i] - 50) / 130).clamp(0, 1), day.hr[i] > 130),
      _Metric('SpO₂', day.spo2[i].toStringAsFixed(0), '%', Icons.air,
          ((day.spo2[i] - 88) / 12).clamp(0, 1), day.spo2[i] < 94),
      _Metric('Skin temp', day.skin[i].toStringAsFixed(1), '°C', Icons.device_thermostat,
          ((day.skin[i] - 30) / 8).clamp(0, 1), false),
      _Metric('Core temp', day.coreTemp[i].toStringAsFixed(1), '°C', Icons.thermostat,
          ((day.coreTemp[i] - 36.5) / 3).clamp(0, 1), day.coreTemp[i] > 38.5),
      _Metric('HRV', day.hrv[i].toStringAsFixed(0), 'ms', Icons.monitor_heart_outlined,
          (day.hrv[i] / 120).clamp(0, 1), false),
      _Metric('Resp rate', day.respRate[i].toStringAsFixed(0), '/min', Icons.waves,
          ((day.respRate[i] - 8) / 22).clamp(0, 1), day.respRate[i] > 24),
      _Metric('Anomaly', day.anomaly[i].toStringAsFixed(1), '/10', Icons.blur_on,
          (day.anomaly[i] / 10).clamp(0, 1), day.anomaly[i] > 7),
      _Metric('Vitals risk', (day.vitalsRisk[i] * 100).toStringAsFixed(0), '%',
          Icons.psychology_outlined, day.vitalsRisk[i].clamp(0, 1), day.vitalsRisk[i] > 0.6),
      _Metric('Cardio (live)', (day.cardioLive[i] * 100).toStringAsFixed(0), '%',
          Icons.favorite_border, day.cardioLive[i].clamp(0, 1), day.cardioLive[i] > 0.5),
    ];

    return SectionCard(
      eyebrow: 'Live vitals',
      title: 'Everything, right now',
      child: LayoutBuilder(builder: (context, box) {
        const cols = 3;
        const gap = 10.0;
        final w = (box.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final m in metrics) SizedBox(width: w, child: _Tile(m: m))],
        );
      }),
    );
  }
}

class _Metric {
  _Metric(this.label, this.value, this.unit, this.icon, this.frac, this.flagged);
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final double frac;
  final bool flagged;
}

class _Tile extends StatelessWidget {
  const _Tile({required this.m});
  final _Metric m;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final col = m.flagged ? c.critical : c.accent;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: m.flagged ? c.criticalSoft : c.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: m.flagged ? c.critical.withValues(alpha: 0.4) : c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(m.icon, size: 15, color: col),
          const SizedBox(height: 6),
          Text(m.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: c.faint)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: MonoText(m.value,
                    size: 17, weight: FontWeight.w700, color: c.ink),
              ),
              const SizedBox(width: 2),
              Text(m.unit, style: TextStyle(fontSize: 9.5, color: c.faint)),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(children: [
              Container(height: 4, color: c.line),
              FractionallySizedBox(
                widthFactor: m.frac.clamp(0.0, 1.0),
                child: Container(height: 4, color: col),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
