import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/core.dart';

import '../../models/sounding_note.dart';
import '../../providers/input_idle_notifier.dart';
import '../../providers/pedal_state_provider.dart';
import '../../providers/sounding_notes_provider.dart';
import 'input_display_sizing.dart';
import 'note_chip.dart';
import 'pedal_indicator.dart';

class InputDisplay extends ConsumerStatefulWidget {
  const InputDisplay({super.key, required this.padding});
  final EdgeInsets padding;

  @override
  ConsumerState<InputDisplay> createState() => _InputDisplayState();
}

class _InputDisplayState extends ConsumerState<InputDisplay>
    with SingleTickerProviderStateMixin {
  final _notesKey = GlobalKey<SliverAnimatedListState>();
  final _scrollController = ScrollController();
  static const double _fadeWidth = 24.0;

  late List<SoundingNote> _notes;
  late bool _pedal;
  bool _showLeadingFade = false;
  bool _showTrailingFade = false;

  ProviderSubscription<List<SoundingNote>>? _notesSubscription;
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

    _notes = [...ref.read(soundingNotesProvider)];
    _pedal = ref.read(inputPedalStateProvider).isDown;
    _pedalCtl.value = _pedal ? 1.0 : 0.0;
    _scrollController.addListener(_updateScrollFade);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateScrollFade();
    });

    _notesSubscription = ref.listenManual<List<SoundingNote>>(
      soundingNotesProvider,
      (prev, next) {
        if (!mounted) return;

        if (!listEquals(prev ?? const <SoundingNote>[], next)) {
          ref
              .read(appActivityProvider.notifier)
              .markActivity(AppActivitySource.midi);
        }

        _applyNotesDiff(next);
      },
    );

    _pedalSubscription = ref.listenManual<bool>(
      inputPedalStateProvider.select((s) => s.isDown),
      (prev, next) {
        if (!mounted) return;

        setState(() => _pedal = next);

        // Interruptible: immediately retarget animation.
        if (next) {
          _pedalCtl.forward();
        } else {
          _pedalCtl.reverse();
        }
      },
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollFade);
    _scrollController.dispose();
    _pedalCtl.dispose();
    _notesSubscription?.close();
    _pedalSubscription?.close();
    super.dispose();
  }

  void _updateScrollFade() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;

    const epsilon = 0.5;
    final maxExtent = position.maxScrollExtent;
    final pixels = position.pixels;
    final nextLeading = maxExtent > epsilon && pixels > epsilon;
    final nextTrailing = maxExtent > epsilon && pixels < maxExtent - epsilon;

    if (nextLeading == _showLeadingFade && nextTrailing == _showTrailingFade) {
      return;
    }

    setState(() {
      _showLeadingFade = nextLeading;
      _showTrailingFade = nextTrailing;
    });
  }

  void _applyNotesDiff(Iterable<SoundingNote> next) {
    final nextList = next is List<SoundingNote>
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateScrollFade();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final pedalSlotWidth = PedalIndicator.slotWidthFor(context);
    final heightScale = InputDisplaySizing.rowHeightScale(context);

    final scaledMinHeight = 44.0 * heightScale;
    final minHeight = scaledMinHeight < 48.0 ? 48.0 : scaledMinHeight;
    final showPrompt = _notes.isEmpty && ref.watch(inputIdleEligibleProvider);

    return Padding(
      padding: widget.padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: SizedBox(
          height: minHeight,
          child: showPrompt
              ? Row(
                  children: [
                    SizedBox(
                      width: pedalSlotWidth,
                      child: _buildAnimatedPedal(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _updateScrollFade();
                          });

                          return Stack(
                            children: [
                              SingleChildScrollView(
                                controller: _scrollController,
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Play some notes…',
                                    semanticsLabel: 'Play some notes',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              if (_showLeadingFade)
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: _fadeWidth,
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            cs.surface,
                                            cs.surface.withValues(alpha: 0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (_showTrailingFade)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: _fadeWidth,
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerRight,
                                          end: Alignment.centerLeft,
                                          colors: [
                                            cs.surface,
                                            cs.surface.withValues(alpha: 0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _updateScrollFade();
                    });

                    return Stack(
                      children: [
                        CustomScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: SizedBox(
                                  width: pedalSlotWidth,
                                  child: _buildAnimatedPedal(),
                                ),
                              ),
                            ),
                            SliverAnimatedList(
                              key: _notesKey,
                              initialItemCount: _notes.length,
                              itemBuilder: (context, index, animation) {
                                final note = _notes[index];
                                return _buildPaddedAnimatedNoteChip(
                                  note,
                                  animation,
                                );
                              },
                            ),
                          ],
                        ),
                        if (_showLeadingFade)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: _fadeWidth,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      cs.surface,
                                      cs.surface.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (_showTrailingFade)
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            width: _fadeWidth,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                    colors: [
                                      cs.surface,
                                      cs.surface.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
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
    SoundingNote note,
    Animation<double> animation,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: _buildAnimatedNoteChip(note, animation),
    );
  }

  Widget _buildAnimatedNoteChip(
    SoundingNote note,
    Animation<double> animation,
  ) {
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
