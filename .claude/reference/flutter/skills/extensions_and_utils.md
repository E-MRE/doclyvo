# Extensions and Utilities

## BuildContextExtension

File: `lib/app/extensions/build_context_extension.dart`

Provides shortcuts on `BuildContext`. Always use these instead of calling Flutter APIs directly.

```dart
extension BuildContextExtension on BuildContext {
  // Theme
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  T? themeExtension<T>() => Theme.of(this).extension<T>();
  ShimmerColors? get shimmerColors => Theme.of(this).extension<ShimmerColors>();

  // Responsive
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  double dynamicWidth(double val) => screenWidth * val;
  double dynamicHeight(double val) => screenHeight * val;
  EdgeInsets get padding => MediaQuery.of(this).padding;

  // Theme metadata
  Brightness get brightness => Theme.of(this).brightness;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Color get scaffoldBackgroundColor => Theme.of(this).scaffoldBackgroundColor;
}
```

---

## LocalizationExtension

File: `lib/app/extensions/localization_extension.dart`

Wraps `easy_localization`'s `.tr()` with a named method for clarity:

```dart
extension LocalizationExtension on String {
  String translate({
    List<String>? args,
    Map<String, String>? namedArgs,
    String? gender,
    BuildContext? context,
  }) {
    return this.tr(args: args, namedArgs: namedArgs, gender: gender, context: context);
  }

  bool isTranslateExists({BuildContext? context}) {
    return this.trExists(context: context);
  }
}

extension BuildContextExtension on BuildContext {
  List<Locale> get supportedLocaleList => supportedLocales;
  List<LocalizationsDelegate<dynamic>> get localizationDelegateList => localizationDelegates;
}
```

**Usage**:
```dart
// Both are valid — .tr() is shorter, .translate() is more explicit
LocaleKeys.homeScreen_categories.tr()
LocaleKeys.homeScreen_categories.translate()

// In widgets, prefer .tr() for brevity
Text(LocaleKeys.appName.tr())
```

---

## CategoryBackgroundExtension

File: `lib/app/extensions/category_background_extension.dart`

Converts an index integer to a cycling background color for category grid items:

```dart
// Never use inline `Colors.*` (see do_not_do.md) — reference design-system
// tokens from the generated `<AppColors>` palette instead.
extension CategoryBackgroundExtension on int {
  Color toCategoryColor() {
    final mod = this % 6;
    return switch (mod) {
      0 => <AppColors>.categoryAccent1,
      1 => <AppColors>.categoryAccent2,
      2 => <AppColors>.categoryAccent3,
      3 => <AppColors>.categoryAccent4,
      4 => <AppColors>.categoryAccent5,
      5 => <AppColors>.categoryAccent6,
      _ => <AppColors>.categoryAccent1,
    };
  }
}
```

**Usage**:
```dart
backgroundColor: index.toCategoryColor()
```

---

## SpecialKey Enum

File: `lib/app/utils/enums/special_key.dart`

Provides named string constants for special characters:

```dart
enum SpecialKey {
  empty(''),
  dash('-'),
  space(' '),
  currencyTurkish('₺'),
  enterKey('\n'),
  slash('/'),
  centerDot('•'),
  plus('+'),
  dot('.'),
  comma(','),
  threeDots('...'),
  ok('✓'),
  // etc.
}
```

**Usage**:
```dart
// CORRECT
name: SpecialKey.dash.rawValue    // '-'
email: SpecialKey.empty.rawValue  // ''

// WRONG
name: '-'
email: ''
```

---

## SafeStateMixin

File: `lib/app/utils/mixins/safe_state_mixin.dart`

Guards `setState` calls with `mounted` check:

```dart
mixin SafeStateMixin<T extends StatefulWidget> on State<T> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }
}
```

**Usage**:
```dart
class _MyWidgetState extends State<MyWidget>
    with SafeStateMixin<MyWidget> {
  // setState calls are now automatically guarded
}
```

---

## TransitionSlideTypeExtension

File: `lib/app/utils/enums/transition_slide_type.dart`

Extension on `TransitionSlideType` enum to convert to `Tween<Offset>`:

```dart
extension TransitionSlideTypeExtension on TransitionSlideType {
  Tween<Offset> toTween() {
    return switch (this) {
      TransitionSlideType.right => Tween(begin: const Offset(1, 0), end: Offset.zero),
      TransitionSlideType.left  => Tween(begin: const Offset(-1, 0), end: Offset.zero),
      TransitionSlideType.topCenter => Tween(begin: const Offset(0, -1), end: Offset.zero),
      // etc.
    };
  }
}
```

---

## EnvironmentTypeExtension

File: `lib/core/environments/environment_type_extension.dart`

Extension on `EnvironmentType` enum:

```dart
extension EnvironmentTypeExtension on EnvironmentType {
  EnvironmentProfile toProfile() {
    return switch (this) {
      EnvironmentType.release => ReleaseEnvironmentProfile(),
      EnvironmentType.development => DevelopmentEnvironmentProfile(),
    };
  }
}
```

---

## PlatformAwareLauncherMixin

File: `lib/core/utils/mixins/launchers/platform_aware_launcher_mixin.dart`

Provides platform-aware launch methods for URLs, maps, phone, and email:

```dart
mixin PlatformAwareLauncherMixin {
  Future<void> openMap({required double latitude, required double longitude}) async { ... }
  Future<void> openPhone(String phoneNumber) async { ... }
  Future<void> openEmail(String email) async { ... }
  Future<void> openWeb(String url) async { ... }
}
```

Mix into `StatelessWidget` or `StatefulWidget`:
```dart
final class _FooterSuccessView extends StatelessWidget
    with PlatformAwareLauncherMixin {
  // Can now call openPhone(), openEmail(), openMap(), openWeb()
}
```

---

## ImageUrlCompleterMixin

File: `lib/core/utils/mixins/images/image_url_completer_mixin.dart`

Constructs full image URL from relative path stored in model:

```dart
mixin ImageUrlCompleterMixin {
  abstract final String imageUrl;  // relative path

  String get fullImageUrl =>
      '${Configurations.environmentProfile.baseUrl}$imageUrl';
}
```

---

## JsonConverterMixin

File: `lib/core/utils/mixins/json/json_converter_mixin.dart`

Type-safe JSON to Dart conversion for repositories:

```dart
mixin JsonConverterMixin {
  List<T> convertToList<T>({required dynamic json, required T Function(Map<String, dynamic>) parser}) { ... }
  Map<String, dynamic>? convertToMap(dynamic json) { ... }
}
```

---

## Always / Never

### Always
- Use `context.textTheme` not `Theme.of(context).textTheme`
- Use `context.colorScheme` not `Theme.of(context).colorScheme`
- Use `context.screenWidth` / `context.dynamicWidth()` for responsive sizes
- Use `SpecialKey.dash.rawValue` not `'-'` for special characters in UI
- Use `SafeStateMixin` when calling `setState` from async callbacks
- Use `PlatformAwareLauncherMixin` for any URL/phone/map launch

### Never
- Call `MediaQuery.of(context)` directly — use `context.mediaQuery`
- Call `Theme.of(context)` directly — use `context.theme`
- Inline special characters (`'-'`, `'₺'`) — use `SpecialKey.*`
- Call `setState` in async context without `mounted` check — use `SafeStateMixin`
