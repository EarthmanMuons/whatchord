import 'package:meta/meta.dart';

import '../../models/chord_identity.dart';
import '../../models/scale_degree.dart';
import 'chord_symbol.dart';

/// Everything needed to present one analyzed chord: identity, rendered
/// names, spelled members, and scale-degree context.
@immutable
class ChordPresentation {
  const ChordPresentation({
    required this.identity,
    required this.symbol,
    required this.longLabel,
    required this.semanticLabel,
    required this.spokenLabel,
    required this.members,
    required this.memberDegrees,
    required this.memberPitchClasses,
    required this.scaleDegreeAnalysis,
    required this.normalizedVoicing,
  });

  /// The chord identity being presented.
  final ChordIdentity identity;

  /// The structured chord symbol (root, quality, optional bass).
  final ChordSymbol symbol;

  /// Long-form academic name (e.g. "C dominant seventh").
  final String longLabel;

  /// Accessibility label for screen readers.
  final String semanticLabel;

  /// Idiomatic spoken name (e.g. "C seven").
  final String spokenLabel;

  /// Spelled member note names, low to high.
  final List<String> members;

  /// Degree label for each member (e.g. 1, 3, 5, b7), aligned with [members].
  final List<String> memberDegrees;

  /// Member pitch classes as a set.
  final Set<int> memberPitchClasses;

  /// Scale-degree classification in the current key, when the chord is
  /// diatonic.
  final ScaleDegreeAnalysis? scaleDegreeAnalysis;

  /// Example MIDI voicing in a playable register, low to high.
  final List<int> normalizedVoicing;

  /// Shorthand for the classified degree, if any.
  ScaleDegree? get scaleDegree => scaleDegreeAnalysis?.degree;
}
