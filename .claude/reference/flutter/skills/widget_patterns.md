# Widget Patterns

## Screen Widget Structure

Every screen is a `StatefulWidget` with a private mixin for state initialization logic.

```dart
// home_screen.dart
final class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with _HomeScreenStateMixin {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: CustomScrollView(
          controller: _controller,
          slivers: [
            _SliverAppBar(_bannerCubit),
            SliverEmptySize.largeHeight,
            SliverToBoxAdapter(child: CampaignLabelSection(campaignCubit: _campaignCubit)),
            SliverEmptySize.xLargeHeight,
            SliverToBoxAdapter(child: CategoryLabelSection(...)),
            SliverEmptySize.xLargeHeight,
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _FooterView(_companyCubit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Screen State Mixin Pattern

Extract all `initState`/`dispose` logic into a private mixin on the State class.

```dart
// home_screen_state_mixin.dart
mixin _HomeScreenStateMixin on State<HomeScreen> {
  late final ScrollController _controller;
  late final BannerCubit _bannerCubit;
  late final CampaignCubit _campaignCubit;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _bannerCubit = AppDependency.injector.get<BannerCubit>();
    _campaignCubit = AppDependency.injector.get<CampaignCubit>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait<void>([
        _bannerCubit.getBanners(),
        _campaignCubit.getCampaigns(),
      ]);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

**Rule**: The mixin file is `<screen_name>_state_mixin.dart` and lives in `presentation/mixins/`.

---

## Private Widget Pattern

Widgets that are only used within one screen/widget file are declared as private classes (`_WidgetName`) in the same file.

```dart
// In home_screen.dart
final class _SliverAppBar extends StatelessWidget {
  const _SliverAppBar(this.bannerCubit);
  final BannerCubit bannerCubit;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: Text(LocaleKeys.appName.tr()),
      centerTitle: true,
      pinned: true,
      floating: true,
      expandedHeight: Sizes.enormousPlus,
      flexibleSpace: FlexibleSpaceBar(
        background: BannerCarousel(bannerCubit: bannerCubit),
      ),
    );
  }
}
```

**When to use private widget**: When a widget is a direct, non-reusable sub-component of its parent and won't be needed elsewhere.

**When to use separate file**: When a widget is reused in multiple places, or when it's complex enough to warrant its own file.

---

## BlocProvider + BlocBuilder Pattern

`BlocProvider` wraps the widget boundary where the cubit is needed.  
The cubit instance comes from outside (from DI) — never create it inside `BlocProvider.create`.

```dart
// Pass cubit from parent, provide at the widget level
final class CampaignLabelSection extends StatelessWidget {
  const CampaignLabelSection({required this.campaignCubit, super.key});
  final CampaignCubit campaignCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => campaignCubit,  // received from parent, not created here
      child: BlocBuilder<CampaignCubit, CampaignState>(
        builder: (context, state) {
          return LabeledSection(
            isLoading: state is CampaignLoading,
            title: LocaleKeys.homeScreen_categories.translate(),
            section: CampaignCarousel(campaignCubit: campaignCubit),
          );
        },
      ),
    );
  }
}
```

---

## Loading State — Shimmer Skeleton

Every widget that can be in a loading state shows a `BoxShimmer` placeholder.

```dart
// In a BlocBuilder
if (state is BannerLoading) {
  return BoxShimmer(width: double.infinity, height: height);
}

// In LabeledSection — shimmer for the title while loading
if (isLoading)
  BoxShimmer(
    width: context.dynamicWidth(.5),  // 50% of screen width
    height: context.textTheme.titleLarge?.fontSize,
    borderRadius: Sizes.xSmall,
  )
else
  Text(title, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))
```

**Rule**: Shimmer dimensions must match the real content dimensions. Use `Sizes.*` values.

---

## Error State — BasicErrorContainer

Every widget that can fail shows `BasicErrorContainer` with a retry button.

```dart
if (state is BannerError) {
  return BasicErrorContainer(
    height: height,
    width: double.infinity,
    buttonText: LocaleKeys.errors_tryAgain.tr(),
    onPressed: () async => bannerCubit.getBanners(),  // retry callback
    message: state.message,
  );
}
```

**Rule**: Always provide the retry `onPressed` callback. Always use `LocaleKeys.errors_tryAgain` for the button text.

---

## Image Widgets — CachedImage

All network images go through `CachedImage`. Never use `Image.network()` directly.

```dart
CachedImage(
  url: item.fullImageUrl,
  fit: BoxFit.cover,
  width: double.infinity,
)

// With cache size control (for performance)
CachedImage(
  url: imageUrl,
  width: Sizes.mega,
  height: Sizes.mega,
  // maxCacheWidth/Height auto-derived from width/height when finite
)
```

---

## Carousel Widgets — ImageCarouselSlider

For image-only carousels:
```dart
ImageCarouselSlider(
  height: Sizes.giganticPlus,
  imageUrls: state.bannerImageUrls,
  autoPlay: true,
  viewportFraction: 1,
)
```

For complex item carousels, build feature-specific slider widgets (`CampaignSlider`, `CampaignSliderItem`).

---

## Loading Skeleton for Lists

When loading a list (e.g., campaign slider), generate fake items using `List.generate`:

```dart
final isLoading = state is CampaignLoading;
final campaigns = state is CampaignSuccess
    ? state.campaigns
    : List.generate(loadingItemCount, (_) => const CampaignModel());

// Then render normally — isLoading flag controls shimmer inside items
CarouselSlider.builder(
  itemCount: campaigns.length,
  options: options.copyWith(autoPlay: !isLoading),
  itemBuilder: (context, index, realIndex) {
    return CampaignSliderItem(
      elevation: elevation,
      isLoading: isLoading,
      item: campaigns[index],
    );
  },
)
```

---

## Mixin for Platform Actions

Widgets that launch URLs/maps/phone/email use `PlatformAwareLauncherMixin`:

```dart
final class _FooterSuccessView extends StatelessWidget
    with PlatformAwareLauncherMixin {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SocialMediaIconButton(
          icon: Icons.phone,
          onPressed: () async => openPhone(phone),
        ),
        SocialMediaIconButton(
          icon: Icons.mail,
          onPressed: () => openEmail(email),
        ),
        SocialMediaIconButton(
          icon: Icons.pin_drop_rounded,
          onPressed: () async => openMap(latitude: 42, longitude: 44),
        ),
      ],
    );
  }
}
```

---

## View Decomposition Pattern

Complex state branches inside a widget are extracted to separate private view classes:

```dart
final class _FooterView extends StatelessWidget {
  Widget _buildChild(CompanyState state) {
    if (state is CompanyError) return _FooterErrorView(...);
    if (state is CompanySuccess) return _FooterSuccessView(...);
    return _FooterSuccessView(...);  // default/empty state
  }
}

// Separate files in presentation/pages/views/
// footer_view.dart
// footer_success_view.dart
// footer_error_view.dart
```

---

## SafeStateMixin

Stateful widgets that call `setState` from async callbacks must use `SafeStateMixin`:

```dart
class _ImageCarouselState extends State<ImageCarouselSlider>
    with SafeStateMixin<ImageCarouselSlider> {
  int _currentIndex = 0;
  // setState is now safely guarded by `mounted` check
}
```

---

## Always / Never

### Always
- Use private mixin for screen `initState`/`dispose` logic
- Use `BoxShimmer` for loading placeholders — sized to match real content
- Use `BasicErrorContainer` with retry for error states
- Use `CachedImage` for all network images
- Pass cubits from DI to child widgets via constructor — never create in `BlocProvider.create`
- Use `SafeStateMixin` when calling `setState` from async callbacks
- Use `PlatformAwareLauncherMixin` for URL/map/phone/email launching

### Never
- Call `setState` in async code without `mounted` check
- Use `Image.network()` — always `CachedImage`
- Create cubits inside `BlocProvider.create` — inject from DI
- Put loading/error/success logic in separate cubits when it's the same data domain
- Use `BlocConsumer` or `BlocListener` unless side effects are needed (rare)
- Nest BlocProviders unnecessarily — each cubit is provided at the widget that needs it
