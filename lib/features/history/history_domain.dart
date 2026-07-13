// Pure-Dart seam for the history feature, mirroring the whatchord package barrel: model
// and domain types only, no Riverpod or Flutter imports, so CLI tooling and
// the WhatKey harness can compile against them without pulling in the app.
export 'domain/chord_event_segmenter.dart';
export 'models/chord_event.dart';
