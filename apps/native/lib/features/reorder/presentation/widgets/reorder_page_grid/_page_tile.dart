part of '../reorder_page_grid.dart';

/// One tile in the grid: the page's preview (or a placeholder while it
/// streams in) with its original page-number badge, its current position,
/// and left/right arrow buttons to move it — matches
/// `design/Reorder.dc.html`'s row layout, in grid form.
final class _PageTile extends StatelessWidget {
  const _PageTile({
    required this.entry,
    required this.position,
    required this.isFirst,
    required this.isLast,
    required this.onMoveLeft,
    required this.onMoveRight,
  });

  final ReorderPageEntry entry;
  final int position;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onMoveRight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnail = entry.thumbnail;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border.all(color: context.surfaceBorderColor),
                    borderRadius: BorderRadius.circular(Sizes.sm),
                  ),
                  child: Center(
                    child: thumbnail == null
                        ? const SizedBox(
                            width: Sizes.lg,
                            height: Sizes.lg,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(Sizes.xs),
                            child: Image.memory(
                              thumbnail.pngBytes,
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),
                ),
              ),
              Positioned(
                bottom: Sizes.xs,
                left: Sizes.xs,
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
                      '${entry.pageIndex + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.textSoftColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Sizes.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: isFirst ? null : onMoveLeft,
              icon: const Icon(Icons.keyboard_arrow_left),
              color: context.textSoftColor,
              tooltip: LocaleKeys.reorder_moveUp.tr(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Text(
              '$position',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              onPressed: isLast ? null : onMoveRight,
              icon: const Icon(Icons.keyboard_arrow_right),
              color: context.textSoftColor,
              tooltip: LocaleKeys.reorder_moveDown.tr(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }
}
