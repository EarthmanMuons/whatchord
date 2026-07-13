/// Streaming key detection from live chord evidence: [KeyDetector]
/// implementations consume committed chord events and maintain a claim over
/// the 24 major and minor keys, abstaining when evidence is thin.
library;

// Detectors
export 'src/detectors/bocpd_key_detector.dart';
export 'src/detectors/claim_hysteresis_detector.dart';
export 'src/detectors/display_calibration.dart';
export 'src/detectors/hmm_key_detector.dart';
export 'src/detectors/hybrid_key_detector.dart';
export 'src/detectors/key_detector.dart';
export 'src/detectors/key_profiles.dart';
export 'src/detectors/key_space.dart';
export 'src/detectors/profile_correlation_key_detector.dart';
export 'src/detectors/progression_key_detector.dart';
export 'src/detectors/weighted_evidence_key_detector.dart';

// Models
export 'src/models/key_behavior.dart';
export 'src/models/key_estimate.dart';
