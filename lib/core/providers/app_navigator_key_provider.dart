import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stable key for the root navigator, letting non-widget code (e.g. deep-link
/// handling) drive navigation without a [BuildContext].
final appNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(),
);
