import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/app/widgets/layout/tile_grid.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/features/reorder/domain/models/reorder_page_entry.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

part 'reorder_page_grid/_page_tile.dart';

/// The reorderable page grid from `design/Reorder.dc.html` / `design/
/// MobileReorder.dc.html`: one tile per page in current order, each with
/// left/right arrows to move it — the up/down-arrow idiom `MergeFileList`
/// established (`design/Reorder.dc.html`'s copy also mentions dragging, but
/// only the arrow half is implemented, same precedent as Merge).
///
/// The widget is controlled: [entries] and their order live in the caller's
/// state, this only renders them and reports move intents by position.
final class ReorderPageGrid extends StatelessWidget {
  const ReorderPageGrid({
    required this.entries,
    required this.onMoveLeft,
    required this.onMoveRight,
    this.tier = ScreenTier.desktop,
    this.enabled = true,
    super.key,
  });

  final List<ReorderPageEntry> entries;
  final ValueChanged<int> onMoveLeft;
  final ValueChanged<int> onMoveRight;
  final ScreenTier tier;

  /// When `false`, the move arrows are disabled (e.g. while reordering).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final crossAxisCount = switch (tier) {
      ScreenTier.desktop => 6,
      ScreenTier.tablet => 4,
      ScreenTier.mobile => 3,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          LocaleKeys.reorder_pagesSectionTitle.tr(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: context.textSoftColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: Sizes.md),
        TileGrid(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.62,
          children: [
            for (final (index, entry) in entries.indexed)
              _PageTile(
                entry: entry,
                position: index + 1,
                isFirst: index == 0,
                isLast: index == entries.length - 1,
                onMoveLeft: enabled ? () => onMoveLeft(index) : null,
                onMoveRight: enabled ? () => onMoveRight(index) : null,
              ),
          ],
        ),
      ],
    );
  }
}
