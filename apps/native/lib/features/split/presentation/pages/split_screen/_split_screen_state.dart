part of '../split_screen.dart';

final class _SplitScreenState extends State<SplitScreen> {
  late final SplitCubit _cubit;
  late final FilePickerService _filePickerService;

  PickedPdfFile? _selectedFile;
  int? _pageCount;

  @override
  void initState() {
    super.initState();
    _cubit = AppDependency.injector.get<SplitCubit>();
    _filePickerService = AppDependency.injector.get<FilePickerService>();
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  void _onFileSelected(PickedPdfFile file) {
    _cubit.reset();
    setState(() {
      _selectedFile = file;
      _pageCount = null;
    });
    unawaited(_loadPageCount(file));
  }

  Future<void> _loadPageCount(PickedPdfFile file) async {
    final bytes = await file.readBytes();
    final count = await _cubit.readPageCount(bytes: bytes);
    if (!mounted || _selectedFile != file) return;
    setState(() => _pageCount = count);
  }

  void _onFileRemoved() {
    _cubit.reset();
    setState(() {
      _selectedFile = null;
      _pageCount = null;
    });
  }

  Future<void> _startSplit() async {
    final file = _selectedFile;
    if (file == null) return;
    final bytes = await file.readBytes();
    await _cubit.split(bytes: bytes);
  }

  void _startNewOperation() {
    _cubit.reset();
    setState(() {
      _selectedFile = null;
      _pageCount = null;
    });
  }

  String _outputFileName(String inputName) {
    final withoutExtension = inputName.toLowerCase().endsWith('.pdf')
        ? inputName.substring(0, inputName.length - 4)
        : inputName;
    return '${withoutExtension}_sayfalar.zip';
  }

  Future<void> _download(Uint8List bytes, String fileName) async {
    try {
      await _filePickerService.saveZip(fileName: fileName, bytes: bytes);
    } on FilePickerException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.split_saveFailed.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tier = context.screenTier;
    final isMobile = tier == ScreenTier.mobile;

    return BlocProvider<SplitCubit>(
      create: (_) => _cubit,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(RouteConstants.home),
          ),
          title: Text(LocaleKeys.split_pageTitle.tr()),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: isMobile ? AppInsets.all16 : AppInsets.all24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.split_pageSubtitle.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textSoftColor,
                  ),
                ),
                const SizedBox(height: Sizes.xl),
                // Desktop keeps a two-column layout (file/page grid +
                // summary/actions), matching `design/Split.dc.html`'s
                // 1fr/380px grid. Tablet/mobile stack instead of squeezing
                // that split into narrow columns — the same "stack, don't
                // squeeze" call P1-5 made for the home screen and P3A-1 made
                // for Compress.
                if (tier == ScreenTier.desktop)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: _buildUploadPanel(tier)),
                        const SizedBox(width: Sizes.xl),
                        Expanded(flex: 5, child: _buildSummaryPanel(tier)),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUploadPanel(tier),
                      const SizedBox(height: Sizes.xl),
                      _buildSummaryPanel(tier),
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

    return AppCard(
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
            enabled: _cubit.state is! SplitLoading,
          ),
          if (file != null && _pageCount != null) ...[
            const SizedBox(height: Sizes.lg),
            SplitPageGrid(pageCount: _pageCount, tier: tier),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryPanel(ScreenTier tier) {
    return AppCard(
      child: BlocBuilder<SplitCubit, SplitState>(
        bloc: _cubit,
        builder: (context, state) => _PhaseContent(
          tier: tier,
          state: state,
          selectedFile: _selectedFile,
          pageCount: _pageCount,
          onStart: _startSplit,
          onRetry: _startSplit,
          onDownload: (bytes) => unawaited(
            _download(bytes, _outputFileName(_selectedFile?.name ?? 'dosya.pdf')),
          ),
          onReset: _startNewOperation,
        ),
      ),
    );
  }
}
