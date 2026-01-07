import 'package:meta/meta.dart';

import 'chord_symbol.dart';

@immutable
class AnalysisIdentity {
  final ChordSymbol symbol;
  final String? secondaryLabel;

  const AnalysisIdentity({required this.symbol, required this.secondaryLabel});

  bool get hasSecondaryLabel =>
      secondaryLabel != null && secondaryLabel!.trim().isNotEmpty;
}
