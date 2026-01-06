import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';

import 'package:what_chord/features/theory/theory.dart';

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

    final minCardHeight = 132.0;
    final padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 20);

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

      return AutoSizeText.rich(
        TextSpan(style: chordStyle, children: spans),
        textAlign: TextAlign.center,
        style: chordStyle,
        maxLines: 1,
        minFontSize: 22,
      );
    }

    return Card(
      elevation: 0,
      color: cs.primary,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minCardHeight),
        child: Padding(
          padding: padding,
          child: Center(
            child: hasInversion
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      chordText(),
                      const SizedBox(height: 18),
                      AutoSizeText(
                        inversion!,
                        textAlign: TextAlign.center,
                        style: inversionStyle,
                        maxLines: 1,
                        minFontSize: 20,
                      ),
                    ],
                  )
                : chordText(),
          ),
        ),
      ),
    );
  }
}
