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
  final List<ChordEvent> _events = []; // newest first
  var _generation = 0;

  @override
  void initState() {
    super.initState();
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _events.isEmpty
          ? const SizedBox.shrink()
          : Column(
              key: ValueKey('strip$_generation'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent chords',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Colors.white, Colors.transparent],
                      stops: [0, 0.92, 1],
                    ).createShader(bounds),
                    blendMode: BlendMode.dstIn,
                    child: AnimatedList(
                      key: _listKey,
                      scrollDirection: Axis.horizontal,
                      initialItemCount: _events.length,
                      itemBuilder: (context, index, animation) =>
                          _chip(context, _events[index], animation, notation),
                    ),
                  ),
                ),
              ],
            ),
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
