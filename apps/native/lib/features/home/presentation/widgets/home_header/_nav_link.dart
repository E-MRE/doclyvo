part of '../home_header.dart';

final class _NavLink extends StatelessWidget {
  const _NavLink({required this.labelKey, this.emphasized = false});

  final String labelKey;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      labelKey.tr(),
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: Sizes.typeLabel + 2,
        fontWeight: FontWeight.w500,
        color: emphasized
            ? theme.colorScheme.onSurface
            : context.textSoftColor,
      ),
    );
  }
}
