import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The lock badge from `design/Protect.dc.html`'s left column: a padlock that
/// sits muted while the document is untouched and flips to the accent color
/// once it has been encrypted, with the matching status line underneath.
///
/// This tool has no page preview to show (unlike Watermark's), so the badge is
/// the whole left-hand visual — it is the only thing on the screen that says
/// "this file is now protected" outside the result panel.
final class ProtectLockStatus extends StatelessWidget {
  const ProtectLockStatus({
    required this.isProtected,
    this.tier = ScreenTier.desktop,
    super.key,
  });

  final bool isProtected;
  final ScreenTier tier;

  /// 96px on desktop, the mobile design's 88px everywhere else.
  double get _badgeSize => tier == ScreenTier.desktop ? 96 : 88;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _badgeSize,
          height: _badgeSize,
          decoration: BoxDecoration(
            color: isProtected
                ? context.accentSoftColor
                : theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(Sizes.radiusCard),
            border: Border.all(color: context.surfaceBorderColor),
          ),
          child: Icon(
            isProtected ? Icons.lock : Icons.lock_outline,
            size: _badgeSize / 2,
            color: isProtected ? accent : context.textSoftColor,
          ),
        ),
        const SizedBox(height: Sizes.md),
        Padding(
          padding: AppInsets.symmetricH8,
          child: Text(
            (isProtected
                    ? LocaleKeys.protect_lockStatusDone
                    : LocaleKeys.protect_lockStatusIdle)
                .tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isProtected ? accent : context.textSoftColor,
              fontWeight: isProtected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
