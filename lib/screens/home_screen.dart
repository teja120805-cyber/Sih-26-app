import 'package:flutter/material.dart';

import '../main.dart' show ThemeScope;
import '../models/day_data.dart';
import '../models/health_status.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import '../widgets/acclimatization_card.dart';
import '../widgets/activity_card.dart';
import '../widgets/demo_bar.dart';
import '../widgets/environment_card.dart';
import '../widgets/exposure_dose_card.dart';
import '../widgets/expandable_card.dart';
import '../widgets/hourly_activity_card.dart';
import '../widgets/readiness_card.dart';
import '../widgets/route_map_card.dart';
import '../widgets/sleep_card.dart';
import '../widgets/transparency_card.dart';
import '../widgets/vitals_detail.dart';
import 'fall_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    final day = s.day!;
    final i = s.cursor;
    final m = s.medical;
    final status = computeStatus(i, day, m);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Whole-screen tint on critical.
    final bg = status.isCritical
        ? Color.alphaBlend(c.critical.withValues(alpha: isDark ? 0.16 : 0.08), c.paper)
        : c.paper;

    // Summaries
    final hr = day.hr[i];
    final hrWord = hr >= m.effHrCrit ? 'Very high' : hr >= m.effHrWarn ? 'Elevated' : 'Normal';
    final hrCol = hr >= m.effHrCrit ? c.critical : hr >= m.effHrWarn ? c.warning : c.ok;
    final act = computeActivity(i, day);
    final sq = day.stats.sleepQuality;
    final sleepWord = sq >= 80 ? 'Great' : sq >= 65 ? 'Good' : sq >= 50 ? 'Fair' : 'Poor';
    final env = computeEnvironment(i, day);
    final pm = day.pm25[i];
    final envWord = '${_tempWord(day.wbgt[i])} · air ${aqWord(pm)}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _Header(name: m.name, clock: s.cursorClock, onToggleTheme: () => ThemeScope.of(context).toggle(), isDark: isDark),
            const SizedBox(height: 12),
            _AlertBanner(status: status),
            const SizedBox(height: 16),

            ExpandableCard(
              icon: Icons.favorite,
              title: 'Vitals',
              summary: 'Heart rate $hrWord · ${hr.toStringAsFixed(0)} bpm',
              accent: hrCol,
              trailing: StatusPill(hrWord, color: hrCol),
              initiallyExpanded: status.level > 0,
              child: const VitalsDetail(),
            ),
            const SizedBox(height: 12),

            ExpandableCard(
              icon: Icons.directions_walk,
              title: 'Activity',
              summary: '${_fmt(act.stepsSoFar)} steps · ${act.activeCalories} kcal',
              accent: c.ok,
              child: const Column(children: [ActivityCard(), SizedBox(height: 12), HourlyActivityCard()]),
            ),
            const SizedBox(height: 12),

            ExpandableCard(
              icon: Icons.bedtime,
              title: 'Sleep & recovery',
              summary: 'Last night $sleepWord · $sq/100',
              accent: c.accent2,
              trailing: StatusPill(sleepWord, color: sq >= 65 ? c.ok : sq >= 50 ? c.warning : c.critical),
              child: const Column(children: [SleepCard(), SizedBox(height: 12), ReadinessCard()]),
            ),
            const SizedBox(height: 12),

            ExpandableCard(
              icon: Icons.wb_sunny_outlined,
              title: 'Environment',
              summary: envWord[0].toUpperCase() + envWord.substring(1),
              accent: c.warning,
              child: Column(children: [
                Text(env.desc, style: TextStyle(fontSize: 13.5, height: 1.4, color: c.ink)),
                const SizedBox(height: 12),
                const EnvironmentCard(),
                const SizedBox(height: 12),
                const ExposureDoseCard(),
                const SizedBox(height: 12),
                const AcclimatizationCard(),
                const SizedBox(height: 12),
                const RouteMapCard(),
              ]),
            ),
            const SizedBox(height: 12),

            ExpandableCard(
              icon: Icons.science_outlined,
              title: 'Simulation & transparency',
              summary: '${s.scenario == 'heatwave' ? 'Heat-wave' : 'Normal'} day · ${s.cursorClock}',
              accent: c.faint,
              child: const Column(children: [DemoControls(), SizedBox(height: 12), TransparencyCard()]),
            ),
          ],
        ),
      ),
    );
  }

  static String _tempWord(double wbgt) =>
      wbgt >= 32 ? 'Very hot' : wbgt >= 28 ? 'Warm' : wbgt >= 22 ? 'Mild' : 'Cool';

  static String _fmt(int n) {
    final str = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return buf.toString();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.clock, required this.onToggleTheme, required this.isDark});
  final String name;
  final String clock;
  final VoidCallback onToggleTheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final greet = name.trim().isEmpty ? 'Welcome back' : 'Hi, ${name.trim().split(' ').first}';
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: c.heroGradient),
              borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.favorite, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greet,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
              Text('Your health, right now · $clock',
                  style: TextStyle(fontSize: 12.5, color: c.muted)),
            ],
          ),
        ),
        IconButton(
          onPressed: onToggleTheme,
          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: c.muted),
        ),
      ],
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.status});
  final HealthStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (status.isCritical) {
      return _CriticalBanner(status: status);
    }
    final warn = status.isWarning;
    final col = warn ? c.warning : c.ok;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: col.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(warn ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: col, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status.title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.ink)),
                const SizedBox(height: 3),
                Text(status.message,
                    style: TextStyle(fontSize: 13, height: 1.4, color: c.muted)),
                if (status.actions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final a in status.actions)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                              color: c.panel, borderRadius: BorderRadius.circular(20)),
                          child: Text(a,
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: c.ink)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CriticalBanner extends StatelessWidget {
  const _CriticalBanner({required this.status});
  final HealthStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFEF4444), const Color(0xFF991B1B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: c.critical.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(status.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(status.message,
              style: TextStyle(fontSize: 13.5, height: 1.4, color: Colors.white.withValues(alpha: 0.95))),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FallScreen())),
            child: Container(
              height: 52,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sos, color: Color(0xFFCC1F1F), size: 24),
                  SizedBox(width: 8),
                  Text('Emergency SOS',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFCC1F1F))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
