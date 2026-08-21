part of '../merge_screen.dart';

final class _MergeScreenState extends State<MergeScreen> {
  late final MergeCubit _cubit;
  late final FilePickerService _filePickerService;

  List<MergeFileEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _cubit = AppDependency.injector.get<MergeCubit>();
    _filePickerService = AppDependency.injector.get<FilePickerService>();
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  bool get _canMerge => _entries.length >= 2;

  int get _totalPages => _entries.fold(
    0,
    (sum, entry) => sum + (entry.pageCount ?? 0),
  );

  Future<void> _addFiles() async {
    List<PickedPdfFile> picked;
    try {
      picked = await _filePickerService.pickMultiplePdfs();
    } on FilePickerException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.merge_pickFailed.tr())),
      );
      return;
    }
    if (picked.isEmpty) return;

    _cubit.reset();
    final newEntries = picked
        .map((file) => MergeFileEntry(file: file))
        .toList();
    setState(() => _entries = [..._entries, ...newEntries]);

    for (final entry in newEntries) {
      unawaited(_loadPageCount(entry));
    }
  }

  Future<void> _loadPageCount(MergeFileEntry entry) async {
    final bytes = await entry.file.readBytes();
    final count = await _cubit.readPageCount(bytes: bytes);
    if (!mounted) return;
    final index = _entries.indexWhere((e) => e.file == entry.file);
    if (index == -1) return;
    setState(() {
      _entries = [..._entries]
        ..[index] = _entries[index].copyWithPageCount(count);
    });
  }

  void _moveUp(int index) {
    if (index <= 0) return;
    setState(() {
      final entries = [..._entries];
      final entry = entries.removeAt(index);
      entries.insert(index - 1, entry);
      _entries = entries;
    });
  }

  void _moveDown(int index) {
    if (index >= _entries.length - 1) return;
    setState(() {
      final entries = [..._entries];
      final entry = entries.removeAt(index);
      entries.insert(index + 1, entry);
      _entries = entries;
    });
  }

  void _removeFile(int index) {
    _cubit.reset();
    setState(() {
      _entries = [..._entries]..removeAt(index);
    });
  }

  Future<void> _startMerge() async {
    if (!_canMerge) return;
    final entries = _entries;
    final documents = await Future.wait(
      entries.map((entry) => entry.file.readBytes()),
    );
    await _cubit.merge(
      documents: documents,
      fileCount: entries.length,
      totalPages: _totalPages,
    );
  }

  void _startNewOperation() {
    _cubit.reset();
    setState(() => _entries = []);
  }

  Future<void> _download(Uint8List bytes, String fileName) async {
    try {
      await _filePickerService.savePdf(fileName: fileName, bytes: bytes);
    } on FilePickerException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.merge_saveFailed.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tier = context.screenTier;
    final isMobile = tier == ScreenTier.mobile;

    return BlocProvider<MergeCubit>(
      create: (_) => _cubit,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(RouteConstants.home),
          ),
          title: Text(LocaleKeys.merge_pageTitle.tr()),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: isMobile ? AppInsets.all16 : AppInsets.all24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.merge_pageSubtitle.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textSoftColor,
                  ),
                ),
                const SizedBox(height: Sizes.xl),
                // Desktop keeps a two-column layout (file list + summary),
                // matching `design/Merge.dc.html`'s 1fr/380px grid.
                // Tablet/mobile stack instead of squeezing that split into
                // narrow columns — the same "stack, don't squeeze" call
                // P1-5 made for the home screen and P3A-1/P3A-2 made for
                // Compress/Split.
                if (tier == ScreenTier.desktop)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: _buildFileListPanel(tier)),
                        const SizedBox(width: Sizes.xl),
                        Expanded(flex: 5, child: _buildSummaryPanel(tier)),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFileListPanel(tier),
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

  Widget _buildFileListPanel(ScreenTier tier) {
    return AppCard(
      child: MergeFileList(
        entries: _entries,
        onAddFiles: () => unawaited(_addFiles()),
        onMoveUp: _moveUp,
        onMoveDown: _moveDown,
        onRemove: _removeFile,
        tier: tier,
        enabled: _cubit.state is! MergeLoading,
      ),
    );
  }

  Widget _buildSummaryPanel(ScreenTier tier) {
    return AppCard(
      child: BlocBuilder<MergeCubit, MergeState>(
        bloc: _cubit,
        builder: (context, state) => _PhaseContent(
          tier: tier,
          state: state,
          fileCount: _entries.length,
          totalPages: _totalPages,
          canMerge: _canMerge,
          onStart: _startMerge,
          onRetry: _startMerge,
          onDownload: (bytes) => unawaited(
            _download(bytes, _outputFileName),
          ),
          onReset: _startNewOperation,
        ),
      ),
    );
  }

  /// Merge combines multiple inputs into one output, so there is no single
  /// source file name to derive the output name from (unlike Compress/Split,
  /// which suffix the one input file's name) — a fixed Turkish name, same
  /// non-localized-literal precedent as `SplitScreen`'s `_sayfalar` suffix.
  String get _outputFileName => 'birlestirilmis.pdf';
}
