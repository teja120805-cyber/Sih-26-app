import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/medical_profile.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final m = s.medical;
    final eff = m.effectiveProfile();

    Color riskColor = switch (m.riskLevel) {
      'High' => c.critical,
      'Elevated' => c.warning,
      'Moderate' => c.advisory,
      _ => c.ok,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 10, 2, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your profile',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: c.ink)),
              const SizedBox(height: 2),
              Text('Tell us about you — it tunes how early alerts fire',
                  style: TextStyle(fontSize: 13.5, color: c.muted)),
            ],
          ),
        ),

        // Risk summary
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: c.heroGradient),
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RISK LEVEL',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: Colors.white.withValues(alpha: 0.85))),
                    const SizedBox(height: 4),
                    Text(m.riskLevel,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      m.earlierByPct > 0
                          ? 'Alerts fire ~${m.earlierByPct}% earlier than a typical adult'
                          : 'Standard alert sensitivity',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.92)),
                    ),
                  ],
                ),
              ),
              _Ring(score: m.riskScore),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Demographics
        SectionCard(
          eyebrow: 'About you',
          title: 'Demographics',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SliderRow(
                label: 'Age',
                value: '${m.age}',
                unit: 'yrs',
                sliderValue: m.age.toDouble(),
                min: 12,
                max: 95,
                divisions: 83,
                onChanged: (v) => s.setAge(v.round()),
              ),
              const SizedBox(height: 6),
              Text('Sex', style: TextStyle(fontSize: 12.5, color: c.muted)),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final g in Gender.values) ...[
                    Expanded(
                      child: _Choice(
                        label: g.label,
                        selected: m.gender == g,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          s.setGender(g);
                        },
                      ),
                    ),
                    if (g != Gender.values.last) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              _SliderRow(
                label: 'Height',
                value: m.heightCm.round().toString(),
                unit: 'cm',
                sliderValue: m.heightCm,
                min: 130,
                max: 210,
                divisions: 80,
                onChanged: (v) => s.setHeight(v.roundToDouble()),
              ),
              const SizedBox(height: 10),
              _SliderRow(
                label: 'Weight',
                value: m.weightKg.round().toString(),
                unit: 'kg',
                sliderValue: m.weightKg,
                min: 35,
                max: 160,
                divisions: 125,
                onChanged: (v) => s.setWeight(v.roundToDouble()),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: c.paper,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.straighten, size: 16, color: c.accent),
                    const SizedBox(width: 8),
                    Text('BMI', style: TextStyle(fontSize: 13, color: c.muted)),
                    const Spacer(),
                    MonoText(m.bmi.toStringAsFixed(1),
                        size: 14, weight: FontWeight.w700, color: c.ink),
                    const SizedBox(width: 6),
                    Text('· ${bmiCategory(m.bmi)}',
                        style: TextStyle(fontSize: 12.5, color: c.faint)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Conditions
        SectionCard(
          eyebrow: 'Medical conditions',
          title: 'Select any that apply',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cond in MedicalCondition.values)
                    _ConditionChip(
                      condition: cond,
                      selected: m.conditions.contains(cond),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        s.toggleCondition(cond);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Each condition raises your overall risk, which lowers your alert '
                'thresholds so warnings arrive sooner. This is a demo, not medical advice.',
                style: TextStyle(fontSize: 11.5, height: 1.4, color: c.faint),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Effective thresholds
        SectionCard(
          eyebrow: 'Resulting sensitivity',
          title: 'Your alert thresholds',
          trailing: Pill(m.riskLevel, fg: riskColor, bg: c.panel),
          child: Column(
            children: [
              _ThreshRow(label: 'Advisory (L1)', psi: eff.l1, color: c.advisory),
              const SizedBox(height: 8),
              _ThreshRow(label: 'Warning (L2)', psi: eff.l2, color: c.warning),
              const SizedBox(height: 8),
              _ThreshRow(label: 'Critical (L3)', psi: eff.l3, color: c.critical),
              const SizedBox(height: 10),
              Text(
                'Lower numbers = alerts sooner. A typical adult sits at 2.0 / 4.0 / 7.0 PSI.',
                style: TextStyle(fontSize: 11.5, color: c.faint),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              value: (score / 14).clamp(0.05, 1.0),
              strokeWidth: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          MonoText('$score',
              size: 20, weight: FontWeight.w800, color: Colors.white),
        ],
      ),
    );
  }
}

/// Slider that displays live while dragging but only commits (triggering a
/// recompute) when released — keeps dragging smooth.
class _SliderRow extends StatefulWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.sliderValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String unit;
  final double sliderValue;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  State<_SliderRow> createState() => _SliderRowState();
}

class _SliderRowState extends State<_SliderRow> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final current = (_dragging ?? widget.sliderValue).clamp(widget.min, widget.max);
    final display = _dragging != null ? _dragging!.round().toString() : widget.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.label, style: TextStyle(fontSize: 12.5, color: c.muted)),
            const Spacer(),
            MonoText(display, size: 15, weight: FontWeight.w700, color: c.ink),
            const SizedBox(width: 3),
            Text(widget.unit, style: TextStyle(fontSize: 11.5, color: c.faint)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: c.accent,
            inactiveTrackColor: c.line,
            thumbColor: c.accent,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: current,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            onChanged: (v) => setState(() => _dragging = v),
            onChangeEnd: (v) {
              setState(() => _dragging = null);
              widget.onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.accent : c.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? c.accent : c.line),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? c.onAccent : c.muted)),
      ),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  const _ConditionChip(
      {required this.condition, required this.selected, required this.onTap});
  final MedicalCondition condition;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? c.accentSoft : c.paper,
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

class _ThreshRow extends StatelessWidget {
  const _ThreshRow(
      {required this.label, required this.psi, required this.color});
  final String label;
  final double psi;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label, style: TextStyle(fontSize: 13, color: c.ink))),
        MonoText('${psi.toStringAsFixed(1)} PSI',
            size: 13.5, weight: FontWeight.w700, color: color),
      ],
    );
  }
}
