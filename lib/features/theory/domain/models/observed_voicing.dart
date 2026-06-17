import 'package:meta/meta.dart';

/// Optional register/spread evidence for chord analysis.
///
/// `ChordInput` carries only the pitch-class core (mask + bass + count). Real
/// MIDI input also has octaves and spacing, which musicians use to choose
/// between equally-valid names (e.g. an Am7 stacked above an isolated D bass
/// reads as Am7/D, not D9sus4). This model preserves that register evidence so
/// the analyzer can apply a bounded ranking nudge.
///
/// It is always optional: when absent or [isInert] the analyzer behaves exactly
/// as it does for pitch-class-only input. Voicing influences ranking; it is
/// never ground truth.
@immutable
class ObservedVoicing {
  /// Sounding MIDI note numbers, sorted ascending. Register doublings (C3 + C4)
  /// are distinct entries and meaningful.
  final List<int> midiNotes;

  /// Whether the octaves/spacing reflect a real performance.
  ///
  /// True for live MIDI and demo playback, where the player placed each note in
  /// a register. False when octaves were synthesized for the player (the lookup
  /// pad spreads chosen pitch classes algorithmically), so register-magnitude
  /// evidence must not be read as harmonic intent.
  final bool intentionalRegisters;

  const ObservedVoicing._(this.midiNotes, {this.intentionalRegisters = true});

  /// An inert voicing that carries no usable register evidence.
  static const ObservedVoicing inert = ObservedVoicing._(<int>[]);

  /// Builds a voicing from sounding MIDI note numbers. Returns [inert] when
  /// fewer than two notes are present (no spacing to reason about), so callers
  /// that only have pitch classes (typed note names) get zero evidence.
  factory ObservedVoicing.fromMidi(
    Iterable<int> notes, {
    bool intentionalRegisters = true,
  }) {
    final sorted = notes.toList()..sort();
    if (sorted.length < 2) return inert;
    return ObservedVoicing._(
      List.unmodifiable(sorted),
      intentionalRegisters: intentionalRegisters,
    );
  }

  /// Whether this voicing carries no register evidence to act on.
  bool get isInert => midiNotes.length < 2;

  /// Lowest sounding MIDI note.
  int get bassMidi => midiNotes.first;

  /// Highest sounding MIDI note.
  int get topMidi => midiNotes.last;

  /// Total span in semitones from bass to top.
  int get span => topMidi - bassMidi;

  /// Semitones from the bass to the next-lowest distinct note. A large gap is
  /// the signature of a bass isolated below an upper structure.
  int get bassGap => midiNotes.length >= 2 ? midiNotes[1] - midiNotes[0] : 0;

  /// Lowest MIDI note sounding the given pitch class, or null if absent.
  int? lowestMidiOf(int pc) {
    for (final m in midiNotes) {
      if (m % 12 == pc) return m;
    }
    return null;
  }

  /// Stable signature for cache keying. Two voicings with the same pitch
  /// classes but different registers must not alias to the same cache entry.
  int get signature =>
      Object.hash(Object.hashAll(midiNotes), intentionalRegisters);

  @override
  String toString() =>
      'ObservedVoicing($midiNotes, intentional=$intentionalRegisters)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObservedVoicing &&
          other.intentionalRegisters == intentionalRegisters &&
          _listEquals(other.midiNotes, midiNotes);

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
