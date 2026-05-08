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
  var mask = 1 << 0;

  void addInterval(int interval) {
    mask |= 1 << (interval % 12);
  }

  switch (quality) {
    case ChordQualityToken.major:
      addInterval(4);
      addInterval(7);
      break;
    case ChordQualityToken.minor:
      addInterval(3);
      addInterval(7);
      break;
    case ChordQualityToken.diminished:
      addInterval(3);
      addInterval(6);
      break;
    case ChordQualityToken.augmented:
      addInterval(4);
      addInterval(8);
      break;
    case ChordQualityToken.sus2:
      addInterval(2);
      addInterval(7);
      break;
    case ChordQualityToken.sus4:
      addInterval(5);
      addInterval(7);
      break;
    case ChordQualityToken.major6:
      addInterval(4);
      addInterval(7);
      addInterval(9);
      break;
    case ChordQualityToken.minor6:
      addInterval(3);
      addInterval(7);
      addInterval(9);
      break;
    case ChordQualityToken.dominant7:
      addInterval(4);
      addInterval(7);
      addInterval(10);
      break;
    case ChordQualityToken.dominant7sus4:
      addInterval(5);
      addInterval(7);
      addInterval(10);
      break;
    case ChordQualityToken.major7:
      addInterval(4);
      addInterval(7);
      addInterval(11);
      break;
    case ChordQualityToken.minor7:
      addInterval(3);
      addInterval(7);
      addInterval(10);
      break;
    case ChordQualityToken.minorMajor7:
      addInterval(3);
      addInterval(7);
      addInterval(11);
      break;
    case ChordQualityToken.halfDiminished7:
      addInterval(3);
      addInterval(6);
      addInterval(10);
      break;
    case ChordQualityToken.diminished7:
      addInterval(3);
      addInterval(6);
      addInterval(9);
      break;
  }

  for (final extension in extensions) {
    addInterval(extension.intervalAboveRoot);
  }

  return mask;
}
