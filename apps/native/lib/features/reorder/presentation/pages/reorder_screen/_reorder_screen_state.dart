part of '../reorder_screen.dart';

final class _ReorderScreenState extends State<ReorderScreen> {
  late final ReorderCubit _cubit;
  late final FilePickerService _filePickerService;

  PickedPdfFile? _selectedFile;
  List<ReorderPageEntry> _pages = [];
  StreamSubscription<PdfPageThumbnail>? _thumbnailSubscription;

  @override
  void initState() {
    super.initState();
    _cubit = AppDependency.injector.get<ReorderCubit>();
    _filePickerService = AppDependency.injector.get<FilePickerService>();
  }

  @override
  void dispose() {
    unawaited(_thumbnailSubscription?.cancel());
    unawaited(_cubit.close());
    super.dispose();
  }

  bool get _isReordered =>
      _pages.asMap().entries.any((e) => e.value.pageIndex != e.key);

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
        for (var i = 0; i < count; i++) ReorderPageEntry(pageIndex: i),
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
                ..[index] = _pages[index].copyWithThumbnail(thumbnail);
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

  void _moveLeft(int index) {
    if (index <= 0) return;
    setState(() {
      final entries = [..._pages];
      final entry = entries.removeAt(index);
      entries.insert(index - 1, entry);
      _pages = entries;
    });
  }

  void _moveRight(int index) {
    if (index >= _pages.length - 1) return;
    setState(() {
      final entries = [..._pages];
      final entry = entries.removeAt(index);
      entries.insert(index + 1, entry);
      _pages = entries;
    });
  }

  Future<void> _startReorder() async {
    final file = _selectedFile;
    if (file == null || _pages.isEmpty) return;
    final bytes = await file.readBytes();
    final pageOrder = _pages.map((e) => e.pageIndex).toList();
    await _cubit.reorder(
      bytes: bytes,
      pageOrder: pageOrder,
      pageCount: _pages.length,
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
    return '${withoutExtension}_yeniden_siralandi.pdf';
  }

  Future<void> _download(Uint8List bytes, String fileName) async {
    try {
      await _filePickerService.savePdf(fileName: fileName, bytes: bytes);
    } on FilePickerException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.reorder_saveFailed.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tier = context.screenTier;
    final isMobile = tier == ScreenTier.mobile;

    return BlocProvider<ReorderCubit>(
      create: (_) => _cubit,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(RouteConstants.home),
          ),
          title: Text(LocaleKeys.reorder_pageTitle.tr()),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: isMobile ? AppInsets.all16 : AppInsets.all24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.reorder_pageSubtitle.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textSoftColor,
                  ),
                ),
                const SizedBox(height: Sizes.xl),
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

    // One BlocBuilder around the whole panel: the `enabled` flag below is
    // state-derived, and reading `_cubit.state` outside a builder leaves it
    // stale for the whole operation — the panel only rebuilds on setState,
    // which a cubit emission does not trigger.
    return BlocBuilder<ReorderCubit, ReorderState>(
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
              enabled: state is! ReorderLoading,
            ),
            if (file != null && _pages.isNotEmpty) ...[
              const SizedBox(height: Sizes.lg),
              ReorderPageGrid(
                entries: _pages,
                onMoveLeft: _moveLeft,
                onMoveRight: _moveRight,
                tier: tier,
                enabled: state is! ReorderLoading,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPanel(ScreenTier tier) {
    return AppCard(
      child: BlocBuilder<ReorderCubit, ReorderState>(
        bloc: _cubit,
        builder: (context, state) => _PhaseContent(
          tier: tier,
          state: state,
          selectedFile: _selectedFile,
          hasPages: _pages.isNotEmpty,
          order: _pages.map((e) => e.pageIndex + 1).toList(),
          isReordered: _isReordered,
          onStart: _startReorder,
          onRetry: _startReorder,
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
