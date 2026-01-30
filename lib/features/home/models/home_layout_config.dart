import 'package:flutter/material.dart';

@immutable
class HomeLayoutConfig {
  // Analysis
  final EdgeInsets analysisPadding;
  final double chordCardMaxWidth;
  final EdgeInsets detailsSectionPadding; // right panel (landscape)
  final EdgeInsets activeInputPadding;

  // Tonality
  final double tonalityBarHeight;

  // Keyboard
  final int whiteKeyCount;
  final double whiteKeyAspectRatio;
  final int firstMidiNote;

  const HomeLayoutConfig({
    required this.analysisPadding,
    required this.chordCardMaxWidth,
    required this.detailsSectionPadding,
    required this.activeInputPadding,
    required this.tonalityBarHeight,
    required this.whiteKeyCount,
    this.whiteKeyAspectRatio = 7.0,
    required this.firstMidiNote,
  });
}

const portraitLayoutConfig = HomeLayoutConfig(
  analysisPadding: EdgeInsets.fromLTRB(16, 16, 16, 16),
  chordCardMaxWidth: 520,
  detailsSectionPadding: EdgeInsets.zero,
  activeInputPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  tonalityBarHeight: 56,
  whiteKeyCount: 21,
  whiteKeyAspectRatio: 7.0,
  firstMidiNote: 48, // C3
);

const landscapeLayoutConfig = HomeLayoutConfig(
  analysisPadding: EdgeInsets.fromLTRB(16, 16, 8, 16),
  chordCardMaxWidth: 520,
  detailsSectionPadding: EdgeInsets.fromLTRB(8, 12, 16, 12),
  activeInputPadding: EdgeInsets.zero,
  tonalityBarHeight: 44,
  // Full 88-key view: 52 white keys from A0 (MIDI 21) to C8.
  whiteKeyCount: 52,
  whiteKeyAspectRatio: 7.0,
  firstMidiNote: 21, // A0
);
