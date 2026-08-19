# Coding Standards

## Enforced by `very_good_analysis` + Custom Rules

The project uses `very_good_analysis: ^10.0.0` as the analysis baseline.  
Custom overrides are in `analysis_options.yaml`.

```yaml
linter:
  rules:
    avoid_print: true
    prefer_single_quotes: true
    always_declare_return_types: true
    avoid_empty_else: true
    depend_on_referenced_packages: false
    public_member_api_docs: false
    sort_constructors_first: true
    prefer_const_constructors: true
    lines_longer_than_80_chars: false
    one_member_abstracts: false
```

---

## Class Declaration Rules

### Use `final class` for All Concrete Classes

Every concrete class that is not intended to be subclassed MUST be declared `final class`.

```dart
// CORRECT
final class BannerCubit extends BaseCubit<BannerState> { ... }
final class RemoteBannerRepository implements BannerRepository { ... }
final class DioNetworkManager extends NetworkService { ... }
final class AppInitializer with CrashlyticsInitializerMixin { ... }

// WRONG
class BannerCubit extends BaseCubit<BannerState> { ... }
class RemoteBannerRepository implements BannerRepository { ... }
```

### Use `abstract class` for Interfaces and Base Classes

```dart
// CORRECT
abstract class BannerRepository { ... }
abstract class NetworkService { ... }
abstract class AppTheme { ... }
abstract class EntityModel<T extends EntityModel<T>> { ... }
```

### Use `mixin` for Cross-Cutting Behaviors

```dart
// CORRECT
mixin ImageUrlCompleterMixin { ... }
mixin JsonConverterMixin { ... }
mixin PlatformAwareLauncherMixin { ... }
mixin SafeStateMixin<T extends StatefulWidget> on State<T> { ... }
```

### Use `enum` for Fixed Value Sets

```dart
enum SpecialKey { empty(''), dash('-'), ... }
enum ThemeOption { light, dark }
enum TransitionSlideType { topCenter, bottomCenter, left, right, ... }
```

---

## Constructor Rules

### `sort_constructors_first: true`

Constructor ALWAYS comes before fields.

```dart
// CORRECT
final class BannerModel {
  const BannerModel({this.imageUrl = ''});  // ← constructor first
  final String imageUrl;                     // ← fields after
}

// WRONG
final class BannerModel {
  final String imageUrl;
  const BannerModel({this.imageUrl = ''});
}
```

### `prefer_const_constructors: true`

Use `const` wherever possible. All models and pure widgets must have `const` constructors.

```dart
// CORRECT
const BannerModel()
const BannerInitial()
const BoxShimmer(width: 100, height: 50)

// WRONG
BannerModel()   // when no mutable state
BannerInitial() // when no fields
```

### Default Values for All Model Fields

Every model field must have a default value to ensure safe `const` construction.

```dart
// CORRECT
final class CampaignModel {
  const CampaignModel({
    this.title = '',
    this.description = '',
    this.price = 0,
    this.imageUrl = '',
  });
  final String title;
  final String description;
  final double price;
  final String imageUrl;
}
```

---

## String Literals

Always use **single quotes**.

```dart
// CORRECT
final String path = 'assets/translations';
static const String banners = '${_apiV1}Banner';

// WRONG
final String path = "assets/translations";
```

---

## Return Types

Always declare explicit return types. Never use `var` for function return types.

```dart
// CORRECT
Future<void> getBanners() async { ... }
Widget build(BuildContext context) { ... }
List<Widget> _buildItems() { ... }
CarouselOptions _buildOption() { ... }

// WRONG
getBanners() async { ... }
_buildItems() { ... }
```

---

## Magic Numbers

Never use raw number literals for spacing, sizing, or styling.  
Always reference named constants.

```dart
// CORRECT
padding: AppInsets.mediumHorizontal
height: Sizes.mega
borderRadius: BorderRadius.circular(Sizes.smallMedium)
child: EmptySize.smallHeight

// WRONG
padding: EdgeInsets.symmetric(horizontal: 16)
height: 128
borderRadius: BorderRadius.circular(12)
child: SizedBox(height: 8)
```

---

## No `print()`

`avoid_print: true` is enforced. In debug mode, use `debugPrint()`.  
In production error flows, use the crashlytics service.

```dart
// CORRECT (debug)
debugPrint('Crashlytics Initialized!');
debugPrint("Map couldn't open: $e");

// WRONG
print('something happened');
```

---

## Utility Classes Must Be Non-Instantiable

All utility/constant classes use a private `const` constructor.

```dart
// CORRECT
final class Sizes {
  const Sizes._(); // ← prevents instantiation
  static const double small = 8;
}

final class AppInsets {
  const AppInsets._();
  static const EdgeInsets small = EdgeInsets.all(Sizes.small);
}

final class AppConstants {
  const AppConstants._();
  static const double kZero = 0;
}
```

---

## Immutability

Prefer immutable data. Model fields are always `final`. Use `copyWith()` for mutations.

```dart
// CORRECT
final class ApiResponseModel<TData> {
  const ApiResponseModel({this.isSuccess = false, this.message = '', this.data});
  final TData? data;
  final bool isSuccess;
  final String message;

  ApiResponseModel<TData> copyWith({TData? data, bool? isSuccess, String? message}) { ... }
}
```

---

## File Organization

Within a file, maintain this ordering:
1. Constructors (including factory constructors)
2. Fields (`final` first)
3. Getters/computed properties
4. Overrides (`@override`)
5. Private methods
6. Public methods

---

## Always / Never

### Always
- `final class` for all concrete non-base classes
- `const` constructors on models and stateless widgets
- Default values on all model fields
- Single quotes for string literals
- Named return types on all functions
- Named constants from `Sizes`, `AppInsets`, `AppBorderRadius` for dimensions

### Never
- `class` instead of `final class` for concrete implementation classes
- Hardcoded numbers for layout dimensions
- `print()` — use `debugPrint()` or crashlytics
- `var` for return types
- Mutable model fields (`var field` or non-final)
