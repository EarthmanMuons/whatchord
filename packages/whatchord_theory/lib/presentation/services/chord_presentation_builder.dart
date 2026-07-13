import 'package:whatchord_theory/whatchord_theory.dart';

abstract final class ChordPresentationBuilder {
  static ChordPresentation fromIdentity({
    required ChordIdentity identity,
    required Tonality tonality,
    required ChordNotationStyle notation,
    NoteNameSystem noteNameSystem = NoteNameSystem.international,
    String? rootName,
  }) {
    final memberPitchClasses = chordMemberPitchClassesFromMask(
      rootPc: identity.rootPc,
      presentIntervalsMask: identity.presentIntervalsMask,
    );

    // Resolve the displayed root once so the symbol and the scale-degree label
    // are always derived from the same spelling and cannot diverge.
    final resolvedRootName =
        rootName ?? spellChordRoot(identity, tonality: tonality);

    return ChordPresentation(
      identity: identity,
      symbol: ChordSymbolBuilder.fromIdentity(
        identity: identity,
        tonality: tonality,
        notation: notation,
        rootName: resolvedRootName,
      ),
      longLabel: ChordLongFormFormatter.format(
        identity: identity,
        tonality: tonality,
        noteNameSystem: noteNameSystem,
        rootNameOverride: resolvedRootName,
      ),
      semanticLabel: ChordLongFormFormatter.format(
        identity: identity,
        tonality: tonality,
        noteNameSystem: noteNameSystem,
        accidentalStyle: ChordLongFormAccidentalStyle.plainText,
        rootNameOverride: resolvedRootName,
      ),
      spokenLabel: ChordSpokenNameFormatter.format(
        identity: identity,
        tonality: tonality,
        noteNameSystem: noteNameSystem,
        rootNameOverride: resolvedRootName,
      ),
      members: ChordMemberSpeller.spellMembers(
        identity: identity,
        pitchClasses: memberPitchClasses,
        tonality: tonality,
        rootName: resolvedRootName,
      ),
      memberDegrees: ChordMemberDegreeFormatter.formatDegrees(
        identity: identity,
        pitchClasses: memberPitchClasses,
      ),
      memberPitchClasses: memberPitchClasses,
      scaleDegreeAnalysis: tonality.scaleDegreeAnalysisForChord(
        identity,
        rootName: resolvedRootName,
      ),
      normalizedVoicing: normalizedVoicingForIdentity(identity),
    );
  }

  static Set<int> chordMemberPitchClassesFromMask({
    required int rootPc,
    required int presentIntervalsMask,
  }) {
    final pitchClasses = <int>{};
    for (var interval = 0; interval < 12; interval++) {
      final bit = 1 << interval;
      if ((presentIntervalsMask & bit) == 0) continue;
      pitchClasses.add((rootPc + interval) % 12);
    }
    return Set<int>.unmodifiable(pitchClasses);
  }

  static List<int> sortedIntervalsForIdentity(ChordIdentity identity) {
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

  static List<int> normalizedVoicingForIdentity(ChordIdentity identity) {
    final intervals = sortedIntervalsForIdentity(identity);
    if (intervals.isEmpty) return const <int>[];

    final rootMidi = 60 + identity.rootPc;
    final bassInterval = identity.hasSlashBass
        ? _normalizedInterval(identity.bassPc - identity.rootPc)
        : 0;
    final bassMidi = _bassMidiForNormalizedVoicing(
      rootMidi: rootMidi,
      bassInterval: bassInterval,
    );
    final voicingIntervals = identity.hasSlashBass
        ? _compactIntervalsAboveBass(
            intervals: intervals,
            bassInterval: bassInterval,
          )
        : _rootPositionStackIntervals(intervals, identity);
    final notes = <int>[];

    for (final interval in voicingIntervals) {
      final offset = identity.hasSlashBass
          ? _normalizedInterval(interval - bassInterval)
          : _rootPositionStackOffset(interval, identity);
      var midi = bassMidi + offset;
      while (notes.isNotEmpty && midi <= notes.last) {
        midi += 12;
      }
      notes.add(midi);
    }

    return List<int>.unmodifiable(notes);
  }

  static List<int> _compactIntervalsAboveBass({
    required List<int> intervals,
    required int bassInterval,
  }) {
    final out = intervals.toList()
      ..sort((a, b) {
        final offsetA = _normalizedInterval(a - bassInterval);
        final offsetB = _normalizedInterval(b - bassInterval);
        final primary = offsetA.compareTo(offsetB);
        if (primary != 0) return primary;
        return a.compareTo(b);
      });

    return out;
  }

  static List<int> _rootPositionStackIntervals(
    List<int> intervals,
    ChordIdentity identity,
  ) {
    final out = intervals.toList()
      ..sort((a, b) {
        final offsetA = _rootPositionStackOffset(a, identity);
        final offsetB = _rootPositionStackOffset(b, identity);
        final primary = offsetA.compareTo(offsetB);
        if (primary != 0) return primary;
        return a.compareTo(b);
      });

    return out;
  }

  static int _rootPositionStackOffset(int interval, ChordIdentity identity) {
    final role = identity.toneRolesByInterval[interval];
    return switch (role) {
      ChordToneRole.flat9 ||
      ChordToneRole.nine ||
      ChordToneRole.sharp9 ||
      ChordToneRole.add9 ||
      ChordToneRole.addSharp9 ||
      ChordToneRole.eleven ||
      ChordToneRole.sharp11 ||
      ChordToneRole.add11 ||
      ChordToneRole.flat13 ||
      ChordToneRole.thirteen ||
      ChordToneRole.add13 => interval + 12,
      _ => interval,
    };
  }

  static int _fallbackDegreeRank(int interval) {
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

  static int _bassMidiForNormalizedVoicing({
    required int rootMidi,
    required int bassInterval,
  }) {
    return rootMidi + bassInterval;
  }

  static int _normalizedInterval(int value) {
    final normalized = value % 12;
    return normalized < 0 ? normalized + 12 : normalized;
  }
}
