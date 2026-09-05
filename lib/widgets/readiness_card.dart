import 'package:flutter/material.dart';

import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'fx.dart';

/// Readiness — a transparent WHOOP/Oura-style composite (HRV, resting HR,
/// breathing rate, sleep quality). Explicitly not a trained model.
class ReadinessCard extends StatelessWidget {
  const ReadinessCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final r = day.stats.readiness;
    final col = r >= 66 ? c.ok : r >= 40 ? c.warning : c.critical;
    final verdict = r >= 66
        ? 'Well recovered — you can take on a normal or hard day.'
        : r >= 40
            ? 'Moderately recovered — keep today steady.'
            : 'Low recovery — prioritise rest and hydration today.';

    return SectionCard(
      eyebrow: 'Recovery',
      title: 'Readiness',
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: AnimatedDonut(
              fraction: r / 100,
              fill: col,
              track: c.line,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MonoText('$r', size: 26, weight: FontWeight.w800, color: c.ink),
                  Text('/100', style: TextStyle(fontSize: 10, color: c.faint)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(verdict,
                    style: TextStyle(fontSize: 13.5, height: 1.4, color: c.ink)),
                const SizedBox(height: 8),
                Text(
                  'HRV 40% · resting HR 25% · breathing 15% · sleep 20%. A transparent formula, not a trained model.',
                  style: TextStyle(fontSize: 11, height: 1.35, color: c.faint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
