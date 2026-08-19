# Dependency Injection

## Architecture Overview

GetIt is the underlying DI framework, but it is **fully abstracted behind interfaces**. Feature code never imports GetIt directly.

```
DependencyInjector (abstract interface)
└── GetItDependencyInjector (final class — wraps GetIt.instance)

DependencyInjectionService (abstract)
└── GetItDependencyInjectionManager (final class, singleton factory)

AppDependency (final class — global access point)
```

---

## Global Access

```dart
// app_dependency.dart
CrashlyticsService get kCrashlytics =>
    AppDependency.injector.get<CrashlyticsService>();

final class AppDependency {
  static DependencyInjectionService get dependency =>
      GetItDependencyInjectionManager();

  static DependencyInjector get injector =>
      GetItDependencyInjectionManager().injector;

  static T getEnvironment<T extends EnvironmentProfile>() =>
      injector.get<T>();
}
```

**Usage throughout the codebase**:
```dart
// Resolve a dependency anywhere
AppDependency.injector.get<BannerCubit>()
AppDependency.injector.get<NetworkService>()
AppDependency.injector.get<CrashlyticsService>()

// Short form for crashlytics
kCrashlytics.recordFlutterError(details)
```

---

## Registration

All registrations happen in `AppDependencyRegisterMixin`:  
File: `lib/app/utils/mixins/app_dependency_register_mixin.dart`

```dart
mixin AppDependencyRegisterMixin {
  void registerDependencies(DependencyInjector injector) {
    _registerDependencies(injector);       // 1. Core services
    _registerNetwork(injector);            // 2. Network
    if (Configurations.isDevelopment) {
      _registerDevelopmentDependencies(injector);  // 3a. Dev environment
    } else {
      _registerReleaseDependencies(injector);       // 3b. Release environment
    }
    _registerPostDependencies(injector);  // 4. Repositories + Cubits
  }

  void _registerNetwork(DependencyInjector injector) {
    injector
      ..registerFactory<Dio>(() => Dio(BaseOptions(
        baseUrl: Configurations.environmentProfile.baseUrl,
        connectTimeout: const Duration(seconds: 32),
        receiveTimeout: const Duration(seconds: 32),
        sendTimeout: const Duration(seconds: 32),
      )))
      ..registerSingleton<NetworkService>(
        DioNetworkManager(injector.get<Dio>()),
      );
  }

  void _registerRepositories(DependencyInjector injector) {
    injector
      ..registerFactory<BannerRepository>(
        () => RemoteBannerRepository(injector.get<NetworkService>()),
      )
      ..registerFactory<CampaignRepository>(
        () => RemoteCampaignRepository(injector.get<NetworkService>()),
      );
  }

  void _registerCubits(DependencyInjector injector) {
    injector
      ..registerFactory<BannerCubit>(
        () => BannerCubit(injector.get<BannerRepository>()),
      )
      ..registerFactory<CampaignCubit>(
        () => CampaignCubit(injector.get<CampaignRepository>()),
      );
  }
}
```

---

## Registration Types

| Type | Method | When to Use |
|------|--------|-------------|
| New instance per call | `registerFactory<T>(() => ...)` | Cubits, Repositories |
| One instance forever | `registerSingleton<T>(instance)` | NetworkService, CrashlyticsService |
| Lazy singleton | `registerLazySingleton<T>(() => ...)` | Heavy services created on first use |

**Cubits**: Always `registerFactory` — every resolution gets a new fresh cubit.  
**Repositories**: Always `registerFactory` — lightweight, safe to recreate.  
**NetworkService**: `registerSingleton` — single shared instance.  
**CrashlyticsService**: `registerSingleton` — single shared instance.  
**EnvironmentProfile**: `registerSingleton` — fixed at startup.

---

## DependencyInjector Interface

The abstract interface exposes only what is needed:

```dart
abstract class DependencyInjector {
  T get<T extends Object>({String? instanceName, dynamic param1, dynamic param2, Type? type});
  void registerFactory<T extends Object>(FactoryFunc<T> factoryFunc, {String? instanceName});
  T registerSingleton<T extends Object>(T instance, {String? instanceName, bool? signalsReady, DisposingFunc<T>? dispose});
  void registerLazySingleton<T extends Object>(FactoryFunc<T> factoryFunc, {String? instanceName, DisposingFunc<T>? dispose});
  bool isRegistered<T extends Object>({Object? instance, String? instanceName});
  Future<void> reset({bool dispose = true});
  FutureOr<dynamic> resetLazySingleton<T extends Object>({...});
  FutureOr<dynamic> unregister<T extends Object>({...});
}
```

---

## Adding a New Feature's Dependencies

When adding a new feature, register it in `AppDependencyRegisterMixin._registerPostDependencies`:

```dart
void _registerRepositories(DependencyInjector injector) {
  injector
    // ... existing registrations
    ..registerFactory<NewFeatureRepository>(
      () => RemoteNewFeatureRepository(injector.get<NetworkService>()),
    );
}

void _registerCubits(DependencyInjector injector) {
  injector
    // ... existing registrations
    ..registerFactory<NewFeatureCubit>(
      () => NewFeatureCubit(injector.get<NewFeatureRepository>()),
    );
}
```

---

## GetItDependencyInjectionManager Singleton Pattern

```dart
final class GetItDependencyInjectionManager extends DependencyInjectionService {
  factory GetItDependencyInjectionManager() => _instance;

  GetItDependencyInjectionManager._internal()
      : super(injector: GetItDependencyInjector());

  static final GetItDependencyInjectionManager _instance =
      GetItDependencyInjectionManager._internal();
}
```

Uses the `factory` constructor singleton pattern — every `GetItDependencyInjectionManager()` call returns the same instance.

---

## Always / Never

### Always
- Use `AppDependency.injector.get<T>()` to resolve dependencies
- Add new registrations in `AppDependencyRegisterMixin`
- Register cubits as `registerFactory`
- Register shared services as `registerSingleton`
- Depend on abstract interfaces (e.g., `BannerRepository`), not concrete implementations

### Never
- Import `get_it` directly in feature code — always use `AppDependency.injector`
- Register cubits as singletons
- Resolve dependencies in widget `build()` — resolve in `initState` or mixin
- Create DI registrations scattered across feature files
