import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/input/input.dart';

import '../../domain/theory_domain.dart';
import 'analysis_context_provider.dart';
import 'analysis_mode_provider.dart';
import 'chord_candidates_providers.dart';

/// Role-aware spelled chord members for the current voicing (unique pitch classes).
final chordMemberSpellingsProvider = Provider<List<String>>((ref) {
  final mode = ref.watch(analysisModeProvider);
  if (mode != AnalysisMode.chord) return const <String>[];

  final best = ref.watch(bestChordCandidateProvider);
  if (best == null) return const <String>[];

  final midis = ref.watch(soundingNoteNumbersSortedProvider);
  if (midis.isEmpty) return const <String>[];

  final pcs = midis.map((m) => m % 12).toSet();

  final tonality = ref.watch(analysisContextProvider.select((c) => c.tonality));

  return ChordMemberSpeller.spellMembers(
    identity: best.identity,
    pitchClasses: pcs,
    tonality: tonality,
  );
});

/// Role-aware degree tokens for the current voicing, relative to chord root.
///
/// Example: [1, b3, 5, b9, #11].
final chordMemberDegreesProvider = Provider<List<String>>((ref) {
  final mode = ref.watch(analysisModeProvider);
  if (mode != AnalysisMode.chord) return const <String>[];

  final best = ref.watch(bestChordCandidateProvider);
  if (best == null) return const <String>[];

  final midis = ref.watch(soundingNoteNumbersSortedProvider);
  if (midis.isEmpty) return const <String>[];

  final pcs = midis.map((m) => m % 12).toSet();

  return ChordMemberDegreeFormatter.formatDegrees(
    identity: best.identity,
    pitchClasses: pcs,
  );
});

/// Role-aware spelled chord members keyed by pitch class (0..11).
///
/// This is preferred over a list of strings when we need a stable label per key/note.
final chordMemberSpellingsByPcProvider = Provider<Map<int, String>>((ref) {
  final mode = ref.watch(analysisModeProvider);
  if (mode != AnalysisMode.chord) return const <int, String>{};

  final best = ref.watch(bestChordCandidateProvider);
  if (best == null) return const <int, String>{};

  final id = best.identity;
  final tonality = ref.watch(analysisContextProvider.select((c) => c.tonality));

  final rootName = pcToName(id.rootPc, tonality: tonality);

  // Map every pitch class -> role-aware spelling for this identity.
  // (Even if a given pc isn't currently sounding, this is still cheap.)
  final map = <int, String>{};
  for (var pc = 0; pc < 12; pc++) {
    final interval = (pc - id.rootPc) % 12;
    final normInterval = interval < 0 ? interval + 12 : interval;
    final role = id.toneRolesByInterval[normInterval];

    map[pc] = spellPitchClass(
      pc,
      tonality: tonality,
      chordRootName: rootName,
      role: role,
    );
  }

  return Map<int, String>.unmodifiable(map);
});
