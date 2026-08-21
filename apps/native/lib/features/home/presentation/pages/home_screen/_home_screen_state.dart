part of '../home_screen.dart';

final class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _toolsSectionKey = GlobalKey();
  late final ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _themeService = AppDependency.injector.get<ThemeService>();
  }

  void _scrollToTools() {
    final context = _toolsSectionKey.currentContext;
    if (context == null) return;
    unawaited(
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = context.screenTier;
    final isMobile = context.isMobile;
    // Tablet stacks the hero and upload card full-width instead of sharing a
    // Row, same as mobile — see the P1-5 Decisions log entry in
    // NATIVE-TASKS.md for why splitting them into columns at 700-1080px was
    // the original overflow trap. Tablet keeps desktop's padding/typography
    // (HomeHeroSection/UploadPreviewCard already branch on `tier == mobile`,
    // not `!= desktop`), so stacking here is the only change it needs.
    final stackHeroAndUpload = tier != ScreenTier.desktop;

    return BlocProvider<HomeCubit>(
      create: (_) => AppDependency.injector.get<HomeCubit>(),
      child: Scaffold(
        body: SafeArea(
        child: Column(
          children: [
            HomeHeader(tier: tier, themeService: _themeService),
            Expanded(
              child: SingleChildScrollView(
                padding: isMobile ? AppInsets.all16 : AppInsets.all24,
                child: stackHeroAndUpload
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HomeHeroSection(
                            tier: tier,
                            onBrowseTools: _scrollToTools,
                          ),
                          const SizedBox(height: Sizes.xl),
                          UploadPreviewCard(
                            tier: tier,
                            onSelectFile: () {},
                          ),
                          const SizedBox(height: Sizes.xxl),
                          _ToolsSection(key: _toolsSectionKey, theme: theme),
                          SizedBox(height: isMobile ? Sizes.lg : Sizes.xl),
                          ToolGrid(tier: tier),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: HomeHeroSection(
                                  tier: tier,
                                  onBrowseTools: _scrollToTools,
                                ),
                              ),
                              const SizedBox(width: Sizes.xxl - Sizes.xs),
                              Expanded(
                                flex: 5,
                                child: UploadPreviewCard(
                                  tier: tier,
                                  onSelectFile: () {},
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Sizes.xxl),
                          _ToolsSection(key: _toolsSectionKey, theme: theme),
                          const SizedBox(height: Sizes.xl),
                          ToolGrid(tier: tier),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
