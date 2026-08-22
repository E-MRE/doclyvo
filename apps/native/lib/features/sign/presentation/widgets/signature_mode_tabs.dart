import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/features/sign/domain/models/signature_mode.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The design's three-way segmented control (Çiz / Yaz / Yükle).
///
/// Each tab is an `Expanded`, so the three short labels share the panel width
/// evenly at every tier instead of a `Row` that can overflow — the label/value
/// `Row` fix P2-3 and P3A-3 already established.
final class SignatureModeTabs extends StatelessWidget {
  const SignatureModeTabs({
    required this.selected,
    required this.onModeSelected,
    this.enabled = true,
    super.key,
  });

  final SignatureMode selected;
  final ValueChanged<SignatureMode> onModeSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(Sizes.radiusSmall),
      ),
      child: Padding(
        padding: AppInsets.all4,
        child: Row(
          children: [
            for (final mode in SignatureMode.values)
              Expanded(
                child: _ModeTab(
                  label: mode.labelKey.tr(),
                  isSelected: mode == selected,
                  onTap: enabled ? () => onModeSelected(mode) : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Sizes.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(Sizes.sm),
        ),
        child: Padding(
          padding: AppInsets.symmetricV8,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : context.textSoftColor,
            ),
          ),
        ),
      ),
    );
  }
}
