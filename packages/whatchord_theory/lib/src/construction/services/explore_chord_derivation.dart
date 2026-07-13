import '../../formatting/services/chord_presentation_builder.dart';
import '../../models/chord_extension.dart';
import '../../models/chord_identity.dart';
import '../../services/chord_quality_intervals.dart';
import '../../services/chord_tone_roles.dart';
import '../models/explore_chord_state.dart';

ChordIdentity buildExploreChordIdentity(ExploreChordState state) {
  final presentIntervalsMask = canonicalPresentIntervalsMask(
    quality: state.quality,
    extensions: state.extensions,
  );

  final toneRoles = ChordToneRoles.build(
    quality: state.quality,
    extensions: state.extensions,
    relMask: presentIntervalsMask,
  );

  final memberPitchClasses =
      ChordPresentationBuilder.chordMemberPitchClassesFromMask(
        rootPc: state.rootPc,
        presentIntervalsMask: presentIntervalsMask,
      );

  final bassPc = memberPitchClasses.contains(state.bassPc)
      ? state.bassPc
      : state.rootPc;

  return ChordIdentity(
    rootPc: state.rootPc,
    bassPc: bassPc,
    quality: state.quality,
    extensions: state.extensions,
    toneRolesByInterval: toneRoles,
    presentIntervalsMask: presentIntervalsMask,
  );
}

int canonicalPresentIntervalsMask({
  required ChordQualityToken quality,
  required Set<ChordExtension> extensions,
}) {
  var mask = 0;

  void addInterval(int interval) {
    mask |= 1 << (interval % 12);
  }

  for (final interval in quality.canonicalIntervals) {
    addInterval(interval);
  }

  for (final extension in extensions) {
    addInterval(extension.intervalAboveRoot);
  }

  return mask;
}
