part of '../protect_screen.dart';

final class _ProtectScreenState extends State<ProtectScreen> {
  late final ProtectCubit _cubit;
  late final FilePickerService _filePickerService;
  late final TextEditingController _passwordController;

  final PasswordGenerator _passwordGenerator = const PasswordGenerator();

  PickedPdfFile? _selectedFile;
  int? _pageCount;
  bool _isRevealed = false;

  /// `noPrint` starts checked, matching `apps/web`'s default — the tool's
  /// common case is "lock this down", not "encrypt but keep every capability".
  Set<ProtectPermission> _permissions = {ProtectPermission.noPrint};

  @override
  void initState() {
    super.initState();
    _cubit = AppDependency.injector.get<ProtectCubit>();
    _filePickerService = AppDependency.injector.get<FilePickerService>();
    _passwordController = TextEditingController(
      text: _passwordGenerator.generate(),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    unawaited(_cubit.close());
    super.dispose();
  }

  String get _password => _passwordController.text.trim();

  bool get _isPasswordLongEnough =>
      _password.length >= PasswordGenerator.minimumLength;

  bool get _canStart =>
      _isPasswordLongEnough && _cubit.state is! ProtectLoading;

  void _onFileSelected(PickedPdfFile file) {
    _cubit.reset();
    setState(() {
      _selectedFile = file;
      _pageCount = null;
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
    });
  }

  void _onPasswordChanged(String _) {
    // The text itself lives in the controller; this only re-runs [_canStart]
    // so the Koru button and the too-short hint track what was typed.
    setState(() {});
  }

  void _toggleReveal() {
    setState(() => _isRevealed = !_isRevealed);
  }

  /// Generating also reveals, matching `apps/web` — a password the user never
  /// sees is one they cannot write down, and the result copy warns it is shown
  /// only once.
  void _generatePassword() {
    setState(() {
      _passwordController.text = _passwordGenerator.generate();
      _isRevealed = true;
    });
  }

  void _togglePermission(ProtectPermission permission) {
    setState(() {
      _permissions = {..._permissions};
      if (!_permissions.remove(permission)) _permissions.add(permission);
    });
  }

  Future<void> _startProtect() async {
    final file = _selectedFile;
    if (file == null || !_canStart) return;
    final bytes = await file.readBytes();
    await _cubit.protect(
      bytes: bytes,
      options: PdfProtectionOptions(
        password: _password,
        // The permission enum names restrictions ("engelle"), the engine's
        // options name capabilities — so every flag inverts here.
        allowPrinting: !_permissions.contains(ProtectPermission.noPrint),
        allowCopying: !_permissions.contains(ProtectPermission.noCopy),
        allowEditing: !_permissions.contains(ProtectPermission.noEdit),
      ),
      pageCount: _pageCount ?? 0,
    );
  }

  /// A fresh operation gets a fresh suggested password, hidden again — the
  /// previous one belongs to a file that has already been downloaded.
  void _startNewOperation() {
    _cubit.reset();
    setState(() {
      _selectedFile = null;
      _pageCount = null;
      _passwordController.text = _passwordGenerator.generate();
      _isRevealed = false;
    });
  }

  String _outputFileName(String inputName) {
    final withoutExtension = inputName.toLowerCase().endsWith('.pdf')
        ? inputName.substring(0, inputName.length - 4)
        : inputName;
    return '${withoutExtension}_korumali.pdf';
  }

  Future<void> _download(Uint8List bytes, String fileName) async {
    try {
      await _filePickerService.savePdf(fileName: fileName, bytes: bytes);
    } on FilePickerException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.protect_saveFailed.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tier = context.screenTier;
    final isMobile = tier == ScreenTier.mobile;

    return BlocProvider<ProtectCubit>(
      create: (_) => _cubit,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(RouteConstants.home),
          ),
          title: Text(LocaleKeys.protect_pageTitle.tr()),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: isMobile ? AppInsets.all16 : AppInsets.all24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.protect_pageSubtitle.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textSoftColor,
                  ),
                ),
                const SizedBox(height: Sizes.xl),
                // Desktop keeps the design's 1fr/380px two-column split
                // (upload + lock badge, settings); tablet/mobile stack instead
                // of squeezing it into narrow columns — the same "stack, don't
                // squeeze" call every Phase 3A screen has made.
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

    // One BlocBuilder around the whole panel, not just the lock badge: the
    // dropzone's `enabled` flag is state-derived too, and reading it outside a
    // builder would leave it stale for the duration of the operation.
    return AppCard(
      child: BlocBuilder<ProtectCubit, ProtectState>(
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
              enabled: state is! ProtectLoading,
            ),
            if (file != null) ...[
              const SizedBox(height: Sizes.xl),
              Center(
                child: ProtectLockStatus(
                  isProtected: state is ProtectSuccess,
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
      child: BlocBuilder<ProtectCubit, ProtectState>(
        bloc: _cubit,
        builder: (context, state) => _PhaseContent(
          tier: tier,
          state: state,
          selectedFile: _selectedFile,
          passwordController: _passwordController,
          isRevealed: _isRevealed,
          isPasswordLongEnough: _isPasswordLongEnough,
          permissions: _permissions,
          canStart: _canStart,
          onPasswordChanged: _onPasswordChanged,
          onToggleReveal: _toggleReveal,
          onGeneratePassword: _generatePassword,
          onTogglePermission: _togglePermission,
          onStart: _startProtect,
          onRetry: _startProtect,
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
