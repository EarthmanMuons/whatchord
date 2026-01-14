import 'package:meta/meta.dart';

import '../analysis/chord_templates.dart';
import 'chord_candidate.dart';
import 'chord_identity.dart';

@immutable
class ChordCandidateDebug {
  final ChordCandidate candidate;
  final ChordTemplate template;

  final int relMask;
  final int requiredMask;
  final int optionalMask;
  final int penaltyMask;
  final int extrasMask;

  final int missingRequiredMask;
  final int presentRequiredMask;
  final int presentOptionalMask;
  final int presentPenaltyMask;

  final int missingCount;
  final int reqCount;
  final int optCount;
  final int penCount;
  final int extrasCount;

  final double scoreRequired;
  final double scoreMissing;
  final double scoreOptional;
  final double scorePenalty;
  final double scoreExtras;
  final double scoreBass;
  final double scoreRootPos;
  final double scoreAlterations;

  final double rawScore;
  final double normalizedScore;
  final double normalizationDenom;

  const ChordCandidateDebug({
    required this.candidate,
    required this.template,
    required this.relMask,
    required this.requiredMask,
    required this.optionalMask,
    required this.penaltyMask,
    required this.extrasMask,
    required this.missingRequiredMask,
    required this.presentRequiredMask,
    required this.presentOptionalMask,
    required this.presentPenaltyMask,
    required this.missingCount,
    required this.reqCount,
    required this.optCount,
    required this.penCount,
    required this.extrasCount,
    required this.scoreRequired,
    required this.scoreMissing,
    required this.scoreOptional,
    required this.scorePenalty,
    required this.scoreExtras,
    required this.scoreBass,
    required this.scoreRootPos,
    required this.scoreAlterations,
    required this.rawScore,
    required this.normalizedScore,
    required this.normalizationDenom,
  });

  ChordIdentity get identity => candidate.identity;
  double get score => candidate.score;

  @override
  String toString() {
    // Compact but information-dense single-line summary.
    final id = identity.toString();
    return '$id score=${score.toStringAsFixed(3)} '
        '(raw=${rawScore.toStringAsFixed(3)} norm=${normalizedScore.toStringAsFixed(3)} denom=${normalizationDenom.toStringAsFixed(3)}) '
        'req=$reqCount opt=$optCount miss=$missingCount pen=$penCount extra=$extrasCount '
        'parts=[+req:${scoreRequired.toStringAsFixed(2)} '
        'miss:${scoreMissing.toStringAsFixed(2)} '
        '+opt:${scoreOptional.toStringAsFixed(2)} '
        '-pen:${scorePenalty.toStringAsFixed(2)} '
        '-x:${scoreExtras.toStringAsFixed(2)} '
        'bass:${scoreBass.toStringAsFixed(2)} '
        'root:${scoreRootPos.toStringAsFixed(2)} '
        'alt:${scoreAlterations.toStringAsFixed(2)}]';
  }
}
