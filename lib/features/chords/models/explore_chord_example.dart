import 'package:meta/meta.dart';

import 'package:whatchord/features/theory/theory.dart';

@immutable
class ExploreChordExample {
  const ExploreChordExample({
    required this.presentation,
    required this.identity,
    required this.members,
    required this.memberDegrees,
    required this.memberPitchClasses,
    required this.memberPitchClassesInOrder,
    required this.normalizedVoicing,
  });

  final ChordPresentation presentation;
  final ChordIdentity identity;
  final List<String> members;
  final List<String> memberDegrees;
  final Set<int> memberPitchClasses;
  final List<int> memberPitchClassesInOrder;
  final List<int> normalizedVoicing;
}
