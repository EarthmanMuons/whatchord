import 'package:meta/meta.dart';

/// Enharmonic spelling preference when no stronger context decides.
@immutable
class NoteSpellingPolicy {
  /// Whether ambiguous pitch classes spell as flats rather than sharps.
  final bool preferFlats;

  const NoteSpellingPolicy({required this.preferFlats});
}
