part of '../home_screen.dart';

final class _ToolsSection extends StatelessWidget {
  const _ToolsSection({required this.theme, required super.key});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.home_toolsSectionTitle.tr(),
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: Sizes.xs),
        Text(
          LocaleKeys.home_toolsSectionSubtitle.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.textSoftColor,
          ),
        ),
      ],
    );
  }
}
