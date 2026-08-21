part of '../rotate_screen.dart';

/// The settings-panel content, switched on [RotateState] and whether a file
/// (with its pages loaded) is available yet — mirrors `design/Rotate.dc.html`'s
/// `isIdle`/`isProcessing`/`isDone` branches, plus an `Error` branch the
/// design doesn't draw but every tool screen needs.
final class _PhaseContent extends StatelessWidget {
  const _PhaseContent({
    required this.tier,
    required this.state,
    required this.selectedFile,
    required this.hasPages,
    required this.angle,
    required this.selectedCount,
    required this.canRotate,
    required this.onAngleSelected,
    required this.onStart,
    required this.onRetry,
    required this.onDownload,
    required this.onReset,
  });

  final ScreenTier tier;
  final RotateState state;
  final PickedPdfFile? selectedFile;
  final bool hasPages;
  final RotateAngle angle;
  final int selectedCount;
  final bool canRotate;
  final ValueChanged<RotateAngle> onAngleSelected;
  final VoidCallback onStart;
  final VoidCallback onRetry;
  final ValueChanged<Uint8List> onDownload;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (selectedFile == null) {
      return Text(
        LocaleKeys.rotate_selectFileFirst.tr(),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: context.textSoftColor),
      );
    }

    final currentState = state;
    if (currentState is RotateLoading) {
      return ToolProgressIndicator(
        // `pdf_manipulator`'s `rotatePages` exposes no progress callback
        // (same as `merge`/`split`/`compress`, per the P0-11 Decisions log
        // entry), so this is an indeterminate/simulated state.
        progress: 60,
        label: LocaleKeys.rotate_processingLabel.tr(),
        tier: tier,
      );
    }

    if (currentState is RotateSuccess) {
      return ResultPanel(
        message: LocaleKeys.rotate_resultMessage.tr(
          namedArgs: {'fileName': selectedFile!.name},
        ),
        fileName: 'rotated.pdf',
        pageCount: currentState.pageCount,
        onDownload: () => onDownload(currentState.rotatedBytes),
        secondaryActionLabel: LocaleKeys.rotate_newOperation.tr(),
        onSecondaryAction: onReset,
        tier: tier,
      );
    }

    if (currentState is RotateError) {
      return ErrorStateWidget(
        message: currentState.message,
        onRetry: onRetry,
        tier: tier,
      );
    }

    if (!hasPages) {
      return Text(
        LocaleKeys.rotate_loadingPages.tr(),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: context.textSoftColor),
      );
    }

    // RotateInitial with pages loaded: angle pills + selection summary +
    // start action, matching the design's `isIdle` branch.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in RotateAngle.values) ...[
          _AnglePill(
            angle: option,
            isSelected: option == angle,
            onTap: () => onAngleSelected(option),
          ),
          if (option != RotateAngle.values.last)
            const SizedBox(height: Sizes.sm),
        ],
        const SizedBox(height: Sizes.lg),
        Text(
          LocaleKeys.rotate_selectionSummary.tr(
            namedArgs: {
              'count': '$selectedCount',
              'angle': '${angle.degrees}°',
            },
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.textSoftColor,
          ),
        ),
        if (selectedCount == 0) ...[
          const SizedBox(height: Sizes.sm),
          Text(
            LocaleKeys.rotate_noSelectionHint.tr(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.textSoftColor,
            ),
          ),
        ],
        const SizedBox(height: Sizes.xl),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: LocaleKeys.rotate_startAction.tr(),
            onPressed: canRotate ? onStart : null,
          ),
        ),
      ],
    );
  }
}

/// One rotation-direction pill, e.g. "90° sağa döndür · Saat yönünde" —
/// [isSelected] outlines it in the accent color, matching `QualitySelector`'s
/// pill treatment from Compress.
final class _AnglePill extends StatelessWidget {
  const _AnglePill({
    required this.angle,
    required this.isSelected,
    required this.onTap,
  });

  final RotateAngle angle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              angle.labelKey.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              angle.hintKey.tr(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: context.textSoftColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
