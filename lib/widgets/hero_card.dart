import 'package:flutter/material.dart';

import '../models/day_data.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// The single-glance headline: how you're doing right now and what to do,
/// color-coded by severity, with 1–3 quick action chips.
class HeroCard extends StatelessWidget {
  const HeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final hero = computeHero(s.cursor, day, s.profile);
    final sevColor = c.tier(hero.sev);
    final sevBg = hero.sev == 0 ? c.panel : c.tierSoft(hero.sev);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: sevBg,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: sevColor, width: 4),
          top: BorderSide(color: c.line),
          right: BorderSide(color: c.line),
          bottom: BorderSide(color: c.line),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Eyebrow('Right now', color: sevColor),
              const Spacer(),
              MonoText(s.cursorClock, size: 12.5, color: c.muted),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hero.headline,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hero.body,
            style: TextStyle(fontSize: 14.5, height: 1.45, color: c.muted),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in hero.actions)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.panel,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconForName(a.icon), size: 15, color: sevColor),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Text(
                          a.text,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: c.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
