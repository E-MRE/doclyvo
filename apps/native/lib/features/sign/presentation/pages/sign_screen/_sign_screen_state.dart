part of '../sign_screen.dart';

final class _SignScreenState extends State<SignScreen> {
  late final SignCubit _cubit;
  late final FilePickerService _filePickerService;
  late final TextEditingController _typedNameController;

  final SignatureImageRenderer _renderer = const SignatureImageRenderer();

  PickedPdfFile? _selectedFile;
  int? _pageCount;

  /// One-based, matching the design's "Sayfa 1 / 3" copy and `apps/web`.
  int _currentPage = 1;

  SignatureMode _mode = SignatureMode.draw;

  /// Freehand strokes and the pad size they were captured in — the rasterizer
  /// needs both, so they travel together.
  List<List<Offset>> _strokes = const [];
  Size _padSize = Size.zero;

  PickedImageFile? _uploadedImage;
  Uint8List? _uploadedImageBytes;

  /// The rasterized signature, set by "Belgeye Yerleştir". `null` means
  /// nothing is placed yet, which is exactly what gates the İmzala button —
  /// same two-step flow as the design and `apps/web`.
  Uint8List? _placedSignature;

  @override
  void initState() {
    super.initState();
    _cubit = AppDependency.injector.get<SignCubit>();
    _filePickerService = AppDependency.injector.get<FilePickerService>();
    _typedNameController = TextEditingController();
  }

  @override
  void dispose() {
    _typedNameController.dispose();
    unawaited(_cubit.close());
    super.dispose();
  }

  String get _typedName => _typedNameController.text.trim();

  /// Whether the current mode has enough input to rasterize a signature.
  ///
  /// The draw branch also requires a non-empty pad size: the rasterizer turns
  /// it into the output bitmap's dimensions, and a zero-sized image is an
  /// engine error rather than an empty signature.
  bool get _canPlace => switch (_mode) {
    SignatureMode.draw =>
      !_padSize.isEmpty && _strokes.any((stroke) => stroke.isNotEmpty),
    SignatureMode.type => _typedName.isNotEmpty,
    SignatureMode.upload => _uploadedImageBytes != null,
  };

  bool get _canStart =>
      _placedSignature != null && _cubit.state is! SignLoading;

  void _onFileSelected(PickedPdfFile file) {
    _cubit.reset();
    setState(() {
      _selectedFile = file;
      _pageCount = null;
      _currentPage = 1;
    });
    unawaited(_loadFileMetadata(file));
  }

  Future<void> _loadFileMetadata(PickedPdfFile file) async {
    final bytes = await file.readBytes();
    final pageCount = await _cubit.readPageCount(bytes: bytes);
    if (!mounted || _selectedFile != file) return;
    setState(() => _pageCount = pageCount);
  }

