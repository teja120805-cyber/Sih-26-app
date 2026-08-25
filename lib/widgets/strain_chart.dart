import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/day_data.dart';
import '../models/profile.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// "Your strain today" — Physiological Strain Index and estimated core
/// temperature across the whole day, with the wearer's personal advisory /
/// warning / critical lines and shaded bands where an alert fired.
class StrainChart extends StatelessWidget {
  const StrainChart({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final i = s.cursor;
    final psi = day.psi[i];
    final core = day.coreTemp[i];
    final tier = day.tier[i];

    return SectionCard(
      eyebrow: 'Your strain today',
      title: 'Physiological strain & core temperature',
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MonoText('PSI ${psi.toStringAsFixed(1)}',
              size: 15, weight: FontWeight.w700, color: c.tier(tier)),
          const SizedBox(height: 2),
          MonoText('${core.toStringAsFixed(2)}°C',
              size: 12.5, color: c.tempTrace),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.7,
            child: CustomPaint(
              painter: _StrainPainter(day: day, cursor: i, colors: c),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 10),
          _Legend(colors: c),
          const SizedBox(height: 10),
          _Projection(day: day, cursor: i),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    Widget dot(Color col, String label, {bool dashed = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 14, height: 3, color: col),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(fontSize: 11.5, color: colors.muted)),
          ],
        );
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        dot(colors.accent, 'Strain index'),
        dot(colors.tempTrace, 'Core temp'),
        dot(colors.advisory, 'Advisory'),
        dot(colors.warning, 'Warning'),
        dot(colors.critical, 'Critical'),
      ],
    );
  }
}

/// Least-squares slope of the last [n] PSI samples → minutes to next tier.
class _Projection extends StatelessWidget {
  const _Projection({required this.day, required this.cursor});
  final DayData day;
  final int cursor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final prof = day.prof;
    final tier = day.tier[cursor];
    // fit last 6 samples (30 min)
    final n = math.min(6, cursor + 1);
    final start = cursor + 1 - n;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    for (var k = 0; k < n; k++) {
      final x = k.toDouble();
      final y = day.psi[start + k];
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }
    final denom = n * sumXX - sumX * sumX;
    final slope = denom != 0 ? (n * sumXY - sumX * sumY) / denom : 0.0;
    final last = day.psi[cursor];

    String text;
    Color col = c.muted;
    if (tier >= 3) {
      text = 'Already at the critical tier — act now.';
      col = c.critical;
    } else {
      final nextThresh = tier == 0 ? prof.l1 : tier == 1 ? prof.l2 : prof.l3;
      if (slope <= 0.002) {
        text = 'Strain is flat or easing — no next-tier crossing projected.';
      } else {
        final samplesToGo = (nextThresh - last) / slope;
        final minutes = (samplesToGo * kStepMin).round();
        if (minutes <= 0 || minutes > 24 * 60) {
          text = 'No next-tier crossing projected soon.';
        } else {
          text =
              '≈ $minutes min to the next alert tier at the current trend (linear extrapolation, not a forecast).';
          col = c.tier(tier + 1);
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, size: 16, color: col),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12.5, height: 1.35, color: c.ink)),
          ),
        ],
      ),
    );
  }
}

class _StrainPainter extends CustomPainter {
  _StrainPainter({
    required this.day,
    required this.cursor,
    required this.colors,
  });

  final DayData day;
  final int cursor;
  final AppColors colors;

  static const double padL = 28, padR = 8, padT = 8, padB = 20;
  // Core-temp secondary axis range.
  static const double coreMin = 36.5, coreMax = 39.5;

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = size.width - padL - padR;
    final plotH = size.height - padT - padB;

    double xAt(int minute) => padL + (minute / 1440) * plotW;
    double yPsi(double v) => padT + plotH - (v / 10) * plotH;
    double yCore(double v) =>
        padT + plotH - ((v - coreMin) / (coreMax - coreMin)) * plotH;

    // Alert bands (heat strain events).
    for (final e in day.events.where((e) => e.type == 'Heat strain')) {
      final col = colors.tier(e.severity);
      final rect = Rect.fromLTRB(
          xAt(e.startMin), padT, xAt(e.endMin), padT + plotH);
      canvas.drawRect(
          rect, Paint()..color = col.withValues(alpha: 0.12));
    }

    // Gridlines + y labels (PSI).
    final gridPaint = Paint()
      ..color = colors.line
      ..strokeWidth = 1;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final v in [0, 2, 4, 6, 8, 10]) {
      final y = yPsi(v.toDouble());
      canvas.drawLine(Offset(padL, y), Offset(padL + plotW, y), gridPaint);
      tp.text = TextSpan(
        text: '$v',
        style: TextStyle(
          color: colors.faint,
          fontSize: 9.5,
          fontFamily: kMonoFamily,
          fontFamilyFallback: kMonoFallback,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(padL - tp.width - 4, y - tp.height / 2));
    }

    // x labels (hours).
    for (final hh in [0, 6, 12, 18, 24]) {
      final x = xAt(hh * 60);
      tp.text = TextSpan(
        text: '${hh < 10 ? '0' : ''}$hh:00',
        style: TextStyle(
          color: colors.faint,
          fontSize: 9.5,
          fontFamily: kMonoFamily,
          fontFamilyFallback: kMonoFallback,
        ),
      );
      tp.layout();
      canvas.drawLine(Offset(x, padT), Offset(x, padT + plotH),
          Paint()..color = colors.line.withValues(alpha: 0.5));
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - padB + 5));
    }

    // Personal threshold lines (dashed).
    void dashed(double y, Color col) {
      const dash = 5.0, gap = 4.0;
      var x = padL;
      final p = Paint()
        ..color = col.withValues(alpha: 0.7)
        ..strokeWidth = 1.2;
      while (x < padL + plotW) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + dash, padL + plotW), y), p);
        x += dash + gap;
      }
    }

    dashed(yPsi(day.prof.l1), colors.advisory);
    dashed(yPsi(day.prof.l2), colors.warning);
    dashed(yPsi(day.prof.l3), colors.critical);

    // Core-temp trace.
    final corePath = Path();
    for (var i = 0; i < day.coreTemp.length; i++) {
      final x = xAt(i * kStepMin);
      final y = yCore(day.coreTemp[i].clamp(coreMin, coreMax));
      i == 0 ? corePath.moveTo(x, y) : corePath.lineTo(x, y);
    }
    canvas.drawPath(
      corePath,
      Paint()
        ..color = colors.tempTrace
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );

    // PSI trace.
    final psiPath = Path();
    for (var i = 0; i < day.psi.length; i++) {
      final x = xAt(i * kStepMin);
      final y = yPsi(day.psi[i]);
      i == 0 ? psiPath.moveTo(x, y) : psiPath.lineTo(x, y);
    }
    canvas.drawPath(
      psiPath,
      Paint()
        ..color = colors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    // Cursor line + marker.
    final cx = xAt(cursor * kStepMin);
    canvas.drawLine(
      Offset(cx, padT),
      Offset(cx, padT + plotH),
      Paint()
        ..color = colors.ink.withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );
    final marker = Offset(cx, yPsi(day.psi[cursor]));
    canvas.drawCircle(marker, 4.5, Paint()..color = colors.paper);
    canvas.drawCircle(
      marker,
      4.5,
      Paint()
        ..color = colors.tier(day.tier[cursor])
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  @override
  bool shouldRepaint(covariant _StrainPainter old) =>
      old.cursor != cursor || old.day != day || old.colors != colors;
}
