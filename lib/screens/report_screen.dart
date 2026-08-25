import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../models/day_data.dart';
import '../models/medical_profile.dart';
import '../report/report_pdf.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate report: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final i = s.cursor;
    final m = s.medical;
    final act = computeActivity(i, day);
    final fired = day.events.where((e) => e.startMin <= s.cursorMinute).length;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 10, 2, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Doctor report',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: c.ink)),
                  const SizedBox(height: 2),
                  Text('A one-page summary you can hand to a clinician',
                      style: TextStyle(fontSize: 13.5, color: c.muted)),
                ],
              ),
            ),

            // Document preview
            Container(
              decoration: BoxDecoration(
                color: c.panel,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.line),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 12)),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PERSONAL HEALTH COMPANION',
                                style: TextStyle(
                                    fontSize: 9,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w700,
                                    color: c.accent)),
                            const SizedBox(height: 3),
                            Text('Health Summary',
                                style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: c.ink)),
                          ],
                        ),
                      ),
                      Pill(
                        'Risk: ${m.riskLevel}',
                        fg: c.onAccent,
                        bg: c.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: c.line, height: 1),
                  _ReportSection(title: 'Patient', rows: [
                    ('Age / Sex', '${m.age} yrs · ${m.gender.label}'),
                    ('BMI', '${m.bmi.toStringAsFixed(1)} (${bmiCategory(m.bmi)})'),
                    (
                      'Conditions',
                      m.conditions.isEmpty
                          ? 'None reported'
                          : m.conditions.map((x) => x.label).join(', ')
                    ),
                  ]),
                  _ReportSection(title: 'Vitals · ${s.cursorClock}', rows: [
                    ('Heart rate',
                        '${day.hr[i].toStringAsFixed(0)} bpm (${day.stats.minHR.toStringAsFixed(0)}–${day.stats.maxHR.toStringAsFixed(0)})'),
                    ('SpO₂', '${day.spo2[i].toStringAsFixed(0)} %'),
                    ('Core temp', '${day.coreTemp[i].toStringAsFixed(2)} °C'),
                  ]),
                  _ReportSection(title: 'Heat strain', rows: [
                    ('Current PSI',
                        '${day.psi[i].toStringAsFixed(1)} (tier ${day.tier[i]})'),
                    ('Peak today',
                        day.psi.reduce((a, x) => x > a ? x : a).toStringAsFixed(1)),
                    ('Heat-stress', '${day.stats.heatStressMinutes} min'),
                  ]),
                  _ReportSection(title: 'Sleep', rows: [
                    ('Score', '${day.stats.sleepQuality}/100'),
                    ('HRV / resp',
                        '${day.stats.avgHRVsleep.toStringAsFixed(0)} ms · ${day.stats.avgRespSleep.toStringAsFixed(1)}/min'),
                  ]),
                  _ReportSection(title: 'Exposure & activity', rows: [
                    ('Steps / kcal',
                        '${act.stepsSoFar} · ${act.activeCalories} kcal'),
                    ('PM2.5 dose',
                        '${(day.pm25DoseCum[i] / (15 * 24) * 100).round()}% WHO'),
                    ('Noise dose', '${day.noiseDoseCum[i].round()}% OSHA'),
                  ]),
                  _ReportSection(title: 'Model readings', rows: [
                    ('Vitals risk', '${(day.vitalsRisk[i] * 100).round()}%'),
                    ('Cardio ref', '${(day.popRisk[i] * 100).round()}%'),
                    ('Anomaly', '${day.anomaly[i].toStringAsFixed(1)}/10'),
                  ]),
                  _ReportSection(title: 'Alerts today', rows: [
                    ('Total so far', '$fired'),
                  ]),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.warningSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                          left: BorderSide(color: c.warning, width: 3)),
                    ),
                    child: Text(
                      'Not a medical device — a demo of the method on simulated data, '
                      'not a diagnosis.',
                      style: TextStyle(
                          fontSize: 11, height: 1.35, color: c.muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        await Printing.layoutPdf(
                            onLayout: (_) => buildReportPdf(s));
                      }),
              icon: const Icon(Icons.print_outlined, size: 18),
              label: const Text('Print / preview'),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.accent,
                side: BorderSide(color: c.lineStrong),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      await Clipboard.setData(
                          ClipboardData(text: buildReportText(s)));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Summary copied to clipboard')),
                        );
                      }
                    },
              icon: const Icon(Icons.copy_all_outlined, size: 17),
              label: const Text('Copy as text'),
              style: TextButton.styleFrom(foregroundColor: c.muted),
            ),
          ],
        ),

        // Pinned primary action
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: _GenerateButton(
            busy: _busy,
            onTap: () => _run(() async {
              final bytes = await buildReportPdf(s);
              await Printing.sharePdf(
                bytes: bytes,
                filename:
                    'health-summary-${DateTime.now().millisecondsSinceEpoch}.pdf',
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.busy, required this.onTap});
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: c.heroGradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: c.accent.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 8)),
          ],
        ),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white))
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.picture_as_pdf_outlined,
                      color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Generate & share PDF',
                      style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({required this.title, required this.rows});
  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: c.accent)),
        ),
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    width: 120,
                    child: Text(r.$1,
                        style: TextStyle(fontSize: 12.5, color: c.muted))),
                Expanded(
                    child: Text(r.$2,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: c.ink))),
              ],
            ),
          ),
      ],
    );
  }
}
