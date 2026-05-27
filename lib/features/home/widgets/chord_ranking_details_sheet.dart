import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/core.dart';
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

class _RankingDetailsBody extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final chosen = candidates.first;
    final visible = _visibleCandidates(candidates);

    return _FadedVerticalScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CandidateRankCard(
            rank: 1,
            row: visible[0],
            thisCandidate: visible[0].candidate,
            nextDecision: visible.length > 1 ? visible[1].vsPrevious : null,
            bestScore: chosen.candidate.score,
            symbol: _symbolFor(visible[0].candidate.identity),
            longLabel: ChordLongFormFormatter.format(
              identity: visible[0].candidate.identity,
              tonality: tonality,
              noteNameSystem: noteNameSystem,
            ),
          ),
          if (visible.length > 1) ...[
            const SizedBox(height: 14),
            const SectionHeader(
              title: 'Ranking Alternatives',
              icon: Icons.format_list_numbered,
            ),
            for (var i = 1; i < visible.length; i++) ...[
              _CandidateRankCard(
                rank: i + 1,
                row: visible[i],
                thisCandidate: visible[i].candidate,
                nextDecision: i + 1 < visible.length
                    ? visible[i + 1].vsPrevious
                    : null,
                bestScore: chosen.candidate.score,
                symbol: _symbolFor(visible[i].candidate.identity),
                longLabel: ChordLongFormFormatter.format(
                  identity: visible[i].candidate.identity,
                  tonality: tonality,
                  noteNameSystem: noteNameSystem,
                ),
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
        tonality: tonality,
        notation: notation,
      ),
      noteNameSystem: noteNameSystem,
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

class _CandidateRankCard extends StatelessWidget {
  const _CandidateRankCard({
    required this.rank,
    required this.row,
    required this.thisCandidate,
    required this.nextDecision,
    required this.bestScore,
    required this.symbol,
    required this.longLabel,
  });

  final int rank;
  final RankedCandidateDebug row;
  final ChordCandidate thisCandidate;
  final RankingDecision? nextDecision;
  final double bestScore;
  final String symbol;
  final String longLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final scoreDelta = bestScore - row.candidate.score;
    final fitLabel = rank == 1 ? 'Chosen' : _fitLabel(scoreDelta);
    final evidence = _evidenceFor(row);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: rank == 1 ? Border.all(color: cs.outlineVariant) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
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
            Text(evidence, style: theme.textTheme.bodyMedium),
            if (nextDecision?.decidedByRule != null) ...[
              const SizedBox(height: 6),
              Text(
                _plainDecision(
                  nextDecision!.decidedByRule,
                  winner: thisCandidate,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
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

String _fitLabel(double deltaFromBest) {
  if (deltaFromBest.abs() <= ChordCandidateRanking.nearTieWindow) {
    return 'Near tie';
  }
  return 'Unlikely';
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
      '$requiredCount matching structural ${requiredCount == 1 ? 'tone' : 'tones'}',
    ];
    if (optionalCount != null && optionalCount > 0) {
      matchParts.add(
        '$optionalCount matching color ${optionalCount == 1 ? 'tone' : 'tones'}',
      );
    }

    parts.add('Uses ${degrees.join(', ')}, with ${matchParts.join(' and ')}');
  } else if (degrees.isNotEmpty) {
    parts.add('Uses ${degrees.join(', ')}');
  } else if (requiredCount != null && requiredCount > 0) {
    parts.add(
      'Matches $requiredCount structural ${requiredCount == 1 ? 'tone' : 'tones'}',
    );
  }
  if (missingCount != null && missingCount > 0) {
    parts.add(
      '$missingCount expected ${missingCount == 1 ? 'tone is' : 'tones are'} missing',
    );
  }
  if (penaltyCount != null && penaltyCount > 0) {
    parts.add(
      '$penaltyCount conflicting ${penaltyCount == 1 ? 'tone' : 'tones'}',
    );
  }
  if (extrasCount != null && extrasCount > 0) {
    parts.add(
      '$extrasCount extra ${extrasCount == 1 ? 'tone needs' : 'tones need'} explanation',
    );
  }
  parts.add('bass is $bassRole');

  return '${parts.join('; ')}.';
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

String _plainDecision(String? rule, {ChordCandidate? winner}) {
  final sentence = switch (rule) {
    'score outside near-tie window' => 'its fit score was clearly stronger.',
    'prefer root-position 6th over inverted 7th' =>
      'the sixth-chord name is in root position, while the alternate reading puts another chord over a non-root bass.',
    'prefer complete triad over incomplete inverted 6th' =>
      'a complete triad is clearer than an incomplete inverted sixth chord.',
    'prefer upper-structure dominant7 slash' => _upperStructureDominantReason(
      winner,
    ),
    'prefer root-position extended dominant over altered-fifth slash' =>
      'the root-position dominant name aligns the bass, seventh shell, and upper extensions more naturally than an inverted altered-fifth reading.',
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
