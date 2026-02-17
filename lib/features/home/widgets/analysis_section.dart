import 'dart:ui' show clampDouble;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/input/input.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../models/home_layout_config.dart';
import 'identity_card.dart';

class AnalysisSection extends ConsumerWidget {
  const AnalysisSection({super.key, required this.config});

  final HomeLayoutConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityDisplayProvider);
    final showIdle = ref.watch(inputIdleEligibleProvider);

    return Padding(
      padding: config.analysisPadding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = config.isLandscape;
          final preferredW = clampDouble(
            config.analysisCardPreferredWidth,
            0.0,
            config.chordCardMaxWidth,
          );
          final cardW = clampDouble(preferredW, 0.0, constraints.maxWidth);

          // Tunables
          final textScale = MediaQuery.textScalerOf(context).scale(1.0);
          final topPad = isLandscape
              ? 0.0
              : clampDouble(
                  config.analysisTopPadMax - (textScale - 1.0) * 28.0,
                  config.analysisTopPadMin,
                  config.analysisTopPadMax,
                );
          final cardH = config.analysisCardHeight;
          final listGap = config.analysisListGap;
          final laneH = constraints.maxHeight;
          final cardMaxH = clampDouble(
            config.analysisCardMaxHeight,
            0.0,
            laneH,
          );
          final listMaxH = clampDouble(
            laneH - topPad - cardH - listGap,
            0.0,
            laneH,
          );

          return SizedBox.expand(
            child: isLandscape
                ? Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: cardW,
                        maxHeight: cardMaxH,
                      ),
                      child: IdentityCard(
                        identity: identity,
                        showIdle: showIdle,
                        idleAsset: 'assets/logos/whatchord_logo_circle.svg',
                        textScaleMultiplier: config.identityCardTextScale,
                        fill: true,
                      ),
                    ),
                  )
                : Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: topPad),
                      child: SizedBox(
                        width: cardW,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: cardW,
                              height: cardH,
                              child: IdentityCard(
                                identity: identity,
                                showIdle: showIdle,
                                idleAsset:
                                    'assets/logos/whatchord_logo_circle.svg',
                                textScaleMultiplier:
                                    config.identityCardTextScale,
                                fill: true, // critical
                              ),
                            ),

                            if (!isLandscape) ...[
                              SizedBox(height: listGap),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: listMaxH,
                                ),
                                child: NearTieChordCandidatesList(
                                  enabled: true,
                                  alignment: Alignment.topCenter,
                                  textAlign: TextAlign.center,
                                  gap: 8,
                                  textScaleMultiplier: config.nearTieTextScale,
                                ),
                              ),
                            ],
                          ],
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
