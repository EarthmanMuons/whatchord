import 'package:flutter/foundation.dart';

import 'chord_symbol.dart';

@immutable
class ChordAnalysis {
  final ChordSymbol symbol;
  final String? inversion;

  const ChordAnalysis({required this.symbol, required this.inversion});

  bool get hasInversion => inversion != null && inversion!.trim().isNotEmpty;
}
