import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/theory_domain.dart';

final selectedTonalityProvider =
    NotifierProvider<SelectedTonalityNotifier, Tonality>(
      SelectedTonalityNotifier.new,
    );

class SelectedTonalityNotifier extends Notifier<Tonality> {
  @override
  Tonality build() => const Tonality('C', TonalityMode.major);

  void setTonality(Tonality tonality) => state = tonality;
}
