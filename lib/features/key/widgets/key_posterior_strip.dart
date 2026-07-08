import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/theory/theory.dart';

import '../domain/detectors/display_calibration.dart';
import '../domain/detectors/key_space.dart';
import '../domain/models/key_estimate.dart';

/// The circle of fifths unrolled for height-constrained layouts: one column
/// per pitch class in fifths order, major above its relative minor, so the
/// adjacency story survives (fifth neighbors touch, relative pairs stack).
/// Same single-hue calibrated ramp as the wheel; the claim carries a border
/// so it is never marked by color alone. Tapping a cell shows that key's
/// calibrated probability.
class KeyPosteriorStrip extends ConsumerWidget {
  const KeyPosteriorStrip({super.key, required this.ranked, this.claim});

  /// Raw posterior from the detector; calibrated internally for display.
  final List<KeyEstimate> ranked;
  final Tonality? claim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final noteNameSystem = ref.watch(noteNameSystemProvider);
    final calibrated = DisplayCalibration.calibrate(ranked);

    final byIndex = <int, double>{
      for (final estimate in calibrated)
        KeySpace.index(estimate.tonality): estimate.confidence,
    };
    final claimIndex = claim == null ? null : KeySpace.index(claim!);

    Widget cell(Tonality tonality, {required bool isMajor}) {
      final index = KeySpace.index(tonality);
      final confidence = byIndex[index] ?? 0.0;
      final t = math.sqrt(confidence).clamp(0.0, 1.0);
      final fill = Color.lerp(cs.surfaceContainerHighest, cs.primary, t)!;
      final tonic = tonalityPickerTonicLabel(
        tonality,
        noteNameSystem: noteNameSystem,
      );
      final label = isMajor ? tonic : '${tonic}m';
      final percent = confidence * 100;
      final percentLabel = percent >= 0.5 ? '${percent.round()}%' : '<1%';

      return Tooltip(
        message:
            '${tonalitySemanticLabel(tonality, noteNameSystem: noteNameSystem)}'
            ' · $percentLabel',
        triggerMode: TooltipTriggerMode.tap,
        child: Container(
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(4),
            border: index == claimIndex
                ? Border.all(color: cs.onSurface, width: 2)
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              fontSize: 12,
              fontWeight: index == claimIndex
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: t > 0.45 ? cs.onPrimary : cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < 12; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                cell(
                  KeySpace.canonicalTonalities[((7 * i) % 12) * 2],
                  isMajor: true,
                ),
                const SizedBox(height: 2),
                cell(
                  KeySpace.canonicalTonalities[(((7 * i) % 12 + 9) % 12) * 2 +
                      1],
                  isMajor: false,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
