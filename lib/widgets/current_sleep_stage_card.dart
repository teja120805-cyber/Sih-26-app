import 'package:flutter/material.dart';

import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Shows the sleep stage at the current cursor time (large), for the Sleep tab.
class CurrentSleepStageCard extends StatelessWidget {
  const CurrentSleepStageCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final stage = day.sleepStage[s.cursor];
    final asleep = stage != 'Awake';

    final desc = switch (stage) {
      'Deep' => 'Deep sleep — physical restoration and recovery.',
      'REM' => 'REM sleep — dreaming, memory and mood consolidation.',
      'Light' => 'Light sleep — the bridge between wake and deep stages.',
      _ => 'Awake — not currently in a sleep stage.',
    };

    return SectionCard(
      eyebrow: 'Right now',
      title: 'Current sleep stage',
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
                color: c.accentSoft, borderRadius: BorderRadius.circular(14)),
            child: Icon(asleep ? Icons.bedtime : Icons.wb_sunny_outlined,
                color: c.accent, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stage,
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800, color: c.ink)),
                const SizedBox(height: 2),
                Text(desc,
                    style: TextStyle(fontSize: 12.5, height: 1.35, color: c.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
