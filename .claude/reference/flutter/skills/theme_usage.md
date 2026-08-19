# Theme Usage

## Theme Architecture

```
AppTheme (abstract)
├── LightTheme (class)
└── DarkTheme (class)

ThemeService (abstract ChangeNotifier)
└── ThemeManager (final class, WidgetsBindingObserver)
```

---

## Accessing Theme in Widgets

Always use `BuildContextExtension` shortcuts from `lib/app/extensions/build_context_extension.dart`.

```dart
// Theme object
context.theme               // ThemeData
context.textTheme           // TextTheme
context.colorScheme         // ColorScheme
context.brightness          // Brightness
context.isDarkMode          // bool

// Media
context.mediaQuery          // MediaQueryData
context.screenWidth         // double
context.screenHeight        // double
context.padding             // EdgeInsets (safe area)
context.dynamicWidth(0.5)   // 50% of screen width
context.dynamicHeight(0.3)  // 30% of screen height

// Scaffold
context.scaffoldBackgroundColor

// Theme extensions
context.shimmerColors       // ShimmerColors?
context.themeExtension<T>() // Any registered ThemeExtension
```

**Usage**:
```dart
// CORRECT
Text(
  name,
  style: context.textTheme.titleLarge?.copyWith(
    color: context.colorScheme.onPrimary,
    fontWeight: FontWeight.bold,
  ),
)

// WRONG — do not call Theme.of() directly
Text(
  name,
  style: Theme.of(context).textTheme.titleLarge,
)
```

---

## ColorScheme Usage Guide

The `ColorScheme` maps to semantic UI roles. Use these consistently:

| Color Role | Usage |
|------------|-------|
| `colorScheme.primary` | Primary brand color |
| `colorScheme.onPrimary` | Text/icons on primary background |
| `colorScheme.secondary` | Secondary brand color |
| `colorScheme.onSecondary` | Text/icons on secondary |
| `colorScheme.surface` | Card/modal surfaces |
| `colorScheme.onSurface` | Text on surfaces |
| `colorScheme.onSurfaceVariant` | Link color |
| `colorScheme.error` | Error text/icons |
| `colorScheme.errorContainer` | Error background (`AppColors.lightBase`) |
| `colorScheme.onError` | Text on error container |

---

## TextTheme Usage Guide

Always use `context.textTheme.*` for typography. Never hardcode `fontSize`.

| Style | Use Case |
|-------|----------|
| `textTheme.titleLarge` | Section headers, screen titles |
| `textTheme.titleSmall` | Subsection labels |
| `textTheme.bodyMedium` | Default body text |
| `textTheme.labelMedium` | Secondary/caption text |
| `textTheme.labelSmall` | Very small captions, developer info |

Modifying styles:
```dart
// CORRECT — copyWith for variations
context.textTheme.titleLarge?.copyWith(
  fontWeight: FontWeight.bold,
  color: context.colorScheme.onPrimary,
)

// Only use fontSize from Sizes.* if you must override
context.textTheme.labelSmall?.copyWith(
  fontSize: Sizes.small + Sizes.ultraSmall,  // 10
)
```

---

## ShimmerColors — Theme Extension

`ShimmerColors` is a `ThemeExtension` registered in both light and dark themes.

```dart
// Access
final shimmer = context.shimmerColors;

// Usage in BoxShimmer
Shimmer.fromColors(
  baseColor: shimmer?.baseColor ?? context.colorScheme.onSurface,
  highlightColor: shimmer?.highlightColor ?? context.colorScheme.surface,
  child: ...,
)
```

Light values: `AppColors.lightBase`, `AppColors.lightHighlight`  
Dark values: `AppColors.darkBase`, `AppColors.darkHighlight`

---

## Theme Switching

Handled by `ThemeManager`. No manual switching needed in features.

```dart
// ThemeManager auto-detects platform brightness
// and responds to WidgetsBindingObserver.didChangePlatformBrightness()

// If manually switching from UI:
context.read<ThemeService>().setTheme(LightTheme());
context.read<ThemeService>().setTheme(DarkTheme());
```

Theme is provided at app root via `ChangeNotifierProvider<ThemeService>`.  
Feature widgets should `context.watch<ThemeService>()` only when they need to react to theme changes.

---

## AppColors — Static Color Reference

From `lib/generated/colors.gen.dart` (generated from `assets/colors/colors.xml`).

```dart
AppColors.primary          // base primary (used in light theme)
AppColors.primaryLight     // light variant
AppColors.primaryDark      // dark variant
AppColors.onPrimary        // white — used on any primary background
AppColors.lightBackground
AppColors.darkBackground
AppColors.lightSecondary
AppColors.darkSecondary
AppColors.lightOnSecondary
AppColors.darkOnSecondary
AppColors.lightOnSurface
AppColors.darkOnSurface
AppColors.darkSurface
AppColors.lightError
AppColors.lightLink
AppColors.darkLink
AppColors.lightBase         // shimmer base (light)
AppColors.lightHighlight    // shimmer highlight (light)
AppColors.darkBase          // shimmer base (dark)
AppColors.darkHighlight     // shimmer highlight (dark)
```

**Rule**: `AppColors.*` is for theme definitions (`LightTheme`, `DarkTheme`).  
In feature widgets, prefer `context.colorScheme.*` for theme-aware behavior.

---

## Defining New Theme Extensions

Pattern from `ShimmerColors`:

```dart
@immutable
class MyExtension extends ThemeExtension<MyExtension> {
  const MyExtension({required this.someColor});

  final Color someColor;

  @override
  MyExtension copyWith({Color? someColor}) {
    return MyExtension(someColor: someColor ?? this.someColor);
  }

  @override
  MyExtension lerp(ThemeExtension<MyExtension>? other, double t) {
    if (other is! MyExtension) return this;
    return MyExtension(
      someColor: Color.lerp(someColor, other.someColor, t)!,
    );
  }
}
```

Register in both `LightTheme.themeData` and `DarkTheme.themeData`:
```dart
extensions: const [
  ShimmerColors(...),
  MyExtension(...),
],
```

Access:
```dart
context.themeExtension<MyExtension>()?.someColor
```

---

## Always / Never

### Always
- Use `context.textTheme.*` for typography
- Use `context.colorScheme.*` for semantic colors in widgets
- Use `context.shimmerColors` for shimmer colors
- Use `context.isDarkMode` for conditional dark mode logic
- Use `context.dynamicWidth()` / `context.dynamicHeight()` for proportional sizing

### Never
- Call `Theme.of(context)` directly — use `context.theme`
- Hardcode `Color(0xFF...)` or `Colors.*` in feature widgets
- Hardcode `fontSize` values — use `Sizes.*` if override is needed
- Use `MediaQuery.of(context)` directly — use `context.mediaQuery`
