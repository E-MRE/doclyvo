import 'dart:typed_data';

import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The design's left-hand card: the file's name, a page selector, and a
/// skeleton page showing where the signature will land.
///
/// Skeleton bars rather than a real rendered page, matching both design
/// exports and `apps/web` — the placement box is fixed, so a real thumbnail
/// would cost a render pass without telling the user anything the skeleton
/// does not. `PdfEngineService.renderThumbnails` is available if that ever
/// changes.
final class SignDocumentPreview extends StatelessWidget {
  const SignDocumentPreview({
    required this.fileName,
    required this.currentPage,
    required this.pageCount,
    required this.onPageChanged,
    this.signatureImageBytes,
    this.enabled = true,
    this.tier = ScreenTier.desktop,
    super.key,
  });

  final String fileName;

  /// One-based page the signature will be placed on.
  final int currentPage;

  /// Total pages, or `null` while the count is still being read.
  final int? pageCount;

  final ValueChanged<int> onPageChanged;

  /// The placed signature's PNG bytes, or `null` before it is placed.
  final Uint8List? signatureImageBytes;

  /// When `false`, page navigation is ignored (e.g. while processing).
  final bool enabled;

  final ScreenTier tier;

  /// Page height per tier. Fixed, with the width derived from it, so the whole
  /// preview is fully constrained: an `AspectRatio` here would have to answer
  /// intrinsic-height queries from the desktop layout's `IntrinsicHeight` row.
  double get _pageHeight => switch (tier) {
    ScreenTier.desktop => 480,
    ScreenTier.tablet => 420,
    ScreenTier.mobile => 360,
  };

  /// The design's 3:4 page proportion.
  double get _pageWidth => _pageHeight * 3 / 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = pageCount;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.textSoftColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (total != null && total > 0) ...[
              const SizedBox(width: Sizes.sm),
              _PageSelector(
                currentPage: currentPage,
                pageCount: total,
                enabled: enabled,
                onPageChanged: onPageChanged,
              ),
            ],
          ],
        ),
        const SizedBox(height: Sizes.lg),
        SizedBox(
          height: _pageHeight,
          width: _pageWidth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(Sizes.radiusSmall),
              border: Border.all(color: context.surfaceBorderColor),
            ),
            child: Padding(
              padding: AppInsets.all24,
              child: Stack(
                children: [
                  const _SkeletonLines(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: _SignatureSlot(
                      imageBytes: signatureImageBytes,
                      slotHeight: _pageHeight / 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final class _PageSelector extends StatelessWidget {
  const _PageSelector({
    required this.currentPage,
    required this.pageCount,
    required this.enabled,
    required this.onPageChanged,
  });

  final int currentPage;
  final int pageCount;
  final bool enabled;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final canGoBack = enabled && currentPage > 1;
    final canGoForward = enabled && currentPage < pageCount;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: LocaleKeys.sign_previousPage.tr(),
          icon: const Icon(Icons.chevron_left, size: Sizes.xl),
          onPressed: canGoBack ? () => onPageChanged(currentPage - 1) : null,
        ),
        Text(
          LocaleKeys.sign_pageIndicator.tr(
            namedArgs: {'current': '$currentPage', 'total': '$pageCount'},
          ),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.textSoftColor,
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: LocaleKeys.sign_nextPage.tr(),
          icon: const Icon(Icons.chevron_right, size: Sizes.xl),
          onPressed: canGoForward ? () => onPageChanged(currentPage + 1) : null,
        ),
      ],
    );
  }
}

final class _SkeletonLines extends StatelessWidget {
  const _SkeletonLines();

  /// The design's five bars, as fractions of the content width.
  static const List<double> _widthFactors = [0.6, 0.85, 0.75, 0.8, 0.5];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final factor in _widthFactors)
          Padding(
            padding: AppInsets.onlyBottom16,
            child: FractionallySizedBox(
              widthFactor: factor,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.surfaceBorderColor,
                  borderRadius: BorderRadius.circular(Sizes.xs),
                ),
                child: const SizedBox(height: Sizes.sm),
              ),
            ),
          ),
      ],
    );
  }
}

final class _SignatureSlot extends StatelessWidget {
  const _SignatureSlot({required this.imageBytes, required this.slotHeight});

  final Uint8List? imageBytes;
  final double slotHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bytes = imageBytes;

    if (bytes == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Sizes.sm),
          border: Border.all(color: context.surfaceBorderColor, width: 2),
        ),
        child: Padding(
          padding: AppInsets.all8,
          child: Text(
            LocaleKeys.sign_placementHint.tr(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.textSoftColor,
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.accentSoftColor,
        borderRadius: BorderRadius.circular(Sizes.sm),
        border: Border.all(color: theme.colorScheme.primary, width: 2),
      ),
      child: Padding(
        padding: AppInsets.all8,
        child: Image.memory(
          bytes,
          height: slotHeight,
          fit: BoxFit.contain,
          // The bytes are produced on-device by SignatureImageRenderer or
          // picked as a PNG, so a decode failure means the picked file lied
          // about its extension — show nothing rather than crashing layout.
          errorBuilder: (_, _, _) => SizedBox(height: slotHeight),
        ),
      ),
    );
  }
}
