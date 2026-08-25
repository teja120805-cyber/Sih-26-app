import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/day_data.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Last night's sleep: a 0–100 score donut, time in each stage, a plain
/// takeaway, and a recovery note comparing overnight HRV/breathing to the
/// wearer's own typical range.
class SleepCard extends StatelessWidget {
  const SleepCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final st = day.stats;
    final recovery = computeRecovery(day, day.prof);

    final totalStage = (st.deepMinutes + st.lightMinutes + st.remMinutes)
        .clamp(1, 1 << 30);

    String takeaway;
    if (st.sleepQuality >= 80) {
      takeaway = 'A strong night — you got solid deep and REM sleep.';
    } else if (st.sleepQuality >= 65) {
      takeaway = 'A decent night overall, with room for a little more deep sleep.';
    } else if (st.sleepQuality >= 50) {
      takeaway = 'A patchy night — consider an earlier, calmer wind-down tonight.';
    } else {
      takeaway = 'A rough night — deep-sleep time was low. Take it easier today.';
    }

    return SectionCard(
      eyebrow: 'Sleep, last night',
      title: 'Score, stages & recovery',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: CustomPaint(
                  painter: _DonutPainter(
                    fraction: st.sleepQuality / 100,
                    fill: c.accent,
                    track: c.line,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MonoText('${st.sleepQuality}',
                            size: 26, weight: FontWeight.w700, color: c.ink),
                        Text('/100',
                            style: TextStyle(fontSize: 10, color: c.faint)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      takeaway,
                      style: TextStyle(fontSize: 13.5, height: 1.4, color: c.ink),
                    ),
                    const SizedBox(height: 8),
                    MonoText(
                      '${(totalStage / 60).toStringAsFixed(1)} h asleep',
                      size: 12.5,
                      color: c.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stage bar.
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: math.max(1, st.deepMinutes),
                    child: Container(color: c.accentInk),
                  ),
                  Expanded(
                    flex: math.max(1, st.remMinutes),
                    child: Container(color: c.accent),
                  ),
                  Expanded(
                    flex: math.max(1, st.lightMinutes),
                    child: Container(color: c.accentSoft.withValues(alpha: 1)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _StageLegend(color: c.accentInk, label: 'Deep', min: st.deepMinutes),
              _StageLegend(color: c.accent, label: 'REM', min: st.remMinutes),
              _StageLegend(
                  color: c.accentSoft.withValues(alpha: 1),
                  label: 'Light',
                  min: st.lightMinutes),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: c.panel,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(iconForName(recovery.icon),
                    size: 17,
                    color: recovery.icon == 'check' ? c.ok : c.advisory),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recovery.text,
                    style: TextStyle(fontSize: 12.5, height: 1.4, color: c.muted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StageLegend extends StatelessWidget {
  const _StageLegend(
      {required this.color, required this.label, required this.min});
  final Color color;
  final String label;
  final int min;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text('$label ',
            style: TextStyle(fontSize: 12, color: c.muted)),
        MonoText('${min}m', size: 12, color: c.ink),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.fraction,
    required this.fill,
    required this.track,
  });
  final double fraction;
  final Color fill;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const stroke = 9.0;
    final rect = Rect.fromCircle(center: center, radius: size.width / 2 - stroke / 2);
    canvas.drawArc(rect, 0, 2 * math.pi, false,
        Paint()..color = track..style = PaintingStyle.stroke..strokeWidth = stroke);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = fill
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.fraction != fraction;
}
