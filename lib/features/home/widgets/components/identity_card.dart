import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:what_chord/features/theory/theory.dart';
import 'package:what_chord/features/theory/services/note_display_formatter.dart';

class IdentityCard extends StatelessWidget {
  final IdentityDisplay? identity;

  /// When true, show the idle SVG instead of identity text.
  final bool showIdle;

  /// SVG asset to show when idle.
  final String idleAsset;

  final bool fill;

  const IdentityCard({
    super.key,
    required this.identity,
    required this.showIdle,
    required this.idleAsset,
    this.fill = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final hasLabel = identity?.hasSecondaryLabel ?? false;

    final primaryStyle = theme.textTheme.displayMedium!.copyWith(
      color: cs.onPrimary,
      fontWeight: FontWeight.w600,
      height: 1.0,
    );

    final secondaryStyle = theme.textTheme.titleMedium!.copyWith(
      color: cs.onPrimary.withValues(alpha: 0.85),
      height: 1.1,
    );

    final rootStyle = primaryStyle.copyWith(fontWeight: FontWeight.w900);

    const minCardHeight = 132.0;
    const padding = EdgeInsets.symmetric(horizontal: 20);

    Widget identityBody(IdentityDisplay v) {
      return switch (v) {
        NoteDisplay(:final noteName) => AutoSizeText(
          toGlyphAccidentals(noteName),
          textAlign: TextAlign.center,
          style: primaryStyle,
          maxLines: 1,
          minFontSize: 22,
        ),

        IntervalDisplay(:final intervalLabel) => AutoSizeText(
          intervalLabel,
          textAlign: TextAlign.center,
          style: primaryStyle,
          maxLines: 1,
          minFontSize: 22,
        ),

        ChordDisplay(:final symbol) => AutoSizeText.rich(
          TextSpan(
            style: primaryStyle,
            children: <InlineSpan>[
              TextSpan(text: toGlyphAccidentals(symbol.root), style: rootStyle),
              if (symbol.quality.isNotEmpty) ...[
                const TextSpan(text: '\u200A'), // hair space
                TextSpan(text: toGlyphAccidentals(symbol.quality)),
              ],
              if (symbol.hasBass) ...[
                const TextSpan(text: ' / '),
                TextSpan(text: toGlyphAccidentals(symbol.bassRequired)),
              ],
            ],
          ),
          textAlign: TextAlign.center,
          style: primaryStyle,
          maxLines: 1,
          minFontSize: 22,
        ),
      };
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

    Widget placeholderText(TextStyle style) {
      return AutoSizeText(
        '• • •',
        textAlign: TextAlign.center,
        style: style,
        maxLines: 1,
        minFontSize: 22,
      );
    }

    final display = identity;

    Widget switchedChild() {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
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
          // When fill=true, parent will constrain this (via SizedBox.expand),
          // so Stack will fill. When fill=false, it shrink-wraps naturally.
          return Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              for (final c in previousChildren) Center(child: c),
              if (currentChild != null) Center(child: currentChild),
            ],
          );
        },
        child: display != null
            ? KeyedSubtree(
                key: const ValueKey('identity'),
                child: hasLabel
                    ? LayoutBuilder(
                        builder: (context, c) {
                          final tight =
                              c.maxHeight.isFinite && c.maxHeight < 110.0;

                          final gap = tight ? 14.0 : 22.0;
                          final secondaryMin = tight ? 16.0 : 20.0;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              identityBody(display),
                              SizedBox(height: gap),
                              AutoSizeText(
                                display.secondaryLabel!,
                                textAlign: TextAlign.center,
                                style: secondaryStyle,
                                maxLines: 1,
                                minFontSize: secondaryMin,
                              ),
                            ],
                          );
                        },
                      )
                    : identityBody(display),
              )
            : showIdle
            ? KeyedSubtree(
                key: const ValueKey('idle_glyph'),
                child: idleGlyph(),
              )
            : KeyedSubtree(
                key: const ValueKey('placeholder'),
                child: placeholderText(primaryStyle),
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
          child: fill
              // Expand to whatever height the parent gives the card,
              // and keep the switching content centered.
              ? SizedBox.expand(child: switchedChild())
              : switchedChild(),
        ),
      ),
    );
  }
}
