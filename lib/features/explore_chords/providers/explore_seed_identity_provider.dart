import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/theory/theory.dart';

import '../services/explore_seed_derivation.dart';

final exploreSeedIdentityProvider = Provider<ChordIdentity>((ref) {
  final currentChordIdentity = ref.watch(
    bestChordCandidateProvider.select((candidate) => candidate?.identity),
  );
  final input = ref.watch(chordInputProvider);
  final tonality = ref.watch(selectedTonalityProvider);

  return buildExploreSeedIdentity(
    input: input,
    tonality: tonality,
    currentChordIdentity: currentChordIdentity,
  );
});
