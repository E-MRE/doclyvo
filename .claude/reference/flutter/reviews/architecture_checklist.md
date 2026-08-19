# Architecture Checklist

Use when adding a new feature, new screen, or modifying the data layer.

---

## Layer Boundaries

- [ ] Repository layer exists between cubit and network (no direct `NetworkService` in cubit)
- [ ] Abstract repository interface + `Remote*` implementation created as a pair
- [ ] Cubit depends only on the abstract repository interface, never the concrete class
- [ ] No feature importing from another feature (`features/x` → `features/y` is forbidden)
- [ ] Shared cross-feature code lives in `lib/app/` or `lib/core/`, not in a feature folder

---

## Dependency Injection

- [ ] New repository registered with `registerFactory` in `AppDependencyRegisterMixin._registerRepositories()`
- [ ] New cubit registered with `registerFactory` in `AppDependencyRegisterMixin._registerCubits()`
- [ ] No `registerSingleton` for cubits (they are stateful — always factory)
- [ ] `NetworkService` injected via `injector.get<NetworkService>()`, not instantiated directly
- [ ] All DI registrations added before any usage (initialization order respected)

---

## Feature Structure Completeness

- [ ] Model file exists with `@JsonSerializable()` + `implements EntityModel<T>`
- [ ] `*.g.dart` file generated (build_runner has been run)
- [ ] Abstract repository interface exists
- [ ] Remote implementation exists
- [ ] State file has all 4 state classes: `XInitial`, `XLoading`, `XSuccess`, `XError`
- [ ] Cubit file exists extending `BaseCubit<XState>`
- [ ] Screen file uses `StatefulWidget`
- [ ] Screen state mixin file exists in `presentation/mixins/`
- [ ] Route registered in `app_router.dart`
- [ ] Endpoint constant added to `EndpointConstants`

---

## State Design

- [ ] State base class is `abstract class XState { const XState(); }`
- [ ] State variants are `final class XVariant implements XState`
- [ ] No freezed, no sealed classes for states
- [ ] `XSuccess` carries its data as `final` fields with `required` named params
- [ ] `XError` carries a `final String message`
- [ ] `XLoading` and `XInitial` are parameter-free with `const` constructor

---

## Cubit Design

- [ ] Extends `BaseCubit<XState>`, not `Cubit<XState>` directly
- [ ] `safeCall<TData>()` used for every async operation
- [ ] No raw `try/catch` + `emit()` patterns
- [ ] Constructor accepts abstract repository, not concrete implementation
- [ ] Cubit is not a singleton — no shared state between screens

---

## Screen Design

- [ ] `StatefulWidget` + `_ScreenNameStateMixin` pattern used
- [ ] DI resolution (`AppDependency.injector.get<Cubit>()`) in `initState`, not `build()`
- [ ] `late final` used for cubit fields
- [ ] `addPostFrameCallback` used for initial data load
- [ ] `Future.wait()` used when loading multiple cubits simultaneously
- [ ] `dispose()` releases all controllers

---

## Navigation

- [ ] Route defined with `TransitionPageBuilder.*` (not `MaterialPage`)
- [ ] `context.push()` / `context.go()` used (not `Navigator.push()`)
- [ ] Deep linking considered for new routes (path parameters if needed)

---

## Error Handling

- [ ] `ResponseException` thrown when `!response.isSuccess`
- [ ] `JsonException` propagated (handled by `safeCall` automatically)
- [ ] `BasicErrorContainer` used in UI for error states (with retry callback)
- [ ] Retry callback is `() async => cubit.method()` (not inline business logic)

---

## Crashlytics & Observability

- [ ] `kCrashlytics` used for non-user-facing error logging (not `debugPrint` alone)
- [ ] Flutter error handler registered at app root (already done in `AppInitializer`)
- [ ] No sensitive data logged to crashlytics
