import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/audio/audio.dart';
import 'package:whatchord/features/input/input.dart';
import 'package:whatchord/features/theory/theory.dart';

class ChordMembersSection extends StatefulWidget {
  const ChordMembersSection({
    super.key,
    required this.members,
    required this.memberDegrees,
    required this.previewNotes,
    required this.activePitchClasses,
    required this.memberPitchClasses,
    required this.onPreviewStarted,
  });

  final List<String> members;
  final List<String> memberDegrees;
  final List<int> previewNotes;
  final Set<int> activePitchClasses;
  final List<int> memberPitchClasses;
  final ValueChanged<List<int>> onPreviewStarted;

  @override
  State<ChordMembersSection> createState() => _ChordMembersSectionState();
}

class _ChordMembersSectionState extends State<ChordMembersSection>
    with TickerProviderStateMixin {
  static const Duration _insertDuration = Duration(milliseconds: 140);
  static const Duration _removeDuration = Duration(milliseconds: 120);

  late List<_ExploreMemberChipEntry> _entries;
  bool _showDegrees = false;

  @override
  void initState() {
    super.initState();
    _entries = _createInitialEntries();
  }

  @override
  void didUpdateWidget(covariant ChordMembersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyMemberDiff();
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.controller.dispose();
    }
    super.dispose();
  }

  List<_ExploreMemberChipEntry> _createInitialEntries() {
    return [
      for (var i = 0; i < widget.members.length; i++)
        _ExploreMemberChipEntry(
          data: _memberDataAt(i),
          controller: AnimationController(
            vsync: this,
            duration: _insertDuration,
            reverseDuration: _removeDuration,
            value: 1.0,
          ),
        ),
    ];
  }

  _ExploreMemberChipData _memberDataAt(int index) {
    final pitchClass = index < widget.memberPitchClasses.length
        ? widget.memberPitchClasses[index]
        : null;
    final noteLabel = toGlyphAccidentals(widget.members[index]);
    final degreeLabel = index < widget.memberDegrees.length
        ? toGlyphAccidentals(widget.memberDegrees[index])
        : noteLabel;
    final id = pitchClass == null
        ? 'label:${widget.members[index]}'
        : 'pc:$pitchClass';

    return _ExploreMemberChipData(
      id: id,
      label: _showDegrees ? degreeLabel : noteLabel,
      alternateLabel: _showDegrees ? noteLabel : degreeLabel,
      semanticLabel: _showDegrees
          ? 'Chord member $noteLabel, degree $degreeLabel'
          : 'Chord member $noteLabel',
      active:
          pitchClass != null && widget.activePitchClasses.contains(pitchClass),
    );
  }

  void _applyMemberDiff() {
    final nextData = [
      for (var i = 0; i < widget.members.length; i++) _memberDataAt(i),
    ];
    final nextIds = {for (final data in nextData) data.id};
    final entriesById = {
      for (final entry in _entries)
        if (!entry.removing) entry.data.id: entry,
    };
    final nextEntries = <_ExploreMemberChipEntry>[];

    for (final data in nextData) {
      final existing = entriesById[data.id];
      if (existing != null) {
        existing.data = data;
        nextEntries.add(existing);
        continue;
      }

      final entry = _ExploreMemberChipEntry(
        data: data,
        controller: AnimationController(
          vsync: this,
          duration: _insertDuration,
          reverseDuration: _removeDuration,
        ),
      );
      nextEntries.add(entry);
      unawaited(entry.controller.forward());
    }

    for (final entry in _entries) {
      if (entry.removing || nextIds.contains(entry.data.id)) continue;

      entry.removing = true;
      unawaited(
        entry.controller.reverse().whenComplete(() {
          if (!mounted) return;
          setState(() {
            _entries.remove(entry);
          });
          entry.controller.dispose();
        }),
      );

      final oldIndex = _entries.indexOf(entry);
      final insertIndex = oldIndex.clamp(0, nextEntries.length);
      nextEntries.insert(insertIndex, entry);
    }

    setState(() {
      _entries = nextEntries;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Chord members',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ExplorePlayButton(
                previewNotes: widget.previewNotes,
                onPreviewStarted: widget.onPreviewStarted,
              ),
              const SizedBox(width: 4),
              _MemberDisplayModeButton(
                showDegrees: _showDegrees,
                onPressed: () {
                  setState(() {
                    _showDegrees = !_showDegrees;
                  });
                  _applyMemberDiff();
                },
              ),
            ],
          ),
          for (final entry in _entries)
            _AnimatedExploreMemberChip(
              key: ValueKey(entry.data.id),
              entry: entry,
            ),
        ],
      ),
    );
  }
}

class _ExploreMemberChipData {
  const _ExploreMemberChipData({
    required this.id,
    required this.label,
    required this.alternateLabel,
    required this.semanticLabel,
    required this.active,
  });

  final String id;
  final String label;
  final String alternateLabel;
  final String semanticLabel;
  final bool active;
}

class _ExploreMemberChipEntry {
  _ExploreMemberChipEntry({required this.data, required this.controller});

  _ExploreMemberChipData data;
  final AnimationController controller;
  bool removing = false;
}

class _AnimatedExploreMemberChip extends StatelessWidget {
  const _AnimatedExploreMemberChip({super.key, required this.entry});

