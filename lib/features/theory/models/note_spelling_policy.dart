import 'package:meta/meta.dart';

@immutable
class NoteSpellingPolicy {
  final bool preferFlats;
  const NoteSpellingPolicy({required this.preferFlats});

  static const preferSharps = NoteSpellingPolicy(preferFlats: false);
  static const preferFlatsPolicy = NoteSpellingPolicy(preferFlats: true);
}
