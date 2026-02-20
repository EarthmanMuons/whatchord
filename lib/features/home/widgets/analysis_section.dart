import 'dart:ui' show clampDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/demo/demo.dart';
import 'package:whatchord/features/input/input.dart';
import 'package:whatchord/features/theory/theory.dart';

import '../models/home_layout_config.dart';
import 'identity_card.dart';

class AnalysisSection extends ConsumerWidget {
  const AnalysisSection({super.key, required this.config});

  final HomeLayoutConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityDisplayProvider);
    final showIdle = ref.watch(inputIdleEligibleProvider);
    final demoEnabled = ref.watch(demoModeProvider);
    final demoVariant = ref.watch(demoModeVariantProvider);
    final showDemoControls =
        demoEnabled && demoVariant == DemoModeVariant.interactive;

    Future<void> stepDemo(
      void Function(DemoSequenceNotifier notifier) step,
    ) async {
      if (!showDemoControls) return;
      step(ref.read(demoSequenceProvider.notifier));
      ref.read(demoModeProvider.notifier).applyCurrentStep();
      await HapticFeedback.selectionClick();
    }

    Widget identityCard({required bool fillCard}) => _IdentityCardWithChevrons(
      showControls: showDemoControls,
      onPrevious: () => stepDemo((notifier) => notifier.prev()),
      onNext: () => stepDemo((notifier) => notifier.next()),
      child: IdentityCard(
        identity: identity,
        showIdle: showIdle,
        idleAsset: 'assets/logos/whatchord_logo_circle.svg',
        textScaleMultiplier: config.identityCardTextScale,
        fill: fillCard,
      ),
    );

    return Padding(
      padding: config.analysisPadding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = config.isLandscape;
          final preferredW = clampDouble(
            config.analysisCardPreferredWidth,
            0.0,
            config.chordCardMaxWidth,
          );
          final cardW = clampDouble(preferredW, 0.0, constraints.maxWidth);

          // Tunables
          final textScale = MediaQuery.textScalerOf(context).scale(1.0);
          final topPad = isLandscape
              ? 0.0
              : clampDouble(
                  config.analysisTopPadMax - (textScale - 1.0) * 28.0,
                  config.analysisTopPadMin,
                  config.analysisTopPadMax,
                );
          final cardH = config.analysisCardHeight;
          final listGap = config.analysisListGap;
          final laneH = constraints.maxHeight;
          final cardMaxH = clampDouble(
            config.analysisCardMaxHeight,
            0.0,
            laneH,
          );
          final listMaxH = clampDouble(
            laneH - topPad - cardH - listGap,
            0.0,
            laneH,
          );

          return SizedBox.expand(
            child: isLandscape
                ? Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: cardW,
                        maxHeight: cardMaxH,
                      ),
                      child: identityCard(fillCard: true),
                    ),
                  )
                : Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: topPad),
                      child: SizedBox(
                        width: cardW,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: cardW,
                              height: cardH,
                              child: identityCard(fillCard: true),
                            ),

                            if (!isLandscape) ...[
                              SizedBox(height: listGap),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: listMaxH,
                                ),
                                child: NearTieChordCandidatesList(
                                  enabled: true,
                                  alignment: Alignment.topCenter,
                                  textAlign: TextAlign.center,
                                  gap: 8,
                                  textScaleMultiplier: config.nearTieTextScale,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _IdentityCardWithChevrons extends StatelessWidget {
  const _IdentityCardWithChevrons({
    required this.child,
    required this.showControls,
    required this.onPrevious,
    required this.onNext,
  });

  final Widget child;
  final bool showControls;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    if (!showControls) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Align(
          alignment: Alignment.centerLeft,
          child: _DemoStepChevronButton(
            icon: Icons.chevron_left,
            tooltip: 'Previous demo step',
            onTap: onPrevious,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: _DemoStepChevronButton(
            icon: Icons.chevron_right,
            tooltip: 'Next demo step',
            onTap: onNext,
          ),
        ),
      ],
    );
  }
}

class _DemoStepChevronButton extends StatefulWidget {
  const _DemoStepChevronButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_DemoStepChevronButton> createState() => _DemoStepChevronButtonState();
}

class _DemoStepChevronButtonState extends State<_DemoStepChevronButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = _hovered || _pressed;
    final iconColor = cs.onPrimary.withValues(alpha: active ? 0.96 : 0.68);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Semantics(
        button: true,
        label: widget.tooltip,
        onTapHint: widget.tooltip,
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.tooltip,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onTap,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              opacity: active ? 1.0 : 0.76,
              child: SizedBox(
                width: 56,
                height: 56,
                child: Icon(widget.icon, color: iconColor, size: 36),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
