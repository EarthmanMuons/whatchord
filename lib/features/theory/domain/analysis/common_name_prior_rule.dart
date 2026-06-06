import '../models/chord_candidate.dart';
import '../models/chord_extension.dart';
import '../models/chord_identity.dart';
import '../models/tonality.dart';
import 'candidate_features.dart';
import 'choco_common_name_prior.dart';

/// Uses ChoCo chord-label frequency as a weak common-name prior for otherwise
/// equivalent near-ties.
///
/// This is intentionally late and narrow: it compares only semantic chord
/// signatures, not roots or keys, and it refuses to run unless the competing
/// names are similarly well explained. That makes it useful for ambiguities
/// such as Dm7/A vs F6/A without turning corpus frequency into a primary
/// scoring signal.
int? preferCommonNamePrior(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  // Allow the prior to resolve a modest scoring preference caused only by bass
  // position. This remains below the general near-tie window and is guarded by
  // equivalent explanation/extension complexity below.
  if ((a.score - b.score).abs() > 0.15) return null;
  if (fa.unnamedToneCount != fb.unnamedToneCount) return null;
  if (fa.extensionCount != fb.extensionCount) return null;
  if (fa.extensionTensionCount != fb.extensionTensionCount) return null;

  final aCount = _commonNamePriorCount(a.identity);
  final bCount = _commonNamePriorCount(b.identity);
  if (aCount == bCount) return null;

  const minObservations = 100;
  const minRatio = 2.0;
  final high = aCount > bCount ? aCount : bCount;
  final low = aCount > bCount ? bCount : aCount;
  if (high < minObservations) return null;
  if (low > 0 && high / low < minRatio) return null;

  return aCount > bCount ? -1 : 1;
}

int _commonNamePriorCount(ChordIdentity identity) {
  return chocoCommonNamePriorObservationCounts[_commonNamePriorKey(identity)] ??
      0;
}

String _commonNamePriorKey(ChordIdentity identity) {
  if (identity.extensions.isEmpty) return identity.quality.name;

  final extensions = identity.extensions.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return '${identity.quality.name}|${extensions.map((e) => e.name).join(',')}';
}
