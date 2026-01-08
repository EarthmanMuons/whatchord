import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/midi_settings_page.dart';
import '../providers/midi_connection_status_provider.dart';
import '../providers/midi_connection_notifier.dart';

enum _PillTone { normal, error, muted }

class MidiStatusPill extends ConsumerWidget {
  const MidiStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    final connection = ref.watch(midiConnectionStatusProvider);

    final tone = switch (connection.phase) {
      MidiConnectionPhase.connected ||
      MidiConnectionPhase.connecting ||
      MidiConnectionPhase.retrying => _PillTone.normal,

      MidiConnectionPhase.error ||
      MidiConnectionPhase.bluetoothUnavailable ||
      MidiConnectionPhase.deviceUnavailable => _PillTone.error,

      MidiConnectionPhase.idle => _PillTone.muted,
    };

    final (bg, fg, border) = switch (tone) {
      _PillTone.normal => (
        cs.secondaryContainer,
        cs.onSecondaryContainer,
        cs.outlineVariant.withValues(alpha: 0.35),
      ),

      _PillTone.error => (
        cs.errorContainer,
        cs.onErrorContainer,
        cs.outlineVariant.withValues(alpha: 0.35),
      ),

      _PillTone.muted => (
        cs.surfaceContainerHigh,
        cs.onSurfaceVariant,
        cs.outlineVariant.withValues(alpha: 0.55),
      ),
    };

    final dotColor = connection.phase == MidiConnectionPhase.connected
        ? Colors.green.shade600
        : switch (tone) {
            _PillTone.normal => cs.secondary,
            _PillTone.error => cs.error,
            _PillTone.muted => cs.onSurfaceVariant.withValues(alpha: 0.6),
          };

    final pulse = switch (connection.phase) {
      MidiConnectionPhase.connecting || MidiConnectionPhase.retrying => true,
      _ => false,
    };

    final label = connection.label;

    return Semantics(
      label: 'MIDI connection status. Tap to configure.',
      button: true,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const MidiSettingsPage()),
          );
        },
        borderRadius: BorderRadius.circular(999),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: bg,
            shape: StadiumBorder(side: BorderSide(color: border)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MidiStatusDot(color: dotColor, pulse: pulse),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MidiStatusDot extends StatefulWidget {
  // ignore: unused_element_parameter
  const _MidiStatusDot({required this.color, required this.pulse, super.key});

  final Color color;
  final bool pulse;

  @override
  State<_MidiStatusDot> createState() => _MidiStatusDotState();
}

class _MidiStatusDotState extends State<_MidiStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _sync();
  }

  @override
  void didUpdateWidget(covariant _MidiStatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulse != widget.pulse) {
      _sync();
    }
  }

  void _sync() {
    if (widget.pulse) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0; // rest state
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value; // 0..1
        final scale = 1.0 + (0.20 * t);
        final opacity = widget.pulse ? (0.70 + (0.30 * t)) : 1.0;

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: widget.pulse ? scale : 1.0,
            child: child,
          ),
        );
      },
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
