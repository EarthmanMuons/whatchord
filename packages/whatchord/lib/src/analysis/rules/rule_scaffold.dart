import '../../models/chord_candidate.dart';
import '../../models/tonality.dart';
import '../candidate_features.dart';
import 'named_rule.dart';

/// A single-candidate condition used by [preferOver].
typedef CandidateCondition =
    bool Function(
      ChordCandidate candidate,
      CandidateFeatures features,
      Tonality tonality,
    );

/// Builds the standard pairwise-preference rule: when exactly one candidate
/// satisfies [isPreferred] and the other satisfies [competitorQualifies], the
/// preferred candidate ranks higher.
///
/// [preferredQualifies], when set, is a further condition on the preferred
/// candidate checked after the asymmetry test; unlike folding it into
/// [isPreferred], it does not affect when the both-or-neither bail fires.
///
/// With [costCap] set, the preference only holds while the preferred reading
/// costs at most the cap above the competitor; a decisively cheaper
/// competitor stays ahead. Rules whose logic does not fit this shape
/// (relations between the two candidates, or rules where either side can
/// win) are written out by hand instead of being forced into the mold.
RuleFn preferOver({
  required CandidateCondition isPreferred,
  CandidateCondition? preferredQualifies,
  required CandidateCondition competitorQualifies,
  double? costCap,
}) {
  return (a, b, fa, fb, tonality) {
    final aIsPreferred = isPreferred(a, fa, tonality);
    final bIsPreferred = isPreferred(b, fb, tonality);
    if (aIsPreferred == bIsPreferred) return null;

    final preferred = aIsPreferred ? a : b;
    final fPreferred = aIsPreferred ? fa : fb;
    final other = aIsPreferred ? b : a;
    final fOther = aIsPreferred ? fb : fa;
    if (preferredQualifies != null &&
        !preferredQualifies(preferred, fPreferred, tonality)) {
      return null;
    }
    if (!competitorQualifies(other, fOther, tonality)) return null;

    if (costCap != null && preferred.cost > other.cost + costCap) return null;

    return aIsPreferred ? -1 : 1;
  };
}
