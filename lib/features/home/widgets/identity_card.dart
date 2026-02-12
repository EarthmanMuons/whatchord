import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:whatchord/features/theory/theory.dart';

import 'analysis_details_sheet.dart';

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

    final base = theme.textTheme.displayMedium!;

    final primaryStyle = base.copyWith(
      color: cs.onPrimary,
      fontFamilyFallback: const ['Bravura'],
      // fontFeatures: const [FontFeature.enable('ss07')],
      height: 1.0,
    );

    final secondaryStyle = theme.textTheme.titleMedium!.copyWith(
      color: cs.onPrimary.withValues(alpha: 0.85),
      height: 1.1,
      letterSpacing: -0.2,
    );

    final rootStyle = primaryStyle.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: primaryStyle.fontSize! + 6,
    );

    const minCardHeight = 132.0;
    const padding = EdgeInsets.symmetric(horizontal: 20);

    Widget identityBody(IdentityDisplay v) {
      return switch (v) {
        NoteDisplay(:final noteName) => AutoSizeText(
          toSmufl(noteName),
          textAlign: TextAlign.center,
          style: rootStyle,
          maxLines: 1,
          minFontSize: 22,
        ),
        IntervalDisplay(:final intervalLabel) => AutoSizeText(
          intervalLabel,
          textAlign: TextAlign.center,
          style: rootStyle,
          maxLines: 1,
          minFontSize: 22,
        ),
        ChordDisplay(:final symbol) => AutoSizeText.rich(
          TextSpan(
            style: primaryStyle,
            children: <InlineSpan>[
              TextSpan(text: toSmufl(symbol.root), style: rootStyle),
              if (symbol.quality.isNotEmpty) ...[
                const TextSpan(text: '\u200A'),
                ...buildChordSpans(
                  text: toSmufl(symbol.quality),
                  base: primaryStyle,
                  parenStyle: primaryStyle.copyWith(
                    fontSize: (primaryStyle.fontSize ?? 14) + 2.0,
                  ),
                ),
              ],
              if (symbol.hasBass) ...[
                const TextSpan(text: ' / '),
                TextSpan(text: toSmufl(symbol.bassRequired)),
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
      return Opacity(
        opacity: 0.55,
        child: SvgPicture.asset(
          idleAsset,
          width: 72,
          height: 72,
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

    final cardShape = CardTheme.of(context).shape;
    final cardBorderRadius = switch (cardShape) {
      RoundedRectangleBorder(:final borderRadius) => borderRadius.resolve(
        Directionality.of(context),
      ),
      _ => BorderRadius.circular(12),
    };

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
                child: Semantics(
                  container: true,
                  // Announce the meaning in plain English.
                  label: display.longLabel,
                  value: display.hasSecondaryLabel
                      ? display.secondaryLabel
                      : null,

                  // Prevent VoiceOver/TalkBack from reading the visual glyph
                  // text in addition to label.
                  excludeSemantics: true,

                  button: true,
                  onTapHint: 'Show analysis details',
                  child: hasLabel
                      ? LayoutBuilder(
                          builder: (context, c) {
                            final maxH = c.maxHeight;
                            final hasMax = maxH.isFinite && maxH > 0;
                            final textScale = MediaQuery.textScalerOf(
                              context,
                            ).scale(1.0);
                            final gapScale = 1 / textScale.clamp(1.0, 1.6);
                            const gap = 0.0;
                            final maxW = c.maxWidth.isFinite
                                ? c.maxWidth
                                : MediaQuery.sizeOf(context).width -
                                      padding.horizontal;
                            final secondaryLabel = display.secondaryLabel!;

                            if (!hasMax) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  identityBody(display),
                                  const SizedBox(height: gap),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: maxW),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.center,
                                      child: Text(
                                        secondaryLabel,
                                        textAlign: TextAlign.center,
                                        style: secondaryStyle,
                                        maxLines: 1,
                                        softWrap: false,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            final textDirection = Directionality.of(context);
                            final secondaryPainter = TextPainter(
                              text: TextSpan(
                                text: secondaryLabel,
                                style: secondaryStyle,
                              ),
                              textDirection: textDirection,
                              maxLines: 1,
                              textScaler: MediaQuery.textScalerOf(context),
                            )..layout(maxWidth: double.infinity);
                            final secondaryHeight = secondaryPainter.height;

                            final bottomPad =
                                (maxH * 0.12).clamp(10.0, 18.0) * gapScale;

                            return Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                SizedBox(
                                  height:
                                      (maxH - gap - bottomPad - secondaryHeight)
                                          .clamp(0.0, maxH),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: identityBody(display),
                                    ),
                                  ),
                                ),
                                SizedBox(height: gap),
                                SizedBox(
                                  height: secondaryHeight,
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: maxW,
                                      ),
                                      child: AutoSizeText(
                                        secondaryLabel,
                                        textAlign: TextAlign.center,
                                        style: secondaryStyle,
                                        maxLines: 1,
                                        minFontSize: 6.0,
                                        maxFontSize:
                                            secondaryStyle.fontSize ?? 14.0,
                                        stepGranularity: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: bottomPad),
                              ],
                            );
                          },
                        )
                      : identityBody(display),
                ),
              )
            : showIdle
            ? KeyedSubtree(
                key: const ValueKey('idle_glyph'),
                child: Semantics(
                  container: true,
                  label: 'No notes detected',
                  hint: 'Play notes to identify a note, interval, or chord.',
                  child: ExcludeSemantics(child: idleGlyph()),
                ),
              )
            : KeyedSubtree(
                key: const ValueKey('placeholder'),
                child: Semantics(
                  container: true,
                  label: 'Waiting for input',
                  hint: 'Play notes to identify a note, interval, or chord.',
                  child: ExcludeSemantics(child: placeholderText(primaryStyle)),
                ),
              ),
      );
    }

    if (display == null) {
      // No identity; keep card inert.
      return Card(
        elevation: 0,
        color: cs.primary,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: minCardHeight),
          child: Padding(
            padding: padding,
            child: fill
                ? SizedBox.expand(child: switchedChild())
                : switchedChild(),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: cs.primary,
      child: InkWell(
        onTap: () => showAnalysisDetailsSheet(context, identity: display),
        borderRadius: cardBorderRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: minCardHeight),
          child: Padding(
            padding: padding,
            child: fill
                ? SizedBox.expand(child: switchedChild())
                : switchedChild(),
          ),
        ),
      ),
    );
  }
}

List<InlineSpan> buildChordSpans({
  required String text,
  required TextStyle base,
  required TextStyle parenStyle,
}) {
  // We expect `text` already has the correct chord string (root+quality+slash etc.).
  // This helper only styles parentheses differently.
  final spans = <InlineSpan>[];

  // Simple single-pass scan.
  final buf = StringBuffer();
  TextStyle currentStyle = base;

  void flush() {
    if (buf.isEmpty) return;
    spans.add(TextSpan(text: buf.toString(), style: currentStyle));
    buf.clear();
  }

  for (var i = 0; i < text.length; i++) {
    final ch = text[i];

    // Parentheses special styling.
    final isParen = ch == '(' || ch == ')';

    final nextStyle = isParen ? parenStyle : base;

    if (nextStyle != currentStyle) {
      flush();
      currentStyle = nextStyle;
    }

    buf.write(ch);
  }

  flush();
  return spans;
}
