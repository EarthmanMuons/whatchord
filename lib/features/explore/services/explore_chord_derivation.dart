import 'package:whatchord/features/theory/domain/theory_domain.dart';

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

  final memberPitchClasses = chordMemberPitchClassesFromMask(
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
    case ChordQualityToken.power5:
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

Set<int> chordMemberPitchClassesFromMask({
  required int rootPc,
  required int presentIntervalsMask,
}) {
  final pitchClasses = <int>{};
  for (var interval = 0; interval < 12; interval++) {
    final bit = 1 << interval;
    if ((presentIntervalsMask & bit) == 0) continue;
    pitchClasses.add((rootPc + interval) % 12);
  }
  return pitchClasses;
}

List<int> sortedIntervalsForIdentity(ChordIdentity identity) {
  final intervals = <int>[];
  for (var interval = 0; interval < 12; interval++) {
    final bit = 1 << interval;
    if ((identity.presentIntervalsMask & bit) == 0) continue;
    intervals.add(interval);
  }

  intervals.sort((a, b) {
    final roleA = identity.toneRolesByInterval[a];
    final roleB = identity.toneRolesByInterval[b];

    final rankA = roleA?.degreeFromRoot ?? _fallbackDegreeRank(a);
    final rankB = roleB?.degreeFromRoot ?? _fallbackDegreeRank(b);
    final primary = rankA.compareTo(rankB);
    if (primary != 0) return primary;
    return a.compareTo(b);
  });

  return List<int>.unmodifiable(intervals);
}

List<int> normalizedVoicingForIdentity(ChordIdentity identity) {
  final intervals = sortedIntervalsForIdentity(identity);
  if (intervals.isEmpty) return const <int>[];

  final rootMidi = 60 + identity.rootPc;
  final notes = <int>[];

  if (identity.hasSlashBass) {
    final bassInterval = _normalizedInterval(identity.bassPc - identity.rootPc);
    var bassMidi = rootMidi + bassInterval;
    while (bassMidi >= rootMidi) {
      bassMidi -= 12;
    }
    notes.add(bassMidi);
  }

  for (final interval in intervals) {
    var midi = rootMidi + interval;
    while (notes.isNotEmpty && midi <= notes.last) {
      midi += 12;
    }
    notes.add(midi);
  }

  return List<int>.unmodifiable(notes);
}

int _fallbackDegreeRank(int interval) {
  return switch (interval) {
    0 => 1,
    1 || 2 => 2,
    3 || 4 => 3,
    5 || 6 => 4,
    7 || 8 => 5,
    9 => 6,
    10 || 11 => 7,
    _ => 99,
  };
}

int _normalizedInterval(int value) {
  final normalized = value % 12;
  return normalized < 0 ? normalized + 12 : normalized;
}
