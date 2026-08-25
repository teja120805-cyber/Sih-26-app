import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/acclimatization_card.dart';
import '../widgets/activity_card.dart';
import '../widgets/environment_card.dart';
import '../widgets/exposure_dose_card.dart';
import '../widgets/fall_check_card.dart';
import '../widgets/fx.dart';
import '../widgets/route_map_card.dart';
import '../widgets/sleep_card.dart';
import '../widgets/transparency_card.dart';
import '../widgets/waterfall_card.dart';

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const cards = <Widget>[
      ActivityCard(),
      SleepCard(),
      EnvironmentCard(),
      ExposureDoseCard(),
      AcclimatizationCard(),
      WaterfallCard(),
      RouteMapCard(),
      FallCheckCard(),
      TransparencyCard(),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 10, 2, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trends & insights',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: c.ink)),
              const SizedBox(height: 2),
              Text('Activity, sleep, environment & the models behind it all',
                  style: TextStyle(fontSize: 13.5, color: c.muted)),
            ],
          ),
        ),
        for (var i = 0; i < cards.length; i++) ...[
          EntranceCard(index: i, child: cards[i]),
          if (i != cards.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}
