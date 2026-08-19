---
name: mars-change-log
description: Diffs two versions of a Flutter app (git tags, commits, or branches) and produces a QA hand-off report — what changed, grouped by feature and conventional-commit type, with the affected screens/flows, API/permission/config/dependency/localization deltas, risk flags (DB migrations, auth, native, major bumps), and a prioritized smoke-test checklist for QA. Read-only; only saves to a file when asked. Trigger phrases include "iki versiyon arası ne değişti", "QA'ya changelog çıkar", "sürüm farkı raporu", "qa hand-off", "release notes for QA", "what changed between v1 and v2", "diff two tags", "/mars-changelog".
invocation: /mars-changelog, /mars-diff, /qa-handoff
---

# Mars Change Log (QA Hand-off)

İki sürümü (git tag / commit / branch) diff'ler ve QA'nın test edeceği alanları önceliklendiren bir **QA hand-off raporu** üretir.

> **Not:** Salt-okunur — repoyu değiştirmez, commit atmaz. Kullanıcı "kaydet" derse raporu `docs/qa/handoff-<from>-<to>.md`'ye yazar. `git` gerektirir.

## Ne Zaman Kullanılır

- Bir sürümü QA'ya devrederken (release hand-off)
- İki tag/branch arasında ne değiştiğini QA odaklı özetlerken
- Regresyon test kapsamını belirlerken
- Sprint sonu / release öncesi risk değerlendirmesi

---

## Kullanım

```
/mars-changelog <from>..<to>
/mars-diff v1.4.0..v1.5.0
/qa-handoff                    # otomatik: son iki tag arası
```

**Örnekler:**
```
/mars-changelog v1.4.0..HEAD
/mars-diff v1.4.0..v1.5.0
/qa-handoff develop..release/1.6.0
/mars-changelog v1.4.0..v1.5.0 kaydet     # docs/qa/'ya yaz
```

---

## Workflow

### Faz 1: Referans Seçimi

`<from>` ve `<to>` çöz. Verilmediyse:
```bash
git tag --sort=-creatordate | head            # aday sürümler
git describe --tags --abbrev=0                 # son tag
```
Default: `<to>` = `HEAD` (veya en son tag), `<from>` = bir önceki tag. Tag yoksa kullanıcıya commit aralığı sor (`git log --oneline | head`).

### Faz 2: Ham Diff Toplama

```bash
git log --oneline --no-merges <from>..<to>            # commit listesi
git diff --stat <from>..<to>                          # değişim yüzeyi (+X/-Y)
git diff --name-only <from>..<to>                     # değişen dosyalar
git diff <from>..<to> -- pubspec.yaml                 # dependency delta
git diff <from>..<to> -- 'assets/translations/*' 'lib/**/l10n/*'  # string/i18n
git diff <from>..<to> -- 'android/**' 'ios/**'        # native + izin değişiklikleri
```

### Faz 3: Sınıflandırma

**Conventional-Commit prefix'e göre grupla** (`feat/fix/perf/refactor/chore/build/breaking`) ve **feature modülüne göre** (`lib/features/<x>` path'inden). 🔴 risk alanlarını işaretle:

```
┌──────────────────────────────────────────────────────────────────┐
│ 🔴 YÜKSEK RİSK SİNYALLERİ                                          │
├────────────────────────────────────────────────────────────────────┤
│ • DB / migration dosyaları (drift, hive schema, *.sql)            │
│ • Auth / token / güvenlik akışı                                   │
│ • Networking katmanı (endpoint, interceptor, base url)            │
│ • Native değişiklik (android/, ios/, Manifest, Info.plist)        │
│ • İzin değişikliği (permissions, camera, location, notifications) │
│ • Major dependency bump (x.0.0) → breaking API riski              │
│ • .env / config / environment değişikliği                        │
└────────────────────────────────────────────────────────────────────┘
```

### Faz 4: QA Etki Analizi

