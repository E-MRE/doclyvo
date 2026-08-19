# Responsive Rules

## Framework

The project uses two responsive packages:
- `responsive_framework: ^1.5.1` — breakpoints, max width box, scaled box
- `responsive_builder: ^0.7.1` — builder utilities

---

## Breakpoints

Defined in `lib/app/constants/responsive_constants.dart`:

```dart
final class ResponsiveConstants {
  static const int minScreenWidth = 450;
  static const double maxScreenWidth = 1280;

  static const List<Breakpoint> breakpoints = [
    Breakpoint(start: 0, end: 450, name: MOBILE),
    Breakpoint(start: 451, end: 1194, name: TABLET),
    Breakpoint(start: 1195, end: 1920, name: DESKTOP),
    Breakpoint(start: 1921, end: double.infinity, name: '4K'),
  ];

  static const List<Breakpoint> landscapeBreakpoints = [
    Breakpoint(start: 0, end: 600, name: MOBILE),
    Breakpoint(start: 601, end: 1920, name: TABLET),
    Breakpoint(start: 1921, end: 2160, name: DESKTOP),
    Breakpoint(start: 2161, end: double.infinity, name: '4K'),
  ];
}
```

---

## ResponsiveWrapper

File: `lib/app/widgets/wrappers/responsive_wrapper.dart`

Applied as a `builder` in `MaterialApp.router`:

```dart
MaterialApp.router(
  builder: (context, child) {
    return ResponsiveWrapper(child: child ?? const SizedBox.shrink());
  },
)
```

Internally:
```dart
final class ResponsiveWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveBreakpoints.builder(
      debugLog: kDebugMode,
      useShortestSide: useShortestSide,
      child: MaxWidthBox(
        maxWidth: ResponsiveConstants.maxScreenWidth,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Builder(
          builder: (context) {
            return ResponsiveScaledBox(
              width: _getWidth(context).value,  // conditionalValues
              child: ClampingScrollWrapper.builder(context, child),
            );
          },
        ),
      ),
      breakpoints: ResponsiveConstants.breakpoints,
      breakpointsLandscape: ResponsiveConstants.landscapeBreakpoints,
    );
  }
}
```

---

## Conditional Width Values

The scaled box uses conditional width values to ensure consistent layout:

```dart
static const List<Condition<double>> conditionalValues = [
  Condition.between(start: 0, end: 450, value: 450, landscapeValue: 1194),
  Condition.equals(name: MOBILE, value: 450, landscapeValue: 1194),
  Condition.between(start: 451, end: 1194, value: 1194, landscapeValue: 1194),
  Condition.equals(name: TABLET, value: 1194, landscapeValue: 1194),
  Condition.largerThan(breakpoint: 1194, name: DESKTOP, value: 1194, landscapeValue: 1194),
];
```

This means:
- Mobile portrait → 450px logical width
- Everything tablet and above → 1194px logical width
- Max content width → 1280px

---

## Dynamic Sizing in Widgets

Use `BuildContextExtension` for proportional sizing:

```dart
// 50% of screen width
width: context.dynamicWidth(0.5)

// Full width minus padding
width: context.dynamicWidth(1.0)

// 30% of screen height
height: context.dynamicHeight(0.3)
```

Used in practice for shimmer sizing:
```dart
BoxShimmer(
  width: context.dynamicWidth(.5),     // shimmer for title
  height: context.textTheme.titleLarge?.fontSize,
  borderRadius: Sizes.xSmall,
)
```

---

## Breakpoint-Aware Layout

To conditionally render based on breakpoint:
```dart
// Using responsive_framework
ResponsiveBreakpoints.of(context).isMobile
ResponsiveBreakpoints.of(context).isTablet
ResponsiveBreakpoints.of(context).isDesktop
ResponsiveBreakpoints.of(context).largerThan(MOBILE)
```

---

## Always / Never

### Always
- Use `context.dynamicWidth()` / `context.dynamicHeight()` for percentage-based sizing
- Use `context.screenWidth` / `context.screenHeight` for absolute screen dimensions
- Let `ResponsiveWrapper` handle breakpoint detection — it's applied globally

### Never
- Hardcode pixel widths for layout containers
- Use `MediaQuery.of(context).size.width` directly — use `context.screenWidth`
- Bypass `ResponsiveWrapper` by rendering full-screen content without constraints
