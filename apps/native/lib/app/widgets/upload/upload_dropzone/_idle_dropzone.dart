part of '../upload_dropzone.dart';

/// Idle state — dashed border, icon capsule, copy and the "Dosya Seç" button.
final class _IdleDropzone extends StatelessWidget {
  const _IdleDropzone({
    required this.isCompact,
    required this.isDragging,
    required this.isEnabled,
    required this.showDragHint,
    required this.onSelectFile,
  });

  final bool isCompact;
  final bool isDragging;
  final bool isEnabled;
  final bool showDragHint;
  final Future<void> Function() onSelectFile;

  /// Matches `PrimaryButton.disabledOpacity`, so a disabled dropzone and a
  /// disabled button fade by the same amount.
  static const double _disabledOpacity = 0.55;
  static const double _dashLength = Sizes.sm;
  static const double _dashGap = Sizes.xs;
  static const double _borderWidth = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radius = Sizes.radiusButton + Sizes.xs;
    final capsuleSize = isCompact
        ? Sizes.xxl + Sizes.lg
        : Sizes.xxl + Sizes.xl;

    return Opacity(
      opacity: isEnabled ? 1 : _disabledOpacity,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: isDragging
              ? theme.colorScheme.primary
              : context.surfaceBorderColor,
          radius: radius,
          strokeWidth: _borderWidth,
          dashLength: _dashLength,
          gapLength: _dashGap,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDragging ? context.accentSoftColor : Colors.transparent,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? Sizes.lg : Sizes.xl,
              vertical: isCompact ? Sizes.xl + Sizes.xs : Sizes.xxl + Sizes.md,
            ),
            child: Column(
              children: [
                Container(
                  width: capsuleSize,
                  height: capsuleSize,
                  decoration: BoxDecoration(
                    color: context.accentSoftColor,
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  child: Icon(
                    Icons.upload_file_outlined,
                    size: Sizes.xl,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: Sizes.lg),
                Text(
                  isDragging
                      ? LocaleKeys.upload_dropzoneActive.tr()
                      : LocaleKeys.upload_dropzoneTitle.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Sizes.xs),
                Text(
                  LocaleKeys.upload_dropzoneHint.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: context.textSoftColor,
                  ),
                ),
                const SizedBox(height: Sizes.lg),
                PrimaryButton(
                  label: LocaleKeys.upload_selectFile.tr(),
                  onPressed: isEnabled ? onSelectFile : null,
                ),
                if (showDragHint) ...[
                  const SizedBox(height: Sizes.sm),
                  Text(
                    LocaleKeys.upload_orDragDrop.tr(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: context.textSoftColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
