import 'package:flutter/widgets.dart';

List<InlineSpan> scaleDegreeRomanSpans(String roman) {
  return [for (final char in roman.characters) TextSpan(text: char)];
}
