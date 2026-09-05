import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'common.dart';
import 'mini_line_chart.dart';

/// A health metric card inspired by the reference designs: collapsed it shows an
/// icon, big value, a mini sparkline and a status pill; tapped, it expands to a
/// full day chart with Average / Min / Max and a plain-language takeaway.
class ExpandableStatCard extends StatefulWidget {
  const ExpandableStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.statusText,
    required this.statusColor,
    required this.accent,
    required this.series,
    required this.cursor,
    this.warn,
    this.critical,
    this.minY,
    this.maxY,
    this.fill = false,
    this.detail,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String statusText;
  final Color statusColor;
  final Color accent;
  final List<double> series;
  final int cursor;
  final double? warn;
  final double? critical;
  final double? minY;
  final double? maxY;
  final bool fill;
  final Widget? detail;
  final bool initiallyExpanded;

  @override
  State<ExpandableStatCard> createState() => _ExpandableStatCardState();
}

class _ExpandableStatCardState extends State<ExpandableStatCard> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _open = !_open);
            },
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.label, style: TextStyle(fontSize: 12.5, color: c.muted)),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          MonoText(widget.value, size: 23, weight: FontWeight.w800, color: c.ink),
                          const SizedBox(width: 3),
                          Text(widget.unit, style: TextStyle(fontSize: 11.5, color: c.faint)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (!_open)
                    SizedBox(
                      width: 64,
                      child: MiniLineChart(
                        values: widget.series,
                        cursor: widget.cursor,
                        color: widget.accent,
                        minY: widget.minY,
                        maxY: widget.maxY,
                        aspect: 3.0,
                      ),
                    ),
                  const SizedBox(width: 8),
                  StatusPill(widget.statusText, color: widget.statusColor),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: c.faint, size: 22),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: c.line, height: 1),
                        const SizedBox(height: 12),
                        MiniLineChart(
                          values: widget.series,
                          cursor: widget.cursor,
                          color: widget.accent,
                          warn: widget.warn,
                          critical: widget.critical,
                          minY: widget.minY,
                          maxY: widget.maxY,
                          fill: widget.fill,
                          aspect: 2.5,
                        ),
                        const SizedBox(height: 10),
                        _stats(context),
                        if (widget.detail != null) ...[
                          const SizedBox(height: 12),
                          widget.detail!,
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _stats(BuildContext context) {
    final c = context.colors;
    double lo = widget.series.first, hi = widget.series.first, sum = 0;
    for (final v in widget.series) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
      sum += v;
    }
    final avg = sum / widget.series.length;
    Widget cell(String k, double v) => Expanded(
          child: Column(
            children: [
              Text(k, style: TextStyle(fontSize: 11, color: c.faint)),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  MonoText(v.toStringAsFixed(v.abs() < 10 ? 1 : 0),
                      size: 17, weight: FontWeight.w800, color: c.ink),
                  const SizedBox(width: 2),
                  Text(widget.unit, style: TextStyle(fontSize: 10, color: c.faint)),
                ],
              ),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: c.paper, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        cell('Average', avg),
        _divider(c),
        cell('Minimum', lo),
        _divider(c),
        cell('Maximum', hi),
      ]),
    );
  }

  Widget _divider(AppColors c) => Container(width: 1, height: 28, color: c.line);
}
