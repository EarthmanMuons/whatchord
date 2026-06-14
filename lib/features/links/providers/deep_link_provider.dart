import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/lookup/lookup.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../models/chord_link.dart';
import '../services/deep_link_service.dart';

final deepLinkServiceProvider = Provider<DeepLinkService>(
  (ref) => DeepLinkService(),
);

/// App-lifecycle hook: applies incoming `/try` deep links by seeding the lookup
/// pad and tonality. Watched once near the app root; handles both the
/// cold-start link and warm links delivered while running.
final appDeepLinkProvider = Provider<void>((ref) {
  final service = ref.watch(deepLinkServiceProvider);

  void handle(Uri uri) {
    final seed = ChordLink.parse(uri);
    if (seed == null) return;

    if (seed.tonality != null) {
      unawaited(
        ref.read(selectedTonalityProvider.notifier).setTonality(seed.tonality!),
      );
    }

    // Open the pad and replace any prior selection with the linked notes.
    final lookup = ref.read(lookupModeProvider.notifier);
    lookup.enter();
    lookup.clear();
    for (final pc in seed.pitchClasses) {
      lookup.addNote(pc);
    }
  }

  unawaited(
    service.getInitialLink().then((uri) {
      if (uri != null) handle(uri);
    }),
  );

  final sub = service.uriLinkStream.listen(handle);
  ref.onDispose(sub.cancel);
});
