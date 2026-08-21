part of '../merge_file_list.dart';

/// One row in the file list: order number, a small file-icon tile, the
/// name/page-count/size, then move-up/move-down/remove icon buttons —
/// matches `design/Merge.dc.html`'s row layout exactly (drag handle aside,
/// see the `MergeFileList` doc comment for why).
final class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.entry,
    required this.order,
    required this.isFirst,
    required this.isLast,
    required this.enabled,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final MergeFileEntry entry;
  final int order;
  final bool isFirst;
  final bool isLast;
  final bool enabled;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = entry.file;

    return Container(
      padding: AppInsets.symmetricH12.add(AppInsets.symmetricV12),
      decoration: BoxDecoration(
        border: Border.all(color: context.surfaceBorderColor),
        borderRadius: BorderRadius.circular(Sizes.radiusButton),
      ),
      child: Row(
        children: [
          SizedBox(
            width: Sizes.xl,
            child: Text(
              '$order',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: context.textSoftColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: Sizes.md),
          Container(
            width: Sizes.xxl,
            height: Sizes.xxl + Sizes.md,
            decoration: BoxDecoration(
              color: context.accentSoftColor,
              border: Border.all(color: context.surfaceBorderColor),
              borderRadius: BorderRadius.circular(Sizes.sm),
            ),
            child: Icon(
              Icons.description_outlined,
              size: Sizes.lg,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: Sizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  entry.pageCount == null
                      ? file.formattedSize
                      : LocaleKeys.merge_fileMeta.tr(
                          namedArgs: {
                            'pages': '${entry.pageCount}',
                            'size': file.formattedSize,
                          },
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: context.textSoftColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: enabled && !isFirst ? onMoveUp : null,
            icon: const Icon(Icons.keyboard_arrow_up),
            color: context.textSoftColor,
            tooltip: LocaleKeys.merge_moveUp.tr(),
          ),
          IconButton(
            onPressed: enabled && !isLast ? onMoveDown : null,
            icon: const Icon(Icons.keyboard_arrow_down),
            color: context.textSoftColor,
            tooltip: LocaleKeys.merge_moveDown.tr(),
          ),
          IconButton(
            onPressed: enabled ? onRemove : null,
            icon: const Icon(Icons.close),
            color: context.textSoftColor,
            tooltip: LocaleKeys.merge_removeFile.tr(),
          ),
        ],
      ),
    );
  }
}
