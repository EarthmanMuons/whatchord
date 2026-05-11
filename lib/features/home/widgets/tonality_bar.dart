import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/theory/theory.dart';

import 'adaptive_side_sheet.dart';

class TonalityBar extends ConsumerWidget {
  const TonalityBar({
    super.key,
    required this.height,
    this.horizontalInset = 16,
    this.keyTextScaleMultiplier = 1.0,
    this.scaleDegreesTextScaleMultiplier = 1.0,
  });

  final double height;
  final double horizontalInset;
  final double keyTextScaleMultiplier;
  final double scaleDegreesTextScaleMultiplier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TonalityBarView(
      height: height,
      horizontalInset: horizontalInset,
      keyTextScaleMultiplier: keyTextScaleMultiplier,
      scaleDegreesTextScaleMultiplier: scaleDegreesTextScaleMultiplier,
      tonality: ref.watch(selectedTonalityProvider),
      scaleDegreeAnalysis: ref.watch(detectedScaleDegreeAnalysisProvider),
      onOpenPicker: () => openTonalityPicker(
        context,
        useSideSheet: useHomeSideSheet(context),
        showSideSheet:
            ({required context, required barrierLabel, required builder}) {
              showHomeSideSheet<void>(
                context: context,
                barrierLabel: barrierLabel,
                builder: builder,
              );
            },
      ),
    );
  }
}
