# Do Not Do

This file documents patterns, shortcuts, and styles that are explicitly forbidden in this project.

---

## Design System Violations

### DON'T hardcode spacing
```dart
// WRONG
padding: EdgeInsets.symmetric(horizontal: 16)
padding: EdgeInsets.all(8)
SizedBox(height: 8)
SizedBox(width: 16)

// CORRECT
padding: AppInsets.mediumHorizontal
padding: AppInsets.small
EmptySize.smallHeight
EmptySize.mediumWidth
```

### DON'T hardcode border radius
```dart
// WRONG
BorderRadius.circular(16)
BorderRadius.circular(8)

// CORRECT
AppBorderRadius.medium
AppBorderRadius.small
```

### DON'T hardcode colors
```dart
// WRONG
color: Colors.blue
color: Colors.red
color: Color(0xFF123456)
Container(color: Colors.white)

// CORRECT
color: context.colorScheme.primary
color: context.colorScheme.error
color: AppColors.primary  // only in theme definitions
```

### DON'T use raw SizedBox for spacing
```dart
// WRONG
Column(children: [
  Widget1(),
  SizedBox(height: 8),
  Widget2(),
])

// CORRECT
Column(children: [
  Widget1(),
  EmptySize.smallHeight,
  Widget2(),
])
```

---

## State Management Violations

### DON'T use freezed or sealed for states
```dart
// WRONG — freezed adds unnecessary complexity
@freezed
class BannerState with _$BannerState {
  const factory BannerState.loading() = _Loading;
  const factory BannerState.success(List<BannerModel> banners) = _Success;
  const factory BannerState.error(String message) = _Error;
}

// CORRECT — plain classes
abstract class BannerState { const BannerState(); }
final class BannerLoading implements BannerState { const BannerLoading(); }
final class BannerSuccess implements BannerState { ... }
final class BannerError implements BannerState { ... }
```

### DON'T call `emit()` directly — use `safeCall` or `safeEmit`
```dart
// WRONG
Future<void> getBanners() async {
  emit(BannerLoading());
  try {
    final data = await repository.getBanners();
    emit(BannerSuccess(banners: data));
  } catch (e) {
    emit(BannerError(message: e.toString()));
  }
}

// CORRECT
Future<void> getBanners() async {
  return safeCall<List<BannerModel>>(
    action: () async => repository.getBanners(),
    loadingState: const BannerLoading(),
    successState: (data) => BannerSuccess(banners: data),
    errorState: (message) => BannerError(message: message),
  );
}
```

### DON'T register cubits as singletons
```dart
// WRONG — cubit is shared across all resolutions
injector.registerSingleton<BannerCubit>(BannerCubit(repository));

// CORRECT — fresh instance per resolution
injector.registerFactory<BannerCubit>(() => BannerCubit(injector.get<BannerRepository>()));
```

### DON'T create cubits inside BlocProvider
```dart
// WRONG — cubit created inside, not injectable
BlocProvider(
  create: (context) => AppDependency.injector.get<BannerCubit>()..getBanners(),
  child: ...,
)

// CORRECT — cubit injected from parent, provided at boundary
BlocProvider(
  create: (_) => bannerCubit,  // received as constructor param
  child: ...,
)
```

---

## Networking Violations

### DON'T use Dio directly in repositories
```dart
// WRONG
final class RemoteBannerRepository {
  final Dio _dio;
  Future<List<BannerModel>> getBanners() async {
    final response = await _dio.get('/banners');
    // ...
  }
}

// CORRECT
final class RemoteBannerRepository with JsonConverterMixin implements BannerRepository {
  const RemoteBannerRepository(this.networkService);
  final NetworkService networkService;
  // ...
}
```

### DON'T hardcode endpoint strings in repositories
```dart
// WRONG
final response = await networkService.fetchData(endpoint: 'api/v1/Banner', ...);

// CORRECT
final response = await networkService.fetchData(endpoint: EndpointConstants.banners, ...);
```

