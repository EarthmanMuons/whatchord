import 'package:meta/meta.dart';

import '../../models/chord_extension.dart';
import '../../models/chord_identity.dart';
import '../../models/tonic.dart';
import 'chord_spec.dart';

@immutable
class ChordConstruction {
  factory ChordConstruction({
    required int rootPc,
    required ChordQualityToken quality,
    required Set<ChordExtension> extensions,
    required int bassPc,
  }) {
    return ChordConstruction.fromSpec(
      rootPc: rootPc,
      spec: ChordSpec.fromQuality(quality),
      extensions: extensions,
      bassPc: bassPc,
    );
  }

  factory ChordConstruction.fromSpec({
    required int rootPc,
    required ChordSpec spec,
    required Set<ChordExtension> extensions,
    required int bassPc,
  }) {
    return ChordConstruction._(
      root: Tonic.forPitchClass(rootPc),
      spec: spec,
      extensions: Set<ChordExtension>.unmodifiable(extensions),
      bassPc: bassPc,
    );
  }

  const ChordConstruction._({
    required this.root,
    required this.spec,
    required this.extensions,
    required this.bassPc,
  });

  factory ChordConstruction.fromIdentity(
    ChordIdentity identity, {
    Tonic? root,
  }) {
    return ChordConstruction._(
      root: root ?? Tonic.forPitchClass(identity.rootPc),
      spec: ChordSpec.fromQuality(identity.quality),
      extensions: Set<ChordExtension>.unmodifiable(identity.extensions),
      bassPc: identity.bassPc,
    );
  }

  final Tonic root;
  final ChordSpec spec;
  final Set<ChordExtension> extensions;
  final int bassPc;

  int get rootPc => root.pitchClass;

  ChordQualityToken get quality => spec.quality;

  BaseQuality get baseQuality => spec.baseQuality;

  SeventhKind get seventhKind => spec.seventhKind;

  FifthAlteration get fifthAlteration => spec.fifthAlteration;

  ChordConstruction copyWith({
    Tonic? root,
    ChordSpec? spec,
    Set<ChordExtension>? extensions,
    int? bassPc,
  }) {
    return ChordConstruction._(
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
      other is ChordConstruction &&
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
