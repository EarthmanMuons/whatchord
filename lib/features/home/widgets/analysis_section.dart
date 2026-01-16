import 'dart:ui' show clampDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/input/input.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../models/home_layout_config.dart';
import 'identity_card.dart';

class AnalysisSection extends ConsumerWidget {
  const AnalysisSection({
    super.key,
    required this.config,
    required this.isLandscape,
  });

  final HomeLayoutConfig config;
  final bool isLandscape;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityDisplayProvider);
    final showIdle = ref.watch(inputIdleEligibleProvider);

    return Padding(
      padding: config.analysisPadding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const preferredW = 320.0;
          final cardW = clampDouble(preferredW, 0.0, constraints.maxWidth);

          // Tunables
          final topPad = isLandscape ? 0.0 : 82.0;
          final cardH = isLandscape ? 132.0 : 180.0;
          const listGap = 18.0;
          const listSlotH = 28.0 * 3 + 8.0 * 2; // 3 rows + gaps

          final laneH = constraints.maxHeight;
          final cardMaxH = clampDouble(172.0, 0.0, laneH);

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
                        idleAsset: 'assets/logo/whatchord_logo_circle.svg',
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
                                    'assets/logo/whatchord_logo_circle.svg',
                                fill: true, // critical
                              ),
                            ),

                            if (!isLandscape) ...[
                              const SizedBox(height: listGap),
                              SizedBox(
                                height: listSlotH,
                                child: const NearTieChordCandidatesList(
                                  enabled: true,
                                  alignment: Alignment.topCenter,
                                  textAlign: TextAlign.center,
                                  gap: 8,
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
