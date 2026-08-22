part of '../sign_screen.dart';

final class _PhaseContent extends StatelessWidget {
  const _PhaseContent({
    required this.tier,
    required this.state,
    required this.selectedFile,
    required this.mode,
    required this.strokes,
    required this.typedNameController,
    required this.uploadedImage,
    required this.canPlace,
    required this.canStart,
    required this.onModeSelected,
    required this.onStrokesChanged,
    required this.onClearStrokes,
    required this.onTypedNameChanged,
    required this.onPickImage,
    required this.onPlace,
    required this.onStart,
    required this.onRetry,
    required this.onDownload,
    required this.onReset,
  });

  final ScreenTier tier;
  final SignState state;
  final PickedPdfFile? selectedFile;
  final SignatureMode mode;
  final List<List<Offset>> strokes;
  final TextEditingController typedNameController;
  final PickedImageFile? uploadedImage;
  final bool canPlace;
  final bool canStart;
  final ValueChanged<SignatureMode> onModeSelected;
  final void Function(List<List<Offset>> strokes, Size canvasSize)
  onStrokesChanged;
  final VoidCallback onClearStrokes;
  final ValueChanged<String> onTypedNameChanged;
  final VoidCallback onPickImage;
  final VoidCallback onPlace;
  final VoidCallback onStart;
  final VoidCallback onRetry;
  final ValueChanged<Uint8List> onDownload;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = selectedFile;

    if (file == null) {
      return Text(
        LocaleKeys.sign_selectFileFirst.tr(),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: context.textSoftColor,
        ),
      );
    }

    final currentState = state;
    if (currentState is SignLoading) {
      return ToolProgressIndicator(
        // `pdf_manipulator`'s stamping call exposes no progress callback (same
        // as every other Phase 3A operation, per the P0-11 Decisions log
        // entry), so this is an indeterminate/simulated state.
        progress: 60,
        label: LocaleKeys.sign_processingLabel.tr(),
        tier: tier,
      );
    }

    if (currentState is SignSuccess) {
      return ResultPanel(
        message: LocaleKeys.sign_resultMessage.tr(
          namedArgs: {
            'fileName': file.name,
            'page': '${currentState.signedPageNumber}',
          },
        ),
        fileName: 'signed.pdf',
        pageCount: currentState.pageCount,
        onDownload: () => onDownload(currentState.signedBytes),
        secondaryActionLabel: LocaleKeys.sign_newOperation.tr(),
        onSecondaryAction: onReset,
        tier: tier,
      );
    }

    if (currentState is SignError) {
      return ErrorStateWidget(
        message: currentState.message,
        onRetry: onRetry,
        tier: tier,
      );
    }

    // SignInitial: the design's `isIdle` branch — mode tabs, the mode's own
    // input, "Belgeye Yerleştir", then "İmzala".
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SignatureModeTabs(selected: mode, onModeSelected: onModeSelected),
        const SizedBox(height: Sizes.lg),
        _buildModeInput(context),
        const SizedBox(height: Sizes.lg),
        SizedBox(
          width: double.infinity,
          child: SecondaryButton(
            label: LocaleKeys.sign_placeAction.tr(),
            onPressed: canPlace ? onPlace : null,
          ),
        ),
        const SizedBox(height: Sizes.xl),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: LocaleKeys.sign_startAction.tr(),
            onPressed: canStart ? onStart : null,
          ),
        ),
      ],
    );
  }

  Widget _buildModeInput(BuildContext context) {
    final theme = Theme.of(context);
    final hintStyle = theme.textTheme.labelMedium?.copyWith(
      color: context.textSoftColor,
    );

    return switch (mode) {
      SignatureMode.draw => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SignaturePad(
            strokes: strokes,
            onStrokesChanged: onStrokesChanged,
            tier: tier,
          ),
          const SizedBox(height: Sizes.sm),
          Row(
            children: [
              Expanded(
                child: Text(LocaleKeys.sign_drawHint.tr(), style: hintStyle),
              ),
              const SizedBox(width: Sizes.sm),
              // Not in the design, but a pad with no way back from a bad
              // stroke is unusable on a touch screen.
              TextButton(
                onPressed: strokes.isEmpty ? null : onClearStrokes,
                child: Text(LocaleKeys.sign_drawClear.tr()),
              ),
            ],
          ),
        ],
      ),
      SignatureMode.type => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: typedNameController,
            onChanged: onTypedNameChanged,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.words,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: LocaleKeys.sign_typeFieldHint.tr(),
            ),
          ),
          const SizedBox(height: Sizes.sm),
          Text(LocaleKeys.sign_typeHint.tr(), style: hintStyle),
        ],
      ),
      SignatureMode.upload => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              label: LocaleKeys.sign_uploadAction.tr(),
              onPressed: onPickImage,
            ),
          ),
          const SizedBox(height: Sizes.sm),
          Text(
            uploadedImage == null
                ? LocaleKeys.sign_uploadHint.tr()
                : LocaleKeys.sign_uploadSelected.tr(
                    namedArgs: {'fileName': uploadedImage!.name},
                  ),
            style: hintStyle,
          ),
        ],
      ),
    };
  }
}
