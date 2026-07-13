import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/theory/theory.dart';

final exploreSeedIdentityProvider = Provider<ChordIdentity>((ref) {
  final currentChordIdentity = ref.watch(
    bestChordCandidateProvider.select((candidate) => candidate?.identity),
  );
  final input = ref.watch(chordInputProvider);
  final tonality = ref.watch(selectedTonalityProvider);

  return buildSeedIdentity(
    input: input,
    tonality: tonality,
    currentChordIdentity: currentChordIdentity,
  );
});
