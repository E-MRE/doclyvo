# Performance

## Image Caching

All images use `CachedImage` which wraps `cached_network_image`.

```dart
final class CachedImage extends StatelessWidget {
  const CachedImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.defaultCacheHeight = 1080,
    this.defaultCacheWidth = 1080,
    this.maxCacheWidth,
    this.maxCacheHeight,
    this.height,
    this.width,
    super.key,
  });
}
```

### Cache size calculation
- If `width` is a finite value → `maxCacheWidth` = `width.toInt()`
- If `height` is a finite value → `maxCacheHeight` = `height.toInt()`
- Otherwise → uses defaults: `1080x1080`

```dart
final safeMaxWidth = maxCacheWidth ??
    (width?.isFinite ?? false ? width!.toInt() : defaultCacheWidth);
final safeMaxHeight = maxCacheHeight ??
    (height?.isFinite ?? false ? height!.toInt() : defaultCacheHeight);
```

**Best practice**: Always provide explicit `width` and `height` so cached dimensions match display dimensions.

---

## Shimmer Loading — No Layout Jumping

The shimmer pattern matches the real content dimensions exactly. This prevents layout jump on load.

```dart
// Shimmer for title — matches real text height
BoxShimmer(
  width: context.dynamicWidth(.5),                    // 50% width
  height: context.textTheme.titleLarge?.fontSize,     // matches text height
  borderRadius: Sizes.xSmall,
)

// Shimmer for full container — matches real container size
BoxShimmer(
  width: double.infinity,
  height: Sizes.giganticPlus,  // matches carousel height
)
```

---

## Skeleton Lists — Pre-generated Placeholders

Instead of showing a spinner, generate placeholder items of the same count as expected data:

```dart
final isLoading = state is CampaignLoading;
final campaigns = state is CampaignSuccess
    ? state.campaigns
    : List.generate(loadingItemCount, (_) => const CampaignModel());
```

`loadingItemCount` defaults are set in widget constructors (e.g., `loadingItemCount = 3`).

---

## Rebuild Minimization

### `const` widgets prevent rebuilds
```dart
// Widget tree parts that don't depend on state
const SizedBox.shrink()
const DeveloperInfoText()
SliverEmptySize.largeHeight  // these are static const instances
EmptySize.smallHeight         // same — no rebuild cost
```

### Cubit passed from outside prevents `BlocProvider` rebuild chain
```dart
// The section widget doesn't rebuild because of its own state;
// it rebuilds only when the cubit state changes
BlocProvider(
  create: (_) => campaignCubit,  // stable reference from parent
  child: BlocBuilder<...>(...)
)
```

### `safeEmit` prevents crashes from closed cubits
```dart
void safeEmit(State state) {
  if (!isClosed) emit(state);
}
```

---

## Scroll Performance

- `shrinkWrap: true` on `GridView` inside scroll views (requires `controller` to prevent conflicts)
- `BouncingScrollPhysics()` for natural iOS-style scrolling
- `CustomScrollView` with proper sliver types avoids double-scrolling

```dart
GridView.builder(
  shrinkWrap: true,
  controller: controller,        // shared scroll controller
  physics: const BouncingScrollPhysics(),
  // ...
)
```

---

## MaxWidthBox — Prevents Over-Wide Layouts

`ResponsiveWrapper` wraps all content in a `MaxWidthBox(maxWidth: 1280)`. This ensures performance on large screens isn't wasted rendering extra-wide layouts.

---

## Carousel Performance

```dart
CarouselSlider.builder(
  itemCount: campaigns.length,
  options: options.copyWith(autoPlay: !isLoading),  // disable autoplay while loading
  itemBuilder: (context, index, realIndex) {
    return CampaignSliderItem(isLoading: isLoading, item: campaigns[index]);
  },
)
```

Autoplay is disabled while loading to prevent layout instability.

---

## Always / Never

### Always
- Provide `width`/`height` to `CachedImage` when the size is known
- Match shimmer dimensions exactly to real content dimensions
- Use skeleton lists instead of spinners for list content
- Use `const` for widgets that don't depend on runtime state
- Disable carousel `autoPlay` during loading state

### Never
- Use `Image.network()` — no caching
- Use `shrinkWrap: true` on GridView without a shared `ScrollController`
- Show a full-screen spinner — use shimmer skeletons instead
- Forget to disable carousel autoplay while loading
