import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/day_data.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// "Alerts today" — a severity bar chart, then a plain-language list of the
/// alerts that have fired up to the current moment, most recent first.
class AlertsCard extends StatefulWidget {
  const AlertsCard({super.key});

  @override
  State<AlertsCard> createState() => _AlertsCardState();
}

class _AlertsCardState extends State<AlertsCard> {
  bool showAll = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final nowMin = s.cursorMinute;

    // Events that have started by now, most recent first.
    final fired = day.events.where((e) => e.startMin <= nowMin).toList()
      ..sort((a, b) => b.startMin - a.startMin);

    final advisory = fired.where((e) => e.severity == 1).length;
    final warning = fired.where((e) => e.severity == 2).length;
    final critical = fired.where((e) => e.severity >= 3).length;
    final maxCount = math.max(1, [advisory, warning, critical].reduce(math.max));

    final visible = showAll ? fired : fired.take(4).toList();

    return SectionCard(
      eyebrow: 'Alerts today',
      title: '${fired.length} so far',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CountBar(label: 'Advisory', count: advisory, max: maxCount, color: c.advisory),
          const SizedBox(height: 8),
          _CountBar(label: 'Warning', count: warning, max: maxCount, color: c.warning),
          const SizedBox(height: 8),
          _CountBar(label: 'Critical', count: critical, max: maxCount, color: c.critical),
          const SizedBox(height: 16),
          if (fired.isEmpty)
            Row(
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: c.ok),
                const SizedBox(width: 8),
                Text('No alerts yet today — all clear.',
                    style: TextStyle(fontSize: 13, color: c.muted)),
              ],
            )
          else ...[
            for (final e in visible) _AlertRow(event: e),
            if (fired.length > 4)
              TextButton(
                onPressed: () => setState(() => showAll = !showAll),
                style: TextButton.styleFrom(
                    foregroundColor: c.accent,
                    padding: const EdgeInsets.symmetric(vertical: 4)),
                child: Text(showAll
                    ? 'Show fewer'
                    : 'Show earlier alerts (${fired.length - 4})'),
              ),
          ],
        ],
      ),
    );
  }
}

class _CountBar extends StatelessWidget {
  const _CountBar(
      {required this.label,
      required this.count,
      required this.max,
      required this.color});
  final String label;
  final int count;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        SizedBox(
          width: 66,
          child: Text(label, style: TextStyle(fontSize: 12, color: c.muted)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 12, color: c.line),
                FractionallySizedBox(
                  widthFactor: (count / max).clamp(0.0, 1.0),
                  child: Container(
                    height: 12,
                    color: count == 0 ? c.line : color,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 18,
          child: MonoText('$count', size: 12.5, color: c.ink),
        ),
      ],
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.event});
  final HealthEvent event;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final col = c.tier(event.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: col, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eventText(event),
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: c.ink)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    MonoText(
                      '${fmtClock(event.startMin)}–${fmtClock(event.endMin)}',
                      size: 11.5,
                      color: c.faint,
                    ),
                    const SizedBox(width: 8),
                    Text('· ${event.durationMin} min',
                        style: TextStyle(fontSize: 11.5, color: c.faint)),
                  ],
                ),
              ],
            ),
          ),
          Pill(
            event.severity >= 3
                ? 'Critical'
                : event.severity == 2
                    ? 'Warning'
                    : 'Advisory',
            fg: col,
            bg: c.tierSoft(event.severity),
          ),
        ],
      ),
    );
  }
}
