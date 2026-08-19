# Build Runner Rules

## Overview

The project uses `build_runner` to generate code for three systems:

| Generator | Purpose | Output |
|-----------|---------|--------|
| `json_serializable` | Model JSON serialization | `*.g.dart` files |
| `envied_generator` | Environment variable loading | `*_profile.g.dart` files |
| `flutter_gen_runner` | Type-safe assets + colors | `lib/generated/` |
| `easy_localization` | Locale keys | `lib/generated/localization/lang/locale_keys.g.dart` |

---

## Running Build Runner

Standard build (run after any generator-triggering change):
```bash
dart run build_runner build --delete-conflicting-outputs
```

Watch mode (during development):
```bash
dart run build_runner watch --delete-conflicting-outputs
```

Using project script:
```bash
./scripts/build.sh
```

---

## `json_serializable` — Model Code Gen

### Configuration (`build.yaml`)

```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          explicit_to_json: true    # nested objects call toJson()
          include_if_null: false    # null fields omitted from output
```

### Triggering Model Generation

Every model annotated with `@JsonSerializable()` needs:
1. `part 'model_name.g.dart'` at the top
2. `factory ModelName.fromJson(Map<String, dynamic> json) => _$ModelNameFromJson(json)`
3. `toJson()` returning `_$ModelNameToJson(this)`

```dart
@JsonSerializable()
final class BannerModel implements EntityModel<BannerModel> {
  const BannerModel({this.imageUrl = ''});

  factory BannerModel.fromJson(Map<String, dynamic> json) =>
      _$BannerModelFromJson(json);   // ← generated

  @override
  final String imageUrl;

  @override
  BannerModel fromJson(Map<String, dynamic> json) => BannerModel.fromJson(json);

  @override
  Map<String, dynamic> toJson() => _$BannerModelToJson(this);  // ← generated
}
```

### Generated File Exclusion

Generated files are excluded from linting in `analysis_options.yaml`:
```yaml
analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/generated/**"
```

---

## `envied_generator` — Environment Variables

Triggers on `@Envied` and `@EnviedField` annotations:

```dart
@Envied(
  name: 'DevelopmentEnvironment',
  path: 'environments/development.env',
  obfuscate: true,
)
final class DevelopmentEnvironmentProfile extends EnvironmentProfile {
  @override
  @EnviedField(varName: 'BASE_URL')
  final String baseUrl = _DevelopmentEnvironment.baseUrl;
}
```

Run `build_runner` after:
- Modifying `.env` files
- Adding new `@EnviedField` annotations

**Note**: `.env` files must exist before running build_runner. Generated `.g.dart` files are committed to VCS.

---

## `flutter_gen_runner` — Assets and Colors

### Configuration (`build.yaml` + `pubspec.yaml`)

```yaml
# build.yaml
targets:
  $default:
    builders:
      flutter_gen_runner:
        options:
          output: lib/generated/
          line_length: 80

# pubspec.yaml (flutter_gen section)
flutter_gen:
  output: lib/generated/
  line_length: 80

  colors:
    enabled: true
    inputs:
      - assets/colors/colors.xml
    outputs:
      class_name: AppColors

  integrations:
    flutter_svg: true
    rive: true
    lottie: true
    image: true
```

Triggers on:
- Changes to `assets/colors/colors.xml` → regenerates `AppColors`
- Changes to assets in `pubspec.yaml` flutter section → regenerates `Assets` class

### Generated Outputs
- `lib/generated/colors.gen.dart` → `AppColors` class
- `lib/generated/assets.gen.dart` → `Assets` class for type-safe asset references

---

## easy_localization Locale Keys

Locale keys are generated from JSON translation files.  

Run `build_runner` after:
- Adding new keys to `assets/translations/tr-TR.json`
- Adding new locale files

Generated output:
- `lib/generated/localization/lang/locale_keys.g.dart`

---

## What Triggers build_runner

| Change | Run build_runner? |
|--------|-------------------|
| Add `@JsonSerializable` model | Yes |
| Modify model fields | Yes |
| Modify `.env` file | Yes |
| Add `@EnviedField` | Yes |
| Add color to `colors.xml` | Yes |
| Add asset to `pubspec.yaml` | Yes |
| Add translation key to JSON | Yes |
| Add new translation locale | Yes |
| Modify widget code | No |
| Modify cubit/state code | No |
| Modify repository code | No |

---

## Always / Never

### Always
- Run `build_runner build --delete-conflicting-outputs` after model changes
- Add `part 'model.g.dart'` to every `@JsonSerializable` model
- Commit generated `.g.dart` files to VCS
- Use `./scripts/build.sh` if available instead of raw dart commands

### Never
- Edit `*.g.dart` files manually — they will be overwritten
- Commit `.env` files to VCS (only `.g.dart` files)
- Add models without `@JsonSerializable` if they need serialization
