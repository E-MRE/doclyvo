# Project Structure

## Root Layout

```
<app>/
├── android/                    ← Android platform code
├── ios/                        ← iOS platform code
├── assets/
│   ├── colors/colors.xml       ← AppColors source (consumed by flutter_gen)
│   ├── images/
│   │   ├── png/
│   │   └── svg/
│   └── translations/
│       └── tr-TR.json          ← Turkish translations (only supported locale)
├── environments/
│   ├── development.env         ← Dev secrets (envied source)
│   └── release.env             ← Release secrets (envied source)
├── lib/
│   ├── main.dart
│   ├── app/
│   ├── core/
│   ├── features/
│   └── generated/
├── reference/flutter/          ← Shared Flutter convention/knowledge base
├── analysis_options.yaml       ← very_good_analysis + custom lint rules
├── build.yaml                  ← build_runner configuration
├── pubspec.yaml
└── scripts/
    ├── build.sh
    ├── lang.sh
    └── splash.sh
```

---

## `lib/app/` — App Layer

```
lib/app/
├── app_initializer.dart        ← Bootstraps app (DI, crashlytics, localization, splash)
├── app_router.dart             ← GoRouter route definitions
├── constants/
│   ├── app_constants.dart      ← App-wide constants (kZero, kOne, invalidIndex)
│   ├── endpoint_constants.dart ← API endpoint strings
│   └── responsive_constants.dart ← Breakpoints and conditional widths
├── extensions/
│   ├── build_context_extension.dart     ← Theme, media query shortcuts
│   ├── category_background_extension.dart ← int → Color for category items
│   └── localization_extension.dart      ← String.translate(), BuildContext locale helpers
├── theme/
│   ├── app_theme.dart          ← Abstract AppTheme base
│   ├── light_theme.dart        ← LightTheme concrete
│   ├── dark_theme.dart         ← DarkTheme concrete
│   ├── theme_manager.dart      ← ThemeManager (ChangeNotifier + WidgetsBindingObserver)
│   ├── theme_option.dart       ← ThemeOption enum
│   ├── theme_service.dart      ← Abstract ThemeService
│   └── extensions/
│       └── shimmer_colors.dart ← ShimmerColors ThemeExtension
├── utils/
│   ├── builders/
│   │   └── transition_page_builder.dart ← fade/slide/scale page transitions
│   ├── enums/
│   │   ├── special_key.dart             ← SpecialKey enum (dash, empty, currency, etc.)
│   │   └── transition_slide_type.dart   ← TransitionSlideType enum + extension
│   └── mixins/
│       ├── app_dependency_register_mixin.dart ← DI registration logic
│       └── safe_state_mixin.dart              ← setState guard for mounted
└── widgets/
    ├── animations/
    │   └── shimmer.dart                ← Base Shimmer animation widget
    ├── carousels/
    │   ├── image_carousel_slider.dart  ← Full-featured image carousel with indicator
    │   └── slider_indicator.dart       ← Dot indicator for carousel
    ├── errors/
    │   └── basic_error_container.dart  ← Error box with message + retry button
    ├── images/
    │   └── cached_image.dart           ← CachedNetworkImage with shimmer placeholder
    ├── shimmers/
    │   └── box_shimmer.dart            ← Rectangular shimmer skeleton
    ├── texts/
    │   └── link_text.dart              ← RichText with clickable URL span
    └── wrappers/
        ├── localization_wrapper.dart   ← EasyLocalization setup
        └── responsive_wrapper.dart     ← ResponsiveBreakpoints + MaxWidthBox
```

---

## `lib/core/` — Core Layer

