import 'package:meta/meta.dart';

import '../models/key_signature.dart';
import '../models/note_spelling_policy.dart';
import '../models/tonality.dart';

/// Context that can bias chord analysis and control spelling/formatting.
///
/// This keeps the analyzer signature stable even as we add more bias sources.
@immutable
class AnalysisContext {
  final Tonality tonality;
  final KeySignature keySignature;
  final NoteSpellingPolicy spellingPolicy;

  const AnalysisContext({
    required this.tonality,
    required this.keySignature,
    required this.spellingPolicy,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalysisContext &&
          tonality == other.tonality &&
          keySignature.accidentalCount == other.keySignature.accidentalCount &&
          spellingPolicy.preferFlats == other.spellingPolicy.preferFlats;

  @override
  int get hashCode => Object.hash(
    tonality,
    keySignature.accidentalCount,
    spellingPolicy.preferFlats,
  );
}
