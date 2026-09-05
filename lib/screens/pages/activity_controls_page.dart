import 'package:flutter/material.dart';

import '../../models/day_data.dart';
import '../../state/console_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/common.dart';
import '../../widgets/hourly_activity_card.dart';
import '../main_scaffold.dart';

/// Right page — smartwatch-style activity: rings, goals and a workout tile.
class ActivityControlsPage extends StatelessWidget {
  const ActivityControlsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final act = computeActivity(s.cursor, s.day!);
    final stepGoal = 10000;
    final pct = (act.stepsSoFar / stepGoal).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        const PageHeader(title: 'Activity', subtitle: 'Move, calories & goals'),
        // Big step goal control
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Steps today', style: TextStyle(fontSize: 12.5, color: c.muted)),
                    const SizedBox(height: 4),
                    Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                      MonoText('${act.stepsSoFar}', size: 30, weight: FontWeight.w900, color: c.ink),
                      Text(' / $stepGoal', style: TextStyle(fontSize: 13, color: c.faint)),
                    ]),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 10,
                        backgroundColor: c.line,
                        valueColor: AlwaysStoppedAnimation(c.ok),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${(pct * 100).round()}% of your daily goal',
                        style: TextStyle(fontSize: 12, color: c.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const ActivityCard(),
        const SizedBox(height: 12),
        const HourlyActivityCard(),
        const SizedBox(height: 12),
        Row(children: [
          _Control(icon: Icons.directions_run, label: 'Start\nworkout', color: c.warning),
          const SizedBox(width: 12),
          _Control(icon: Icons.self_improvement, label: 'Stand\nreminder', color: c.accent2),
        ]),
      ],
    );
  }
}

class _Control extends StatelessWidget {
  const _Control({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${label.replaceAll('\n', ' ')} — demo')),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: c.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.line),
          ),
          child: Column(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.ink)),
          ]),
        ),
      ),
    );
  }
}
