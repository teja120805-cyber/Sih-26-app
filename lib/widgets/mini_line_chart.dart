import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A compact line/area chart over a full day's series, with a cursor marker and
/// optional warning/critical threshold lines. Used on the Vitals tab.
class MiniLineChart extends StatelessWidget {
  const MiniLineChart({
    super.key,
    required this.values,
    required this.cursor,
    required this.color,
    this.fill = false,
    this.warn,
    this.critical,
    this.minY,
    this.maxY,
    this.aspect = 2.6,
  });

  final List<double> values;
  final int cursor;
  final Color color;
  final bool fill;
  final double? warn;
  final double? critical;
  final double? minY;
  final double? maxY;
  final double aspect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AspectRatio(
      aspectRatio: aspect,
      child: CustomPaint(
        size: Size.infinite,
        painter: _MiniPainter(
          values: values,
          cursor: cursor,
          color: color,
          fill: fill,
          warn: warn,
          critical: critical,
          minY: minY,
          maxY: maxY,
          colors: c,
        ),
      ),
    );
  }
}

class _MiniPainter extends CustomPainter {
  _MiniPainter({
    required this.values,
    required this.cursor,
    required this.color,
    required this.fill,
    required this.warn,
    required this.critical,
    required this.minY,
    required this.maxY,
    required this.colors,
  });

  final List<double> values;
  final int cursor;
  final Color color;
  final bool fill;
  final double? warn;
  final double? critical;
  final double? minY;
  final double? maxY;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const padL = 4.0, padR = 4.0, padT = 6.0, padB = 6.0;
    final plotW = size.width - padL - padR;
    final plotH = size.height - padT - padB;
    var lo = minY ?? values.reduce(math.min);
    var hi = maxY ?? values.reduce(math.max);
    if ((hi - lo).abs() < 1e-6) hi = lo + 1;
    lo -= (hi - lo) * 0.08;
    hi += (hi - lo) * 0.08;

    double xAt(int i) => padL + i / (values.length - 1) * plotW;
    double yAt(double v) => padT + plotH - ((v - lo) / (hi - lo)) * plotH;

    void dash(double? v, Color col) {
      if (v == null) return;
      final y = yAt(v);
      const d = 5.0, g = 4.0;
      var x = padL;
      final p = Paint()
        ..color = col.withValues(alpha: 0.6)
        ..strokeWidth = 1;
      while (x < padL + plotW) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + d, padL + plotW), y), p);
        x += d + g;
      }
    }

    dash(warn, colors.warning);
    dash(critical, colors.critical);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final o = Offset(xAt(i), yAt(values[i]));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }

    if (fill) {
      final area = Path.from(path)
        ..lineTo(xAt(values.length - 1), padT + plotH)
        ..lineTo(xAt(0), padT + plotH)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.0)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    final ci = cursor.clamp(0, values.length - 1);
    final marker = Offset(xAt(ci), yAt(values[ci]));
    canvas.drawLine(Offset(marker.dx, padT), Offset(marker.dx, padT + plotH),
        Paint()..color = colors.ink.withValues(alpha: 0.25)..strokeWidth = 1);
    canvas.drawCircle(marker, 4, Paint()..color = colors.panel);
    canvas.drawCircle(marker, 4,
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _MiniPainter old) =>
      old.cursor != cursor || old.values != values || old.color != color;
}
