# Navigation

## Router Setup

File: `lib/app/app_router.dart`

Uses `go_router` package. The router is a top-level `final` variable:

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (_, __) {
        return TransitionPageBuilder.fadeTransition(
          child: const HomeScreen(),
        );
      },
    ),
  ],
);
```

The router is passed to `MaterialApp.router(routerConfig: router)`.

---

## Page Transitions — TransitionPageBuilder

File: `lib/app/utils/builders/transition_page_builder.dart`

All route transitions go through `TransitionPageBuilder`. Never use `MaterialPage` directly.

### Available transitions

```dart
// Fade transition (default for most screens)
TransitionPageBuilder.fadeTransition(
  child: const HomeScreen(),
  curve: Curves.easeInOutCirc,  // default
)

// Slide transition
TransitionPageBuilder.slideTransition(
  child: const DetailScreen(),
  slide: TransitionSlideType.right,  // default
)

// Scale transition
TransitionPageBuilder.scaleTransition(
  child: const ModalScreen(),
  alignment: Alignment.bottomCenter,
  quality: FilterQuality.high,
)
```

### TransitionSlideType options

```dart
TransitionSlideType.topCenter     // slides from top center
TransitionSlideType.topRight      // slides from top right
TransitionSlideType.topLeft       // slides from top left
TransitionSlideType.bottomCenter  // slides from bottom center
TransitionSlideType.bottomRight   // slides from bottom right
TransitionSlideType.bottomLeft    // slides from bottom left
TransitionSlideType.left          // slides from left
TransitionSlideType.right         // slides from right (default)
```

---

## Adding a New Route

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (_, __) => TransitionPageBuilder.fadeTransition(
        child: const HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/detail/:id',
      pageBuilder: (context, state) => TransitionPageBuilder.slideTransition(
        child: DetailScreen(id: state.pathParameters['id'] ?? ''),
        slide: TransitionSlideType.right,
      ),
    ),
  ],
);
```

---

## Navigation Calls

```dart
// Push (navigate forward)
context.push('/detail/123');

// Replace current route
context.replace('/home');

// Go to route (clears stack)
context.go('/');

// Pop
context.pop();
```

---

## Always / Never

### Always
- Use `TransitionPageBuilder.*` for page transitions in `pageBuilder`
- Define all routes in `lib/app/app_router.dart`
- Use path parameters for dynamic routes

### Never
- Use `MaterialPage` directly — always use `TransitionPageBuilder`
- Use `Navigator.push()` or `Navigator.pushNamed()` — use `context.push()` / `context.go()`
- Scatter route definitions across feature files
