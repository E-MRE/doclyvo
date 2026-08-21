part of '../rotate_page_grid.dart';

/// One tile in the grid: the page's preview (or a placeholder while it
/// streams in), a page-number badge, a selection checkmark, and — when
/// selected — the preview rotated by [angle] so the user can see what will
/// happen before starting, matching `apps/web`'s `rotate(${deg}) scale(0.75)`
/// selected-state transform.
final class _PageTile extends StatelessWidget {
  const _PageTile({
    required this.entry,
    required this.angle,
    required this.onTap,
  });

  final RotatePageEntry entry;
  final RotateAngle angle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnail = entry.thumbnail;
    final selected = entry.selected;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : context.surfaceBorderColor,
                  width: selected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(Sizes.sm),
              ),
              child: Center(
                child: thumbnail == null
                    ? const SizedBox(
                        width: Sizes.lg,
                        height: Sizes.lg,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : AnimatedRotation(
                        turns: selected ? angle.degrees / 360 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Padding(
                          padding: const EdgeInsets.all(Sizes.xs),
                          child: Image.memory(
                            thumbnail.pngBytes,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            top: Sizes.xs,
            right: Sizes.xs,
            child: Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              size: Sizes.lg,
              color: selected
                  ? theme.colorScheme.primary
                  : context.textSoftColor,
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
    );
  }
}
