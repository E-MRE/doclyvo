import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

/// The page-number tile grid from `design/Split.dc.html`'s file card —
/// plain numbered boxes, not real page thumbnails (real per-page rendering is
/// Rotate/Reorder's job, per the Phase 3A table).
///
/// [pageCount] may be `null` while it is still being read (or failed to
/// read); the grid then shows nothing rather than a wrong number. Capped at
/// [maxTiles] so a huge document doesn't lay out hundreds of boxes.
final class SplitPageGrid extends StatelessWidget {
  const SplitPageGrid({
    required this.pageCount,
    this.tier = ScreenTier.desktop,
    super.key,
  });

  final int? pageCount;
  final ScreenTier tier;

  static const int maxTiles = 24;

  @override
  Widget build(BuildContext context) {
    final count = pageCount;
    if (count == null || count <= 0) return const SizedBox.shrink();

    final visibleCount = count > maxTiles ? maxTiles : count;
    final crossAxisCount = tier == ScreenTier.desktop ? 6 : 4;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 3 / 4,
        crossAxisSpacing: Sizes.sm,
        mainAxisSpacing: Sizes.sm,
      ),
      itemCount: visibleCount,
      itemBuilder: (context, index) => _PageTile(number: index + 1),
    );
  }
}

final class _PageTile extends StatelessWidget {
  const _PageTile({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border.all(color: context.surfaceBorderColor),
              borderRadius: BorderRadius.circular(Sizes.xs + Sizes.xs / 2),
            ),
          ),
        ),
        Positioned(
          bottom: Sizes.xs,
          right: Sizes.xs,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(Sizes.sm),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Sizes.xs + 1,
                vertical: 1,
              ),
              child: Text(
                '$number',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.textSoftColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
