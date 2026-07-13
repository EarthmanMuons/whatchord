import 'package:whatchord_theory/whatchord_theory.dart';

ExploreChordState normalizeExploreChordState(ExploreChordState state) {
  final spec = state.spec.normalized();
  return _withSpec(state, spec);
}

ExploreChordState exploreStateWithRoot(ExploreChordState state, Tonic root) {
  return _withValidBass(state.copyWith(root: root));
}

ExploreChordState exploreStateWithBaseQuality(
  ExploreChordState state,
  ExploreBaseQuality baseQuality,
) {
  final nextSpec = state.spec.copyWith(
    baseQuality: baseQuality,
    fifthAlteration: defaultFifthAlterationFor(baseQuality),
  );
  return _withSpec(state, nextSpec);
}

ExploreChordState exploreStateWithSeventhKind(
  ExploreChordState state,
  ExploreSeventhKind seventhKind,
) {
  final nextSpec = state.spec.copyWith(seventhKind: seventhKind);
  return _withSpec(state, nextSpec);
}

ExploreChordState exploreStateWithFifthAlteration(
  ExploreChordState state,
  ExploreFifthAlteration fifthAlteration,
) {
  final nextSpec = state.spec.copyWith(fifthAlteration: fifthAlteration);
  return _withSpec(state, nextSpec);
}

ExploreChordState exploreStateWithQuality(
  ExploreChordState state,
  ChordQualityToken quality,
) {
  final nextSpec = ExploreChordSpec.fromQuality(quality);
  return _withSpec(state, nextSpec);
}

ExploreChordState _withSpec(ExploreChordState state, ExploreChordSpec spec) {
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

ExploreChordState exploreStateWithExtensions(
  ExploreChordState state,
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

ExploreChordState exploreStateWithBass(ExploreChordState state, int bassPc) {
  return _withValidBass(state.copyWith(bassPc: bassPc));
}

ExploreChordState _withValidBass(ExploreChordState state) {
  final pitchClasses = ExploreChordExampleBuilder.canonicalBassPitchClasses(
    state,
  );

  final bassPc = pitchClasses.contains(state.bassPc)
      ? state.bassPc
      : state.rootPc;

  return state.copyWith(bassPc: bassPc);
}
