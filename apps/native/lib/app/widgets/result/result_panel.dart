import 'dart:async';

import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/app/widgets/buttons/primary_button.dart';
import 'package:doclyvo/app/widgets/buttons/secondary_button.dart';
import 'package:doclyvo/app/widgets/cards/app_card.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The success state shared by all 11 tool screens, from
/// `design/Result.dc.html` / `design/MobileResult.dc.html`: a pop-in success
/// badge, a before/after file size comparison, a download button and an
/// optional secondary action, plus a conditional 24-hour auto-delete notice.
///
/// Lives in `lib/app/widgets/` rather than `lib/core/widgets/` for the same
/// reason `UploadDropzone` and `ToolProgressIndicator` do (see the P2-1
/// Decisions log entry in `NATIVE-TASKS.md`): it needs `BuildContextExtension`
/// and the `PrimaryButton`/`SecondaryButton`/`AppCard` widgets, all in
/// `lib/app/`, and `core/` may not import `app/`.
///
/// [beforeSizeInBytes]/[afterSizeInBytes] must be supplied together or not at
/// all — the comparison card only renders when both are known. Byte sizes are
/// formatted the same way `PickedPdfFile.formattedSize` does (`KB`/`MB`/`GB`,
/// not localized — the unit symbols read the same in Turkish).
///
/// [showAutoDeleteNotice] is caller-controlled rather than inferred here: it
/// only makes sense for Phase 3B (backend-processed) results, never for
/// Phase 3A files that never left the device.
final class ResultPanel extends StatefulWidget {
  const ResultPanel({
    required this.message,
    required this.fileName,
    required this.onDownload,
    this.pageCount,
    this.beforeSizeInBytes,
    this.afterSizeInBytes,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.showAutoDeleteNotice = false,
    this.tier = ScreenTier.desktop,
    super.key,
  }) : assert(
         (beforeSizeInBytes == null) == (afterSizeInBytes == null),
         'beforeSizeInBytes and afterSizeInBytes must be supplied together',
       ),
       assert(
         (secondaryActionLabel == null) == (onSecondaryAction == null),
         'secondaryActionLabel and onSecondaryAction must be supplied '
         'together',
       );

  /// Subtitle under the "Dosyan hazır" heading, e.g.
  /// "rapor-2024.pdf sıkıştırıldı ve indirilmeye hazır." Tool-specific copy,
  /// owned by the caller.
  final String message;

  /// The output file's name, shown in the file info row.
  final String fileName;

  /// Fires when the download button is tapped. Actually saving the bytes to
  /// disk (share-sheet, downloads dir, file-save dialog) is the caller's job
  /// — the bytes source differs between Phase 3A/3B.
  final VoidCallback onDownload;

  /// Page count shown under the file name, when known.
  final int? pageCount;

  /// Size of the input file, in bytes. Must be supplied together with
  /// [afterSizeInBytes] or not at all.
  final int? beforeSizeInBytes;

  /// Size of the output file, in bytes.
  final int? afterSizeInBytes;

  /// Label for an optional second action (e.g. "Bağlantıyı Kopyala"). Must be
  /// supplied together with [onSecondaryAction] or not at all.
  final String? secondaryActionLabel;

  final VoidCallback? onSecondaryAction;

  /// Shows the "deleted after 24 hours" notice. Only meaningful for
  /// backend-processed (Phase 3B) results.
  final bool showAutoDeleteNotice;

  /// The current [ScreenTier]. Only `mobile` stacks the actions vertically —
  /// `tablet` maps to the desktop layout for now.
  final ScreenTier tier;

  @override
  State<ResultPanel> createState() => _ResultPanelState();
}

