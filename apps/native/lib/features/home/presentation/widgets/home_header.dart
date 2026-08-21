import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/app/theme/theme_service.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Sticky top bar of the home screen, in three tiers.
///
/// `design/Main.dc.html` and `design/MobileHome.dc.html` only draw the two ends
/// of the range: a wide header with five centered nav links, and a phone header
/// with just the logo and the theme toggle. Between them — roughly 700px to
/// 1080px, a resized desktop window or a landscape tablet — the desktop branch
/// used to render its nav links into a box too narrow for them and overflow, so
/// there is a middle tier: desktop paddings and type, mobile's slimmed-down
/// contents.
final class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.isMobile,
    required this.themeService,
    super.key,
  });

  final bool isMobile;
  final ThemeService themeService;

  @override
  Widget build(BuildContext context) {
    // Read the width the same way HomeScreen picks `isMobile`, so the two
    // tier decisions can never disagree about what the window is doing.
    final showNavLinks =
        !isMobile &&
        MediaQuery.sizeOf(context).width >=
            ResponsiveConstants.headerNavBreakpoint;

    return Container(
      padding: isMobile
          ? AppInsets.symmetricH16.add(AppInsets.symmetricV12)
          : AppInsets.symmetricH24.add(
              const EdgeInsets.symmetric(vertical: Sizes.md + Sizes.xs),
            ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.surfaceBorderColor)),
      ),
      child: Row(
        children: [
          _Wordmark(isMobile: isMobile),
          if (showNavLinks) ...[
            const Spacer(),
            const _NavLinks(),
          ],
          const Spacer(),
          _ThemeToggleButton(themeService: themeService),
        ],
      ),
    );
  }
}

/// Accent icon capsule plus the `doclyvo` word, the one element every tier
/// keeps.
final class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capsuleSize = isMobile ? Sizes.xl + Sizes.xs : Sizes.xxl + Sizes.xs;

    return Row(
      children: [
        Container(
          width: capsuleSize,
          height: capsuleSize,
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
        const SizedBox(width: Sizes.sm),
        Text(
          LocaleKeys.appName.tr(),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: isMobile ? Sizes.typeBody + 2 : Sizes.typeH2,
          ),
        ),
      ],
    );
  }
}

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
