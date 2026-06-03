import 'package:meta/meta.dart';

import 'package:whatchord/features/theory/theory.dart';

import 'explore_chord_spec.dart';

@immutable
class ExploreChordState {
  factory ExploreChordState({
    required int rootPc,
    required ChordQualityToken quality,
    required Set<ChordExtension> extensions,
    required int bassPc,
  }) {
    return ExploreChordState.fromSpec(
      rootPc: rootPc,
      spec: ExploreChordSpec.fromQuality(quality),
      extensions: extensions,
      bassPc: bassPc,
    );
  }

  const ExploreChordState.fromSpec({
    required this.rootPc,
    required this.spec,
    required this.extensions,
    required this.bassPc,
  });

  factory ExploreChordState.fromIdentity(ChordIdentity identity) {
    return ExploreChordState(
      rootPc: identity.rootPc,
      quality: identity.quality,
      extensions: Set<ChordExtension>.unmodifiable(identity.extensions),
      bassPc: identity.bassPc,
    );
  }

  final int rootPc;
  final ExploreChordSpec spec;
  final Set<ChordExtension> extensions;
  final int bassPc;

  ChordQualityToken get quality => spec.quality;

  ExploreBaseQuality get baseQuality => spec.baseQuality;

  ExploreSeventhKind get seventhKind => spec.seventhKind;

  ExploreFifthAlteration get fifthAlteration => spec.fifthAlteration;

  ExploreChordState copyWith({
    int? rootPc,
    ExploreChordSpec? spec,
    Set<ChordExtension>? extensions,
    int? bassPc,
  }) {
    return ExploreChordState.fromSpec(
      rootPc: rootPc ?? this.rootPc,
      spec: spec ?? this.spec,
      extensions: Set<ChordExtension>.unmodifiable(
        extensions ?? this.extensions,
      ),
      bassPc: bassPc ?? this.bassPc,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExploreChordState &&
          other.rootPc == rootPc &&
          other.spec == spec &&
          other.bassPc == bassPc &&
          _setEquals(other.extensions, extensions);

  @override
  int get hashCode =>
      Object.hash(rootPc, spec, bassPc, Object.hashAllUnordered(extensions));

  static bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }
}
