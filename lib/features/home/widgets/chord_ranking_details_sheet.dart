import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/core.dart';
import 'package:whatchord/features/chords/chords.dart';
import 'package:whatchord/features/theory/theory.dart';

import 'adaptive_side_sheet.dart';

class ChordRankingDetailsSnapshot {
  ChordRankingDetailsSnapshot._({
    required List<RankedCandidateDebug> candidates,
    required this.tonality,
    required this.notation,
    required this.noteNameSystem,
  }) : candidates = List.unmodifiable(candidates);

  factory ChordRankingDetailsSnapshot.capture(WidgetRef ref) {
    return ChordRankingDetailsSnapshot._(
      candidates: ref.read(rankedChordCandidateDebugProvider),
      tonality: ref.read(analysisContextProvider).tonality,
      notation: ref.read(chordNotationStyleProvider),
      noteNameSystem: ref.read(noteNameSystemProvider),
    );
  }

  final List<RankedCandidateDebug> candidates;
  final Tonality tonality;
  final ChordNotationStyle notation;
  final NoteNameSystem noteNameSystem;
}

Future<void> showChordRankingDetailsSheet(
  BuildContext context, {
  required ChordRankingDetailsSnapshot snapshot,
}) async {
  if (useHomeSideSheet(context)) {
    await showHomeSideSheet<void>(
      context: context,
      barrierLabel: 'Dismiss chord ranking details',
      builder: (_) => _ChordRankingDetailsContent(
        snapshot: snapshot,
        showCloseButton: true,
      ),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final mq = MediaQuery.of(context);
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mq.size.height * 0.75),
        child: _ChordRankingDetailsContent(snapshot: snapshot),
      );
    },
  );
}

class _ChordRankingDetailsContent extends StatelessWidget {
  const _ChordRankingDetailsContent({
    required this.snapshot,
    this.showCloseButton = false,
  });

  final ChordRankingDetailsSnapshot snapshot;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isSideSheet = showCloseButton;

