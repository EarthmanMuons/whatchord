import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/history/history.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../models/inferred_key_state.dart';
import '../providers/inferred_key_notifier.dart';

/// The evidence trail: chords the detector is currently listening to, newest
/// on the left, older sliding right and off into the scroll. Cleared when
/// the detector forgets (the two-minute reset), so nothing on screen looks
/// like it still contributes when it does not.
class RecentChordsStrip extends ConsumerStatefulWidget {
  const RecentChordsStrip({super.key, this.maxChords = 24});

  final int maxChords;

  @override
  ConsumerState<RecentChordsStrip> createState() => _RecentChordsStripState();
}

class _RecentChordsStripState extends ConsumerState<RecentChordsStrip> {
  final _listKey = GlobalKey<AnimatedListState>();
  final _scrollController = ScrollController();
  final List<ChordEvent> _events = []; // newest first
  var _generation = 0;
  var _showLeftFade = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final scrolled =
          _scrollController.hasClients && _scrollController.offset > 4;
      if (scrolled != _showLeftFade) {
        setState(() => _showLeftFade = scrolled);
      }
    });
    // Seed from the events already contributing to the current belief (the
    // page can open mid-session).
    final inferred = ref.read(inferredKeyProvider);
    if (inferred.freshness != InferredKeyFreshness.none) {
      final since = inferred.resetAt;
      final history = ref.read(chordHistoryProvider);
      _events.addAll(
        history
            .where((e) => since == null || e.timestamp.isAfter(since))
            .toList()
            .reversed
            .take(widget.maxChords),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(chordHistoryProvider, _onHistory);
    ref.listen(inferredKeyProvider.select((state) => state.freshness), (
      previous,
      next,
    ) {
      if (next == InferredKeyFreshness.none) _clear();
    });

    final notation = ref.watch(chordNotationStyleProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final empty = _events.isEmpty;

    // Height stays reserved even before the first chord arrives so the rest
    // of the page does not reflow when the strip appears.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedOpacity(
          opacity: empty ? 0 : 1,
          duration: const Duration(milliseconds: 400),
          child: Text(
            'Recent chords',
            style: theme.textTheme.titleSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: empty
                ? const SizedBox.expand()
                : ShaderMask(
                    key: ValueKey('strip$_generation'),
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        _showLeftFade ? Colors.transparent : Colors.white,
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: const [0, 0.06, 0.92, 1],
                    ).createShader(bounds),
                    blendMode: BlendMode.dstIn,
                    child: AnimatedList(
                      key: _listKey,
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      // Without explicit padding a scrollable adopts the
                      // ambient safe-area insets, indenting the newest chip
                      // in landscape.
                      padding: EdgeInsets.zero,
                      initialItemCount: _events.length,
                      itemBuilder: (context, index, animation) =>
                          _chip(context, _events[index], animation, notation),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    ChordEvent event,
    Animation<double> animation,
    ChordNotationStyle notation,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final eased = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    return SizeTransition(
      sizeFactor: eased,
      axis: Axis.horizontal,
      child: FadeTransition(
        opacity: eased,
        child: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Text(
              ChordSymbolBuilder.formatIdentity(
                identity: event.identity,
                tonality: event.tonality,
                notation: notation,
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }

  void _onHistory(List<ChordEvent>? previous, List<ChordEvent> next) {
    if (next.isEmpty) return; // reset handled via freshness
    if (previous != null &&
        previous.isNotEmpty &&
        identical(previous.last, next.last)) {
      return;
    }
    setState(() {
      _events.insert(0, next.last);
    });
    _listKey.currentState?.insertItem(
      0,
      duration: const Duration(milliseconds: 350),
    );
    if (_events.length > widget.maxChords) {
      final removeIndex = _events.length - 1;
      _events.removeLast();
      _listKey.currentState?.removeItem(
        removeIndex,
        (context, animation) => const SizedBox.shrink(),
        duration: Duration.zero,
      );
    }
  }

  void _clear() {
    if (_events.isEmpty) return;
    setState(() {
      _events.clear();
      _generation += 1; // rebuild the AnimatedList empty
    });
  }
}
