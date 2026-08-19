# Developer Preferences

This file captures the inferred engineering preferences of the original developer, derived statistically from the codebase. Use this to produce code that is indistinguishable from the original.

> For class declaration syntax rules (`final class`, `abstract class`, `mixin`) and linting config — see [coding_standards.md](coding_standards.md).

---

## Composition > Inheritance

Problems are solved with mixins, not deep inheritance hierarchies:

```dart
// Feature behaviors via mixins
final class AppInitializer with CrashlyticsInitializerMixin, AppDependencyRegisterMixin {}

// Model capabilities via mixins
final class BannerModel with ImageUrlCompleterMixin implements EntityModel<BannerModel> {}

// Widget state logic via mixins
class _HomeScreenState extends State<HomeScreen> with _HomeScreenStateMixin {}

// URL launching via mixin
class LinkText extends StatelessWidget with PlatformAwareLauncherMixin {}
```

---

## Mixin-First Screen State Management

Screen state classes delegate all logic to a `mixin`:

```dart
// State class — minimal
class _HomeScreenState extends State<HomeScreen> with _HomeScreenStateMixin {
  // No logic here — everything is in the mixin
}

// Mixin — all logic
mixin _HomeScreenStateMixin on State<HomeScreen> {
  late final ScrollController _controller;
  late final BannerCubit _bannerCubit;
  // initState, dispose, widget builder methods
}
```

---

## `late final` for DI-Resolved State

```dart
late final BannerCubit _bannerCubit;

@override
void initState() {
  super.initState();
  _bannerCubit = AppDependency.injector.get<BannerCubit>();
}
```

`late final` enforces single assignment. Never `late` without `final` unless mutation is required.

---

## Private Widgets — Private, But Each in Its Own File

Internal sub-widgets stay private with the `_` prefix, but they are **never stacked in the
parent file**. Each private widget gets its own file, declared as a `part` of its parent.

```dart
// home_screen.dart — HomeScreen is the ONLY class in this file
part 'home_screen/_home_screen_state.dart';
part 'home_screen/_home_screen_state_mixin.dart';
part 'home_screen/_sliver_app_bar.dart';
part 'home_screen/_footer_view.dart';
part 'home_screen/_footer_success_view.dart';
part 'home_screen/_footer_error_view.dart';

final class HomeScreen extends StatefulWidget { ... }
```

```dart
// home_screen/_sliver_app_bar.dart — one class, nothing else
part of '../home_screen.dart';

final class _SliverAppBar extends StatelessWidget { ... }
```

Layout on disk — the part folder is named after the parent file:

```
pages/
├── home_screen.dart                    → HomeScreen
└── home_screen/
    ├── _home_screen_state.dart         → _HomeScreenState
    ├── _home_screen_state_mixin.dart   → _HomeScreenStateMixin
    ├── _sliver_app_bar.dart            → _SliverAppBar
    ├── _footer_view.dart               → _FooterView
    ├── _footer_success_view.dart       → _FooterSuccessView
    └── _footer_error_view.dart         → _FooterErrorView
```

Rules:
- Part folder name = parent file name without `.dart`
- Part file name = class name in `snake_case`, keeping the leading `_`
- Exactly one class per part file
- All `import` directives live in the parent file — a part file starts with `part of` and nothing else

Public reusable widgets go in `lib/app/widgets/` or `lib/features/x/presentation/widgets/` —
still one class per file.

---

## `const` as Default

The developer writes `const` on everything unless it's explicitly impossible. This includes:

- All model constructors
- All state constructors
- Single-instance widgets like `const DeveloperInfoText()`
- All `SizedBox.shrink()` → `const SizedBox.shrink()`
- All `EmptySize.*` and `SliverEmptySize.*` — these are static `const` instances

---

## Named Parameters with Defaults in Models

```dart
// Prefer named with defaults over positional
const BannerModel({this.imageUrl = ''});
const CampaignModel({this.imageUrl = '', this.title = ''});

// Never positional
const BannerModel(this.imageUrl);  // NEVER
```

This allows `const BannerModel()` for skeleton loading.

---

## `Future.wait()` over sequential awaits

