import 'package:flutter/material.dart';

import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Band sync status + a one-line health headline + quick delta pills.
class WatchStatusCard extends StatelessWidget {
  const WatchStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final i = s.cursor;
    final tier = day.tier[i];
    final anom = day.anomaly[i];

    String headline;
    Color hc;
    IconData hi;
    if (tier >= 2) {
      headline = 'Action needed now';
      hc = c.critical;
      hi = Icons.warning_amber_rounded;
    } else if (anom >= 7) {
      headline = 'Anomaly detected';
      hc = c.warning;
      hi = Icons.blur_on;
    } else {
      headline = 'All signals within your plan';
      hc = c.ok;
      hi = Icons.check_circle_outline;
    }

    final hrDelta = day.hr[i] - day.prof.hr0;
    final tempDelta = day.coreTemp[i] - day.prof.tc0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.watch_outlined, size: 16, color: c.accent),
              const SizedBox(width: 6),
              Text('Band synced',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: c.muted)),
              const Spacer(),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                    color: s.playing ? c.accent : c.faint, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              MonoText(s.cursorClock, size: 13, color: c.ink),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(hi, size: 22, color: hc),
              const SizedBox(width: 10),
              Expanded(
                child: Text(headline,
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800, color: c.ink)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Delta(label: 'HR', value: '${hrDelta >= 0 ? '+' : ''}${hrDelta.toStringAsFixed(0)}', color: hrDelta.abs() > 20 ? c.warning : c.muted),
              const SizedBox(width: 8),
              _Delta(label: 'Temp', value: '${tempDelta >= 0 ? '+' : ''}${tempDelta.toStringAsFixed(1)}°', color: tempDelta > 1 ? c.warning : c.muted),
              const SizedBox(width: 8),
              _Delta(label: 'Anomaly', value: anom.toStringAsFixed(1), color: anom > 7 ? c.critical : c.muted),
            ],
          ),
        ],
      ),
    );
  }
}

class _Delta extends StatelessWidget {
  const _Delta({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: c.paper, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label ', style: TextStyle(fontSize: 11, color: c.faint)),
          MonoText(value, size: 12.5, weight: FontWeight.w700, color: color),
        ],
      ),
    );
  }
}
