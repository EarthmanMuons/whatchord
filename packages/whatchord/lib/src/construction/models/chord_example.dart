import 'package:meta/meta.dart';

import '../../formatting/models/chord_presentation.dart';
import '../../models/chord_identity.dart';

/// A canonical rendering of a constructed chord: its names, member notes,
/// and an example voicing.
@immutable
class ChordExample {
  const ChordExample({
    required this.presentation,
    required this.identity,
    required this.members,
    required this.memberDegrees,
    required this.memberPitchClasses,
    required this.memberPitchClassesInOrder,
    required this.normalizedVoicing,
  });

  /// Rendered names for the chord (symbol, spoken, long form).
  final ChordPresentation presentation;

  /// The chord identity the example realizes.
  final ChordIdentity identity;

  /// Spelled member note names, low to high (e.g. C, E, G, Bb).
  final List<String> members;

  /// Degree label for each member (e.g. 1, 3, 5, b7), aligned with [members].
  final List<String> memberDegrees;

  /// Member pitch classes as a set.
  final Set<int> memberPitchClasses;

  /// Member pitch classes in stack order, aligned with [members].
  final List<int> memberPitchClassesInOrder;

  /// Example MIDI voicing in a playable register, low to high.
  final List<int> normalizedVoicing;
}
