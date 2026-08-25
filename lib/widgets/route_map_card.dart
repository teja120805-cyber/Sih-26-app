import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/day_data.dart';
import '../models/profile.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// "Where today's events happened" — the day's route with a marker at each
/// place an alert fired, color-coded by severity. When Online, real
/// OpenStreetMap raster tiles render behind the route (hand-rolled Web-Mercator
/// tiling, no map package); when Offline (or tiles fail), it falls back to a
/// drawn map — the online/offline behavior of the web console.
class RouteMapCard extends StatelessWidget {
  const RouteMapCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;

    return SectionCard(
      eyebrow: "Where events happened",
      title: "Today's route",
      trailing: Pill(
        s.network ? 'Live map' : 'Offline',
        fg: s.network ? c.accent : c.advisory,
        bg: s.network ? c.accentSoft : c.advisorySoft,
        icon: s.network ? Icons.public : Icons.cloud_off_outlined,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: _MapView(day: day, cursor: s.cursor, online: s.network),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _dot(c.advisory),
              _lbl(c, 'Advisory'),
              const SizedBox(width: 10),
              _dot(c.warning),
              _lbl(c, 'Warning'),
              const SizedBox(width: 10),
              _dot(c.critical),
              _lbl(c, 'Critical'),
              const Spacer(),
              Icon(Icons.my_location, size: 12, color: c.accent),
              _lbl(c, 'You'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            s.network
                ? 'Live OpenStreetMap tiles. Fictional loop near Vellore — only generic tile coordinates leave the device, never health data.'
                : 'Offline — drawn fallback. Set the simulation Online to load real map tiles.',
            style: TextStyle(fontSize: 11.5, height: 1.35, color: c.faint),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color col) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: col, shape: BoxShape.circle));
  Widget _lbl(AppColors c, String t) => Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(t, style: TextStyle(fontSize: 11, color: c.muted)));
}

// Web-Mercator helpers (global pixel space at a given zoom, tile size 256).
double _lonToGX(double lon, int z) => (lon + 180) / 360 * 256 * (1 << z);
double _latToGY(double lat, int z) {
  final r = lat * math.pi / 180;
  return (1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) /
      2 *
      256 *
      (1 << z);
}

class _MapView extends StatelessWidget {
  const _MapView({required this.day, required this.cursor, required this.online});
  final DayData day;
  final int cursor;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final minLat = day.lat.reduce(math.min), maxLat = day.lat.reduce(math.max);
    final minLon = day.lon.reduce(math.min), maxLon = day.lon.reduce(math.max);
    final lonSpan = math.max(1e-5, maxLon - minLon);
    final latSpan = math.max(1e-5, maxLat - minLat);

    // Choose a zoom so the route bbox fits within ~320px of content.
    int zoomFor(double px) => (math.log(320 / px) / math.log(2)).floor();
    final zx = zoomFor((lonSpan / 360) * 256);
    final zy = zoomFor((latSpan / 360) * 256);
    final z = math.min(zx, zy).clamp(11, 18);

    // Content rect in global pixels, padded.
    var minGX = _lonToGX(minLon, z), maxGX = _lonToGX(maxLon, z);
    var minGY = _latToGY(maxLat, z), maxGY = _latToGY(minLat, z); // lat inverts
    const padPx = 46.0;
    minGX -= padPx;
    maxGX += padPx;
    minGY -= padPx;
    maxGY += padPx;
    final contentW = maxGX - minGX;
    final contentH = maxGY - minGY;

    final tiles = <Widget>[];
    if (online) {
      final tMinX = (minGX / 256).floor();
      final tMaxX = (maxGX / 256).floor();
      final tMinY = (minGY / 256).floor();
      final tMaxY = (maxGY / 256).floor();
      final maxTile = (1 << z) - 1;
      for (var tx = tMinX; tx <= tMaxX; tx++) {
        for (var ty = tMinY; ty <= tMaxY; ty++) {
          if (tx < 0 || ty < 0 || tx > maxTile || ty > maxTile) continue;
          tiles.add(Positioned(
            left: tx * 256 - minGX,
            top: ty * 256 - minGY,
            width: 256,
            height: 256,
            child: Image.network(
              'https://tile.openstreetmap.org/$z/$tx/$ty.png',
              fit: BoxFit.fill,
              headers: const {
                'User-Agent': 'sih26_companion/1.0 (SIH26181 health demo)'
              },
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              loadingBuilder: (ctx, child, progress) =>
                  progress == null ? child : const SizedBox.shrink(),
            ),
          ));
        }
      }
    }

    Offset project(double lat, double lon) =>
        Offset(_lonToGX(lon, z) - minGX, _latToGY(lat, z) - minGY);

    final content = SizedBox(
      width: contentW,
      height: contentH,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _BasePainter(colors: c, online: online)),
          ...tiles,
          CustomPaint(
            painter: _RouteOverlayPainter(
              day: day,
              cursor: cursor,
              colors: c,
              project: project,
            ),
          ),
        ],
      ),
    );

    return Container(
      color: c.paper,
      child: FittedBox(
          fit: BoxFit.cover, clipBehavior: Clip.hardEdge, child: content),
    );
  }
}

class _BasePainter extends CustomPainter {
  _BasePainter({required this.colors, required this.online});
  final AppColors colors;
  final bool online;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.paper);
    final grid = Paint()
      ..color = colors.line.withValues(alpha: online ? 0.25 : 1.0)
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      final x = size.width * i / 6, y = size.height * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant _BasePainter old) => old.online != online;
}

class _RouteOverlayPainter extends CustomPainter {
  _RouteOverlayPainter({
    required this.day,
    required this.cursor,
    required this.colors,
    required this.project,
  });

  final DayData day;
  final int cursor;
  final AppColors colors;
  final Offset Function(double lat, double lon) project;

  @override
  void paint(Canvas canvas, Size size) {
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
    // White casing so the route reads over map tiles.
    canvas.drawPath(
        full,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeJoin = StrokeJoin.round);
    canvas.drawPath(
        full,
        Paint()
          ..color = colors.lineStrong
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
    canvas.drawPath(
        traveled,
        Paint()
          ..color = colors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeJoin = StrokeJoin.round);

    for (final e in day.events) {
      final idx = (e.startMin ~/ kStepMin).clamp(0, day.lat.length - 1);
      final o = project(day.lat[idx], day.lon[idx]);
      final col = colors.tier(e.severity);
      canvas.drawCircle(o, 8, Paint()..color = Colors.white);
      canvas.drawCircle(o, 6.5, Paint()..color = col);
    }

    final here = project(day.lat[cursor], day.lon[cursor]);
    canvas.drawCircle(
        here, 15, Paint()..color = colors.accent.withValues(alpha: 0.2));
    canvas.drawCircle(here, 7, Paint()..color = Colors.white);
    canvas.drawCircle(here, 5, Paint()..color = colors.accent);
  }

  @override
  bool shouldRepaint(covariant _RouteOverlayPainter old) =>
      old.cursor != cursor || old.day != day;
}
