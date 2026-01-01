import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/piano/piano.dart';

import '../../models/home_layout_config.dart';

class DetailsSection extends ConsumerWidget {
  const DetailsSection({super.key, required this.config});
  final HomeLayoutConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: config.detailsSectionPadding,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: ActiveInput(padding: config.activeInputPadding),
      ),
    );
  }
}
