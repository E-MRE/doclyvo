# Code Review Checklist

Use this checklist when reviewing any PR or generated code in this repository.

---

## Class & File Structure

- [ ] All concrete classes declared as `final class`
- [ ] Abstract interfaces and base classes declared as `abstract class`
- [ ] Mixins declared with `mixin`, not `abstract class`
- [ ] One top-level public class per file
- [ ] Private sub-classes use `_WidgetName` prefix
- [ ] Utility/constants classes have `const ._()` private constructor
- [ ] Constructor appears before fields in class body (`sort_constructors_first`)
- [ ] `@override` present on all interface/base implementations

---

## Const & Immutability

- [ ] `const` constructor on all models
- [ ] All model fields are `final`
- [ ] All model fields have default values (enables `const Model()` for skeletons)
- [ ] Named parameters with defaults in all model constructors (no positional params)
- [ ] `const` used on all widget instantiations that are possible
- [ ] `super.key` present in all widget constructors

---

## Design System Compliance

- [ ] No inline `SizedBox(height:)` or `SizedBox(width:)` — using `EmptySize.*`
- [ ] No inline `EdgeInsets.*` — using `AppInsets.*`
- [ ] No inline `BorderRadius.circular()` — using `AppBorderRadius.*`
- [ ] No `Colors.*` or `Color(0xFF...)` inline in widgets — using `context.colorScheme.*`
- [ ] No `Image.network()` — using `CachedImage`
- [ ] No `Theme.of(context)` directly — using `context.theme`
- [ ] No `MediaQuery.of(context)` directly — using `context.mediaQuery` / `context.screenWidth`
- [ ] No raw numbers for spacing/sizing — using `Sizes.*`
- [ ] Sliver spacing uses `SliverEmptySize.*`, not `EmptySize.*`

---

## State Management

- [ ] States use plain `final class implements XState`, NOT freezed or sealed
- [ ] All 4 state variants present: `XInitial`, `XLoading`, `XSuccess`, `XError`
- [ ] Cubit extends `BaseCubit<State>`, not `Cubit<State>` directly
- [ ] Cubit uses `safeCall()`, not raw try/catch with `emit()`
- [ ] `safeEmit()` used instead of raw `emit()` when called outside `safeCall`
- [ ] `BlocProvider.create` receives a pre-resolved cubit, not `AppDependency.injector.get<>()`

---

## Dependency Injection

- [ ] Cubit registered with `registerFactory` (not `registerSingleton`)
- [ ] Repository registered with `registerFactory`
- [ ] DI resolution in `initState`, not in `build()`
- [ ] `late final` used for cubit/controller fields resolved in `initState`

---

## Navigation

- [ ] No `Navigator.push()` — using `context.push()` / `context.go()`
- [ ] No `MaterialPage` — using `TransitionPageBuilder.*`
- [ ] New routes added to `app_router.dart`

---

## Network & Data Layer

- [ ] `response.isSuccess` checked before returning data
- [ ] `ResponseException(response.message)` thrown when `!response.isSuccess`
- [ ] No raw Dio usage in repositories — using `NetworkService`
- [ ] No hardcoded endpoint strings — using `EndpointConstants.*`
- [ ] No hardcoded base URL — using `Configurations.environmentProfile.baseUrl`
- [ ] `fullImageUrl` used for display, not `imageUrl` (bare relative path)

---

## Models

- [ ] `@JsonSerializable()` annotation present
- [ ] `part '<entity>_model.g.dart'` directive present
- [ ] `implements EntityModel<T>` present
- [ ] `fromJson` factory and `toJson` method present
- [ ] `build_runner` run after model changes

---

## Widget Lifecycle

- [ ] Cubit/controller initialization in `initState`, not `build()`
- [ ] `addPostFrameCallback` used for post-render side effects
- [ ] All controllers disposed in `dispose()`
- [ ] `SafeStateMixin` used when `setState` is called from async context
- [ ] No `setState` without `mounted` check

---

## Async Patterns

- [ ] `Future.wait()` used for parallel async calls (not sequential `await`)
- [ ] No sequential awaits that could run in parallel

---

## Localization

- [ ] All user-visible text uses `LocaleKeys.*` constants + `.tr()` or `.translate()`
- [ ] No hardcoded display strings
- [ ] New translation keys added to `assets/translations/tr-TR.json`

---

## Logging

- [ ] No `print()` — using `debugPrint()` for debug logs
- [ ] Production errors reported via `kCrashlytics`

---

## Architecture Integrity

- [ ] No cross-feature imports (`features/x` not importing from `features/y`)
- [ ] No cubit calling `NetworkService` directly (must go through repository)
- [ ] No business logic in widget `build()` methods
- [ ] Screen uses `StatefulWidget` + `_ScreenNameStateMixin` pattern
