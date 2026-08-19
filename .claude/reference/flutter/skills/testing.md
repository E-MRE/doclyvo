# Testing

## Current Test Setup

The project has a minimal test setup. Only one test file exists:

**`test/widget_test.dart`** — Flutter-generated placeholder.

No unit tests, cubit tests, or repository tests are implemented yet.

---

## Test Stack (Available in pubspec.yaml)

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
```

No additional test packages are configured yet (`bloc_test`, `mocktail`, `mockito`).

---

## How Tests Should Be Written (Project-Consistent Style)

When tests are added, they must follow the same architectural patterns.

### Cubit Unit Tests

Following project conventions (when `bloc_test` is added):

```dart
// test/features/home/cubit/banner_cubit_test.dart

void main() {
  late BannerCubit cubit;
  late MockBannerRepository mockRepository;

  setUp(() {
    mockRepository = MockBannerRepository();
    cubit = BannerCubit(mockRepository);
  });

  tearDown(() => cubit.close());

  group('BannerCubit', () {
    test('initial state is BannerInitial', () {
      expect(cubit.state, isA<BannerInitial>());
    });

    blocTest<BannerCubit, BannerState>(
      'emits [BannerLoading, BannerSuccess] when getBanners succeeds',
      build: () {
        when(() => mockRepository.getBanners())
            .thenAnswer((_) async => [const BannerModel(imageUrl: '/test.jpg')]);
        return cubit;
      },
      act: (cubit) => cubit.getBanners(),
      expect: () => [
        isA<BannerLoading>(),
        isA<BannerSuccess>(),
      ],
    );

    blocTest<BannerCubit, BannerState>(
      'emits [BannerLoading, BannerError] when getBanners throws',
      build: () {
        when(() => mockRepository.getBanners())
            .thenThrow(const ResponseException('API failed'));
        return cubit;
      },
      act: (cubit) => cubit.getBanners(),
      expect: () => [
        isA<BannerLoading>(),
        isA<BannerError>(),
      ],
    );
  });
}
```

### Repository Unit Tests

```dart
// test/features/home/data/repositories/remote_banner_repository_test.dart

void main() {
  late MockNetworkService mockNetworkService;
  late RemoteBannerRepository repository;

  setUp(() {
    mockNetworkService = MockNetworkService();
    repository = RemoteBannerRepository(mockNetworkService);
  });

  test('getBanners returns list when isSuccess is true', () async {
    when(() => mockNetworkService.fetchData<List<BannerModel>>(
      endpoint: any(named: 'endpoint'),
      parser: any(named: 'parser'),
    )).thenAnswer((_) async => const ApiResponseModel(
      isSuccess: true,
      data: [BannerModel(imageUrl: '/test.jpg')],
    ));

    final result = await repository.getBanners();
    expect(result, isA<List<BannerModel>>());
    expect(result.length, 1);
  });

  test('getBanners throws ResponseException when isSuccess is false', () async {
    when(() => mockNetworkService.fetchData<List<BannerModel>>(
      endpoint: any(named: 'endpoint'),
      parser: any(named: 'parser'),
    )).thenAnswer((_) async => const ApiResponseModel(
      isSuccess: false,
      message: 'Server error',
    ));

    expect(() => repository.getBanners(), throwsA(isA<ResponseException>()));
  });
}
```

---

## Test File Organization

When tests are added, mirror the `lib/` structure under `test/`:

```
test/
├── features/
│   └── home/
│       ├── cubit/
│       │   ├── banner_cubit_test.dart
│       │   ├── campaign_cubit_test.dart
│       │   └── ...
│       ├── data/
│       │   └── repositories/
│       │       ├── remote_banner_repository_test.dart
│       │       └── ...
│       └── models/
│           └── banner_model_test.dart
└── core/
    ├── network/
    │   └── dio_network_manager_test.dart
    └── states/
        └── base_cubit_test.dart
```

---

## Recommended Test Dependencies to Add

```yaml
dev_dependencies:
  bloc_test: ^9.x.x
  mocktail: ^1.x.x  # preferred for modern null-safe mocking
```

---

## Always / Never

### Always
- Mirror `lib/` structure in `test/`
- Test cubits with `blocTest` (Initial → Loading → Success/Error)
- Test repositories with mock `NetworkService`
- `tearDown(() => cubit.close())` for all cubit tests

### Never
- Test generated code (`*.g.dart`)
- Skip the Loading state in cubit test expectations
- Use `flutter_test` for pure Dart logic — use `dart:test` instead
