import 'package:meta/meta.dart';

import '../../models/chord_extension.dart';
import '../../models/chord_identity.dart';
import '../../models/tonic.dart';
import 'chord_spec.dart';

/// A chord being built: a spelled root, a [ChordSpec], selected extensions,
/// and a bass pitch class.
///
/// This is the working state of chord construction; the transition functions
/// in `construction_transitions.dart` evolve it while keeping every part
/// combination valid.
@immutable
class ChordConstruction {
  /// Builds a construction from a complete [quality], decomposing it into a
  /// [ChordSpec].
  factory ChordConstruction({
    required int rootPc,
    required ChordQuality quality,
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

  /// Builds a construction from spec parts, defaulting the root spelling for
  /// [rootPc].
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

  /// Builds a construction matching an analyzed [identity], optionally with
  /// an explicit [root] spelling.
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

  /// The spelled chord root, drawn from the [Tonic] vocabulary: chord
  /// symbols conventionally spell roots with the same 21 single-accidental
  /// names used for tonal centers.
  final Tonic root;

  /// The selected quality parts.
  final ChordSpec spec;

  /// The selected extensions (unmodifiable).
  final Set<ChordExtension> extensions;

  /// Pitch class of the bass (0..11).
  final int bassPc;

  /// Pitch class of the root (0..11).
  int get rootPc => root.pitchClass;

  /// The complete quality named by [spec].
  ChordQuality get quality => spec.quality;

  /// Shorthand for `spec.baseQuality`.
  BaseQuality get baseQuality => spec.baseQuality;

  /// Shorthand for `spec.seventhKind`.
  SeventhKind get seventhKind => spec.seventhKind;

  /// Shorthand for `spec.fifthAlteration`.
  FifthAlteration get fifthAlteration => spec.fifthAlteration;

  /// A copy with the given parts replaced.
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
