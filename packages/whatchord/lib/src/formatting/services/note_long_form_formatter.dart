import '../models/chord_symbol.dart';
import 'note_display_formatter.dart';

/// Renders note names in plain English (e.g. "F sharp").
abstract final class NoteLongFormFormatter {
  /// Converts a canonical ASCII note name to its plain-English form.
  static String format(
    String noteName, {
    NoteNameSystem noteNameSystem = NoteNameSystem.international,
  }) {
    return noteSemanticLabel(noteName, noteNameSystem: noteNameSystem);
  }
}
