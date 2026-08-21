part of '../home_header.dart';

final class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton({required this.themeService});

  final ThemeService themeService;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: themeService.toggleTheme,
      tooltip: LocaleKeys.home_themeToggleTooltip.tr(),
      icon: Icon(
        context.isDarkMode
            ? Icons.dark_mode_outlined
            : Icons.light_mode_outlined,
        color: context.textSoftColor,
      ),
    );
  }
}
