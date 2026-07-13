import '../../models/chord_extension.dart';
import '../../models/chord_identity.dart';
import '../../models/tonic.dart';
import '../models/chord_construction.dart';
import '../models/chord_spec.dart';
import 'chord_example_builder.dart';
import 'extension_rules.dart';

/// [state] with its spec normalized and dependent parts revalidated.
ChordConstruction normalizeChordConstruction(ChordConstruction state) {
  final spec = state.spec.normalized();
  return _withSpec(state, spec);
}

/// [state] with a new spelled root, revalidating the bass.
ChordConstruction constructionWithRoot(ChordConstruction state, Tonic root) {
  return _withValidBass(state.copyWith(root: root));
}

/// [state] with a new base quality; the fifth resets to the quality's
/// default and the seventh and extensions renormalize.
ChordConstruction constructionWithBaseQuality(
  ChordConstruction state,
  BaseQuality baseQuality,
) {
  final nextSpec = state.spec.copyWith(
    baseQuality: baseQuality,
    fifthAlteration: defaultFifthAlterationFor(baseQuality),
  );
  return _withSpec(state, nextSpec);
}

/// [state] with a new sixth/seventh selection, renormalized.
ChordConstruction constructionWithSeventhKind(
  ChordConstruction state,
  SeventhKind seventhKind,
) {
  final nextSpec = state.spec.copyWith(seventhKind: seventhKind);
  return _withSpec(state, nextSpec);
}

/// [state] with a new fifth alteration, renormalized.
ChordConstruction constructionWithFifthAlteration(
  ChordConstruction state,
  FifthAlteration fifthAlteration,
) {
  final nextSpec = state.spec.copyWith(fifthAlteration: fifthAlteration);
  return _withSpec(state, nextSpec);
}

/// [state] respecified to a complete [quality], renormalized.
ChordConstruction constructionWithQuality(
  ChordConstruction state,
  ChordQualityToken quality,
) {
  final nextSpec = ChordSpec.fromQuality(quality);
  return _withSpec(state, nextSpec);
}

ChordConstruction _withSpec(ChordConstruction state, ChordSpec spec) {
  return _withValidBass(
    state.copyWith(
      spec: spec,
      extensions: normalizeExtensionsForQuality(
        quality: spec.quality,
        extensions: state.extensions,
      ),
    ),
  );
}

/// [state] with a replacement extension set, normalized for the current
/// quality.
ChordConstruction constructionWithExtensions(
  ChordConstruction state,
  Set<ChordExtension> extensions,
) {
  return _withValidBass(
    state.copyWith(
      extensions: normalizeExtensionsForQuality(
        quality: state.quality,
        extensions: extensions,
      ),
    ),
  );
}

/// [state] with a new bass pitch class, snapped back to the root when the
/// bass is not a chord member.
ChordConstruction constructionWithBass(ChordConstruction state, int bassPc) {
  return _withValidBass(state.copyWith(bassPc: bassPc));
}

ChordConstruction _withValidBass(ChordConstruction state) {
  final pitchClasses = ChordExampleBuilder.canonicalBassPitchClasses(state);

  final bassPc = pitchClasses.contains(state.bassPc)
      ? state.bassPc
      : state.rootPc;

  return state.copyWith(bassPc: bassPc);
}
