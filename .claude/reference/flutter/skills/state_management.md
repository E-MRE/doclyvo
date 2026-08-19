# State Management

## Pattern Overview

All state management uses **Flutter BLoC — Cubits only** (no full Blocs).  
Every cubit extends `BaseCubit<TState>` from `lib/core/states/base_cubit.dart`.

---

## BaseCubit

```dart
abstract class BaseCubit<State> extends Cubit<State> {
  BaseCubit(super.initialState);

  void safeEmit(State state) {
    if (!isClosed) emit(state);
  }

  Future<void> safeCall<T>({
    required Future<T> Function() action,
    required State loadingState,
    required State Function(T data) successState,
    required State Function(String message) errorState,
    void Function(T data)? onAfterAction,
    void Function(String error)? onAfterError,
    VoidCallback? onBeforeAction,
  }) async {
    try {
      safeEmit(loadingState);
      onBeforeAction?.call();

      final result = await action();

      onAfterAction?.call(result);
      safeEmit(successState(result));
    } on ResponseException catch (e) {
      safeEmit(errorState(e.message));
    } on JsonException catch (e) {
      safeEmit(errorState(e.message));
    } on Exception catch (e) {
      safeEmit(errorState(e.toString()));
    }
  }
}
```

**Key behaviors**:
- `safeEmit()` — guards against emitting after cubit is closed
- `safeCall()` — handles loading → success/error lifecycle automatically
- Catches `ResponseException`, `JsonException`, and generic `Exception`

---

## State Class Pattern

Every feature domain gets **exactly 4 state classes**: `Initial`, `Loading`, `Success`, `Error`.

```dart
// Abstract base
abstract class BannerState {
  const BannerState();
}

// Initial — before any action
final class BannerInitial implements BannerState {
  const BannerInitial();
}

// Loading — action in progress
final class BannerLoading implements BannerState {
  const BannerLoading();
}

// Success — action completed, holds data
final class BannerSuccess implements BannerState {
  const BannerSuccess({required this.banners});
  final List<BannerModel> banners;

  // Computed getters on Success are allowed
  List<String> get bannerImageUrls =>
      banners.map((banner) => banner.fullImageUrl).toList();
}

// Error — action failed, holds message
final class BannerError implements BannerState {
  const BannerError({this.message = ''});
  final String message;
}
```

**Rules for state classes**:
- Abstract base is `abstract class` (not sealed, not freezed)
- All concrete states implement (not extend) the abstract base
- All concrete states are `final class`
- All concrete states have `const` constructors
- `Error` state always has `message` field with default `''`
- `Success` state holds the data (`required` named parameter)
- `Initial`/`Loading` have no fields

---

## Cubit Pattern

```dart
final class BannerCubit extends BaseCubit<BannerState> {
  BannerCubit(this.repository) : super(const BannerInitial());

  final BannerRepository repository;

  Future<void> getBanners() async {
    return safeCall<List<BannerModel>>(
      action: () async => repository.getBanners(),
      loadingState: const BannerLoading(),
      successState: (data) => BannerSuccess(banners: data),
      errorState: (message) => BannerError(message: message),
    );
  }
}
```

**Naming**: `XCubit` for the cubit class, `XState` for the abstract state base.

**File structure** (always 2 files per domain):
```
cubit/banners/
├── banner_cubit.dart
└── banner_state.dart
```

---

## Cubit Registration (DI)

Cubits are **always** registered as `registerFactory` — new instance per resolution:

```dart
injector.registerFactory<BannerCubit>(
  () => BannerCubit(injector.get<BannerRepository>()),
)
```

Cubits must NOT be singletons. Each screen that needs a cubit gets a fresh instance.

---

## Accessing Cubits in Screens

Cubits are retrieved from DI in the screen's `initState` via the state mixin:

```dart
mixin _HomeScreenStateMixin on State<HomeScreen> {
  late final BannerCubit _bannerCubit;

  @override
  void initState() {
    super.initState();
    _bannerCubit = AppDependency.injector.get<BannerCubit>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _bannerCubit.getBanners();
    });
  }
}
```

---

## Providing and Consuming Cubits

### Providing at widget boundary
```dart
BlocProvider(
  create: (_) => bannerCubit,  // inject from parent, don't create here
  child: BlocBuilder<BannerCubit, BannerState>(
    builder: (context, state) { ... },
  ),
)
```

### Consuming state
```dart
BlocBuilder<BannerCubit, BannerState>(
  builder: (context, state) {
    if (state is BannerLoading) {
      return BoxShimmer(width: double.infinity, height: height);
    }
    if (state is BannerError) {
      return BasicErrorContainer(
        height: height,
        width: double.infinity,
        buttonText: LocaleKeys.errors_tryAgain.tr(),
        onPressed: () async => bannerCubit.getBanners(),
        message: state.message,
      );
    }
    if (state is BannerSuccess) {
      return ImageCarouselSlider(
        height: height,
        imageUrls: state.bannerImageUrls,
      );
    }
    return const SizedBox.shrink();
  },
)
```

**Important**: `BlocProvider.create` receives the cubit from outside (from DI). Do NOT call `injector.get<>()` inside `BlocProvider.create`.

---

## Multiple Cubits in One Screen

Cubits are retrieved in `initState` and passed down to child widgets.  
Use `Future.wait` for parallel initialization:

```dart
WidgetsBinding.instance.addPostFrameCallback((_) async {
  FlutterNativeSplash.remove();
  await Future.wait<void>([
    _bannerCubit.getBanners(),
    _campaignCubit.getCampaigns(),
    _companyCubit.getCompanyInfo(),
    _categoryCubit.getCategories(),
  ]);
});
```

---

## Always / Never

### Always
- Extend `BaseCubit<TState>` — never `Cubit<TState>` directly
- Use `safeCall()` for every async operation — never emit manually in try/catch
- Use `safeEmit()` if you must emit outside `safeCall()`
- Create exactly 4 state classes per domain: Initial/Loading/Success/Error
- Keep state classes as plain `final class` — no freezed, no sealed
- Default `''` on Error.message
- Register cubits as `registerFactory` in DI

### Never
- Extend state classes (use `implements`)
- Use freezed or sealed classes for states
- Create singleton cubits
- Call `emit()` directly — use `safeEmit()` or `safeCall()`
- Put UI logic in cubits
- Put business logic in BlocBuilder callbacks
- Call `injector.get<>()` inside `BlocProvider.create`
