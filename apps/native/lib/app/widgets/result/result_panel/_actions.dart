part of '../result_panel.dart';

/// The download button plus an optional secondary action. Stacked full-width
/// on mobile, side by side on tablet/desktop — mirrors
/// `design/MobileResult.dc.html` vs `design/Result.dc.html`.
final class _Actions extends StatelessWidget {
  const _Actions({
    required this.isMobile,
    required this.onDownload,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final bool isMobile;
  final VoidCallback onDownload;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final downloadButton = PrimaryButton(
      label: LocaleKeys.result_download.tr(),
      icon: Icons.download_rounded,
      onPressed: onDownload,
    );
    final secondaryButton = secondaryActionLabel == null
        ? null
        : SecondaryButton(
            label: secondaryActionLabel!,
            onPressed: onSecondaryAction,
          );

    if (isMobile) {
      return Column(
        children: [
          downloadButton,
          if (secondaryButton != null) ...[
            const SizedBox(height: Sizes.md),
            secondaryButton,
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        downloadButton,
        if (secondaryButton != null) ...[
          const SizedBox(width: Sizes.md),
          secondaryButton,
        ],
      ],
    );
  }
}
