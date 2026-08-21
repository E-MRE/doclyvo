part of '../result_panel.dart';

/// File icon, name (truncated with an ellipsis) and optional page count.
final class _FileInfoRow extends StatelessWidget {
  const _FileInfoRow({required this.fileName, this.pageCount});

  final String fileName;
  final int? pageCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const iconBoxSize = Sizes.xxl + Sizes.xs;

    return Row(
      children: [
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: context.accentSoftColor,
            border: Border.all(color: context.surfaceBorderColor),
            borderRadius: BorderRadius.circular(Sizes.radiusSmall),
          ),
          child: Icon(
            Icons.picture_as_pdf_outlined,
            size: Sizes.lg,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: Sizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (pageCount != null) ...[
                const SizedBox(height: Sizes.xs),
                Text(
                  LocaleKeys.result_pageCount.tr(
                    namedArgs: {'count': '$pageCount'},
                  ),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: context.textSoftColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
