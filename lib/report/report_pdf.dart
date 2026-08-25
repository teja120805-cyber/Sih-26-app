import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/day_data.dart';
import '../models/medical_profile.dart';
import '../models/profile.dart';
import '../state/console_state.dart';

/// Collects everything the doctor report shows, from the live state.
class ReportData {
  ReportData(ConsoleState s)
      : day = s.day!,
        medical = s.medical,
        cursor = s.cursor,
        scenario = s.scenario,
        generatedAt = DateTime.now() {
    activity = computeActivity(cursor, day);
    recovery = computeRecovery(day, day.prof);
  }

  final DayData day;
  final MedicalProfile medical;
  final int cursor;
  final String scenario;
  final DateTime generatedAt;
  late final ActivitySnapshot activity;
  late final RecoveryInfo recovery;

  int tierMinutes(int t) => day.tier.where((v) => v >= t).length * kStepMin;
}

String _fmtDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${months[d.month - 1]} ${d.year}, $hh:$mm';
}

/// A plain-text version of the report (for clipboard copy).
String buildReportText(ConsoleState s) {
  final r = ReportData(s);
  final d = r.day;
  final i = r.cursor;
  final m = r.medical;
  final conds =
      m.conditions.isEmpty ? 'None reported' : m.conditions.map((c) => c.label).join(', ');
  final b = StringBuffer();
  b.writeln('PERSONAL HEALTH COMPANION — HEALTH SUMMARY');
  b.writeln('Generated ${_fmtDate(r.generatedAt)}');
  b.writeln('(Demo of the approach — not a clinical diagnosis)');
  b.writeln('');
  b.writeln('PATIENT');
  b.writeln('  Age ${m.age} · ${m.gender.label} · BMI ${m.bmi.toStringAsFixed(1)} (${bmiCategory(m.bmi)})');
  b.writeln('  Conditions: $conds');
  b.writeln('  Overall risk level: ${m.riskLevel}');
  b.writeln('');
  b.writeln('VITALS (at ${d.hr.isEmpty ? '' : fmtClock(i * kStepMin)})');
  b.writeln('  Heart rate: ${d.hr[i].toStringAsFixed(0)} bpm  (day ${d.stats.minHR.toStringAsFixed(0)}-${d.stats.maxHR.toStringAsFixed(0)}, avg ${d.stats.avgHR.toStringAsFixed(0)})');
  b.writeln('  SpO2: ${d.spo2[i].toStringAsFixed(0)} %');
  b.writeln('  Est. core temp: ${d.coreTemp[i].toStringAsFixed(2)} degC');
  b.writeln('');
  b.writeln('HEAT STRAIN');
  b.writeln('  Current PSI: ${d.psi[i].toStringAsFixed(1)} (tier ${d.tier[i]})');
  b.writeln('  Peak PSI today: ${d.psi.reduce((a, x) => x > a ? x : a).toStringAsFixed(1)}');
  b.writeln('  Heat-stress minutes: ${d.stats.heatStressMinutes}');
  b.writeln('');
  b.writeln('SLEEP');
  b.writeln('  Score: ${d.stats.sleepQuality}/100 · deep ${d.stats.deepMinutes}m / REM ${d.stats.remMinutes}m / light ${d.stats.lightMinutes}m');
  b.writeln('  Overnight HRV ${d.stats.avgHRVsleep.toStringAsFixed(0)} ms · resp ${d.stats.avgRespSleep.toStringAsFixed(1)}/min');
  b.writeln('');
  b.writeln('ACTIVITY & EXPOSURE');
  b.writeln('  Steps ${r.activity.stepsSoFar} · active ${r.activity.activeCalories} kcal');
  b.writeln('  PM2.5 dose ${(d.pm25DoseCum[i] / (15 * 24) * 100).round()}% of WHO daily · Noise dose ${d.noiseDoseCum[i].round()}% of OSHA daily');
  b.writeln('');
  b.writeln('MODEL READINGS');
  b.writeln('  Vitals-risk classifier: ${(d.vitalsRisk[i] * 100).round()}%');
  b.writeln('  Population cardio reference: ${(d.popRisk[i] * 100).round()}%');
  b.writeln('  Anomaly score: ${d.anomaly[i].toStringAsFixed(1)}/10');
  final fired = d.events.where((e) => e.startMin <= i * kStepMin).toList();
  b.writeln('');
  b.writeln('ALERTS TODAY (${fired.length})');
  for (final e in fired.reversed.take(8)) {
    b.writeln('  [${['ADVISORY', 'ADVISORY', 'WARNING', 'CRITICAL'][e.severity.clamp(0, 3)]}] ${eventText(e)} (${fmtClock(e.startMin)}-${fmtClock(e.endMin)})');
  }
  return b.toString();
}

