import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/medical_profile.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TextEditingController? _name;
  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _name?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final m = s.medical;
    _name ??= TextEditingController(text: m.name);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Text('Your profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: c.ink)),
        const SizedBox(height: 4),
        Text('This tunes how the app reads your body and when it warns you.',
            style: TextStyle(fontSize: 13.5, color: c.muted)),
        const SizedBox(height: 16),

        // Risk summary
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: c.heroGradient),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OVERALL RISK',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white.withValues(alpha: 0.85))),
                    const SizedBox(height: 4),
                    Text(m.riskLevel, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      m.hasCustomThresholds
                          ? 'Using your custom alert limits'
                          : m.earlierByPct > 0
                              ? 'Alerts fire ~${m.earlierByPct}% earlier than a typical adult'
                              : 'Standard alert sensitivity',
                      style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.92)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.shield_moon_outlined, color: Colors.white.withValues(alpha: 0.9), size: 40),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Demographics
        SectionCard(
          eyebrow: 'About you',
          title: 'Personal details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Full name', style: TextStyle(fontSize: 12, color: c.muted)),
              const SizedBox(height: 6),
              TextField(
                controller: _name,
                onChanged: s.setName,
                style: TextStyle(color: c.ink, fontSize: 15),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.badge_outlined, color: c.faint, size: 20),
                  filled: true,
                  fillColor: c.paper,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.line)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.line)),
                ),
              ),
              const SizedBox(height: 14),
              _slider('Age', '${m.age}', 'yrs', m.age.toDouble(), 12, 95, (v) => s.setAge(v.round())),
              const SizedBox(height: 6),
              Text('Sex', style: TextStyle(fontSize: 12, color: c.muted)),
              const SizedBox(height: 6),
              Row(children: [
                for (final g in Gender.values) ...[
                  Expanded(child: _choice(g.label, m.gender == g, () => s.setGender(g))),
                  if (g != Gender.values.last) const SizedBox(width: 8),
                ],
              ]),
              const SizedBox(height: 14),
              _slider('Height', '${m.heightCm.round()}', 'cm', m.heightCm, 130, 210, (v) => s.setHeight(v.roundToDouble())),
              const SizedBox(height: 10),
              _slider('Weight', '${m.weightKg.round()}', 'kg', m.weightKg, 35, 160, (v) => s.setWeight(v.roundToDouble())),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(color: c.paper, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Icon(Icons.straighten, size: 16, color: c.accent),
                      const SizedBox(width: 8),
                      Text('BMI', style: TextStyle(fontSize: 13, color: c.muted)),
                      const Spacer(),
                      MonoText(m.bmi.toStringAsFixed(1), size: 14, weight: FontWeight.w700, color: c.ink),
                      Text(' ${bmiCategory(m.bmi)}', style: TextStyle(fontSize: 12, color: c.faint)),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _bloodDropdown(context, m.bloodType, s)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Conditions
        SectionCard(
          eyebrow: 'Medical conditions',
          title: 'Select any that apply',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cond in MedicalCondition.values)
                _conditionChip(context, cond, m.conditions.contains(cond), () {
                  HapticFeedback.selectionClick();
                  s.toggleCondition(cond);
                }),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Threshold editors
        SectionCard(
          eyebrow: 'Alert limits',
          title: 'Set your warn & critical levels',
          trailing: m.hasCustomThresholds
              ? TextButton(
                  onPressed: s.resetThresholds,
                  style: TextButton.styleFrom(foregroundColor: c.accent, padding: EdgeInsets.zero),
                  child: const Text('Reset'))
              : null,
          child: Column(
            children: [
              Text(
                'Alerts trigger when a reading crosses these. Defaults come from your risk profile — drag to personalise.',
                style: TextStyle(fontSize: 12, height: 1.35, color: c.muted)),
              const SizedBox(height: 14),
              _ThreshEditor(
                label: 'Heart rate', unit: 'bpm', min: 80, max: 200,
                warn: m.effHrWarn, crit: m.effHrCrit,
                onWarn: (v) => s.setThreshold(hrWarn: v), onCrit: (v) => s.setThreshold(hrCrit: v),
              ),
              _ThreshEditor(
                label: 'Body temperature', unit: '°C', min: 37, max: 40, decimals: 1,
                warn: m.effTempWarn, crit: m.effTempCrit,
                onWarn: (v) => s.setThreshold(tempWarn: v), onCrit: (v) => s.setThreshold(tempCrit: v),
              ),
              _ThreshEditor(
                label: 'Blood oxygen (SpO₂)', unit: '%', min: 85, max: 99, lowerWorse: true,
                warn: m.effSpo2Warn, crit: m.effSpo2Crit,
                onWarn: (v) => s.setThreshold(spo2Warn: v), onCrit: (v) => s.setThreshold(spo2Crit: v),
              ),
              _ThreshEditor(
                label: 'Heat strain', unit: 'PSI', min: 1, max: 10, decimals: 1,
                warn: m.effStrainWarn, crit: m.effStrainCrit,
                onWarn: (v) => s.setThreshold(strainWarn: v), onCrit: (v) => s.setThreshold(strainCrit: v),
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _slider(String label, String value, String unit, double v, double min, double max, ValueChanged<double> onEnd) {
    final c = context.colors;
    return _CommitSlider(label: label, value: value, unit: unit, initial: v, min: min, max: max, onEnd: onEnd, accent: c.accent, line: c.line, ink: c.ink, muted: c.muted, faint: c.faint);
  }

  Widget _choice(String label, bool sel, VoidCallback onTap) {
    final c = context.colors;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel ? c.accent : c.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? c.accent : c.line),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sel ? c.onAccent : c.muted)),
      ),
    );
  }

  Widget _bloodDropdown(BuildContext context, String? value, ConsoleState s) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(color: c.paper, borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Row(children: [
            Icon(Icons.bloodtype_outlined, color: c.faint, size: 18),
            const SizedBox(width: 6),
            Text('Blood', style: TextStyle(color: c.faint, fontSize: 13)),
          ]),
          dropdownColor: c.panel,
          style: TextStyle(color: c.ink, fontSize: 14),
          icon: Icon(Icons.arrow_drop_down, color: c.faint),
          items: [for (final b in _bloodTypes) DropdownMenuItem(value: b, child: Text(b))],
          onChanged: (b) { if (b != null) s.setBloodType(b); },
        ),
      ),
    );
  }

  Widget _conditionChip(BuildContext context, MedicalCondition cond, bool sel, VoidCallback onTap) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? c.accentSoft : c.paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? c.accent : c.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(sel ? Icons.check_circle : Icons.add_circle_outline, size: 15, color: sel ? c.accent : c.faint),
          const SizedBox(width: 6),
          Text(cond.label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: sel ? c.accent : c.ink)),
        ]),
      ),
    );
  }
}

