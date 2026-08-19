# Shared vs Local Widget Rules

When to put a widget in `lib/app/widgets/` versus `lib/features/x/presentation/widgets/` versus as a private class in a file.

---

## The Three Widget Tiers

```
Tier 1: Private class within a file     → _WidgetName (underscore prefix)
Tier 2: Feature-local public widget     → lib/features/x/presentation/widgets/
Tier 3: App-wide shared widget          → lib/app/widgets/<category>/
```

---

## Decision Rules

### Tier 1 — Private File Class

Use when ALL of the following are true:
- Used only by one screen
- Is a structural or branch sub-widget (`_SliverAppBar`, `_FooterSuccessView`, `_FooterErrorView`)
- Would not be reused even if a similar screen was added

```dart
// In home_screen.dart
final class _SliverAppBar extends StatelessWidget { ... }

// In company_footer.dart
final class _FooterSuccessView extends StatelessWidget { ... }
final class _FooterErrorView extends StatelessWidget { ... }
```

### Tier 2 — Feature-Local Widget

Use when:
- Used in multiple places within one feature (screen + sub-screen, or 2 related widgets)
- Depends on a feature-specific model type (`CampaignModel`, `CategoryModel`, `BannerModel`)
- Importing it from `app/widgets/` would create a circular feature dependency

```
lib/features/home/presentation/widgets/
├── banners/
│   └── image_carousel_slider.dart    ← uses BannerModel (home-specific)
├── campaigns/
│   └── campaign_slider_item.dart     ← uses CampaignModel
└── categories/
    ├── category_grid_view.dart
    └── category_card.dart            ← uses CategoryModel
```

> Note: Some of these (like `ImageCarouselSlider`) have evolved into `lib/app/widgets/carousels/` because they are generic enough.

### Tier 3 — Shared App Widget

Use when:
- Used in 2 or more features, OR clearly generic
- Has NO dependency on any feature-specific model
- Could be used in any future feature without modification

```
lib/app/widgets/
├── carousels/
│   └── image_carousel_slider.dart    ← generic image carousel
├── errors/
│   └── basic_error_container.dart    ← used everywhere for errors
├── images/
│   └── cached_image.dart             ← always used for network images
├── shimmers/
│   └── box_shimmer.dart              ← used everywhere for loading
├── sections/
│   └── labeled_section.dart          ← title + content pattern
├── texts/
│   └── link_text.dart                ← tappable link with URL launch
├── buttons/
│   └── social_media_icon_button.dart ← icon button for social links
└── texts/
    └── developer_info_text.dart      ← footer copyright text
```

---

## Promotion Rules

A widget should be **promoted from Tier 1 to Tier 2** when:
- A second screen within the same feature needs to use it

A widget should be **promoted from Tier 2 to Tier 3** when:
- A second feature needs to use it
- It naturally becomes generic (no feature model dependency)

Do NOT pre-promote. Start at Tier 1 and promote when the need arises.

---

## Category Subfolder Rules for `lib/app/widgets/`

Group by visual/functional category:

| Subfolder | Examples |
|-----------|---------|
| `carousels/` | `image_carousel_slider.dart`, `slider_indicator.dart` |
| `errors/` | `basic_error_container.dart` |
| `images/` | `cached_image.dart` |
| `shimmers/` | `box_shimmer.dart` |
| `sections/` | `labeled_section.dart` |
| `buttons/` | `social_media_icon_button.dart` |
| `texts/` | `link_text.dart`, `developer_info_text.dart` |
| `wrappers/` | `localization_wrapper.dart`, `responsive_wrapper.dart` |

Do not create a subfolder for a single widget. If there's only one item, put it directly in `app/widgets/` or batch with a related category.

---

## Naming Rules for Widgets

| Tier | Visibility | Name Format |
|------|-----------|-------------|
| Private | File-only | `_SliverAppBar`, `_FooterSuccessView` |
| Feature-local | Feature-public | `CampaignSliderItem`, `CategoryCard` |
| Shared | App-public | `BoxShimmer`, `CachedImage`, `LabeledSection` |

All widget class names use `PascalCase`. Shared and feature-local widgets are `final class` unless they must be subclassed (which is rare for widgets).

---

## The `isLoading` Pattern for Item Widgets

Feature-local item widgets that appear in lists must accept an `isLoading` flag:

```dart
final class CampaignSliderItem extends StatelessWidget {
  const CampaignSliderItem({
    required this.isLoading,
    required this.item,
    required this.elevation,
    super.key,
  });

  final bool isLoading;
  final CampaignModel item;   // default-constructable: const CampaignModel()
  final double elevation;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return BoxShimmer(width: ..., height: ...);
    return _buildCard(context);
  }
}
```

This allows the parent to render the same widget tree for both shimmer and real data.

---

## Always / Never

### Always
- Start at Tier 1 (private), promote to Tier 2 or 3 only when there's real reuse
- Check if a shared widget already exists in `app/widgets/` before creating a new one
- Ensure Tier 3 widgets have zero feature-specific imports
- Match shimmer size to real content size in item widgets

### Never
- Create `lib/features/shared/` or `lib/features/common/` — use `lib/app/widgets/`
- Put a widget in `app/widgets/` if it imports from `lib/features/`
- Reuse widgets across features by making feature-specific params optional with defaults — promote to shared instead
