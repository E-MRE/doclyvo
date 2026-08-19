# Error Handling

## Error Flow Overview

```
API call fails / returns isSuccess: false
    ↓
Repository throws ResponseException
    ↓
BaseCubit.safeCall catches it
    ↓
Emits ErrorState(message: e.message)
    ↓
BlocBuilder receives ErrorState
    ↓
Widget renders BasicErrorContainer with retry button
```

---

## Exception Types

### `ResponseException`
File: `lib/core/error/response_exception.dart`

Thrown by repositories when the API response indicates failure (`isSuccess = false`).

```dart
final class ResponseException implements Exception {
  const ResponseException(this.message);
  final String message;

  @override
  String toString() => message;
}
```

**Usage in repositories**:
```dart
if (!response.isSuccess) {
  throw ResponseException(response.message);
}
```

### `JsonException`
File: `lib/core/error/json_exception.dart`

Thrown by `JsonConverterMixin.convertToMap()` when the JSON is not a `Map<String, dynamic>`.

```dart
final class JsonException implements Exception {
  const JsonException();
  String get message => LocaleKeys.errors_jsonTypeError.tr();

  @override
  String toString() => message;
}
```

The message is localized — comes from `LocaleKeys.errors_jsonTypeError`.

---

## BaseCubit Error Catching

`BaseCubit.safeCall` catches in this priority order:

```dart
try {
  safeEmit(loadingState);
  final result = await action();
  safeEmit(successState(result));
} on ResponseException catch (e) {
  safeEmit(errorState(e.message));   // ← API failure (most specific)
} on JsonException catch (e) {
  safeEmit(errorState(e.message));   // ← Malformed JSON
} on Exception catch (e) {
  safeEmit(errorState(e.toString())); // ← Any other exception
}
```

**Rule**: Never add additional `try/catch` inside `safeCall`'s `action` closure. Let exceptions propagate up to `safeCall`.

---

## Repository Error Pattern

Every repository method follows this exact pattern:

```dart
Future<List<BannerModel>> getBanners() async {
  final response = await networkService.fetchData<List<BannerModel>>(
    endpoint: EndpointConstants.banners,
    parser: (json) => convertToList(parser: BannerModel.fromJson, json: json),
  );

  // Always check isSuccess
  if (!response.isSuccess) {
    throw ResponseException(response.message);  // ← throw, never return error
  }

  return response.data ?? [];  // ← safe default
}
```

**Rule**: Repositories throw exceptions — they do NOT return error states or null values.

---

## Error State Pattern

Every cubit domain has a typed error state:

```dart
final class BannerError implements BannerState {
  const BannerError({this.message = ''});
  final String message;
}
```

- `message` is always a non-null `String` (default `''`)
- Message comes from the exception — already localized if from `JsonException`

---

## Error UI — BasicErrorContainer

```dart
BasicErrorContainer(
  height: height,
  width: double.infinity,
  buttonText: LocaleKeys.errors_tryAgain.tr(),
  onPressed: () async => cubit.retryMethod(),
  message: state.message,
)
```

**Rule**: Always include a retry callback (`onPressed`). Use `LocaleKeys.errors_tryAgain` for button text.

---

## Network-Level Error Handling

`DioNetworkManager` catches all exceptions and converts them to `ApiResponseModel` with `isSuccess: false`:

```dart
Future<ApiResponseModel<TData>> _getRawResponse<TData>({...}) async {
  try {
    final response = await requestFunction;
    return ApiResponseModel<TData>.fromJson(response.data ?? {}, parser: parser);
  } on Exception catch (exception) {
    return ApiResponseModel<TData>(message: exception.toString());
    // isSuccess defaults to false — repository will throw ResponseException
  }
}
```

---

## Crashlytics Error Logging

Flutter and platform errors are caught globally in `AppInitializer` via `CrashlyticsInitializerMixin`:

```dart
FlutterError.onError = handleFlutterError;

PlatformDispatcher.instance.onError = (error, stack) {
  final details = FlutterErrorDetails(exception: error, stack: stack);
  handleFlutterError(details);
  return true;
};
```

The `handleFlutterError` method:
1. Records to Firebase Crashlytics (release) or console (debug)
2. Dumps to console via `FlutterError.dumpErrorToConsole`
3. Calls `onErrorLog` override for custom logging

---

## Debug vs Release Error Reporting

`CrashlyticsServiceFactory` selects implementation based on `kDebugMode`:

```dart
final class CrashlyticsServiceFactory {
  CrashlyticsService create() {
    if (kDebugMode) {
      return ConsoleCrashlyticsManager();  // prints to console
    }
    return FirebaseCrashlyticsManager();   // sends to Firebase
  }
}
```

---

## Always / Never

### Always
- Throw `ResponseException` from repositories when `!response.isSuccess`
- Return safe defaults (`response.data ?? []` or `response.data ?? const Model()`)
- Let `safeCall` handle all exception catching in cubits
- Show `BasicErrorContainer` with retry on error states
- Use `LocaleKeys.errors_tryAgain` for retry button text

### Never
- Return `null` from repositories — throw or return a default
- Catch exceptions inside `safeCall`'s action closure
- Swallow exceptions silently
- Show raw technical error messages in UI without localization
- Use `print()` for error logging — use `debugPrint()` or the crashlytics service
