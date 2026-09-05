import 'package:flutter/material.dart';

import '../../models/health_status.dart';
import '../../models/medical_profile.dart';
import '../../state/console_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/acclimatization_card.dart';
import '../../widgets/common.dart';
import '../../widgets/readiness_card.dart';
import '../../widgets/sleep_card.dart';
import '../main_scaffold.dart';
import '../report_screen.dart';

/// Far-left page — Patient health: who the patient is and how their body is
/// holding up (recovery, sleep, adaptation).
class PatientHealthPage extends StatelessWidget {
  const PatientHealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final m = s.medical;
    final stress = bodyStress(day.anomaly[s.cursor]);
    final stressCol = stress.label == 'High'
        ? c.critical
        : stress.label == 'Noticeable'
            ? c.warning
            : c.ok;
    final riskCol = switch (m.riskLevel) {
      'High' => c.critical,
      'Elevated' => c.warning,
      'Moderate' => c.advisory,
      _ => c.ok,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        const PageHeader(title: 'Patient health', subtitle: 'Who you are & how you\'re holding up'),

        // Patient card
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: c.heroGradient),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name.trim().isEmpty ? 'You' : m.name.trim(),
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 3),
                    Text('${m.age} yrs · ${m.gender.label} · BMI ${m.bmi.toStringAsFixed(1)}',
                        style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.9))),
                  ],
                ),
              ),
              Column(
                children: [
                  Text('RISK', style: TextStyle(fontSize: 9, letterSpacing: 1, color: Colors.white.withValues(alpha: 0.85))),
                  Text(m.riskLevel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Conditions
        SectionCard(
          eyebrow: 'Reported conditions',
          title: m.conditions.isEmpty ? 'None reported' : '${m.conditions.length} on record',
          child: m.conditions.isEmpty
              ? Text('No medical conditions selected. Add them on the conditions screen to tighten your alerts.',
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: c.muted))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final cond in m.conditions)
                      Pill(cond.label, fg: riskCol, bg: c.tierSoft(2)),
                  ],
                ),
        ),
        const SizedBox(height: 12),

        // Body stress (qualitative anomaly)
        SectionCard(
          eyebrow: 'How your body is coping',
          title: 'Body stress: ${stress.label}',
          trailing: StatusPill(stress.label, color: stressCol),
          child: Text(stress.meaning, style: TextStyle(fontSize: 13, height: 1.45, color: c.ink)),
        ),
        const SizedBox(height: 12),

        const SleepCard(),
        const SizedBox(height: 12),
        const ReadinessCard(),
        const SizedBox(height: 12),
        const AcclimatizationCard(),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReportScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: c.panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.line),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.description_outlined, color: c.accent, size: 20),
              const SizedBox(width: 10),
              Text('Generate doctor report',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.accent)),
            ]),
          ),
        ),
      ],
    );
  }
}
