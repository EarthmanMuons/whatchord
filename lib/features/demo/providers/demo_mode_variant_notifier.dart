import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DemoModeVariant { interactive, screenshot }

final demoModeVariantProvider =
    NotifierProvider<DemoModeVariantNotifier, DemoModeVariant>(
      DemoModeVariantNotifier.new,
    );

class DemoModeVariantNotifier extends Notifier<DemoModeVariant> {
  @override
  DemoModeVariant build() => DemoModeVariant.interactive;

  void setVariant(DemoModeVariant variant) {
    if (variant == state) return;
    state = variant;
  }
}
