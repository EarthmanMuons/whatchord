/// Shared schedule for audible previews and their keyboard highlights.
///
/// [AudioMonitorNotifier]'s preview playback and [PreviewAnimationController]'s
/// highlight choreography are separately scheduled timer chains; they stay in
/// step only because both read these constants.
abstract final class PreviewTimings {
  /// How long a plain (non-rolled) preview chord or single note sounds.
  static const Duration hold = Duration(milliseconds: 1400);

  /// Delay between successive note onsets while rolling a chord.
  static const Duration rolledStep = Duration(milliseconds: 180);

  /// How long each rolled note sounds before its note-off.
  static const Duration rolledNoteDuration = Duration(milliseconds: 220);

  /// Pause between the end of the roll and the full block chord.
  static const Duration rolledBlockGap = Duration(milliseconds: 260);

  /// How long the full block chord sounds after the roll.
  static const Duration rolledBlockDuration = Duration(milliseconds: 1400);

  /// Delay between successive note onsets in a melodic run.
  static const Duration sequenceStep = Duration(milliseconds: 200);

  /// How long each run note sounds; equal to [sequenceStep] so notes abut.
  static const Duration sequenceNoteDuration = Duration(milliseconds: 200);
}
