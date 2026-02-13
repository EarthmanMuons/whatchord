import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/input/input.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../models/home_layout_config.dart';

class DetailsSection extends ConsumerWidget {
  const DetailsSection({super.key, required this.config});

  final HomeLayoutConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: config.detailsSectionPadding,
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
                  padding: EdgeInsets.only(bottom: 12),
                  textScaleMultiplier: config.nearTieTextScale,
                  showScrollbarWhenOverflow: true,
                ),
              ),
            )
          else
            const Spacer(),

          Align(
            alignment: Alignment.bottomLeft,
            child: InputDisplay(
              padding: config.inputDisplayPadding,
              visualScaleMultiplier: config.inputDisplayVisualScale,
            ),
          ),
        ],
      ),
    );
  }
}
