part of '../rotate_screen.dart';

final class _RotateScreenState extends State<RotateScreen> {
  late final RotateCubit _cubit;
  late final FilePickerService _filePickerService;

  PickedPdfFile? _selectedFile;
  List<RotatePageEntry> _pages = [];
  RotateAngle _angle = RotateAngle.clockwise90;
  StreamSubscription<PdfPageThumbnail>? _thumbnailSubscription;

  @override
  void initState() {
    super.initState();
    _cubit = AppDependency.injector.get<RotateCubit>();
    _filePickerService = AppDependency.injector.get<FilePickerService>();
  }

  @override
  void dispose() {
    unawaited(_thumbnailSubscription?.cancel());
    unawaited(_cubit.close());
    super.dispose();
  }

  int get _selectedCount => _pages.where((e) => e.selected).length;

  bool get _canRotate => _selectedCount > 0 && _cubit.state is! RotateLoading;

  void _onFileSelected(PickedPdfFile file) {
    _cubit.reset();
    unawaited(_thumbnailSubscription?.cancel());
    setState(() {
      _selectedFile = file;
      _pages = [];
    });
    unawaited(_loadPages(file));
  }

  Future<void> _loadPages(PickedPdfFile file) async {
    final bytes = await file.readBytes();
    final count = await _cubit.readPageCount(bytes: bytes);
    if (!mounted || _selectedFile != file || count == null) return;

    setState(() {
      _pages = [
        for (var i = 0; i < count; i++) RotatePageEntry(pageIndex: i),
      ];
    });

    _thumbnailSubscription = _cubit
        .renderThumbnails(bytes: bytes)
        .listen(
          (thumbnail) {
            if (!mounted || _selectedFile != file) return;
            final index = _pages.indexWhere(
              (e) => e.pageIndex == thumbnail.pageIndex,
            );
            if (index == -1) return;
            setState(() {
              _pages = [..._pages]
                ..[index] = _pages[index].copyWith(thumbnail: thumbnail);
            });
          },
          onError: (Object _) {
            // Previews just stay blank placeholders; the grid still works by
            // page number alone.
          },
        );
  }

  void _onFileRemoved() {
    _cubit.reset();
    unawaited(_thumbnailSubscription?.cancel());
    setState(() {
      _selectedFile = null;
      _pages = [];
    });
  }

  void _toggleEntry(int index) {
    setState(() {
      _pages = [..._pages]
        ..[index] = _pages[index].copyWith(
          selected: !_pages[index].selected,
        );
    });
  }

  void _toggleAll(bool selected) {
    setState(() {
      _pages = [
        for (final entry in _pages) entry.copyWith(selected: selected),
      ];
    });
  }

  void _onAngleSelected(RotateAngle angle) {
    setState(() => _angle = angle);
  }

  Future<void> _startRotate() async {
    final file = _selectedFile;
    if (file == null || !_canRotate) return;
    final bytes = await file.readBytes();
    final selectedIndexes = _pages
        .where((e) => e.selected)
        .map((e) => e.pageIndex);
    final pageRotations = {
      for (final index in selectedIndexes) index: _angle.degrees,
    };
    await _cubit.rotate(
      bytes: bytes,
      pageRotations: pageRotations,
      pageCount: _pages.length,
      rotatedPageCount: pageRotations.length,
    );
  }

  void _startNewOperation() {
    _cubit.reset();
    unawaited(_thumbnailSubscription?.cancel());
    setState(() {
      _selectedFile = null;
      _pages = [];
    });
  }

  String _outputFileName(String inputName) {
    final withoutExtension = inputName.toLowerCase().endsWith('.pdf')
        ? inputName.substring(0, inputName.length - 4)
        : inputName;
    return '${withoutExtension}_donduruldu.pdf';
  }

  Future<void> _download(Uint8List bytes, String fileName) async {
    try {
      await _filePickerService.savePdf(fileName: fileName, bytes: bytes);
    } on FilePickerException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.rotate_saveFailed.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tier = context.screenTier;
    final isMobile = tier == ScreenTier.mobile;

    return BlocProvider<RotateCubit>(
      create: (_) => _cubit,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(RouteConstants.home),
          ),
          title: Text(LocaleKeys.rotate_pageTitle.tr()),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: isMobile ? AppInsets.all16 : AppInsets.all24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.rotate_pageSubtitle.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textSoftColor,
                  ),
                ),
                const SizedBox(height: Sizes.xl),
                // Desktop keeps a two-column layout (page grid + settings),
                // matching `design/Rotate.dc.html`'s 1fr/380px grid.
                // Tablet/mobile stack instead of squeezing that split into
                // narrow columns — the same "stack, don't squeeze" call
                // P1-5/P3A-1..3 already made.
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
    return BlocBuilder<RotateCubit, RotateState>(
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
              enabled: state is! RotateLoading,
            ),
            if (file != null && _pages.isNotEmpty) ...[
              const SizedBox(height: Sizes.lg),
              RotatePageGrid(
                entries: _pages,
                angle: _angle,
                onToggleEntry: _toggleEntry,
                onToggleAll: _toggleAll,
                tier: tier,
                enabled: state is! RotateLoading,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel(ScreenTier tier) {
    return AppCard(
      child: BlocBuilder<RotateCubit, RotateState>(
        bloc: _cubit,
        builder: (context, state) => _PhaseContent(
          tier: tier,
          state: state,
          selectedFile: _selectedFile,
          hasPages: _pages.isNotEmpty,
          angle: _angle,
          selectedCount: _selectedCount,
          canRotate: _canRotate,
          onAngleSelected: _onAngleSelected,
          onStart: _startRotate,
          onRetry: _startRotate,
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
