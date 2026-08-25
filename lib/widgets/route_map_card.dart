import 'package:flutter/material.dart';

import '../models/day_data.dart';
import '../models/profile.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// "Where today's events happened" — the day's simulated route with a marker
/// at each place an alert fired, color-coded by severity. This is the drawn
/// (offline) fallback the web console falls back to when map tiles can't load;
/// real OpenStreetMap tiles would require a map package + network.
class RouteMapCard extends StatelessWidget {
  const RouteMapCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;

    return SectionCard(
      eyebrow: "Where today's events happened",
      title: "Today's route & alerts",
      trailing: Pill(
        s.network ? 'Live tiles off' : 'Offline',
        fg: s.network ? c.muted : c.advisory,
        bg: s.network ? c.panel : c.advisorySoft,
        icon: s.network ? Icons.map_outlined : Icons.cloud_off_outlined,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: CustomPaint(
                painter: _RoutePainter(day: day, cursor: s.cursor, colors: c),
                size: Size.infinite,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fictional loop near Vellore, generated with the data. '
            '${s.network ? 'With a map package, real OpenStreetMap tiles would render behind this route.' : 'Offline — the drawn fallback is shown.'}',
            style: TextStyle(fontSize: 12, height: 1.35, color: c.faint),
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.day,
    required this.cursor,
    required this.colors,
  });

  final DayData day;
  final int cursor;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.paper);

    // Bounds of the route.
    var minLat = day.lat.reduce((a, b) => a < b ? a : b);
    var maxLat = day.lat.reduce((a, b) => a > b ? a : b);
    var minLon = day.lon.reduce((a, b) => a < b ? a : b);
    var maxLon = day.lon.reduce((a, b) => a > b ? a : b);
    final latPad = (maxLat - minLat) * 0.12 + 1e-6;
    final lonPad = (maxLon - minLon) * 0.12 + 1e-6;
    minLat -= latPad;
    maxLat += latPad;
    minLon -= lonPad;
    maxLon += lonPad;

    const pad = 14.0;
    Offset project(double lat, double lon) {
      final x = pad + (lon - minLon) / (maxLon - minLon) * (size.width - 2 * pad);
      // Latitude increases upward → invert y.
      final y = pad + (maxLat - lat) / (maxLat - minLat) * (size.height - 2 * pad);
      return Offset(x, y);
    }

    // Faint grid.
    final grid = Paint()..color = colors.line..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      final y = size.height * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Route path up to the current cursor (traveled) vs. remaining.
    final full = Path();
    final traveled = Path();
    for (var i = 0; i < day.lat.length; i++) {
      final o = project(day.lat[i], day.lon[i]);
      if (i == 0) {
        full.moveTo(o.dx, o.dy);
        traveled.moveTo(o.dx, o.dy);
      } else {
        full.lineTo(o.dx, o.dy);
        if (i <= cursor) traveled.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(
      full,
      Paint()
        ..color = colors.lineStrong
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawPath(
      traveled,
      Paint()
        ..color = colors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );

    // Alert markers at each event's start position.
    for (final e in day.events) {
      final idx = (e.startMin ~/ kStepMin).clamp(0, day.lat.length - 1);
      final o = project(day.lat[idx], day.lon[idx]);
      final col = colors.tier(e.severity);
      canvas.drawCircle(o, 6, Paint()..color = col.withValues(alpha: 0.9));
      canvas.drawCircle(
        o,
        6,
        Paint()
          ..color = colors.paper
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Current position.
    final here = project(day.lat[cursor], day.lon[cursor]);
    canvas.drawCircle(here, 9, Paint()..color = colors.accent.withValues(alpha: 0.22));
    canvas.drawCircle(here, 4.5, Paint()..color = colors.accent);
    canvas.drawCircle(
      here,
      4.5,
      Paint()
        ..color = colors.paper
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) =>
      old.cursor != cursor || old.day != day;
}
