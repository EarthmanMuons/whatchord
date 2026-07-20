/// Selects a stable chord-analysis policy without forking the analysis engine.
///
/// Production callers use [current]. Research fixture generators may select a
/// frozen profile so later naming improvements do not silently change the
/// observations consumed by a published experiment.
enum ChordAnalysisProfile {
  /// The current production chord-ranking policy.
  current,

  /// The ranking policy used to generate the WhatKey paper fixtures released
  /// with WhatChord v2026.7.14.
  whatKeyPaper2026,
}
