import 'package:flutter/material.dart';

import '../../widgets/activity_card.dart';
import '../../widgets/fx.dart';
import '../../widgets/hourly_activity_card.dart';
import '../../widgets/readiness_card.dart';

class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    const cards = <Widget>[
      ActivityCard(),
      HourlyActivityCard(),
      ReadinessCard(),
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
