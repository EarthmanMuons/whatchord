import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/theory/theory.dart';

import '../../models/home_layout_config.dart';
import '../components/chord_card.dart';

class AnalysisSection extends ConsumerWidget {
  const AnalysisSection({super.key, required this.config});
  final HomeLayoutConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(chordAnalysisProvider);

    return Padding(
      padding: config.analysisPadding,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: config.chordCardMaxWidth),
            child: ChordCard(
              symbol: analysis.symbol,
              inversion: analysis.inversion,
            ),
          ),
        ),
      ),
    );
  }
}