    return Material(
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: isSideSheet
            ? const EdgeInsets.fromLTRB(0, 0, 0, 16)
            : const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isSideSheet)
              const ModalPanelHeader(
                title: 'Why This Chord?',
                showCloseButton: true,
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  header: true,
                  child: Text(
                    'Why This Chord?',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isSideSheet ? 16 : 0),
                child: snapshot.candidates.isEmpty
                    ? const _EmptyRankingDetails()
                    : _RankingDetailsBody(
                        candidates: snapshot.candidates,
                        tonality: snapshot.tonality,
                        notation: snapshot.notation,
                        noteNameSystem: snapshot.noteNameSystem,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingDetailsBody extends StatefulWidget {
  const _RankingDetailsBody({
    required this.candidates,
    required this.tonality,
    required this.notation,
    required this.noteNameSystem,
  });

  final List<RankedCandidateDebug> candidates;
  final Tonality tonality;
  final ChordNotationStyle notation;
  final NoteNameSystem noteNameSystem;

  @override
  State<_RankingDetailsBody> createState() => _RankingDetailsBodyState();
}

class _RankingDetailsBodyState extends State<_RankingDetailsBody> {
  final _cardKeys = List.generate(
    5,
    (_) => GlobalKey<_CandidateRankCardState>(),
  );

  void _toggleAllCards() {
    for (final key in _cardKeys) {
      key.currentState?._toggleFace();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chosen = widget.candidates.first;
    final visible = _visibleCandidates(widget.candidates);

    return _FadedVerticalScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CandidateRankCard(
            key: _cardKeys[0],
            rank: 1,
            row: visible[0],
            thisCandidate: visible[0].candidate,
            nextDecision: visible.length > 1 ? visible[1].vsPrevious : null,
            bestScore: chosen.candidate.score,
            symbol: _symbolFor(visible[0].candidate.identity),
            tonality: widget.tonality,
            noteNameSystem: widget.noteNameSystem,
            longLabel: ChordLongFormFormatter.format(
              identity: visible[0].candidate.identity,
              tonality: widget.tonality,
              noteNameSystem: widget.noteNameSystem,
            ),
            onLongPress: _toggleAllCards,
          ),
          if (visible.length > 1) ...[
            const SizedBox(height: 14),
            const SectionHeader(
              title: 'Ranking Alternatives',
              icon: Icons.format_list_numbered,
            ),
            for (var i = 1; i < visible.length; i++) ...[
              _CandidateRankCard(
                key: _cardKeys[i],
                rank: i + 1,
                row: visible[i],
                thisCandidate: visible[i].candidate,
                nextDecision: i + 1 < visible.length
                    ? visible[i + 1].vsPrevious
                    : null,
                bestScore: chosen.candidate.score,
                symbol: _symbolFor(visible[i].candidate.identity),
                tonality: widget.tonality,
                noteNameSystem: widget.noteNameSystem,
                longLabel: ChordLongFormFormatter.format(
                  identity: visible[i].candidate.identity,
                  tonality: widget.tonality,
                  noteNameSystem: widget.noteNameSystem,
                ),
                onLongPress: _toggleAllCards,
              ),
              if (i != visible.length - 1) const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  String _symbolFor(ChordIdentity identity) {
    return chordSymbolDisplayLabel(
      ChordSymbolBuilder.fromIdentity(
        identity: identity,
        tonality: widget.tonality,
        notation: widget.notation,
      ),
      noteNameSystem: widget.noteNameSystem,
    );
  }
}

class _FadedVerticalScrollView extends StatefulWidget {
  const _FadedVerticalScrollView({required this.child});

  final Widget child;

  @override
  State<_FadedVerticalScrollView> createState() =>
      _FadedVerticalScrollViewState();
}

class _FadedVerticalScrollViewState extends State<_FadedVerticalScrollView> {
  static const _fadeHeight = 24.0;

  late final ScrollController _controller = ScrollController();

  bool _showTopFade = false;
  bool _showBottomFade = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateFades);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateFades();
    });
  }

  @override
  void didUpdateWidget(covariant _FadedVerticalScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateFades();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateFades);
    _controller.dispose();
    super.dispose();
  }

  void _updateFades() {
    if (!_controller.hasClients) return;

    final position = _controller.position;
    if (!position.hasContentDimensions) return;

    const epsilon = 0.5;
    final maxExtent = position.maxScrollExtent;
    final pixels = position.pixels;
    final nextTop = maxExtent > epsilon && pixels > epsilon;
    final nextBottom = maxExtent > epsilon && pixels < maxExtent - epsilon;

    if (nextTop == _showTopFade && nextBottom == _showBottomFade) return;

    setState(() {
      _showTopFade = nextTop;
      _showBottomFade = nextBottom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fadeColor = Theme.of(context).colorScheme.surfaceContainerLow;

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _updateFades();
        });

        return Stack(
          children: [
            SingleChildScrollView(controller: _controller, child: widget.child),
            if (_showTopFade)
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: _fadeHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [fadeColor, fadeColor.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
            if (_showBottomFade)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _fadeHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [fadeColor, fadeColor.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

List<RankedCandidateDebug> _visibleCandidates(
  List<RankedCandidateDebug> candidates,
) {
  return candidates.take(5).toList(growable: false);
}

class _CandidateRankCard extends StatefulWidget {
  const _CandidateRankCard({
    super.key,
    required this.rank,
    required this.row,
    required this.thisCandidate,
    required this.nextDecision,
    required this.bestScore,
    required this.symbol,
    required this.tonality,
    required this.noteNameSystem,
    required this.longLabel,
    required this.onLongPress,
  });

  final int rank;
  final RankedCandidateDebug row;
  final ChordCandidate thisCandidate;
  final RankingDecision? nextDecision;
  final double bestScore;
  final String symbol;
  final Tonality tonality;
  final NoteNameSystem noteNameSystem;
  final String longLabel;
  final VoidCallback onLongPress;

  @override
  State<_CandidateRankCard> createState() => _CandidateRankCardState();
}

class _CandidateRankCardState extends State<_CandidateRankCard> {
  bool _showScoring = false;

  void _toggleFace() {
    setState(() => _showScoring = !_showScoring);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fitLabel = widget.rank == 1
        ? 'Chosen'
        : (ChordCandidateRanking.isNearTie(
                widget.bestScore,
                widget.row.candidate.score,
              )
              ? 'Near tie'
              : 'Unlikely');
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ??
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations;

    return Semantics(
      button: true,
      toggled: _showScoring,
      label: '${widget.symbol}, rank ${widget.rank}',
      hint: _showScoring
          ? 'Tap to show the plain-language explanation. '
                'Long press to flip all ranked chords'
          : 'Tap to show scoring details. Long press to flip all ranked chords',
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: widget.rank == 1
              ? BorderSide(color: cs.outlineVariant)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _toggleFace,
          onLongPress: widget.onLongPress,
          child: AnimatedSize(
            duration: disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.topCenter,
                children: [...previousChildren, ?currentChild],
              ),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.025),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Padding(
                key: ValueKey(_showScoring),
                padding: const EdgeInsets.all(12),
                child: _showScoring
                    ? _CandidateScoreBack(
                        rank: widget.rank,
                        row: widget.row,
                        symbol: widget.symbol,
                        tonality: widget.tonality,
                        noteNameSystem: widget.noteNameSystem,
                        decision: widget.nextDecision,
                        winner: widget.thisCandidate,
                      )
                    : _CandidateExplanationFront(
                        rank: widget.rank,
                        row: widget.row,
                        symbol: widget.symbol,
                        longLabel: widget.longLabel,
                        fitLabel: fitLabel,
                        nextDecision: widget.nextDecision,
                        winner: widget.thisCandidate,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CandidateExplanationFront extends StatelessWidget {
  const _CandidateExplanationFront({
    required this.rank,
    required this.row,
    required this.symbol,
    required this.longLabel,
    required this.fitLabel,
    required this.nextDecision,
    required this.winner,
  });

  final int rank;
  final RankedCandidateDebug row;
  final String symbol;
  final String longLabel;
  final String fitLabel;
  final RankingDecision? nextDecision;
  final ChordCandidate winner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RankBadge(rank: rank),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(symbol, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    longLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              fitLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: rank == 1 ? cs.primary : cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(_evidenceFor(row), style: theme.textTheme.bodyMedium),
        if (nextDecision?.decidedByRule != null) ...[
          const SizedBox(height: 6),
          Text(
            _plainDecision(nextDecision!.decidedByRule, winner: winner),
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _CandidateScoreBack extends StatelessWidget {
  const _CandidateScoreBack({
    required this.rank,
    required this.row,
    required this.symbol,
    required this.tonality,
    required this.noteNameSystem,
    required this.decision,
    required this.winner,
  });

  final int rank;
  final RankedCandidateDebug row;
  final String symbol;
  final Tonality tonality;
  final NoteNameSystem noteNameSystem;
  final RankingDecision? decision;
  final ChordCandidate winner;

  void _openExplore(BuildContext context) {
    // Push over the open sheet without dismissing it, so returning from Explore
    // reveals the same "Why This Chord?" view (flipped cards and scroll intact).
    unawaited(
      Navigator.of(
        context,
      ).push(ExploreChordPage.route(seedIdentity: row.candidate.identity)),
    );
  }

  int _maskFor(String label) {
    for (final reason in row.scoreReasons) {
      if (reason.label == label) return reason.intervals ?? 0;
    }
    return 0;
  }

  int get _representedPlayedTonesMask => row
      .candidate
      .identity
      .toneRolesByInterval
      .keys
      .fold<int>(0, (mask, interval) => mask | (1 << interval));

  int get _alsoPlayedTonesMask =>
      row.candidate.identity.presentIntervalsMask &
      ~_representedPlayedTonesMask;

  /// Builds (degree, note) pairs for the tones in [mask], ordered by degree.
  /// Each tone is labeled individually so the degree and note name stay paired.
  List<_ToneEntry> _tonesFor(int mask) {
    final identity = row.candidate.identity;
    final entries = <_ToneEntry>[];
    final intervals =
        [
          for (var interval = 0; interval < 12; interval++)
            if ((mask & (1 << interval)) != 0) interval,
        ]..sort((a, b) {
          final roleA = identity.toneRolesByInterval[a];
          final roleB = identity.toneRolesByInterval[b];
          if (roleA == null || roleB == null) return a.compareTo(b);
          final degreeComparison = roleA.degreeOrder.compareTo(
            roleB.degreeOrder,
          );
          return degreeComparison != 0 ? degreeComparison : a.compareTo(b);
        });
    for (final interval in intervals) {
      final pitchClass = (identity.rootPc + interval) % 12;
      final pc = {pitchClass};
      final degree = theoryTokenDisplayLabel(
        ChordMemberDegreeFormatter.formatDegrees(
          identity: identity,
          pitchClasses: pc,
        ).first,
      );
      final note = noteDisplayLabel(
        ChordMemberSpeller.spellMembers(
          identity: identity,
          pitchClasses: pc,
          tonality: tonality,
        ).first,
        noteNameSystem: noteNameSystem,
      );
      entries.add(
        _ToneEntry(
          degree: degree,
          note: note,
          isBass: pitchClass == identity.bassPc,
        ),
      );
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final scoringReasons = row.scoreReasons.where(
      (reason) => reason.label != 'normalize' && reason.delta != 0,
    );
    final rawScore = _rawScore(row);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RankBadge(rank: rank),
            const SizedBox(width: 10),
            Expanded(child: Text(symbol, style: theme.textTheme.titleMedium)),
            const SizedBox(width: 8),
            Text(
              row.candidate.score.toStringAsFixed(2),
              style: theme.textTheme.titleMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _TemplateLedger(
          chordTones: _tonesFor(_representedPlayedTonesMask),
          missing: _tonesFor(_maskFor('missing required')),
          alsoPlayed: _tonesFor(_alsoPlayedTonesMask),
        ),
        const Divider(height: 16),
        for (final reason in scoringReasons)
          _ScoreRow(
            label: _scoreReasonLabel(reason.label),
            value: reason.delta,
          ),
        if (rawScore != null) ...[
          const Divider(height: 16),
          _ScoreRow(label: 'Raw score', value: rawScore, signed: false),
        ],
        _ScoreRow(
          label: 'Final score',
          value: row.candidate.score,
          signed: false,
          emphasized: true,
        ),
        if (decision?.decidedByRule != null) ...[
          const SizedBox(height: 10),
          Text(
            _plainDecision(decision!.decidedByRule, winner: winner),
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _openExplore(context),
            icon: const Icon(Icons.explore_outlined, size: 18),
            label: const Text('Explore'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: cs.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToneEntry {
  const _ToneEntry({
    required this.degree,
    required this.note,
    this.isBass = false,
  });

  final String degree;
  final String note;
  final bool isBass;
}

/// Shows the candidate's template tones grouped as played chord tones, missing
/// required tones, and any extra/conflicting tones that were played anyway.
class _TemplateLedger extends StatelessWidget {
  const _TemplateLedger({
    required this.chordTones,
    required this.missing,
    required this.alsoPlayed,
  });

  final List<_ToneEntry> chordTones;
  final List<_ToneEntry> missing;
  final List<_ToneEntry> alsoPlayed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ToneGroup(label: 'Chord tones', tones: chordTones),
        if (missing.isNotEmpty)
          _ToneGroup(label: 'Missing', tones: missing, muted: true),
        if (alsoPlayed.isNotEmpty)
          _ToneGroup(label: 'Also played', tones: alsoPlayed),
      ],
    );
  }
}

class _ToneGroup extends StatelessWidget {
  const _ToneGroup({
    required this.label,
    required this.tones,
    this.muted = false,
  });

  final String label;
  final List<_ToneEntry> tones;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final tone in tones) _ToneChip(tone: tone, muted: muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToneChip extends StatelessWidget {
  const _ToneChip({required this.tone, this.muted = false});

  final _ToneEntry tone;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isBass = tone.isBass;
    final foreground = isBass
        ? cs.onPrimaryContainer
        : muted
        ? cs.onSurfaceVariant
        : cs.onSurface;
    final fill = isBass
        ? cs.primaryContainer
        : muted
        ? cs.surface
        : cs.surfaceContainer;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isBass ? cs.primary : cs.outlineVariant.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: tone.degree,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground.withValues(alpha: 0.7),
              ),
            ),
            const TextSpan(text: '  '),
            TextSpan(
              text: tone.note,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    if (!isBass) return chip;

    return Semantics(
      label: '${tone.note}, ${tone.degree}, bass note',
      child: ExcludeSemantics(child: chip),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.value,
    this.signed = true,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final bool signed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasized
        ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.bodyMedium;
    final valueLabel =
        '${signed && value > 0 ? '+' : ''}${value.toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 8),
          Text(valueLabel, style: style),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ExcludeSemantics(
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: rank == 1 ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          '$rank',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: rank == 1 ? cs.onPrimary : cs.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EmptyRankingDetails extends StatelessWidget {
  const _EmptyRankingDetails();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Text('No chord ranking details are available right now.'),
    );
  }
}

String _evidenceFor(RankedCandidateDebug row) {
  final id = row.candidate.identity;
  final degrees = ChordMemberDegreeFormatter.formatDegrees(
    identity: id,
    pitchClasses: ChordPresentationBuilder.chordMemberPitchClassesFromMask(
      rootPc: id.rootPc,
      presentIntervalsMask: id.presentIntervalsMask,
    ),
  ).map(theoryTokenDisplayLabel).toList(growable: false);
  final bassRole = _bassRoleLabel(id);
  final requiredCount = _reasonCount(row, 'required tones');
  final optionalCount = _reasonCount(row, 'optional tones');
  final missingCount = _reasonCount(row, 'missing required');
  final penaltyCount = _reasonCount(row, 'penalty tones');
  final extrasCount = _reasonCount(row, 'extras');
  final parts = <String>[];

  if (degrees.isNotEmpty && requiredCount != null && requiredCount > 0) {
    final matchParts = <String>[
      '${_quantityWord(requiredCount)} matching structural ${requiredCount == 1 ? 'tone' : 'tones'}',
    ];
    if (optionalCount != null && optionalCount > 0) {
      matchParts.add(
        '${_quantityWord(optionalCount)} matching color ${optionalCount == 1 ? 'tone' : 'tones'}',
      );
    }

    parts.add('Uses ${degrees.join(', ')}, with ${matchParts.join(' and ')}');
  } else if (degrees.isNotEmpty) {
    parts.add('Uses ${degrees.join(', ')}');
  } else if (requiredCount != null && requiredCount > 0) {
    parts.add(
      'Matches ${_quantityWord(requiredCount)} structural ${requiredCount == 1 ? 'tone' : 'tones'}',
    );
  }
  if (missingCount != null && missingCount > 0) {
    parts.add(
      '${_quantityWord(missingCount)} expected ${missingCount == 1 ? 'tone is' : 'tones are'} missing',
    );
  }
  if (penaltyCount != null && penaltyCount > 0) {
    parts.add(
      '${_quantityWord(penaltyCount)} conflicting ${penaltyCount == 1 ? 'tone' : 'tones'}',
    );
  }
  if (extrasCount != null && extrasCount > 0) {
    parts.add(
      '${_quantityWord(extrasCount)} additional ${extrasCount == 1 ? 'color increases' : 'colors increase'} complexity',
    );
  }
  parts.add('bass is $bassRole');

  return '${parts.join('; ')}.';
}

String _quantityWord(int quantity) {
  return switch (quantity) {
    0 => 'zero',
    1 => 'one',
    2 => 'two',
    3 => 'three',
    4 => 'four',
    5 => 'five',
    6 => 'six',
    7 => 'seven',
    8 => 'eight',
    9 => 'nine',
    10 => 'ten',
    11 => 'eleven',
    12 => 'twelve',
    _ => '$quantity',
  };
}

String _bassRoleLabel(ChordIdentity id) {
  if (!id.hasSlashBass) return 'the root';

  final interval = (id.bassPc - id.rootPc) % 12;
  final role = id.toneRolesByInterval[interval];
  if (role == null) return 'outside the basic chord';

  return _roleLabel(role);
}

String _roleLabel(ChordToneRole role) {
  return switch (role) {
    ChordToneRole.root => 'the root',
    ChordToneRole.sus2 => 'the suspended second',
    ChordToneRole.flat9 => 'the flat nine',
    ChordToneRole.nine => 'the nine',
    ChordToneRole.sharp9 => 'the sharp nine',
    ChordToneRole.add9 => 'the added nine',
    ChordToneRole.addSharp9 => 'the added sharp nine',
    ChordToneRole.minor3 => 'the minor third',
    ChordToneRole.splitMinor3 => 'the split minor third',
    ChordToneRole.major3 => 'the major third',
    ChordToneRole.sus4 => 'the suspended fourth',
    ChordToneRole.eleven => 'the eleven',
    ChordToneRole.sharp11 => 'the sharp eleven',
    ChordToneRole.add11 => 'the added eleven',
    ChordToneRole.flat5 => 'the flat five',
    ChordToneRole.perfect5 => 'the fifth',
    ChordToneRole.sharp5 => 'the sharp five',
    ChordToneRole.sixth => 'the sixth',
    ChordToneRole.flat13 => 'the flat thirteen',
    ChordToneRole.thirteenth => 'the thirteen',
    ChordToneRole.add13 => 'the added thirteen',
    ChordToneRole.dim7 => 'the diminished seventh',
    ChordToneRole.flat7 => 'the flat seven',
    ChordToneRole.major7 => 'the major seventh',
  };
}

int? _reasonCount(RankedCandidateDebug row, String label) {
  for (final reason in row.scoreReasons) {
    if (reason.label != label) continue;
    final detail = reason.detail;
    if (detail == null) return null;
    final match = RegExp(r'count=(\d+)').firstMatch(detail);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }
  return null;
}

double? _rawScore(RankedCandidateDebug row) {
  final normalize = row.scoreReasons
      .where((reason) => reason.label == 'normalize')
      .firstOrNull;
  final match = RegExp(
    r'raw=(-?\d+(?:\.\d+)?)',
  ).firstMatch(normalize?.detail ?? '');
  return match == null ? null : double.tryParse(match.group(1)!);
}

String _scoreReasonLabel(String label) {
  return switch (label) {
    'required tones' => 'Required notes present',
    'missing required' => 'Required notes missing',
    'optional tones' => 'Optional color tones',
    'penalty tones' => 'Conflicting tones',
    'extras' => 'Added complexity',
    'bass fit' => 'Bass fit',
    'm#5 bass' => 'Sharp-five bass',
    'sus-tone bass' => 'Suspended-tone bass',
    'alterations penalty' => 'Altered spelling',
    'dominant stack' => 'Dominant-stack fit',
    'add9 bass triad' => 'Upper-triad fit',
    'sixNo5' => 'Missing fifth in sixth chord',
    _ => label,
  };
}

String _plainDecision(String? rule, {ChordCandidate? winner}) {
  final sentence = switch (rule) {
    'score difference beyond tie-break range' =>
      'its fit score was clearly stronger.',
    'prefer root-position 6th over inverted 7th' =>
      'the sixth-chord name is in root position, while the alternate reading puts another chord over a non-root bass.',
    'prefer complete triad over incomplete inverted 6th' =>
      'a complete triad is clearer than an incomplete inverted sixth chord.',
    'prefer upper-structure dominant7 slash' => _upperStructureDominantReason(
      winner,
    ),
    'prefer voicing-supported upper-structure slash' =>
      'the way it was played stacks a complete chord above an isolated bass note, so this slash name reads more naturally than a root-position reading.',
    'prefer stable extended dominant over double-accidental altered-fifth slash' =>
      'the extended dominant inversion avoids the double-accidental spelling required by the altered-fifth slash reading.',
    'prefer stable extended dominant over altered-fifth slash' =>
      'the extended dominant name keeps the bass, seventh shell, and upper extensions in a stable inversion more naturally than an altered-fifth slash reading.',
    'prefer root-position diminished7' =>
      'the diminished seventh is clearest when the bass is named as the root.',
    'prefer dominant7 over dim7 slash' ||
    'prefer altered dominant7 over dim7 slash' =>
      'the dominant-seventh shell gives the voicing a clearer dominant reading.',
    'prefer fewer altered/tension colors' =>
      'it needs fewer altered color tones.',
    'prefer diatonic chords' => 'it fits the selected key more directly.',
    'prefer tonic chord' => 'it is the tonic chord in the selected key.',
    'prefer I chord when bass is tonic' =>
      'with the tonic in the bass, it gives the clearest I-chord reading.',
    'prefer natural extensions over adds, then fewer total' =>
      'natural extensions give a cleaner chord name than added-tone spellings.',
    'prefer root position' => 'its bass is the chord root.',
    'prefer common naming preference' =>
      'common naming practice favors this chord name for the same kind of sonority.',
    'prefer 1st inversion over 2nd inversion' =>
      'its bass note is a more stable chord tone.',
    'prefer 7th chords over triads' =>
      'the seventh-chord reading explains more of the voicing.',
    'prefer fewer extensions' => 'it needs fewer extensions.',
    'avoid suspended chords' =>
      'a chord with a clear third is a more specific match than a suspended reading.',
    'prefer close root-position dominant7 over non-dominant slash' =>
      'a root-position dominant seventh is clearer than the alternative slash-chord name for these notes.',
    'prefer root-position altered-fifth dominant over slash' =>
      'the root-position altered dominant name is clearer than the slash reading.',
    'prefer conventional altered seventh over add11 slash' =>
      'the altered seventh chord is more conventional than the add-eleven slash reading.',
    'prefer complete minor sharp11 over altered maj7sus4' =>
      'the complete minor sharp-eleven reading is clearer than the altered suspended reading.',
    'deterministic fallback: rootPc' =>
      'these interpretations were essentially equivalent, so the app chose a consistent spelling.',
    _ => 'the ranking rules made it the clearest name for this voicing.',
  };

  return 'Ranked better than the next option because $sentence';
}

String _upperStructureDominantReason(ChordCandidate? winner) {
  if (winner?.identity.hasSlashBass ?? false) {
    return 'the bass note sounds like an intentional color note rather than a separate chord root.';
  }

  return 'the root-position dominant reading is clearer than the slash-bass alternative.';
}
