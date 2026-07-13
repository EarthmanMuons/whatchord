import 'package:whatchord_theory/whatchord_theory.dart';

/// MIDI voicings for the Scale Explorer's keyboard highlighting and playback.
///
/// The tonic is anchored near middle C: C through G# use the C4 octave (so a C
/// major scale starts on middle C), while A and above drop to the C3 octave to
/// keep the run from climbing too high.
int _tonicMidi(Scale scale) {
  final pc = scale.tonicPitchClass;
  return (pc >= 9 ? 48 : 60) + pc;
}

/// The scale ascending to the octave above the tonic and back down.
List<int> scaleRunMidi(Scale scale) {
  final tonicMidi = _tonicMidi(scale);
  final ascending = [
    for (final interval in scale.intervals) tonicMidi + interval,
    tonicMidi + 12,
  ];
  return [...ascending, ...ascending.reversed.skip(1)];
}

List<int> degreeChordMidi(
  Scale scale,
  ScaleDegreeHarmony degree, {
  required bool seventh,
}) {
  final quality = seventh ? degree.seventhQuality : degree.triadQuality;
  final rootMidi = _tonicMidi(scale) + scale.intervals[degree.ordinal - 1];
  final intervals = quality.canonicalIntervals.toList()..sort();
  return [for (final interval in intervals) rootMidi + interval];
}
