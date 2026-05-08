import 'package:meta/meta.dart';

import 'package:whatchord/features/theory/theory.dart';

@immutable
class ExploreChordState {
  const ExploreChordState({
    required this.rootPc,
    required this.quality,
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
  final ChordQualityToken quality;
  final Set<ChordExtension> extensions;
  final int bassPc;

  ExploreChordState copyWith({
    int? rootPc,
    ChordQualityToken? quality,
    Set<ChordExtension>? extensions,
    int? bassPc,
  }) {
    return ExploreChordState(
      rootPc: rootPc ?? this.rootPc,
      quality: quality ?? this.quality,
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
          other.quality == quality &&
          other.bassPc == bassPc &&
          _setEquals(other.extensions, extensions);

  @override
  int get hashCode =>
      Object.hash(rootPc, quality, bassPc, Object.hashAllUnordered(extensions));

  static bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }
}
