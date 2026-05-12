import 'package:whatchord/features/theory/theory.dart';

import '../models/explore_chord_example.dart';
import '../models/explore_chord_state.dart';
import 'explore_chord_derivation.dart';

abstract final class ExploreChordExampleBuilder {
  static Set<int> canonicalBassPitchClasses(ExploreChordState state) {
    final intervals = _canonicalExampleIntervals(state);
    return Set<int>.unmodifiable(
      intervals.map((interval) => (state.rootPc + interval) % 12),
    );
  }

  static ExploreChordExample build({
    required ExploreChordState state,
    required Tonality tonality,
    required ChordNotationStyle notation,
  }) {
    final presentationIdentity = buildExploreChordIdentity(state);
    final presentation = ChordPresentationBuilder.fromIdentity(
      identity: presentationIdentity,
      tonality: tonality,
      notation: notation,
    );

    final exampleIntervals = _canonicalExampleIntervals(state);
    final exampleExtensions = _canonicalExampleExtensions(
      state.quality,
      state.extensions,
    );
    final exampleMask = _maskOfIntervals(exampleIntervals);
    final toneRoles = ChordToneRoles.build(
      quality: state.quality,
      extensions: exampleExtensions,
      relMask: exampleMask,
    );
    final pitchClasses =
        ChordPresentationBuilder.chordMemberPitchClassesFromMask(
          rootPc: state.rootPc,
          presentIntervalsMask: exampleMask,
        );
    final bassPc = pitchClasses.contains(state.bassPc)
        ? state.bassPc
        : state.rootPc;
    final identity = ChordIdentity(
      rootPc: state.rootPc,
      bassPc: bassPc,
      quality: state.quality,
      extensions: exampleExtensions,
      toneRolesByInterval: toneRoles,
      presentIntervalsMask: exampleMask,
    );
    final orderedPitchClasses = exampleIntervals
        .map((interval) => (state.rootPc + interval) % 12)
        .toList(growable: false);

    return ExploreChordExample(
      presentation: presentation,
      identity: identity,
      members: _spellMembersInIntervalOrder(
        identity: identity,
        intervals: exampleIntervals,
        tonality: tonality,
      ),
      memberDegrees: _formatDegreesInIntervalOrder(
        identity: identity,
        intervals: exampleIntervals,
      ),
      memberPitchClasses: pitchClasses,
      memberPitchClassesInOrder: orderedPitchClasses,
      normalizedVoicing: _canonicalVoicing(
        rootPc: state.rootPc,
        bassPc: bassPc,
        intervals: exampleIntervals,
        identity: identity,
      ),
    );
  }

  static List<int> _canonicalExampleIntervals(ExploreChordState state) {
    final intervals = <int>{...coreIntervalsForQuality(state.quality)};
    final extensions = _canonicalExampleExtensions(
      state.quality,
      state.extensions,
    );

    for (final extension in extensions) {
      intervals.add(extension.intervalAboveRoot);
    }

    final roles = ChordToneRoles.build(
      quality: state.quality,
      extensions: extensions,
      relMask: _maskOfIntervals(intervals),
    );
    final ordered = intervals.toList()
      ..sort((a, b) {
        final primary = _sortRank(
          a,
          roles[a],
        ).compareTo(_sortRank(b, roles[b]));
        if (primary != 0) return primary;
        return a.compareTo(b);
      });
    return List<int>.unmodifiable(ordered);
  }

  static Set<ChordExtension> _canonicalExampleExtensions(
    ChordQualityToken quality,
    Set<ChordExtension> selected,
  ) {
    if (!quality.isSeventhFamily) {
      return _canonicalTriadLikeExampleExtensions(quality, selected);
    }

    final out = <ChordExtension>{...selected};
    final hasAlteredNinth =
        out.contains(ChordExtension.flat9) ||
        out.contains(ChordExtension.sharp9);

    if (!hasAlteredNinth &&
        (out.contains(ChordExtension.eleven) ||
            out.contains(ChordExtension.thirteen))) {
      out.add(ChordExtension.nine);
    }

    return Set<ChordExtension>.unmodifiable(out);
  }

