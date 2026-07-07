import 'package:whatchord/features/history/history_domain.dart';
import 'package:whatchord/features/theory/domain/theory_domain.dart';

import '../models/key_estimate.dart';
import 'key_detector.dart';
import 'key_profiles.dart';
import 'profile_correlation_key_detector.dart';
import 'weighted_evidence_key_detector.dart';

/// Hybrid key detection: profile correlation as the base score with the
/// weighted evidence model's functional points as an adjustment.
///
/// The two ingredients fail in complementary places (log entry 2026-07-07-03):
/// histograms are robust on dense romantic harmony but blind to function, so
/// they lag modulations; the functional rules track cadences but tie on
/// purely diatonic or dominant-heavy stretches. Per key, the hybrid score is
///
///   correlation + functionalBlend * functional points per weighted event
///
/// so profile shape breaks functional ties and functional evidence moves the
/// histogram's supertanker at key changes. `functionalBlend: 0` reduces to
/// pure profile correlation, which is the ablation anchor.
class HybridKeyDetector implements KeyDetector {
  final ProfileCorrelationKeyDetector _profile;
  final WeightedEvidenceKeyDetector _evidence;

  /// Weight of one functional point per weighted event, in correlation units.
  final double functionalBlend;
  final int minEvents;
  final double marginFloor;

  int _eventCount = 0;

  HybridKeyDetector({
    KeyProfilePair profiles = KeyProfilePair.albrechtShanahan,
    bool durationWeighted = true,
    Duration? decayHalfLife = const Duration(seconds: 30),
    bool confidenceWeighted = true,
    // Selected on the development split: the blend sweep plateaus at
    // 0.1-0.15 and the paired test against the profile floor is decisive
    // there (log entry 2026-07-07-04).
    this.functionalBlend = 0.1,
    this.minEvents = 3,
    this.marginFloor = 0.05,
  }) : _profile = ProfileCorrelationKeyDetector(
         profiles: profiles,
         durationWeighted: durationWeighted,
         decayHalfLife: decayHalfLife,
         minEvents: 1,
         marginFloor: 0,
       ),
       _evidence = WeightedEvidenceKeyDetector(
         durationWeighted: durationWeighted,
         decayHalfLife: decayHalfLife,
         confidenceWeighted: confidenceWeighted,
         minEvents: 1,
         marginFloor: 0,
       );

  @override
  String get name => 'hybrid';

  @override
  String get configuration =>
      'functionalBlend=$functionalBlend minEvents=$minEvents '
      'marginFloor=$marginFloor | profile: ${_profile.configuration} '
      '| evidence: ${_evidence.configuration}';

  @override
  void reset() {
    _profile.reset();
    _evidence.reset();
    _eventCount = 0;
  }

  @override
  KeyEstimateFrame onEvent(ChordEvent event) {
    final profileFrame = _profile.onEvent(event);
    final evidenceFrame = _evidence.onEvent(event);
    _eventCount += 1;

    final combined = <int, double>{};
    for (final estimate in profileFrame.ranked) {
      combined[_keyIndex(estimate.tonality)] = estimate.confidence;
    }
    for (final estimate in evidenceFrame.ranked) {
      combined.update(
        _keyIndex(estimate.tonality),
        (base) => base + functionalBlend * estimate.confidence,
        ifAbsent: () => functionalBlend * estimate.confidence,
      );
    }
    if (combined.isEmpty) return const KeyEstimateFrame.abstain([]);

    final byIndex = {
      for (final tonality in ProfileCorrelationKeyDetector.canonicalTonalities)
        _keyIndex(tonality): tonality,
    };
    final ranked = [
      for (final entry in combined.entries)
        KeyEstimate(tonality: byIndex[entry.key]!, confidence: entry.value),
    ]..sort((a, b) => b.confidence.compareTo(a.confidence));

    if (_eventCount < minEvents) return KeyEstimateFrame.abstain(ranked);
    final margin = ranked.length < 2
        ? double.infinity
        : ranked[0].confidence - ranked[1].confidence;
    if (ranked[0].confidence <= 0 || margin < marginFloor) {
      return KeyEstimateFrame.abstain(ranked);
    }
    return KeyEstimateFrame(ranked: ranked, claim: ranked.first);
  }

  static int _keyIndex(Tonality tonality) =>
      tonality.tonicPitchClass * 2 + (tonality.isMinor ? 1 : 0);
}
