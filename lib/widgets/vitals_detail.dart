import 'package:flutter/material.dart';

import '../models/health_status.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'expandable_card.dart';
import 'mini_line_chart.dart';
import 'strain_chart.dart';

/// The expanded content for the Vitals card — qualitative readings with plain
/// "what to do" guidance, and graphs only shown here (not on the summary).
class VitalsDetail extends StatelessWidget {
  const VitalsDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final m = s.medical;
    final i = s.cursor;

    final hr = day.hr[i];
    final spo2 = day.spo2[i];
    final core = day.coreTemp[i];
    final hrv = day.hrv[i];
    final stress = bodyStress(day.anomaly[i]);

    Color hrCol = hr >= m.effHrCrit ? c.critical : hr >= m.effHrWarn ? c.warning : c.ok;
    Color spCol = spo2 <= m.effSpo2Crit ? c.critical : spo2 <= m.effSpo2Warn ? c.warning : c.ok;
    Color tCol = core >= m.effTempCrit ? c.critical : core >= m.effTempWarn ? c.warning : c.ok;
    Color stressCol = stress.label == 'High' ? c.critical : stress.label == 'Noticeable' ? c.warning : c.ok;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VitalRow(
          icon: Icons.favorite,
          label: 'Heart rate',
          value: hr.toStringAsFixed(0),
          unit: 'bpm',
          statusText: hr >= m.effHrWarn ? (hr >= m.effHrCrit ? 'Very high' : 'Elevated') : 'Normal',
          color: hrCol,
          guidance: hrGuidance(hr, day.prof.hr0, m.effHrWarn),
        ),
        _VitalRow(
          icon: Icons.air,
          label: 'Blood oxygen (SpO₂)',
          value: spo2.toStringAsFixed(0),
          unit: '%',
          statusText: spo2 <= m.effSpo2Warn ? (spo2 <= m.effSpo2Crit ? 'Low' : 'Dipping') : 'Healthy',
          color: spCol,
          guidance: spo2Guidance(spo2, m.effSpo2Warn),
        ),
        _VitalRow(
          icon: Icons.thermostat,
          label: 'Body temperature',
          value: core.toStringAsFixed(1),
          unit: '°C',
          statusText: core >= m.effTempWarn ? (core >= m.effTempCrit ? 'Overheating' : 'Warm') : 'Normal',
          color: tCol,
          guidance: coreTempGuidance(core, m.effTempWarn),
        ),
        _VitalRow(
          icon: Icons.self_improvement,
          label: 'Recovery (HRV)',
          value: hrv.toStringAsFixed(0),
          unit: 'ms',
          statusText: hrv < day.prof.hrv0 - 12 ? 'Low' : 'Healthy',
          color: hrv < day.prof.hrv0 - 12 ? c.warning : c.ok,
          guidance: hrvGuidance(hrv, day.prof.hrv0),
        ),
        const SizedBox(height: 4),
        // Body stress (plain-language replacement for the anomaly number)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: stressCol.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.insights, size: 18, color: stressCol),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('Body stress: ',
                          style: TextStyle(fontSize: 13, color: c.muted)),
                      Text(stress.label,
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800, color: stressCol)),
                    ]),
                    const SizedBox(height: 3),
                    Text(stress.meaning,
                        style: TextStyle(fontSize: 12, height: 1.35, color: c.ink)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Heart-rate graph with actionable caption
        Text('Heart rate today',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.muted)),
        const SizedBox(height: 8),
        MiniLineChart(
          values: day.hr,
          cursor: i,
          color: c.accent,
          warn: m.effHrWarn,
          critical: m.effHrCrit,
          minY: 45,
          maxY: 175,
        ),
        const SizedBox(height: 6),
        _caption(context, hr >= m.effHrWarn
            ? 'Above your limit line — slow down and cool off to bring it back down.'
            : 'Staying under your limit lines — keep doing what works.'),
        const SizedBox(height: 16),
        Text('Recovery (HRV) today',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.muted)),
        const SizedBox(height: 8),
        MiniLineChart(values: day.hrv, cursor: i, color: c.accent2, fill: true),
        const SizedBox(height: 6),
        _caption(context, hrv < day.prof.hrv0 - 12
            ? 'Below your usual — rest, hydrate and aim for an earlier night to lift it.'
            : 'Around your usual — good recovery; maintain sleep and hydration.'),
        const SizedBox(height: 16),
        Text('Heat strain today',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.muted)),
        const SizedBox(height: 8),
        const StrainChart(),
      ],
    );
  }

  Widget _caption(BuildContext context, String text) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lightbulb_outline, size: 14, color: c.accent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 11.5, height: 1.35, color: c.muted)),
        ),
      ],
    );
  }
}

class _VitalRow extends StatelessWidget {
  const _VitalRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.statusText,
    required this.color,
    required this.guidance,
  });
  final IconData icon;
  final String label, value, unit, statusText, guidance;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('$label  ',
                        style: TextStyle(fontSize: 13, color: c.muted)),
                    MonoText(value, size: 18, weight: FontWeight.w800, color: c.ink),
                    const SizedBox(width: 2),
                    Text(unit, style: TextStyle(fontSize: 11, color: c.faint)),
                    const Spacer(),
                    StatusPill(statusText, color: color),
                  ],
                ),
                const SizedBox(height: 2),
                Text(guidance,
                    style: TextStyle(fontSize: 12, height: 1.3, color: c.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
