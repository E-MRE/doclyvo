# Design System

## Overview

The project uses a fully centralized design system. Every sizing, spacing, border radius, shape, decoration, and color value has a named constant. **Never use raw numbers or `Colors.*` inline.**

---

## Spacing Scale — `Sizes`

File: `lib/core/utils/constants/sizes.dart`

4-based scale from 0 to 480. All sizes are named semantically.

```dart
Sizes.none          // 0
Sizes.ultraSmall    // 2
Sizes.xSmall        // 4
Sizes.small         // 8
Sizes.smallMedium   // 12
Sizes.medium        // 16
Sizes.mediumLarge   // 20
Sizes.large         // 24
Sizes.largePlus     // 28
Sizes.xLarge        // 32
Sizes.xLargePlus    // 36
Sizes.xxLarge       // 40
Sizes.xxLargePlus   // 44
Sizes.xxxLarge      // 48
Sizes.huge          // 56
Sizes.gigantic      // 64
Sizes.colossal      // 80
Sizes.massive       // 96
Sizes.enormous      // 112
Sizes.mega          // 128
Sizes.ultra         // 160
Sizes.hugePlus      // 192
Sizes.enormousPlus  // 224
Sizes.giganticPlus  // 256
Sizes.titan         // 288
Sizes.olympian      // 320
// ... up to Sizes.ultimate = 480
```

**Usage**: Always use `Sizes.*` when passing a `double` for layout dimensions.

```dart
// CORRECT
height: Sizes.mega          // 128
height: Sizes.giganticPlus  // 256
borderRadius: Sizes.smallMedium  // 12

// WRONG
height: 128
height: 256
borderRadius: 12
```

---

## Edge Insets — `AppInsets`

File: `lib/core/utils/constants/app_insets.dart`

Pre-defined `EdgeInsets` constants for padding/margin. All reference `Sizes.*`.

### All-sides
```dart
AppInsets.none       // EdgeInsets.zero
AppInsets.xSmall     // EdgeInsets.all(4)
AppInsets.small      // EdgeInsets.all(8)
AppInsets.medium     // EdgeInsets.all(16)
AppInsets.large      // EdgeInsets.all(24)
AppInsets.xLarge     // EdgeInsets.all(32)
AppInsets.xxLarge    // EdgeInsets.all(40)
AppInsets.xxxLarge   // EdgeInsets.all(48)
```

### Horizontal / Vertical
```dart
AppInsets.smallHorizontal   // horizontal: 8
AppInsets.mediumHorizontal  // horizontal: 16
AppInsets.largeHorizontal   // horizontal: 24
AppInsets.xLargeHorizontal  // horizontal: 32

AppInsets.smallVertical     // vertical: 8
AppInsets.mediumVertical    // vertical: 16
AppInsets.largeVertical     // vertical: 24
AppInsets.xLargeVertical    // vertical: 32
```

### Symmetric
```dart
AppInsets.symmetricSmall    // h:8, v:8
AppInsets.symmetricMedium   // h:16, v:16
AppInsets.symmetricLarge    // h:24, v:24
AppInsets.symmetricXLarge   // h:32, v:32
```

### Single Side
```dart
AppInsets.topSmall
AppInsets.bottomSmall
AppInsets.leftSmall
AppInsets.rightSmall
```

**Usage**:
```dart
// CORRECT
padding: AppInsets.mediumHorizontal
padding: AppInsets.small
padding: AppInsets.xLargeVertical

// WRONG
padding: EdgeInsets.symmetric(horizontal: 16)
padding: EdgeInsets.all(8)
```

---

## Border Radius — `AppBorderRadius`

File: `lib/core/utils/constants/app_border_radius.dart`

Pre-defined `BorderRadius` constants matching `Sizes.*` values.

```dart
AppBorderRadius.xSmall          // BorderRadius.circular(4)
AppBorderRadius.small           // BorderRadius.circular(8)
AppBorderRadius.smallMedium     // BorderRadius.circular(12)
AppBorderRadius.medium          // BorderRadius.circular(16)
// ... full range available
AppBorderRadius.verticalTopMedium  // only top corners rounded at medium
```

**Usage**:
```dart
// CORRECT
borderRadius: AppBorderRadius.medium
borderRadius: AppBorderRadius.verticalTopMedium

// WRONG
borderRadius: BorderRadius.circular(16)
```

---

## Shapes — `AppRoundedRectangleBorder`

File: `lib/core/utils/constants/app_rounded_rectangle_border.dart`

Pre-defined `RoundedRectangleBorder` shapes for cards and buttons.

```dart
AppRoundedRectangleBorder.small
AppRoundedRectangleBorder.medium
AppRoundedRectangleBorder.large
// etc.
```