```
lib/core/
├── config/
│   ├── configurations.dart                  ← Environment switch (isDevelopment flag)
│   └── mixins/
│       └── crashlytics_configuration_mixin.dart ← FlutterError.onError setup
├── crashlytics/
│   ├── crashlytics_service.dart             ← Abstract CrashlyticsService
│   ├── crashlytics_manager.dart             ← Firebase implementation
│   ├── console_crashlytics_manager.dart     ← Dev/debug implementation (console output)
│   └── crashlytics_service_factory.dart     ← Picks implementation based on kDebugMode
├── dependency/
│   ├── app_dependency.dart                  ← Global AppDependency access point + kCrashlytics
│   ├── get_it/
│   │   ├── get_it_dependency_injector.dart           ← GetIt wrapper impl
│   │   └── get_it_dependency_injection_manager.dart  ← Singleton manager
│   └── injector/
│       ├── dependency_injector.dart          ← Abstract DependencyInjector
│       └── dependency_injection_service.dart ← Abstract DependencyInjectionService
├── environments/
│   ├── environment_type.dart                ← EnvironmentType enum
│   ├── environment_profile.dart             ← Abstract EnvironmentProfile
│   ├── environment_type_extension.dart      ← .toProfile() switch
│   ├── development_environment_profile.dart ← @Envied dev profile
│   ├── development_environment_profile.g.dart ← generated
│   ├── release_environment_profile.dart     ← @Envied release profile
│   └── release_environment_profile.g.dart  ← generated
├── error/
│   ├── json_exception.dart      ← Thrown when JSON type mismatch
│   └── response_exception.dart  ← Thrown when API returns isSuccess=false
├── localization/
│   └── localization_config.dart ← Supported locales, fallback locale, path
├── models/
│   ├── api_request_model.dart   ← Abstract base for request bodies
│   ├── api_response_model.dart  ← Generic response wrapper (isSuccess/message/data)
│   ├── empty_entity_model.dart  ← Passthrough model for raw JSON
│   └── entity_model.dart        ← Abstract EntityModel<T> contract
├── network/
│   ├── network_service.dart     ← Abstract NetworkService
│   ├── dio_network_manager.dart ← Dio-based implementation
│   ├── remote_data_source.dart  ← Abstract base with NetworkService injection
│   └── remote_repository.dart   ← Abstract base with NetworkService getter
├── states/
│   └── base_cubit.dart          ← BaseCubit with safeCall + safeEmit
└── utils/
    ├── constants/
    │   ├── sizes.dart                       ← Sizes (4-based scale: 0→480)
    │   ├── app_insets.dart                  ← AppInsets EdgeInsets constants
    │   ├── app_border_radius.dart           ← AppBorderRadius constants
    │   ├── app_rounded_rectangle_border.dart ← AppRoundedRectangleBorder constants
    │   ├── empty_size.dart                  ← EmptySize SizedBox shortcuts
    │   └── sliver_empty_size.dart           ← SliverEmptySize sliver shortcuts
    ├── decorations/
    │   └── box_decorations.dart             ← AppDecorations (shimmer, indicator)
    └── mixins/
        ├── images/
        │   └── image_url_completer_mixin.dart  ← fullImageUrl computed property
        ├── json/
        │   └── json_converter_mixin.dart        ← convertToList, convertToMap
        └── launchers/
            └── platform_aware_launcher_mixin.dart ← openMap, openPhone, openEmail, openWeb
```

---

## `lib/features/` — Feature Modules

```
lib/features/
├── home/           ← Fully implemented (canonical reference)
├── category/       ← Stub (future development)
└── detail/         ← Stub (future development)
```

Each feature folder follows the same internal structure as `home/`.  
See `reference/flutter/skills/architecture.md` for the canonical feature folder layout.

---

## `lib/generated/` — Code-Generated Output

```
lib/generated/
├── assets.gen.dart                    ← Type-safe asset references (Assets class)
├── colors.gen.dart                    ← AppColors constants
└── localization/
    └── lang/
        └── locale_keys.g.dart         ← LocaleKeys constants (generated by easy_localization)
```

---

## Where to Add New Code

| What | Where |
|------|-------|
| New screen | `lib/features/<feature>/presentation/pages/` |
| New cubit | `lib/features/<feature>/presentation/cubit/<domain>/` |
| New repository | `lib/features/<feature>/data/repositories/<domain>/` |
| New model | `lib/features/<feature>/models/<domain>/` |
| New shared widget | `lib/app/widgets/<category>/` |
| New extension | `lib/app/extensions/` |
| New constant | `lib/core/utils/constants/` |
| New mixin (util) | `lib/core/utils/mixins/<category>/` |
| New API endpoint | `lib/app/constants/endpoint_constants.dart` |
| New route | `lib/app/app_router.dart` |
| New DI registration | `lib/app/utils/mixins/app_dependency_register_mixin.dart` |
| New color | `assets/colors/colors.xml` then run `build_runner` |
| New translation key | `assets/translations/tr-TR.json` then run `build_runner` |
