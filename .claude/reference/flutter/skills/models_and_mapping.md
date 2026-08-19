# Models and Mapping

## Model Contract — `EntityModel<T>`

All domain models implement `EntityModel<T>` from `lib/core/models/entity_model.dart`.

```dart
abstract class EntityModel<T extends EntityModel<T>> {
  const EntityModel();

  T fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

This ensures every model is serializable via a consistent interface.

---

## Standard Model Pattern

```dart
import 'package:<app>/core/models/entity_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'banner_model.g.dart';

@JsonSerializable()
final class BannerModel implements EntityModel<BannerModel> {
  const BannerModel({this.imageUrl = ''});  // constructor first

  factory BannerModel.fromJson(Map<String, dynamic> json) =>
      _$BannerModelFromJson(json);

  @override
  final String imageUrl;  // fields after constructor

  @override
  BannerModel fromJson(Map<String, dynamic> json) => BannerModel.fromJson(json);

  @override
  Map<String, dynamic> toJson() => _$BannerModelToJson(this);
}
```

**Rules**:
- `final class` — not extendable
- `const` constructor with named parameters
- All fields have default values (`this.imageUrl = ''`, `this.price = 0`)
- `factory BannerModel.fromJson` for deserialization (generated)
- `@override toJson()` delegates to generated `_$ModelToJson(this)` 
- `@override fromJson()` delegates to `factory fromJson`
- `part 'model_name.g.dart'` at top of file

---

## `@JsonSerializable` Configuration

Set globally in `build.yaml`:
```yaml
json_serializable:
  options:
    explicit_to_json: true    # nested objects call their toJson()
    include_if_null: false    # null fields omitted from JSON output
```

This means:
- Nested models are fully serialized recursively
- `null` values are not included in `toJson()` output

**No custom options needed per-model** unless overriding a specific field.

---

## ImageUrlCompleterMixin

Models with image URLs use this mixin to construct the full URL from the base URL:

```dart
mixin ImageUrlCompleterMixin {
  abstract final String imageUrl;  // relative path from API

  String get fullImageUrl =>
      '${Configurations.environmentProfile.baseUrl}$imageUrl';
}
```

Apply it with `with`:
```dart
@JsonSerializable()
final class BannerModel
    with ImageUrlCompleterMixin
    implements EntityModel<BannerModel> {
  const BannerModel({this.imageUrl = ''});
  @override
  final String imageUrl;  // stored as relative, accessed as fullImageUrl
  // ...
}
```

**Rule**: Store `imageUrl` as relative path. Always use `model.fullImageUrl` in widgets, never `model.imageUrl` directly for display.

---

## Model Inheritance Pattern

When multiple models share fields, use an abstract base class:

```dart
// Abstract base — no JsonSerializable annotation
abstract class CategoryModel with ImageUrlCompleterMixin {
  const CategoryModel({
    this.title = '',
    this.description = '',
    this.shortDescription = '',
    this.imageUrl = '',
  });

  final String title;
  final String description;
  final String shortDescription;
  @override
  final String imageUrl;
}

// Concrete subclass — has JsonSerializable
@JsonSerializable()
final class MainCategoryModel extends CategoryModel
    implements EntityModel<MainCategoryModel> {
  const MainCategoryModel({
    super.title,
    super.description,
    super.shortDescription,
    super.imageUrl,
    this.subCategoryList = const [],
    this.itemList = const [],
  });

  factory MainCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$MainCategoryModelFromJson(json);

  @override
  final List<SubCategoryModel> subCategoryList;
  @override
  final List<ProductModel> itemList;

  @override
  MainCategoryModel fromJson(Map<String, dynamic> json) =>
      MainCategoryModel.fromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MainCategoryModelToJson(this);
}
```

---

## ApiResponseModel — Network Wrapper

All API responses are wrapped in `ApiResponseModel<TData>`:

```dart
final class ApiResponseModel<TData> {
  const ApiResponseModel({
    this.isSuccess = false,
    this.message = '',
    this.data,
  });

  factory ApiResponseModel.fromJson(
    Map<String, dynamic> json, {
    required TData Function(dynamic json) parser,
  }) { ... }

  final TData? data;
  final bool isSuccess;
  final String message;

  ApiResponseModel<TData> copyWith({...}) { ... }
}
```

JSON keys (defined as top-level constants):
- `isSuccess` key: `'isSuccess'`
- `message` key: `'errorMessage'`
- `data` key: `'data'`

---

## JsonConverterMixin — Repository Parsing Helper

Repositories use `JsonConverterMixin` to safely parse API responses:

```dart
mixin JsonConverterMixin {
  // For list responses
  List<T> convertToList<T>({
    required dynamic json,
    required T Function(Map<String, dynamic> json) parser,
  }) {
    if (json == null || json is! List) return <T>[];
    return json.map<T>((element) {
      if (element is! Map<String, dynamic>) return parser({});
      return parser(element);
    }).cast<T>().toList();
  }

  // For single object responses
  Map<String, dynamic>? convertToMap(dynamic json) {
    if (json == null) return null;
    if (json is Map<String, dynamic>) return json;
    throw const JsonException();
  }
}
```

**Usage in repositories**:
```dart
// List response
parser: (json) => convertToList(
  parser: BannerModel.fromJson,
  json: json,
)

// Single object response
parser: (json) => CompanyModel.fromJson(convertToMap(json) ?? {})
```

---

## EmptyEntityModel

Used as a passthrough when no typed model is needed:

```dart
final class EmptyEntityModel implements EntityModel<EmptyEntityModel> {
  EmptyEntityModel({Map<String, dynamic>? json})
    : _json = json ?? <String, dynamic>{};

  factory EmptyEntityModel.fromJson(Map<String, dynamic> json) =>
      EmptyEntityModel(json: json);

  final Map<String, dynamic> _json;
  Map<String, dynamic> get json => _json;

  @override
  EmptyEntityModel fromJson(Map<String, dynamic> json) =>
      EmptyEntityModel(json: json);

  @override
  Map<String, dynamic> toJson() => _json;
}
```

---

## Field Default Value Rules

| Dart type | Default value |
|-----------|--------------|
| `String` | `''` |
| `int` | `0` |
| `double` | `0` |
| `bool` | `false` |
| `List<T>` | `const []` |
| `Map<K,V>` | `const {}` |
| Nullable `T?` | (omit default — will be `null`) |

---

## Always / Never

### Always
- Annotate concrete models with `@JsonSerializable()`
- Add `part 'model_name.g.dart'`
- Implement `EntityModel<T>`
- Use `const` constructor with default values for all fields
- Use `ImageUrlCompleterMixin` when model has an image URL
- Use `with` for mixins, `extends` for inheritance, `implements` for interfaces
- Run `build_runner` after adding/modifying models

### Never
- Hardcode base URL in model — use `ImageUrlCompleterMixin.fullImageUrl`
- Use non-final fields in models
- Skip `EntityModel<T>` implementation
- Manually write JSON parsing logic — use `@JsonSerializable`
- Use nullable fields as a shortcut for "optional" — prefer default values
