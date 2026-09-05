import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/day_data.dart';
import '../../state/console_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/environment_card.dart';
import '../../widgets/exposure_dose_card.dart';
import '../main_scaffold.dart';

/// Far-right page — smartwatch-style controls: hydration, breathing, exposure.
class HydrationControlsPage extends StatelessWidget {
  const HydrationControlsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final act = computeActivity(s.cursor, s.day!);
    final target = act.hydrationTarget;
    final glasses = s.waterGlasses;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        const PageHeader(title: 'Water & more', subtitle: 'Hydration and quick controls'),
        // Water tracker
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.water_drop, color: const Color(0xFF38BDF8), size: 22),
                const SizedBox(width: 8),
                Text('Hydration', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.ink)),
                const Spacer(),
                MonoText('$glasses / $target', size: 18, weight: FontWeight.w900, color: c.ink),
                Text(' glasses', style: TextStyle(fontSize: 12, color: c.faint)),
              ]),
              const SizedBox(height: 14),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (var i = 0; i < target; i++)
                    Icon(Icons.water_drop, size: 26, color: i < glasses ? const Color(0xFF38BDF8) : c.lineStrong),
                ],
              ),
              const SizedBox(height: 8),
              Text('Target rises with heat and activity — today it is $target glasses.',
                  style: TextStyle(fontSize: 12, color: c.muted)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () { HapticFeedback.lightImpact(); s.addGlass(); },
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), padding: const EdgeInsets.symmetric(vertical: 13)),
                    icon: const Icon(Icons.add),
                    label: const Text('Add a glass'),
                  ),
                ),
                if (glasses > 0) ...[
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: s.resetWater,
                    style: OutlinedButton.styleFrom(foregroundColor: c.muted, side: BorderSide(color: c.lineStrong), padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16)),
                    child: const Text('Reset'),
                  ),
                ],
              ]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Breathing control
        GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('1-minute breathing — demo')),
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [c.accent2, c.accent]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              const Icon(Icons.air, color: Colors.white, size: 30),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Breathe', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                  SizedBox(height: 2),
                  Text('1-minute guided breathing to settle your heart rate',
                      style: TextStyle(fontSize: 12.5, color: Colors.white)),
                ]),
              ),
              const Icon(Icons.play_circle_fill, color: Colors.white, size: 34),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        const ExposureDoseCard(),
        const SizedBox(height: 12),
        const EnvironmentCard(),
      ],
    );
  }
}