final class _ResultPanelState extends State<ResultPanel>
    with SingleTickerProviderStateMixin {
  static const _popInDuration = Duration(milliseconds: 400);

  late final AnimationController _badgeController = AnimationController(
    vsync: this,
    duration: _popInDuration,
  );
  late final Animation<double> _badgeScale = CurvedAnimation(
    parent: _badgeController,
    curve: Curves.easeOutBack,
  );

  bool _hasAnimated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `prefers-reduced-motion` parity with `design/README.md`'s motion
    // conventions — jump straight to the settled state, no pop.
    if (_hasAnimated) return;
    _hasAnimated = true;
    if (MediaQuery.of(context).disableAnimations) {
      _badgeController.value = 1;
    } else {
      unawaited(_badgeController.forward());
    }
  }

  @override
  void dispose() {
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = widget.tier == ScreenTier.mobile;
    final verticalPadding = isMobile ? Sizes.lg : Sizes.xl;
    final hasComparison =
        widget.beforeSizeInBytes != null && widget.afterSizeInBytes != null;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _badgeScale,
            child: Container(
              width: Sizes.xxl * 2,
              height: Sizes.xxl * 2,
              decoration: BoxDecoration(
                color: context.accentSoftColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: Sizes.xl + Sizes.xs,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: Sizes.lg),
          Text(
            LocaleKeys.result_ready.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: Sizes.xs),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.textSoftColor,
            ),
          ),
          const SizedBox(height: Sizes.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FileInfoRow(
                  fileName: widget.fileName,
                  pageCount: widget.pageCount,
                ),
                if (hasComparison) ...[
                  const SizedBox(height: Sizes.lg),
                  _SizeComparisonRow(
                    beforeSizeInBytes: widget.beforeSizeInBytes!,
                    afterSizeInBytes: widget.afterSizeInBytes!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Sizes.lg),
          _Actions(
            isMobile: isMobile,
            onDownload: widget.onDownload,
            secondaryActionLabel: widget.secondaryActionLabel,
            onSecondaryAction: widget.onSecondaryAction,
          ),
          if (widget.showAutoDeleteNotice) ...[
            const SizedBox(height: Sizes.sm),
            Text(
              LocaleKeys.result_autoDelete.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: context.textSoftColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// File icon, name (truncated with an ellipsis) and optional page count.
final class _FileInfoRow extends StatelessWidget {
  const _FileInfoRow({required this.fileName, this.pageCount});

  final String fileName;
  final int? pageCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const iconBoxSize = Sizes.xxl + Sizes.xs;

    return Row(
      children: [
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: context.accentSoftColor,
            border: Border.all(color: context.surfaceBorderColor),
            borderRadius: BorderRadius.circular(Sizes.radiusSmall),
          ),
          child: Icon(
            Icons.picture_as_pdf_outlined,
            size: Sizes.lg,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: Sizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (pageCount != null) ...[
                const SizedBox(height: Sizes.xs),
                Text(
                  LocaleKeys.result_pageCount.tr(
                    namedArgs: {'count': '$pageCount'},
                  ),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: context.textSoftColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The before/after size blocks. Each block lives inside an [Expanded] rather
/// than a fixed width, so this never rigid-overflows regardless of surface
/// width — the tablet-width overflow trap this shape is prone to (see
/// `apps/native/CLAUDE.md`) comes from fixed-width children, not flexible
/// ones.
final class _SizeComparisonRow extends StatelessWidget {
  const _SizeComparisonRow({
    required this.beforeSizeInBytes,
    required this.afterSizeInBytes,
  });

  final int beforeSizeInBytes;
  final int afterSizeInBytes;

  static const List<String> _unitSymbols = ['B', 'KB', 'MB', 'GB'];
  static const int _unitStep = 1024;

  /// Not localized on purpose, same reasoning as
  /// `PickedPdfFile.formattedSize`: `KB`/`MB`/`GB` read the same in Turkish.
  static String _formatBytes(int bytes) {
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= _unitStep && unitIndex < _unitSymbols.length - 1) {
      size /= _unitStep;
      unitIndex++;
    }
    final fractionDigits = unitIndex == 0 ? 0 : 1;
    return '${size.toStringAsFixed(fractionDigits)} ${_unitSymbols[unitIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final afterFraction = beforeSizeInBytes <= 0
        ? 0.0
        : (afterSizeInBytes / beforeSizeInBytes).clamp(0.0, 1.0);
    final deltaPercent = beforeSizeInBytes <= 0
        ? 0
        : (((afterSizeInBytes - beforeSizeInBytes) / beforeSizeInBytes) * 100)
              .round();
    final sign = deltaPercent > 0 ? '+' : '';
    final afterText = '${_formatBytes(afterSizeInBytes)} · $sign$deltaPercent%';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SizeBlock(
            label: LocaleKeys.result_beforeSize.tr(),
            valueText: _formatBytes(beforeSizeInBytes),
            fraction: 1,
            barColor: context.surfaceBorderColor,
          ),
        ),
        const SizedBox(width: Sizes.lg),
        Expanded(
          child: _SizeBlock(
            label: LocaleKeys.result_afterSize.tr(),
            valueText: afterText,
            fraction: afterFraction,
            barColor: theme.colorScheme.primary,
            valueColor: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

final class _SizeBlock extends StatelessWidget {
  const _SizeBlock({
    required this.label,
    required this.valueText,
    required this.fraction,
    required this.barColor,
    this.valueColor,
  });

  final String label;
  final String valueText;
  final double fraction;
  final Color barColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w400,
            color: context.textSoftColor,
          ),
        ),
        const SizedBox(height: Sizes.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(Sizes.xs),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: Sizes.sm,
                child: Stack(
                  children: [
                    Container(color: theme.scaffoldBackgroundColor),
                    Container(
                      width: constraints.maxWidth * fraction,
                      color: barColor,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: Sizes.sm),
        Text(
          valueText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

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
