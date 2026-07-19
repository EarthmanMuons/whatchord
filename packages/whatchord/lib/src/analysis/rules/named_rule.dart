import '../../models/chord_candidate.dart';
import '../../models/tonality.dart';
import '../candidate_features.dart';

/// Signature shared by every ranking rule. Returns -1 if `a` ranks higher, 1 if
/// `b` ranks higher, 0 or null if the rule does not apply to this pair.
typedef RuleFn =
    int? Function(
      ChordCandidate a,
      ChordCandidate b,
      CandidateFeatures fa,
      CandidateFeatures fb,
      Tonality tonality,
    );

/// Candidate-local necessary condition for a rule to fire.
///
/// Returns true if [candidate] could be *either* operand of a rule that returns
/// non-null. It must be a superset of the rule's real firing precondition: if it
/// is ever false for a candidate the rule could actually decide, that decision
/// is silently dropped. It depends only on the single candidate (plus tonality),
/// never on the candidate it is being compared against.
typedef RuleGate =
    bool Function(
      ChordCandidate candidate,
      CandidateFeatures features,
      Tonality tonality,
    );

/// A ranking rule paired with a human-readable name for debugging and for
/// explaining ranking decisions to users.
class NamedRule {
  final String name;
  final RuleFn apply;

  /// Optional candidate-local gate (see [RuleGate]). When set, the pairwise
  /// ranking pass skips [apply] for any pair where the gate is false for either
  /// candidate, since the rule could not fire there anyway. When null, [apply]
  /// is always evaluated (the original behavior).
  final RuleGate? gate;

  const NamedRule(this.name, this.apply, {this.gate});
}
