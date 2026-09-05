import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/medical_profile.dart';
import '../../state/console_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/fx.dart';
import '../main_scaffold.dart';

class ConditionsScreen extends StatelessWidget {
  const ConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final m = s.medical;
    final eff = m.effectiveProfile();
    final mult = m.thresholdMultiplier;
    final total = MedicalCondition.values.length;
    final selected = m.conditions.length;

    int hrWarn = (108 * mult).round(), hrCrit = (135 * mult).round();
    int spo2Warn = (94 + (1 - mult) * 10).round().clamp(90, 97);
    int spo2Crit = (90 + (1 - mult) * 8).round().clamp(85, 94);
    double tempWarn = 37.8 - (1 - mult) * 0.6;
    double tempCrit = 38.6 - (1 - mult) * 0.6;

    return Scaffold(
      appBar: AppBar(title: const Text('Medical conditions'), backgroundColor: c.paper),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text('Select your conditions',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
            const SizedBox(height: 4),
            Text(
              'Each raises your risk score, tightening alert thresholds so warnings arrive sooner.',
              style: TextStyle(fontSize: 13, height: 1.4, color: c.muted),
            ),
            const SizedBox(height: 18),
            // Doughnut: X of N selected
            Center(
              child: SizedBox(
                width: 130,
                height: 130,
                child: AnimatedDonut(
                  fraction: total == 0 ? 0 : selected / total,
                  fill: c.accent,
                  track: c.line,
                  stroke: 12,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MonoText('$selected',
                          size: 30, weight: FontWeight.w800, color: c.ink),
                      Text('of $total',
                          style: TextStyle(fontSize: 12, color: c.faint)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cond in MedicalCondition.values)
                  _Chip(
                    condition: cond,
                    selected: m.conditions.contains(cond),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      s.toggleCondition(cond);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _ThreshCard(label: 'Heart Rate', warn: '$hrWarn', crit: '$hrCrit', unit: 'bpm', icon: Icons.favorite, color: c.critical)),
                const SizedBox(width: 10),
                Expanded(child: _ThreshCard(label: 'SpO₂', warn: '$spo2Warn', crit: '$spo2Crit', unit: '%', icon: Icons.air, color: c.accent)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _ThreshCard(label: 'Core Temp', warn: tempWarn.toStringAsFixed(1), crit: tempCrit.toStringAsFixed(1), unit: '°C', icon: Icons.thermostat, color: c.tempTrace)),
                const SizedBox(width: 10),
                Expanded(child: _ThreshCard(label: 'Strain', warn: eff.l2.toStringAsFixed(1), crit: eff.l3.toStringAsFixed(1), unit: 'PSI', icon: Icons.bolt, color: c.warning)),
              ],
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Enter app',
              icon: Icons.arrow_forward,
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainScaffold()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.condition, required this.selected, required this.onTap});
  final MedicalCondition condition;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? c.accentSoft : c.panel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c.accent : c.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? Icons.check_circle : Icons.add_circle_outline,
                size: 15, color: selected ? c.accent : c.faint),
            const SizedBox(width: 6),
            Text(condition.label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? c.accent : c.ink)),
          ],
        ),
      ),
    );
  }
}

class _ThreshCard extends StatelessWidget {
  const _ThreshCard({
    required this.label,
    required this.warn,
    required this.crit,
    required this.unit,
    required this.icon,
    required this.color,
  });
  final String label, warn, crit, unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12.5, color: c.muted)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _val(context, 'Warn', warn, unit, c.warning),
            const SizedBox(width: 14),
            _val(context, 'Crit', crit, unit, c.critical),
          ]),
        ],
      ),
    );
  }

  Widget _val(BuildContext context, String lbl, String v, String unit, Color col) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lbl, style: TextStyle(fontSize: 10, color: c.faint)),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          MonoText(v, size: 15, weight: FontWeight.w700, color: col),
          const SizedBox(width: 2),
          Text(unit, style: TextStyle(fontSize: 9, color: c.faint)),
        ]),
      ],
    );
  }
}
