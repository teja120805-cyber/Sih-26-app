import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../state/console_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// The "demo data controls" strip — not part of the product, but the way the
/// console is explored: pick a scenario/profile, go online/offline, play the
/// day forward, or scrub to any moment.
class DemoBar extends StatelessWidget {
  const DemoBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(bottom: BorderSide(color: c.lineStrong)),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Segmented(
                label: 'Day',
                value: s.scenario,
                options: const [
                  ('normal', 'Normal'),
                  ('heatwave', 'Heat-wave'),
                ],
                onChanged: s.setScenario,
              ),
              _Segmented(
                label: 'Profile',
                value: s.profileKey,
                options: [
                  ('standard', 'Typical adult'),
                  ('vulnerable', 'Higher-risk'),
                ],
                onChanged: s.setProfile,
              ),
              _Segmented(
                label: 'Net',
                value: s.network ? 'on' : 'off',
                options: const [
                  ('on', 'Online'),
                  ('off', 'Offline'),
                ],
                onChanged: (v) => s.setNetwork(v == 'on'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _PlayButton(
                playing: s.playing,
                onTap: s.togglePlay,
              ),
              const SizedBox(width: 12),
              _StatusDot(live: s.playing),
              const SizedBox(width: 6),
              SizedBox(
                width: 48,
                child: MonoText(s.cursorClock, size: 13, color: c.ink),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
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

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Eyebrow(label),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: c.lineStrong),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < options.length; i++)
                GestureDetector(
                  onTap: () => onChanged(options[i].$1),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: value == options[i].$1 ? c.accent : c.panel,
                      border: i == 0
                          ? null
                          : Border(left: BorderSide(color: c.lineStrong)),
                    ),
                    child: Text(
                      options[i].$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: value == options[i].$1 ? c.onAccent : c.muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
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
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(playing ? Icons.pause : Icons.play_arrow,
                  size: 16, color: c.onAccent),
              const SizedBox(width: 4),
              Text(
                playing ? 'Pause' : 'Play day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: c.onAccent,
                ),
              ),
            ],
          ),
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
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: c.faint, shape: BoxShape.circle),
      );
    }
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_ctrl),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
      ),
    );
  }
}
