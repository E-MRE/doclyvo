# Widget Decomposition Rules

Rules for deciding when and how to break a widget into smaller pieces, specific to this codebase.

---

## Rule 1 — Private Class vs Private Method

Use a **private class** (`final class _Name`) when:
- The widget has its own `BlocBuilder` / `BlocProvider` (independent rebuild scope)
- The widget is a named visual region with clear identity (`_SliverAppBar`, `_FooterView`)
- The widget encapsulates a loading/success/error branch

Use a **private method** (`Widget _buildX()`) when:
- The widget is a simple layout helper with no independent rebuild scope
- It's used exactly once and contains no state
- It just reduces `build()` line count

```dart
// Private class — independent rebuild
final class _BannerSection extends StatelessWidget {
  const _BannerSection(this.bannerCubit);
  final BannerCubit bannerCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => bannerCubit,
      child: BlocBuilder<BannerCubit, BannerState>(
        builder: (context, state) => _buildContent(state),
      ),
    );
  }
}

// Private method — simple layout helper
Widget _buildTitle(BuildContext context) {
  return Padding(
    padding: AppInsets.mediumHorizontal,
    child: Text(title, style: context.textTheme.titleLarge),
  );
}
```

---

## Rule 2 — State Branch Decomposition

Every distinct state branch gets its own private class:

```
BlocBuilder → 
  state is XLoading → BoxShimmer(...)
  state is XError   → _XErrorView(...)
  state is XSuccess → _XSuccessView(...)
  default           → const SizedBox.shrink()
```

Name the views `_XSuccessView`, `_XErrorView`. Loading inline shimmer is acceptable — it's a single widget call.

```dart
if (state is CompanyError) {
  return _FooterErrorView(message: state.message, onRetry: ...);
}
if (state is CompanySuccess) {
  return _FooterSuccessView(name: state.company.name, ...);
}
// Loading/Initial → shimmer or dash placeholders
return _FooterSuccessView(
  name: SpecialKey.dash.rawValue,
  email: SpecialKey.empty.rawValue,
  ...
);
```

---

## Rule 3 — When to Extract to Public Widget

Extract to `lib/app/widgets/` when the widget:
- Is used in 2 or more features
- Has no feature-specific type dependencies (doesn't import a feature model)
- Is a generic UI primitive (`BoxShimmer`, `CachedImage`, `BasicErrorContainer`, `LabeledSection`)

Keep in `lib/features/x/presentation/widgets/` when the widget:
- Is specific to one feature's domain
- Depends on a feature-specific model (`CampaignSliderItem`, `CategoryCard`)
- Would need to import cross-feature types if moved to `app/widgets/`

Keep as a private class in the same file when the widget:
- Is used only in one screen
- Is an implementation detail of that screen

---

## Rule 4 — StatefulWidget vs StatelessWidget + Mixin

Use `StatefulWidget` only when the widget needs `State` lifecycle:
- Manages a controller (`ScrollController`, `AnimationController`, `TabController`)
- Calls `setState` for local UI state (e.g., carousel index)
- Subscribes to streams/listeners in `initState`

If a `StatefulWidget` has complex logic, put it in a `_ScreenStateMixin`:
```dart
// All state logic in the mixin, state class is empty
mixin _HomeScreenStateMixin on State<HomeScreen> {
  late final ScrollController _controller;
  late final BannerCubit _bannerCubit;

  @override
  void initState() { ... }

  @override
  void dispose() { ... }
}

class _HomeScreenState extends State<HomeScreen>
    with _HomeScreenStateMixin {
  // intentionally empty
}
```

---

## Rule 5 — Skeleton Decomposition

When a widget shows both loading and real content, the item widget must handle both:

```dart
// Item widget receives isLoading flag
final class CampaignSliderItem extends StatelessWidget {
  const CampaignSliderItem({
    required this.isLoading,
    required this.item,
    required this.elevation,
    super.key,
  });
  final bool isLoading;
  final CampaignModel item;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return BoxShimmer(width: ..., height: ...);
    }
    return _buildCard(context);
  }
}

// Parent generates placeholders for loading
final items = state is CampaignSuccess
    ? state.campaigns
    : List.generate(loadingItemCount, (_) => const CampaignModel());
```

---

## Rule 6 — Sliver vs Box Widgets

Inside `CustomScrollView`, always use sliver widgets:
- `SliverToBoxAdapter` wraps any box widget
- `SliverList`, `SliverGrid` for lists/grids
- `SliverEmptySize.*` for spacing (not `EmptySize.*`)
- `SliverFillRemaining(hasScrollBody: false)` for footer

Never mix sliver and box scroll contexts. If content needs to scroll independently, isolate it.

---

## Rule 7 — Build Method Decomposition Threshold

Decompose `build()` when it exceeds ~30 lines or has more than one logical section:

```dart
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      _buildHeader(context),    // < 10 lines each
      _buildBody(context),
      _buildFooter(context),
    ],
  );
}
```

When sections have independent rebuilds (BLoC state), use private classes instead of private methods.
