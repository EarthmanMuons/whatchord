import '../../domain/theory_domain.dart';
import '../models/chord_presentation.dart';
import '../models/chord_symbol.dart';
import 'chord_long_form_formatter.dart';
import 'chord_symbol_builder.dart';

abstract final class ChordPresentationBuilder {
  static ChordPresentation fromIdentity({
    required ChordIdentity identity,
    required Tonality tonality,
    required ChordNotationStyle notation,
  }) {
    final memberPitchClasses = chordMemberPitchClassesFromMask(
      rootPc: identity.rootPc,
      presentIntervalsMask: identity.presentIntervalsMask,
    );

    return ChordPresentation(
      identity: identity,
      symbol: ChordSymbolBuilder.fromIdentity(
        identity: identity,
        tonality: tonality,
        notation: notation,
      ),
      longLabel: ChordLongFormFormatter.format(
        identity: identity,
        tonality: tonality,
      ),
      members: ChordMemberSpeller.spellMembers(
        identity: identity,
        pitchClasses: memberPitchClasses,
        tonality: tonality,
      ),
      memberDegrees: ChordMemberDegreeFormatter.formatDegrees(
        identity: identity,
        pitchClasses: memberPitchClasses,
      ),
      memberPitchClasses: memberPitchClasses,
      scaleDegree: tonality.scaleDegreeForChord(identity),
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
    final notes = <int>[];

    if (identity.hasSlashBass) {
      final bassInterval = _normalizedInterval(
        identity.bassPc - identity.rootPc,
      );
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

  static int _normalizedInterval(int value) {
    final normalized = value % 12;
    return normalized < 0 ? normalized + 12 : normalized;
  }
}
