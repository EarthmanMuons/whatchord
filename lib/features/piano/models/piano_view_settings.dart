import 'package:meta/meta.dart';

/// User-chosen piano keyboard sizing, shared across every page that renders the
/// keyboard. Both factors default to 1.0 (the built-in layout) and are only ever
/// >= 1.0: the default proportions are the minimum size.
///
/// - [widthScale] widens the keys. It is applied by reducing the visible white
///   key count, so larger values show fewer, wider keys (the rest scroll).
/// - [heightScale] grows the vertical space the keyboard occupies, applied as a
///   multiplier on the layout-derived base height (clamped to available space).
@immutable
class PianoViewSettings {
  const PianoViewSettings({
    required this.widthScale,
    required this.heightScale,
  });

  const PianoViewSettings.defaults() : widthScale = 1.0, heightScale = 1.0;

  /// Allowed range for both factors. The current layout is the minimum.
  static const double minScale = 1.0;
  static const double maxScale = 3.0;

  final double widthScale;
  final double heightScale;

  bool get isDefault => widthScale == 1.0 && heightScale == 1.0;

  static double clampScale(double value) => value.clamp(minScale, maxScale);

  PianoViewSettings copyWith({double? widthScale, double? heightScale}) {
    return PianoViewSettings(
      widthScale: widthScale ?? this.widthScale,
      heightScale: heightScale ?? this.heightScale,
    );
  }
}
