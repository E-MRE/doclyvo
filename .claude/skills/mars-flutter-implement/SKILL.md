---
name: mars-flutter-implement
description: Implements a Flutter feature from a short description (screen, cubit, widget, service) with clean, lint-free, convention-correct code — reads the project first, presents a short plan, then writes code following 16 mandatory rules (final classes, const, design tokens, theme colors, BLoC/Cubit with isClosed/SafeEmit, abstract interface services, widget decomposition, freezed switch, dispose). Trigger phrases include "şunu implemente et", "widget yaz", "cubit oluştur", "implement", "build this screen", "create a service", "/mars-flutter-implement".
invocation: /mars-flutter-implement, /flutter-implement, /implement
---

# Mars Flutter Implement

Kısa bir açıklamadan (ekran / cubit / widget / service) temiz, lint-free ve konvansiyona
uygun Flutter kodu üretir. Önce projeyi okur, kısa bir plan gösterir, sonra 16 zorunlu
kurala uyarak kod yazar.

> **Not:** Bu skill genel "şunu implemente et" komutudur. Bir **ticket/issue**'dan tam
> feature scaffold'u (model→repo→cubit→view→DI→l10n + kabul kriteri eşlemesi) istiyorsan
> `/mars-implement-ticket` kullan. Konvansiyon kaynağı: `.claude/reference/flutter/*` + `CLAUDE.md`.

## Ne Zaman Kullanılır

- Tekil bir widget / ekran / cubit / service yazarken
- Hızlı, kurallara uygun bir Flutter parçası eklerken
- `/mars-screenshot-to-code` çıktısını genişletirken

---

## Kullanım

```
/mars-flutter-implement <ne implemente edilecek>
/flutter-implement <açıklama>
/implement <açıklama>
```

**Örnekler:**
```
/mars-flutter-implement ProfileScreen with edit functionality
/flutter-implement WalletCubit with transaction history
/implement SearchBar widget with debounce
```

---

## Workflow

### Faz 1: Önce Projeyi Oku

Kod yazmadan önce mevcut yapıyı anla:
1. **CLAUDE.md + `reference/flutter/*`** oku — proje kurallarını uygula.
2. **Benzer feature'ları tara** — aynı domaindeki cubit/service/view/widget örneklerini bul.
3. **Paylaşılan bileşenler** — `lib/product/widget/`, `lib/shared/`, `lib/core/` vb. kontrol et.
4. **Design token'lar** — spacing/color sabitlerini bul (`Sizes`, `AppColors`, `AppInsets`).
5. **Routing** — hangi router (go_router / auto_route / Navigator).
6. **State management** — hangi pattern (BaseCubit / Cubit / Riverpod).

### Faz 2: Kısa Plan Göster

Kod yazmadan önce kullanıcıya göster: oluşturulacak dosyalar + dizin yapısı, yeniden
kullanılacak mevcut bileşenler, eksik dependency'ler. Belirsizse sor.

### Faz 3: Kodu Yaz (16 Zorunlu Kural)

1. **Widget sınıfları `final class`** (`final class MyScreen extends StatelessWidget`); private widget `final class _MyWidget`.
2. **Her yerde `const`** (`const SizedBox(height: 16)`, `const Duration(...)`, `const Text(...)`).
3. **Design token — hardcoded değer yok**; proje spacing/size sabitlerini kullan (`Sizes.md`, `AppRadius.sm`). Token yoksa magic number'dan kaçın.
4. **Renkler daima Theme'den**: `context.colorScheme.primary`, `.onSurface.withValues(alpha: .6)`. `Colors.red` / `Color(0xFF...)` yok.
5. **`ColoredBox`/`DecoratedBox`** — sadece renk/dekorasyon için `Container` kullanma.
6. **Cascade notation**: `_controller..reset()..forward();`.
7. **State management BLoC/Cubit**: `isClosed` guard'ı (veya `SafeEmit`), state Initial/Loading/Complete/Error.
   ```dart
   Future<void> fetchData() async {
     if (isClosed) return;
     emit(const FeatureState.loading());
     try {
       final data = await _service.fetchData();
       if (isClosed) return;
       emit(FeatureState.complete(data));
     } catch (e) {
       if (isClosed) return;
       emit(FeatureState.error(e.toString()));
     }
   }
   ```
8. **Service interface pattern**: `abstract interface class IFeatureService` + `final class FeatureService implements IFeatureService`.
9. **Async context safety**: `await` sonrası `if (!mounted) return;` (widget) / `if (isClosed) return;` (cubit).
10. **Widget decomposition**: 50+ satır → private widget'a böl (`_Header`, `_Body`, `_ActionButton`).
11. **`part`/`part of`**: 200+ satır dosyada `view/_x_header.dart` şeklinde parçala.
12. **Switch pattern matching** (freezed/sealed): `return switch (state) { ... }` — `is` cast'leri yerine.
13. **Trailing comma** her multi-line yapıda.
14. **Expression body** basit metodlarda: `Widget build(...) => const Text('Hi');`.
15. **Controller dispose**: `dispose()`'da tüm controller/scroll/animation dispose edilir.
16. **Minimal comment**: sadece non-obvious mantık veya public API için yorum.

### Faz 4: Kalite Checklist

```
[ ] Tüm mümkün const'lar uygulandı
[ ] final class tüm widget'larda
[ ] Renkler sadece context.colorScheme'den
[ ] ColoredBox/DecoratedBox (gereğinde Container yerine)
[ ] Design token'lar kullanıldı
[ ] Trailing comma'lar
[ ] 50+ satır widget'lar extract edildi
[ ] 200+ satır dosyada part/part of
[ ] await sonrası mounted / isClosed kontrolü
[ ] Service interface arkasında
[ ] Controller'lar dispose edildi
[ ] Gereksiz comment yok
[ ] flutter analyze → 0 issue
```

---

## Feature Dizin Yapısı

```
lib/features/<domain>/<feature>/
├── cubit/     <feature>_cubit.dart, <feature>_state.dart
├── model/     <feature>_model.dart (+ .g.dart)
├── service/   i_<feature>_service.dart, <feature>_service.dart
├── view/      <feature>_view.dart, <feature>_mixin.dart, view/ (200+ satır)
└── widget/    <feature>_card.dart, <feature>_list_tile.dart
```

---

## Çıktı Formatı

```markdown
# ⚙️ Implementasyon: <ne>

## 📂 Oluşturulan Dosyalar
| Dosya | Tür |
|-------|-----|
| `.../feature_cubit.dart` | Cubit |
| `.../feature_view.dart` | View |

## ✅ Kural Uyumu
- flutter analyze: <sonuç>
- Checklist: <özet>

---
🤖 Oluşturan: Claude Code
```

---

## Sınırlamalar

### Yapılır
- Kısa açıklamadan konvansiyona uygun Flutter kodu üretimi
- 16 kural + kalite checklist uygulaması
- Proje okuma + kısa plan gösterme

### Yapılmaz
- Ticket'tan tam scaffold + kabul kriteri eşlemesi (→ `/mars-implement-ticket`)
- Test üretimi (→ `/mars-unit-test`)
- Onaysız büyük mimari değişiklik (önce plan gösterir)
- Commit / PR açma

---

## İlgili Skill'ler

- `/mars-implement-ticket` - Ticket'tan tam feature akışı için
- `/mars-unit-test` - Üretilen kod için test yazmak için
- `/mars-bug-finder` - Implementasyon sonrası triyaj için
- `/mars-screenshot-to-code` - Görselden UI kodu üretmek için
