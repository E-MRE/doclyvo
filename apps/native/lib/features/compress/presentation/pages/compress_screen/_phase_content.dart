part of '../compress_screen.dart';

/// The settings-panel content, switched on [CompressState] and whether a
/// file has been picked yet — mirrors `design/Compress.dc.html`'s
/// `isIdle`/`isProcessing`/`isDone` branches, plus an `Error` branch the
/// design doesn't draw but every tool screen needs.
final class _PhaseContent extends StatelessWidget {
  const _PhaseContent({
    required this.tier,
    required this.state,
    required this.selectedFile,
    required this.quality,
    required this.progress,
    required this.onQualitySelected,
    required this.onStart,
    required this.onRetry,
    required this.onDownload,
    required this.onReset,
    required this.outputFileNameOf,
  });

  final ScreenTier tier;
  final CompressState state;
  final PickedPdfFile? selectedFile;
  final CompressQuality quality;
  final double progress;
  final ValueChanged<CompressQuality> onQualitySelected;
  final VoidCallback onStart;
  final VoidCallback onRetry;
  final ValueChanged<Uint8List> onDownload;
  final VoidCallback onReset;
  final String Function(String inputName) outputFileNameOf;

  @override
  Widget build(BuildContext context) {
    final file = selectedFile;

    if (file == null) {
      return Text(
        LocaleKeys.compress_selectFileFirst.tr(),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: context.textSoftColor),
      );
    }

    final currentState = state;
    if (currentState is CompressLoading) {
      return ToolProgressIndicator(
        progress: progress,
        label: LocaleKeys.compress_processingLabel.tr(),
        tier: tier,
      );
    }

    if (currentState is CompressSuccess) {
      final outputName = outputFileNameOf(file.name);
      return ResultPanel(
        message: LocaleKeys.compress_resultMessage.tr(
          namedArgs: {'fileName': file.name},
        ),
        fileName: outputName,
        beforeSizeInBytes: currentState.originalSizeInBytes,
        afterSizeInBytes: currentState.compressedSizeInBytes,
        onDownload: () => onDownload(currentState.compressedBytes),
        secondaryActionLabel: LocaleKeys.compress_newOperation.tr(),
        onSecondaryAction: onReset,
        tier: tier,
      );
    }

    if (currentState is CompressError) {
      return ErrorStateWidget(
        message: currentState.message,
        onRetry: onRetry,
        tier: tier,
      );
    }

    // CompressInitial: quality picker + start action, matching the design's
    // `isIdle` branch.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        QualitySelector(selected: quality, onSelected: onQualitySelected),
        const SizedBox(height: Sizes.xl),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: LocaleKeys.compress_startAction.tr(),
            onPressed: onStart,
          ),
        ),
      ],
    );
  }
}