/// Builds the doctor-facing PDF document.
Future<Uint8List> buildReportPdf(ConsoleState s) async {
  final r = ReportData(s);
  final d = r.day;
  final i = r.cursor;
  final m = r.medical;
  final doc = pw.Document();

  final teal = PdfColor.fromInt(0xFF0D9488);
  final ink = PdfColor.fromInt(0xFF0F172A);
  final muted = PdfColor.fromInt(0xFF64748B);
  final line = PdfColor.fromInt(0xFFE2E8F0);
  final soft = PdfColor.fromInt(0xFFF1F5F9);

  pw.Widget sectionTitle(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
        child: pw.Text(t,
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: teal,
                letterSpacing: 0.5)),
      );

  pw.Widget kv(String k, String v, {PdfColor? vColor}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
                width: 150,
                child: pw.Text(k,
                    style: pw.TextStyle(fontSize: 10, color: muted))),
            pw.Expanded(
                child: pw.Text(v,
                    style: pw.TextStyle(
                        fontSize: 10,
                        color: vColor ?? ink,
                        fontWeight: pw.FontWeight.bold))),
          ],
        ),
      );

  pw.Widget card(List<pw.Widget> children) => pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(bottom: 4),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: soft,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: line),
        ),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start, children: children),
      );

  final conds = m.conditions.isEmpty
      ? 'None reported'
      : m.conditions.map((c) => c.label).join(', ');
  final peakPsi = d.psi.reduce((a, x) => x > a ? x : a);
  final fired = d.events.where((e) => e.startMin <= i * kStepMin).toList();
  final sevNames = ['Advisory', 'Advisory', 'Warning', 'Critical'];
  final sevColors = [
    PdfColor.fromInt(0xFFD97706),
    PdfColor.fromInt(0xFFD97706),
    PdfColor.fromInt(0xFFEA580C),
    PdfColor.fromInt(0xFFDC2626),
  ];

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 36),
      build: (context) => [
        // Header
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Personal Health Companion',
                      style: pw.TextStyle(fontSize: 9, color: teal, letterSpacing: 1)),
                  pw.SizedBox(height: 2),
                  pw.Text('Health Summary',
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: ink)),
                  pw.SizedBox(height: 3),
                  pw.Text('Generated ${_fmtDate(r.generatedAt)}',
                      style: pw.TextStyle(fontSize: 9.5, color: muted)),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                  color: teal, borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Text('RISK: ${m.riskLevel.toUpperCase()}',
                  style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: line),

        sectionTitle('PATIENT'),
        card([
          kv('Age / Sex', '${m.age} years · ${m.gender.label}'),
          kv('BMI', '${m.bmi.toStringAsFixed(1)} (${bmiCategory(m.bmi)})'),
          kv('Reported conditions', conds),
          kv('Overall risk level', m.riskLevel),
          kv('Alert sensitivity',
              m.earlierByPct > 0 ? '~${m.earlierByPct}% earlier than typical adult' : 'Standard'),
        ]),

        sectionTitle('VITALS  ·  at ${fmtClock(i * kStepMin)}'),
        card([
          kv('Heart rate',
              '${d.hr[i].toStringAsFixed(0)} bpm   (day range ${d.stats.minHR.toStringAsFixed(0)}-${d.stats.maxHR.toStringAsFixed(0)}, avg ${d.stats.avgHR.toStringAsFixed(0)})'),
          kv('SpO2 (oxygen saturation)', '${d.spo2[i].toStringAsFixed(0)} %'),
          kv('Estimated core temperature', '${d.coreTemp[i].toStringAsFixed(2)} degC'),
        ]),

        sectionTitle('HEAT STRAIN'),
        card([
          kv('Physiological Strain Index',
              '${d.psi[i].toStringAsFixed(1)} / 10  (tier ${d.tier[i]})',
              vColor: sevColors[d.tier[i].clamp(0, 3)]),
          kv('Peak PSI today', peakPsi.toStringAsFixed(1)),
          kv('Heat-stress minutes', '${d.stats.heatStressMinutes} min'),
          kv('Time at/over warning', '${r.tierMinutes(2)} min'),
        ]),

        sectionTitle('SLEEP  &  RECOVERY'),
        card([
          kv('Sleep score', '${d.stats.sleepQuality} / 100'),
          kv('Stages',
              'Deep ${d.stats.deepMinutes}m · REM ${d.stats.remMinutes}m · Light ${d.stats.lightMinutes}m'),
          kv('Overnight HRV', '${d.stats.avgHRVsleep.toStringAsFixed(0)} ms'),
          kv('Overnight respiration', '${d.stats.avgRespSleep.toStringAsFixed(1)} /min'),
          kv('Recovery note', r.recovery.text),
        ]),

        sectionTitle('ACTIVITY  &  ENVIRONMENTAL EXPOSURE'),
        card([
          kv('Steps so far', '${r.activity.stepsSoFar}'),
          kv('Active calories', '${r.activity.activeCalories} kcal'),
          kv('PM2.5 dose',
              '${(d.pm25DoseCum[i] / (15 * 24) * 100).round()}% of WHO 24h guideline'),
          kv('Noise dose',
              '${d.noiseDoseCum[i].round()}% of OSHA daily allowance'),
        ]),

        sectionTitle('MODEL READINGS  (trained on public datasets)'),
        card([
          kv('Vitals-risk classifier', '${(d.vitalsRisk[i] * 100).round()}% (Random Forest, held-out AUC 0.71)'),
          kv('Population cardio reference', '${(d.popRisk[i] * 100).round()}% (population reference, not a diagnosis)'),
          kv('Anomaly score', '${d.anomaly[i].toStringAsFixed(1)} / 10 (Isolation Forest)'),
        ]),

        sectionTitle('ALERTS TODAY  (${fired.length})'),
        if (fired.isEmpty)
          pw.Text('No alerts recorded so far today.',
              style: pw.TextStyle(fontSize: 10, color: muted))
        else
          card([
            for (final e in fired.reversed.take(12))
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(children: [
                  pw.Container(
                    width: 58,
                    child: pw.Text(sevNames[e.severity.clamp(0, 3)].toUpperCase(),
                        style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: sevColors[e.severity.clamp(0, 3)])),
                  ),
                  pw.Expanded(
                      child: pw.Text(eventText(e),
                          style: pw.TextStyle(fontSize: 9.5, color: ink))),
                  pw.Text('${fmtClock(e.startMin)}-${fmtClock(e.endMin)}',
                      style: pw.TextStyle(fontSize: 9, color: muted)),
                ]),
              ),
          ]),

        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border(left: pw.BorderSide(color: sevColors[2], width: 3)),
            color: PdfColor.fromInt(0xFFFFF7ED),
          ),
          child: pw.Text(
            'Not a medical device. This summary demonstrates an on-device monitoring '
            'approach on simulated sensor data; it has not been clinically validated and '
            'none of the training data came from this exact hardware. Every number is a '
            'demonstration of the method, not a diagnosis.',
            style: pw.TextStyle(fontSize: 8.5, color: muted),
          ),
        ),
      ],
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Personal Health Companion · SIH26181',
              style: pw.TextStyle(fontSize: 8, color: muted)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: muted)),
        ],
      ),
    ),
  );

  return doc.save();
}
