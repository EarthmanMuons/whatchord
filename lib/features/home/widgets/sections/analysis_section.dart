import 'dart:ui' show clampDouble;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/core/activity/midi_activity_tracker.dart';
import 'package:what_chord/features/theory/theory.dart';

import '../../models/home_layout_config.dart';
import '../components/chord_card.dart';

class AnalysisSection extends ConsumerWidget {
  const AnalysisSection({super.key, required this.config});
  final HomeLayoutConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(chordAnalysisProvider);

    final showIdle = ref.watch(midiIdleEligibleProvider);

    return Padding(
      padding: config.analysisPadding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableW = constraints.maxWidth;

          const preferredW = 320.0;
          final width = clampDouble(preferredW, 0, availableW);

          return Center(
            child: UnconstrainedBox(
              constrainedAxis: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  alignment: Alignment.center,
                  child: ChordCard(
                    symbol: analysis.symbol,
                    inversion: analysis.inversion,
                    showIdle: showIdle,
                    idleAsset: 'assets/logo/whatchord_logo_circle.svg',
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
