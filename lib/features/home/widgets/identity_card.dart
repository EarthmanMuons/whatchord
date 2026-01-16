import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:whatchord/features/theory/theory.dart';

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

    Future<void> showDetailsSheet(
      BuildContext context,
      IdentityDisplay d,
    ) async {
      final copyText = d.debugText?.trimRight();
      final canCopy = copyText != null && copyText.isNotEmpty;

      await showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) {
          final t = Theme.of(context);

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.80,
            builder: (context, controller) {
              return Material(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    Text('Analysis Details', style: t.textTheme.titleLarge),
                    const SizedBox(height: 16),

                    // Plain English
                    SelectableText(
                      d.longLabel,
                      style: t.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    if (!canCopy)
                      Text(
                        'No debug info available.',
                        style: t.textTheme.bodyMedium,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: t.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SelectableText(
                            copyText,
                            style: t.textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: canCopy
                                ? () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: copyText),
                                    );
                                  }
                                : null,
                            child: const Text('Copy as Text'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: null, // Future: JSON
                            child: const Text('Copy as JSON'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          );
        },
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
        onLongPress: () => showDetailsSheet(context, display),
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
