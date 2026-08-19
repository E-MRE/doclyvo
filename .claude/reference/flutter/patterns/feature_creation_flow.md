# Feature Creation Flow

Step-by-step guide to creating a complete feature in this project. Follow this order strictly.

---

## Reference: The `home` Feature as Canonical Example

```
lib/features/home/
├── models/
│   ├── banners/banner_model.dart + banner_model.g.dart
│   ├── campaigns/campaign_model.dart + campaign_model.g.dart
│   ├── categories/category_model.dart + category_model.g.dart
│   └── company/company_model.dart + company_model.g.dart
├── data/repositories/
│   ├── banners/banner_repository.dart
│   ├── banners/remote_banner_repository.dart
│   └── ...
└── presentation/
    ├── cubit/banners/banner_cubit.dart + banner_state.dart
    ├── mixins/home_screen_state_mixin.dart
    ├── pages/home_screen.dart
    └── widgets/...
```

---

## Step 1 — Create the Feature Folder

```
lib/features/<feature_name>/
├── models/
├── data/repositories/
└── presentation/
    ├── cubit/
    ├── mixins/
    ├── pages/
    └── widgets/
```

---

## Step 2 — Create the Model

File: `lib/features/<feature_name>/models/<entity>_model.dart`

```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:<app>/core/models/entity_model.dart';
import 'package:<app>/core/utils/mixins/images/image_url_completer_mixin.dart';

part '<entity>_model.g.dart';

@JsonSerializable()
final class <Entity>Model with ImageUrlCompleterMixin implements EntityModel<<Entity>Model> {
  const <Entity>Model({
    this.id = 0,
    this.title = '',
    this.imageUrl = '',
  });

  factory <Entity>Model.fromJson(Map<String, dynamic> json) =>
      _$<Entity>ModelFromJson(json);

  final int id;
  final String title;

  @override
  final String imageUrl;

  @override
  <Entity>Model fromJson(Map<String, dynamic> json) => <Entity>Model.fromJson(json);

  @override
  Map<String, dynamic> toJson() => _$<Entity>ModelToJson(this);
}
```

> Omit `ImageUrlCompleterMixin` if the model has no image URL.

---

## Step 3 — Run build_runner

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates `<entity>_model.g.dart`. Do this before proceeding.

---

## Step 4 — Create the Abstract Repository

File: `lib/features/<feature_name>/data/repositories/<entity>_repository.dart`

```dart
import 'package:<app>/features/<feature_name>/models/<entity>_model.dart';

abstract class <Entity>Repository {
  Future<List<<Entity>Model>> get<Entity>s();
}
```

---

## Step 5 — Create the Remote Repository

File: `lib/features/<feature_name>/data/repositories/remote_<entity>_repository.dart`

```dart
import 'package:<app>/app/constants/endpoint_constants.dart';
import 'package:<app>/core/error/response_exception.dart';
import 'package:<app>/core/models/api_response_model.dart';
import 'package:<app>/core/network/network_service.dart';
import 'package:<app>/core/utils/mixins/json/json_converter_mixin.dart';
import '<entity>_repository.dart';
import '../../models/<entity>_model.dart';

final class Remote<Entity>Repository with JsonConverterMixin implements <Entity>Repository {
  const Remote<Entity>Repository(this.networkService);
  final NetworkService networkService;

  @override
  Future<List<<Entity>Model>> get<Entity>s() async {
    final response = await networkService.fetchData<List<<Entity>Model>>(
      endpoint: EndpointConstants.<entities>,
      parser: (data) => convertToList(data, const <Entity>Model()),
    );
    if (!response.isSuccess) throw ResponseException(response.message);
    return response.data ?? [];
  }
}
```

---

## Step 6 — Create the State File

File: `lib/features/<feature_name>/presentation/cubit/<entity>/<entity>_state.dart`

