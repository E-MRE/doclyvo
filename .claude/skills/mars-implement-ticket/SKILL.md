---
name: mars-implement-ticket
description: Turns a ticket (Jira/GitHub issue text or a plain description) into a planned, convention-correct Flutter implementation. Reads the project's CLAUDE.md and reference/flutter/* conventions first, produces a file-by-file plan, waits for approval, then generates code that follows the house architecture (final classes, BaseCubit + safeCall, abstract→concrete repositories, design tokens, localization). Trigger phrases include "ticket'ı implemente et", "şu feature'ı yaz", "issue'yu koda dök", "implement this ticket", "build this feature", "add this screen", "/mars-ticket".
invocation: /mars-ticket, /mars-implement, /ticket
---

# Mars Implement Ticket

Bir ticket'ı (Jira/GitHub issue metni veya düz açıklama) alır, önce projeyi ve Mars konvansiyonlarını okur, dosya-dosya bir plan çıkarır, **onay bekler**, sonra konvansiyona uygun kod üretir.

> **Not:** Kod yazmadan önce **Faz 3'te planı gösterir ve onay bekler** — onaysız dosya değiştirilmez. Konvansiyon kaynağı: proje `CLAUDE.md` + `.claude/reference/flutter/*`. Bunlar yoksa mevcut kod stilinden çıkarım yapar.

## Ne Zaman Kullanılır

- Bir ticket / issue / task açıklamasını Flutter feature'ına çevirirken
- Yeni bir ekran, cubit, repository veya endpoint eklerken
- Mevcut projenin mimari kurallarına birebir uyan kod istendiğinde
- Feature scaffold'u (model → repo → cubit → view → widget → DI) kurarken

---

## Kullanım

```
/mars-ticket <ticket metni veya issue no/url>
/mars-implement <açıklama>
/ticket <metin>
```

**Örnekler:**
```
/mars-ticket PROJ-123: Kullanıcı profili ekranı ekle, avatar + isim + çıkış butonu
/mars-implement "Ana sayfaya kampanya listesi ekle, /campaigns endpoint'inden çek"
/mars-ticket https://github.com/org/repo/issues/42
```

---

## Workflow

### Faz 1: Ticket Parse

Ticket'tan çıkar: **hedef**, **kabul kriterleri (acceptance criteria)**, **etkilenen feature/modül**, **kapsam dışı**. Argüman yoksa veya kabul kriterleri belirsizse kullanıcıya sor — varsayım yapma.

GitHub issue verildiyse:
```bash
gh issue view <number> --json title,body,labels
```

### Faz 2: Proje Okuma (ZORUNLU)

Kod yazmadan önce oku (varsa):
```
CLAUDE.md
.claude/reference/flutter/skills/architecture.md      # katman kuralları
.claude/reference/flutter/skills/coding_standards.md  # final class, const, quotes
.claude/reference/flutter/skills/state_management.md  # BaseCubit, safeCall, 4-state
.claude/reference/flutter/skills/networking.md        # NetworkService, ApiResponseModel
.claude/reference/flutter/skills/do_not_do.md         # yasaklı pattern'ler
.claude/reference/flutter/patterns/feature_creation_flow.md
```

Ayrıca **benzer bir mevcut feature'ı tara** ve o projenin gerçek pattern'ini örnek al (import stili, klasör düzeni, DI kaydı). Kod yazım kuralları için `/mars-flutter-implement` skill'indeki 16 kuralı uygula.

### Faz 3: Plan Üretimi (ONAY BEKLE)

Aşağıdaki sırayla dosya-dosya bir plan çıkar (Feature-First Clean):

```
features/<feature>/
├── data/
│   ├── models/<x>_model.dart              # @JsonSerializable, defaults
│   └── repositories/
│       ├── <x>_repository.dart            # abstract interface
│       └── remote_<x>_repository.dart     # concrete + NetworkService
├── cubit/
│   ├── <x>_cubit.dart                     # BaseCubit<XState> + safeCall
│   └── <x>_state.dart                     # Initial/Loading/Success/Error
├── view/<x>_screen.dart                   # StatefulWidget + _ScreenStateMixin
└── widget/<x>_*.dart                      # private/feature-local widget'lar
+ DI kaydı (AppDependency): registerFactory<XCubit>, registerFactory<XRepository>
+ Localization anahtarları (LocaleKeys.*) + translation json
```

