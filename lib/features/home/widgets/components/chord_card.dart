import 'package:flutter/material.dart';

import '../../../theory/theory.dart';

class ChordCard extends StatelessWidget {
  final ChordSymbol symbol;
  final String? inversion;

  const ChordCard({super.key, required this.symbol, required this.inversion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final hasInversion = inversion != null && inversion!.trim().isNotEmpty;

    final chordStyle = theme.textTheme.displayMedium!.copyWith(
      color: cs.onPrimary,
      fontWeight: FontWeight.w600,
      height: 1.0,
    );

    final rootStyle = chordStyle.copyWith(fontWeight: FontWeight.w900);

    final inversionStyle = theme.textTheme.titleMedium!.copyWith(
      color: cs.onPrimary.withValues(alpha: 0.85),
      height: 1.1,
    );

    final minCardHeight = 124.0;
    final padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 18);

    Widget chordText() {
      final spans = <InlineSpan>[
        TextSpan(text: symbol.root, style: rootStyle),
        if (symbol.quality.isNotEmpty) ...[
          const TextSpan(text: '\u200A'), // hair space
          TextSpan(text: symbol.quality),
        ],
        if (symbol.hasBass) ...[
          const TextSpan(text: ' / '),
          TextSpan(text: symbol.bass),
        ],
      ];

      return Text.rich(
        TextSpan(style: chordStyle, children: spans),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Card(
      elevation: 0,
      color: cs.primary,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minCardHeight),
        child: Padding(
          padding: padding,
          child: hasInversion
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    chordText(),
                    const SizedBox(height: 18),
                    Text(
                      inversion!,
                      textAlign: TextAlign.center,
                      style: inversionStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              : Center(child: chordText()),
        ),
      ),
    );
  }
}
