import 'dart:io';

import 'package:what_chord/features/theory/engine/engine.dart';
import 'package:what_chord/features/theory/models/chord_symbol.dart';
import 'package:what_chord/features/theory/services/chord_symbol_formatter.dart';

/// Usage:
///   dart run tool/chord_debug.dart C E G D
///   dart run tool/chord_debug.dart C E G Bb D --bass=C
///   dart run tool/chord_debug.dart 60 64 67 74
///   dart run tool/chord_debug.dart 60 64 67 70 74 --top=12
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Provide notes (pitch names or MIDI numbers).');
    exitCode = 2;
    return;
  }

  final top = _readIntFlag(args, 'top') ?? 5;
  final bassName = _readStringFlag(args, 'bass');

  // Extract positional args (notes), ignoring flags.
  final noteTokens = args.where((a) => !a.startsWith('--')).toList();
  if (noteTokens.isEmpty) {
    stderr.writeln('No notes provided.');
    exitCode = 2;
    return;
  }

  final parsed = _parseNotes(noteTokens);
  final midi = parsed.midiNotes;
  final pcs = parsed.pitchClasses;

  if (pcs.isEmpty) {
    stderr.writeln('Could not parse any notes.');
    exitCode = 2;
    return;
  }

  final pcMask = _toPcMask(pcs);
  final bassPc = bassName != null
      ? _parsePitchClass(bassName)
      : (midi.isNotEmpty
            ? (midi.reduce((a, b) => a < b ? a : b) % 12)
            : pcs.first);

  final input = ChordInput(
    pcMask: pcMask,
    bassPc: bassPc,
    noteCount: midi.isNotEmpty ? midi.length : pcs.length,
  );

  stdout.writeln('Input: $input');
  stdout.writeln('pcs: ${pcs.map(_pcName).toSet().toList()..sort()}');
  stdout.writeln('bass: ${_pcName(bassPc)}');
  stdout.writeln('');
  stdout.writeln('Note: ordering uses near-tie heuristics within ±0.20');
  stdout.writeln('');

  final results = ChordAnalyzer.analyzeDebug(input, take: top);

  if (results.isEmpty) {
    stdout.writeln('No candidates.');
    return;
  }

  final style = ChordSymbolStyle.standard;

  for (var i = 0; i < results.length; i++) {
    final r = results[i];
    final id = r.identity;

    final root = _pcName(id.rootPc);
    final bass = id.hasSlashBass ? _pcName(id.bassPc) : null;

    final quality = ChordSymbolFormatter.formatQuality(
      quality: id.quality,
      extensions: id.extensions,
      style: style,
    );

    final symbol = ChordSymbol(root: root, quality: quality, bass: bass);

    stdout.writeln('${i + 1}. $symbol');
    stdout.writeln('   ${r.toString()}');
  }
}

int _toPcMask(Iterable<int> pcs) {
  var mask = 0;
  for (final pc in pcs) {
    mask |= (1 << (pc % 12));
  }
  return mask;
}

String _pcName(int pc) {
  switch (pc % 12) {
    case 0:
      return 'C';
    case 1:
      return 'C#';
    case 2:
      return 'D';
    case 3:
      return 'Eb';
    case 4:
      return 'E';
    case 5:
      return 'F';
    case 6:
      return 'F#';
    case 7:
      return 'G';
    case 8:
      return 'Ab';
    case 9:
      return 'A';
    case 10:
      return 'Bb';
    case 11:
      return 'B';
    default:
      return '?';
  }
}

int _parsePitchClass(String s) {
  final n = s.trim();
  final u = n.toUpperCase();

  // Normalize common flats/sharps
  // Accept: C, C#, Db, EB, F#, GB, etc.
  switch (u) {
    case 'C':
      return 0;
    case 'B#':
      return 0;

    case 'C#':
    case 'DB':
      return 1;

    case 'D':
      return 2;

    case 'D#':
    case 'EB':
      return 3;

    case 'E':
      return 4;
    case 'FB':
      return 4;

    case 'F':
      return 5;
    case 'E#':
      return 5;

    case 'F#':
    case 'GB':
      return 6;

    case 'G':
      return 7;

    case 'G#':
    case 'AB':
      return 8;

    case 'A':
      return 9;

    case 'A#':
    case 'BB':
      return 10;

    case 'B':
      return 11;
    case 'CB':
      return 11;

    default:
      throw FormatException('Unrecognized pitch name: $s');
  }
}

({List<int> midiNotes, List<int> pitchClasses}) _parseNotes(
  List<String> tokens,
) {
  final midi = <int>[];
  final pcs = <int>[];

  for (final t in tokens) {
    final tt = t.trim();
    if (tt.isEmpty) continue;

    final asInt = int.tryParse(tt);
    if (asInt != null) {
      midi.add(asInt);
      pcs.add(asInt % 12);
      continue;
    }

    pcs.add(_parsePitchClass(tt));
  }

  return (midiNotes: midi, pitchClasses: pcs);
}

int? _readIntFlag(List<String> args, String name) {
  final prefix = '--$name=';
  for (final a in args) {
    if (a.startsWith(prefix)) {
      return int.tryParse(a.substring(prefix.length));
    }
  }
  return null;
}

String? _readStringFlag(List<String> args, String name) {
  final prefix = '--$name=';
  for (final a in args) {
    if (a.startsWith(prefix)) {
      return a.substring(prefix.length);
    }
  }
  return null;
}
