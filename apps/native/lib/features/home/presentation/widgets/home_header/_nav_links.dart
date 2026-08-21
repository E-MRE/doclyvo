part of '../home_header.dart';

/// The five section labels, shown only on the widest tier.
final class _NavLinks extends StatelessWidget {
  const _NavLinks();

  static const List<String> _labelKeys = [
    LocaleKeys.home_navAllTools,
    LocaleKeys.home_navConvert,
    LocaleKeys.home_navEdit,
    LocaleKeys.home_navOrganize,
    LocaleKeys.home_navSecurity,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: Sizes.xl,
      children: [
        for (final (index, labelKey) in _labelKeys.indexed)
          _NavLink(labelKey: labelKey, emphasized: index == 0),
      ],
    );
  }
}
