part of '../split_screen.dart';

/// The summary-panel content, switched on [SplitState] and whether a file has
/// been picked yet — mirrors `design/Split.dc.html`'s `isIdle`/`isProcessing`/
/// `isDone` branches, plus an `Error` branch the design doesn't draw but
/// every tool screen needs.
final class _PhaseContent extends StatelessWidget {
  const _PhaseContent({
    required this.tier,
    required this.state,
    required this.selectedFile,
    required this.pageCount,
    required this.onStart,
    required this.onRetry,
    required this.onDownload,
    required this.onReset,
  });

  final ScreenTier tier;
  final SplitState state;
  final PickedPdfFile? selectedFile;
  final int? pageCount;
  final VoidCallback onStart;
  final VoidCallback onRetry;
  final ValueChanged<Uint8List> onDownload;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final file = selectedFile;

    if (file == null) {
      return Text(
        LocaleKeys.split_selectFileFirst.tr(),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: context.textSoftColor),
      );
    }

    final currentState = state;
    if (currentState is SplitLoading) {
      return ToolProgressIndicator(
        // `pdf_manipulator`'s `split` exposes no progress callback (same as
        // `compress`, per the P0-11 Decisions log entry), so this is an
        // indeterminate/simulated state rather than a real byte count.
        progress: 60,
        label: LocaleKeys.split_processingLabel.tr(),
        tier: tier,
      );
    }

    if (currentState is SplitSuccess) {
      final outputName = _outputZipName(file.name);
      return ResultPanel(
        message: LocaleKeys.split_resultMessage.tr(
          namedArgs: {
            'fileName': file.name,
            'count': '${currentState.pageCount}',
          },
        ),
        fileName: outputName,
        pageCount: currentState.pageCount,
        onDownload: () => onDownload(currentState.zipBytes),
        secondaryActionLabel: LocaleKeys.split_newOperation.tr(),
        onSecondaryAction: onReset,
        tier: tier,
      );
    }

    if (currentState is SplitError) {
      return ErrorStateWidget(
        message: currentState.message,
        onRetry: onRetry,
        tier: tier,
      );
    }

    // SplitInitial: page-count/output summary + start action, matching the
    // design's `isIdle` branch. There is no settings step for Split.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          LocaleKeys.split_resultSectionTitle.tr(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.textSoftColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: Sizes.md),
        _SummaryRow(
          label: LocaleKeys.split_pageCountLabel.tr(),
          value: pageCount == null ? '—' : '$pageCount',
          highlighted: true,
        ),
        const SizedBox(height: Sizes.sm),
        _SummaryRow(
          label: LocaleKeys.split_outputLabel.tr(),
          value: pageCount == null
              ? LocaleKeys.split_outputValueUnknown.tr()
              : LocaleKeys.split_outputValue.tr(
                  namedArgs: {'count': '$pageCount'},
                ),
        ),
        const SizedBox(height: Sizes.xl),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: LocaleKeys.split_startAction.tr(),
            onPressed: onStart,
          ),
        ),
      ],
    );
  }

  String _outputZipName(String inputName) {
    final withoutExtension = inputName.toLowerCase().endsWith('.pdf')
        ? inputName.substring(0, inputName.length - 4)
        : inputName;
    return '${withoutExtension}_sayfalar.zip';
  }
}

/// One label/value row inside the idle summary, e.g. "Sayfa sayısı: 18" or
/// "Çıkış: 18 ayrı PDF (.zip)" — [highlighted] gives it the accent-soft
/// background `design/Split.dc.html` uses for the first row.
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
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.textSoftColor,
            ),
          ),
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
