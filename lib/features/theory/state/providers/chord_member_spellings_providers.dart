import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatchord/whatchord.dart';

import 'analysis_context_provider.dart';
import 'chord_presentation_provider.dart';

/// Role-aware spelled chord members for the current voicing (unique pitch classes).
final chordMemberSpellingsProvider = Provider<List<String>>((ref) {
  return ref.watch(chordPresentationProvider)?.members ?? const <String>[];
});

/// Role-aware degree tokens for the current voicing, relative to chord root.
///
/// Example: [1, b3, 5, b9, #11].
final chordMemberDegreesProvider = Provider<List<String>>((ref) {
  return ref.watch(chordPresentationProvider)?.memberDegrees ??
      const <String>[];
});

/// Role-aware spelled chord members keyed by pitch class (0..11).
///
/// Preferred over a list of strings when a stable label per key is needed.
final chordMemberSpellingsByPcProvider = Provider<Map<int, String>>((ref) {
  final presentation = ref.watch(chordPresentationProvider);
  if (presentation == null) return const <int, String>{};

  final id = presentation.identity;
  final tonality = ref.watch(analysisContextProvider.select((c) => c.tonality));
  // Use the chord-aware root spelling (matching the identity card/symbol), not
  // the plain chromatic noteNameForPitchClass. Otherwise a non-diatonic root such as Bb in C
  // major resolves to A#, and every member is spelled relative to A# (Cx, E#,
  // Gx, B#) even though the card reads Bbmaj9.
  final rootName = spellChordRoot(id, tonality: tonality);

  // Map every pitch class -> role-aware spelling for this identity.
  // (Even if a given pc isn't currently sounding, this is still cheap.)
  final map = <int, String>{};
  for (var pc = 0; pc < 12; pc++) {
    final role = id.toneRolesByInterval[intervalAboveRoot(pc, id.rootPc)];

    map[pc] = spellPitchClass(
      pc,
      tonality: tonality,
      chordRootName: rootName,
      role: role,
    );
  }

  return Map<int, String>.unmodifiable(map);
});
