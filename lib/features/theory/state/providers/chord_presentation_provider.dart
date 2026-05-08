import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/models/chord_presentation.dart';
import '../../presentation/services/chord_presentation_builder.dart';
import 'analysis_context_provider.dart';
import 'chord_candidates_providers.dart';
import 'theory_preferences_notifier.dart';

final chordPresentationProvider = Provider<ChordPresentation?>((ref) {
  final identity = ref.watch(
    bestChordCandidateProvider.select((candidate) => candidate?.identity),
  );
  if (identity == null) return null;

  final tonality = ref.watch(analysisContextProvider.select((c) => c.tonality));
  final notation = ref.watch(chordNotationStyleProvider);

  return ChordPresentationBuilder.fromIdentity(
    identity: identity,
    tonality: tonality,
    notation: notation,
  );
});
