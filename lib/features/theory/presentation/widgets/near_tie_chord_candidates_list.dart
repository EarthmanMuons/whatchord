import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers/analysis_context_provider.dart';
import '../../state/providers/chord_candidates_providers.dart';
import '../../state/providers/theory_preferences_notifier.dart';
import '../services/chord_long_form_formatter.dart';
import '../services/chord_symbol_builder.dart';

class NearTieChordCandidatesList extends ConsumerStatefulWidget {
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
    this.showScrollbarWhenOverflow = false,
  });

  final bool enabled;
  final Axis axis;
  final int maxItems;
  final EdgeInsets padding;
  final double gap;
  final Alignment alignment;
  final TextAlign textAlign;
  final TextStyle? styleOverride;
  final bool showScrollbarWhenOverflow;

  @override
  ConsumerState<NearTieChordCandidatesList> createState() =>
      _NearTieChordCandidatesListState();
}

class _NearTieChordCandidatesListState
    extends ConsumerState<NearTieChordCandidatesList> {
  late final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final alternatives = widget.enabled
        ? ref.watch(nearTieChordCandidatesProvider)
        : const [];

    final tonality = ref.watch(
      analysisContextProvider.select((c) => c.tonality),
    );
    final notation = ref.watch(chordNotationStyleProvider);

    final base =
        widget.styleOverride ??
        theme.textTheme.bodyMedium ??
        const TextStyle(fontSize: 14);
    final textStyle = base.copyWith(
      fontSize: (base.fontSize ?? 14) + 4,
      fontWeight: FontWeight.w800,
      color: cs.onSurface.withValues(alpha: 0.45),
      height: 1.18,
    );

    final visible = alternatives.take(widget.maxItems).toList(growable: false);
    final hasContent = widget.enabled && visible.isNotEmpty;

    Widget content() {
      final list = ListView.separated(
        key: const ValueKey(
          'ambiguous_list',
        ), // stable key for the "present" state
        primary: false,
        padding: widget.padding,
        shrinkWrap:
            !(widget.axis == Axis.vertical && widget.showScrollbarWhenOverflow),
        controller: _scrollController,
        scrollDirection: widget.axis,
        itemCount: visible.length,
        separatorBuilder: (_, _) => widget.axis == Axis.vertical
            ? SizedBox(height: widget.gap)
            : SizedBox(width: widget.gap),
        itemBuilder: (context, i) {
          final c = visible[i];
          final symbol = ChordSymbolBuilder.fromIdentity(
            identity: c.identity,
            tonality: tonality,
            notation: notation,
          );
          final spokenLabel = ChordLongFormFormatter.format(
            identity: c.identity,
            tonality: tonality,
          );

          return Text(
            symbol.toString(),
            semanticsLabel: spokenLabel,
            style: textStyle,
            textAlign: widget.textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          );
        },
      );

      return Align(
        alignment: widget.alignment,
        child: widget.showScrollbarWhenOverflow && widget.axis == Axis.vertical
            ? Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: list,
              )
            : list,
      );
    }

    // Empty state must still occupy an animatable child.
    // Using a SizedBox with a key ensures AnimatedSwitcher recognizes changes.
    Widget empty() => const SizedBox(key: ValueKey('ambiguous_empty'));

    return Semantics(
      container: true,
      label: 'Alternative chord candidates',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 120),
        reverseDuration: const Duration(milliseconds: 90),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,

        layoutBuilder: (currentChild, previousChildren) {
          final stackAlignment = widget.axis == Axis.vertical
              ? Alignment.topCenter
              : Alignment.centerLeft;

          return Stack(
            alignment: stackAlignment,
            children: [for (final c in previousChildren) c, ?currentChild],
          );
        },

        transitionBuilder: (child, animation) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );

          return FadeTransition(
            opacity: fade,
            child: ClipRect(
              child: SizeTransition(
                sizeFactor: animation,
                axis: widget.axis,
                axisAlignment: -1.0,
                child: child,
              ),
            ),
          );
        },

        child: hasContent ? content() : empty(),
      ),
    );
  }
}
