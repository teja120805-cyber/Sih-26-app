import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/day_data.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// "Why this risk score, right now" — ablation attribution on the live
/// vitals-risk classifier: each bar is how much swapping just that one signal
/// back to the personal baseline would change the probability. A simple, honest
/// approximation of Shapley-style attribution, not a separate explainer model.
class WaterfallCard extends StatelessWidget {
  const WaterfallCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final attr = attributeRisk(s.cursor, day, s.models!);

    // Largest absolute contribution sets the bar scale.
    final maxAbs = math.max(
      0.01,
      attr.contributions
          .map((e) => e.contribution.abs())
          .fold<double>(0, math.max),
    );
    final sorted = [...attr.contributions]
      ..sort((a, b) => b.contribution.abs().compareTo(a.contribution.abs()));

    return SectionCard(
      eyebrow: 'Why this risk score',
      title: 'What is driving it, right now',
      trailing: MonoText('${(attr.fullProb * 100).toStringAsFixed(0)}%',
          size: 16, weight: FontWeight.w700, color: c.accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final rc in sorted)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AttrBar(
                label: rc.label,
                contribution: rc.contribution,
                maxAbs: maxAbs,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'Bars right of centre push risk up; left pull it down. Each is the '
            'change from swapping that one signal back to your baseline — single-'
            'feature ablation on the same trained model, not a separate explainer.',
            style: TextStyle(fontSize: 11.5, height: 1.4, color: c.faint),
          ),
        ],
      ),
    );
  }
}

class _AttrBar extends StatelessWidget {
  const _AttrBar({
    required this.label,
    required this.contribution,
    required this.maxAbs,
  });

  final String label;
  final double contribution;
  final double maxAbs;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final up = contribution >= 0;
    final frac = (contribution.abs() / maxAbs).clamp(0.0, 1.0);
    final col = up ? c.warning : c.ok;
    final pctPts = (contribution * 100);

    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(label,
              style: TextStyle(fontSize: 12.5, color: c.muted),
              overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          child: SizedBox(
            height: 20,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: frac),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => CustomPaint(
                size: Size.infinite,
                painter: _DivergingBarPainter(
                  fraction: v,
                  up: up,
                  color: col,
                  axis: c.lineStrong,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 52,
          child: MonoText(
            '${up ? '+' : '−'}${pctPts.abs().toStringAsFixed(1)}',
            size: 12,
            color: col,
          ),
        ),
      ],
    );
  }
}

class _DivergingBarPainter extends CustomPainter {
  _DivergingBarPainter({
    required this.fraction,
    required this.up,
    required this.color,
    required this.axis,
  });

  final double fraction;
  final bool up;
  final Color color;
  final Color axis;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.width / 2;
    // Center axis line.
    canvas.drawLine(Offset(mid, 0), Offset(mid, size.height),
        Paint()..color = axis..strokeWidth = 1);
    final half = size.width / 2 - 2;
    final w = half * fraction;
    final rect = up
        ? Rect.fromLTWH(mid + 1, 3, w, size.height - 6)
        : Rect.fromLTWH(mid - 1 - w, 3, w, size.height - 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _DivergingBarPainter old) =>
      old.fraction != fraction || old.up != up || old.color != color;
}
