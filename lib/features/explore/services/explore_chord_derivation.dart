import 'package:whatchord/features/theory/theory.dart';

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

  for (final interval in coreIntervalsForQuality(quality)) {
    addInterval(interval);
  }

  for (final extension in extensions) {
    addInterval(extension.intervalAboveRoot);
  }

  return mask;
}

Set<int> coreIntervalsForQuality(ChordQualityToken quality) {
  switch (quality) {
    case ChordQualityToken.major:
      return const {0, 4, 7};
    case ChordQualityToken.minor:
      return const {0, 3, 7};
    case ChordQualityToken.diminished:
      return const {0, 3, 6};
    case ChordQualityToken.augmented:
      return const {0, 4, 8};
    case ChordQualityToken.sus2:
      return const {0, 2, 7};
    case ChordQualityToken.sus4:
      return const {0, 5, 7};
    case ChordQualityToken.major6:
      return const {0, 4, 7, 9};
    case ChordQualityToken.minor6:
      return const {0, 3, 7, 9};
    case ChordQualityToken.dominant7:
      return const {0, 4, 7, 10};
    case ChordQualityToken.dominant7sus4:
      return const {0, 5, 7, 10};
    case ChordQualityToken.major7:
      return const {0, 4, 7, 11};
    case ChordQualityToken.minor7:
      return const {0, 3, 7, 10};
    case ChordQualityToken.minorMajor7:
      return const {0, 3, 7, 11};
    case ChordQualityToken.halfDiminished7:
      return const {0, 3, 6, 10};
    case ChordQualityToken.diminished7:
      return const {0, 3, 6, 9};
  }
}
