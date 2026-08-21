part of '../upload_dropzone.dart';

/// Selected state — accent-soft tile with the file name, size and a remove
/// button, mirroring the `hasFile` branch of `design/MobileHome.dc.html`.
final class _SelectedFileTile extends StatelessWidget {
  const _SelectedFileTile({required this.file, required this.onRemove});

  final PickedPdfFile file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const iconSize = Sizes.xxl + Sizes.xs;

    return Container(
      padding: AppInsets.all16,
      decoration: BoxDecoration(
        color: context.accentSoftColor,
        borderRadius: BorderRadius.circular(Sizes.radiusButton),
      ),
      child: Row(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(Sizes.radiusSmall),
            ),
            child: Icon(
              Icons.picture_as_pdf_outlined,
              size: Sizes.lg,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: Sizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Sizes.xs),
                Text(
                  file.formattedSize,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: context.textSoftColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Sizes.sm),
          IconButton(
            onPressed: onRemove,
            tooltip: LocaleKeys.upload_remove.tr(),
            icon: Icon(
              Icons.close_rounded,
              size: Sizes.lg,
              color: context.textSoftColor,
            ),
          ),
        ],
      ),
    );
  }
}
