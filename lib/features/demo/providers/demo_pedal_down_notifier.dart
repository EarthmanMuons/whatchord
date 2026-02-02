import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo_sequence_notifier.dart';

final demoPedalDownProvider = NotifierProvider<DemoPedalDownNotifier, bool>(
  DemoPedalDownNotifier.new,
);

class DemoPedalDownNotifier extends Notifier<bool> {
  @override
  bool build() {
    ref.listen<DemoSequenceState>(demoSequenceProvider, (_, next) {
      state = _pedalForStep(next.index);
    });
    return _pedalForStep(ref.read(demoSequenceProvider).index);
  }

  void toggle() => state = !state;

  void setDown(bool down) => state = down;

  bool _pedalForStep(int index) {
    final steps = DemoSequenceNotifier.steps;
    if (index < 0 || index >= steps.length) return false;
    final step = steps[index];
    return step.pedalDown ?? false;
  }
}
