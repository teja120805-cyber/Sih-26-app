import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/fall_check_card.dart';

class FallScreen extends StatelessWidget {
  const FallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Fall detection'), backgroundColor: c.paper),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          const FallCheckCard(),
          const SizedBox(height: 14),
          SectionCard(
            eyebrow: 'How it works',
            title: 'Detect → confirm → alert',
            child: Column(
              children: const [
                _Step(n: 1, title: 'Detect', body: 'The IMU flags a hard impact (>2.5g) plus a rapid orientation change (>200°/s).'),
                _Step(n: 2, title: 'Confirm', body: 'A 10-second no-response countdown starts, so you can cancel a false alarm.'),
                _Step(n: 3, title: 'Alert', body: 'If you don\'t respond, a contact would be alerted with your location.'),
                _Step(n: 4, title: 'Severity', body: 'Impact force + stillness classify the fall so responders know the urgency.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.title, required this.body});
  final int n;
  final String title, body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: c.accentSoft, borderRadius: BorderRadius.circular(9)),
            child: Text('$n',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: c.accent)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: c.ink)),
                const SizedBox(height: 2),
                Text(body,
                    style: TextStyle(fontSize: 12.5, height: 1.35, color: c.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