### DON'T ignore `response.isSuccess`
```dart
// WRONG — returns data regardless of API success flag
return response.data ?? [];

// CORRECT
if (!response.isSuccess) throw ResponseException(response.message);
return response.data ?? [];
```

---

## Architecture Violations

### DON'T import features from other features
```dart
// WRONG — feature coupling
import 'package:<app>/features/home/models/banners/banner_model.dart';
// in lib/features/category/...

// There is no legitimate cross-feature import
```

### DON'T skip the repository layer
```dart
// WRONG — cubit calls network directly
final class BannerCubit extends BaseCubit<BannerState> {
  BannerCubit(this.networkService) : super(const BannerInitial());
  final NetworkService networkService;
  // directly calls networkService.fetchData(...)
}

// CORRECT — cubit calls repository
final class BannerCubit extends BaseCubit<BannerState> {
  BannerCubit(this.repository) : super(const BannerInitial());
  final BannerRepository repository;
}
```

### DON'T put business logic in widgets
```dart
// WRONG
if (company.phone.isNotEmpty) {
  final uri = Uri.parse('tel:$phone');
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}

// CORRECT — use PlatformAwareLauncherMixin
onPressed: () async => openPhone(phone)
```

---

## Theming Violations

### DON'T call Theme.of() directly
```dart
// WRONG
final style = Theme.of(context).textTheme.titleLarge;

// CORRECT
final style = context.textTheme.titleLarge;
```

### DON'T bypass theme for typography
```dart
// WRONG
Text('Hello', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))

// CORRECT
Text('Hello', style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))
```

---

## Model Violations

### DON'T use non-final fields in models
```dart
// WRONG
final class BannerModel {
  String imageUrl;  // mutable field
}

// CORRECT
final class BannerModel {
  const BannerModel({this.imageUrl = ''});
  final String imageUrl;
}
```

### DON'T skip EntityModel implementation
```dart
// WRONG — no contract
@JsonSerializable()
final class BannerModel {
  const BannerModel({this.imageUrl = ''});
  factory BannerModel.fromJson(Map<String, dynamic> json) => _$BannerModelFromJson(json);
  Map<String, dynamic> toJson() => _$BannerModelToJson(this);
}

// CORRECT — implements contract
@JsonSerializable()
final class BannerModel implements EntityModel<BannerModel> { ... }
```

### DON'T use model.imageUrl for display — use fullImageUrl
```dart
// WRONG — missing base URL
CachedImage(url: banner.imageUrl)

// CORRECT — full URL with base
CachedImage(url: banner.fullImageUrl)
```

---

## General Violations

### DON'T use print()
```dart
// WRONG
print('Error: $e');

// CORRECT
debugPrint('Error: $e');
```

### DON'T use Image.network()
```dart
// WRONG — no caching
Image.network(url)

// CORRECT
CachedImage(url: url)
```

### DON'T use Navigator directly
```dart
// WRONG
Navigator.push(context, MaterialPageRoute(builder: (_) => Screen()));

// CORRECT
context.push('/route');
```

### DON'T use setState in async without mounted check
```dart
// WRONG
Future<void> _fetchData() async {
  final data = await api.getData();
  setState(() => _data = data);  // might be called after dispose
}

// CORRECT — use SafeStateMixin
class _MyState extends State<MyWidget> with SafeStateMixin<MyWidget> {
  Future<void> _fetchData() async {
    final data = await api.getData();
    setState(() => _data = data);  // SafeStateMixin guards this
  }
}
```

---

## Known Inconsistencies to Be Aware Of

These inconsistencies exist in the codebase but should NOT be copied:

1. `CategoryGridView` uses `class` instead of `final class` — the dominant convention is `final class`
2. `ImageCarouselSlider` uses `class` instead of `final class` — same note
3. `LinkText` uses `class` instead of `final class` — same note
4. `SocialMediaIconButton` uses `class` instead of `final class` — same note

When creating new code, **always use `final class`** unless the class is explicitly designed to be subclassed (then use `abstract class`).
