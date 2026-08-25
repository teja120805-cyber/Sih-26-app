import 'package:flutter/material.dart';

import '../models/day_data.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// "How this was calculated" — collapsed by default. Opens into the raw sensor
/// readings behind the current moment and the exact formulas with today's real
/// numbers substituted in, so nothing is a black box.
class TransparencyCard extends StatefulWidget {
  const TransparencyCard({super.key});

  @override
  State<TransparencyCard> createState() => _TransparencyCardState();
}

class _TransparencyCardState extends State<TransparencyCard> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final i = s.cursor;
    final prof = day.prof;

    final tc0 = prof.tc0;
    final hr0 = prof.hr0;
    final tc = day.coreTemp[i];
    final hr = day.hr[i];
    final termT = 5 * (tc - tc0) / (39.5 - tc0);
    final termH = 5 * (hr - hr0) / (180 - hr0);

    return SectionCard(
      eyebrow: 'Full transparency',
      title: 'How this was calculated',
      trailing: IconButton(
        onPressed: () => setState(() => open = !open),
        icon: Icon(open ? Icons.expand_less : Icons.expand_more, color: c.muted),
      ),
      child: open
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sub(c, 'Raw sensor readings at ${s.cursorClock}'),
                _KvGrid(entries: [
                  ('Heart rate', '${hr.toStringAsFixed(1)} bpm'),
                  ('SpO₂', '${day.spo2[i].toStringAsFixed(1)} %'),
                  ('Skin temp', '${day.skin[i].toStringAsFixed(2)} °C'),
                  ('Ambient temp', '${day.ambientTemp[i].toStringAsFixed(1)} °C'),
                  ('Humidity', '${day.humidity[i].toStringAsFixed(0)} %'),
                  ('Personal WBGT', '${day.wbgt[i].toStringAsFixed(1)} °C'),
                  ('PM2.5', '${day.pm25[i].toStringAsFixed(0)} µg/m³'),
                  ('Resp rate', '${day.respRate[i].toStringAsFixed(1)} /min'),
                  ('HRV', '${day.hrv[i].toStringAsFixed(0)} ms'),
                  ('Noise', '${day.noise[i].toStringAsFixed(0)} dB'),
                  ('Activity index', day.exertion[i].toStringAsFixed(3)),
                ]),
                const SizedBox(height: 16),
                _sub(c, 'Personal baseline (this profile)'),
                _Formula(
                  'Resting HR₀ = ${hr0.toStringAsFixed(0)} bpm · '
                  'Skin₀ = ${prof.skin0.toStringAsFixed(1)}°C · '
                  'Core₀ = ${tc0.toStringAsFixed(1)}°C\n'
                  'Alert tiers: L1 ${prof.l1} · L2 ${prof.l2} · L3 ${prof.l3} '
                  '(PSI). Higher-risk profiles trigger earlier.',
                ),
                const SizedBox(height: 16),
                _sub(c, 'Physiological Strain Index'),
                _Formula(
                  'PSI = 5×(Tc − Tc₀)/(39.5 − Tc₀) + 5×(HR − HR₀)/(180 − HR₀)\n'
                  '    = 5×(${tc.toStringAsFixed(2)} − ${tc0.toStringAsFixed(2)})/(39.5 − ${tc0.toStringAsFixed(2)})'
                  ' + 5×(${hr.toStringAsFixed(0)} − ${hr0.toStringAsFixed(0)})/(180 − ${hr0.toStringAsFixed(0)})\n'
                  '    = ${termT.toStringAsFixed(2)} + ${termH.toStringAsFixed(2)} '
                  '= ${day.psi[i].toStringAsFixed(2)}',
                ),
                const SizedBox(height: 16),
                _sub(c, 'Core temperature (literature-grounded filter)'),
                _Formula(
                  'A recursive skin-to-core estimate (Buller et al. 2013 family): '
                  'relaxes toward Tc₀ + ke·exertion, then blends in '
                  'skin + skin-to-core gradient (≈2.5–4°C, narrowing as ambient '
                  'rises, widening with exertion). Every constant is '
                  'literature-grounded, not fitted.\n'
                  'Estimate now = ${tc.toStringAsFixed(2)}°C',
                ),
                const SizedBox(height: 16),
                _sub(c, 'The trained models (held-out scores)'),
                _Formula(
                  'Isolation Forest anomaly (80 trees, 200,020 records): '
                  '${day.anomaly[i].toStringAsFixed(1)}/10\n'
                  'Vitals-risk classifier (Random Forest, AUC 0.712): '
                  '${(day.vitalsRisk[i] * 100).toStringAsFixed(0)}% high-risk\n'
                  'Population cardio reference (Random Forest, AUC 0.671): '
                  '${(day.popRisk[i] * 100).toStringAsFixed(0)}% '
                  '(a population reference, not a personal diagnosis)\n'
                  'Sleep-quality model (Random Forest, R² 0.963): '
                  '${day.stats.sleepQuality}/100',
                ),
                const SizedBox(height: 16),
                _sub(c, 'Activity, calories & hydration'),
                _Formula(
                  'Active calories ≈ steps × 0.045 + exercise minutes × 0.35\n'
                  'Hydration target = clamp(6 + heat-min/45 + exercise-min/40, 6, 14)',
                ),
                const SizedBox(height: 6),
                Text(
                  'Every number above is computed on-device from data embedded in '
                  'the app — nothing is fetched pre-computed, and no health data '
                  'leaves the device.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: c.faint),
                ),
              ],
            )
          : Text(
              'Opens into every raw reading and formula for the exact moment '
              'you\'re looking at — nothing is a black box. Tap to expand.',
              style: TextStyle(fontSize: 13, height: 1.4, color: c.muted),
            ),
    );
  }

  Widget _sub(AppColors c, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Eyebrow(t, color: c.accent),
      );
}

class _KvGrid extends StatelessWidget {
  const _KvGrid({required this.entries});
  final List<(String, String)> entries;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 360 ? 2 : 1;
      final rowH = 30.0;
      final rows = (entries.length / cols).ceil();
      return SizedBox(
        height: rows * rowH,
        child: GridView.count(
          crossAxisCount: cols,
          childAspectRatio: (constraints.maxWidth / cols) / rowH,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final e in entries)
              Row(
                children: [
                  Expanded(
                    child: Text(e.$1,
                        style: TextStyle(fontSize: 12.5, color: c.muted)),
                  ),
                  MonoText(e.$2, size: 12.5, color: c.ink),
                ],
              ),
          ],
        ),
      );
    });
  }
}

class _Formula extends StatelessWidget {
  const _Formula(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: c.paper,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.line),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: kMonoFamily,
          fontFamilyFallback: kMonoFallback,
          fontFeatures: kTabularFigures,
          fontSize: 11.5,
          height: 1.5,
          color: c.ink,
        ),
      ),
    );
  }
}
