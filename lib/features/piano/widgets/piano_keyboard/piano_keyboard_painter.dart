import 'package:flutter/material.dart';

class PianoKeyboardPainter extends CustomPainter {
  PianoKeyboardPainter({
    required this.whiteKeyCount,
    required this.firstMidiNote,
    required this.soundingMidiNotes,
    required this.whiteKeyColor,
    required this.whiteKeyActiveColor,
    required this.whiteKeyBorderColor,
    required this.blackKeyColor,
    required this.blackKeyActiveColor,
    required this.backgroundColor,
    required this.showNoteDebugLabels,
    required this.debugLabelColor,
    this.drawBackground = true,
    this.drawFeltStrip = true,
    this.feltColor = const Color(0xFF800020),
    this.feltHeight = 2.0,
  });

  final int whiteKeyCount;
  final int firstMidiNote;

  /// Sounding *MIDI note numbers* (e.g., 60 for middle C).
  final Set<int> soundingMidiNotes;

  final Color whiteKeyColor;
  final Color whiteKeyActiveColor;
  final Color whiteKeyBorderColor;
  final Color blackKeyColor;
  final Color blackKeyActiveColor;
  final Color backgroundColor;

  final bool showNoteDebugLabels;
  final Color debugLabelColor;

  final bool drawBackground;

  final bool drawFeltStrip;
  final Color feltColor;
  final double feltHeight;

  static const double _blackKeyWidthRatio = 0.62;
  static const double _blackKeyHeightRatio = 0.62;

  // Bias magnitudes as fractions of white key width.
  static const double _smallBlackKeyBiasRatio = 0.10; // C#, D#
  static const double _largeBlackKeyBiasRatio = 0.15; // F#, A#

  // MIDI pitch classes (C=0).
  static const int _pcC = 0;
  static const int _pcD = 2;
  static const int _pcE = 4;
  static const int _pcF = 5;
  static const int _pcG = 7;
  static const int _pcA = 9;
  static const int _pcB = 11;

  static const List<int> _whitePitchClassesInOctave = <int>[
    _pcC,
    _pcD,
    _pcE,
    _pcF,
    _pcG,
    _pcA,
    _pcB,
  ];

  static bool _hasBlackAfterWhitePc(int whitePc) {
    return whitePc == _pcC ||
        whitePc == _pcD ||
        whitePc == _pcF ||
        whitePc == _pcG ||
        whitePc == _pcA;
  }

  int _whitePcForIndex(int whiteIndex) {
    final startPc = firstMidiNote % 12;
    final startPos = _whitePitchClassesInOctave.indexOf(startPc);
    final normalizedStartPos = startPos < 0 ? 0 : startPos;
    return _whitePitchClassesInOctave[(normalizedStartPos + whiteIndex) % 7];
  }

  int _whiteMidiForIndex(int whiteIndex) {
    int midi = firstMidiNote;
    for (int i = 0; i < whiteIndex; i++) {
      final pc = _whitePcForIndex(i);
      final step = (pc == _pcE || pc == _pcB) ? 1 : 2;
      midi += step;
    }
    return midi;
  }

  bool _isSounding(int midi) => soundingMidiNotes.contains(midi);

