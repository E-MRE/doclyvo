part of '../reorder_screen.dart';

/// The summary-panel content, switched on [ReorderState] and whether a file
/// (with its pages loaded) is available yet — mirrors
/// `design/Reorder.dc.html`'s `isIdle`/`isProcessing`/`isDone` branches, plus
/// an `Error` branch the design doesn't draw but every tool screen needs.
final class _PhaseContent extends StatelessWidget {
  const _PhaseContent({
    required this.tier,
    required this.state,
    required this.selectedFile,
    required this.hasPages,
    required this.order,
    required this.isReordered,
    required this.onStart,
    required this.onRetry,
    required this.onDownload,
    required this.onReset,
  });

  final ScreenTier tier;
  final ReorderState state;
  final PickedPdfFile? selectedFile;
  final bool hasPages;
  final List<int> order;
  final bool isReordered;
  final VoidCallback onStart;
  final VoidCallback onRetry;
  final ValueChanged<Uint8List> onDownload;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (selectedFile == null) {
      return Text(
        LocaleKeys.reorder_selectFileFirst.tr(),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: context.textSoftColor),
      );
    }

    final currentState = state;
    if (currentState is ReorderLoading) {
      return ToolProgressIndicator(
        // `pdf_manipulator`'s `reorderPages` exposes no progress callback
        // (same as `rotatePages`/`merge`/`split`/`compress`, per the P0-11
        // Decisions log entry), so this is an indeterminate/simulated state.
        progress: 60,
        label: LocaleKeys.reorder_processingLabel.tr(),
        tier: tier,
      );
    }

    if (currentState is ReorderSuccess) {
      return ResultPanel(
        message: LocaleKeys.reorder_resultMessage.tr(
          namedArgs: {'fileName': selectedFile!.name},
        ),
        fileName: 'reordered.pdf',
        pageCount: currentState.pageCount,
        onDownload: () => onDownload(currentState.reorderedBytes),
        secondaryActionLabel: LocaleKeys.reorder_newOperation.tr(),
        onSecondaryAction: onReset,
        tier: tier,
      );
    }

    if (currentState is ReorderError) {
      return ErrorStateWidget(
        message: currentState.message,
        onRetry: onRetry,
        tier: tier,
      );
    }

    if (!hasPages) {
      return Text(
        LocaleKeys.reorder_loadingPages.tr(),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: context.textSoftColor),
      );
    }

    // ReorderInitial with pages loaded: order summary + start action,
    // matching the design's `isIdle` branch.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          LocaleKeys.reorder_resultSectionTitle.tr(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.textSoftColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: Sizes.md),
        Text(
          LocaleKeys.reorder_orderSummary.tr(
            namedArgs: {'order': order.join(' → ')},
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: Sizes.xl),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: LocaleKeys.reorder_startAction.tr(),
            onPressed: isReordered ? onStart : null,
          ),
        ),
      ],
    );
  }
}
