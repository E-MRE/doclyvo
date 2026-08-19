---
name: mars-bug-finder
description: Read-first static bug triage over a git diff, a file/folder, or a described symptom in a Flutter project. Runs convention greps (hardcoded colors, Navigator.of, layer-boundary imports, missing final) plus Flutter bug smells (unawaited futures, missing mounted/isClosed guards, setState/emit after dispose, uncanceled controllers/streams), ranks findings 🔴/🟡/🟢 with file:line, root-cause hypothesis and minimal fix, and proposes a reproduction test. Does NOT change code unless approved. Trigger phrases include "bug bul", "hata ayıkla", "neden çöküyor", "şu diff'te sorun var mı", "find bugs", "triage this crash", "why does this break", "/mars-bug".
invocation: /mars-bug, /bug-finder, /mars-triage
---

# Mars Bug Finder

Flutter projesinde bir diff, dosya/klasör veya tarif edilen semptom üzerinden **önce-oku** statik bug triyajı yapar. Bulguları severity'ye göre sıralar, kök-neden hipotezi ve minimal fix önerir.

> **Not:** Default olarak **read-only** — kod değiştirmez, sadece rapor üretir. Fix yalnızca kullanıcı onayıyla uygulanır. Yalnızca statik analiz; runtime debug/profiling yapmaz.

## Ne Zaman Kullanılır

- Bir PR/branch diff'inde regresyon veya sorun ararken
- Bir crash/hata semptomunun kök nedenini triyaj ederken
- Merge öncesi hızlı hata taraması
- `/mars-project-overview` uyum skorundaki ihlalleri derinleştirirken

---

## Kullanım

```
/mars-bug                        # git diff (working tree) üzerinde tara
/mars-bug <dosya|klasör>         # belirli hedefi tara
/mars-triage "<semptom>"         # tarif edilen davranıştan başla
```

**Örnekler:**
```
/mars-bug lib/features/home
/bug-finder                      # staged + unstaged diff'i triyaj et
/mars-triage "listeye scroll edince uygulama donuyor"
```

---

## Workflow

### Faz 1: Kapsam Tespiti

Hedefi belirle:
- Argüman yok → `git diff HEAD` + `git diff --staged` (değişen dosyalar).
- Dosya/klasör verildi → o path.
- Semptom verildi → semptomdan olası ilgili dosyaları çıkar (grep + `lib/features/` taraması), sonra o dosyaları tara.

```bash
git diff --stat HEAD                       # değişim yüzeyi
git diff --name-only HEAD                   # dosya listesi
```

### Faz 2: Otomatik Tarama

**A. Konvansiyon / kalite grep'leri** (`mars-gh-pr-review` motorundan):
```bash
grep -rn "Colors\.\|Color(0x" <target>          # hardcoded renk
grep -rn "^class .*extends .*Widget" <target> | grep -v "final class"  # eksik final
grep -rn "Navigator\.of\|Navigator\.push" <target>   # go_router beklenirken
grep -rn "Text('" <target> | grep -v "LocaleKeys\|\.tr()"  # hardcoded string
grep -rn "import.*infrastructure\|import.*data/" <target>  # katman ihlali (presentation içinde)
```

