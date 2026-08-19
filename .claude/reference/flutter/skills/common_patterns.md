# Common Patterns

## Pattern 1 — BLoC Loading/Success/Error Loop

The universal pattern for any async data fetch in this project:

```dart
// 1. Cubit
final class BannerCubit extends BaseCubit<BannerState> {
  BannerCubit(this.repository) : super(const BannerInitial());
  final BannerRepository repository;

  Future<void> getBanners() async {
    return safeCall<List<BannerModel>>(
      action: () async => repository.getBanners(),
      loadingState: const BannerLoading(),
      successState: (data) => BannerSuccess(banners: data),
      errorState: (message) => BannerError(message: message),
    );
  }
}

// 2. Widget
BlocBuilder<BannerCubit, BannerState>(
  builder: (context, state) {
    if (state is BannerLoading) {
      return BoxShimmer(width: double.infinity, height: height);
    }
    if (state is BannerError) {
      return BasicErrorContainer(
        height: height,
        width: double.infinity,
        buttonText: LocaleKeys.errors_tryAgain.tr(),
        onPressed: () async => bannerCubit.getBanners(),
        message: state.message,
      );
    }
    if (state is BannerSuccess) {
      return ImageCarouselSlider(
        height: height,
        imageUrls: state.bannerImageUrls,
      );
    }
    return const SizedBox.shrink();
  },
)
```

---

## Pattern 2 — LabeledSection

Wraps any content with a title row (shimmer while loading):

```dart
LabeledSection(
  isLoading: state is CampaignLoading,
  title: LocaleKeys.homeScreen_categories.translate(),
  section: CampaignCarousel(campaignCubit: campaignCubit),
)
```

`LabeledSection` handles:
- Showing `BoxShimmer` for title when `isLoading: true`
- Showing bold title text when loaded
- `EmptySize.mediumHeight` between title and section
- `Column(mainAxisSize: MainAxisSize.min)` layout

---

## Pattern 3 — Skeleton Loading for Lists

Generate placeholder items while loading real data:

```dart
final isLoading = state is CampaignLoading;
final items = state is CampaignSuccess
    ? state.campaigns
    : List.generate(loadingItemCount, (_) => const CampaignModel());

// Render real items and placeholders identically
// isLoading flag passed down to item widget
itemBuilder: (context, index, _) => CampaignSliderItem(
  isLoading: isLoading,
  item: items[index],
  elevation: elevation,
)

// Inside CampaignSliderItem
if (isLoading) return const BoxShimmer(width: ..., height: ...);
return _buildRealContent(item);
```

---

## Pattern 4 — Parallel Data Fetching

Multiple cubits initialized and data loaded in parallel:

```dart
WidgetsBinding.instance.addPostFrameCallback((_) async {
  FlutterNativeSplash.remove();
  await Future.wait<void>([
    _bannerCubit.getBanners(),
    _campaignCubit.getCampaigns(),
    _companyCubit.getCompanyInfo(),
    _categoryCubit.getCategories(),
  ]);
});
```

---

## Pattern 5 — Cubit Passed to Child Widget

Cubits flow downward from screen to widgets via constructor injection:

```dart
// Screen
_SliverAppBar(_bannerCubit)
CampaignLabelSection(campaignCubit: _campaignCubit)
CategoryLabelSection(controller: _controller, categoryCubit: _categoryCubit)

// Section widget receives cubit and provides it
final class CampaignLabelSection extends StatelessWidget {
  const CampaignLabelSection({required this.campaignCubit, super.key});
  final CampaignCubit campaignCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => campaignCubit,  // provide at boundary
      child: ...,
    );
  }
}
```

---

## Pattern 6 — View Decomposition by State

Complex state-dependent widgets extract each state into a separate private/file class:

```dart
// _FooterView delegates to specific view classes
Widget _buildChild(CompanyState state) {
  if (state is CompanyError) {
    return _FooterErrorView(
      message: state.message,
      onRetry: () async => companyCubit.getCompanyInfo(),
    );
  }
  if (state is CompanySuccess) {
    return _FooterSuccessView(
      name: state.company.name,
      address: state.company.address,
      email: state.company.email,
      phone: state.company.phone,
      location: state.company.location,
    );
  }
  return _FooterSuccessView(
    name: SpecialKey.dash.rawValue,   // placeholder values
    address: SpecialKey.dash.rawValue,
    email: SpecialKey.empty.rawValue,
    phone: SpecialKey.empty.rawValue,
    location: SpecialKey.empty.rawValue,
  );
}
```

---

## Pattern 7 — Image with Rounded Top Corners

Standard pattern for images inside cards:

```dart
ClipRRect(
  borderRadius: AppBorderRadius.verticalTopMedium,
  child: CachedImage(url: item.fullImageUrl),
)
```

---

## Pattern 8 — Card with Elevation

```dart
Card(
  margin: AppInsets.small,
  elevation: elevation,
  shape: AppRoundedRectangleBorder.medium,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: ClipRRect(
        borderRadius: AppBorderRadius.verticalTopMedium,
        child: CachedImage(url: item.fullImageUrl),
      )),
      Padding(
        padding: AppInsets.small,
        child: Text(item.title, textAlign: TextAlign.center, style: context.textTheme.bodyMedium),
      ),
    ],
  ),
)
```

---

## Pattern 9 — Column with Spacers

Use `EmptySize` widgets as gap children, not wrapping with `Padding`:

```dart
Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(name, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    EmptySize.smallHeight,
    Text(subtitle, style: context.textTheme.labelMedium),
    EmptySize.mediumHeight,
    Row(children: [...]),
  ],
)
```

---

## Pattern 10 — Sliver Screen Layout

Standard screen layout using `CustomScrollView` with slivers:

```dart
SafeArea(
  child: Scaffold(
    body: CustomScrollView(
      controller: _controller,
      slivers: [
        SliverAppBar(
          title: Text(LocaleKeys.appName.tr()),
          pinned: true,
          floating: true,
          expandedHeight: Sizes.enormousPlus,
          flexibleSpace: FlexibleSpaceBar(background: BannerCarousel(...)),
        ),
        SliverEmptySize.largeHeight,
        SliverToBoxAdapter(child: SectionWidget(...)),
        SliverEmptySize.xLargeHeight,
        SliverFillRemaining(
          hasScrollBody: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FooterWidget(...),
          ),
        ),
      ],
    ),
  ),
)
```

---

## Pattern 11 — Social Icon Button

Circular icon button for social media links:

```dart
SocialMediaIconButton(
  icon: Icons.phone,
  onPressed: () async => openPhone(phone),
  // optional: backgroundColor, iconColor, size
)
```

---

## Pattern 12 — Developer Info Footer

DeveloperInfoText widget placed at the bottom of every footer:

```dart
Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    // ... other footer content
    EmptySize.smallHeight,
    const DeveloperInfoText(),
  ],
)
```
