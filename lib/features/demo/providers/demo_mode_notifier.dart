import 'package:flutter_riverpod/flutter_riverpod.dart';

final demoModeProvider = NotifierProvider<DemoModeNotifier, bool>(
  DemoModeNotifier.new,
);

class DemoModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Default to off.
    return false;
  }

  void setEnabled(bool v) => state = v;
  void toggle() => state = !state;
}
