---
name: mars-unit-test
description: Generates project-consistent unit tests for a Flutter cubit, repository, or model, mirroring lib/ under test/ and following the house test style (blocTest Initial→Loading→Success/Error, mock NetworkService for repositories, tearDown cubit.close(), never test *.g.dart). Detects bloc_test/mocktail availability, runs flutter test --coverage, and reports uncovered branches. Trigger phrases include "test yaz", "unit test ekle", "şu cubit'i test et", "coverage artır", "write unit tests", "add tests for this", "test this repository", "/mars-test".
invocation: /mars-test, /unit-test, /mars-cover
---

# Mars Unit Test

Bir cubit / repository / model için projeye tutarlı unit test'ler üretir; `lib/` yapısını `test/` altında mirror'lar ve ev stiline (blocTest, mock NetworkService) uyar.

> **Not:** Test stili kaynağı: `.claude/reference/flutter/skills/testing.md`. `bloc_test` + `mocktail` yoksa önce onları eklemeyi önerir. Generated kod (`*.g.dart`) test edilmez.

## Ne Zaman Kullanılır

- Yeni bir cubit/repository/model'e test eklerken
- `/mars-implement-ticket` sonrası kapsamı tamamlarken
- `/mars-bug-finder` bulgusu için reprodüksiyon testi yazarken
- Coverage boşluklarını kapatırken

---

## Kullanım

```
/mars-test <hedef: cubit/repo/model dosyası veya adı>
/unit-test <path>
/mars-cover <feature>
```

**Örnekler:**
```
/mars-test lib/features/home/cubit/banner_cubit.dart
/unit-test RemoteBannerRepository
/mars-cover features/profile        # feature'daki eksik testleri üret
```

---

## Workflow

### Faz 1: Hedef Tespiti

Neyin test edileceğini belirle (cubit / repository / model / widget) ve `lib/` içindeki path'ini bul. Argüman yoksa sor. Widget testi istenirse minimal `pumpWidget` + finder yaklaşımı kullan; asıl odak cubit/repository/model.

### Faz 2: Bağımlılık Analizi

- Hedefin collaborator'larını çıkar (repository, `NetworkService`, başka cubit) → bunlar mock'lanacak.
- `pubspec.yaml`'da `bloc_test` ve `mocktail` var mı kontrol et. Yoksa öner:
  ```yaml
  dev_dependencies:
    bloc_test: ^9.x.x
    mocktail: ^1.x.x
  ```
  Kullanıcı onaylamadan pubspec'i değiştirme.
- Mock sınıflarını tanımla: `class MockXRepository extends Mock implements XRepository {}`, `class MockNetworkService extends Mock implements NetworkService {}`.

### Faz 3: Test Üretimi

Testi `test/` altında **lib/ yapısını mirror'layan** path'e yaz. Örn `lib/features/home/cubit/banner_cubit.dart` → `test/features/home/cubit/banner_cubit_test.dart`.

**Cubit testi** (Initial → Loading → Success/Error, Loading ASLA atlanmaz):
```dart
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
      'emits [Loading, Success] when getBanners succeeds',
      build: () {
        when(() => mockRepository.getBanners())
            .thenAnswer((_) async => [const BannerModel(imageUrl: '/test.jpg')]);
        return cubit;
      },
      act: (c) => c.getBanners(),
      expect: () => [isA<BannerLoading>(), isA<BannerSuccess>()],
    );

    blocTest<BannerCubit, BannerState>(
      'emits [Loading, Error] when getBanners throws',
      build: () {
        when(() => mockRepository.getBanners())
            .thenThrow(const ResponseException('API failed'));
        return cubit;
      },
      act: (c) => c.getBanners(),
      expect: () => [isA<BannerLoading>(), isA<BannerError>()],
    );
  });
}
```

**Repository testi** (isSuccess true/false → `ResponseException`):
```dart
test('getBanners throws ResponseException when isSuccess is false', () async {
  when(() => mockNetworkService.fetchData<List<BannerModel>>(
        endpoint: any(named: 'endpoint'),
        parser: any(named: 'parser'),
      )).thenAnswer((_) async =>
      const ApiResponseModel(isSuccess: false, message: 'Server error'));

  expect(() => repository.getBanners(), throwsA(isA<ResponseException>()));
});
```

**Model testi:** `fromJson`/`toJson` round-trip + default değerler. `*.g.dart` çağrısını dolaylı doğrula, doğrudan test etme.

### Faz 4: Çalıştırma & Kapsam

```bash
flutter test --coverage
# opsiyonel: lcov özeti
# gencov / lcov ile uncovered satırları özetle
```

Uncovered branch'leri (özellikle Error state ve edge case'ler) raporla ve eksikler için ek test öner.

---

## Çıktı Formatı

```markdown
# 🧪 Unit Test Raporu: <hedef>

## Üretilen Test Dosyaları
| Dosya | Tür | Test Sayısı |
|-------|-----|-------------|
| `test/features/home/cubit/banner_cubit_test.dart` | Cubit | 3 |
| `test/features/home/repositories/remote_banner_repository_test.dart` | Repo | 2 |

## Kapsam
| Metrik | Önce | Sonra |
|--------|------|-------|
| Coverage | X% | Y% |
| Kapsanmayan branch | <liste> | |

## ✅ Always/Never Uyumu
- [x] lib/ yapısı test/ altında mirror'landı
- [x] Cubit testleri Initial→Loading→Success/Error
- [x] Repository mock NetworkService ile
- [x] tearDown(() => cubit.close())
- [x] *.g.dart test edilmedi

## Çalıştırma
\`\`\`bash
flutter test --coverage
\`\`\`
Sonuç: <geçti/kaldı + sayı>

---
🤖 Oluşturan: Claude Code
```

---

## Sınırlamalar

### Yapılır
- Cubit/repository/model için konvansiyona uygun test üretimi
- `lib/` → `test/` mirror yapısı
- Mock kurulumu (mocktail) ve blocTest
- `flutter test --coverage` + uncovered branch raporu

### Yapılmaz
- Generated kod (`*.g.dart`) testi
- Cubit testinde Loading state'i atlama
- Onaysız `pubspec.yaml` değişikliği (dev_dependency eklemeyi önce önerir)
- Integration/E2E test (→ `maestro-add`)
- Backend testi

---

## İlgili Skill'ler

- `/mars-implement-ticket` - Test edilecek feature'ı üretmek için
- `/mars-bug-finder` - Reprodüksiyon senaryosu için
- `/maestro-add` - E2E/UI test için
- `/sc:test` - SuperClaude test akışı (opsiyonel)
