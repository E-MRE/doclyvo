import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/features/compress/domain/models/compress_quality.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The three compression-level pills from `design/Compress.dc.html`'s
/// `isIdle` branch — a title, a hint, and an illustrative percent, with the
/// selected pill outlined in the accent color.
final class QualitySelector extends StatelessWidget {
  const QualitySelector({
    required this.selected,
    required this.onSelected,
    this.enabled = true,
    super.key,
  });

  final CompressQuality selected;
  final ValueChanged<CompressQuality> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.compress_qualitySectionTitle.tr(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: context.textSoftColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: Sizes.md),
        for (final quality in CompressQuality.values) ...[
          _QualityPill(
            quality: quality,
            isSelected: quality == selected,
            onTap: enabled ? () => onSelected(quality) : null,
          ),
          if (quality != CompressQuality.values.last)
            const SizedBox(height: Sizes.sm),
        ],
      ],
    );
  }
}

final class _QualityPill extends StatelessWidget {
  const _QualityPill({
    required this.quality,
    required this.isSelected,
    required this.onTap,
  });

  final CompressQuality quality;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppInsets.symmetricH16.add(AppInsets.symmetricV12),
        decoration: BoxDecoration(
          color: isSelected ? context.accentSoftColor : null,
          borderRadius: BorderRadius.circular(Sizes.radiusButton),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : context.surfaceBorderColor,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    quality.titleKey.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    quality.hintKey.tr(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: context.textSoftColor,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              quality.illustrativePercent,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
