import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/app/widgets/buttons/secondary_button.dart';
import 'package:doclyvo/app/widgets/layout/tile_grid.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/features/rotate/domain/models/rotate_angle.dart';
import 'package:doclyvo/features/rotate/domain/models/rotate_page_entry.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

part 'rotate_page_grid/_page_tile.dart';

/// The selectable page grid from `design/Rotate.dc.html` / `design/
/// MobileRotate.dc.html`: a header with select-all/deselect-all, then one
/// tile per page — tap to select, selected tiles preview [angle]'s rotation.
///
/// The widget is controlled: [entries] and their selection live in the
/// caller's state (same contract as `MergeFileList`), this only renders them
/// and reports intents.
final class RotatePageGrid extends StatelessWidget {
  const RotatePageGrid({
    required this.entries,
    required this.angle,
    required this.onToggleEntry,
    required this.onToggleAll,
    this.tier = ScreenTier.desktop,
    this.enabled = true,
    super.key,
  });

  final List<RotatePageEntry> entries;
  final RotateAngle angle;
  final ValueChanged<int> onToggleEntry;

  /// `true` selects every page, `false` clears the selection.
  final ValueChanged<bool> onToggleAll;
  final ScreenTier tier;

  /// When `false`, tapping tiles and the select-all actions are disabled
  /// (e.g. while rotating).
  final bool enabled;

  bool get _allSelected =>
      entries.isNotEmpty && entries.every((e) => e.selected);

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                LocaleKeys.rotate_pagesSectionTitle.tr(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: context.textSoftColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Sizes.sm),
            SecondaryButton(
              label: _allSelected
                  ? LocaleKeys.rotate_deselectAll.tr()
                  : LocaleKeys.rotate_selectAll.tr(),
              onPressed: enabled && entries.isNotEmpty
                  ? () => onToggleAll(!_allSelected)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: Sizes.md),
        TileGrid(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 3 / 4,
          children: [
            for (final (index, entry) in entries.indexed)
              _PageTile(
                entry: entry,
                angle: angle,
                onTap: enabled ? () => onToggleEntry(index) : null,
              ),
          ],
        ),
      ],
    );
  }
}
