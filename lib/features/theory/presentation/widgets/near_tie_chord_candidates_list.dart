import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers/analysis_context_provider.dart';
import '../../state/providers/chord_candidates_providers.dart';
import '../../state/providers/theory_preferences_notifier.dart';
import '../services/chord_symbol_builder.dart';

class NearTieChordCandidatesList extends ConsumerWidget {
  const NearTieChordCandidatesList({
    super.key,
    this.enabled = true,
    this.axis = Axis.vertical,
    this.maxItems = 3,
    this.padding = EdgeInsets.zero,
    this.gap = 4.0,
    this.alignment = Alignment.center,
    this.textAlign = TextAlign.center,
    this.styleOverride,
  });

  final bool enabled;
  final Axis axis;
  final int maxItems;
  final EdgeInsets padding;
  final double gap;
  final Alignment alignment;
  final TextAlign textAlign;
  final TextStyle? styleOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final alternatives = enabled
        ? ref.watch(nearTieChordCandidatesProvider)
        : const [];

    final tonality = ref.watch(
      analysisContextProvider.select((c) => c.tonality),
    );
    final notation = ref.watch(chordNotationStyleProvider);

    final base =
        styleOverride ??
        theme.textTheme.bodyMedium ??
        const TextStyle(fontSize: 14);
    final textStyle = base.copyWith(
      fontSize: (base.fontSize ?? 14) + 4,
      fontWeight: FontWeight.w800,
      color: cs.onSurface.withValues(alpha: 0.45),
      height: 1.18,
    );

    final visible = alternatives.take(maxItems).toList(growable: false);
    final hasContent = enabled && visible.isNotEmpty;

    Widget content() {
      return Padding(
        padding: padding,
        child: Align(
          alignment: alignment,
          child: ListView.separated(
            key: const ValueKey(
              'ambiguous_list',
            ), // stable key for the "present" state
            primary: false,
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            scrollDirection: axis,
            itemCount: visible.length,
            separatorBuilder: (_, _) => axis == Axis.vertical
                ? SizedBox(height: gap)
                : SizedBox(width: gap),
            itemBuilder: (context, i) {
              final c = visible[i];
              final symbol = ChordSymbolBuilder.fromIdentity(
                identity: c.identity,
                tonality: tonality,
                notation: notation,
              );

              return Text(
                symbol.toString(),
                style: textStyle,
                textAlign: textAlign,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              );
            },
          ),
        ),
      );
    }

    // Empty state must still occupy an animatable child.
    // Using a SizedBox with a key ensures AnimatedSwitcher recognizes changes.
    Widget empty() => const SizedBox(key: ValueKey('ambiguous_empty'));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 90),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,

      layoutBuilder: (currentChild, previousChildren) {
        final stackAlignment = axis == Axis.vertical
            ? Alignment.topCenter
            : Alignment.centerLeft;

        return Stack(
          alignment: stackAlignment,
          children: [for (final c in previousChildren) c, ?currentChild],
        );
      },

      transitionBuilder: (child, animation) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

        return FadeTransition(
          opacity: fade,
          child: ClipRect(
            child: SizeTransition(
              sizeFactor: animation,
              axis: axis,
              axisAlignment: -1.0,
              child: child,
            ),
          ),
        );
      },

      child: hasContent ? content() : empty(),
    );
  }
}
