import 'package:meta/meta.dart';

@immutable
class NoteSpellingPolicy {
  final bool preferFlats;

  const NoteSpellingPolicy({required this.preferFlats});

  const NoteSpellingPolicy.preferFlats() : preferFlats = true;
  const NoteSpellingPolicy.preferSharps() : preferFlats = false;
}
