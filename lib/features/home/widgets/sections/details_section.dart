import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/piano/piano.dart';
import 'package:what_chord/features/theory/theory.dart';

import '../../models/home_layout_config.dart';

class DetailsSection extends ConsumerWidget {
  const DetailsSection({
    super.key,
    required this.config,
    required this.isLandscape,
  });

  final HomeLayoutConfig config;
  final bool isLandscape;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: config.detailsSectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLandscape)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: const AmbiguousChordCandidatesList(
                  enabled: true,
                  alignment: Alignment.topLeft,
                  textAlign: TextAlign.left,
                  gap: 6,
                ),
              ),
            )
          else
            const Spacer(),

          Align(
            alignment: Alignment.bottomLeft,
            child: ActiveInput(padding: config.activeInputPadding),
          ),
        ],
      ),
    );
  }
}
