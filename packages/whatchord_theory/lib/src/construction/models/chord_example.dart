import 'package:meta/meta.dart';

import '../../formatting/models/chord_presentation.dart';
import '../../models/chord_identity.dart';

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

  final ChordPresentation presentation;
  final ChordIdentity identity;
  final List<String> members;
  final List<String> memberDegrees;
  final Set<int> memberPitchClasses;
  final List<int> memberPitchClassesInOrder;
  final List<int> normalizedVoicing;
}
