import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/input/input.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../models/home_layout_config.dart';
import 'chord_ranking_details_sheet.dart';
import 'demo_mode_explanation.dart';

class DetailsSection extends ConsumerWidget {
  const DetailsSection({super.key, required this.config});

  final HomeLayoutConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityDisplayProvider);

    // Reclaim the vertical room Android's persistent landscape status bar
    // steals, so the third alternative isn't clipped.
    final tightenForStatusBar =
        config.isLandscape && defaultTargetPlatform == TargetPlatform.android;
    final sectionPadding = tightenForStatusBar
        ? config.detailsSectionPadding.copyWith(
            top: config.analysisPadding.top,
            bottom: config.analysisPadding.bottom,
          )
        : config.detailsSectionPadding;
    final listBottomPad = tightenForStatusBar ? 8.0 : 12.0;

    return Padding(
      padding: sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (config.isLandscape)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: NearTieChordCandidatesList(
                  enabled: true,
                  alignment: Alignment.topLeft,
                  textAlign: TextAlign.left,
                  gap: 6,
                  padding: EdgeInsets.only(bottom: listBottomPad),
                  textScaleMultiplier: config.nearTieTextScale,
                  showScrollbarWhenOverflow: true,
                  tappableWhenEmpty: identity is ChordDisplay,
                  onTap: () => unawaited(
                    showChordRankingDetailsSheet(
                      context,
                      snapshot: ChordRankingDetailsSnapshot.capture(ref),
                    ),
                  ),
                ),
              ),
            )
          else
            const Spacer(),

          Align(
            alignment: Alignment.bottomLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DemoModeExplanation(
                  textAlign: TextAlign.left,
                  padding: EdgeInsets.fromLTRB(0, 0, 12, 8),
                ),
                InputDisplay(
                  padding: config.inputDisplayPadding,
                  visualScaleMultiplier: config.inputDisplayVisualScale,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
