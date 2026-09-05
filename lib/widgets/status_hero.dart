import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/day_data.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// The Today screen centerpiece: a gradient status card with the headline,
/// a live strain gauge, and quick action chips. Gradient shifts with severity.
class StatusHero extends StatelessWidget {
  const StatusHero({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final i = s.cursor;
    final hero = computeHero(i, day, s.profile);
    final psi = day.psi[i];
    final tier = day.tier[i];

    final gradient = switch (hero.sev) {
      3 => [const Color(0xFFEF4444), const Color(0xFF991B1B)],
      2 => [const Color(0xFFF97316), const Color(0xFFC2410C)],
      1 => [c.accent, c.accent2],
      _ => [c.accent, c.accent2],
    };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.35),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            switch (hero.sev) {
                              3 => 'CRITICAL',
                              2 => 'WARNING',
                              1 => 'HEADS UP',
                              _ => 'ALL GOOD',
                            },
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        MonoText(s.cursorClock,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.85)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hero.headline,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.4,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _StrainGauge(psi: psi, tier: tier),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            hero.body,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in hero.actions.take(3))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconForName(a.icon), size: 15, color: Colors.white),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          a.text,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StrainGauge extends StatelessWidget {
  const _StrainGauge({required this.psi, required this.tier});
  final double psi;
  final int tier;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 78,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: (psi / 10).clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          painter: _GaugePainter(fraction: v),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MonoText(psi.toStringAsFixed(1),
                    size: 20, weight: FontWeight.w800, color: Colors.white),
                Text('PSI',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.fraction});
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const stroke = 7.0;
    final rect = Rect.fromCircle(center: center, radius: size.width / 2 - stroke / 2);
    canvas.drawArc(rect, 0, 2 * math.pi, false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.fraction != fraction;
}
