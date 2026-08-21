part of '../watermark_screen.dart';

/// The settings-panel content, switched on [WatermarkState] — mirrors
/// `design/Watermark.dc.html`'s `isIdle`/`isProcessing`/`isDone` branches,
/// plus an `Error` branch the design doesn't draw but every tool screen
/// needs.
final class _PhaseContent extends StatelessWidget {
  const _PhaseContent({
    required this.tier,
    required this.state,
    required this.selectedFile,
    required this.text,
    required this.position,
    required this.opacity,
    required this.canStart,
    required this.onCyclePreset,
    required this.onTextChanged,
    required this.onPositionSelected,
    required this.onOpacitySelected,
    required this.onStart,
    required this.onRetry,
    required this.onDownload,
    required this.onReset,
  });

  final ScreenTier tier;
  final WatermarkState state;
  final PickedPdfFile? selectedFile;
  final String text;
  final WatermarkPosition position;
  final WatermarkOpacity opacity;
  final bool canStart;
  final VoidCallback onCyclePreset;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<WatermarkPosition> onPositionSelected;
  final ValueChanged<WatermarkOpacity> onOpacitySelected;
  final VoidCallback onStart;
  final VoidCallback onRetry;
  final ValueChanged<Uint8List> onDownload;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (selectedFile == null) {
      return Text(
        LocaleKeys.watermark_selectFileFirst.tr(),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: context.textSoftColor),
      );
    }

    final currentState = state;
    if (currentState is WatermarkLoading) {
      return ToolProgressIndicator(
        // `pdf_manipulator`'s `addWatermark` exposes no progress callback
        // (same as every other Phase 3A operation, per the P0-11 Decisions
        // log entry), so this is an indeterminate/simulated state.
        progress: 60,
        label: LocaleKeys.watermark_processingLabel.tr(),
        tier: tier,
      );
    }

    if (currentState is WatermarkSuccess) {
      return ResultPanel(
        message: LocaleKeys.watermark_resultMessage.tr(
          namedArgs: {
            'fileName': selectedFile!.name,
            'count': '${currentState.pageCount}',
          },
        ),
        fileName: 'watermarked.pdf',
        pageCount: currentState.pageCount,
        onDownload: () => onDownload(currentState.watermarkedBytes),
        secondaryActionLabel: LocaleKeys.watermark_newOperation.tr(),
        onSecondaryAction: onReset,
        tier: tier,
      );
    }

    if (currentState is WatermarkError) {
      return ErrorStateWidget(
        message: currentState.message,
        onRetry: onRetry,
        tier: tier,
      );
    }

    // WatermarkInitial: text/position/opacity settings + start action,
    // matching the design's `isIdle` branch.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                LocaleKeys.watermark_textLabel.tr(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.textSoftColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Sizes.sm),
            SecondaryButton(
              label: LocaleKeys.watermark_presetChange.tr(),
              onPressed: onCyclePreset,
            ),
          ],
        ),
        const SizedBox(height: Sizes.sm),
        TextField(
          controller: TextEditingController(text: text)
            ..selection = TextSelection.collapsed(offset: text.length),
          onChanged: onTextChanged,
          textCapitalization: TextCapitalization.characters,
        ),
        if (text.trim().isEmpty) ...[
          const SizedBox(height: Sizes.sm),
          Text(
            LocaleKeys.watermark_emptyTextHint.tr(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.textSoftColor,
            ),
          ),
        ],
        const SizedBox(height: Sizes.lg),
        Text(
          LocaleKeys.watermark_positionSectionTitle.tr(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.textSoftColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: Sizes.sm),
        Wrap(
          spacing: Sizes.sm,
          runSpacing: Sizes.sm,
          children: [
            for (final option in WatermarkPosition.values)
              _PresetPill(
                label: option.labelKey.tr(),
                isSelected: option == position,
                onTap: () => onPositionSelected(option),
              ),
          ],
        ),
        const SizedBox(height: Sizes.lg),
        Text(
          LocaleKeys.watermark_opacitySectionTitle.tr(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.textSoftColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: Sizes.sm),
        Wrap(
          spacing: Sizes.sm,
          runSpacing: Sizes.sm,
          children: [
            for (final option in WatermarkOpacity.values)
              _PresetPill(
                label: option.labelKey.tr(),
                isSelected: option == opacity,
                onTap: () => onOpacitySelected(option),
              ),
          ],
        ),
        const SizedBox(height: Sizes.xl),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: LocaleKeys.watermark_startAction.tr(),
            onPressed: canStart ? onStart : null,
          ),
        ),
      ],
    );
  }
}

/// One small selection pill shared by the position and opacity rows, e.g.
/// "Çapraz" or "Orta" — [isSelected] outlines it in the accent color, same
/// treatment as `QualitySelector`'s pills from Compress.
final class _PresetPill extends StatelessWidget {
  const _PresetPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
