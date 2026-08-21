part of '../upload_dropzone.dart';

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
            isCompact: widget.tier == ScreenTier.mobile,
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
