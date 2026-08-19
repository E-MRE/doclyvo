# Architecture

## Overview

The project follows a **Feature-First Clean Architecture** with 4 top-level layers inside `lib/`:

```
lib/
├── app/         ← App-level concerns (routing, theming, DI registration, shared widgets)
├── core/        ← Cross-cutting infrastructure (network, DI abstractions, error, models, utils)
├── features/    ← Vertical feature slices (each feature is self-contained)
└── generated/   ← Code-gen output (flutter_gen: assets, colors, locale keys)
```

---

## Layer Responsibilities

### `lib/app/`
- Entry point bootstrap (`app_initializer.dart`)
- Route definitions (`app_router.dart`)
- Theme system (`theme/`)
- App-wide constants (`constants/`)
- App-wide extensions (`extensions/`)
- App-wide reusable widgets (`widgets/`)
- Utility builders and mixins (`utils/`)

**Rule**: `app/` may depend on `core/`. It must NOT import from `features/`.

### `lib/core/`
- Network abstraction (`network/`)
- Dependency injection abstractions (`dependency/`)
- Error types (`error/`)
- Base classes for state management (`states/base_cubit.dart`)
- Shared models contracts (`models/entity_model.dart`, `api_response_model.dart`)
- Utility constants (`utils/constants/`)
- Utility mixins (`utils/mixins/`)
- Environment configuration (`environments/`)
- Crashlytics abstraction (`crashlytics/`)
- Localization config (`localization/`)

**Rule**: `core/` must have zero imports from `app/` or `features/`. It is the lowest layer.

### `lib/features/`
Each feature is a vertical slice:
```
features/
└── home/
    ├── models/           ← Data models (@JsonSerializable, EntityModel)
    ├── data/
    │   └── repositories/ ← Abstract interfaces + Remote implementations
    └── presentation/
        ├── cubit/        ← State management (BaseCubit subclasses)
        ├── pages/        ← Screen widgets + views
        ├── widgets/      ← Feature-specific widget components
        └── mixins/       ← Screen state mixins
```

**Rule**: Features may import from `app/` and `core/`. Features must NOT import from other features.

### `lib/generated/`
- `colors.gen.dart` — `AppColors` class (generated from `assets/colors/colors.xml`)
- `assets.gen.dart` — Type-safe asset references
- `localization/lang/locale_keys.g.dart` — `LocaleKeys` constants

**Rule**: Never edit generated files manually. Re-run `build_runner` instead.

---

## Canonical Feature Structure (Home Feature)

Use `lib/features/home/` as the reference template for all new features.

```
features/home/
├── models/
│   ├── banners/
│   │   ├── banner_model.dart
│   │   └── banner_model.g.dart       ← generated
│   ├── campaigns/
│   │   ├── campaign_model.dart
│   │   └── campaign_model.g.dart
│   ├── categories/
│   │   ├── category_model.dart       ← abstract base
│   │   ├── main_category_model.dart
│   │   └── sub_category_model.dart
│   └── products/
│       └── product_model.dart
├── data/
│   └── repositories/
│       ├── banners/
│       │   ├── banner_repository.dart         ← abstract interface
│       │   └── remote_banner_repository.dart  ← concrete remote impl
│       └── [same pattern per domain...]
└── presentation/
    ├── cubit/
    │   ├── banners/
    │   │   ├── banner_cubit.dart
    │   │   └── banner_state.dart
    │   └── [same pattern per domain...]
    ├── pages/
    │   ├── home_screen.dart
    │   └── views/
    │       ├── footer_view.dart
    │       ├── footer_success_view.dart
    │       └── footer_error_view.dart
    ├── widgets/
    │   ├── carousels/
    │   ├── sections/
    │   ├── grids/
    │   ├── buttons/
    │   └── text/
    └── mixins/
        └── home_screen_state_mixin.dart
```

---

## Dependency Flow

```
features/ → app/ → core/
features/ → core/
app/ → core/
generated/ ← (app/, core/, features/ all consume generated)
```

Arrows point in the direction of dependency (A → B means A imports B).

---

## Dependency Injection Wiring

Dependencies are wired in `lib/app/utils/mixins/app_dependency_register_mixin.dart`.

Registration order:
1. Core dependencies (CrashlyticsService)
2. Environment profile (dev or release)
3. Network (Dio + NetworkService) — singleton
4. Repositories — factory
5. Cubits — factory

Cubits are **always** `registerFactory` (new instance per resolution).
Services that must be shared are `registerSingleton`.

---

## Always / Never

### Always
- Keep each feature self-contained — models + repositories + cubits + widgets all in the same feature folder
- Add new features as new directories under `lib/features/`
- Wire new cubits/repositories in `AppDependencyRegisterMixin`
- Follow the `lib/features/home/` folder structure exactly for new features

### Never
- Import one feature from another feature
- Put business logic in widgets
- Put UI rendering in cubits
- Import `features/` from `core/`
- Skip the repository layer (call network directly from cubits)
