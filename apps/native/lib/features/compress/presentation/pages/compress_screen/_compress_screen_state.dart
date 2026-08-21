part of '../compress_screen.dart';

final class _CompressScreenState extends State<CompressScreen> {
  late final CompressCubit _cubit;
  late final FilePickerService _filePickerService;
  late final _FakeProgressTicker _progressTicker;

  PickedPdfFile? _selectedFile;
  CompressQuality _quality = CompressQuality.recommended;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _cubit = AppDependency.injector.get<CompressCubit>();
    _filePickerService = AppDependency.injector.get<FilePickerService>();
    _progressTicker = _FakeProgressTicker(
      onTick: (value) {
        if (!mounted) return;
        setState(() => _progress = value);
      },
    );
  }

  @override
  void dispose() {
    _progressTicker.dispose();
    unawaited(_cubit.close());
    super.dispose();
  }

  void _onFileSelected(PickedPdfFile file) {
    _cubit.reset();
    setState(() => _selectedFile = file);
  }

  void _onFileRemoved() {
    _cubit.reset();
    setState(() => _selectedFile = null);
  }

  Future<void> _startCompress() async {
    final file = _selectedFile;
    if (file == null) return;
    final bytes = await file.readBytes();
    await _cubit.compress(bytes: bytes, quality: _quality);
  }

  void _startNewOperation() {
    _cubit.reset();
    setState(() => _selectedFile = null);
  }

  String _outputFileName(String inputName) {
    final withoutExtension = inputName.toLowerCase().endsWith('.pdf')
        ? inputName.substring(0, inputName.length - 4)
        : inputName;
    return '${withoutExtension}_sikistirilmis.pdf';
  }

  Future<void> _download(Uint8List bytes, String fileName) async {
    try {
      await _filePickerService.savePdf(fileName: fileName, bytes: bytes);
    } on FilePickerException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.compress_saveFailed.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tier = context.screenTier;
    final isMobile = tier == ScreenTier.mobile;

    return BlocProvider<CompressCubit>(
      create: (_) => _cubit,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(RouteConstants.home),
          ),
          title: Text(LocaleKeys.compress_pageTitle.tr()),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: isMobile ? AppInsets.all16 : AppInsets.all24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.compress_pageSubtitle.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textSoftColor,
                  ),
                ),
                const SizedBox(height: Sizes.xl),
                // Desktop keeps a two-column layout (upload surface + settings
                // panel), matching `design/Compress.dc.html`'s 1fr/380px grid.
                // Tablet/mobile stack instead of squeezing that split into
                // ~320-490px columns — the same "stack, don't squeeze" call
                // P1-5 made for the home screen's hero/upload split.
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
    return UploadDropzone(
      filePickerService: _filePickerService,
      selectedFile: _selectedFile,
      onFileSelected: _onFileSelected,
      onFileRemoved: _onFileRemoved,
      tier: tier,
      enabled: _cubit.state is! CompressLoading,
    );
  }

  Widget _buildSettingsPanel(ScreenTier tier) {
    return AppCard(
      child: BlocConsumer<CompressCubit, CompressState>(
        bloc: _cubit,
        listener: (context, state) {
          if (state is CompressLoading) {
            _progressTicker.start();
          } else {
            _progressTicker.stop();
            if (state is CompressSuccess) {
              setState(() => _progress = 100);
            }
          }
        },
        builder: (context, state) => _PhaseContent(
          tier: tier,
          state: state,
          selectedFile: _selectedFile,
          quality: _quality,
          progress: _progress,
          onQualitySelected: (quality) => setState(() => _quality = quality),
          onStart: _startCompress,
          onRetry: _startCompress,
          onDownload: (bytes) => unawaited(
            _download(bytes, _outputFileName(_selectedFile?.name ?? 'dosya.pdf')),
          ),
          onReset: _startNewOperation,
          outputFileNameOf: _outputFileName,
        ),
      ),
    );
  }
}
