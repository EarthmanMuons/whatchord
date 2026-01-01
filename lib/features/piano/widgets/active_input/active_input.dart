import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final _listKey = GlobalKey<AnimatedListState>();
  late List<ActiveNote> _notes;
  late bool _pedal;
  ProviderSubscription<List<ActiveNote>>? _notesSub;
  ProviderSubscription<bool>? _pedalSub;

  @override
  void initState() {
    super.initState();

    _notes = ref.read(activeNotesProvider);
    _pedal = ref.read(isPedalDownProvider);

    _notesSub = ref.listenManual<List<ActiveNote>>(activeNotesProvider, (
      prev,
      next,
    ) {
      if (!mounted) return;
      _applyNotesDiff(next);
    });

    _pedalSub = ref.listenManual<bool>(isPedalDownProvider, (prev, next) {
      if (!mounted) return;
      setState(() => _pedal = next);
    });
  }

  @override
  void dispose() {
    _notesSub?.close();
    _pedalSub?.close();
    super.dispose();
  }

  void _applyNotesDiff(List<ActiveNote> next) {
    final nextIdSet = next.map((e) => e.id).toSet();
    final currentIdSet = _notes.map((e) => e.id).toSet();

    final nextById = <String, ActiveNote>{for (final n in next) n.id: n};

    // Remove notes that no longer exist
    for (int i = _notes.length - 1; i >= 0; i--) {
      final id = _notes[i].id;
      if (!nextIdSet.contains(id)) {
        final removed = _notes.removeAt(i);
        currentIdSet.remove(id);
        _listKey.currentState?.removeItem(
          // Offset by 1 if pedal is showing
          _pedal ? i + 1 : i,
          (context, animation) => _buildAnimatedNoteChip(removed, animation),
          duration: const Duration(milliseconds: 120),
        );
      }
    }

    // Insert new notes
    for (int i = 0; i < next.length; i++) {
      final id = next[i].id;
      if (!currentIdSet.contains(id)) {
        _notes.insert(i, next[i]);
        currentIdSet.add(id);
        _listKey.currentState?.insertItem(
          // Offset by 1 if pedal is showing
          _pedal ? i + 1 : i,
          duration: const Duration(milliseconds: 140),
        );
      }
    }

    // Update existing notes in-place (for pressed <-> sustained transitions)
    setState(() {
      for (int i = 0; i < _notes.length; i++) {
        final updated = nextById[_notes[i].id];
        if (updated != null) {
          _notes[i] = updated;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    const minHeight = 44.0;

    final showPrompt = _notes.isEmpty && !_pedal;

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
                child: AnimatedList(
                  key: _listKey,
                  initialItemCount: _pedal ? _notes.length + 1 : _notes.length,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index, animation) {
                    // Pedal always at index 0 when showing
                    if (_pedal && index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildAnimatedPedalIndicator(animation),
                      );
                    }

                    final noteIndex = _pedal ? index - 1 : index;
                    final note = _notes[noteIndex];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildAnimatedNoteChip(note, animation),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildAnimatedPedalIndicator(Animation<double> animation) {
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
          child: const PedalIndicator(key: ValueKey('sustain')),
        ),
      ),
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
