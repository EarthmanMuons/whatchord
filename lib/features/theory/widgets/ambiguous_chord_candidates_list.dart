import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ambiguous_chord_candidates_provider.dart';
import '../providers/analysis_context_provider.dart';
import '../providers/chord_symbol_style_notifier.dart';
import '../services/chord_symbol_formatter.dart';

class AmbiguousChordCandidatesList extends ConsumerWidget {
  const AmbiguousChordCandidatesList({
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

  /// Optional explicit style if you want to control size per placement.
  final TextStyle? styleOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return const SizedBox.shrink();

    final items = ref.watch(ambiguousChordCandidatesProvider);
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final analysisContext = ref.watch(analysisContextProvider);
    final tonality = analysisContext.tonality;
    final chordStyle = ref.watch(chordSymbolStyleProvider);

    final textStyle =
        styleOverride ??
        (const TextStyle(fontSize: 18)).copyWith(
          color: cs.onSurface.withValues(alpha: 0.45),
          height: 1.18,
          fontWeight: FontWeight.w800,
        );

    final visible = items.take(maxItems).toList(growable: false);

    return Padding(
      padding: padding,
      child: Align(
        alignment: alignment,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: visible.length,
          separatorBuilder: (_, _) => SizedBox(height: gap),
          itemBuilder: (context, i) {
            final c = visible[i];
            final symbol = ChordSymbolFormatter.fromIdentity(
              identity: c.identity,
              tonality: tonality,
              style: chordStyle,
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
}
