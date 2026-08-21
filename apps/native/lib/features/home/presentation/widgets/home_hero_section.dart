import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/app/widgets/buttons/primary_button.dart';
import 'package:doclyvo/app/widgets/buttons/secondary_button.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

final class HomeHeroSection extends StatelessWidget {
  const HomeHeroSection({
    required this.isMobile,
    required this.onBrowseTools,
    super.key,
  });

  final bool isMobile;
  final VoidCallback onBrowseTools;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMobile)
          Container(
            padding: AppInsets.symmetricH12.add(
              const EdgeInsets.symmetric(vertical: Sizes.xs + 2),
            ),
            decoration: BoxDecoration(
              color: context.accentSoftColor,
              borderRadius: BorderRadius.circular(Sizes.xxl),
            ),
            child: Text(
              LocaleKeys.home_heroBadge.tr(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        if (!isMobile) const SizedBox(height: Sizes.lg),
        Text(
          LocaleKeys.home_heroTitle.tr(),
          style: isMobile
              ? theme.textTheme.headlineLarge?.copyWith(
                  fontSize: Sizes.typeH1 - 2,
                )
              : theme.textTheme.displayLarge,
        ),
        const SizedBox(height: Sizes.md),
        Text(
          LocaleKeys.home_heroSubtitle.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.textSoftColor,
            height: 1.5,
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(height: Sizes.xl),
          // Wrap, not Row: the hero only gets `flex: 6` of the row it shares
          // with the upload card, so between the mobile breakpoint and the
          // design width the two CTAs do not fit side by side. Wrapping lets
          // the secondary one drop to its own line instead of overflowing.
          Wrap(
            spacing: Sizes.md,
            runSpacing: Sizes.md,
            children: [
              PrimaryButton(
                label: LocaleKeys.home_ctaStart.tr(),
                onPressed: onBrowseTools,
              ),
              SecondaryButton(
                label: LocaleKeys.home_ctaViewAll.tr(),
                onPressed: onBrowseTools,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
