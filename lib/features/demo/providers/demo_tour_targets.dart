import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A home-screen element a guided-tour step can point at with a callout arrow.
enum DemoTarget { chordCard, alternatives, tonalityBar, lookupButton, midiIcon }

/// Stable [GlobalKey]s the tour overlay uses to locate the prompt anchor and the
/// element each step points at. Exactly one widget is mounted per key at a time
/// (portrait and landscape layouts build the same element in different places),
/// so a single shared key per role is safe.
class DemoTourKeys {
  DemoTourKeys()
    : prompt = GlobalKey(debugLabel: 'demoTour.prompt'),
      chordCard = GlobalKey(debugLabel: 'demoTour.chordCard'),
      alternatives = GlobalKey(debugLabel: 'demoTour.alternatives'),
      tonalityBar = GlobalKey(debugLabel: 'demoTour.tonalityBar'),
      lookupButton = GlobalKey(debugLabel: 'demoTour.lookupButton'),
      midiIcon = GlobalKey(debugLabel: 'demoTour.midiIcon');

  final GlobalKey prompt;
  final GlobalKey chordCard;
  final GlobalKey alternatives;
  final GlobalKey tonalityBar;
  final GlobalKey lookupButton;
  final GlobalKey midiIcon;

  GlobalKey forTarget(DemoTarget target) => switch (target) {
    DemoTarget.chordCard => chordCard,
    DemoTarget.alternatives => alternatives,
    DemoTarget.tonalityBar => tonalityBar,
    DemoTarget.lookupButton => lookupButton,
    DemoTarget.midiIcon => midiIcon,
  };
}

final demoTourKeysProvider = Provider<DemoTourKeys>((ref) => DemoTourKeys());
