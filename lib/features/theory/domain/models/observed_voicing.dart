import 'package:meta/meta.dart';

/// How literally the octaves in an [ObservedVoicing] should be read.
enum VoicingRegisters {
  /// A real performance (live MIDI, typed MIDI numbers): octaves and spacing
  /// carry intent, so register-magnitude evidence is meaningful.
  exact,

  /// Octaves were synthesized for the player (typed note names, the lookup
  /// pad). The note order is still meaningful — the first note is the bass and
  /// the rest stack upward — but the spacing is not, so magnitude-based
  /// evidence must be skipped.
  synthesized,
}

/// Optional voicing evidence for chord analysis.
///
/// `ChordInput` carries only the pitch-class core (mask + bass + count). The
/// interfaces that feed analysis also know the note order, and live MIDI knows
/// the octaves too. Musicians use both to choose between equally-valid names
/// (an Am7 stacked above an isolated D bass reads as Am7/D, not D9sus4). This
/// model preserves that evidence so the analyzer can apply a bounded ranking
/// nudge. Voicing influences ranking; it is never ground truth.
@immutable
class ObservedVoicing {
  /// Notes from bass upward. For [VoicingRegisters.exact] these are the sounding
  /// MIDI numbers sorted ascending; for [VoicingRegisters.synthesized] they are
  /// ascending positions that preserve the input order, with real pitch classes
  /// but placeholder octaves.
  final List<int> midiNotes;

  /// Whether [midiNotes] are real octaves or synthesized placeholders.
  final VoicingRegisters registers;

  const ObservedVoicing._(this.midiNotes, this.registers);

  /// An inert voicing that carries no evidence to act on.
  static const ObservedVoicing inert = ObservedVoicing._(
    <int>[],
    VoicingRegisters.exact,
  );

  /// Builds an exact voicing from sounding MIDI note numbers (sorted ascending).
  /// Returns [inert] when fewer than two notes are present.
  factory ObservedVoicing.fromMidi(Iterable<int> notes) {
    final sorted = notes.toList()..sort();
    if (sorted.length < 2) return inert;
    return ObservedVoicing._(List.unmodifiable(sorted), VoicingRegisters.exact);
  }

  /// Builds a synthesized voicing from pitch classes in bass-first order. The
  /// order is preserved and the octaves are placeholders, so order-based
  /// evidence applies but magnitude-based evidence does not. Returns [inert]
  /// when fewer than two notes are present.
  factory ObservedVoicing.fromOrder(Iterable<int> pitchClasses) {
    final pcs = pitchClasses.toList(growable: false);
    if (pcs.length < 2) return inert;

    final notes = <int>[];
    var floor = 48; // arbitrary low octave; magnitude is ignored here
    for (final raw in pcs) {
      final pc = ((raw % 12) + 12) % 12;
      var midi = floor - (floor % 12) + pc;
      if (midi < floor) midi += 12;
      notes.add(midi);
      floor = midi + 1;
    }
    return ObservedVoicing._(
      List.unmodifiable(notes),
      VoicingRegisters.synthesized,
    );
  }

  /// Whether this voicing carries no evidence to act on.
  bool get isInert => midiNotes.length < 2;

  /// Whether the octaves are real and register-magnitude evidence may be read.
  bool get hasExactRegisters => registers == VoicingRegisters.exact;

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
  /// classes but different registers or provenance must not alias.
  int get signature => Object.hash(Object.hashAll(midiNotes), registers);

  @override
  String toString() => 'ObservedVoicing($midiNotes, ${registers.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObservedVoicing &&
          other.registers == registers &&
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
