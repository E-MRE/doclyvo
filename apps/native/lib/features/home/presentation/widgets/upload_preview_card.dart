import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/app/widgets/buttons/primary_button.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

final class UploadPreviewCard extends StatelessWidget {
  const UploadPreviewCard({
    required this.tier,
    required this.onSelectFile,
    super.key,
  });

  final ScreenTier tier;
  final VoidCallback onSelectFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = tier == ScreenTier.mobile;

    return Container(
      padding: isMobile ? AppInsets.all16 : AppInsets.all24,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(Sizes.radiusCard),
        border: Border.all(color: context.surfaceBorderColor),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Sizes.lg,
          vertical: isMobile ? Sizes.xl - Sizes.xs : Sizes.xxl + Sizes.lg,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: context.surfaceBorderColor, width: 2),
          borderRadius: BorderRadius.circular(Sizes.radiusButton + Sizes.xs),
        ),
        child: Column(
          children: [
            Container(
              width: isMobile ? Sizes.xxl + Sizes.xs : Sizes.xxl + Sizes.xl,
              height: isMobile ? Sizes.xxl + Sizes.xs : Sizes.xxl + Sizes.xl,
              decoration: BoxDecoration(
                color: context.accentSoftColor,
                borderRadius: BorderRadius.circular(Sizes.radiusButton + Sizes.xs),
              ),
              child: Icon(
                Icons.upload_file_outlined,
                size: Sizes.xl,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: Sizes.md),
            Text(
              LocaleKeys.home_dropzoneTitle.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Sizes.xs),
            Text(
              LocaleKeys.home_dropzoneHint.tr(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: context.textSoftColor,
              ),
            ),
            const SizedBox(height: Sizes.lg),
            PrimaryButton(
              label: LocaleKeys.upload_selectFile.tr(),
              onPressed: onSelectFile,
            ),
          ],
        ),
      ),
    );
  }
}
