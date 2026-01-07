import 'package:meta/meta.dart';

import 'chord_symbol.dart';

@immutable
class ChordAnalysis {
  final ChordSymbol symbol;
  final String? secondaryLabel;

  const ChordAnalysis({required this.symbol, required this.secondaryLabel});

  bool get hasSecondaryLabel =>
      secondaryLabel != null && secondaryLabel!.trim().isNotEmpty;
}
