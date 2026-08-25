import 'package:flutter/material.dart';

import '../models/day_data.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// "Outside right now" — a plain description of conditions plus up to three
/// concrete actions, with a bar chart of each reading against its safety
/// threshold.
class EnvironmentCard extends StatelessWidget {
  const EnvironmentCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final i = s.cursor;
    final env = computeEnvironment(i, day);

    final wbgt = day.wbgt[i];
    final pm = day.pm25[i];
    final noise = day.noise[i];

    Color heatColor = wbgt >= 32
        ? c.critical
        : wbgt >= 28
            ? c.warning
            : wbgt >= 22
                ? c.advisory
                : c.ok;
    Color aqColor = pm > 90
        ? c.critical
        : pm > 55
            ? c.warning
            : pm > 35
                ? c.advisory
                : c.ok;
    Color noiseColor = noise >= 80
        ? c.warning
        : noise >= 65
            ? c.advisory
            : c.ok;

    return SectionCard(
      eyebrow: 'Outside right now',
      title: 'Conditions & what to do',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(env.desc,
              style: TextStyle(fontSize: 14.5, height: 1.45, color: c.ink)),
          const SizedBox(height: 14),
          ThresholdBar(
            label: 'Heat (personal WBGT)',
            valueText: '${wbgt.toStringAsFixed(1)}°C',
            fraction: wbgt / 40,
            color: heatColor,
          ),
          const SizedBox(height: 12),
          ThresholdBar(
            label: 'Air quality (PM2.5)',
            valueText: '${pm.toStringAsFixed(0)} µg/m³',
            fraction: pm / 150,
            color: aqColor,
          ),
          const SizedBox(height: 12),
          ThresholdBar(
            label: 'Ambient noise',
            valueText: '${noise.toStringAsFixed(0)} dB',
            fraction: (noise - 30) / (95 - 30),
            color: noiseColor,
          ),
          const SizedBox(height: 16),
          for (final m in env.measures)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(iconForName(m.icon), size: 16, color: c.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(m.text,
                        style: TextStyle(
                            fontSize: 13, height: 1.35, color: c.muted)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
