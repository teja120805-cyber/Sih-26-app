import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// A grid of quick "smart insight" tiles derived from the intelligence features.
class SmartInsights extends StatelessWidget {
  const SmartInsights({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final i = s.cursor;
    final prof = day.prof;

    // time-to-next-alert (least-squares slope over last 6 PSI samples)
    final n = math.min(6, i + 1);
    final start = i + 1 - n;
    double sx = 0, sy = 0, sxy = 0, sxx = 0;
    for (var k = 0; k < n; k++) {
      final xx = k.toDouble(), yy = day.psi[start + k];
      sx += xx; sy += yy; sxy += xx * yy; sxx += xx * xx;
    }
    final denom = n * sxx - sx * sx;
    final slope = denom != 0 ? (n * sxy - sx * sy) / denom : 0.0;
    final tier = day.tier[i];
    final last = day.psi[i];
    String ttaVal, ttaSub;
    if (tier >= 3) {
      ttaVal = 'Now';
      ttaSub = 'critical tier';
    } else {
      final next = tier == 0 ? prof.l1 : tier == 1 ? prof.l2 : prof.l3;
      if (slope <= 0.002) {
        ttaVal = '—';
        ttaSub = 'not rising';
      } else {
        final mins = ((next - last) / slope * kStepMin).round();
        ttaVal = mins <= 0 || mins > 1440 ? '—' : '$mins min';
        ttaSub = 'to next tier';
      }
    }

    final acclimDelta = day.acclimHistory.first.score - day.acclimHistory.last.score;
    final rhrDelta = day.stats.rhrToday - prof.hr0;
    final pm25Pct = (day.pm25DoseCum[i] / (15 * 24) * 100).round();
    final noisePct = day.noiseDoseCum[i].round();

    final tiles = <_Tile>[
      _Tile(Icons.timer_outlined, 'Time to alert', ttaVal, ttaSub, c.accent),
      _Tile(Icons.thermostat_outlined, 'Heat adaptation',
          '${acclimDelta >= 0 ? '↓' : '↑'}${acclimDelta.abs().toStringAsFixed(1)}',
          acclimDelta > 1 ? 'adapting' : 'steady', acclimDelta > 1 ? c.ok : c.muted),
      _Tile(Icons.monitor_heart_outlined, 'Resting HR',
          '${rhrDelta >= 0 ? '+' : ''}${rhrDelta.toStringAsFixed(0)}', 'vs baseline',
          rhrDelta > 3 ? c.warning : c.ok),
      _Tile(Icons.bolt_outlined, 'Readiness', '${day.stats.readiness}',
          'out of 100', day.stats.readiness >= 66 ? c.ok : day.stats.readiness >= 40 ? c.warning : c.critical),
      _Tile(Icons.blur_on, 'Air dose', '$pm25Pct%', 'of WHO daily',
          pm25Pct >= 100 ? c.critical : pm25Pct >= 60 ? c.warning : c.accent),
      _Tile(Icons.hearing_outlined, 'Noise dose', '$noisePct%', 'of OSHA daily',
          noisePct >= 100 ? c.critical : noisePct >= 60 ? c.warning : c.accent),
    ];

    return SectionCard(
      eyebrow: 'Smart insights',
      title: 'What to watch',
      child: LayoutBuilder(builder: (context, box) {
        const gap = 10.0;
        final w = (box.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final t in tiles) SizedBox(width: w, child: _PillTile(t: t))],
        );
      }),
    );
  }
}

class _Tile {
  _Tile(this.icon, this.label, this.value, this.sub, this.color);
  final IconData icon;
  final String label, value, sub;
  final Color color;
}

class _PillTile extends StatelessWidget {
  const _PillTile({required this.t});
  final _Tile t;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.paper, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: t.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(t.icon, size: 18, color: t.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: c.faint)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: MonoText(t.value,
                          size: 16, weight: FontWeight.w700, color: t.color),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(t.sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: c.muted)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
