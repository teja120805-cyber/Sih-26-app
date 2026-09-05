import 'package:flutter/material.dart';

import '../../models/health_status.dart';
import '../../state/console_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/expandable_stat_card.dart';
import '../main_scaffold.dart';

/// Left page 2 — Vitals. Each metric is a small card that expands into a full
/// day chart with Average / Min / Max and a plain-language takeaway.
class VitalsPage extends StatelessWidget {
  const VitalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final m = s.medical;
    final i = s.cursor;

    Widget note(String text) => Text(text,
        style: TextStyle(fontSize: 12.5, height: 1.4, color: c.muted));

    final hr = day.hr[i], spo2 = day.spo2[i], temp = day.coreTemp[i], hrv = day.hrv[i];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        const PageHeader(title: 'Vitals', subtitle: 'Tap a card to see the whole day'),
        ExpandableStatCard(
          icon: Icons.favorite,
          label: 'Heart rate',
          value: hr.toStringAsFixed(0),
          unit: 'bpm',
          statusText: hr >= m.effHrCrit ? 'Very high' : hr >= m.effHrWarn ? 'Elevated' : 'Normal',
          statusColor: hr >= m.effHrCrit ? c.critical : hr >= m.effHrWarn ? c.warning : c.ok,
          accent: c.accent,
          series: day.hr,
          cursor: i,
          warn: m.effHrWarn,
          critical: m.effHrCrit,
          minY: 45,
          maxY: 175,
          initiallyExpanded: true,
          detail: note(hrGuidance(hr, day.prof.hr0, m.effHrWarn)),
        ),
        const SizedBox(height: 12),
        ExpandableStatCard(
          icon: Icons.air,
          label: 'Blood oxygen (SpO₂)',
          value: spo2.toStringAsFixed(0),
          unit: '%',
          statusText: spo2 <= m.effSpo2Crit ? 'Low' : spo2 <= m.effSpo2Warn ? 'Dipping' : 'Healthy',
          statusColor: spo2 <= m.effSpo2Crit ? c.critical : spo2 <= m.effSpo2Warn ? c.warning : c.ok,
          accent: const Color(0xFF38BDF8),
          series: day.spo2,
          cursor: i,
          warn: m.effSpo2Warn,
          critical: m.effSpo2Crit,
          minY: 88,
          maxY: 100,
          detail: note(spo2Guidance(spo2, m.effSpo2Warn)),
        ),
        const SizedBox(height: 12),
        ExpandableStatCard(
          icon: Icons.thermostat,
          label: 'Body temperature',
          value: temp.toStringAsFixed(1),
          unit: '°C',
          statusText: temp >= m.effTempCrit ? 'Overheating' : temp >= m.effTempWarn ? 'Warm' : 'Normal',
          statusColor: temp >= m.effTempCrit ? c.critical : temp >= m.effTempWarn ? c.warning : c.ok,
          accent: c.tempTrace,
          series: day.coreTemp,
          cursor: i,
          warn: m.effTempWarn,
          critical: m.effTempCrit,
          minY: 36.4,
          maxY: 39.6,
          detail: note(coreTempGuidance(temp, m.effTempWarn)),
        ),
        const SizedBox(height: 12),
        ExpandableStatCard(
          icon: Icons.self_improvement,
          label: 'Recovery (HRV)',
          value: hrv.toStringAsFixed(0),
          unit: 'ms',
          statusText: hrv < day.prof.hrv0 - 12 ? 'Low' : 'Healthy',
          statusColor: hrv < day.prof.hrv0 - 12 ? c.warning : c.ok,
          accent: c.accent2,
          series: day.hrv,
          cursor: i,
          fill: true,
          detail: note(hrvGuidance(hrv, day.prof.hrv0)),
        ),
        const SizedBox(height: 12),
        ExpandableStatCard(
          icon: Icons.waves,
          label: 'Breathing rate',
          value: day.respRate[i].toStringAsFixed(0),
          unit: '/min',
          statusText: day.respRate[i] > 20 ? 'Fast' : 'Steady',
          statusColor: day.respRate[i] > 20 ? c.warning : c.ok,
          accent: const Color(0xFF34D399),
          series: day.respRate,
          cursor: i,
          fill: true,
          detail: note('Your breathing rate across the day. Faster breathing often tracks exertion or heat.'),
        ),
      ],
    );
  }
}
