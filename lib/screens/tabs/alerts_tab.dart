import 'package:flutter/material.dart';

import '../../state/console_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/alerts_card.dart';
import '../../widgets/common.dart';
import '../../widgets/fx.dart';

class AlertsTab extends StatelessWidget {
  const AlertsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final now = s.cursorMinute;
    final fired = day.events.where((e) => e.startMin <= now).toList();
    final warnings = fired.where((e) => e.severity == 2).length;
    final critical = fired.where((e) => e.severity >= 3).length;
    final prioritized = warnings + critical;

    final cards = <Widget>[
      _Summary(total: fired.length, warnings: warnings, critical: critical, prioritized: prioritized),
      const AlertsCard(),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          EntranceCard(index: i, child: cards[i]),
          if (i != cards.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.total, required this.warnings, required this.critical, required this.prioritized});
  final int total, warnings, critical, prioritized;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SectionCard(
      eyebrow: 'Alerts today',
      title: 'Summary',
      child: Row(
        children: [
          _Stat(value: '$total', label: 'Total', color: c.ink),
          _Stat(value: '$warnings', label: 'Warnings', color: c.warning),
          _Stat(value: '$critical', label: 'Critical', color: c.critical),
          _Stat(value: '$prioritized', label: 'Prioritized', color: c.accent),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});
  final String value, label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Column(
        children: [
          MonoText(value, size: 26, weight: FontWeight.w800, color: color),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: c.faint)),
        ],
      ),
    );
  }
}