Planı kullanıcıya göster: her dosya, sorumluluğu, kabul kriteriyle eşlemesi. **Onay al** ("uygula" / "devam" / seçici değişiklik). Onaysız Faz 4'e geçme.

### Faz 4: Implementasyon

Onaylanan plana göre kod üret. Zorunlu kurallar (`reference/flutter/skills/*` + `/mars-flutter-implement` 16 kuralı):

- `final class` her widget/sınıfta; `sort_constructors_first`; tek tırnak.
- `const` default; hardcoded değer yok — renk `AppColors.*`/`context.colorScheme`, spacing `Sizes/AppInsets`, radius `AppBorderRadius`.
- Cubit: `BaseCubit<State>` + `safeCall`/`safeEmit`; `isClosed` guard; state 4 sınıf (Initial/Loading/Success/Error), Loading atlanmaz.
- Repository: `abstract interface class` + `Remote<X>Repository`; `!isSuccess` → `throw ResponseException`.
- DI: `late final`, `AppDependency.injector` üzerinden; cubit/repo `registerFactory`, service `registerSingleton`.
- Widget'lar 50 satırı geçince private class'a böl; 200+ satır dosyada `part`/`part of`.
- UI string yok → `LocaleKeys.*.tr()`; navigation `context.push/go` (Navigator.of yok).
- `mounted`/`isClosed` kontrolleri; controller/stream dispose.

### Faz 5: Doğrulama & Devir

```bash
flutter analyze                                   # 0 issue hedefi
# generated dosya (model .g.dart) eklendiyse:
dart run build_runner build --delete-conflicting-outputs
```

Kabul kriterlerini kod ile eşleyen bir checklist üret. Sonra test için `/mars-unit-test`'e, gözden geçirme için `/mars-gh-pr-review`'e yönlendir.

---

## Çıktı Formatı

```markdown
# 🎫 Ticket Implementasyonu: <ticket-id / başlık>

## 📋 Kabul Kriterleri → Kod Eşlemesi
- [x] <kriter 1> → `features/x/view/x_screen.dart`
- [x] <kriter 2> → `features/x/cubit/x_cubit.dart`
- [ ] <kriter 3> → <manuel test gerekli>

## 📂 Değişen / Eklenen Dosyalar
| Dosya | Tür | Sorumluluk |
|-------|-----|-----------|
| `.../x_model.dart` | Yeni | Veri modeli (JsonSerializable) |
| `.../remote_x_repository.dart` | Yeni | API erişimi |
| `.../x_cubit.dart` | Yeni | State yönetimi |

## ✅ Doğrulama
- flutter analyze: <sonuç>
- build_runner: <çalıştırıldı mı>
- Sonraki adım: `/mars-unit-test x_cubit`

---
🤖 Oluşturan: Claude Code
```

---

## Sınırlamalar

### Yapılır
- Ticket → dosya-dosya plan + onay sonrası kod üretimi
- Proje konvansiyonlarına (reference/flutter, CLAUDE.md) tam uyum
- Kabul kriteri ↔ kod eşlemesi
- `flutter analyze` + `build_runner` doğrulaması

### Yapılmaz
- Onaysız kod yazma (Faz 3 gate'i)
- Test üretimi (→ `/mars-unit-test`)
- Commit / PR açma / merge
- Backend/API tarafı değişikliği
- Belirsiz kabul kriterlerinde varsayım (önce sorar)

---

## İlgili Skill'ler

- `/mars-project-overview` - Önce projeyi ve konvansiyonları anlamak için
- `/mars-unit-test` - Üretilen kod için test yazmak için
- `/mars-bug-finder` - Implementasyon sonrası triyaj için
- `/mars-gh-pr-review` - Değişikliği review etmek için
- `/sc:implement` - SuperClaude implementasyon akışı (opsiyonel)
