import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chord_symbol.dart';

class ChordSymbolNotifier extends Notifier<ChordSymbolStyle> {
  @override
  ChordSymbolStyle build() => ChordSymbolStyle.standard;
  void setStyle(ChordSymbolStyle style) => state = style;
}

final chordSymbolProvider =
    NotifierProvider<ChordSymbolNotifier, ChordSymbolStyle>(
      ChordSymbolNotifier.new,
    );
