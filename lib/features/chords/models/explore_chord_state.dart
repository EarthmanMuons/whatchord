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

  factory ExploreChordState.fromSpec({
    required int rootPc,
    required ExploreChordSpec spec,
    required Set<ChordExtension> extensions,
    required int bassPc,
  }) {
    return ExploreChordState._(
      root: Tonic.forPitchClass(rootPc),
      spec: spec,
      extensions: Set<ChordExtension>.unmodifiable(extensions),
      bassPc: bassPc,
    );
  }

  const ExploreChordState._({
    required this.root,
    required this.spec,
    required this.extensions,
    required this.bassPc,
  });

  factory ExploreChordState.fromIdentity(
    ChordIdentity identity, {
    Tonic? root,
  }) {
    return ExploreChordState._(
      root: root ?? Tonic.forPitchClass(identity.rootPc),
      spec: ExploreChordSpec.fromQuality(identity.quality),
      extensions: Set<ChordExtension>.unmodifiable(identity.extensions),
      bassPc: identity.bassPc,
    );
  }

  final Tonic root;
  final ExploreChordSpec spec;
  final Set<ChordExtension> extensions;
  final int bassPc;

  int get rootPc => root.pitchClass;

  ChordQualityToken get quality => spec.quality;

  ExploreBaseQuality get baseQuality => spec.baseQuality;

  ExploreSeventhKind get seventhKind => spec.seventhKind;

  ExploreFifthAlteration get fifthAlteration => spec.fifthAlteration;

  ExploreChordState copyWith({
    Tonic? root,
    ExploreChordSpec? spec,
    Set<ChordExtension>? extensions,
    int? bassPc,
  }) {
    return ExploreChordState._(
      root: root ?? this.root,
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
          other.root == root &&
          other.spec == spec &&
          other.bassPc == bassPc &&
          _setEquals(other.extensions, extensions);

  @override
  int get hashCode =>
      Object.hash(root, spec, bassPc, Object.hashAllUnordered(extensions));

  static bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }
}
