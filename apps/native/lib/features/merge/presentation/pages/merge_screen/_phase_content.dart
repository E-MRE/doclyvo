part of '../merge_screen.dart';

/// The summary-panel content, switched on [MergeState] and whether enough
/// files have been picked yet — mirrors `design/Merge.dc.html`'s
/// `isIdle`/`isProcessing`/`isDone` branches, plus an `Error` branch the
/// design doesn't draw but every tool screen needs.
final class _PhaseContent extends StatelessWidget {
  const _PhaseContent({
    required this.tier,
    required this.state,
    required this.fileCount,
    required this.totalPages,
    required this.canMerge,
    required this.onStart,
    required this.onRetry,
    required this.onDownload,
    required this.onReset,
  });

  final ScreenTier tier;
  final MergeState state;
  final int fileCount;
  final int totalPages;
  final bool canMerge;
  final VoidCallback onStart;
  final VoidCallback onRetry;
  final ValueChanged<Uint8List> onDownload;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final currentState = state;

    if (currentState is MergeLoading) {
      return ToolProgressIndicator(
        // `pdf_manipulator`'s `merge` exposes no progress callback (same as
        // `compress`/`split`, per the P0-11 Decisions log entry), so this is
        // an indeterminate/simulated state rather than a real byte count.
        progress: 60,
        label: LocaleKeys.merge_processingLabel.tr(),
        tier: tier,
      );
    }

    if (currentState is MergeSuccess) {
      return ResultPanel(
        message: LocaleKeys.merge_resultMessage.tr(
          namedArgs: {'count': '${currentState.fileCount}'},
        ),
        fileName: 'birlestirilmis.pdf',
        pageCount: currentState.totalPages,
        // No before/after comparison: Merge combines multiple inputs, so
        // there is no single meaningful "before" size (see the P2-3
        // Decisions log entry).
        onDownload: () => onDownload(currentState.mergedBytes),
        secondaryActionLabel: LocaleKeys.merge_newOperation.tr(),
        onSecondaryAction: onReset,
        tier: tier,
      );
    }

    if (currentState is MergeError) {
      return ErrorStateWidget(
        message: currentState.message,
        onRetry: onRetry,
        tier: tier,
      );
    }

    // MergeInitial: file-count/total-pages/output summary + start action,
    // matching the design's `isIdle` branch. There is no settings step for
    // Merge.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          LocaleKeys.merge_resultSectionTitle.tr(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.textSoftColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: Sizes.md),
        _SummaryRow(
          label: LocaleKeys.merge_fileCountLabel.tr(),
          value: '$fileCount',
          highlighted: true,
        ),
        const SizedBox(height: Sizes.sm),
        _SummaryRow(
          label: LocaleKeys.merge_totalPagesLabel.tr(),
          value: '$totalPages',
        ),
        const SizedBox(height: Sizes.sm),
        _SummaryRow(
          label: LocaleKeys.merge_outputLabel.tr(),
          value: LocaleKeys.merge_outputValue.tr(),
        ),
        if (!canMerge) ...[
          const SizedBox(height: Sizes.md),
          Text(
            LocaleKeys.merge_minFilesHint.tr(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.textSoftColor,
            ),
          ),
        ],
        const SizedBox(height: Sizes.xl),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: LocaleKeys.merge_startAction.tr(),
            onPressed: canMerge ? onStart : null,
          ),
        ),
      ],
    );
  }
}

/// One label/value row inside the idle summary, e.g. "Dosya sayısı: 3" or
/// "Toplam sayfa: 7" — [highlighted] gives it the accent-soft background
/// `design/Merge.dc.html` uses for the first row.
final class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: AppInsets.symmetricH16.add(AppInsets.symmetricV12),
      decoration: BoxDecoration(
        color: highlighted ? context.accentSoftColor : null,
        borderRadius: BorderRadius.circular(Sizes.radiusButton),
        border: highlighted
            ? null
            : Border.all(color: context.surfaceBorderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // The label is the flexible side (Expanded, not a fixed width) so
          // longer copy — "Çıkış dosyası" runs longer than Split's "Çıkış"
          // — shrinks with an ellipsis instead of pushing the value off the
          // edge of the row at narrow widths, same fix P2-3's Decisions log
          // entry recorded for ResultPanel's size-comparison row.
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.textSoftColor,
              ),
            ),
          ),
          const SizedBox(width: Sizes.sm),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
