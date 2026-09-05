import 'package:flutter/material.dart';

import '../../widgets/current_sleep_stage_card.dart';
import '../../widgets/fx.dart';
import '../../widgets/readiness_card.dart';
import '../../widgets/sleep_card.dart';

class SleepTab extends StatelessWidget {
  const SleepTab({super.key});

  @override
  Widget build(BuildContext context) {
    const cards = <Widget>[
      SleepCard(),
      CurrentSleepStageCard(),
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
