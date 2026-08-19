# Networking

## Network Layer Architecture

```
NetworkService (abstract)
└── DioNetworkManager (final class)

ApiResponseModel<TData> — wraps every response
JsonConverterMixin — parsing helper for repositories
```

---

## NetworkService — Abstract Contract

File: `lib/core/network/network_service.dart`

```dart
abstract class NetworkService {
  const NetworkService();

  Future<ApiResponseModel<TData>> fetchData<TData>({
    required String endpoint,
    required TData Function(dynamic) parser,
    Map<String, dynamic>? queryParameters,
  });

  Future<ApiResponseModel<TData>> postData<TData>({
    required String endpoint,
    required Object body,
    required TData Function(dynamic) parser,
    Map<String, dynamic>? queryParameters,
  });
}
```

**Rule**: Always depend on the abstract `NetworkService` interface, never directly on `DioNetworkManager`.

---

## DioNetworkManager — Implementation

File: `lib/core/network/dio_network_manager.dart`

```dart
final class DioNetworkManager extends NetworkService {
  const DioNetworkManager(Dio dio) : _dio = dio, super();

  final Dio _dio;

  @override
  Future<ApiResponseModel<TData>> fetchData<TData>({...}) async {
    final futureGet = _dio.get<Map<String, dynamic>>(endpoint, queryParameters: queryParameters);
    return _getRawResponse<TData>(requestFunction: futureGet, parser: parser);
  }

  @override
  Future<ApiResponseModel<TData>> postData<TData>({...}) async {
    final futurePost = _dio.post<Map<String, dynamic>>(endpoint, data: body, queryParameters: queryParameters);
    return _getRawResponse<TData>(requestFunction: futurePost, parser: parser);
  }

  Future<ApiResponseModel<TData>> _getRawResponse<TData>({
    required Future<Response<Map<String, dynamic>>> requestFunction,
    required TData Function(dynamic) parser,
  }) async {
    try {
      final response = await requestFunction;
      return ApiResponseModel<TData>.fromJson(response.data ?? {}, parser: parser);
    } on Exception catch (exception) {
      return ApiResponseModel<TData>(message: exception.toString());
    }
  }
}
```

---

## ApiResponseModel — Response Wrapper

File: `lib/core/models/api_response_model.dart`

All API responses are wrapped in this generic model:

```dart
final class ApiResponseModel<TData> {
  final TData? data;
  final bool isSuccess;
  final String message;
}
```

JSON contract:
- `isSuccess` → parsed from key `'isSuccess'`
- `message` → parsed from key `'errorMessage'`
- `data` → parsed from key `'data'`

---

## Endpoint Constants

File: `lib/app/constants/endpoint_constants.dart`

```dart
final class EndpointConstants {
  static const String _apiV1 = 'api/v1/';
  static const String banners = '${_apiV1}Banner';
  static const String campaign = '${_apiV1}Campaign';
  static const String company = '${_apiV1}Company';
  static const String category = '${_apiV1}Category';
}
```

**Rule**: All endpoint strings go in `EndpointConstants`. Never hardcode endpoint strings in repositories.

---

## Dio Configuration

Dio is configured during DI registration with base URL from the environment profile:

```dart
injector.registerFactory<Dio>(
  () => Dio(
    BaseOptions(
      baseUrl: Configurations.environmentProfile.baseUrl,
      connectTimeout: const Duration(seconds: 32),
      receiveTimeout: const Duration(seconds: 32),
      sendTimeout: const Duration(seconds: 32),
    ),
  ),
)
```

`NetworkService` is registered as a **singleton**:
```dart
injector.registerSingleton<NetworkService>(
  DioNetworkManager(injector.get<Dio>()),
)
```

---

## Repository Pattern — Complete Example

Every repository domain has:
1. Abstract interface
2. Remote implementation

```dart
// 1. Abstract interface
abstract class BannerRepository {
  const BannerRepository();
  Future<List<BannerModel>> getBanners();
}

// 2. Remote implementation
final class RemoteBannerRepository
    with JsonConverterMixin
    implements BannerRepository {
  const RemoteBannerRepository(this.networkService);
  final NetworkService networkService;

  @override
  Future<List<BannerModel>> getBanners() async {
    final response = await networkService.fetchData<List<BannerModel>>(
      endpoint: EndpointConstants.banners,
      parser: (json) => convertToList(
        parser: BannerModel.fromJson,
        json: json,
      ),
    );
    if (!response.isSuccess) {
      throw ResponseException(response.message);
    }
    return response.data ?? [];
  }
}
```

---

## Single Object Fetch Pattern

```dart
final response = await networkService.fetchData<CompanyModel>(
  endpoint: EndpointConstants.company,
  parser: (json) => CompanyModel.fromJson(convertToMap(json) ?? {}),
);
if (!response.isSuccess) throw ResponseException(response.message);
return response.data ?? const CompanyModel();
```

---

## Error Flow

```
DioNetworkManager catches Exception → returns ApiResponseModel(isSuccess: false, message: error)
Repository checks response.isSuccess → throws ResponseException(response.message)
BaseCubit.safeCall catches ResponseException → emits ErrorState(message)
BlocBuilder receives ErrorState → displays BasicErrorContainer
```

---

## POST Request Pattern

```dart
Future<void> submitData(MyRequestModel request) async {
  final response = await networkService.postData<MyResponseModel>(
    endpoint: EndpointConstants.myEndpoint,
    body: request.toJson(),
    parser: (json) => MyResponseModel.fromJson(convertToMap(json) ?? {}),
  );
  if (!response.isSuccess) throw ResponseException(response.message);
  return response.data ?? const MyResponseModel();
}
```

---

## RemoteRepository / RemoteDataSource Base Classes

Two base classes exist (legacy/alternative approaches):

```dart
// Constructor injection approach
abstract class RemoteRepository {
  const RemoteRepository();
  NetworkService get networkService =>
      AppDependency.injector.get<NetworkService>();
}

// Field injection approach
abstract class RemoteDataSource {
  RemoteDataSource({NetworkService? networkService})
    : _networkService = networkService ?? AppDependency.injector.get<NetworkService>();

  NetworkService get networkService => _networkService;
  final NetworkService _networkService;
}
```

**Current dominant pattern**: Repositories take `NetworkService` as a constructor parameter (not using these base classes directly):
```dart
final class RemoteBannerRepository with JsonConverterMixin implements BannerRepository {
  const RemoteBannerRepository(this.networkService);
  final NetworkService networkService;
}
```

---

## Always / Never

### Always
- Depend on abstract `NetworkService`, not `DioNetworkManager`
- Use `EndpointConstants` for endpoint strings
- Check `response.isSuccess` and throw `ResponseException` in repositories
- Use `JsonConverterMixin` for type-safe JSON conversion in repositories
- Return safe defaults (`response.data ?? []` or `response.data ?? const Model()`) 

### Never
- Use Dio directly in repositories or cubits
- Hardcode endpoint strings outside `EndpointConstants`
- Return raw `Map<String, dynamic>` from repositories — always parse to typed models
- Ignore `response.isSuccess` — always validate
- Add Dio interceptors without registering them in the DI Dio factory
