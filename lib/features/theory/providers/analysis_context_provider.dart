import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/models/analysis_context.dart';
import '../models/note_spelling_policy.dart';
import 'selected_key_signature_provider.dart';
import 'selected_tonality_notifier.dart';

final analysisContextProvider = Provider<AnalysisContext>((ref) {
  final tonality = ref.watch(selectedTonalityProvider);
  final keySignature = ref.watch(selectedKeySignatureProvider);

  final spellingPolicy = NoteSpellingPolicy(
    preferFlats: keySignature.prefersFlats,
  );

  return AnalysisContext(
    tonality: tonality,
    keySignature: keySignature,
    spellingPolicy: spellingPolicy,
  );
});
