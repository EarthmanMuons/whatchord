import 'package:flutter/material.dart';

class PianoKeyboardPainter extends CustomPainter {
  PianoKeyboardPainter({
    required this.whiteKeyCount,
    required this.startMidiNote,
    required this.activePitchClasses,
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
    this.feltColor = const Color(0xFF4A0E0E), // dark red "felt"
    this.feltHeight = 2.0,
  });

  final int whiteKeyCount;
  final int startMidiNote;
  final Set<int> activePitchClasses;

  final Color whiteKeyColor;
  final Color whiteKeyActiveColor;
  final Color whiteKeyBorderColor;
  final Color blackKeyColor;
  final Color blackKeyActiveColor;
  final Color backgroundColor;

  final bool showNoteDebugLabels;
  final Color debugLabelColor;

  /// If true, paints a rectangular background behind keys.
  final bool drawBackground;

  /// If true, paints a thin "felt" strip at the top edge.
  final bool drawFeltStrip;

  /// Color of the felt strip (dark red by default).
  final Color feltColor;

  /// Height in logical pixels of the felt strip.
  final double feltHeight;

  // Geometry ratios (tune after you see it rendered).
  static const double _blackKeyWidthRatio = 0.62; // relative to white width
  static const double _blackKeyHeightRatio = 0.62; // relative to total height

  // Bias magnitudes as fractions of white key width.
  // Upper group (C#/D#) should be subtler than lower group.
  static const double _smallBlackKeyBiasRatio = 0.10; // C#, D#
  static const double _largeBlackKeyBiasRatio = 0.16; // F#, A#

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

  // Black key exists after these white pitch classes: C, D, F, G, A
  // No black key after E (E->F) and B (B->C).
  static bool _hasBlackAfterWhitePc(int whitePc) {
    return whitePc == _pcC ||
        whitePc == _pcD ||
        whitePc == _pcF ||
        whitePc == _pcG ||
        whitePc == _pcA;
  }

  int _whitePcForIndex(int whiteIndex) {
    final startPc = startMidiNote % 12;
    final startPos = _whitePitchClassesInOctave.indexOf(startPc);
    final normalizedStartPos = startPos < 0 ? 0 : startPos;
    return _whitePitchClassesInOctave[(normalizedStartPos + whiteIndex) % 7];
  }

  int _whiteMidiForIndex(int whiteIndex) {
    int midi = startMidiNote;
    for (int i = 0; i < whiteIndex; i++) {
      final pc = _whitePcForIndex(i);
      // Diatonic white-step semitone distances.
      final step = (pc == _pcE || pc == _pcB) ? 1 : 2;
      midi += step;
    }
    return midi;
  }

  bool _isActivePc(int pc) => activePitchClasses.contains(pc);

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

    // Background (optional; useful to define bounds during layout tests).
    if (drawBackground) {
      final bgPaint = Paint()..color = backgroundColor;
      canvas.drawRect(Offset.zero & size, bgPaint);
    }

    // Felt strip at the very top edge (optional).
    if (drawFeltStrip && feltHeight > 0) {
      final feltPaint = Paint()..color = feltColor;
      canvas.drawRect(Rect.fromLTWH(0, 0, w, feltHeight), feltPaint);
    }

    final whiteKeyW = w / whiteKeyCount;
    final whiteKeyH = h;
    final blackKeyW = whiteKeyW * _blackKeyWidthRatio;
    final blackKeyH = whiteKeyH * _blackKeyHeightRatio;

    // White keys: fill + border.
    final whiteFillPaint = Paint()..style = PaintingStyle.fill;
    final whiteBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = whiteKeyBorderColor;

    for (int i = 0; i < whiteKeyCount; i++) {
      final x = i * whiteKeyW;
      final rect = Rect.fromLTWH(x, 0, whiteKeyW, whiteKeyH);

      final pc = _whitePcForIndex(i);
      whiteFillPaint.color = _isActivePc(pc)
          ? whiteKeyActiveColor
          : whiteKeyColor;

      canvas.drawRect(rect, whiteFillPaint);
      canvas.drawRect(rect, whiteBorderPaint);
    }

    // Black keys: draw on top.
    // Important: no rounding; keep straight edges (especially at top).
    final blackFillPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < whiteKeyCount - 1; i++) {
      final whitePc = _whitePcForIndex(i);
      if (!_hasBlackAfterWhitePc(whitePc)) continue;

      final boundaryX = (i + 1) * whiteKeyW; // boundary between white i and i+1
      final blackPc = (whitePc + 1) % 12;

      final centerX = boundaryX + _blackCenterBiasForPc(blackPc, whiteKeyW);
      double blackLeft = centerX - (blackKeyW / 2.0);

      // Clamp so we never paint outside the component.
      blackLeft = blackLeft.clamp(0.0, w - blackKeyW);

      final rect = Rect.fromLTWH(blackLeft, 0, blackKeyW, blackKeyH);

      blackFillPaint.color = _isActivePc(blackPc)
          ? blackKeyActiveColor
          : blackKeyColor;

      canvas.drawRect(rect, blackFillPaint);
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
      final pc = midi % 12;
      final label = _pcName(pc);

      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(color: debugLabelColor, fontSize: 10),
      );
      textPainter.layout(minWidth: whiteKeyW, maxWidth: whiteKeyW);

      final x = i * whiteKeyW;
      final y = size.height - textPainter.height - 4;

      textPainter.paint(canvas, Offset(x, y));
    }
  }

  String _pcName(int pc) {
    switch (pc) {
      case 0:
        return 'C';
      case 1:
        return 'C#';
      case 2:
        return 'D';
      case 3:
        return 'D#';
      case 4:
        return 'E';
      case 5:
        return 'F';
      case 6:
        return 'F#';
      case 7:
        return 'G';
      case 8:
        return 'G#';
      case 9:
        return 'A';
      case 10:
        return 'A#';
      case 11:
        return 'B';
      default:
        return '?';
    }
  }

  @override
  bool shouldRepaint(covariant PianoKeyboardPainter oldDelegate) {
    return oldDelegate.whiteKeyCount != whiteKeyCount ||
        oldDelegate.startMidiNote != startMidiNote ||
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
        !_setEquals(oldDelegate.activePitchClasses, activePitchClasses);
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
