import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/home/widgets/components/chord_card.dart';

import '../providers/chord_analysis_provider.dart';

/// Renders the chord card using live analysis, and shows debug output beneath
/// the card in debug builds.
class ChordCardPanel extends ConsumerWidget {
  const ChordCardPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(chordAnalysisProvider);
    final debug = ref.watch(chordAnalysisDebugProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChordCard(symbol: analysis.symbol, inversion: analysis.inversion),
        if (kDebugMode) ...[
          const SizedBox(height: 10),
          _ChordDebugLine(text: debug),
        ],
      ],
    );
  }
}

class _ChordDebugLine extends StatelessWidget {
  final String text;
  const _ChordDebugLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.labelSmall?.copyWith(fontFamily: 'monospace'),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
