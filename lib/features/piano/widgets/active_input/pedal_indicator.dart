import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PedalIndicator extends StatelessWidget {
  const PedalIndicator({super.key});

  static const double slotWidth = 36;
  static const double glyphSize = 32;
  static const Offset opticalOffset = Offset(0, -3);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Sustain pedal held',
      child: Tooltip(
        message: 'Sustain pedal held',
        child: SizedBox(
          width: slotWidth,
          height: double.infinity,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: opticalOffset,
              child: SvgPicture.asset(
                'assets/glyphs/keyboard_pedal_ped.svg',
                width: glyphSize,
                height: glyphSize,
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
    );
  }
}
