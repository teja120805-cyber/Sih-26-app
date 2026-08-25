import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/day_data.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Heat-acclimatization trend — a 14-day trend of heat-driven heart-rate excess
/// (how far above what exertion alone predicts the heart rate runs during heat
/// exposure). A real occupational-medicine adaptation signal no mainstream
/// consumer wearable surfaces. Today is real; the other 13 are illustrative.
class AcclimatizationCard extends StatelessWidget {
  const AcclimatizationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final hist = day.acclimHistory;

    final first = hist.first.score;
    final last = hist.last.score;
    final delta = first - last;

    String verdict;
    Color vColor;
    if (delta > 1) {
      verdict =
          'Your body is adapting — heat-driven heart-rate excess is down ${delta.toStringAsFixed(1)} bpm versus 13 days ago.';
      vColor = c.ok;
    } else if (delta < -1) {
      verdict =
          'Heat-driven heart-rate excess is up ${delta.abs().toStringAsFixed(1)} bpm versus 13 days ago — less adapted, or a hotter stretch.';
      vColor = c.warning;
    } else {
      verdict = 'Roughly steady heat response over the last two weeks.';
      vColor = c.muted;
    }

    return SectionCard(
      eyebrow: 'Heat acclimatization',
      title: 'Are you adapting to the heat?',
      trailing: MonoText('${last >= 0 ? '+' : ''}${last.toStringAsFixed(1)} bpm',
          size: 14, weight: FontWeight.w700, color: vColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2.4,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => CustomPaint(
                size: Size.infinite,
                painter: _AcclimPainter(hist: hist, colors: c, reveal: t),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('13 days ago',
                  style: TextStyle(fontSize: 11, color: c.faint)),
              const Spacer(),
              Text('Today', style: TextStyle(fontSize: 11, color: c.faint)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.accentSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.thermostat_outlined, size: 16, color: vColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(verdict,
                      style: TextStyle(fontSize: 12.5, height: 1.35, color: c.ink)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lower is better (less extra cardiac strain in heat). Today\'s point '
            'is real; the earlier 13 are illustrative, seeded to trend downward.',
            style: TextStyle(fontSize: 11.5, height: 1.4, color: c.faint),
          ),
        ],
      ),
    );
  }
}

class _AcclimPainter extends CustomPainter {
  _AcclimPainter({required this.hist, required this.colors, required this.reveal});
  final List<AcclimDay> hist;
  final AppColors colors;
  final double reveal;

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 26.0, padR = 8, padT = 8, padB = 8;
    final plotW = size.width - padL - padR;
    final plotH = size.height - padT - padB;
    final vmax = math.max(
        2.0, hist.map((p) => p.score.abs()).fold<double>(0, math.max) * 1.15);

    double xAt(int idx) => padL + idx / (hist.length - 1) * plotW;
    double yAt(double v) => padT + plotH - ((v + vmax) / (2 * vmax)) * plotH;

    // Zero line.
    final zeroY = yAt(0);
    canvas.drawLine(Offset(padL, zeroY), Offset(padL + plotW, zeroY),
        Paint()..color = colors.line..strokeWidth = 1);
    final tp = TextPainter(
      text: TextSpan(
          text: '0',
          style: TextStyle(
              color: colors.faint,
              fontSize: 9.5,
              fontFamily: kMonoFamily,
              fontFamilyFallback: kMonoFallback)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(2, zeroY - tp.height / 2));

    // How many points to reveal.
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
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < shown; i++) {
      final o = Offset(xAt(i), yAt(hist[i].score));
      final illus = hist[i].illustrative;
      canvas.drawCircle(o, illus ? 2.4 : 4.4,
          Paint()..color = illus ? colors.lineStrong : colors.accent);
      if (!illus) {
        canvas.drawCircle(
            o,
            4.4,
            Paint()
              ..color = colors.panel
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AcclimPainter old) =>
      old.hist != hist || old.reveal != reveal || old.colors != colors;
}
