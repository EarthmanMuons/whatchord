import '../detectors/display_calibration.dart';
import '../detectors/hmm_key_detector.dart';

/// User-facing key detection presets (research/whatkey/key-behavior-modes.md):
/// the shipped detector with a per-mode emission half-life, paired with the
/// display calibration temperature fitted for that timescale. Every other
/// detector knob measured best at its default at all three timescales.
enum KeyBehavior {
  /// Section-scale reading: names the song's key and absorbs brief detours.
  /// The shipped configuration.
  stable(
    emissionHalfLife: Duration(
      seconds: HmmKeyDetector.defaultEmissionHalfLifeSeconds,
    ),
    displayTemperature: DisplayCalibration.temperature,
  ),

  /// Follows section-scale key changes within a few chords at section
  /// accuracy statistically matching [stable].
  balanced(emissionHalfLife: Duration(seconds: 4), displayTemperature: 1.5),

  /// Local-scale reading: re-bases on the current tonal center quickly, at
  /// the cost of more switching and more abstention.
  reactive(emissionHalfLife: Duration(seconds: 1), displayTemperature: 1.75);

  const KeyBehavior({
    required this.emissionHalfLife,
    required this.displayTemperature,
  });

  /// Emission memory for the detector: how far back chord evidence counts.
  final Duration emissionHalfLife;

  /// Temperature for [DisplayCalibration.calibrate], fitted per mode so the
  /// displayed confidence stays honest for what this mode's claims mean.
  final double displayTemperature;
}
