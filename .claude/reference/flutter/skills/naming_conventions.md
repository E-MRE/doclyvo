# Naming Conventions

## File Names

All files use `snake_case.dart`.

```
banner_model.dart
banner_cubit.dart
banner_state.dart
banner_repository.dart
remote_banner_repository.dart
home_screen.dart
home_screen_state_mixin.dart
build_context_extension.dart
app_dependency_register_mixin.dart
```

---

## Class Names

All classes use `PascalCase`.

---

## Concrete Classes — `final class`

```dart
final class BannerModel { ... }
final class BannerCubit extends BaseCubit<BannerState> { ... }
final class RemoteBannerRepository implements BannerRepository { ... }
final class DioNetworkManager extends NetworkService { ... }
final class AppInitializer { ... }
final class HomeScreen extends StatefulWidget { ... }
final class Configurations { ... }
```

---

## Abstract Classes (Interfaces / Bases) — `abstract class`

```dart
abstract class BannerRepository { ... }
abstract class NetworkService { ... }
abstract class AppTheme { ... }
abstract class EntityModel<T> { ... }
abstract class BaseCubit<State> extends Cubit<State> { ... }
abstract class ThemeService extends ChangeNotifier { ... }
abstract class EnvironmentProfile { ... }
abstract class BannerState { ... }  // state base
```

---

## Mixins — `mixin`

```dart
mixin ImageUrlCompleterMixin { ... }
mixin JsonConverterMixin { ... }
mixin PlatformAwareLauncherMixin { ... }
mixin SafeStateMixin<T extends StatefulWidget> on State<T> { ... }
mixin AppDependencyRegisterMixin { ... }
mixin CrashlyticsInitializerMixin { ... }
```

---

## Private Widgets — `_WidgetName`

```dart
final class _SliverAppBar extends StatelessWidget { ... }
final class _FooterView extends StatelessWidget { ... }
final class _FooterSuccessView extends StatelessWidget { ... }
final class _FooterErrorView extends StatelessWidget { ... }
```

Private widgets are defined in the same file as their parent. The `_` prefix signals "not exported, not reusable outside this file."

---

## Screen State Mixin — `_ScreenNameStateMixin`

```dart
mixin _HomeScreenStateMixin on State<HomeScreen> { ... }
```

Always private (prefixed `_`). Lives in `presentation/mixins/<screen_name>_state_mixin.dart`.

---

## Repository Naming

| Type | Pattern | Example |
|------|---------|---------|
| Abstract interface | `XRepository` | `BannerRepository` |
| Remote implementation | `RemoteXRepository` | `RemoteBannerRepository` |

---

## Cubit / State Naming

| Type | Pattern | Example |
|------|---------|---------|
| Cubit | `XCubit` | `BannerCubit` |
| State abstract | `XState` | `BannerState` |
| Initial state | `XInitial` | `BannerInitial` |
| Loading state | `XLoading` | `BannerLoading` |
| Success state | `XSuccess` | `BannerSuccess` |
| Error state | `XError` | `BannerError` |

---

## Model Naming

| Type | Pattern | Example |
|------|---------|---------|
| Model | `XModel` | `BannerModel`, `CampaignModel` |
| Abstract base | `XModel` (abstract) | `CategoryModel` |
| Concrete subtype | `SpecificXModel` | `MainCategoryModel`, `SubCategoryModel` |

---

## Constants Classes

All utility/constant classes end in a descriptive suffix and use `final class`:

```dart
final class Sizes { ... }
final class AppInsets { ... }
final class AppBorderRadius { ... }
final class AppRoundedRectangleBorder { ... }
final class AppConstants { ... }
final class EndpointConstants { ... }
final class ResponsiveConstants { ... }
final class LocalizationConfig { ... }
```

All have a private `const _()` constructor.

---

## Extension Naming

```dart
extension BuildContextExtension on BuildContext { ... }
extension LocalizationExtension on String { ... }
extension CategoryBackgroundExtension on int { ... }
extension TransitionSlideTypeExtension on TransitionSlideType { ... }
extension EnvironmentTypeExtension on EnvironmentType { ... }
```

---

## Enum Naming

```dart
enum ThemeOption { light, dark }
enum EnvironmentType { release, development }
enum TransitionSlideType { topCenter, topRight, right, ... }
enum SpecialKey { empty, dash, space, ... }
enum ShimmerDirection { ltr, rtl, ttb, btt }
```

Enum values use `camelCase`.

---

## Widget File Grouping

```
widgets/
├── carousels/   ← carousel-related widgets
├── sections/    ← section/labeled container widgets
├── grids/       ← grid layout widgets
├── buttons/     ← button components
├── text/        ← text display components
└── slivers/     ← sliver-specific widgets
```

---

## Always / Never

### Always
- `final class` for all concrete classes
- `abstract class` for interfaces and base classes
- `mixin` for cross-cutting behaviors
- `_PrivateName` for private widgets within a file
- `XRepository` / `RemoteXRepository` naming for repositories
- `XCubit` / `XState` / `XInitial` / `XLoading` / `XSuccess` / `XError` for state management
- `snake_case.dart` for all file names

### Never
- `class` (without `final`) for leaf/implementation classes
- `IRepository` or `IService` prefixes for interfaces (not the project convention)
- `BaseX` prefix for abstract classes — just `X` (e.g., `BannerState` not `BaseBannerState`)
- Uppercase file names or `camelCase.dart` file names