  void _onFileRemoved() {
    _cubit.reset();
    setState(() {
      _selectedFile = null;
      _pageCount = null;
      _currentPage = 1;
    });
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  /// Switching modes drops the other modes' input, matching `apps/web`'s
  /// `handleModeChange`, and un-places the signature — leaving a placed
  /// graphic from the previous mode would sign something the visible controls
  /// no longer describe.
  void _onModeSelected(SignatureMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _strokes = const [];
      _padSize = Size.zero;
      _typedNameController.clear();
      _uploadedImage = null;
      _uploadedImageBytes = null;
      _placedSignature = null;
    });
  }

  void _onStrokesChanged(List<List<Offset>> strokes, Size canvasSize) {
    setState(() {
      _strokes = strokes;
      if (!canvasSize.isEmpty) _padSize = canvasSize;
    });
  }

  void _clearStrokes() {
    setState(() {
      _strokes = const [];
      _placedSignature = null;
    });
  }

  void _onTypedNameChanged(String _) {
    // The text lives in the controller; this only re-runs [_canPlace] so the
    // "Belgeye Yerleştir" button tracks what was typed.
    setState(() {});
  }

  Future<void> _pickSignatureImage() async {
    try {
      final image = await _filePickerService.pickSignatureImage();
      if (image == null || !mounted) return;
      final bytes = await image.readBytes();
      if (!mounted) return;
      setState(() {
        _uploadedImage = image;
        _uploadedImageBytes = bytes;
        _placedSignature = null;
      });
    } on FilePickerException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.sign_uploadFailed.tr())),
      );
    }
  }

  /// Rasterizes the current mode's input into the PNG bytes the engine stamps.
  ///
  /// All three modes end up as an image because `addImageStamp` is
  /// `pdf_manipulator`'s only stamping primitive — see `SignatureMode`.
  Future<void> _placeSignature() async {
    if (!_canPlace) return;
    final ink = Theme.of(context).colorScheme.primary;

    final bytes = switch (_mode) {
      SignatureMode.draw => await _renderer.renderStrokes(
        strokes: _strokes,
        canvasSize: _padSize,
        color: ink,
      ),
      SignatureMode.type => await _renderer.renderText(
        text: _typedName,
        color: ink,
      ),
      SignatureMode.upload => _uploadedImageBytes!,
    };

    if (!mounted) return;
    setState(() => _placedSignature = bytes);
  }

  Future<void> _startSign() async {
    final file = _selectedFile;
    final signature = _placedSignature;
    if (file == null || signature == null || !_canStart) return;
    final bytes = await file.readBytes();
    await _cubit.sign(
      bytes: bytes,
      signatureImageBytes: signature,
      pageIndex: _currentPage - 1,
      placement: SignaturePlacement.bottomRight,
      pageCount: _pageCount ?? 0,
    );
  }

  /// A fresh operation starts from an empty pad on the default mode — the
  /// previous signature belongs to a file that has already been downloaded.
  void _startNewOperation() {
    _cubit.reset();
    setState(() {
      _selectedFile = null;
      _pageCount = null;
      _currentPage = 1;
      _mode = SignatureMode.draw;
      _strokes = const [];
      _padSize = Size.zero;
      _typedNameController.clear();
      _uploadedImage = null;
      _uploadedImageBytes = null;
      _placedSignature = null;
    });
  }

  String _outputFileName(String inputName) {
    final withoutExtension = inputName.toLowerCase().endsWith('.pdf')
        ? inputName.substring(0, inputName.length - 4)
        : inputName;
    return '${withoutExtension}_imzali.pdf';
  }

  Future<void> _download(Uint8List bytes, String fileName) async {
    try {
      await _filePickerService.savePdf(fileName: fileName, bytes: bytes);
    } on FilePickerException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.sign_saveFailed.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tier = context.screenTier;
    final isMobile = tier == ScreenTier.mobile;

    return BlocProvider<SignCubit>(
      create: (_) => _cubit,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(RouteConstants.home),
          ),
          title: Text(LocaleKeys.sign_pageTitle.tr()),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: isMobile ? AppInsets.all16 : AppInsets.all24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.sign_pageSubtitle.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textSoftColor,
                  ),
                ),
                const SizedBox(height: Sizes.xl),
                // Desktop keeps the design's 1fr/380px two-column split
                // (document preview, signature settings); tablet/mobile stack
                // instead of squeezing — the same "stack, don't squeeze" call
                // every Phase 3A screen has made.
                if (tier == ScreenTier.desktop)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: _buildDocumentPanel(tier)),
                        const SizedBox(width: Sizes.xl),
                        Expanded(flex: 5, child: _buildSettingsPanel(tier)),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDocumentPanel(tier),
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

  Widget _buildDocumentPanel(ScreenTier tier) {
    final file = _selectedFile;

    // One BlocBuilder around the whole panel, not just the preview: the
    // dropzone's `enabled` flag is state-derived too, and reading it outside a
    // builder would leave it stale for the duration of the operation (the
    // cross-cutting bug found in P3A-7).
    return AppCard(
      child: BlocBuilder<SignCubit, SignState>(
        bloc: _cubit,
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            UploadDropzone(
              filePickerService: _filePickerService,
              selectedFile: file,
              onFileSelected: _onFileSelected,
              onFileRemoved: _onFileRemoved,
              tier: tier,
              enabled: state is! SignLoading,
            ),
            if (file != null) ...[
              const SizedBox(height: Sizes.xl),
              Center(
                child: SignDocumentPreview(
                  fileName: file.name,
                  currentPage: _currentPage,
                  pageCount: _pageCount,
                  onPageChanged: _onPageChanged,
                  signatureImageBytes: _placedSignature,
                  enabled: state is! SignLoading,
                  tier: tier,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel(ScreenTier tier) {
    return AppCard(
      child: BlocBuilder<SignCubit, SignState>(
        bloc: _cubit,
        builder: (context, state) => _PhaseContent(
          tier: tier,
          state: state,
          selectedFile: _selectedFile,
          mode: _mode,
          strokes: _strokes,
          typedNameController: _typedNameController,
          uploadedImage: _uploadedImage,
          canPlace: _canPlace,
          canStart: _canStart,
          onModeSelected: _onModeSelected,
          onStrokesChanged: _onStrokesChanged,
          onClearStrokes: _clearStrokes,
          onTypedNameChanged: _onTypedNameChanged,
          onPickImage: () => unawaited(_pickSignatureImage()),
          onPlace: () => unawaited(_placeSignature()),
          onStart: () => unawaited(_startSign()),
          onRetry: () => unawaited(_startSign()),
          onDownload: (bytes) => unawaited(
            _download(bytes, _outputFileName(_selectedFile?.name ?? 'dosya.pdf')),
          ),
          onReset: _startNewOperation,
        ),
      ),
    );
  }
}