/// A slider whose value shows live while dragging but commits on release.
class _CommitSlider extends StatefulWidget {
  const _CommitSlider({
    required this.label, required this.value, required this.unit,
    required this.initial, required this.min, required this.max, required this.onEnd,
    required this.accent, required this.line, required this.ink, required this.muted, required this.faint,
  });
  final String label, value, unit;
  final double initial, min, max;
  final ValueChanged<double> onEnd;
  final Color accent, line, ink, muted, faint;

  @override
  State<_CommitSlider> createState() => _CommitSliderState();
}

class _CommitSliderState extends State<_CommitSlider> {
  double? _drag;
  @override
  Widget build(BuildContext context) {
    final cur = (_drag ?? widget.initial).clamp(widget.min, widget.max);
    final disp = _drag != null ? _drag!.round().toString() : widget.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(widget.label, style: TextStyle(fontSize: 12.5, color: widget.muted)),
          const Spacer(),
          MonoText(disp, size: 15, weight: FontWeight.w700, color: widget.ink),
          const SizedBox(width: 3),
          Text(widget.unit, style: TextStyle(fontSize: 11.5, color: widget.faint)),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4, activeTrackColor: widget.accent, inactiveTrackColor: widget.line,
            thumbColor: widget.accent, overlayShape: const RoundSliderOverlayShape(overlayRadius: 14)),
          child: Slider(
            value: cur, min: widget.min, max: widget.max,
            onChanged: (v) => setState(() => _drag = v),
            onChangeEnd: (v) { setState(() => _drag = null); widget.onEnd(v); },
          ),
        ),
      ],
    );
  }
}

/// Warn + Crit dual slider for one metric.
class _ThreshEditor extends StatelessWidget {
  const _ThreshEditor({
    required this.label, required this.unit, required this.min, required this.max,
    required this.warn, required this.crit, required this.onWarn, required this.onCrit,
    this.decimals = 0, this.lowerWorse = false, this.isLast = false,
  });
  final String label, unit;
  final double min, max, warn, crit;
  final ValueChanged<double> onWarn, onCrit;
  final int decimals;
  final bool lowerWorse, isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    String f(double v) => v.toStringAsFixed(decimals);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.ink)),
            const Spacer(),
            _tag(context, 'Warn ${f(warn)}$unit', c.warning),
            const SizedBox(width: 6),
            _tag(context, 'Crit ${f(crit)}$unit', c.critical),
          ]),
          _MiniSlider(value: warn, min: min, max: max, color: c.warning, onEnd: onWarn),
          _MiniSlider(value: crit, min: min, max: max, color: c.critical, onEnd: onCrit),
        ],
      ),
    );
  }

  Widget _tag(BuildContext context, String t, Color col) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: col.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: col)),
      );
}

class _MiniSlider extends StatefulWidget {
  const _MiniSlider({required this.value, required this.min, required this.max, required this.color, required this.onEnd});
  final double value, min, max;
  final Color color;
  final ValueChanged<double> onEnd;
  @override
  State<_MiniSlider> createState() => _MiniSliderState();
}

class _MiniSliderState extends State<_MiniSlider> {
  double? _drag;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        activeTrackColor: widget.color,
        inactiveTrackColor: c.line,
        thumbColor: widget.color,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
      ),
      child: Slider(
        value: (_drag ?? widget.value).clamp(widget.min, widget.max),
        min: widget.min,
        max: widget.max,
        onChanged: (v) => setState(() => _drag = v),
        onChangeEnd: (v) { setState(() => _drag = null); widget.onEnd(v); },
      ),
    );
  }
}
