import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/day_data.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'fx.dart';

/// Environmental exposure dose — two real dose formulas on a personal wearable:
/// a WHO-guideline PM2.5 dose (time-integral of exposure) and an OSHA Hearing
/// Conservation noise dose, each vs 100% of the daily allowance, plus a 14-day
/// calendar heatmap (13 illustrative + 1 real "today").
class ExposureDoseCard extends StatelessWidget {
  const ExposureDoseCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final i = s.cursor;

    final pm25Ratio = day.pm25DoseCum[i] / (15 * 24);
    final noisePct = day.noiseDoseCum[i];

    final pmColor = pm25Ratio >= 1
        ? c.critical
        : pm25Ratio >= 0.6
            ? c.warning
            : c.accent;
    final noiseColor = noisePct >= 100
        ? c.critical
        : noisePct >= 60
            ? c.warning
            : c.accent;

    return SectionCard(
      eyebrow: 'Environmental exposure dose',
      title: 'How much you have taken in today',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _DoseDonut(
                  fraction: pm25Ratio.clamp(0.0, 1.0),
                  centerText: '${(pm25Ratio * 100).round()}%',
                  centerSub: 'PM2.5 dose',
                  color: pmColor,
                ),
              ),
              Expanded(
                child: _DoseDonut(
                  fraction: (noisePct / 100).clamp(0.0, 1.0),
                  centerText: '${noisePct.round()}%',
                  centerSub: 'Noise dose',
                  color: noiseColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DoseNote(
            pm25Pct: (pm25Ratio * 100).round(),
            noisePct: noisePct.round(),
          ),
          const SizedBox(height: 16),
          Eyebrow('Last 14 days · PM2.5 dose', color: c.faint),
          const SizedBox(height: 8),
          _Heatmap(history: day.doseHistory),
          const SizedBox(height: 8),
          Text(
            'Cell shade = that day\'s PM2.5 dose ratio. The outlined cell is today '
            '(real); the rest are illustrative, seeded from this build\'s '
            'calibration statistics.',
            style: TextStyle(fontSize: 11.5, height: 1.4, color: c.faint),
          ),
        ],
      ),
    );
  }
}

class _DoseDonut extends StatelessWidget {
  const _DoseDonut({
    required this.fraction,
    required this.centerText,
    required this.centerSub,
    required this.color,
  });
  final double fraction;
  final String centerText;
  final String centerSub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: AnimatedDonut(
            fraction: fraction,
            fill: color,
            track: c.line,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MonoText(centerText,
                    size: 20, weight: FontWeight.w700, color: color),
                Text(centerSub,
                    style: TextStyle(fontSize: 9.5, color: c.faint)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DoseNote extends StatelessWidget {
  const _DoseNote({required this.pm25Pct, required this.noisePct});
  final int pm25Pct;
  final int noisePct;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    TextSpan bold(String t) =>
        TextSpan(text: t, style: TextStyle(fontWeight: FontWeight.w700, color: c.ink));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.line),
      ),
      child: Text.rich(
        TextSpan(
          style: TextStyle(fontSize: 12, height: 1.5, color: c.muted),
          children: [
            bold('PM2.5 dose'),
            TextSpan(
                text: ' — $pm25Pct% of today\'s WHO 24-hour guideline allowance, '
                    'integrated over time (µg·h/m³), not just this instant\'s reading.\n\n'),
            bold('Noise dose'),
            TextSpan(
                text: ' — $noisePct%, the OSHA Hearing Conservation formula '
                    '(90 dBA permissible for 8h, 5 dB exchange rate) industrial '
                    'dosimeters use, on a personal wearable.'),
          ],
        ),
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.history});
  final List<DoseDay> history;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxRatio = math.max(
      0.2,
      history.map((d) => d.pm25Ratio).fold<double>(0, math.max),
    );
    return LayoutBuilder(builder: (context, box) {
      const gap = 5.0;
      final cell = (box.maxWidth - gap * 13) / 14;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final d in history)
            Tooltip(
              message: d.illustrative
                  ? '${d.offset}d ago · PM2.5 ${(d.pm25Ratio * 100).round()}% · noise ${d.noisePct.round()}% (illustrative)'
                  : 'Today · PM2.5 ${(d.pm25Ratio * 100).round()}% · noise ${d.noisePct.round()}%',
              child: Container(
                width: cell,
                height: cell,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    c.line,
                    d.pm25Ratio >= 1 ? c.critical : c.accent,
                    (0.12 + 0.88 * (d.pm25Ratio / maxRatio)).clamp(0.0, 1.0),
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: d.illustrative
                      ? null
                      : Border.all(color: c.ink, width: 1.6),
                ),
              ),
            ),
        ],
      );
    });
  }
}