  double _blackCenterBiasForPc(int blackPc, double whiteKeyW) {
    switch (blackPc) {
      case 1: // C#
        return -whiteKeyW * _smallBlackKeyBiasRatio;
      case 3: // D#
        return whiteKeyW * _smallBlackKeyBiasRatio;
      case 6: // F#
        return -whiteKeyW * _largeBlackKeyBiasRatio;
      case 10: // A#
        return whiteKeyW * _largeBlackKeyBiasRatio;
      case 8: // G#
      default:
        return 0.0;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (whiteKeyCount <= 0 || w <= 0 || h <= 0) return;

    if (drawBackground) {
      final bgPaint = Paint()..color = backgroundColor;
      canvas.drawRect(Offset.zero & size, bgPaint);
    }

    final whiteKeyW = w / whiteKeyCount;
    final whiteKeyH = h;
    final blackKeyW = whiteKeyW * _blackKeyWidthRatio;
    final blackKeyH = whiteKeyH * _blackKeyHeightRatio;

    final whiteFillPaint = Paint()..style = PaintingStyle.fill;
    final whiteBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = whiteKeyBorderColor;

    // White keys
    for (int i = 0; i < whiteKeyCount; i++) {
      final x = i * whiteKeyW;
      final rect = Rect.fromLTWH(x, 0, whiteKeyW, whiteKeyH);

      final midi = _whiteMidiForIndex(i);

      whiteFillPaint.color = _isSounding(midi)
          ? whiteKeyActiveColor
          : whiteKeyColor;

      canvas.drawRect(rect, whiteFillPaint);
      canvas.drawRect(rect, whiteBorderPaint);
    }

    // Black keys
    final blackFillPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < whiteKeyCount - 1; i++) {
      final whitePc = _whitePcForIndex(i);
      if (!_hasBlackAfterWhitePc(whitePc)) continue;

      final whiteMidi = _whiteMidiForIndex(i);
      final blackMidi = whiteMidi + 1;
      final blackPc = blackMidi % 12;

      final boundaryX = (i + 1) * whiteKeyW;
      final centerX = boundaryX + _blackCenterBiasForPc(blackPc, whiteKeyW);

      double blackLeft = centerX - (blackKeyW / 2.0);
      blackLeft = blackLeft.clamp(0.0, w - blackKeyW);

      final rect = Rect.fromLTWH(blackLeft, 0, blackKeyW, blackKeyH);

      blackFillPaint.color = _isSounding(blackMidi)
          ? blackKeyActiveColor
          : blackKeyColor;
      canvas.drawRect(rect, blackFillPaint);
    }

    // Felt strip LAST so it stays visible.
    if (drawFeltStrip && feltHeight > 0) {
      final feltPaint = Paint()..color = feltColor;
      canvas.drawRect(Rect.fromLTWH(0, 0, w, feltHeight), feltPaint);
    }

    if (showNoteDebugLabels) {
      _paintDebugLabels(canvas, size, whiteKeyW);
    }
  }

  void _paintDebugLabels(Canvas canvas, Size size, double whiteKeyW) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < whiteKeyCount; i++) {
      final midi = _whiteMidiForIndex(i);
      textPainter.text = TextSpan(
        text: midi.toString(),
        style: TextStyle(color: debugLabelColor, fontSize: 10),
      );
      textPainter.layout(minWidth: whiteKeyW, maxWidth: whiteKeyW);
      textPainter.paint(
        canvas,
        Offset(i * whiteKeyW, size.height - textPainter.height - 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant PianoKeyboardPainter oldDelegate) {
    return oldDelegate.whiteKeyCount != whiteKeyCount ||
        oldDelegate.firstMidiNote != firstMidiNote ||
        oldDelegate.drawBackground != drawBackground ||
        oldDelegate.drawFeltStrip != drawFeltStrip ||
        oldDelegate.feltColor != feltColor ||
        oldDelegate.feltHeight != feltHeight ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.whiteKeyColor != whiteKeyColor ||
        oldDelegate.whiteKeyActiveColor != whiteKeyActiveColor ||
        oldDelegate.whiteKeyBorderColor != whiteKeyBorderColor ||
        oldDelegate.blackKeyColor != blackKeyColor ||
        oldDelegate.blackKeyActiveColor != blackKeyActiveColor ||
        oldDelegate.showNoteDebugLabels != showNoteDebugLabels ||
        oldDelegate.debugLabelColor != debugLabelColor ||
        !_setEquals(oldDelegate.soundingMidiNotes, soundingMidiNotes);
  }

  bool _setEquals(Set<int> a, Set<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }
}
