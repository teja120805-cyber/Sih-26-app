import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/profile.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Compact simulation controls: scenario (Normal / Heat-wave), online/offline,
/// play the day forward, and a time scrubber. Not part of the product — the way
/// the demo day is explored.
class DemoControls extends StatelessWidget {
  const DemoControls({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, size: 15, color: c.faint),
              const SizedBox(width: 6),
              Text('Simulate',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: c.faint)),
              const Spacer(),
              _NetToggle(online: s.network, onTap: () {
                HapticFeedback.selectionClick();
                s.setNetwork(!s.network);
              }),
            ],
          ),
          const SizedBox(height: 10),
          _Segmented(
            value: s.scenario,
            options: const [
              ('normal', 'Normal day', Icons.wb_sunny_outlined),
              ('heatwave', 'Heat-wave', Icons.local_fire_department_outlined),
            ],
            onChanged: (v) {
              HapticFeedback.selectionClick();
              s.setScenario(v);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _PlayButton(playing: s.playing, onTap: () {
                HapticFeedback.lightImpact();
                s.togglePlay();
              }),
              const SizedBox(width: 12),
              _StatusDot(live: s.playing),
              const SizedBox(width: 6),
              SizedBox(
                width: 46,
                child: MonoText(s.cursorClock, size: 13, color: c.ink),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: c.accent,
                    inactiveTrackColor: c.line,
                    thumbColor: c.accent,
                  ),
                  child: Slider(
                    min: 0,
                    max: (kN - 1).toDouble(),
                    value: s.cursor.toDouble(),
                    onChanged: (v) {
                      if (s.playing) s.pause();
                      s.setCursor(v.round());
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetToggle extends StatelessWidget {
  const _NetToggle({required this.online, required this.onTap});
  final bool online;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: online ? c.accentSoft : c.advisorySoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(online ? Icons.wifi : Icons.wifi_off,
                size: 13, color: online ? c.accent : c.advisory),
            const SizedBox(width: 5),
            Text(online ? 'Online' : 'Offline',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: online ? c.accent : c.advisory)),
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<(String, String, IconData)> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.paper,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(o.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: value == o.$1 ? c.panel : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: value == o.$1
                        ? [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(o.$3,
                          size: 15,
                          color: value == o.$1 ? c.accent : c.muted),
                      const SizedBox(width: 6),
                      Text(o.$2,
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: value == o.$1 ? c.ink : c.muted)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.playing, required this.onTap});
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.accent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(playing ? Icons.pause : Icons.play_arrow,
              size: 20, color: c.onAccent),
        ),
      ),
    );
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.live});
  final bool live;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (!widget.live) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: c.faint, shape: BoxShape.circle),
      );
    }
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_ctrl),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
      ),
    );
  }
}
