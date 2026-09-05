import 'package:flutter/material.dart';

import '../../main.dart' show ThemeScope;
import '../../state/console_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/alerts_card.dart';
import '../../widgets/demo_bar.dart';
import '../../widgets/route_map_card.dart';
import '../../widgets/status_hero.dart';
import '../main_scaffold.dart';

/// Middle page — the hub. Status headline, quick jumps to the other four
/// screens, today's alerts, and a map of where triggers happened.
class MenuPage extends StatelessWidget {
  const MenuPage({super.key, required this.onJump});
  final void Function(int) onJump;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final name = s.medical.name.trim();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        PageHeader(
          title: name.isEmpty ? 'Your health' : 'Hi, ${name.split(' ').first}',
          subtitle: 'Swipe left for health · right for controls',
          trailing: IconButton(
            onPressed: () => ThemeScope.of(context).toggle(),
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: c.muted),
          ),
        ),
        const StatusHero(),
        const SizedBox(height: 14),
        // Quick jumps
        Row(children: [
          _Tile(icon: Icons.monitor_heart_outlined, label: 'Vitals', color: c.accent, onTap: () => onJump(1)),
          const SizedBox(width: 12),
          _Tile(icon: Icons.favorite_outline, label: 'Health', color: c.accent2, onTap: () => onJump(0)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _Tile(icon: Icons.directions_walk, label: 'Activity', color: c.ok, onTap: () => onJump(3)),
          const SizedBox(width: 12),
          _Tile(icon: Icons.water_drop_outlined, label: 'Water', color: const Color(0xFF38BDF8), onTap: () => onJump(4)),
        ]),
        const SizedBox(height: 14),
        const AlertsCard(),
        const SizedBox(height: 14),
        const RouteMapCard(),
        const SizedBox(height: 14),
        const DemoControls(),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: c.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.ink)),
            ],
          ),
        ),
      ),
    );
  }
}
