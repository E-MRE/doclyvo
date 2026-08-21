import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/app/theme/theme_service.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);

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
          Container(
            width: isMobile ? Sizes.xl + Sizes.xs : Sizes.xxl + Sizes.xs,
            height: isMobile ? Sizes.xl + Sizes.xs : Sizes.xxl + Sizes.xs,
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
          if (!isMobile) ...[
            const Spacer(),
            const _NavLink(
              labelKey: LocaleKeys.home_navAllTools,
              emphasized: true,
            ),
            const SizedBox(width: Sizes.xl),
            const _NavLink(labelKey: LocaleKeys.home_navConvert),
            const SizedBox(width: Sizes.xl),
            const _NavLink(labelKey: LocaleKeys.home_navEdit),
            const SizedBox(width: Sizes.xl),
            const _NavLink(labelKey: LocaleKeys.home_navOrganize),
            const SizedBox(width: Sizes.xl),
            const _NavLink(labelKey: LocaleKeys.home_navSecurity),
          ],
          const Spacer(),
          IconButton(
            onPressed: themeService.toggleTheme,
            tooltip: LocaleKeys.home_themeToggleTooltip.tr(),
            icon: Icon(
              context.isDarkMode
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
              color: context.textSoftColor,
            ),
          ),
        ],
      ),
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
