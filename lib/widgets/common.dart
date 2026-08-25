import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Maps the web console's inline-SVG icon names to Material icons.
IconData iconForName(String name) {
  switch (name) {
    case 'drop':
      return Icons.water_drop_outlined;
    case 'umbrella':
      return Icons.beach_access_outlined;
    case 'home':
      return Icons.home_outlined;
    case 'mask':
      return Icons.masks_outlined;
    case 'moon':
      return Icons.bedtime_outlined;
    case 'heart':
      return Icons.favorite_outline;
    case 'flame':
      return Icons.local_fire_department_outlined;
    case 'footsteps':
      return Icons.directions_walk;
    case 'waves':
      return Icons.graphic_eq;
    case 'check':
    default:
      return Icons.check_rounded;
  }
}

/// Small uppercase eyebrow / section-kicker label.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: color ?? c.faint,
      ),
    );
  }
}

/// The frosted card shell every console section sits in.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.eyebrow,
    this.title,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColorOverride,
  });

  final String? eyebrow;
  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColorOverride;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: borderColorOverride ?? c.line.withValues(alpha: isDark ? 1 : 0.7)),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF64748B))
                .withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null || title != null || trailing != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrow != null) Eyebrow(eyebrow!, color: c.accent),
                      if (title != null)
                        Padding(
                          padding: EdgeInsets.only(top: eyebrow != null ? 3 : 0),
                          child: Text(
                            title!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: c.ink,
                              height: 1.15,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

/// Tabular-figures monospace text for numeric read-outs.
class MonoText extends StatelessWidget {
  const MonoText(
    this.text, {
    super.key,
    this.size = 14,
    this.weight = FontWeight.w500,
    this.color,
  });

  final String text;
  final double size;
  final FontWeight weight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: kMonoFamily,
        fontFamilyFallback: kMonoFallback,
        fontFeatures: kTabularFigures,
        fontSize: size,
        fontWeight: weight,
        color: color ?? context.colors.ink,
      ),
    );
  }
}

/// A soft pill/badge (used for severity tags, chips).
class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    required this.fg,
    required this.bg,
    this.icon,
  });

  final String text;
  final Color fg;
  final Color bg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled horizontal bar showing a reading against a threshold.
class ThresholdBar extends StatelessWidget {
  const ThresholdBar({
    super.key,
    required this.label,
    required this.valueText,
    required this.fraction,
    required this.color,
  });

  final String label;
  final String valueText;
  final double fraction; // 0..1 of the bar filled
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12.5, color: c.muted)),
            MonoText(valueText, size: 12.5, color: c.ink),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(height: 7, color: c.line),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(height: 7, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
