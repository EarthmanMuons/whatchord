import 'package:flutter/widgets.dart';

/// Builds the spans for a scale-degree roman numeral so the diminished (°) and
/// half-diminished (ø) symbols render in Inter rather than the music symbol
/// font, matching the scale-degree strip's conventions.
List<InlineSpan> scaleDegreeRomanSpans(String roman) {
  return [
    for (final char in roman.characters)
      TextSpan(
        text: char,
        style: _usesTextFont(char) ? _romanTextFontStyle : null,
      ),
  ];
}

const _romanTextFontStyle = TextStyle(
  fontFamily: 'Inter',
  fontFamilyFallback: [],
);

bool _usesTextFont(String char) => char == '°' || char == 'ø';
