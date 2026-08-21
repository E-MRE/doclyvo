import 'package:desktop_drop/desktop_drop.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/app/widgets/buttons/primary_button.dart';
import 'package:doclyvo/core/error/file_picker_exception.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/core/widgets/upload/file_picker_service.dart';
import 'package:doclyvo/core/widgets/upload/models/picked_pdf_file.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The shared upload surface every tool starts from.
///
/// Two states, straight from `design/Main.dc.html` / `design/MobileHome.dc.html`:
/// an *idle* dashed dropzone with a "Dosya Seç" button, and a *selected* tile
/// showing the file name, its size and a remove button.
///
/// The widget is **controlled**: the caller (a tool cubit, in Phase 3) owns
/// [selectedFile] and reacts to [onFileSelected]/[onFileRemoved]. Only the
/// transient drag-hover and validation-error bits live in local state, so the
/// same instance can be driven from any tool's state machine.
///
/// Drag-drop is wired up on desktop only — on iOS/Android the drop channel does
/// not exist and the file-picker dialog is the single entry point.
final class UploadDropzone extends StatefulWidget {
  const UploadDropzone({
    required this.filePickerService,
    required this.onFileSelected,
    this.selectedFile,
    this.onFileRemoved,
    this.isCompact = false,
    this.enabled = true,
    super.key,
  });

  /// Comes from `AppDependency.injector` at the feature edge — `core/` never
  /// reaches up into `app/` to resolve it itself.
  final FilePickerService filePickerService;

  /// Called with a validated PDF whenever the user picks or drops one.
  final ValueChanged<PickedPdfFile> onFileSelected;

  /// The file currently held by the caller, or `null` for the idle state.
  final PickedPdfFile? selectedFile;

  /// Called when the user taps the remove button on the selected tile.
  final VoidCallback? onFileRemoved;

  /// Tighter paddings and a smaller icon capsule, for mobile layouts.
  final bool isCompact;

  /// When `false`, picking and dropping are both ignored (e.g. while a tool is
  /// processing).
  final bool enabled;

  @override
  State<UploadDropzone> createState() => _UploadDropzoneState();
}

final class _UploadDropzoneState extends State<UploadDropzone> {
  static const Set<TargetPlatform> _desktopPlatforms = {
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
  };

  bool _isDragging = false;
  FilePickerErrorKind? _errorKind;

  bool get _supportsDragDrop => _desktopPlatforms.contains(defaultTargetPlatform);

  bool get _isInteractive => widget.enabled;

  @override
  void didUpdateWidget(UploadDropzone oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A successful selection from the caller clears any stale rejection notice.
    if (widget.selectedFile != null && _errorKind != null) {
      _errorKind = null;
    }
  }

  Future<void> _pickFile() async {
    await _select(
      () => widget.filePickerService.pickPdf(
        dialogTitle: LocaleKeys.upload_selectFile.tr(),
      ),
    );
  }

  Future<void> _onDragDone(DropDoneDetails details) async {
    if (!_isInteractive || details.files.isEmpty) return;
    final droppedPath = details.files.first.path;
    await _select(
      () => widget.filePickerService.resolveDroppedPath(droppedPath),
    );
  }

  /// Runs a selection attempt and funnels its outcome into either the caller's
  /// [UploadDropzone.onFileSelected] or a locally rendered error message.
  Future<void> _select(Future<PickedPdfFile?> Function() attempt) async {
    if (!_isInteractive) return;
    setState(() {
      _isDragging = false;
      _errorKind = null;
    });

    try {
      final file = await attempt();
      if (!mounted || file == null) return;
      widget.onFileSelected(file);
    } on FilePickerException catch (error) {
      if (!mounted) return;
      setState(() => _errorKind = error.kind);
    }
  }

  void _setDragging({required bool dragging}) {
    if (!_isInteractive || _isDragging == dragging) return;
    setState(() => _isDragging = dragging);
  }

  String get _errorMessage => switch (_errorKind) {
    FilePickerErrorKind.notPdf => LocaleKeys.upload_selectPdf.tr(),
    FilePickerErrorKind.unreadable => LocaleKeys.upload_readFailed.tr(),
    FilePickerErrorKind.pickerFailure => LocaleKeys.error_unknownError.tr(),
    null => '',
  };

  @override
  Widget build(BuildContext context) {
    final selectedFile = widget.selectedFile;

    final surface = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectedFile == null)
          _IdleDropzone(
            isCompact: widget.isCompact,
            isDragging: _isDragging,
            isEnabled: _isInteractive,
            showDragHint: _supportsDragDrop,
            onSelectFile: _pickFile,
          )
        else
          _SelectedFileTile(
            file: selectedFile,
            onRemove: _isInteractive ? widget.onFileRemoved : null,
          ),
        if (_errorKind != null) _RejectionNotice(message: _errorMessage),
      ],
    );

    if (!_supportsDragDrop) return surface;

    return DropTarget(
      enable: _isInteractive,
      onDragEntered: (_) => _setDragging(dragging: true),
      onDragExited: (_) => _setDragging(dragging: false),
      onDragDone: _onDragDone,
      child: surface,
    );
  }
}

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

/// Selected state — accent-soft tile with the file name, size and a remove
/// button, mirroring the `hasFile` branch of `design/MobileHome.dc.html`.
final class _SelectedFileTile extends StatelessWidget {
  const _SelectedFileTile({required this.file, required this.onRemove});

  final PickedPdfFile file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const iconSize = Sizes.xxl + Sizes.xs;

    return Container(
      padding: AppInsets.all16,
      decoration: BoxDecoration(
        color: context.accentSoftColor,
        borderRadius: BorderRadius.circular(Sizes.radiusButton),
      ),
      child: Row(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(Sizes.radiusSmall),
            ),
            child: Icon(
              Icons.picture_as_pdf_outlined,
              size: Sizes.lg,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: Sizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Sizes.xs),
                Text(
                  file.formattedSize,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: context.textSoftColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Sizes.sm),
          IconButton(
            onPressed: onRemove,
            tooltip: LocaleKeys.upload_remove.tr(),
            icon: Icon(
              Icons.close_rounded,
              size: Sizes.lg,
              color: context.textSoftColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline validation message shown when a selection is refused.
final class _RejectionNotice extends StatelessWidget {
  const _RejectionNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppInsets.onlyTop8,
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: Sizes.lg,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: Sizes.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the dashed rounded rectangle Flutter's `Border` cannot express.
final class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(strokeWidth / 2),
      );

    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength;
}
