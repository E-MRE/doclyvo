part of '../watermark_screen.dart';

final class _WatermarkScreenState extends State<WatermarkScreen> {
  static const List<String> _presetTexts = ['TASLAK', 'GİZLİ', 'ÖRNEK'];

  late final WatermarkCubit _cubit;
  late final FilePickerService _filePickerService;

  PickedPdfFile? _selectedFile;
  int? _pageCount;
  PdfPageThumbnail? _previewThumbnail;
  String _text = _presetTexts.first;
  int _presetIndex = 0;
  WatermarkPosition _position = WatermarkPosition.diagonal;
  WatermarkOpacity _opacity = WatermarkOpacity.medium;

  @override
  void initState() {
    super.initState();
    _cubit = AppDependency.injector.get<WatermarkCubit>();
    _filePickerService = AppDependency.injector.get<FilePickerService>();
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  bool get _canStart =>
      _text.trim().isNotEmpty && _cubit.state is! WatermarkLoading;

  void _onFileSelected(PickedPdfFile file) {
    _cubit.reset();
    setState(() {
      _selectedFile = file;
      _pageCount = null;
      _previewThumbnail = null;
    });
    unawaited(_loadFileMetadata(file));
  }

  Future<void> _loadFileMetadata(PickedPdfFile file) async {
    final bytes = await file.readBytes();
    final results = await Future.wait([
      _cubit.readPageCount(bytes: bytes),
      _cubit.renderFirstPageThumbnail(bytes: bytes),
    ]);
    if (!mounted || _selectedFile != file) return;
    setState(() {
      _pageCount = results[0] as int?;
      _previewThumbnail = results[1] as PdfPageThumbnail?;
    });
  }

  void _onFileRemoved() {
    _cubit.reset();
    setState(() {
      _selectedFile = null;
      _pageCount = null;
      _previewThumbnail = null;
    });
  }

  void _cyclePreset() {
    setState(() {
      _presetIndex = (_presetIndex + 1) % _presetTexts.length;
      _text = _presetTexts[_presetIndex];
    });
  }

  void _onTextChanged(String value) {
    setState(() => _text = value);
  }

  void _onPositionSelected(WatermarkPosition position) {
    setState(() => _position = position);
  }

  void _onOpacitySelected(WatermarkOpacity opacity) {
    setState(() => _opacity = opacity);
  }

  Future<void> _startWatermark() async {
    final file = _selectedFile;
    if (file == null || !_canStart) return;
    final bytes = await file.readBytes();
    final options = PdfWatermarkOptions(
      text: _text.trim(),
      placement: _position.placement,
      rotation: _position.rotation,
      opacity: _opacity.value,
    );
    await _cubit.addWatermark(
      bytes: bytes,
      options: options,
      pageCount: _pageCount ?? 0,
    );
  }

  void _startNewOperation() {
    _cubit.reset();
    setState(() {
      _selectedFile = null;
      _pageCount = null;
      _previewThumbnail = null;
    });
  }

  String _outputFileName(String inputName) {
    final withoutExtension = inputName.toLowerCase().endsWith('.pdf')
        ? inputName.substring(0, inputName.length - 4)
        : inputName;
    return '${withoutExtension}_filigranli.pdf';
  }

  Future<void> _download(Uint8List bytes, String fileName) async {
    try {
      await _filePickerService.savePdf(fileName: fileName, bytes: bytes);
    } on FilePickerException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.watermark_saveFailed.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tier = context.screenTier;
    final isMobile = tier == ScreenTier.mobile;

    return BlocProvider<WatermarkCubit>(
      create: (_) => _cubit,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(RouteConstants.home),
          ),
          title: Text(LocaleKeys.watermark_pageTitle.tr()),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: isMobile ? AppInsets.all16 : AppInsets.all24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.watermark_pageSubtitle.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textSoftColor,
                  ),
                ),
                const SizedBox(height: Sizes.xl),
                // Desktop keeps a two-column layout (upload + preview,
                // settings), matching `design/Watermark.dc.html`'s
                // 1fr/380px grid. Tablet/mobile stack instead of squeezing
                // that split into narrow columns — the same "stack, don't
                // squeeze" call P1-5/P3A-1..5 already made.
                if (tier == ScreenTier.desktop)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: _buildUploadPanel(tier)),
                        const SizedBox(width: Sizes.xl),
                        Expanded(flex: 5, child: _buildSettingsPanel(tier)),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUploadPanel(tier),
                      const SizedBox(height: Sizes.xl),
                      _buildSettingsPanel(tier),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadPanel(ScreenTier tier) {
    final file = _selectedFile;

    // One BlocBuilder around the whole panel: the `enabled` flag below is
    // state-derived, and reading `_cubit.state` outside a builder leaves it
    // stale for the whole operation — the panel only rebuilds on setState,
    // which a cubit emission does not trigger.
    return BlocBuilder<WatermarkCubit, WatermarkState>(
      bloc: _cubit,
      builder: (context, state) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            UploadDropzone(
              filePickerService: _filePickerService,
              selectedFile: file,
              onFileSelected: _onFileSelected,
              onFileRemoved: _onFileRemoved,
              tier: tier,
              enabled: state is! WatermarkLoading,
            ),
            if (file != null) ...[
              const SizedBox(height: Sizes.lg),
              WatermarkPreview(
                text: _text,
                position: _position,
                opacity: _opacity,
                pageThumbnail: _previewThumbnail,
                tier: tier,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel(ScreenTier tier) {
    return AppCard(
      child: BlocBuilder<WatermarkCubit, WatermarkState>(
        bloc: _cubit,
        builder: (context, state) => _PhaseContent(
          tier: tier,
          state: state,
          selectedFile: _selectedFile,
          text: _text,
          position: _position,
          opacity: _opacity,
          canStart: _canStart,
          onCyclePreset: _cyclePreset,
          onTextChanged: _onTextChanged,
          onPositionSelected: _onPositionSelected,
          onOpacitySelected: _onOpacitySelected,
          onStart: _startWatermark,
          onRetry: _startWatermark,
          onDownload: (bytes) => unawaited(
            _download(
              bytes,
              _outputFileName(_selectedFile?.name ?? 'dosya.pdf'),
            ),
          ),
          onReset: _startNewOperation,
        ),
      ),
    );
  }
}