  static Set<ChordExtension> _canonicalTriadLikeExampleExtensions(
    ChordQualityToken quality,
    Set<ChordExtension> selected,
  ) {
    final out = <ChordExtension>{...selected};
    if (!quality.isSeventhFamily &&
        !coreIntervalsForQuality(
          quality,
        ).contains(ChordExtension.add9.intervalAboveRoot) &&
        !out.contains(ChordExtension.add9) &&
        (out.contains(ChordExtension.add11) ||
            out.contains(ChordExtension.sharp11) ||
            out.contains(ChordExtension.add13))) {
      out.add(ChordExtension.add9);
    }
    return Set<ChordExtension>.unmodifiable(out);
  }

  static List<int> _canonicalVoicing({
    required int rootPc,
    required int bassPc,
    required List<int> intervals,
    required ChordIdentity identity,
  }) {
    if (intervals.isEmpty) return const <int>[];

    final bassInterval = _normalizedInterval(bassPc - rootPc);
    final orderedIntervals = identity.hasSlashBass
        ? _intervalsAboveBass(intervals, bassInterval)
        : intervals;
    final bassMidi = 60 + rootPc + bassInterval;
    final notes = <int>[];

    for (final interval in orderedIntervals) {
      final offset = identity.hasSlashBass
          ? _normalizedInterval(interval - bassInterval)
          : _octaveAdjustedOffset(interval, identity);
      var midi = bassMidi + offset;
      while (notes.isNotEmpty && midi <= notes.last) {
        midi += 12;
      }
      notes.add(midi);
    }

    return List<int>.unmodifiable(notes);
  }

  static List<int> _intervalsAboveBass(List<int> intervals, int bassInterval) {
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

  static int _octaveAdjustedOffset(int interval, ChordIdentity identity) {
    final role = identity.toneRolesByInterval[interval];
    return switch (role) {
      ChordToneRole.flat9 ||
      ChordToneRole.nine ||
      ChordToneRole.sharp9 ||
      ChordToneRole.add9 ||
      ChordToneRole.eleven ||
      ChordToneRole.sharp11 ||
      ChordToneRole.add11 ||
      ChordToneRole.flat13 ||
      ChordToneRole.thirteenth ||
      ChordToneRole.add13 => interval + 12,
      _ => interval,
    };
  }

  static int _sortRank(int interval, ChordToneRole? role) {
    if (role != null) {
      return switch (role) {
        ChordToneRole.root => 10,
        ChordToneRole.sus2 => 20,
        ChordToneRole.minor3 || ChordToneRole.major3 => 30,
        ChordToneRole.sus4 => 40,
        ChordToneRole.flat5 ||
        ChordToneRole.perfect5 ||
        ChordToneRole.sharp5 => 50,
        ChordToneRole.sixth => 60,
        ChordToneRole.dim7 || ChordToneRole.flat7 || ChordToneRole.major7 => 70,
        ChordToneRole.flat9 ||
        ChordToneRole.nine ||
        ChordToneRole.sharp9 ||
        ChordToneRole.add9 => 80,
        ChordToneRole.eleven ||
        ChordToneRole.sharp11 ||
        ChordToneRole.add11 => 90,
        ChordToneRole.flat13 ||
        ChordToneRole.thirteenth ||
        ChordToneRole.add13 => 100,
      };
    }

    return switch (interval) {
      0 => 10,
      2 => 20,
      3 || 4 => 30,
      5 => 40,
      7 || 8 => 50,
      9 => 60,
      10 || 11 => 70,
      1 => 80,
      6 => 90,
      _ => 990,
    };
  }

  static List<String> _spellMembersInIntervalOrder({
    required ChordIdentity identity,
    required List<int> intervals,
    required Tonality tonality,
  }) {
    return [
      for (final interval in intervals)
        ChordMemberSpeller.spellMembers(
          identity: identity,
          pitchClasses: {(identity.rootPc + interval) % 12},
          tonality: tonality,
        ).single,
    ];
  }

  static List<String> _formatDegreesInIntervalOrder({
    required ChordIdentity identity,
    required List<int> intervals,
  }) {
    return [
      for (final interval in intervals)
        ChordMemberDegreeFormatter.formatDegrees(
          identity: identity,
          pitchClasses: {(identity.rootPc + interval) % 12},
        ).single,
    ];
  }

  static int _maskOfIntervals(Iterable<int> intervals) {
    var mask = 0;
    for (final interval in intervals) {
      mask |= 1 << (interval % 12);
    }
    return mask;
  }

  static int _normalizedInterval(int value) {
    final normalized = value % 12;
    return normalized < 0 ? normalized + 12 : normalized;
  }
}
