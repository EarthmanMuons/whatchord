import 'package:flutter/material.dart';

class InputDisplaySizing {
  const InputDisplaySizing._();

  static double textScale(BuildContext context) {
    return MediaQuery.textScalerOf(context).scale(1.0);
  }

  static double pedalScale(BuildContext context) {
    return _scale(context, weight: 0.4, max: 1.45);
  }

  static double noteScale(BuildContext context) {
    return _scale(context, weight: 0.35, max: 1.35);
  }

  static double noteVerticalScale(BuildContext context) {
    return _scale(context, weight: 0.55, max: 1.95);
  }

  static double rowHeightScale(BuildContext context) {
    final base = _scale(context, weight: 0.7, max: 2.0);
    final vertical = noteVerticalScale(context);
    return base > vertical ? base : vertical;
  }

  static double _scale(
    BuildContext context, {
    required double weight,
    required double max,
  }) {
    final scale = 1.0 + (textScale(context) - 1.0) * weight;
    return scale.clamp(1.0, max);
  }
}
