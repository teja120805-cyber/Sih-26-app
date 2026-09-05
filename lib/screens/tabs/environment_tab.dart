import 'package:flutter/material.dart';

import '../../widgets/acclimatization_card.dart';
import '../../widgets/environment_card.dart';
import '../../widgets/exposure_dose_card.dart';
import '../../widgets/fx.dart';
import '../../widgets/route_map_card.dart';

class EnvironmentTab extends StatelessWidget {
  const EnvironmentTab({super.key});

  @override
  Widget build(BuildContext context) {
    const cards = <Widget>[
      EnvironmentCard(),
      ExposureDoseCard(),
      AcclimatizationCard(),
      RouteMapCard(),
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
