import 'package:whatchord/features/theory/theory.dart';

import '../models/explore_chord_state.dart';
import 'explore_chord_example_builder.dart';
import 'explore_chord_options.dart';

ExploreChordState normalizeExploreChordState(ExploreChordState state) {
  return _withValidBass(
    state.copyWith(
      extensions: normalizeExtensionsForQuality(
        quality: state.quality,
        extensions: state.extensions,
      ),
    ),
  );
}

ExploreChordState exploreStateWithRoot(ExploreChordState state, int rootPc) {
  return _withValidBass(state.copyWith(rootPc: rootPc));
}

ExploreChordState exploreStateWithQuality(
  ExploreChordState state,
  ChordQualityToken quality,
) {
  return _withValidBass(
    state.copyWith(
      quality: quality,
      extensions: normalizeExtensionsForQuality(
        quality: quality,
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
