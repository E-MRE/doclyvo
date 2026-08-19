# Flutter Best Practices

> For `const`, class declaration rules, and linting config — see [coding_standards.md](coding_standards.md).

---

## Widget Lifecycle

### StatefulWidget initialization

All side-effectful initialization goes in `initState` — never in `build()`:

```dart
@override
void initState() {
  super.initState();
  _controller = ScrollController();
  _bannerCubit = AppDependency.injector.get<BannerCubit>();

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await _bannerCubit.getBanners();
  });
}
```

`WidgetsBinding.instance.addPostFrameCallback` is used to defer work until the first frame is rendered (e.g., showing data after splash removal).

### dispose

Always dispose controllers and observers:

```dart
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

`ThemeManager` also observes `WidgetsBindingObserver` and removes itself in `dispose`.

---

## setState Safety

Never call `setState` from async context without `mounted` check.  
Use `SafeStateMixin` to handle this automatically:

```dart
class _ImageCarouselState extends State<ImageCarouselSlider>
    with SafeStateMixin<ImageCarouselSlider> {
  int _currentIndex = 0;

  void _setIndex(int index) {
    setState(() => _currentIndex = index);  // SafeStateMixin guards this
  }
}
```

---

## Avoid Unnecessary Rebuilds

### Use `BlocBuilder` with `buildWhen` for expensive widgets

```dart
BlocBuilder<MyCubit, MyState>(
  buildWhen: (previous, current) => previous != current,
  builder: (context, state) { ... },
)
```

### Use `context.watch` only at the top level

In `MyApp`, `context.watch<ThemeService>()` is used because the whole app needs to rebuild on theme change. This is intentional and correct.

### Extract leaf widgets

Small, frequently-rebuilt leaf widgets are extracted to separate classes to minimize rebuild scope.

---

## Key Usage

Always pass `key` through `super.key` in widgets that may be in lists or conditionally shown:

```dart
final class CampaignSliderItem extends StatelessWidget {
  const CampaignSliderItem({
    required this.elevation,
    required this.isLoading,
    required this.item,
    super.key,  // ← always pass through
  });
}
```

---

## Image Performance

`CachedImage` automatically derives cache dimensions from widget size:

```dart
CachedImage(
  url: imageUrl,
  width: Sizes.mega,    // → maxCacheWidth defaults to this
  height: Sizes.mega,   // → maxCacheHeight defaults to this
)
```

Default cache size is `1080x1080` when no `width`/`height` is provided. Set explicit `maxCacheWidth`/`maxCacheHeight` to override.

---

## CustomScrollView Performance

Use `SliverFillRemaining` for footer content that should pin to bottom:

```dart
SliverFillRemaining(
  hasScrollBody: false,
  child: Align(
    alignment: Alignment.bottomCenter,
    child: FooterWidget(),
  ),
)
```

Use `BouncingScrollPhysics` for lists:
```dart
GridView.builder(
  physics: const BouncingScrollPhysics(),
  // ...
)
```

---

## Platform Dispatcher Error Handling

Platform errors are caught at the root level — no need for individual try/catch in UI:

```dart
PlatformDispatcher.instance.onError = (error, stack) {
  final details = FlutterErrorDetails(exception: error, stack: stack);
  handleFlutterError(details);
  return true;
};
```

---

## Leak Tracking

In debug mode, `leak_tracker` is active:

```dart
if (kDebugMode) {
  LeakTracking.start();
  FlutterMemoryAllocations.instance.addListener(
    (ObjectEvent event) => LeakTracking.dispatchObjectEvent(event.toMap()),
  );
}
```

Always `dispose` controllers, streams, and animation controllers to avoid leaks.

---

## Always / Never

### Always
- Use `const` constructors wherever possible
- Initialize in `initState`, not in `build()`
- Defer post-frame work with `WidgetsBinding.instance.addPostFrameCallback`
- `dispose()` all controllers (ScrollController, AnimationController, etc.)
- Use `SafeStateMixin` for async `setState` calls
- Pass `super.key` in all widget constructors

### Never
- Call `AppDependency.injector.get<>()` inside `build()`
- Initialize controllers/cubits in `build()`
- Call `setState` from an async callback without `mounted` check
- Forget to `dispose()` ScrollController or similar
- Use `Image.network()` — always use `CachedImage`