```dart
// NEVER — sequential
await _bannerCubit.getBanners();
await _campaignCubit.getCampaigns();
await _companyCubit.getCompanyInfo();

// CORRECT — parallel
await Future.wait<void>([
  _bannerCubit.getBanners(),
  _campaignCubit.getCampaigns(),
  _companyCubit.getCompanyInfo(),
]);
```

---

## One Class per File — No Exception for Private Classes

Each Dart file declares **exactly one class**, public or private. Being private is not a license
to share a file — a private class gets its own file too, as a `part` (see above).

```
banner_model.dart         → BannerModel (+ generated BannerModel extension)
banner_cubit.dart         → BannerCubit (no state here)
banner_repository.dart    → BannerRepository (abstract)
remote_banner_repository.dart → RemoteBannerRepository (impl)
home_screen.dart          → HomeScreen (sub-widgets are parts, one per file)
```

### The only exception: a sealed state family

State variants are one sealed type, not independent classes, so they stay together:

```
banner_state.dart → BannerState + BannerInitial + BannerLoading + BannerSuccess + BannerError
```

This exception covers **nothing else**. Widgets, mixins, models, services, repositories, cubits
and every private helper class get their own file.

---

## Abstract Base → Concrete Implementation

Every service, repository, and theme follows this pattern:

```
NetworkService (abstract) → DioNetworkManager (final class)
BannerRepository (abstract) → RemoteBannerRepository (final class)
AppTheme (abstract) → LightTheme / DarkTheme (class — not final, so they can override)
ThemeService (abstract ChangeNotifier) → ThemeManager (final class)
EnvironmentProfile (abstract) → DevelopmentEnvironmentProfile / ReleaseEnvironmentProfile
CrashlyticsService (abstract) → ConsoleCrashlyticsManager / FirebaseCrashlyticsManager
DependencyInjector (abstract) → GetItInjector (final class)
```

---

## Comment Style

Code is self-documenting. Comments are rare.

- `///` doc comments appear only on constants classes with enum-like statics (e.g., `Sizes`, `AppInsets`)
- No inline block comments
- No `// TODO` found in the existing codebase
- No parameter comments in model fields

---

## Build Methods Decomposed via Private Widget Classes

When `build()` grows, it decomposes into **private widget classes in their own part files** —
never into `Widget _buildX()` helper methods.

```dart
// home_screen.dart
@override
Widget build(BuildContext context) {
  return const Column(
    children: [
      _Header(),
      _Body(),
    ],
  );
}
```

```dart
// home_screen/_header.dart
part of '../home_screen.dart';

final class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) { ... }
}
```

```dart
// NEVER — a build helper method instead of a widget class
Widget _buildHeader(BuildContext context) { ... }
```

A widget class gets a `const` constructor and its own rebuild scope; a helper method gets
neither and rebuilds with the whole parent.

---

## Sort Order Within Files

Follows `sort_constructors_first` linter rule:

1. Constructors (including factory)
2. Fields
3. Getters and setters
4. Methods
5. Overrides

---

## `@override` Explicitly on All Implementations

```dart
@override
Widget build(BuildContext context) { ... }

@override
Map<String, dynamic> toJson() => _$BannerModelToJson(this);

@override
BannerModel fromJson(Map<String, dynamic> json) => BannerModel.fromJson(json);
```

Never omit `@override`.

---

## Dart 3 Patterns Preferred

```dart
// Switch expressions (not if-else chains)
final theme = switch (themeOption) {
  ThemeOption.light => LightTheme().theme,
  ThemeOption.dark => DarkTheme().theme,
};

// Null-safe defaults
final items = state is CampaignSuccess ? state.campaigns : const <CampaignModel>[];
final company = state is CompanySuccess ? state.company : const CompanyModel();
```

---

## Clean Separation of Concerns

| Layer | Responsibility | Example |
|-------|---------------|---------|
| Repository | Data fetch + exception | `RemoteBannerRepository` |
| Cubit | State orchestration | `BannerCubit.getBanners()` |
| Screen | Navigation + lifecycle | `HomeScreen` init/dispose |
| Widget | Pure rendering | `ImageCarouselSlider`, `BoxShimmer` |
| Mixin | Cross-cutting behavior | `ImageUrlCompleterMixin`, `SafeStateMixin` |