**Usage**:
```dart
// CORRECT
Card(shape: AppRoundedRectangleBorder.medium, ...)

// WRONG
Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), ...)
```

---

## Spacing Widgets — `EmptySize`

File: `lib/core/utils/constants/empty_size.dart`

Pre-configured `SizedBox` widgets for vertical and horizontal gaps.

```dart
EmptySize.xSmallHeight     // SizedBox(height: 4)
EmptySize.smallHeight      // SizedBox(height: 8)
EmptySize.mediumHeight     // SizedBox(height: 16)
EmptySize.largeHeight      // SizedBox(height: 24)
EmptySize.xLargeHeight     // SizedBox(height: 32)

EmptySize.xSmallWidth      // SizedBox(width: 4)
EmptySize.smallWidth       // SizedBox(width: 8)
EmptySize.mediumWidth      // SizedBox(width: 16)
EmptySize.largeWidth       // SizedBox(width: 24)
```

**Usage in `Column`/`Row`**:
```dart
// CORRECT
Column(
  children: [
    Text('Hello'),
    EmptySize.smallHeight,
    Text('World'),
  ],
)

// WRONG
Column(
  children: [
    Text('Hello'),
    SizedBox(height: 8),
    Text('World'),
  ],
)
```

---

## Sliver Spacing Widgets — `SliverEmptySize`

File: `lib/core/utils/constants/sliver_empty_size.dart`

Pre-configured `SliverToBoxAdapter` widgets for sliver context spacing.

```dart
SliverEmptySize.smallHeight
SliverEmptySize.mediumHeight
SliverEmptySize.largeHeight
SliverEmptySize.xLargeHeight
```

**Usage in `CustomScrollView`**:
```dart
// CORRECT
CustomScrollView(
  slivers: [
    _SliverAppBar(_bannerCubit),
    SliverEmptySize.largeHeight,
    SliverToBoxAdapter(child: CampaignLabelSection(...)),
    SliverEmptySize.xLargeHeight,
  ],
)

// WRONG
CustomScrollView(
  slivers: [
    _SliverAppBar(_bannerCubit),
    SliverToBoxAdapter(child: SizedBox(height: 24)),
    ...
  ],
)
```

---

## Colors — `AppColors`

File: `lib/generated/colors.gen.dart` (generated from `assets/colors/colors.xml`)

```dart
AppColors.primary
AppColors.primaryLight
AppColors.primaryDark
AppColors.onPrimary
AppColors.lightBackground
AppColors.darkBackground
AppColors.lightSecondary
AppColors.darkSecondary
AppColors.lightError
// etc.
```

**Rule**: Never use `Color(0xFF...)` or `Colors.*` inline for semantic UI colors.  
Use `AppColors.*` for static colors, or `context.colorScheme.*` for theme-aware colors.

---

## Decorations — `AppDecorations`

File: `lib/core/utils/decorations/box_decorations.dart`

```dart
AppDecorations.indicator(color: someColor)
AppDecorations.shimmer(color: shimmerBase, borderRadius: ...)
```

**Usage**:
```dart
Container(
  decoration: AppDecorations.shimmer(
    color: shimmer?.baseColor,
    borderRadius: BorderRadius.circular(borderRadius),
  ),
)
```

---

## Shimmer Theme Extension — `ShimmerColors`

File: `lib/app/theme/extensions/shimmer_colors.dart`

Accessed via `context.shimmerColors`.

```dart
final shimmer = context.shimmerColors;
baseColor: shimmer?.baseColor ?? context.colorScheme.onSurface
highlightColor: shimmer?.highlightColor ?? context.colorScheme.surface
```

Defined in theme:
- `LightTheme`: `baseColor: AppColors.lightBase`, `highlightColor: AppColors.lightHighlight`
- `DarkTheme`: `baseColor: AppColors.darkBase`, `highlightColor: AppColors.darkHighlight`

---

## Always / Never

### Always
- Use `Sizes.*` for all dimension values
- Use `AppInsets.*` for all padding/margin
- Use `AppBorderRadius.*` for all border radii
- Use `AppRoundedRectangleBorder.*` for card/container shapes
- Use `EmptySize.*` in Column/Row for gaps (not `SizedBox`)
- Use `SliverEmptySize.*` in `CustomScrollView` for gaps
- Use `AppColors.*` or `context.colorScheme.*` for colors
- Use `context.shimmerColors` to read shimmer theme colors

### Never
- `EdgeInsets.all(16)` or `EdgeInsets.symmetric(horizontal: 8)` — use AppInsets
- `SizedBox(height: 8)` — use EmptySize.smallHeight
- `BorderRadius.circular(12)` — use AppBorderRadius.smallMedium
- `Colors.red` or `Color(0xFF...)` inline in UI widgets
- Raw integer/double literals for layout
