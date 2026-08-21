part of '../result_panel.dart';

final class _SizeBlock extends StatelessWidget {
  const _SizeBlock({
    required this.label,
    required this.valueText,
    required this.fraction,
    required this.barColor,
    this.valueColor,
  });

  final String label;
  final String valueText;
  final double fraction;
  final Color barColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w400,
            color: context.textSoftColor,
          ),
        ),
        const SizedBox(height: Sizes.sm),
        // FractionallySizedBox, not a LayoutBuilder: this panel renders inside
        // the tool screens' desktop `IntrinsicHeight` row, which cannot
        // measure a LayoutBuilder — see the note on `_ProgressBar`.
        ClipRRect(
          borderRadius: BorderRadius.circular(Sizes.xs),
          child: SizedBox(
            height: Sizes.sm,
            child: DecoratedBox(
              decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction.clamp(0.0, 1.0),
                child: DecoratedBox(decoration: BoxDecoration(color: barColor)),
              ),
            ),
          ),
        ),
        const SizedBox(height: Sizes.sm),
        Text(
          valueText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
