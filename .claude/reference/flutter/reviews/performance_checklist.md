# Performance Checklist

Use before shipping any screen or feature to verify runtime performance characteristics.

---

## Image Performance

- [ ] All network images use `CachedImage`, not `Image.network()`
- [ ] Explicit `width` and `height` provided to `CachedImage` where dimensions are known
- [ ] `maxCacheWidth` / `maxCacheHeight` explicitly set for high-density display images
- [ ] No unbounded `CachedImage` in a list without dimensions (defaults to 1080x1080)

---

## Loading State / Shimmer

- [ ] Shimmer dimensions exactly match real content dimensions (same height, same width)
- [ ] No layout jump between shimmer and loaded state
- [ ] Skeleton placeholder item count matches expected real data count
- [ ] `List.generate(count, (_) => const Model())` used for skeleton lists, not a spinner
- [ ] Shimmer uses `context.shimmerColors` (theme-aware), not hardcoded colors

---

## Carousel

- [ ] `autoPlay: !isLoading` — autoplay disabled during skeleton loading
- [ ] Carousel height explicitly set to prevent layout recalculation on load

---

## Rebuild Minimization

- [ ] `const` used on all widgets that don't depend on runtime data
- [ ] `BlocBuilder` scoped as narrowly as possible (wraps only the part that changes)
- [ ] `BlocBuilder.buildWhen` added for expensive widgets with frequent cubit state changes
- [ ] `context.watch<ThemeService>()` only used at `MyApp` level — not inside feature widgets
- [ ] Cubits passed by reference (not re-resolved from DI on every build)

---

## Async & Data Loading

- [ ] `Future.wait()` used for parallel cubit initializations
- [ ] `FlutterNativeSplash.remove()` called only after initial data is ready (in `addPostFrameCallback`)
- [ ] No blocking calls in `build()` methods

---

## Scroll Performance

- [ ] `BouncingScrollPhysics` used on `GridView` / `ListView` inside `CustomScrollView`
- [ ] `shrinkWrap: true` only used with a shared `ScrollController` to prevent double scroll
- [ ] `SliverFillRemaining(hasScrollBody: false)` used for footer (not `Expanded` or `Spacer`)
- [ ] `ClampingScrollWrapper` applied globally via `ResponsiveWrapper` (already done — verify not bypassed)

---

## Memory

- [ ] All `ScrollController`, `AnimationController`, `TabController` disposed in `dispose()`
- [ ] No widgets that subscribe to streams without cancelling in `dispose()`
- [ ] `leak_tracker` warnings reviewed in debug mode before shipping

---

## Responsive

- [ ] No hardcoded pixel widths for layout containers
- [ ] `context.dynamicWidth()` / `context.dynamicHeight()` used for proportional sizing
- [ ] Content respects `MaxWidthBox(maxWidth: 1280)` applied by `ResponsiveWrapper`
