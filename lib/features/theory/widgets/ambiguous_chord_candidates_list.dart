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

    final tonality = ref.watch(
      analysisContextProvider.select((c) => c.tonality),
    );
    final chordStyle = ref.watch(chordSymbolStyleProvider);

    final base = theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final textStyle = base.copyWith(
      fontSize: (base.fontSize ?? 14) + 4,
      fontWeight: FontWeight.w800,
      color: cs.onSurface.withValues(alpha: 0.45),
      height: 1.18,
    );

    final visible = items.take(maxItems).toList(growable: false);

    return Padding(
      padding: padding,
      child: Align(
        alignment: alignment,
        child: ListView.separated(
          primary: false, // important for safety
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
