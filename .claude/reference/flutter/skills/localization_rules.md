# Localization Rules

## Setup

Package: `easy_localization: ^3.0.8`

Translation files: `assets/translations/tr-TR.json`  
Supported locales: Turkish (`tr_TR`) only — fallback locale is also `tr_TR`.

---

## LocalizationConfig

File: `lib/core/localization/localization_config.dart`

```dart
final class LocalizationConfig {
  const LocalizationConfig._();

  static const String path = 'assets/translations';
  static const Locale fallbackLocale = Locale('tr', 'TR');
  static const List<Locale> supportedLocales = [
    Locale('tr', 'TR'),
  ];
}
```

To add a new locale:
1. Add JSON file to `assets/translations/` (e.g., `en-US.json`)
2. Add `Locale('en', 'US')` to `LocalizationConfig.supportedLocales`
3. Run `build_runner` to regenerate `locale_keys.g.dart`

---

## LocaleKeys — Generated Constants

File: `lib/generated/localization/lang/locale_keys.g.dart`

All translation keys are generated as string constants. Never use raw strings.

```dart
abstract class LocaleKeys {
  static const appName = 'appName';
  static const developerInfo_createdBy = 'developerInfo.createdBy';
  static const developerInfo_creator = 'developerInfo.creator';
  static const developerInfo_years = 'developerInfo.years';
  static const errors_tryAgain = 'errors.tryAgain';
  static const errors_jsonTypeError = 'errors.jsonTypeError';
  static const footer_followUs = 'footer.followUs';
  static const homeScreen_categories = 'homeScreen.categories';
  // etc.
}
```

---

## Translation File Structure

`assets/translations/tr-TR.json`:
```json
{
  "appName": "<AppName>",
  "developerInfo": {
    "createdBy": "Created by {name}",
    "creator": "<team>",
    "years": "2024-2025"
  },
  "errors": {
    "tryAgain": "Tekrar Dene",
    "jsonTypeError": "JSON tipi hatası"
  },
  "footer": {
    "followUs": "Bizi Takip Edin"
  },
  "homeScreen": {
    "categories": "Kategoriler"
  }
}
```

---

## Translation Usage in Code

### Short form — `.tr()` (preferred in widgets)
```dart
Text(LocaleKeys.appName.tr())
Text(LocaleKeys.errors_tryAgain.tr())
```

### Explicit form — `.translate()` (more readable in complex calls)
```dart
title: LocaleKeys.homeScreen_categories.translate()
```

Both are valid. Use `.tr()` for simple cases, `.translate()` when passing args/namedArgs.

### With arguments
```dart
// Positional args
LocaleKeys.someKey.tr(args: ['value1', 'value2'])

// Named args
LocaleKeys.someKey.tr(namedArgs: {'name': '<user>'})
```

---

## LocalizationWrapper

File: `lib/app/widgets/wrappers/localization_wrapper.dart`

Wraps the app in `EasyLocalization`. Used once at app root:

```dart
final class LocalizationWrapper extends StatelessWidget {
  const LocalizationWrapper({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      supportedLocales: LocalizationConfig.supportedLocales,
      fallbackLocale: LocalizationConfig.fallbackLocale,
      path: LocalizationConfig.path,
      child: child,
    );
  }
}
```

---

## BuildContext Localization Helpers

File: `lib/app/extensions/localization_extension.dart`

```dart
context.supportedLocaleList    // List<Locale>
context.localizationDelegateList // List<LocalizationsDelegate>
```

Used in `MaterialApp.router`:
```dart
MaterialApp.router(
  supportedLocales: context.supportedLocaleList,
  localizationsDelegates: context.localizationDelegateList,
)
```

---

## Adding New Translation Keys

1. Add key/value pair to `assets/translations/tr-TR.json`
2. Run: `dart run build_runner build --delete-conflicting-outputs`
3. New key appears in `lib/generated/localization/lang/locale_keys.g.dart`
4. Use: `LocaleKeys.myNewKey.tr()`

---

## Always / Never

### Always
- Use `LocaleKeys.*` constants — never raw string keys
- Call `.tr()` or `.translate()` on `LocaleKeys` constants
- Use `LocalizationConfig` as single source of locale configuration
- Add translation strings to the JSON file before using them in code

### Never
- Hardcode display text in widgets — all user-visible text goes through localization
- Use raw string keys like `'appName'.tr()` — always use `LocaleKeys.appName.tr()`
- Add locales to `EasyLocalization` directly — update `LocalizationConfig`
