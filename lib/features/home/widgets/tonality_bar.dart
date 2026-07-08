import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/key/key.dart';
import 'package:whatchord/features/theory/theory.dart';

import 'adaptive_side_sheet.dart';

class TonalityBar extends ConsumerWidget {
  const TonalityBar({
    super.key,
    required this.height,
    this.horizontalInset = 16,
    this.keyTextScaleMultiplier = 1.0,
    this.scaleDegreesTextScaleMultiplier = 1.0,
    this.onScaleDegreesTap,
  });

  final double height;
  final double horizontalInset;
  final double keyTextScaleMultiplier;
  final double scaleDegreesTextScaleMultiplier;
  final VoidCallback? onScaleDegreesTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoKey = ref.watch(keyModeProvider) == KeyMode.auto;
    // Watching here is what activates live key detection; the inferred state
    // stays warm for the picker's auto view even in manual mode.
    final inferred = ref.watch(inferredKeyProvider);
    return TonalityBarView(
      height: height,
      horizontalInset: horizontalInset,
      keyTextScaleMultiplier: keyTextScaleMultiplier,
      scaleDegreesTextScaleMultiplier: scaleDegreesTextScaleMultiplier,
      tonality: ref.watch(selectedTonalityProvider),
      scaleDegreeAnalysis: ref.watch(detectedScaleDegreeAnalysisProvider),
      onScaleDegreesTap: onScaleDegreesTap,
      autoKey: autoKey,
      autoKeyTonality: inferred.displayKey?.tonality,
      autoKeyDimmed: inferred.displayKey != null && !inferred.emphasized,
      onOpenPicker: () => openTonalityPicker(
        context,
        useSideSheet: useHomeSideSheet(context),
        showSideSheet:
            ({required context, required barrierLabel, required builder}) {
              unawaited(
                showHomeSideSheet<void>(
                  context: context,
                  barrierLabel: barrierLabel,
                  builder: builder,
                ),
              );
            },
      ),
    );
  }
}
