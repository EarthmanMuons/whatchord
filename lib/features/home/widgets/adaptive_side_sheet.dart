import 'dart:ui' show clampDouble;

import 'package:flutter/material.dart';

import '../models/home_layout_config.dart';

bool useHomeSideSheet(BuildContext context) {
  final sizeClass = homeSizeClassForSize(MediaQuery.sizeOf(context));
  return sizeClass != HomeSizeClass.compact;
}

Future<T?> showHomeSideSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String barrierLabel = 'Dismiss',
}) {
  final mq = MediaQuery.of(context);
  final sizeClass = homeSizeClassForSize(mq.size);
  final config = homeSideSheetConfigForSizeClass(sizeClass);
  final isPortrait = mq.size.height >= mq.size.width;
  final width = clampDouble(
    mq.size.width * config.widthFactor,
    config.minWidth,
    config.maxWidth,
  );
  final effectiveHeightFactor = isPortrait
      ? config.portraitHeightFactor
      : config.landscapeHeightFactor;
  final maxHeight = clampDouble(
    mq.size.height * effectiveHeightFactor,
    config.minHeight,
    mq.size.height,
  );

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: Colors.black26,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: config.verticalMargin),
        child: SafeArea(
          left: false,
          child: Align(
            alignment: Alignment.centerRight,
            child: Dismissible(
              key: const ValueKey('home_side_sheet'),
              direction: DismissDirection.startToEnd,
              dismissThresholds: const {DismissDirection.startToEnd: 0.22},
              resizeDuration: null,
              onDismissed: (_) => Navigator.of(context).maybePop(),
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(20),
                  ),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: config.minHeight,
                    maxHeight: maxHeight,
                  ),
                  child: SizedBox(width: width, child: builder(context)),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}
