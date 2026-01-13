import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/core/core.dart';
import 'package:what_chord/features/input/input.dart';
import 'package:what_chord/features/midi/midi.dart' show isPedalDownProvider;

import '../../models/active_note.dart';
import '../../providers/active_notes_provider.dart';
import 'note_chip.dart';
import 'pedal_indicator.dart';

class ActiveInput extends ConsumerStatefulWidget {
  const ActiveInput({super.key, required this.padding});
  final EdgeInsets padding;

  @override
  ConsumerState<ActiveInput> createState() => _ActiveInputState();
}

class _ActiveInputState extends ConsumerState<ActiveInput>
    with SingleTickerProviderStateMixin {
  final _notesKey = GlobalKey<SliverAnimatedListState>();

  late List<ActiveNote> _notes;
  late bool _pedal;

  ProviderSubscription<List<ActiveNote>>? _notesSubscription;
  ProviderSubscription<bool>? _pedalSubscription;

  late final AnimationController _pedalCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120), // press
    reverseDuration: const Duration(milliseconds: 90), // release
  );

  late final Animation<double> _press = CurvedAnimation(
    parent: _pedalCtl,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  // Mechanical travel: small downward press + settle.
  late final Animation<double> _travel = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: -6.0,
        end: 1.5,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 70,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.5,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 30,
    ),
  ]).animate(_press);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.25,
    end: 1.0,
  ).animate(_press);

  late final Animation<double> _scale = Tween<double>(
    begin: 0.98,
    end: 1.0,
  ).animate(_press);

  @override
  void initState() {
    super.initState();

    _notes = [...ref.read(activeNotesProvider)];
    _pedal = ref.read(isPedalDownProvider);
    _pedalCtl.value = _pedal ? 1.0 : 0.0;

    _notesSubscription = ref.listenManual<List<ActiveNote>>(
      activeNotesProvider,
      (prev, next) {
        if (!mounted) return;

        if (!listEquals(prev ?? const <ActiveNote>[], next)) {
          ref
              .read(appActivityProvider.notifier)
              .markActivity(ActivitySource.midi);
        }

        _applyNotesDiff(next);
      },
    );

    _pedalSubscription = ref.listenManual<bool>(isPedalDownProvider, (
      prev,
      next,
    ) {
      if (!mounted) return;

      setState(() => _pedal = next);

      // Interruptible: immediately retarget animation.
      if (next) {
        _pedalCtl.forward();
      } else {
        _pedalCtl.reverse();
      }
    });
  }

  @override
  void dispose() {
    _pedalCtl.dispose();
    _notesSubscription?.close();
    _pedalSubscription?.close();
    super.dispose();
  }

  void _applyNotesDiff(Iterable<ActiveNote> next) {
    final nextList = next is List<ActiveNote>
        ? next
        : next.toList(growable: false);
    final nextIdSet = {for (final n in nextList) n.id};
    final nextById = {for (final n in nextList) n.id: n};

    final currentIdSet = _notes.map((e) => e.id).toSet();

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

    for (int i = 0; i < nextList.length; i++) {
      final id = nextList[i].id;
      if (!currentIdSet.contains(id)) {
        _notes.insert(i, nextList[i]);
        currentIdSet.add(id);

        _notesKey.currentState?.insertItem(
          i,
          duration: const Duration(milliseconds: 140),
        );
      }
    }

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
    final showPrompt = _notes.isEmpty && ref.watch(inputIdleEligibleProvider);

    return Padding(
      padding: widget.padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minHeight),
        child: SizedBox(
          height: minHeight,
          child: showPrompt
              ? Row(
                  children: [
                    SizedBox(
                      width: PedalIndicator.slotWidth,
                      child: _buildAnimatedPedal(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Play some notes…',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : CustomScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: PedalIndicator.slotWidth,
                          child: _buildAnimatedPedal(),
                        ),
                      ),
                    ),
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
    return AnimatedBuilder(
      animation: _pedalCtl,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _travel.value),
            child: Transform.scale(
              scale: _scale.value,
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
        );
      },
      child: const Align(
        alignment: Alignment.centerLeft,
        child: PedalIndicator(),
      ),
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
