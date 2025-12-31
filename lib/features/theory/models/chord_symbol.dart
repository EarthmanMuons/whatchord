import 'package:flutter/foundation.dart';

enum ChordSymbolStyle { standard, jazz }

@immutable
class ChordSymbol {
  final String root; // e.g., "C", "F#", "Bb"
  final String quality; // e.g., "maj", "m7(b5)", "sus4", "" (optional)
  final String? bass; // e.g., "E" in "Cmaj / E" (no leading " / ")

  const ChordSymbol({required this.root, this.quality = '', this.bass});

  bool get hasBass => bass?.trim().isNotEmpty ?? false;

  String format() {
    final base = '$root$quality';
    return hasBass ? '$base / ${bass!}' : base;
  }
}