**B. Flutter bug smell'leri** (asıl bug motoru):
```
┌──────────────────────────────────────────────────────────────────┐
│ BUG SMELL                        │ TARAMA / BELİRTİ                │
├──────────────────────────────────┼─────────────────────────────────┤
│ Unawaited Future                 │ `future...` await'siz çağrı;     │
│                                  │ `unawaited(` yokken async gap    │
│ Dispose sonrası setState/emit    │ async callback içinde setState;  │
│                                  │ `if (!mounted) return` / isClosed│
│                                  │ guard'ı YOK                      │
│ İptal edilmeyen controller/stream│ Controller/StreamSubscription    │
│                                  │ tanımlı ama dispose()'da yok     │
│ initState'de context/async iş    │ initState içinde ref.watch,      │
│                                  │ MediaQuery.of, await             │
│ Null-force / geç init            │ `!` force unwrap; `late` erken   │
│                                  │ erişim riski                     │
│ Liste/build'de ağır iş           │ build() içinde sort/filter/IO;   │
│                                  │ ListView.builder yerine Column   │
│ Yanlış eşitlik / rebuild         │ State'te Equatable/== yok →      │
│                                  │ gereksiz rebuild veya kaçan emit │
└──────────────────────────────────┴─────────────────────────────────┘
```

```bash
# örnek smell grep'leri
grep -rn "setState(" <target> -A2 | grep -B2 "async\|await"     # async setState riski
grep -rn "StreamController\|AnimationController\|TextEditingController" <target>  # dispose eşleştir
grep -rn "\.listen(" <target>                                     # cancel'ı kontrol et
grep -rn "initState" <target> -A8 | grep "await\|ref\.watch\|MediaQuery"
```

### Faz 3: Kök-Neden Hipotezleri

Her bulgu için: **severity 🔴/🟡/🟢**, `dosya:satır`, **semptom**, **hipotez (kök neden)**, **minimal fix**. En riskliden başla.

Severity rehberi:
- 🔴 Crash/veri kaybı/güvenlik: dispose sonrası emit, null-force crash, katman ihlali, sensitive log, unawaited future ile yarış.
- 🟡 Fonksiyonel/performans riski: gereksiz rebuild, eksik cancel, build'de ağır iş, hardcoded string/renk.
- 🟢 Kokusu/iyileştirme: naming, eksik const, küçük refactor.

### Faz 4: Reprodüksiyon Testi Önerisi

En kritik bulgu için başarısız olacak (kırmızı) bir test taslağı öner ve `/mars-unit-test`'e köprü kur. Örn: cubit'in dispose sonrası emit etmediğini doğrulayan `blocTest`, veya repository'nin `!isSuccess`'te `ResponseException` fırlattığı test.

---

## Çıktı Formatı

```markdown
# 🐛 Bug Triyaj Raporu

## Özet
| Metrik | Değer |
|--------|-------|
| Taranan dosya | N |
| 🔴 Kritik | X | 🟡 Uyarı | Y | 🟢 Öneri | Z |

## 🔴 Kritik Bulgular
### 1. Dispose sonrası emit — `lib/features/x/x_cubit.dart:88`
- **Semptom:** ekran kapanınca "emit after close" exception / rastgele crash
- **Kök neden:** async `getData()` tamamlanırken cubit kapanmış; `isClosed` guard'ı yok
- **Minimal fix:**
  \`\`\`dart
  Future<void> getData() => safeCall(() async {
    final res = await repo.fetch();
    if (isClosed) return;           // guard eklendi
    safeEmit(XSuccess(res));
  });
  \`\`\`

## 🟡 Uyarılar
### 1. [Kategori] - dosya:satır — <hipotez + öneri>

## 🟢 Öneriler
### 1. [Kategori] - dosya:satır — <gözlem + öneri>

## 🧪 Önerilen Reprodüksiyon Testi
<blocTest/test taslağı → /mars-unit-test>

---
🤖 Oluşturan: Claude Code
```

---

## Sınırlamalar

### Yapılır
- Diff/dosya/semptom üzerinde statik bug taraması
- Konvansiyon + Flutter bug smell tespiti
- Severity sıralı kök-neden hipotezleri + minimal fix
- Reprodüksiyon testi önerme

### Yapılmaz
- Onaysız kod değiştirme (default read-only)
- Runtime debug / breakpoint / profiling
- Build/run/test çalıştırma (öneri sunar, `/mars-unit-test`'e devreder)
- Backend tarafı analiz

---

## İlgili Skill'ler

- `/mars-unit-test` - Bulunan bug için reprodüksiyon testi yazmak için
- `/mars-implement-ticket` - Fix'i konvansiyona uygun uygulamak için
- `/mars-project-overview` - Genel uyum skoru için
- `/mars-gh-pr-review` - PR bazlı review için
- `/sc:troubleshoot` - SuperClaude derin troubleshoot (opsiyonel)
