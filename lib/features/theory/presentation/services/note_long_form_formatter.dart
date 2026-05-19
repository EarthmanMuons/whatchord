import '../models/chord_symbol.dart';
import 'note_display_formatter.dart';

abstract final class NoteLongFormFormatter {
  /// Convert canonical ASCII names to plain-English
  static String format(
    String noteName, {
    NoteNameSystem noteNameSystem = NoteNameSystem.international,
  }) {
    return noteSemanticLabel(noteName, noteNameSystem: noteNameSystem);
  }
}
