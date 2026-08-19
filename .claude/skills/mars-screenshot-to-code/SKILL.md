---
name: mars-screenshot-to-code
description: UI ekran görüntüsünü Flutter widget koduna dönüştürür. Vision ile görsel analiz yaparak tema uyumlu, Clean Architecture'a uygun kod üretir. Trigger phrases include "görseli koda çevir", "screenshot to code", "UI'ı Flutter'a dönüştür", "/mars-screenshot".
invocation: /mars-screenshot, /screenshot, /ss2code, /ui-to-code
---

# Screenshot to Flutter Code

UI ekran görüntülerini analiz ederek Flutter widget koduna dönüştürür.

> **Not:** Üretilen kod, projenin CLAUDE.md dosyasındaki design token'larını ve coding standartlarını kullanır. Placeholder değerler (`<app>`, `<feature>`, token isimleri) projeye göre uyarlanmalıdır.

## Ne Zaman Kullanılır

- Tasarımcıdan gelen UI mockup'larını koda dönüştürürken
- Figma/Sketch export'larından widget oluştururken
- Referans UI'dan hızlı prototip çıkarırken
- Mevcut uygulamalardan UI pattern kopyalarken

---

## Kullanım

```
/screenshot <görsel_yolu>
/ss2code <görsel_yolu>
/ui-to-code <görsel_yolu>
```

**Örnekler:**
```
/screenshot ~/Desktop/login_screen.png
/ss2code ./designs/home_page.jpg
/ui-to-code /tmp/screenshot_2024.png
```

---

## Workflow

### Faz 1: Görsel Analiz

Screenshot'ı yükle ve analiz et:

```
[ ] Görsel dosyayı Read tool ile aç (multimodal)
[ ] Genel layout yapısını belirle (Column, Row, Stack, Grid)
[ ] Renk paletini çıkar
[ ] Tipografi stillerini tespit et
[ ] Spacing/padding değerlerini tahmin et
```

### Faz 2: Bileşen Tespiti

UI elementlerini kategorize et:

```
┌─────────────────────────────────────────────────────────────────┐
│ FLUTTER WIDGET MAPPING                                          │
├─────────────────────────────────────────────────────────────────┤
│ Üst bar           → AppBar / SliverAppBar                       │
│ Alt navigasyon    → BottomNavigationBar / NavigationBar         │
│ Liste             → ListView / ListView.builder                 │
│ Grid              → GridView / GridView.builder                 │
│ Kart              → Card / Container (decorated)                │
│ Buton             → FilledButton / OutlinedButton / TextButton  │
│ Input             → TextField / TextFormField                   │
│ Görsel            → Image.asset / Image.network                 │
│ İkon              → Icon / IconButton                           │
│ Tab               → TabBar / TabBarView                         │
│ Dialog            → AlertDialog / BottomSheet                   │
│ Chip              → Chip / FilterChip / ChoiceChip              │
│ Switch/Toggle     → Switch / Checkbox / Radio                   │
│ Progress          → CircularProgressIndicator / LinearProgress  │
│ Avatar            → CircleAvatar                                │
│ Divider           → Divider / VerticalDivider                   │
└─────────────────────────────────────────────────────────────────┘
```

### Faz 3: Widget Hiyerarşisi

Tespit edilen bileşenlerden tree oluştur:

```dart
// Örnek Widget Tree
Scaffold
├── AppBar
│   ├── leading: IconButton (back)
│   ├── title: Text
│   └── actions: [IconButton, IconButton]
├── body: SingleChildScrollView
│   └── Column
│       ├── _HeaderSection
│       ├── SizedBox (spacing)
│       ├── _ContentSection
│       │   └── ListView.builder
│       └── _ActionSection
│           └── FilledButton
└── bottomNavigationBar: NavigationBar
```

### Faz 4: Kod Üretimi

Flutter kodunu üret (mars-flutter-implement formatında):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part '_<feature>_widgets.dart';

/// Screenshot'tan üretildi: <dosya_adı>
/// Tarih: <tarih>
final class <Feature>Page extends ConsumerWidget {
  const <Feature>Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.<feature>_title.tr()),
      ),
      body: const _<Feature>Content(),
    );
  }
}
```

### Faz 5: Dosya Yapısı Önerisi

Üretilen kod için dosya konumu öner:

```
lib/features/<domain>/<feature>/
├── presentation/
│   ├── pages/
│   │   └── <feature>_page.dart
│   └── widgets/
│       └── _<feature>_widgets.dart
└── (gerekirse diğer katmanlar)
```

---

## Kod Üretim Kuralları

### Widget Yapısı

```dart
// ✅ DOĞRU - final class, const constructor
final class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.data});
  final FeatureData data;

  @override
  Widget build(BuildContext context) {
    // ...
  }
}

// ❌ YANLIŞ - final yok, const yok
class _FeatureCard extends StatelessWidget {
  _FeatureCard({required this.data});
  // ...
}
```

### Tema Kullanımı

```dart
// ✅ DOĞRU - Tema token'ları
Container(
  padding: context.paddingM,
  decoration: BoxDecoration(
    color: context.colorScheme.surface,
    borderRadius: context.radiusM,
  ),
  child: Text(
    'Başlık',
    style: context.textTheme.titleMedium,
  ),
)

// ❌ YANLIŞ - Hardcoded değerler
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    'Başlık',
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  ),
)
```

### Spacing

```dart
// ✅ DOĞRU - Spacing token'ları
Column(
  children: [
    const _Header(),
    SizedBox(height: context.spacingM),
    const _Content(),
    SizedBox(height: context.spacingL),
    const _Actions(),
  ],
)

// ❌ YANLIŞ - Magic numbers
Column(
  children: [
    _Header(),
    SizedBox(height: 16),
    _Content(),
    SizedBox(height: 24),
    _Actions(),
  ],
)
```

---

## Analiz Raporu Şablonu

Screenshot analizi sonrası üretilecek rapor:

```markdown
# UI Analiz Raporu

## Görsel Bilgisi
- **Dosya:** <dosya_yolu>
- **Boyut:** <genişlik> x <yükseklik>
- **Platform:** iOS / Android / Web

## Tespit Edilen Bileşenler

| Bileşen | Flutter Widget | Konum |
|---------|----------------|-------|
| Üst bar | AppBar | Üst |
| Liste | ListView.builder | Orta |
| Buton | FilledButton | Alt |

## Renk Paleti
- Primary: #XXXXXX → context.colorScheme.primary
- Background: #XXXXXX → context.colorScheme.surface
- Text: #XXXXXX → context.colorScheme.onSurface

## Tipografi
- Başlık: ~18sp → context.textTheme.titleMedium
- Body: ~14sp → context.textTheme.bodyMedium
- Caption: ~12sp → context.textTheme.bodySmall

## Widget Tree
<ağaç yapısı>

## Önerilen Dosya Yapısı
<dizin yapısı>
```

---

## Sınırlamalar

### Yapılır
- UI bileşenlerini tespit etme
- Widget hiyerarşisi oluşturma
- Tema uyumlu kod üretme
- Dosya yapısı önerme
- Clean Architecture uyumlu output

### Yapılmaz
- Pixel-perfect implementasyon garantisi
- Animasyon/transition otomatik tespiti
- Backend/API entegrasyonu
- State management logic üretimi
- Gerçek asset dosyaları oluşturma

---

## İlgili Skill'ler

- `/mars-flutter-implement` - Üretilen kodu genişletmek için
- `/mars-bug-finder` - Üretilen kodu review etmek için
- `/mars-unit-test` - Üretilen kod için test yazmak için
