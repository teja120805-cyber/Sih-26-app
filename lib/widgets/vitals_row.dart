import 'package:flutter/material.dart';

import '../models/day_data.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Exactly three numbers — heart rate, SpO₂, estimated core temperature — each
/// with a small range gauge against the wearer's own baseline, plus the live
/// ML vitals-risk classifier reading.
class VitalsRow extends StatelessWidget {
  const VitalsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final i = s.cursor;
    final prof = day.prof;

    final risk = day.vitalsRisk[i];
    final riskTier = risk >= 0.6
        ? 3
        : risk >= 0.45
            ? 2
            : risk >= 0.3
                ? 1
                : 0;
    final riskLabel = risk >= 0.6
        ? 'High'
        : risk >= 0.45
            ? 'Elevated'
            : risk >= 0.3
                ? 'Moderate'
                : 'Low';

    return SectionCard(
      eyebrow: 'Vitals',
      title: 'The three a doctor asks for first',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Vital(
                  label: 'Heart rate',
                  value: day.hr[i].toStringAsFixed(0),
                  unit: 'bpm',
                  fraction: ((day.hr[i] - 50) / (180 - 50)).clamp(0.0, 1.0),
                  baselineFraction: ((prof.hr0 - 50) / (180 - 50)).clamp(0.0, 1.0),
                  color: c.accent,
                ),
              ),
              _divider(c),
              Expanded(
                child: _Vital(
                  label: 'SpO₂',
                  value: day.spo2[i].toStringAsFixed(0),
                  unit: '%',
                  fraction: ((day.spo2[i] - 90) / (100 - 90)).clamp(0.0, 1.0),
                  baselineFraction:
                      ((prof.spo20 - 90) / (100 - 90)).clamp(0.0, 1.0),
                  color: c.accent,
                ),
              ),
              _divider(c),
              Expanded(
                child: _Vital(
                  label: 'Core temp',
                  value: day.coreTemp[i].toStringAsFixed(1),
                  unit: '°C',
                  fraction:
                      ((day.coreTemp[i] - 36.5) / (39.5 - 36.5)).clamp(0.0, 1.0),
                  baselineFraction:
                      ((prof.tc0 - 36.5) / (39.5 - 36.5)).clamp(0.0, 1.0),
                  color: c.tempTrace,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.tierSoft(riskTier),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology_outlined, size: 18, color: c.tier(riskTier)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ML vitals-risk classifier',
                    style: TextStyle(fontSize: 12.5, color: c.muted),
                  ),
                ),
                MonoText('${(risk * 100).toStringAsFixed(0)}%',
                    size: 14, weight: FontWeight.w700, color: c.tier(riskTier)),
                const SizedBox(width: 8),
                Pill(riskLabel, fg: c.tier(riskTier), bg: c.panel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(AppColors c) => Container(
        width: 1,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: c.line,
      );
}

class _Vital extends StatelessWidget {
  const _Vital({
    required this.label,
    required this.value,
    required this.unit,
    required this.fraction,
    required this.baselineFraction,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final double fraction;
  final double baselineFraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: c.faint)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            MonoText(value, size: 24, weight: FontWeight.w600, color: c.ink),
            const SizedBox(width: 2),
            Text(unit, style: TextStyle(fontSize: 11, color: c.faint)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 8,
          child: CustomPaint(
            size: Size.infinite,
            painter: _GaugePainter(
              fraction: fraction,
              baseline: baselineFraction,
              fill: color,
              track: c.line,
              baselineColor: c.faint,
            ),
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.fraction,
    required this.baseline,
    required this.fill,
    required this.track,
    required this.baselineColor,
  });

  final double fraction;
  final double baseline;
  final Color fill;
  final Color track;
  final Color baselineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;
    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(r));
    canvas.drawRRect(rrect, Paint()..color = track);

    // Baseline tick.
    final bx = (baseline * size.width).clamp(2.0, size.width - 2);
    canvas.drawLine(
      Offset(bx, -1),
      Offset(bx, size.height + 1),
      Paint()
        ..color = baselineColor
        ..strokeWidth = 1.4,
    );

    // Current marker.
    final mx = (fraction * size.width).clamp(r, size.width - r);
    canvas.drawCircle(Offset(mx, size.height / 2), r, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.fraction != fraction || old.baseline != baseline || old.fill != fill;
}
