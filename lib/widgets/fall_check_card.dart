import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';

/// A test button that starts a no-response countdown, exactly like a genuine
/// fall detector's confirm-cancel window. Sending an actual SOS is intentionally
/// not built — it needs real hardware and telecom access.
class FallCheckCard extends StatefulWidget {
  const FallCheckCard({super.key});

  @override
  State<FallCheckCard> createState() => _FallCheckCardState();
}

enum _FallPhase { idle, counting, wouldSend, cancelled }

class _FallCheckCardState extends State<FallCheckCard> {
  static const int _start = 12;
  _FallPhase phase = _FallPhase.idle;
  int secondsLeft = _start;
  Timer? _timer;

  void _simulate() {
    _timer?.cancel();
    setState(() {
      phase = _FallPhase.counting;
      secondsLeft = _start;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        secondsLeft--;
        if (secondsLeft <= 0) {
          t.cancel();
          phase = _FallPhase.wouldSend;
        }
      });
    });
  }

  void _imOk() {
    _timer?.cancel();
    setState(() => phase = _FallPhase.cancelled);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      phase = _FallPhase.idle;
      secondsLeft = _start;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SectionCard(
      eyebrow: 'Fall & distress check',
      title: 'No-response countdown',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          switch (phase) {
            _FallPhase.idle => _Idle(onSimulate: _simulate),
            _FallPhase.counting =>
              _Counting(secondsLeft: secondsLeft, onOk: _imOk),
            _FallPhase.wouldSend => _WouldSend(onReset: _reset),
            _FallPhase.cancelled => _Cancelled(onReset: _reset),
          },
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.panel,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: c.faint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No SOS message or location is ever actually sent — that '
                    'needs real hardware and telecom access. This only '
                    'demonstrates the detect-and-confirm window.',
                    style:
                        TextStyle(fontSize: 12, height: 1.4, color: c.faint),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Idle extends StatelessWidget {
  const _Idle({required this.onSimulate});
  final VoidCallback onSimulate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'If a hard fall is detected and you don\'t respond, the device would '
          'raise an alarm and start a countdown before alerting a contact.',
          style: TextStyle(fontSize: 13.5, height: 1.45, color: c.muted),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onSimulate,
          icon: const Icon(Icons.warning_amber_rounded, size: 18),
          label: const Text('Simulate a fall'),
          style: FilledButton.styleFrom(
            backgroundColor: c.warning,
            foregroundColor: c.onAccent,
          ),
        ),
      ],
    );
  }
}

class _Counting extends StatelessWidget {
  const _Counting({required this.secondsLeft, required this.onOk});
  final int secondsLeft;
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: secondsLeft / 12,
                    strokeWidth: 4,
                    backgroundColor: c.line,
                    valueColor: AlwaysStoppedAnimation(c.critical),
                  ),
                  MonoText('$secondsLeft',
                      size: 20, weight: FontWeight.w700, color: c.critical),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Possible fall detected. Alerting a contact in $secondsLeft s '
                'unless you respond.',
                style: TextStyle(fontSize: 13.5, height: 1.4, color: c.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onOk,
          icon: const Icon(Icons.check, size: 18),
          label: const Text("I'm OK — cancel"),
          style: FilledButton.styleFrom(
            backgroundColor: c.ok,
            foregroundColor: c.onAccent,
          ),
        ),
      ],
    );
  }
}

class _WouldSend extends StatelessWidget {
  const _WouldSend({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.criticalSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: c.critical, width: 3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.sos_outlined, size: 20, color: c.critical),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No response. On a real device, an SOS with your location '
                  'would now be sent to your emergency contact. (Not sent here.)',
                  style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: c.ink),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onReset, child: const Text('Reset')),
      ],
    );
  }
}

class _Cancelled extends StatelessWidget {
  const _Cancelled({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_outline, size: 20, color: c.ok),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Cancelled — glad you\'re OK. No alert was sent.',
                  style: TextStyle(fontSize: 13.5, color: c.ink)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onReset, child: const Text('Reset')),
      ],
    );
  }
}
