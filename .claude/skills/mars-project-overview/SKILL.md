---
name: mars-project-overview
description: Quickly analyzes a Flutter project and produces an onboarding summary — stack, architecture, dependencies, critical files — AND scores the repo against the Mars/team conventions in reference/flutter/*. Use before plan mode, when onboarding a new teammate, or to audit convention drift. Trigger phrases include "projeyi incele", "proje özeti çıkar", "mars uyum skoru", "onboarding özeti", "project overview", "scan this repo", "how does this project work", "/mars-overview".
invocation: /mars-overview, /mars-scan, /mars-onboard, /overview, /onboard
---

# Mars Project Overview

Flutter projesini hızlıca analiz eder; yapı, mimari ve kritik dosyaları özetler, ardından repoyu **Mars konvansiyonlarına** (`reference/flutter/*`) karşı puanlar.

> **Not:** Standart proje analizine ek olarak **Faz 3 — Mars Uyum Kontrolü** yapar. Sadece analiz eder, kod değiştirmez. Detaylı kod analizi için `/mars-bug-finder`, yeni feature için `/mars-implement-ticket` kullanın.

## Ne Zaman Kullanılır

- Yeni bir projeye başlarken veya plan modu öncesi context toplarken
- Yeni takım üyesini projeye alıştırırken (onboarding)
- Projenin Mars/takım standartlarına ne kadar uyduğunu ölçerken
- Refactor/temizlik önceliklerini belirlemeden önce

---

## Kullanım

```
/mars-overview
/mars-scan ./my_app
/mars-onboard
```

**Örnekler:**
```
/mars-overview               # Mevcut dizindeki projeyi analiz et + uyum skoru
/mars-scan ./packages/app    # Belirli bir paketi/projeyi analiz et
/mars-onboard                # Yeni geliştirici için genişletilmiş özet
```

---

## Workflow

### Faz 1: Proje Root & Stack Tespiti

```bash
# Kritik dosyaları kontrol et
[ ] pubspec.yaml           # Flutter projesi doğrulama + isim/versiyon
[ ] analysis_options.yaml  # Lint kuralları (very_good_analysis?)
[ ] CLAUDE.md              # Proje standartları (varsa mutlaka oku)
[ ] .claude/reference/     # Mars referans bilgi tabanı kurulu mu?
[ ] README.md              # Proje dokümantasyonu
```

`pubspec.yaml`'dan stack çıkar: state management (bloc/riverpod/provider/getx), navigation (go_router/auto_route), networking (dio/http), storage (hive/shared_preferences/drift), code-gen (freezed/json_serializable/envied/easy_localization).

### Faz 2: Mimari & Katman Haritası

```bash
tree lib/ -L 3 -d          # veya: find lib -type d -maxdepth 3
```

Mimariyi sınıflandır:

```
┌─────────────────────────────────────────────────────────────────┐
│ MİMARİ PATTERN TESPİTİ                                            │
├──────────────────────┬──────────────────────────────────────────┤
│ Feature-First Clean  │ features/<x>/data + presentation, app/    │
│ Layer-First          │ data/, domain/, presentation/ (root)      │
│ BLoC/Cubit           │ *_cubit.dart, *_state.dart, flutter_bloc  │
│ Repository Pattern   │ *_repository.dart, Remote<X>Repository    │
└──────────────────────┴──────────────────────────────────────────┘
```

### Faz 3: Mars Uyum Kontrolü (YENİ)

Repoyu `reference/flutter/skills/*` ve `reference/flutter/patterns/*` heuristiklerine karşı tara. Referans kurulu değilse (`.claude/reference/` yok) bu fazı atla ve raporda "referans kurulu değil — `setup.sh` çalıştır" notu düş.

Kontrol edilen kurallar ve tarama komutları:

```bash
# 1. Widget'lar `final class` mı? (final olmayanlar 🔴)
grep -rn "^class .*extends .*Widget" lib/ | grep -v "final class"

# 2. Hardcoded renk var mı? (design token yerine Colors.* / Color(0x...))
grep -rn "Colors\.\|Color(0x" lib/ | grep -v "//"

# 3. Hardcoded spacing/radius (EdgeInsets.all(16), BorderRadius.circular(...))
grep -rn "EdgeInsets\.\|BorderRadius.circular" lib/ | grep -v "AppInsets\|Sizes\|AppBorderRadius"

# 4. Navigator.of kullanımı (go_router beklenirken)
grep -rn "Navigator\.of\|Navigator\.push" lib/

# 5. Hardcoded UI string (LocaleKeys yerine)
grep -rn "Text('" lib/ | grep -v "LocaleKeys\|\.tr()"

# 6. Katman ihlali (repository/cubit içinde doğrudan Dio importu vb.)
grep -rn "import 'package:dio" lib/features/*/presentation 2>/dev/null

