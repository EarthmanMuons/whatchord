import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:whatchord/features/midi/midi.dart'
    show
        isPedalDownProvider,
        pedalSourceProvider,
        midiNoteStateProvider,
        PedalInputSource;

class PedalIndicator extends ConsumerStatefulWidget {
  const PedalIndicator({super.key});

  static const double slotWidth = 36;
  static const double glyphSize = 32;
  static const Offset opticalOffset = Offset(0, -3);

  @override
  ConsumerState<PedalIndicator> createState() => _PedalIndicatorState();
}

class _PedalIndicatorState extends ConsumerState<PedalIndicator> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final isDown = ref.watch(isPedalDownProvider);
    final source = ref.watch(pedalSourceProvider);

    final showManualRing = isDown && source == PedalInputSource.manual;

    final tooltip = isDown
        ? 'Sustain pedal held. Tap to toggle.'
        : 'Sustain pedal. Tap to toggle.';

    const basePad = EdgeInsets.symmetric(horizontal: 4, vertical: 6);
    final pressPad = _pressed
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 7)
        : basePad;

    final ringColor = cs.outlineVariant.withValues(alpha: 0.78);

    return Semantics(
      label: tooltip,
      button: true,
      onTapHint: 'Toggle sustain pedal',
      child: Tooltip(
        message: tooltip,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onHighlightChanged: (v) => setState(() => _pressed = v),
            onTap: () =>
                ref.read(midiNoteStateProvider.notifier).togglePedalManual(),
            child: SizedBox(
              width: PedalIndicator.slotWidth,
              height: double.infinity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: showManualRing
                      ? Border.all(color: ringColor, width: 1.0)
                      : null,
                ),
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOutCubic,
                  padding: pressPad,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.translate(
                      offset: PedalIndicator.opticalOffset,
                      child: SvgPicture.asset(
                        'assets/glyphs/keyboard_pedal_ped.svg',
                        width: PedalIndicator.glyphSize,
                        height: PedalIndicator.glyphSize,
                        alignment: Alignment.centerLeft,
                        colorFilter: ColorFilter.mode(
                          cs.onSurfaceVariant,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
