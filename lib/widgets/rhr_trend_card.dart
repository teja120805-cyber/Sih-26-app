import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/day_data.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// 14-day resting-HR trend against the personal baseline. A rising trend
/// without extra activity is an early illness / overtraining signal.
class RhrTrendCard extends StatelessWidget {
  const RhrTrendCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final hist = day.rhrHistory;
    final baseline = day.prof.hr0;
    final today = day.stats.rhrToday;
    final delta = today - baseline;

    return SectionCard(
      eyebrow: 'Early-warning signal',
      title: 'Resting heart rate trend',
      trailing: MonoText('${today.toStringAsFixed(0)} bpm',
          size: 14, weight: FontWeight.w700, color: c.accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2.6,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => CustomPaint(
                size: Size.infinite,
                painter: _RhrPainter(hist: hist, baseline: baseline, colors: c, reveal: t),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: c.accentSoft, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(delta > 3 ? Icons.trending_up : Icons.trending_flat,
                    size: 16, color: delta > 3 ? c.warning : c.ok),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    delta > 3
                        ? 'Resting HR is ${delta.toStringAsFixed(0)} bpm above your baseline — watch for illness or overtraining.'
                        : 'Resting HR is close to your ${baseline.toStringAsFixed(0)} bpm baseline — nothing unusual.',
                    style: TextStyle(fontSize: 12.5, height: 1.35, color: c.ink),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RhrPainter extends CustomPainter {
  _RhrPainter({required this.hist, required this.baseline, required this.colors, required this.reveal});
  final List<AcclimDay> hist;
  final double baseline;
  final AppColors colors;
  final double reveal;

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 26.0, padR = 8, padT = 8, padB = 8;
    final plotW = size.width - padL - padR;
    final plotH = size.height - padT - padB;
    final all = [...hist.map((e) => e.score), baseline];
    var lo = all.reduce(math.min) - 3, hi = all.reduce(math.max) + 3;
    if ((hi - lo).abs() < 1e-6) hi = lo + 1;

    double xAt(int i) => padL + i / (hist.length - 1) * plotW;
    double yAt(double v) => padT + plotH - ((v - lo) / (hi - lo)) * plotH;

    // baseline dashed line
    final by = yAt(baseline);
    const d = 5.0, g = 4.0;
    var x = padL;
    final bp = Paint()..color = colors.faint..strokeWidth = 1;
    while (x < padL + plotW) {
      canvas.drawLine(Offset(x, by), Offset(math.min(x + d, padL + plotW), by), bp);
      x += d + g;
    }
    final tp = TextPainter(
      text: TextSpan(
          text: baseline.toStringAsFixed(0),
          style: TextStyle(
              color: colors.faint,
              fontSize: 9,
              fontFamily: kMonoFamily,
              fontFamilyFallback: kMonoFallback)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(1, by - tp.height / 2));

    final shown = (hist.length * reveal).ceil().clamp(1, hist.length);
    final path = Path();
    for (var i = 0; i < shown; i++) {
      final o = Offset(xAt(i), yAt(hist[i].score));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = colors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round);
    for (var i = 0; i < shown; i++) {
      final o = Offset(xAt(i), yAt(hist[i].score));
      final illus = hist[i].illustrative;
      canvas.drawCircle(o, illus ? 2.4 : 4.4,
          Paint()..color = illus ? colors.lineStrong : colors.accent);
      if (!illus) {
        canvas.drawCircle(o, 4.4,
            Paint()..color = colors.panel..style = PaintingStyle.stroke..strokeWidth = 1.6);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RhrPainter old) =>
      old.hist != hist || old.reveal != reveal || old.colors != colors;
}