# 7. test/ dizini lib/ yapısını mirror'lıyor mu?
diff <(find lib -type d | sed 's|^lib/||') <(find test -type d | sed 's|^test/||') 2>/dev/null
```

Her kural için 🔴/🟡/🟢 ver ve bir **Uyum Skoru** tablosu üret.

### Faz 4: Kritik Dosya Listesi

```
┌──────────────────────┬──────────────────────────────────────────┐
│ Kategori             │ Dosyalar                                 │
├──────────────────────┼──────────────────────────────────────────┤
│ Entry Point          │ lib/main.dart                            │
│ App/DI               │ lib/app/*.dart, AppDependency.injector   │
│ Router               │ lib/app/router/*.dart                    │
│ Design System        │ lib/**/design_system, Sizes/AppColors    │
│ Networking           │ NetworkService / DioNetworkManager       │
│ Localization         │ assets/translations/, LocaleKeys         │
│ Environment          │ .env*, Configurations                    │
└──────────────────────┴──────────────────────────────────────────┘
```

### Faz 5: Özet Rapor & Başlangıç Komutları

Aşağıdaki çıktı formatını üret.

---

## Çıktı Formatı

```markdown
# 📱 Proje Özeti: <proje-adı>

## 🔧 Teknoloji Stack
| Kategori | Değer |
|----------|-------|
| Flutter / Dart SDK | x.x.x / x.x.x |
| State Management | BLoC/Cubit / Riverpod / ... |
| Navigation | GoRouter / ... |
| Networking | Dio / ... |
| Code Gen | Freezed / JsonSerializable / Envied |

## 📁 Proje Yapısı
\`\`\`
lib/
├── app/        # config, router, DI
├── core/       # network, states, extensions
└── features/   # feature modülleri
\`\`\`

## 🎯 Tespit Edilen Patternler
| Pattern | Durum |
|---------|-------|
| Feature-First Clean | ✅ |
| Repository Pattern | ✅ |
| BaseCubit + safeCall | ✅ |

## 🏅 Mars Uyum Skoru
| Kural | Durum | Bulgu |
|-------|-------|-------|
| final class widgets | 🟢 | tümü final |
| Design token (renk/spacing) | 🟡 | 3 hardcoded renk (lib/x.dart:42) |
| go_router (Navigator.of yok) | 🟢 | temiz |
| LocaleKeys (hardcoded string yok) | 🔴 | 12 hardcoded string |
| test/ lib/ mirror | 🟡 | test yok |

**Genel Uyum:** 🟡 Orta — 2 kritik alan düzeltilmeli.

## 📌 Kritik Dosyalar
| Dosya | Konum | Açıklama |
|-------|-------|----------|
| Entry | `lib/main.dart` | Uygulama başlangıcı |
| DI | `lib/app/...` | Dependency injection |

## 🚀 Başlangıç Komutları
\`\`\`bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
flutter test
\`\`\`

## 📋 Proje Standartları
<CLAUDE.md + reference/flutter özeti>

## 📊 İstatistikler
| Feature | Dart Dosyası | Test Dosyası | LOC (tahmini) |
|---------|--------------|--------------|---------------|
| X | Y | Z | ~N |

---
📅 Analiz Tarihi: <tarih>
🤖 Oluşturan: Claude Code
```

---

## Sınırlamalar

### Yapılır
- Proje yapısı, dependency ve mimari pattern tespiti
- Mars konvansiyonlarına karşı uyum skoru üretme
- Kritik dosya listesi ve onboarding rehberi
- Özet rapor oluşturma

### Yapılmaz
- Kod değişikliği veya düzeltme (→ `/mars-bug-finder`, `/mars-implement-ticket`)
- Build/run/test çalıştırma
- PR review (→ `/mars-gh-pr-review`)
- Detaylı performance profiling

---

## İlgili Skill'ler

- `/mars-bug-finder` - Bulunan uyum ihlallerini detaylı triyaj etmek için
- `/mars-implement-ticket` - Konvansiyona uygun yeni feature yazmak için
- `/mars-unit-test` - Eksik test kapsamını gidermek için
- `/mars-gh-pr-review` - PR bazlı review için
- `/sc:analyze` - SuperClaude derin analiz için (opsiyonel)
