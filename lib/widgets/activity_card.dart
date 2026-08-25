import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/day_data.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Today's activity as concentric rings (steps / active calories / stand hours)
/// plus a hydration tracker whose target rises with heat and exercise.
class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final act = computeActivity(s.cursor, day);

    final stepsPct = (act.stepsSoFar / 10000).clamp(0.0, 1.0);
    final calPct = (act.activeCalories / 500).clamp(0.0, 1.0);
    final standPct = (act.standHours / 12).clamp(0.0, 1.0);

    return SectionCard(
      eyebrow: "Today's activity",
      title: 'Move, calories, stand & water',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 118,
                height: 118,
                child: CustomPaint(
                  painter: _RingsPainter(
                    values: [stepsPct, calPct, standPct],
                    colors: [c.accent, c.warning, c.advisory],
                    track: c.line,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatLine(
                      color: c.accent,
                      icon: Icons.directions_walk,
                      value: _fmt(act.stepsSoFar),
                      unit: 'steps',
                    ),
                    const SizedBox(height: 10),
                    _StatLine(
                      color: c.warning,
                      icon: Icons.local_fire_department_outlined,
                      value: '${act.activeCalories}',
                      unit: 'kcal',
                    ),
                    const SizedBox(height: 10),
                    _StatLine(
                      color: c.advisory,
                      icon: Icons.self_improvement_outlined,
                      value: '${act.standHours}',
                      unit: 'stand hrs',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: c.line, height: 1),
          const SizedBox(height: 14),
          _Hydration(target: act.hydrationTarget, glasses: s.waterGlasses),
        ],
      ),
    );
  }

  static String _fmt(int n) {
    final str = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return buf.toString();
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.color,
    required this.icon,
    required this.value,
    required this.unit,
  });
  final Color color;
  final IconData icon;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 8),
        MonoText(value, size: 20, weight: FontWeight.w600, color: c.ink),
        const SizedBox(width: 5),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(unit, style: TextStyle(fontSize: 12, color: c.faint)),
        ),
      ],
    );
  }
}

class _Hydration extends StatelessWidget {
  const _Hydration({required this.target, required this.glasses});
  final int target;
  final int glasses;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.water_drop_outlined, size: 16, color: c.accent),
            const SizedBox(width: 6),
            Text('Hydration', style: TextStyle(fontSize: 13, color: c.muted)),
            const Spacer(),
            MonoText('$glasses / $target',
                size: 14, weight: FontWeight.w700, color: c.ink),
            const SizedBox(width: 4),
            Text('glasses', style: TextStyle(fontSize: 12, color: c.faint)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            for (var i = 0; i < target; i++)
              Icon(
                Icons.water_drop,
                size: 18,
                color: i < glasses ? c.accent : c.lineStrong,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: s.addGlass,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add a glass'),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.accent,
                side: BorderSide(color: c.lineStrong),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(width: 8),
            if (glasses > 0)
              TextButton(
                onPressed: s.resetWater,
                style: TextButton.styleFrom(foregroundColor: c.faint),
                child: const Text('Reset'),
              ),
          ],
        ),
      ],
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({
    required this.values,
    required this.colors,
    required this.track,
  });

  final List<double> values;
  final List<Color> colors;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const stroke = 11.0;
    const gap = 4.0;
    for (var i = 0; i < values.length; i++) {
      final radius = size.width / 2 - stroke / 2 - i * (stroke + gap);
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        0,
        2 * math.pi,
        false,
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * values[i],
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) =>
      old.values.toString() != values.toString();
}
