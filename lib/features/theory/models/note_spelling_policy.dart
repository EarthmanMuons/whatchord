import 'package:meta/meta.dart';

@immutable
class NoteSpellingPolicy {
  final bool preferFlats;
  const NoteSpellingPolicy({required this.preferFlats});
}
