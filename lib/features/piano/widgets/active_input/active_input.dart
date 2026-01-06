import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/core/activity/activity_tracker.dart';
import 'package:what_chord/core/activity/midi_activity_tracker.dart';
import 'package:what_chord/features/midi/midi.dart'
    show activeNotesProvider, isPedalDownProvider;

import '../../models/active_note.dart';
import 'note_chip.dart';
import 'pedal_indicator.dart';

class ActiveInput extends ConsumerStatefulWidget {
  const ActiveInput({super.key, required this.padding});
  final EdgeInsets padding;

  @override
  ConsumerState<ActiveInput> createState() => _ActiveInputState();
}

class _ActiveInputState extends ConsumerState<ActiveInput> {
  final _notesKey = GlobalKey<SliverAnimatedListState>();

  late List<ActiveNote> _notes;
  late bool _pedal;

  ProviderSubscription<List<ActiveNote>>? _notesSubscription;
  ProviderSubscription<bool>? _pedalSubscription;

  @override
  void initState() {
    super.initState();

    _notes = ref.read(activeNotesProvider);
    _pedal = ref.read(isPedalDownProvider);

    _notesSubscription = ref.listenManual<List<ActiveNote>>(activeNotesProvider, (
      prev,
      next,
    ) {
      if (!mounted) return;

      // Any change in notes counts as activity (note on/off, sustain changes, etc.)
      if (!listEquals(prev ?? const <ActiveNote>[], next)) {
        ref
            .read(activityTrackerProvider.notifier)
            .markActivity(ActivitySource.midi);
      }

      _applyNotesDiff(next);
    });

    _pedalSubscription = ref.listenManual<bool>(isPedalDownProvider, (
      prev,
      next,
    ) {
      if (!mounted) return;

      if ((prev ?? false) != next) {
        ref
            .read(activityTrackerProvider.notifier)
            .markActivity(ActivitySource.midi);
      }

      setState(() => _pedal = next);
    });
  }

  @override
  void dispose() {
    _notesSubscription?.close();
    _pedalSubscription?.close();
    super.dispose();
  }

  void _applyNotesDiff(List<ActiveNote> next) {
    final nextIdSet = next.map((e) => e.id).toSet();
    final currentIdSet = _notes.map((e) => e.id).toSet();
    final nextById = <String, ActiveNote>{for (final n in next) n.id: n};

    // 1) Remove notes that no longer exist (reverse order keeps indices valid).
    for (int i = _notes.length - 1; i >= 0; i--) {
      final id = _notes[i].id;
      if (!nextIdSet.contains(id)) {
        final removed = _notes.removeAt(i);
        currentIdSet.remove(id);

        _notesKey.currentState?.removeItem(
          i,
          (context, animation) =>
              _buildPaddedAnimatedNoteChip(removed, animation),
          duration: const Duration(milliseconds: 120),
        );
      }
    }

    // 2) Insert new notes at their target indices.
    for (int i = 0; i < next.length; i++) {
      final id = next[i].id;
      if (!currentIdSet.contains(id)) {
        _notes.insert(i, next[i]);
        currentIdSet.add(id);

        _notesKey.currentState?.insertItem(
          i,
          duration: const Duration(milliseconds: 140),
        );
      }
    }

    // 3) Update existing notes in-place (pressed <-> sustained transitions).
    setState(() {
      for (int i = 0; i < _notes.length; i++) {
        final updated = nextById[_notes[i].id];
        if (updated != null) _notes[i] = updated;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    const minHeight = 44.0;
    final showPrompt =
        _notes.isEmpty && !_pedal && ref.watch(midiIdleEligibleProvider);

    return Padding(
      padding: widget.padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minHeight),
        child: showPrompt
            ? Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Play some notes…',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              )
            : SizedBox(
                height: minHeight,
                child: CustomScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Pedal sliver: exists independently of note indices.
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildAnimatedPedal(),
                      ),
                    ),

                    // Notes sliver: pure note list, no offset math.
                    SliverAnimatedList(
                      key: _notesKey,
                      initialItemCount: _notes.length,
                      itemBuilder: (context, index, animation) {
                        final note = _notes[index];
                        return _buildPaddedAnimatedNoteChip(note, animation);
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAnimatedPedal() {
    // Keep the pedal animation local to the pedal; no impact on note indices.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 140),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SizeTransition(
          sizeFactor: curved,
          axis: Axis.horizontal,
          child: FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-0.20, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          ),
        );
      },
      child: _pedal
          ? const PedalIndicator(key: ValueKey('sustain'))
          : const SizedBox.shrink(key: ValueKey('no-sustain')),
    );
  }

  Widget _buildPaddedAnimatedNoteChip(
    ActiveNote note,
    Animation<double> animation,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: _buildAnimatedNoteChip(note, animation),
    );
  }

  Widget _buildAnimatedNoteChip(ActiveNote note, Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    return SizeTransition(
      sizeFactor: curved,
      axis: Axis.horizontal,
      child: FadeTransition(
        opacity: curved,
        child: NoteChip(key: ValueKey(note.id), note: note),
      ),
    );
  }
}