Her değişen feature için QA'nın **ne test edeceğini** türet:
- **Etkilenen ekran/flow:** değişen `view/`/`screen` dosyalarından.
- **API/endpoint değişikliği:** networking diff'inden yeni/değişen endpoint.
- **Yeni izin / config / env:** native + env diff'inden.
- **Data-migration riski:** DB/schema dosyaları.
- **Regresyon yüzeyi:** değişen dosyalara dokunan mevcut akışlar (aynı feature içindeki diğer ekranlar, paylaşılan widget'lar).

### Faz 5: QA Hand-off Raporu

Aşağıdaki formatı üret. Salt-okunur; kullanıcı "kaydet"/"doc'a yaz" derse `docs/qa/handoff-<from>-<to>.md`'ye de yaz (dizini oluştur).

---

## Çıktı Formatı

```markdown
# 🚦 QA Hand-off: <from> → <to>

**Tarih:** <YYYY-MM-DD> · **Commit:** N · **Değişen dosya:** M (+X / -Y)

## 📦 Sürüm Özeti
| Kategori | Adet |
|----------|------|
| ✨ Feature (feat) | .. |
| 🐛 Fix (fix) | .. |
| ⚡ Perf (perf) | .. |
| 🔧 Refactor/Chore | .. |
| 🔴 Breaking | .. |

## 🎯 Test Edilecek Alanlar (öncelik sıralı)

### 🔴 <feature> — <ekran/flow>
- **Değişiklik:** <özet>
- **Etkilenen ekran:** `lib/features/<x>/view/...`
- **QA senaryosu:** <adımlar → beklenen sonuç>
- **Regresyon riski:** <hangi mevcut akışlar etkilenebilir>

### 🟡 <feature> — <ekran/flow>
- ...

## 🔌 API / Endpoint Değişiklikleri
| Endpoint | Değişiklik | QA Notu |
|----------|-----------|---------|
| `GET /x` | yeni | response şemasını doğrula |

## 🔐 İzin / Config / Env Değişiklikleri
- <izin/manifest/env değişikliği + QA notu>

## 📦 Dependency Değişiklikleri
| Paket | Eski | Yeni | Risk |
|-------|------|------|------|
| `dio` | 5.3.0 | 5.4.0 | 🟢 minor |
| `x` | 2.x | 3.0.0 | 🔴 major — regresyon testi |

## 🌍 Localization / String Değişiklikleri
- <yeni/değişen anahtarlar → ilgili ekranlarda görsel kontrol>

## ⚠️ Bilinen Riskler & Migration Notları
- <DB migration, breaking API, feature flag vb.>

## ✅ Smoke-test Checklist
- [ ] Uygulama açılıyor, ana akış çalışıyor
- [ ] <değişen feature 1> temel senaryosu
- [ ] <değişen feature 2> temel senaryosu
- [ ] İzin isteyen akışlar (varsa)
- [ ] Offline / hata durumu

---
🤖 Oluşturan: Claude Code
```

Boş bölümleri (değişiklik yoksa) rapordan çıkar.

---

## Sınırlamalar

### Yapılır
- İki sürüm/tag/branch arası git diff analizi
- Conventional-commit + feature bazlı sınıflandırma
- Risk sinyali işaretleme (DB, auth, native, major bump)
- QA etki analizi + öncelikli smoke-test checklist
- "kaydet" ile `docs/qa/`'ya rapor yazma

### Yapılmaz
- Kod değişikliği veya commit
- Test çalıştırma (checklist üretir, çalıştırmaz)
- Otomatik release/tag oluşturma
- Backend changelog analizi (sadece bu repo)

---

## İlgili Skill'ler

- `/mars-project-overview` - Sürüm öncesi genel durum için
- `/mars-bug-finder` - Riskli diff alanlarını triyaj etmek için
- `/mars-gh-pr-review` - PR bazlı review için
- `/sc:git` - SuperClaude git akışı (opsiyonel)
