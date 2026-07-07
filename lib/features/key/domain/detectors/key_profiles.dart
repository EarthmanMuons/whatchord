/// Published key-profile pairs for profile-correlation detection.
///
/// The literature is clear that profile choice matters more than the
/// correlation formula, so the pair is a parameter, not a constant. Values are
/// indexed by interval above the tonic (0..11). Sources are cited in
/// research/whatkey/temporal-context-key-detection.md.
enum KeyProfilePair {
  /// Krumhansl & Kessler probe-tone ratings (Krumhansl 1990). The historical
  /// baseline; known to underperform in minor.
  krumhanslKessler(
    major: [
      6.35, 2.23, 3.48, 2.33, 4.38, 4.09, //
      2.52, 5.19, 2.39, 3.66, 2.29, 2.88,
    ],
    minor: [
      6.33, 2.68, 3.52, 5.38, 2.60, 3.53, //
      2.54, 4.75, 3.98, 2.69, 3.34, 3.17,
    ],
  ),

  /// Temperley's 1999 revision ("What's Key for Key?").
  temperley(
    major: [
      5.0, 2.0, 3.5, 2.0, 4.5, 4.0, //
      2.0, 4.5, 2.0, 3.5, 1.5, 4.0,
    ],
    minor: [
      5.0, 2.0, 3.5, 4.5, 2.0, 4.0, //
      2.0, 4.5, 3.5, 2.0, 1.5, 4.0,
    ],
  ),

  /// Albrecht & Shanahan (2013) corpus-trained profiles; notably better in
  /// minor and the recommended default.
  albrechtShanahan(
    major: [
      0.238, 0.006, 0.111, 0.006, 0.137, 0.094, //
      0.016, 0.214, 0.009, 0.080, 0.008, 0.081,
    ],
    minor: [
      0.220, 0.006, 0.104, 0.123, 0.019, 0.103, //
      0.012, 0.214, 0.062, 0.022, 0.061, 0.052,
    ],
  );

  final List<double> major;
  final List<double> minor;

  const KeyProfilePair({required this.major, required this.minor});
}
