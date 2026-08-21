import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/app/widgets/buttons/secondary_button.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/features/merge/domain/models/merge_file_entry.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

part 'merge_file_list/_empty_file_list.dart';
part 'merge_file_list/_file_row.dart';

/// The reorderable file list from `design/Merge.dc.html` / `design/
/// MobileMerge.dc.html`: a header with an "add files" action, then one row
/// per picked PDF showing its order, name, page count and size, with
/// up/down move buttons and a remove button.
///
/// `design/Merge.dc.html`'s header copy says "sürükleyerek veya oklarla" (by
/// drag or by arrows), but only the arrow half is implemented — see the
/// P3A-3 Decisions log entry for why drag reordering was dropped in favor of
/// the up/down-arrow idiom the task table already established for
/// Rotate/Reorder. The widget is controlled: [entries] and its order live in
/// the caller's state, this only renders it and reports intents.
final class MergeFileList extends StatelessWidget {
  const MergeFileList({
    required this.entries,
    required this.onAddFiles,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    this.tier = ScreenTier.desktop,
    this.enabled = true,
    super.key,
  });

  final List<MergeFileEntry> entries;
  final VoidCallback onAddFiles;
  final ValueChanged<int> onMoveUp;
  final ValueChanged<int> onMoveDown;
  final ValueChanged<int> onRemove;
  final ScreenTier tier;

  /// When `false`, add/move/remove are all disabled (e.g. while merging).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                LocaleKeys.merge_fileListSectionTitle.tr(),
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
              label: LocaleKeys.merge_addFilesAction.tr(),
              icon: Icons.add,
              onPressed: enabled ? onAddFiles : null,
            ),
          ],
        ),
        const SizedBox(height: Sizes.md),
        if (entries.isEmpty)
          const _EmptyFileList()
        else
          Column(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                _FileRow(
                  entry: entries[i],
                  order: i + 1,
                  isFirst: i == 0,
                  isLast: i == entries.length - 1,
                  enabled: enabled,
                  onMoveUp: () => onMoveUp(i),
                  onMoveDown: () => onMoveDown(i),
                  onRemove: () => onRemove(i),
                ),
                if (i != entries.length - 1) const SizedBox(height: Sizes.sm),
              ],
            ],
          ),
      ],
    );
  }
}
