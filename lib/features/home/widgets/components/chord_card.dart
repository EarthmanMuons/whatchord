import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:what_chord/features/theory/theory.dart';
import 'package:what_chord/features/theory/services/note_display_formatter.dart';

class ChordCard extends StatelessWidget {
  final ChordSymbol symbol;
  final String? inversion;

  /// When true, show the idle SVG instead of chord text.
  final bool showIdle;

  /// SVG asset to show when idle.
  final String idleAsset;

  const ChordCard({
    super.key,
    required this.symbol,
    required this.inversion,
    required this.showIdle,
    required this.idleAsset,
  });

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

    const minCardHeight = 132.0;
    const padding = EdgeInsets.symmetric(horizontal: 20, vertical: 20);

    Widget chordText() {
      final spans = <InlineSpan>[
        TextSpan(text: formatNoteDisplay(symbol.root), style: rootStyle),
        if (symbol.quality.isNotEmpty) ...[
          const TextSpan(text: '\u200A'), // hair space
          TextSpan(text: formatNoteDisplay(symbol.quality)),
        ],
        if (symbol.hasBass) ...[
          const TextSpan(text: ' / '),
          TextSpan(text: formatNoteDisplay(symbol.bassRequired)),
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

    Widget idleGlyph() {
      // Keep this subtle; it should read as "resting," not "empty/error".
      return Opacity(
        opacity: 0.55,
        child: SvgPicture.asset(
          idleAsset,
          width: 72,
          height: 72,
          // Tint to onPrimary so it harmonizes with the card.
          colorFilter: ColorFilter.mode(
            cs.onPrimary.withValues(alpha: 0.9),
            BlendMode.srcIn,
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: cs.primary,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minCardHeight),
        child: Padding(
          padding: padding,
          child: AnimatedSwitcher(
            // New child animates in over `duration`.
            duration: const Duration(milliseconds: 260),

            // Old child animates out over `reverseDuration`.
            // Make this shorter to reduce "competition".
            reverseDuration: const Duration(milliseconds: 90),

            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              return FadeTransition(opacity: curved, child: child);
            },
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            child: showIdle
                ? KeyedSubtree(key: const ValueKey('idle'), child: idleGlyph())
                : KeyedSubtree(
                    key: const ValueKey('chord'),
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
      ),
    );
  }
}
