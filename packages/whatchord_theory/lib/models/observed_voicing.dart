import 'package:meta/meta.dart';

/// Optional voicing evidence for chord analysis.
///
/// `ChordInput` carries only the pitch-class core (mask + bass + count). Live
/// MIDI also knows the octaves, which musicians use to choose between
/// equally-valid names (an Am7 stacked above an isolated D bass reads as Am7/D,
/// not D9sus4). This model preserves that register evidence so the analyzer can
/// apply a bounded ranking nudge. Voicing influences ranking; it is never
/// ground truth.
///
/// Only real octaves carry usable evidence, so this is built from sounding MIDI
/// numbers; pitch-class-only input (typed note names, the lookup pad) supplies
/// no voicing.
@immutable
class ObservedVoicing {
  /// Sounding MIDI note numbers, sorted ascending. Register doublings (C3 + C4)
  /// are distinct entries and meaningful.
  final List<int> midiNotes;

  const ObservedVoicing._(this.midiNotes);

  /// An inert voicing that carries no evidence to act on.
  static const ObservedVoicing inert = ObservedVoicing._(<int>[]);

  /// Builds a voicing from sounding MIDI note numbers (sorted ascending).
  /// Returns [inert] when fewer than two notes are present.
  factory ObservedVoicing.fromMidi(Iterable<int> notes) {
    final sorted = notes.toList()..sort();
    if (sorted.length < 2) return inert;
    return ObservedVoicing._(List.unmodifiable(sorted));
  }

  /// Whether this voicing carries no evidence to act on.
  bool get isInert => midiNotes.length < 2;

  /// Lowest sounding note.
  int get bassMidi => midiNotes.first;

  /// Highest sounding note.
  int get topMidi => midiNotes.last;

  /// Total span in semitones from bass to top.
  int get span => topMidi - bassMidi;

  /// Semitones from the bass to the next-lowest distinct note. A large gap is
  /// the signature of a bass isolated below an upper structure.
  int get bassGap => midiNotes.length >= 2 ? midiNotes[1] - midiNotes[0] : 0;

  /// Lowest note sounding the given pitch class, or null if absent.
  int? lowestMidiOf(int pc) {
    for (final m in midiNotes) {
      if (m % 12 == pc) return m;
    }
    return null;
  }

  /// Stable signature for cache keying. Two voicings with the same pitch
  /// classes but different registers must not alias.
  int get signature => Object.hashAll(midiNotes);

  @override
  String toString() => 'ObservedVoicing($midiNotes)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObservedVoicing && _listEquals(other.midiNotes, midiNotes);

  @override
  int get hashCode => signature;

  static bool _listEquals(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
