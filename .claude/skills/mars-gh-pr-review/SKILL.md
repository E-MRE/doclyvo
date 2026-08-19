---
name: mars-gh-pr-review
description: GitHub PR'larını kapsamlı review eder. gh CLI kullanarak diff analizi, kod kalitesi kontrolü ve otomatik comment yapar. Flutter projeleri için Mars konvansiyon standartlarını (reference/flutter/*) uygular. Trigger phrases include "PR review et", "pull request incele", "review this PR", "/mars-pr-review".
invocation: /mars-pr-review, /pr-review, /gh-review, /review
---

# GitHub PR Review

GitHub Pull Request'lerini kapsamlı şekilde review eder ve gh CLI ile otomatik feedback sağlar.

> **Not:** Bu skill `gh` CLI'ın kurulu ve authenticate olmuş olmasını gerektirir. Flutter projeleri için `reference/flutter/*` konvansiyon standartlarını uygular.

## Ne Zaman Kullanılır

- PR merge öncesi kod review
- Takım arkadaşının PR'ını inceleme
- Otomatik kod kalitesi kontrolü
- Coding standartları doğrulama
- Security vulnerability taraması

---

## Kullanım

```
/pr-review <pr_numarası>
/gh-review <pr_numarası>
/review <pr_numarası>
```

**Örnekler:**
```
/pr-review 123
/gh-review 456 --detailed
/review 789 --focus security
```

---

## Workflow

### Faz 1: PR Bilgilerini Al

```bash
# PR detaylarını çek
gh pr view <number> --json title,body,author,baseRefName,headRefName,files,additions,deletions,state,reviewDecision

# Örnek output
{
  "title": "feat: Add user profile screen",
  "author": {"login": "developer"},
  "baseRefName": "main",
  "headRefName": "feature/user-profile",
  "additions": 450,
  "deletions": 23,
  "files": [...]
}
```

### Faz 2: Diff Analizi

```bash
# PR diff'ini al
gh pr diff <number>

# Değişen dosyaları listele
gh pr view <number> --json files --jq '.files[].path'
```

### Faz 3: Dosya Bazlı Review

Her değişen dosya için analiz yap:

```
┌─────────────────────────────────────────────────────────────────┐
│ REVIEW KATEGORİLERİ                                             │
├─────────────────────────────────────────────────────────────────┤
│ 1. Mimari Uyumluluk                                             │
│    • Layer boundary ihlalleri                                   │
│    • Domain → Infrastructure import var mı?                     │
│    • Presentation → Domain import var mı?                       │
│                                                                 │
│ 2. Widget Yapısı                                                │
│    • final class kullanımı                                      │
│    • const constructor                                          │
│    • Function widget yok                                        │
│                                                                 │
│ 3. State Yönetimi                                               │
│    • @immutable annotation                                      │
│    • Equatable extends                                          │
│    • copyWith metodu                                            │
│                                                                 │
│ 4. Tema Uyumluluğu                                              │
│    • Hardcoded Colors yok                                       │
│    • Hardcoded EdgeInsets yok                                   │
│    • Hardcoded BorderRadius yok                                 │
│    • Design token kullanımı                                     │
│                                                                 │
│ 5. Provider Patterns                                            │
│    • Provider<Widget> yok                                       │
│    • ref.watch initState'de yok                                 │
│    • Proper disposal                                            │
│                                                                 │
│ 6. Localization                                                 │
│    • Hardcoded string yok                                       │
│    • LocaleKeys kullanımı                                       │
│                                                                 │
│ 7. Navigation                                                   │
│    • Navigator.of yok                                           │
│    • GoRouter kullanımı                                         │
│                                                                 │
│ 8. Security                                                     │
│    • Sensitive data log'lanmıyor                                │
│    • API key hardcoded değil                                    │
│    • Input validation var                                       │
└─────────────────────────────────────────────────────────────────┘
```

### Faz 4: Review Raporu Oluştur

```markdown
# PR Review: #<number>

## Özet
- **Başlık:** <title>
- **Yazar:** <author>
- **Branch:** <head> → <base>
- **Değişiklik:** +<additions> / -<deletions>

## Genel Değerlendirme
✅ / ⚠️ / ❌ <genel durum>

## Kritik Sorunlar (Merge Engeli)
### 1. [Kategori] - dosya:satır
**Sorun:** Açıklama
**Mevcut:**
```dart
// sorunlu kod
```
**Önerilen:**
```dart
// düzeltilmiş kod
```

## Uyarılar (Düzeltilmeli)
### 1. [Kategori] - dosya:satır
**Sorun:** Açıklama
**Öneri:** Düzeltme önerisi

## Öneriler (İsteğe Bağlı)
### 1. [Kategori] - dosya:satır
**Gözlem:** Açıklama
**Öneri:** İyileştirme önerisi

## Geçen Kontroller
- ✅ <liste>
```

