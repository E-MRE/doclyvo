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
        ClipRRect(
          borderRadius: BorderRadius.circular(Sizes.xs),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: Sizes.sm,
                child: Stack(
                  children: [
                    Container(color: theme.scaffoldBackgroundColor),
                    Container(
                      width: constraints.maxWidth * fraction,
                      color: barColor,
                    ),
                  ],
                ),
              );
            },
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
