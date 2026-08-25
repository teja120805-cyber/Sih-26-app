import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A donut ring that animates smoothly whenever [fraction] changes, with an
/// optional [center] widget.
class AnimatedDonut extends StatelessWidget {
  const AnimatedDonut({
    super.key,
    required this.fraction,
    required this.fill,
    required this.track,
    this.stroke = 9,
    this.center,
  });

  final double fraction;
  final Color fill;
  final Color track;
  final double stroke;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => CustomPaint(
        painter: _DonutPainter(fraction: v, fill: fill, track: track, stroke: stroke),
        child: Center(child: center),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.fraction,
    required this.fill,
    required this.track,
    required this.stroke,
  });
  final double fraction;
  final Color fill;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect =
        Rect.fromCircle(center: center, radius: size.width / 2 - stroke / 2);
    canvas.drawArc(rect, 0, 2 * math.pi, false,
        Paint()..color = track..style = PaintingStyle.stroke..strokeWidth = stroke);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      Paint()
        ..color = fill
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.fraction != fraction || old.fill != fill;
}

/// Concentric progress rings that animate on value change.
class AnimatedRings extends StatelessWidget {
  const AnimatedRings({
    super.key,
    required this.values,
    required this.colors,
    required this.track,
  });
  final List<double> values;
  final List<Color> colors;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => CustomPaint(
        painter: _RingsPainter(
          values: values.map((v) => v * t).toList(),
          colors: colors,
          track: track,
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.values, required this.colors, required this.track});
  final List<double> values;
  final List<Color> colors;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const stroke = 11.0;
    const gap = 4.0;
    for (var i = 0; i < values.length; i++) {
      final radius = size.width / 2 - stroke / 2 - i * (stroke + gap);
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, 0, 2 * math.pi, false,
          Paint()..color = track..style = PaintingStyle.stroke..strokeWidth = stroke);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * values[i].clamp(0.0, 1.0),
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) =>
      old.values.toString() != values.toString();
}

/// A number that tweens to its new value (with optional decimals / suffix).
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.style,
    this.decimals = 0,
    this.suffix = '',
    this.thousands = false,
  });

  final double value;
  final TextStyle style;
  final int decimals;
  final String suffix;
  final bool thousands;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: value, end: value),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, v, _) {
        var text = v.toStringAsFixed(decimals);
        if (thousands) text = _withThousands(text);
        return Text('$text$suffix', style: style);
      },
    );
  }

  static String _withThousands(String intStr) {
    final neg = intStr.startsWith('-');
    final digits = neg ? intStr.substring(1) : intStr;
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return '${neg ? '-' : ''}$buf';
  }
}

/// Wraps a child in a one-shot fade+slide entrance, staggered by [index].
class EntranceCard extends StatefulWidget {
  const EntranceCard({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<EntranceCard> createState() => _EntranceCardState();
}

class _EntranceCardState extends State<EntranceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 40 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