  final _ExploreMemberChipEntry entry;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: entry.controller,
      curve: Curves.easeOutCubic,
    );

    return SizeTransition(
      sizeFactor: curved,
      axis: Axis.horizontal,
      child: FadeTransition(
        opacity: curved,
        child: _ExploreMemberChip(
          label: entry.data.label,
          alternateLabel: entry.data.alternateLabel,
          semanticLabel: entry.data.semanticLabel,
          active: entry.data.active,
        ),
      ),
    );
  }
}

class _ExplorePlayButton extends ConsumerWidget {
  const _ExplorePlayButton({
    required this.previewNotes,
    required this.onPreviewStarted,
  });

  final List<int> previewNotes;
  final ValueChanged<List<int>> onPreviewStarted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    void playChord() {
      onPreviewStarted(previewNotes);
      ref
          .read(audioMonitorNotifier.notifier)
          .playRolledPreviewNotes(previewNotes);
    }

    return Semantics(
      button: true,
      label: 'Play chord',
      onTapHint: 'Play the current Explore chord',
      onTap: playChord,
      child: Tooltip(
        message: 'Play chord',
        child: ExcludeSemantics(
          child: IconButton.filledTonal(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            style: IconButton.styleFrom(
              fixedSize: const Size.square(48),
              shape: const CircleBorder(),
              backgroundColor: cs.secondaryContainer,
              foregroundColor: cs.onSecondaryContainer,
            ),
            onPressed: playChord,
            icon: const Icon(Icons.play_arrow),
          ),
        ),
      ),
    );
  }
}

class _MemberDisplayModeButton extends StatelessWidget {
  const _MemberDisplayModeButton({
    required this.showDegrees,
    required this.onPressed,
  });

  final bool showDegrees;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final value = showDegrees ? 'Degrees' : 'Note names';
    final tooltip = showDegrees ? 'Show note names' : 'Show chord degrees';
    final activeStyle = theme.textTheme.labelSmall?.copyWith(
      color: cs.onSurface,
      fontWeight: FontWeight.w800,
      height: 1.0,
    );
    final inactiveStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.disabledColor,
      fontWeight: FontWeight.w500,
      height: 1.0,
    );

    return Semantics(
      button: true,
      label: 'Chord member display',
      value: value,
      onTap: onPressed,
      onTapHint: tooltip,
      child: Tooltip(
        message: tooltip,
        child: ExcludeSemantics(
          child: InkResponse(
            containedInkWell: false,
            highlightShape: BoxShape.circle,
            radius: 24,
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 48,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'name',
                      strutStyle: const StrutStyle(
                        fontSize: 11,
                        height: 1.0,
                        forceStrutHeight: true,
                      ),
                      style: showDegrees ? inactiveStyle : activeStyle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'deg',
                      strutStyle: const StrutStyle(
                        fontSize: 11,
                        height: 1.0,
                        forceStrutHeight: true,
                      ),
                      style: showDegrees ? activeStyle : inactiveStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreMemberChip extends StatelessWidget {
  const _ExploreMemberChip({
    required this.label,
    required this.alternateLabel,
    required this.semanticLabel,
    required this.active,
  });

  final String label;
  final String alternateLabel;
  final String semanticLabel;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sizeScale = InputDisplaySizing.noteScale(context);
    final verticalScale = InputDisplaySizing.noteVerticalScale(context);

    final labelStyle = theme.textTheme.titleMedium?.copyWith(
      color: active ? cs.onPrimaryContainer : cs.onSurface,
      fontWeight: active ? FontWeight.w700 : null,
    );
    final fontSize = labelStyle?.fontSize ?? 16.0;
    final defaultHeight = labelStyle?.height ?? 1.2;
    final extraVertical = ((defaultHeight - 1.0) * fontSize / 2).clamp(
      0.0,
      8.0,
    );
    final labelStrut = StrutStyle(
      fontSize: fontSize,
      height: 1.0,
      forceStrutHeight: true,
    );
    final horizontalPadding = 10 * sizeScale;
    final chipTextWidth = math.max(
      _measureLabelWidth(context, label, labelStyle),
      _measureLabelWidth(context, alternateLabel, labelStyle),
    );

    return Semantics(
      container: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 340),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return _ExploreMemberChipFlipTransition(
              animation: animation,
              incoming: child.key == ValueKey(label),
              child: child,
            );
          },
          child: AnimatedContainer(
            key: ValueKey(label),
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: active ? cs.primaryContainer : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10 * sizeScale),
              border: Border.all(
                color: active
                    ? cs.primary.withValues(alpha: 0.82)
                    : cs.outlineVariant.withValues(alpha: 0.60),
                width: active ? 1.6 : 1.0,
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: (6 * verticalScale) + extraVertical,
            ),
            child: SizedBox(
              width: chipTextWidth,
              child: Text(
                label,
                strutStyle: labelStrut,
                style: labelStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _measureLabelWidth(
    BuildContext context,
    String text,
    TextStyle? style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return painter.width;
  }
}

class _ExploreMemberChipFlipTransition extends StatelessWidget {
  const _ExploreMemberChipFlipTransition({
    required this.animation,
    required this.incoming,
    required this.child,
  });

  final Animation<double> animation;
  final bool incoming;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final value = animation.value;
        final angle = (incoming ? 1 - value : value - 1) * (math.pi / 2);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(angle),
          child: child,
        );
      },
    );
  }
}