```dart
abstract class <Entity>State {
  const <Entity>State();
}

final class <Entity>Initial implements <Entity>State {
  const <Entity>Initial();
}

final class <Entity>Loading implements <Entity>State {
  const <Entity>Loading();
}

final class <Entity>Success implements <Entity>State {
  const <Entity>Success({required this.<entities>});
  final List<<Entity>Model> <entities>;
}

final class <Entity>Error implements <Entity>State {
  const <Entity>Error({required this.message});
  final String message;
}
```

---

## Step 7 — Create the Cubit

File: `lib/features/<feature_name>/presentation/cubit/<entity>/<entity>_cubit.dart`

```dart
import 'package:<app>/core/states/base_cubit.dart';
import '../../../data/repositories/<entity>_repository.dart';
import '<entity>_state.dart';

final class <Entity>Cubit extends BaseCubit<<Entity>State> {
  <Entity>Cubit(this.repository) : super(const <Entity>Initial());
  final <Entity>Repository repository;

  Future<void> get<Entity>s() async {
    return safeCall<List<<Entity>Model>>(
      action: () async => repository.get<Entity>s(),
      loadingState: const <Entity>Loading(),
      successState: (<entities>) => <Entity>Success(<entities>: <entities>),
      errorState: (message) => <Entity>Error(message: message),
    );
  }
}
```

---

## Step 8 — Register in DI

File: `lib/app/utils/mixins/app_dependency_register_mixin.dart`

Add to `_registerRepositories()`:
```dart
injector.registerFactory<<Entity>Repository>(
  () => Remote<Entity>Repository(injector.get<NetworkService>()),
);
```

Add to `_registerCubits()`:
```dart
injector.registerFactory<<Entity>Cubit>(
  () => <Entity>Cubit(injector.get<<Entity>Repository>()),
);
```

---

## Step 9 — Create the Screen

File: `lib/features/<feature_name>/presentation/pages/<screen_name>_screen.dart`

```dart
final class <Screen>Screen extends StatefulWidget {
  const <Screen>Screen({super.key});

  @override
  State<<Screen>Screen> createState() => _<Screen>ScreenState();
}

class _<Screen>ScreenState extends State<<Screen>Screen>
    with _<Screen>ScreenStateMixin {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: CustomScrollView(
          controller: _controller,
          slivers: [
            // ... sliver content
          ],
        ),
      ),
    );
  }
}
```

---

## Step 10 — Create the Screen State Mixin

File: `lib/features/<feature_name>/presentation/mixins/<screen_name>_screen_state_mixin.dart`

```dart
mixin _<Screen>ScreenStateMixin on State<<Screen>Screen> {
  late final ScrollController _controller;
  late final <Entity>Cubit _<entity>Cubit;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _<entity>Cubit = AppDependency.injector.get<<Entity>Cubit>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait<void>([
        _<entity>Cubit.get<Entity>s(),
      ]);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

## Step 11 — Add the Route

File: `lib/app/app_router.dart`

```dart
GoRoute(
  path: '/<route_name>',
  pageBuilder: (context, state) =>
    TransitionPageBuilder.fadeTransition(child: const <Screen>Screen()),
),
```

---

## Step 12 — Add Endpoint Constant

File: `lib/app/constants/endpoint_constants.dart`

```dart
static const String <entities> = '${_apiV1}<EndpointName>';
```

---

## Step 13 — Add Translation Keys (if needed)

1. Add to `assets/translations/tr-TR.json`
2. Run `build_runner build` again
3. Use `LocaleKeys.<feature>_<key>.tr()` in widgets

---

## Checklist

- [ ] Model created with `@JsonSerializable()` + `implements EntityModel<T>`
- [ ] `build_runner` run after model creation
- [ ] Abstract repository + remote implementation created
- [ ] State file has all 4 classes (Initial/Loading/Success/Error)
- [ ] Cubit uses `safeCall`, not raw try/catch
- [ ] Both repository and cubit registered in `AppDependencyRegisterMixin`
- [ ] Repository as `registerFactory`, NetworkService as `get<NetworkService>()`
- [ ] Cubit as `registerFactory`
- [ ] Screen uses `StatefulWidget` + `_ScreenStateMixin`
- [ ] Route added to `app_router.dart`
- [ ] Endpoint constant added to `EndpointConstants`
