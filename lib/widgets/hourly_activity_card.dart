import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// 24-bar hourly step chart (day bars accent, night bars dimmed), with peak-hour
/// and current-hour insights.
class HourlyActivityCard extends StatelessWidget {
  const HourlyActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final steps = day.hourlySteps;
    final nowHour = s.cursorMinute ~/ 60;
    final maxSteps = math.max(1, steps.reduce(math.max));
    var peakHour = 0;
    for (var h = 1; h < 24; h++) {
      if (steps[h] > steps[peakHour]) peakHour = h;
    }

    return SectionCard(
      eyebrow: "Today's movement",
      title: 'Hourly activity',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var h = 0; h < 24; h++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: steps[h] / maxSteps),
                            duration: Duration(milliseconds: 400 + h * 12),
                            curve: Curves.easeOut,
                            builder: (context, v, _) => Container(
                              height: math.max(2, v * 92),
                              decoration: BoxDecoration(
                                color: h == nowHour
                                    ? c.accent2
                                    : (h >= 6 && h < 20)
                                        ? c.accent
                                        : c.accent.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('00', style: TextStyle(fontSize: 9, color: c.faint)),
              const Spacer(),
              Text('12', style: TextStyle(fontSize: 9, color: c.faint)),
              const Spacer(),
              Text('24', style: TextStyle(fontSize: 9, color: c.faint)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Insight(
                  label: 'Peak hour',
                  value: '${peakHour.toString().padLeft(2, '0')}:00',
                  sub: '${steps[peakHour]} steps',
                  color: c.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Insight(
                  label: 'This hour',
                  value: '${nowHour.toString().padLeft(2, '0')}:00',
                  sub: '${steps[nowHour.clamp(0, 23)]} steps',
                  color: c.accent2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Insight extends StatelessWidget {
  const _Insight({required this.label, required this.value, required this.sub, required this.color});
  final String label, value, sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(color: c.paper, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: c.faint)),
          const SizedBox(height: 3),
          MonoText(value, size: 17, weight: FontWeight.w700, color: color),
          Text(sub, style: TextStyle(fontSize: 11, color: c.muted)),
        ],
      ),
    );
  }
}
