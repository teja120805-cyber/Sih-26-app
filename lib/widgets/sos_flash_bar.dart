import 'package:flutter/material.dart';

/// Top bar that stays empty when all is well, and **flashes SOS + emergency
/// numbers** during a critical emergency. Numbers are the Indian emergency
/// services; tapping one shows a confirm sheet (no real call is placed).
class SosFlashBar extends StatefulWidget {
  const SosFlashBar({super.key, required this.active, required this.reason});

  final bool active;
  final String reason;

  @override
  State<SosFlashBar> createState() => _SosFlashBarState();
}

class _SosFlashBarState extends State<SosFlashBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant SosFlashBar old) {
    super.didUpdateWidget(old);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.active && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _call(BuildContext context, String number, String label) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emergency_share, color: Color(0xFFDC2626), size: 40),
              const SizedBox(height: 12),
              Text('Call $label ($number)?',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Demo — no real call is placed.',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Dialing $label ($number)… [demo]')),
                      );
                    },
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox(width: double.infinity, height: 0);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        final bg = Color.lerp(const Color(0xFFB91C1C), const Color(0xFFEF4444), t)!;
        return Container(
          width: double.infinity,
          color: bg,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Row(
                  children: [
                    Opacity(
                      opacity: 0.55 + 0.45 * t,
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 8),
                    const Text('SOS',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.reason,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.95))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _num(context, '112', 'Emergency'),
                    const SizedBox(width: 8),
                    _num(context, '108', 'Ambulance'),
                    const SizedBox(width: 8),
                    _num(context, '102', 'Medical'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _num(BuildContext context, String number, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _call(context, number, label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.call, size: 14, color: Color(0xFFB91C1C)),
                  const SizedBox(width: 5),
                  Text(number,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFB91C1C))),
                ],
              ),
              Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF7F1D1D))),
            ],
          ),
        ),
      ),
    );
  }
}
