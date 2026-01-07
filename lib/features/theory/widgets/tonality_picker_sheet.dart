import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/key_signature.dart';
import '../models/tonality.dart';
import '../providers/selected_tonality_notifier.dart';

class TonalityPickerSheet extends ConsumerStatefulWidget {
  const TonalityPickerSheet({super.key});

  @override
  ConsumerState<TonalityPickerSheet> createState() =>
      _TonalityPickerSheetState();
}

class _TonalityPickerSheetState extends ConsumerState<TonalityPickerSheet> {
  static const double _rowHeight = 62.0;
  static const double _headerHeight = 46.0;
  static const double _chipWidth = 64.0;

  late final ScrollController _controller;
  late final List<KeySignature> _rows;

  bool? _lastIsLandscape;

  @override
  void initState() {
    super.initState();

    _rows = _buildOrderedRows();
    _controller = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _centerSelectedRow(animated: false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedTonalityProvider);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final selectedRowBg = Color.alphaBlend(
      cs.primary.withValues(alpha: 0.06),
      cs.surface,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;

        final didOrientationChange =
            _lastIsLandscape != null && _lastIsLandscape != isLandscape;
        _lastIsLandscape = isLandscape;

        if (didOrientationChange) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _centerSelectedRow(animated: false);
          });
        }

        final mq = MediaQuery.of(context);

        // Always strip left/right for full-width expansion (existing behavior)
        final mqAdjusted = isLandscape
            ? mq.copyWith(
                padding: mq.padding.copyWith(left: 0, right: 0),
                viewPadding: mq.viewPadding.copyWith(left: 0, right: 0),
              )
            : mq;

        final screenHeight = mqAdjusted.size.height;
        final sheetHeight = isLandscape ? screenHeight : screenHeight * 0.42;

        return MediaQuery(
          data: mqAdjusted,
          child: SafeArea(
            left: !isLandscape,
            right: !isLandscape,
            child: SizedBox(
              height: sheetHeight,
              child: CustomScrollView(
                controller: _controller,
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TonalityPickerHeaderDelegate(
                      extent: _headerHeight,
                      chipWidth: _chipWidth,
                      backgroundColor: cs.surfaceContainerLow,
                    ),
                  ),
                  SliverFixedExtentList(
                    itemExtent: _rowHeight,
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final row = _rows[index];
                        final major = row.relativeMajor;
                        final minor = row.relativeMinor;

                        final rowSelected =
                            selected == major || selected == minor;
                        final majorSelected = selected == major;
                        final minorSelected = selected == minor;

                        return DecoratedBox(
                          decoration: BoxDecoration(
                            color: rowSelected
                                ? selectedRowBg
                                : Colors.transparent,
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          row.label,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: cs.onSurfaceVariant,
                                              ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: _chipWidth,
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: _TonalityChoiceChip(
                                            label: major.label,
                                            selected: majorSelected,
                                            onTap: () => _selectTonality(major),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: _chipWidth,
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: _TonalityChoiceChip(
                                            label: minor.label,
                                            selected: minorSelected,
                                            onTap: () => _selectTonality(minor),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Divider(height: 1),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: _rows.length, // finite
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<KeySignature> _buildOrderedRows() {
    KeySignature rowFor(int acc) =>
        keySignatureRows.firstWhere((r) => r.accidentalCount == acc);

    return <KeySignature>[
      for (var n = 7; n >= 1; n--) rowFor(n), // 7# … 1#
      rowFor(0), // 0
      for (var n = 1; n <= 7; n++) rowFor(-n), // 1b … 7b
    ];
  }

  int _indexForSelected(Tonality selected) {
    final i = _rows.indexWhere(
      (row) => row.relativeMajor == selected || row.relativeMinor == selected,
    );
    if (i >= 0) return i;

    // Fallback: center around 0 accidentals if something unexpected happens.
    return _rows.indexWhere((row) => row.accidentalCount == 0);
  }

  void _centerSelectedRow({required bool animated}) {
    if (!_controller.hasClients) return;

    final selected = ref.read(selectedTonalityProvider);
    final viewport = _controller.position.viewportDimension;

    final index = _indexForSelected(selected);

    final target = (index * _rowHeight) - (viewport / 2) + (_rowHeight / 2);

    final clamped = target.clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );

    if (!animated) {
      _controller.jumpTo(clamped);
      return;
    }

    _controller.animateTo(
      clamped,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  void _selectTonality(Tonality tonality) {
    ref.read(selectedTonalityProvider.notifier).setTonality(tonality);

    // Recenter after selection so the choice stays visually anchored.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _centerSelectedRow(animated: true);
    });
  }
}

class _TonalityPickerHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double extent;
  final double chipWidth;
  final Color backgroundColor;

  const _TonalityPickerHeaderDelegate({
    required this.extent,
    required this.chipWidth,
    required this.backgroundColor,
  });

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final headerStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    );

    return Material(
      color: backgroundColor,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: Text('Signature', style: headerStyle)),
                  SizedBox(
                    width: chipWidth,
                    child: Text(
                      'Major',
                      textAlign: TextAlign.center,
                      style: headerStyle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: chipWidth,
                    child: Text(
                      'Minor',
                      textAlign: TextAlign.center,
                      style: headerStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, thickness: 2),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TonalityPickerHeaderDelegate oldDelegate) {
    return oldDelegate.extent != extent ||
        oldDelegate.chipWidth != chipWidth ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _TonalityChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TonalityChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final side = BorderSide(
      color: selected ? cs.primary : cs.outlineVariant,
      width: selected ? 1.5 : 1.0,
    );

    return ChoiceChip(
      label: SizedBox(
        width: 44,
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: side,
      ),
    );
  }
}