### Faz 5: GitHub'a Feedback Gönder

```bash
# Genel yorum ekle
gh pr comment <number> --body "$(cat <<'EOF'
## 🔍 Otomatik PR Review

<review özeti>

---
🤖 *Bu review Claude Code tarafından otomatik oluşturulmuştur.*
EOF
)"

# Review kararı
gh pr review <number> --approve --body "LGTM! ✅"
# veya
gh pr review <number> --request-changes --body "Lütfen kritik sorunları düzeltin."
# veya
gh pr review <number> --comment --body "Birkaç öneri var, değerlendirin."
```

---

## Review Komutları

### PR Bilgi Toplama

```bash
# Temel bilgiler
gh pr view <number>

# JSON formatında detaylı bilgi
gh pr view <number> --json title,body,author,files,additions,deletions,commits

# Sadece değişen dosyalar
gh pr view <number> --json files --jq '.files[].path'

# Commit listesi
gh pr view <number> --json commits --jq '.commits[].messageHeadline'
```

### Diff Analizi

```bash
# Full diff
gh pr diff <number>

# Sadece belirli dosya
gh pr diff <number> -- <file_path>

# Stat özeti
gh pr diff <number> --stat
```

### Review İşlemleri

```bash
# Yorum ekle
gh pr comment <number> --body "Yorum metni"

# Approve
gh pr review <number> --approve

# Request changes
gh pr review <number> --request-changes --body "Değişiklik gerekli"

# Sadece yorum
gh pr review <number> --comment --body "Görüşlerim"
```

---

## Severity Seviyeleri

### 🔴 Kritik (Merge Engeli)

- Layer boundary ihlali (domain → infrastructure import)
- Mutable state (var/late in state class)
- Hardcoded Colors
- Provider<Widget> kullanımı
- Function-style widget
- Navigator.of kullanımı
- Security vulnerability
- Missing `final` on widget class

### 🟡 Uyarı (Düzeltilmeli)

- Hardcoded spacing/padding
- Missing Equatable
- Missing copyWith
- Inconsistent naming
- Hardcoded BorderRadius
- Missing const keyword
- Large widget (>100 satır)

### 🟢 Öneri (İsteğe Bağlı)

- Kod organizasyonu
- Performance optimizasyonu
- Dokumentasyon eksikliği
- Naming improvements
- Refactoring fırsatı

---

## Otomatik Kontrol Komutları

```bash
# Hardcoded colors
grep -rn "Colors\." <changed_files> | grep -v "//.*Colors\."
grep -rn "Color(0x" <changed_files>

# Non-final widgets
grep -rn "^class.*extends.*Widget" <changed_files>

# Navigator kullanımı
grep -rn "Navigator\.of" <changed_files>

# Hardcoded strings
grep -rn "Text('" <changed_files> | grep -v "//"

# Mutable state
grep -rn "class.*State" -A 20 <changed_files> | grep -E "^\s+(var|late)\s+"

# Layer violations
grep -rn "import.*infrastructure" <domain_files>
grep -rn "import.*presentation" <domain_files>
```

---

## Review Çıktı Şablonu

```markdown
## 🔍 PR Review: #<number>

### Özet
| Metrik | Değer |
|--------|-------|
| Toplam Değişiklik | +X / -Y |
| Dosya Sayısı | N |
| Kritik Sorun | X |
| Uyarı | Y |
| Öneri | Z |

### Karar: ✅ APPROVE / ⚠️ COMMENT / ❌ REQUEST CHANGES

---

### Kritik Sorunlar
<detaylar>

### Uyarılar
<detaylar>

### Öneriler
<detaylar>

---
🤖 *Otomatik review by Claude Code*
📋 *Standartlar: reference/flutter*
```

---

## Sınırlamalar

### Yapılır
- PR diff analizi
- Kod kalitesi kontrolü
- Flutter standartları doğrulama
- GitHub'a comment ekleme
- Review kararı verme
- Inline öneriler sunma

### Yapılmaz
- Test çalıştırma
- Build/compile işlemi
- Merge işlemi
- Branch silme
- Force push

---

## İlgili Skill'ler

- `/mars-bug-finder` - Detaylı bug triyajı için
- `/mars-flutter-implement` - Düzeltme önerilerini uygulamak için
- `/mars-project-overview` - Proje context'i için
