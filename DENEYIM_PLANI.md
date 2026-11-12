# DENEYİM PLANI — Faz 72–80 (görünüş · his · hız · tutarlılık)

**Tarih:** 2026-11-12 (aynı gün 2. sürüm: çelişki ve tekrar taraması) · **Taban commit:**
`d2491206` · **Yazan:** Fable 5.2 incelemesi (ekran turu 9 boyut × 31 sahne + takvim + koyu
tema = 312 görüntü; kod sayımı `tool/design/token_sayim.py`; dokunulan dosyalardaki eski
kullanıcı isteklerinin dökümü `tool/design/istek_tara.py`).

**Kullanıcı isteği (2026-11-12):** "Son kullanıcının gördüğü ve hissettiği her şeyi baştan
sona incele: renk, tasarım, animasyon, hız, boyut, işlev. Abartılı olmayan, kullanışlı,
mükemmelleştirilmiş bir uygulama. Tasarım sende, ıvır zıvır işleri alt modeller yapabilir."
Ardından: **"Planımız diğer fazlarla zıt olmasın, aynı yerde tekrar tekrar çalışmayalım,
israf olmasın."**

Bu dosya `OTURTMA_PLANI.md`'nin DEVAMIDIR (Faz 58–71 orada). Yürütme düzeni
`OTOMASYON.md` (kuyruk P33–P42). Hedef görünüm: **`docs/deneyim/hedef.html`** (çelişirse bu
dosya geçerli).

> **2. sürümde ne değişti:** ilk sürümdeki 16 fikir, kullanıcının geçmiş turlarda AÇIKÇA
> istediği şeyleri tersine çeviriyordu (klasör sayısının simge üstünde durması, menünün 3
> sütun simge olması, etiketin renkli olması, 10 günlük takvim şeridi…). Hepsi çıkarıldı
> ve §4'te "yapılmayacak" diye gerekçesiyle kayıtlı — bir daha önerilmesin. Diğer
> paketlerle aynı yere dokunan maddeler tek pakete toplandı (Ek D).

> Satır numaraları `d2491206` içindir ve kayar. Bir yeri bulamazsan ADIYLA ara.

---

## Bu dosya nasıl kullanılır (protokol)

`OTURTMA_PLANI.md` protokolü aynen geçerli (kanıtı üret → düzelt → aynı kanıt yeşil →
`[x]` + tek satır → commit; faz sonu regresyon turu). Bu plana özgü ekler:

0. **Önce eski isteğe bak.** Bir bileşenin GÖRÜNÜŞÜNÜ ya da YERİNİ değiştirmeden önce
   `python tool/design/istek_tara.py <dosya>` çalıştır. Çıkan "kullanıcı isteği / bulgusu /
   kararı" yorumlarından biri yapacağın değişiklikle çelişiyorsa: **YAPMA**, maddeye
   "çelişki: <dosya:satır>" yaz ve geç. §4'teki liste bu taramanın ilk sonucudur.
1. **Görsel kanıt = ekran turu.** İşe başlamadan `flutter test tool/tour/screen_tour_test.dart`
   çıktısını `build/tour-once/`'ye kopyala; iş bitince `TOUR_COMPARE=build/tour-once` ile
   yeniden koş. Değişmesi BEKLENMEYEN sahnede fark > %0,5 ise neden bak. Kabulde adı geçen
   PNG'ye `Read` ile kendin bak. Koyu tema: `TOUR_DARK=1 TOUR_SIZES=telefon
   TOUR_OUT=build/tour-koyu` (dosya adı `<sahne>-koyu.png`).
2. **K-D kararları VERİLDİ** (§3; kullanıcı tasarım kararlarını Fable'a bıraktı). Gözetimsiz
   oturum SORMADAN uygular; "KARAR → en güvenli" kuralı yalnız bu dosyada OLMAYAN yeni bir
   karar çıkarsa geçerlidir. Her K-D **tek başına geri alınabilir tek commit**; başlıkta
   karar numarası geçer.
3. **Yeni özellik yok** (K-O1 dondurması sürüyor). Bu plan var olanı hizalar, sakinleştirir,
   hızlandırır.
4. **Akıcılık kapısı bağlayıcı.** Editör, klavye, alt/üst çubuk, ana ekran listesi ya da
   geçişe dokunan paket CLAUDE.md "ÖLÇÜM KAPISI"ndan geçer; "Kasma kontrol listesi" her
   editör/ızgara değişikliğinde tek tek işaretlenir. Bu planın hiçbir maddesi boy
   animasyonu, kök `setState`, koşula göre değişen ağaç şekli, çubuk YÜKSEKLİĞİ değişimi
   gerektirmez.
5. **Kapsam çiti (Ek D).** Her paket yalnız Ek D'de adına yazılı dosyalara dokunur. Başka
   paketin maddesi "nasılsa buradayım" diye yapılmaz; kendi maddesi başka pakete
   taşınmışsa o paket yapar.
6. Kullanıcıya görünen her paket `[apk]` + sürüm notu (tr + en, kullanıcı diliyle).

---

## Durum

| Faz | Konu | Paket | Model | Durum |
|---|---|---|---|---|
| 72 | Zemin: belirteçler, mandal testi, ortak bileşenler | P33 | Opus | F72.1–F72.4 bitti, F72.5 kısmi (dalda, 2026-11-12) |
| 73 | Renk rolleri + sakin tipografi | P34 | Opus | F73.1–F73.4 bitti (dalda, 2026-11-12; F73.1-2 P36'ya) |
| 74 | Ana ekran cilası | P35 | Opus | Dalda (oto/P35-ana-ekran), cihaz A/B bekliyor |
| 75 | Not ekranı alt çubuğu | P36 | Fable | Bekliyor |
| 76 | Levhalar: ortak başlık, ortak karo | P37 | Opus | F76.1–F76.4 bitti (dalda `oto/P37-levhalar`, 2026-11-12; F76.3 kalanı sabah bakılacak) |
| 77 | Hareket ve dokunsal dil | P38 | Opus | Bekliyor |
| 78 | Hız hissi (açılış, yeni not, yükleme hâlleri) | P39 | Fable | F78.1–F78.5 yazıldı (dalda `oto/P39-hiz-hissi`, 2026-11-12); F78.1 beyaz kare ve F78.2 sayısı cihazda ölçülecek |
| 79 | İkincil ekranlar + boş/çevrimdışı hâller | P40 | Opus | F79.1–F79.6 bitti (dalda `oto/P40-ikincil-ekranlar`, 2026-11-12) |
| 72.6 | Belirteç göçü (mekanik) | P41 | Sonnet | Bekliyor |
| 80 | Koyu tema, küçük ekran, web cilası, önce/sonra dosyası | P42 | Sonnet + Opus | Bekliyor |

**Sıra (Ek D'de gerekçesi):** P19 + P18 (ikisi de dalda sürüyor) → **P33 → P34 → P35 → P36 → P37 → P38 →
P39 → P40 → P41 → P42** → P20 → P21 → P22.

---

## 0. Değerlendirme

### İyi olan (dokunma, üstüne kur)

- **Görsel fikir doğru:** "masa ve kâğıt" (zemin orta ton, kart açık), not rengi kartta ve
  açık notta aynı, mürekkep saf siyah değil.
- **Asıl hareketler yerinde ve ölçülü:** kart → not genişleyerek açılıyor
  (`note_open_route.dart`), levhalar tek eğriyle geliyor (`app_sheet.dart`), kart basınca
  %2 çöküyor (`PressScale`), madde işaretlenince `_CheckPop`/`_CheckMove`.
- **Ekranların çoğu kullanıcıyla tur tur şekillenmiş.** `istek_tara.py` dökümü: arama hapı,
  klasör şeridi, not menüsü, alt kapsül, sabit ek çubuğu, takvimin her görünümü, AI merkezi
  — hepsinin bugünkü hâli açık bir kullanıcı isteğinin sonucu. Bu yüzden bu plan ekranları
  YENİDEN TASARLAMAZ; yerleşimi bırakır, **yüzeyi** düzeltir.
- **Altyapı hazır:** tek simge sözlüğü, `noteMenuModel`, `addCatalog`, `SheetHeader`,
  `EmptyState`, `showUndoSnackBar`, kontrast/erişilebilirlik bekçileri, 9 boyutlu tur.

### "Tam oturmamış" hissinin asıl kaynakları

1. **Değerler elle, ölçek yok** (D1). Tek ekranda 3–4 farklı köşe, yarım puntolar, 39
   farklı süre. Tek tek hiçbiri hata değil; toplamı pürüz.
2. **Üç vurgu rengi kuralsız** (D3): hatırlatıcı mor, "oluştur" bir yerde petrol iki yerde
   şeftali, ayarlarda simge kutuları dört renk.
3. **Krom içerikten yüksek sesle konuşuyor** (D2, D4, D8): yazıların yarısı kalın; ana
   ekranın en ağır öğesi 56 dp dolu ev düğmesi; mor notun altında petrol kapsül.
4. **Aynı iş dört kılıkta** (D12): dört levhada dört başlık/bölüm adı/karo dili.
5. **İlk yarım saniye ve yükleme hâlleri** (D14, D15): beyaz açılış; gri kutu + halka.
6. **Kimi ikincil yüzeyler özensiz** (D18, D19): ayarlar, klasörler, çöp.

Kazanç yerleşim değişikliğinden değil **tutarlılıktan** gelecek: ölçek + rol kuralı +
ortak karo + sessiz krom + hız cilası.

---

## 1. Kanıtlı bulgular

Sayılar `python tool/design/token_sayim.py` çıktısıdır. Görüntüler `build/tour/` (koyu:
`build/tour-koyu/`); yeniden üretmek için protokol 1.

| # | Bulgu | Kanıt | Faz |
|---|---|---|---|
| **D1** | Görsel değerlerde ölçek yok | köşe 344 kullanım / **28** farklı değer (12×57, 10×53, 14×47, 16×32…); `fontSize` 215 / **19** (12,5 · 13,5 · 14,5 · 10,5 · 11,5 · 9,5 · 8,5 dahil); süre 219 / **39**; eğri 95 çıplak `Curves.` (easeOutCubic 59) — `AppMotion` yalnız 44 yerde; simge boyutu 509 / 30; saydamlık 241 / 39 | 72 |
| **D2** | Krom fazla kalın | `FontWeight.w700` 107, `w800` 9, `w600` 86, `w500` 19. Tur `telefon-ayarlar.png`, `telefon-n4-menu.png` | 73 |
| **D3** | Üç vurgu rengi kuralsız | palet ilkesi (`app_palette.dart` başlığı): serin vurgu = dokunulacak yer, sıcak = dikkat. Uygulamada: zamanı gelen şeridi **mor** (`due_banner.dart:73` `tertiaryContainer`); editörde "+" rozeti ve Klasörler'de "Yeni klasör" **şeftali**; paylaş levhasında Kopyala/PDF/Görsel şeftali daire; ayarlarda simge kutuları petrol/mor/şeftali/gri | 73 |
| **D4** | Ana ekranın en ağır öğesi içerik değil | `telefon-ana.png`: 56 dp DOLU `primary` ev düğmesi (`dashboard_shelf.dart` `home-strip-at-home`) + dolu "+"; koyu temada ikisi ekranın en parlak iki yüzeyi (`telefon-ana-koyu.png`) | 74 |
| **D6** | Kartta okunacak satır kalmıyor | `telefon-ana.png` ilk iki kart: 5–6 üstü çizili satır, işaretsiz tek madde aralarında kayboluyor (OTURTMA K-O11 açık); her kartta tam koyulukta ⋮ (ekranda 16) | 74 |
| **D7** | Takvim şeridinde gün harfi belirsiz | telefonda `weekday.characters.first` (`home_calendar_strip.dart:286`): "P C C P P S Ç P C C" — üç gün P, iki gün C | 74 |
| **D8** | Not alt çubuğu: 40 dp hedef; renkli notta renk çatışması; telefonda kalem yok | `kEditorBarSegment = 40` (`editor_bar_layout.dart:24`); sağ kapsül `primaryContainer`: mor notta petrol (`telefon-n1.png`), sarı notta petrol (`telefon-n4.png`); OTURTMA B10 + K-O5 açık | 75 |
| **D11** | Menü levhasında ölü alan | `telefon-n4-menu.png`: tutamak + ✕ birlikte (üstte ~50 dp boş); altta "Ekranı düzenle" + "Ayarlar" + başlıkta ⚙ — üç düzenleme kapısı (~50 dp); bölüm adları ~18 pt. 360×640'ta "Sil" görünmüyor (`telefon-kucuk-n4-menu.png`) | 76 |
| **D12** | Dört levha, dört dil | bölüm adı menüde ~18 pt, paylaşta ~14 pt; AI levhası ÇERÇEVELİ kart (`telefon-n4-ai.png`), Ekle dolu karo (`telefon-n4-ekle.png`), Paylaş kutusuz büyük satır + şeftali daire (`telefon-n4-paylas.png`) | 76 |
| **D13** | Hareket/titreşim dili dağınık | D1 süre/eğri; `elasticOut` 1, `easeOutBack` 6; `HapticFeedback` 86 doğrudan çağrı (selectionClick 68, mediumImpact 16, lightImpact 2), kural yok | 77 |
| **D14** | Beyaz açılış | HAFIZA "Beyaz açılış (ÇÖZÜLMEDİ)": MIUI 13'te ~0,6 sn; OTURTMA K-O14 açık | 78 |
| **D15** | Yükleme hâli = gri kutu + halka | `telefon-e-pdf-sabit.png`; `CircularProgressIndicator` 74 yerde, gecikmesiz | 78 |
| **D16** | Ajanda satırları türe göre farklı | `takvim-telefon-agenda.png`: görev 16 pt, etkinlik 20 pt, satır boyları üç ayrı; çöp düğmeleri tam koyulukta (düğmenin KENDİSİ kullanıcı isteği — kalır, §4 Y11) | 79 |
| **D18** | Ayarlar: rastgele renkli simge kutuları, iki farklı tonda üst kart, misafirde boş profil kartı | `telefon-ayarlar.png` | 79 |
| **D19** | Klasörler: "Yeni klasör" iki kez; boş klasör kartı 128 dp. Çöp: üstte 4 etiketsiz simge, kartta etiketsiz iki çöp simgesi | `telefon-klasorler.png`, `telefon-cop.png` | 79 |
| **D20** | 12 pt altı yazı | `fontSize` 9–11,5 arası 45 kullanım (kural: okunan metin ≥ 12 pt) | 73 |
| **D21** | Tema seçici 20 aile tek ızgarada, grupsuz | `telefon-ayarlar-gorunum.png` | 73 |
| **D22** | Geniş ekranda bölüm çizgisi ızgaranın ortasında bitiyor | `masaustu-ana.png`; `kSectionHeaderMaxWidth` (`dashboard_slivers.dart`) | 80 |
| **D23** | Boş hâller turda yok | tur veri setinde boş hesap sahnesi yok; `EmptyState` 27 yerde, görünüşleri karşılaştırılmadı | 79 |
| **D24** | Koyu tema bulguları | F80.1 altındaki liste | 80 |

(D5, D9, D10, D17 ilk sürümde vardı; dayandıkları fikirler §4'e taşındı.)

---

## 2. Tasarım dili (sözleşme)

Beş ilke:

1. **İçerik konuşur, krom susar.** Bir ekranda en koyu/en doygun yüzey kullanıcının
   notudur. Renk yalnız DURUM ya da TEK birincil eylemdir.
2. **Ekran başına tek dolu birincil düğme** (ana ekranda "+").
3. **Aynı iş her yerde aynı kılıkta.** Başlık, bölüm adı, karo tek bileşen.
4. **Hareket yön söyler, süs değildir.** Giriş 200–300 ms, çıkış 2/3'ü; yalnız boyama.
5. **Dokunuşa 100 ms'de cevap, 300 ms altı işte halka yok.**

### 2.1 Belirteçler (`lib/app/theme/app_tokens.dart`'a eklenir — F72.1)

```dart
abstract final class AppSpace {
  static const double xxs = 2, xs = 4, s = 8, m = 12, l = 16, xl = 20, xxl = 24, xxxl = 32;
}
abstract final class AppRadius {
  static const double hair = 2;  // ilerleme çubuğu, imleç, ince şerit
  static const double xs = 4;    // kutucuk, küçük rozet
  static const double s = 8;     // çip, etiket hapı, ipucu
  static const double m = 12;    // düğme, giriş alanı, karo, menü, bildirim
  static const double l = 16;    // kart, "+" düğmesi
  static const double xl = 24;   // levha üstü, pencere
  static const double pill = 999;
}
abstract final class AppIconSize { static const double xs = 16, s = 18, m = 20, l = 24; }
abstract final class AppAlpha {
  static const double hairline = 0.08, pressed = 0.12, soft = 0.24,
      disabled = 0.38, muted = 0.60, strong = 0.85, scrim = 0.32;
}
abstract final class AppWeight {
  static const regular = FontWeight.w400, medium = FontWeight.w500, strong = FontWeight.w600;
}
// AppMotion'a eklenir (instant 100, short 200, medium 300, reduced 150 kalır):
//   static const quick = Duration(milliseconds: 150);
//   static const long  = Duration(milliseconds: 420);
```

**Yazı rolleri** — `AppText` (aynı dosya). `ThemeData` alır, `BuildContext` DEĞİL (editör
ve kart dosyalarında `Theme.of(context)` yasak — `_themeOf`; HAFIZA "Okunurluk"):

| Rol | pt / satır | Ağırlık | Renk | Nerede |
|---|---|---|---|---|
| `badge` | 11 / 14 | strong | — | sayı rozeti, sayfa hapı (okunan metin değil) |
| `meta` | 12 / 16 | regular | `onSurfaceVariant` | tarih, alt bilgi |
| `label` | 13 / 18 | medium | `onSurface` | çip, karo adı, küçük düğme |
| `body` | 14 / 20 | regular | `onSurface` | levha metni, satır açıklaması |
| `section` | 14 / 20 | strong | `primary` | bölüm adı (`SectionLabel`) — her yerde AYNI |
| `rowTitle` | 16 / 22 | medium | `onSurface` | ayar satırı, liste satırı, zengin karo başlığı |
| `sheetTitle` | 18 / 24 | strong | `onSurface` | levha / pencere başlığı |
| `screenTitle` | 20 / 26 | strong | `onSurface` | üst çubuk başlığı |

Not başlığı ve gövdesi bu tabloda YOK (`noteTitleStyle`, kullanıcının yazı ayarı).
Kullanıcının notta yazdığı **kalın** w700 kalır; kural yalnız arayüz kromu içindir.

**Göç eşlemesi** (F72.6; tabloda olmayan değer en yakınına):

| Tür | Eski → yeni |
|---|---|
| Köşe | 1–3 → `hair` · 4–5 → `xs` · 6–9 → `s` · 10–14 → `m` · 15–18 → `l` · 20–28 → `xl` · ≥ 32 → `pill` |
| Punto | ≤ 11,5 → 11 (yalnız rozet; okunan metinse 12) · 12–12,5 → 12 · 13–13,5 → 13 · 14–14,5 → 14 · 15–16 → 16 · 17–18 → 18 |
| Ağırlık | krom içinde w700/w800/bold → `strong`; w500 kalır |
| Süre | ≤ 110 → `instant` · 120–170 → `quick` · 180–260 → `short` · 280–350 → `medium` · 380–500 → `long` · > 500 dokunma (bekleme/zamanlayıcıdır — yanına `// bekleme` yaz) |
| Eğri | easeOut/easeOutCubic → `AppMotion.enter` · easeIn/easeInCubic → `exit` · easeInOut* → `standard` · easeOutBack kalır (yalnız onay "pop"u) · elasticOut → `enter` |
| Simge | 11–15 → 16 yalnız satır içi; 17–19 → 18 · 20–22 → 20 · 24–28 → 24; ≥ 30 dokunma |
| Saydamlık | 0,05–0,10 → `hairline` · 0,12–0,18 → `pressed` · 0,2–0,3 → `soft` · 0,32–0,45 → `disabled` · 0,5–0,7 → `muted` · 0,75–0,9 → `strong` |

### 2.2 Renk rolleri (F73.1)

| Rol | Anlam | Kullanıldığı yerler (tam liste) |
|---|---|---|
| `primary` / `primaryContainer` | **eylem, seçim, oluşturma, odak** | "+" (ana ekran, editör rozeti, klasör), seçili çip, imleç, bağlantı, bugünün günü, bölüm adı, not alt çubuğunun sağ kapsülü (renksiz notta) |
| `secondary` / `secondaryContainer` (sıcak) | **zaman, dikkat, etiket** | sabitli iğne, yıldız, hatırlatıcı çipi, zamanı gelen şeridi, bekleyen yükleme, etiket hapı (kullanıcı isteği 2026-11-05 — kalır) |
| `tertiary` / `tertiaryContainer` | **yapay zekâ kimliği** | ✨ simgesi (`AiIcon`), AI levhasındaki simgeler |
| `error` | **yıkıcı** | Sil, kalıcı sil |
| nötr (`surfaceContainer*`, `onSurfaceVariant`) | geri kalan | karo zemini, ayar simge kutusu, paylaş daireleri, çubuk, rozet zemini |

Renkli notun İÇİNDE: içerik öğeleri `NoteAccent` (var), alt çubuk kapsülleri notun tonu
(K-D6).

### 2.3 Ortak bileşenler (F72.4, `lib/core/widgets/sheet_tile.dart` + var olanlar)

| Bileşen | Ölçü | Görünüş |
|---|---|---|
| `SheetHeader` (var; güncellenir) | yükseklik 56; başlık `sheetTitle` solda 16 dp; sağda en çok 2 simge | ✕ varsa TUTAMAK YOK (K-D7) |
| `SectionLabel` (var; güncellenir) | üst 20, alt 8 | `section` rolü; sayı `meta` ile "· 3" |
| `SheetTile.tile` | yükseklik 56, köşe `m`, simge 20 `primary`, etiket `label` | zemin `surfaceContainer`; 2 sütun |
| `SheetTile.rich` | en az 64, köşe `m`, simge 24 solda, `rowTitle` + `meta` açıklama (2 satır), sağda › | zemin `surfaceContainer`; ÇERÇEVE YOK |
| `DestructiveRow` | yükseklik 48, köşe `m` | zemin `errorContainer` %50, yazı `error` |
| `DelayedSpinner` | 300 ms sonra 150 ms'de belirir | F78.3 |
| `EmptyState` (var; güncellenir) | simge 32, 72 dp nötr dairede; başlık `rowTitle`; açıklama `body`; tek düğme | dikeyde %38'de |
| `AppHaptics` (`lib/core/haptics.dart`) | `tick` · `thud` · `heavy` | F77.2 |

Not menüsünün simge ızgarası (`ActionMenu`, 3 sütun daire + alt etiket) ve Ekle karosu
(`AddTile`) kullanıcı isteğiyle bugünkü biçiminde — ortak bileşene ÇEVRİLMEZ (§4 Y6, Y16).

---

## 3. Kararlar (hepsi VERİLDİ — protokol 2)

- **K-D1 Renk rolleri §2.2'deki gibi.**
- **K-D2 Arayüz kromunda en kalın ağırlık w600.**
- **K-D3 Ev düğmesi KALIR, sessizleşir:** 56 dp dolu `primary` → 40 dp; ana sayfadayken
  `primaryContainer` + dolu ev simgesi, klasördeyken bugünkü `filledTonal`. Yeri, işi,
  anahtarları (`home-strip-at-home` / `home-strip-go-home`) ve şerit yüksekliği AYNI.
- **K-D4 Takvim şeridi olduğu gibi kalır (10 gün, 2 satır); yalnız telefonda gün adı tek
  harf yerine üç harf.** OTURTMA **K-O10 kapanır: "bugünkü"** (F66.1 kapanır).
- **K-D5 Kartta işaretsiz madde varken işaretliler tek satır "✓ N tamamlandı".** OTURTMA
  **K-O11 kapanır: önerilen** (F66.3). Ayarlar → Kartlar'a `card_show_checked` anahtarı
  (açılırsa bugünkü görünüm).
- **K-D6 Not alt çubuğu:** sol kapsülde Paylaş'ın yerine **Kalem** (Paylaş ⋮ menüsünün
  hızlı satırında zaten var). OTURTMA **K-O5 kapanır: önerilen** (F63.5, F66.2). Sağ kapsül
  ve üç düğmesi AYNEN (§4 Y9). Renkli notta iki kapsül de notun tonunda; renksiz notta
  bugünkü renkler.
- **K-D7 ✕ düğmesi olan levhada tutamak çizilmez** (aşağı çekerek kapatma çalışır).
- **K-D8 Açılış: `androidx.core:core-splashscreen`.** OTURTMA **K-O14 kapanır: önerilen**
  (F60.7) — yalnız cihazda `screenrecord` ile beyaz kare kalmadığı görülürse birleştirilir.
- **K-D9 Tema seçicide 20 aile üç grupta** (Sakin · Kâğıt · Canlı); aile silinmez.
- **K-D10 Menü levhasının altındaki "Ekranı düzenle" ve "Ayarlar" bağlantıları ⚙'nin
  açılır menüsüne taşınır** (Menüyü düzenle · Ekranı düzenle · Ayarlar).

**Kullanıcıda AÇIK kalan** (gözetimsiz yapılmaz, OTURTMA'daki hâliyle durur): **K-O6**
sabit ek çubuğunun sadeleşmesi (F65.1) — çubuktaki düğmelerin çoğu tek tek kullanıcı
isteği (§4 Y10); hangisinin ⋮'e ineceğine yalnız kullanıcı karar verir.

---

## 4. Yapılmayacaklar — kullanıcının eski istekleriyle çelişir

İlk sürümde önerilmiş, taramada (protokol 0) çelişkisi çıkmış fikirler. **Bunları yeniden
önerme, "iyileştirme" diye yapma.** Kullanıcı kendisi isterse ayrı.

| # | Fikir | Çeliştiği istek (kod yorumu) |
|---|---|---|
| Y1 | Arama hapından ✨ ya da süz düğmesini çıkarmak / gizlemek | 2026-11-06 "boştayken AI tuşu görünmüyor" → HEP GÖRÜNÜR (`dashboard_widgets.dart:408`); 2026-11-06 "arama çubuğu profil ve 3 noktayı da kapsasın" (`:305`) |
| Y2 | Klasör çipinde sayıyı adın yanına almak | 2026-10-31 "not sayısını simgesinde üssü şeklinde yaz" + "görünür alana maksimum klasör butonu sığsın" (`folder_tile.dart:583, 594`) |
| Y3 | Ev düğmesini kaldırmak ya da "Tümü" çipiyle birleştirmek | 2026-11-06 "klasörlerde ana menüye dön düğmesi olmalı" (`dashboard_shelf.dart:184`); ayrıca ana sayfa ≠ "Tümü" (`showAllNotesProvider`) |
| Y4 | Takvim şeridini 7 güne indirmek ya da varsayılan gizlemek | 2026-11-08 "en üstte 2 satır yüksekliğinde takvim satırı; bugünden itibaren 10 gün" (`home_calendar_strip.dart:20`) |
| Y5 | Etiket hapını nötr yapmak | 2026-11-05 "etiketler çok sönük görünüyor, temaya göre renklendirilebilir" (`tag_pill.dart:3`) |
| Y6 | Not menüsünü iki sütunlu "simge + yanında yazı" satırlara çevirmek | 2026-10-20 "not menüsü üstteki 4'lü gibi simge olsun, 3 sütun olsun" — iki sütun satır ESKİ hâldi (`action_menu_sheet.dart:375`) |
| Y7 | Başlık satırındaki "+"yı çip satırına almak / boşken çip satırı açmak | 2026-08-09 "artı butonu başlık satırında olsun; etiket yoksa etiket satırı oluşmasın" (`note_editor_screen.dart:3410`) |
| Y8 | Not üst çubuğuna geri oku eklemek | 2026-11-03 sıkı üst çubuk, 2026-11-05 "üst alanda sadeleşme" (`:472, :4785`); sistem geri hareketi var |
| Y9 | Alt kapsüldeki ses düğmelerini birleştirmek / gizlemek / uzun basışa almak | 2026-09-01 "mikrofon direkt sesle yazma olsun, yanına farklı bir mikrofon" (`:2729`); 2026-10-11 tek kapsül (`:4576`); 2026-10-20 (`add_catalog.dart:41`) |
| Y10 | Sabit ek çubuğundan T / balon / görünüm anahtarı / kalemi ⋮'e indirmek | 2026-11-09 "menüye girmeden T" (`pinned_media_pane.dart:1326`), 2026-11-05 "açık metin kısmını bulamadım" (`:1413`), 2026-10-16 (`:171`), 2026-11-08 (`:1249`) → K-O6 kullanıcıda |
| Y11 | Ajandada/gün sayfasında satır sonu çöp düğmesini kaldırmak | 2026-11-08 "üzerine tıklayınca ilk açılan yerde silme de olmalı" (`calendar_entry_delete.dart:19`) |
| Y12 | Ay görünümünde gün kâğıtlarını düz ızgaraya çevirmek; çipleri tek satıra indirmek | 2026-11-07 "çok düz, günler arasında belli belirsiz çizgi var" → KÂĞIT HÜCRELER (`calendar_views.dart:322`); "gerekirse 2 satır" (`:394`) |
| Y13 | Telefonda takvim ‹ › oklarını kaldırmak | 2026-11-07 "dar ekranda da var; yalnız kaydırma bilinmiyordu" (`calendar_screen.dart:504`) |
| Y14 | Ana ekranda kaydırınca başlığın çekilmesi | 2026-11-06 ev düğmesi "kaydırılınca kaybolmasın"; 2026-11-07 şerit kök nedeni (HAFIZA "Klasör şeridi sabit") |
| Y15 | AI merkezini yeniden düzenlemek | 2026-09-23 yeniden tasarım, 2026-10-20 "AI sesli not en üstte" (`ai_hub_screen.dart:93, 113`) |
| Y16 | "+" tek dokunuşta doğrudan not; Ekle karolarını yeniden biçimlemek | 2026-10-20 "artı menüsü düzeni" tek panel tek dokunuş (`quick_add_fab.dart:367`); 2026-11-11 düzen kipi |

---

## FAZ 72 — Zemin: belirteçler, mandal, ortak bileşenler [Opus · P33]

**Önce oku:** `lib/app/theme/app_tokens.dart`, `app_theme.dart`, `core/widgets/sheet_header.dart`,
`core/widgets/empty_state.dart`, `core/a11y/min_tap_target.dart`, `test/perf_budget_test.dart`
(mandal kalıbı), `tool/design/token_sayim.py`.

Bu faz, F72.5'teki bölüm adı puntosu dışında **ekranda hiçbir şeyi değiştirmez**.

- [x] **F72.1 Belirteçler.** *(2026-11-12: `AppSpace/AppRadius/AppIconSize/AppAlpha/AppWeight` + `AppMotion.quick/long` `app_tokens.dart`ta; `_base` aynı.)* §2.1'deki sınıflar `app_tokens.dart`'a; `AppMotion.quick/long`.
  `AppTheme._base` içindeki değerlere DOKUNMA (çip 10, giriş 14, "+" 18 bugünkü kalır;
  göçü F72.6 yapar).
- [x] **F72.2 `AppText`.** *(2026-11-12: `AppText.of(ThemeData)`, tema başına `Expando`; `test/design_components_test.dart` 8 rol × açık/zıt/düz tema yeşil.)* §2.1 tablosu; `static AppText of(ThemeData theme)`; her rol
  `TextTheme`'in en yakın rolünden `copyWith` ile. Birim testi: 8 rolün pt/ağırlığı
  tabloyla aynı; `AppTheme.opposite` temasında (HAFIZA: ham tema, M3 ölçüleri null) null
  dönmez.
- [x] **F72.3 Mandal testi.** *(2026-11-12: bütçe yeniden ölçüldü `{radius 344, fontSize 215, duration 220, curve 96, iconSize 509, alpha 243, fontWeight 225, haptic 88}`; bozma denemesinde (`BorderRadius.circular(7)`) kırmızı.)* `test/design_tokens_guard_test.dart` +
  `test/design_tokens/budget.json`. Test `token_sayim.py` ile AYNI desenleri Dart'ta sayar
  (yorum satırı ve tanım dosyaları hariç). Sayı > bütçe → kırmızı ("yeni elle değer:
  `AppRadius`/`AppText`/`AppMotion` kullan"); sayı < bütçe → kırmızı ("bütçeyi şuna indir")
  — bütçe yalnız DÜŞER. Başlangıç (2026-11-12; yazmadan önce yeniden ölç):
  `{"radius": 344, "fontSize": 215, "duration": 219, "curve": 95, "iconSize": 509, "alpha": 241, "fontWeight": 226, "haptic": 86}`.
  *Çakışma notu:* bu test, o sırada dalda çalışan BAŞKA paketi kırmızıya düşürebilir (o
  paket yeni elle değer eklediyse). Yürütücü birleştirirken bütçeyi o dalın sayısına göre
  bir kez yukarı ayarlayabilir; bunu Kuyruk notuna yazar.
- [x] **F72.4 Ortak bileşenler.** *(2026-11-12: `sheet_tile.dart` + `delayed_spinner.dart`; 360 dp taşma/üç nokta/Tooltip/3 sütun/zamanlayıcı testleri yeşil.)* `lib/core/widgets/sheet_tile.dart`: `SheetTile.tile`,
  `SheetTile.rich`, `DestructiveRow`, `SheetTileGrid(columns:)` (2; ≥ 600 dp 3;
  `LayoutBuilder` ile eşit genişlik). Hepsi `MinTapTarget` ≥ 48, `Semantics(button)`,
  fareyle üstüne gelince `pressed` tonu. `DelayedSpinner`: 300 ms `Timer` → `AnimatedOpacity`
  150 ms; hareket azaltılmışsa doğrudan. Widget testleri: 360 dp'de taşma yok; uzun etiket
  tek satırda üç noktayla biter, `Tooltip` tam adı verir.
- [x] **F72.5 `SheetHeader` / `SectionLabel` / `EmptyState` ölçüleri** §2.3'e çekilir
  (bileşenin İÇİ; çağıranlar değişmez). K-D7: `SheetHeader(onClose:)` taşıyan levhalarda
  `showDragHandle: false` (Grep `SheetHeader(` → çağıran `showAppSheet`).
  *Tuzak:* ana ekrandaki "Sabit · 3" başlığı da `SectionLabel` — punto 18 → 14 olur; tur
  farkında beklenir (bu fazın TEK görünür farkı), `telefon-ana.png`'de iyi durduğuna bak.
  *(2026-11-12, KISMİ: `SectionLabel`/`sectionLabelStyle` → `AppText.section` (14/20 w600; eskisi
  `labelLarge` 14 w700 — "18 → 14" varsayımı yanlıştı, punto zaten 14, değişen yalnız ağırlık).
  Tur farkı 274 PNG'nin hepsinde %0,00: tur yalnız Roboto Regular/Medium/Bold yükler, w600 ve
  w700 ikisi de Bold'a düşer; cihazda (Inter Tight) bölüm adı biraz incelir — cihazda doğrulanmadı.
  **Sabah bakılacak:** `SheetHeader` 56 dp / 16 dp sol / `sheetTitle` 18, `EmptyState` 32+72 daire,
  `SectionLabel` iç dolgusu (üst 20 alt 8) ve K-D7 tutamak kaldırma YAPILMADI — her levhada görünür
  fark yaratıyor ("bölüm adı dışında ekran değişmez" kuralıyla çelişki) ve K-D7 ~15 çağıran
  dosyaya (P37/P20 alanı) dokunuyor. Önerilen: P37 F76.1/F76.3'te, `EmptyState` P40 F79.5'te.)*
- [ ] **F72.6 Göç (mekanik) [Sonnet · P41].** `python tool/design/token_sayim.py radius`
  dökümü üzerinden KLASÖR KLASÖR (sıra: `core/widgets` → `features/settings` →
  `features/calendar` → `features/folders` + `inbox` + `friends` + `gmail` → `features/ai`
  → `features/notes/presentation` kök → `viewers/`). Her klasör ayrı commit; §2.1 eşlemesi
  dışına ÇIKMA. Her commit'ten sonra `dart analyze` + o klasörün testleri + tur farkı
  (sahne başına < %2; üstündeyse o dosyayı geri al ve maddeye yaz).
  **`editor/` klasörü, `items_editor*`, `text_wrap*`, `ink_*`, `pen_*`, `keyboard_snap.dart`,
  `note_open_route.dart` KAPSAM DIŞI** — P20 (Faz 64) aynı dosyaları yeniden düzenleyecek;
  oradaki ölçüler cihazda ayarlandı. Editör klasörünün göçü P20'den sonra ayrı karar.
  P41 başlarken Kuyruk'ta `sürüyor` / `bulutta:` satırı OLMAMALI (yüzlerce satıra dokunur,
  açık dalla çakışır). Hedef (editör hariç sayım): köşe ≤ 120, punto ≤ 70, süre ≤ 110,
  ağırlık ≤ 60.
- Kabul: tur farkı beklenen dışında < %0,5; mandal yeşil ve bozma denemesinde kırmızı.

---

## FAZ 73 — Renk rolleri ve sakin tipografi [Opus · P34 · `[apk]`]

**Önce oku:** `app_palette.dart` (başlık + `FamilyTokens`), `test/theme_contrast_test.dart`,
`test/visual_consistency_test.dart`, `test/note_accent_consistency_test.dart`, `due_banner.dart`.

- [x] **F73.1 Rol sözleşmesi + bekçi (K-D1).** *(2026-11-12: 1,3,4,5,6 yapıldı + `test/color_roles_test.dart` (eski `due_banner` ile kırmızı → yeşil); **2 (`_addToolButton`) YAPILMADI — `editor/` P36'nın (Ek D.1), sabah bakılacak**; AiIcon dolu düğmede/devre dışıyken miras renkte.)* §2.2 tablosu `app_palette.dart` başlığına.
  Düzeltilecekler:
  1. `due_banner.dart`: `tertiaryContainer/onTertiaryContainer` → `secondaryContainer/
     onSecondaryContainer`.
  2. `note_editor_toolbar.dart` `_addToolButton`: rozet zemini `primaryContainer`, simge
     `onPrimaryContainer` (rozet biçimi ve kalın artı KALIR — kullanıcı isteği 2026-10-30).
  3. `folders_screen.dart` "Yeni klasör" düğmesi: `primaryContainer` tonu.
  4. Paylaş levhası (Grep `Dışarı gönder` ARB anahtarı → levha) Kopyala / PDF / Görsel
     daireleri: nötr `surfaceContainerHigh`; ilk daire (Metni paylaş) `primary` kalır.
  5. Ayarlar kök satırlarının simge kutuları: hepsi `surfaceContainerHigh` +
     `onSurfaceVariant`.
  6. `AiIcon`: `tertiary`. (AI merkezi ve levha yerleşimine dokunma — §4 Y15.)
  Etiket hapına DOKUNMA (§4 Y5).
  Bekçi `test/color_roles_test.dart`: `lib/` içinde `tertiaryContainer|\.tertiary\b` yalnız
  `features/ai/`, `AiIcon` dosyası ve tema dosyalarında geçer (bugünkü başka kullanımlar
  izin listesine gerekçesiyle yazılır — liste testte).
  *Tuzak:* `theme_contrast_test` 20 ailede dener; `balloon_list_theme_fixes_test` vurgu
  doygunluğu > 0,2 ister.
- [x] **F73.2 Krom ağırlığı (K-D2).** *(2026-11-12: 83 yer w700/w800 → `AppWeight.strong`; dışarıda: kullanıcı içeriği (balon/sunum/görsel notu kalını), `note_card`, `action_menu_sheet` (P37), takvimde bugün; bütçe fontWeight 225→142.)* `token_sayim.py fontWeight` dökümü: w700/w800/bold →
  `AppWeight.strong`. DOKUNMA: `rich_text.dart`, `text_wrap*`, `format_bar.dart`'ın "B"
  düğmesi, `noteTitleStyle`, dışa aktarım (PDF/Word), takvimde bugünün günü, `editor/`
  klasörü (P36/P20'nin alanı). Tur farkı beklenir (ayarlar, menüler, levhalar).
- [x] **F73.3 Punto (D20).** *(2026-11-12: 10 yer 12-altı (okunan 12, rozet 11) + 23 yarım punto; dışarıda: takvim ay/hafta/yıl (Ek D.1 kimsede değil), şerit + kart (P35), AI merkezi (Y15), not menüsü (P37).)* `token_sayim.py fontSize`: 12'nin altındaki 45 kullanımın her
  biri — okunan metinse 12, rozet/sayıysa 11. İSTİSNA (dokunma): klasör çipindeki üst simge
  sayısı (§4 Y2), takvim ay hücresi çipleri (§4 Y12), `editor/` klasörü. Yarım puntolar
  §2.1 eşlemesiyle.
- [x] **F73.4 Tema seçici grupları (K-D9).** *(2026-11-12: `themeChoiceGroupOrder` + `SectionLabel`; "Koyu" listede yoktu → Sakin'in sonunda, sabah bakılacak; bekçi `test/theme_picker_groups_test.dart`.)* `theme_picker.dart` `themeChoiceOptions`: sıra
  ve üç `SectionLabel`: **Sakin** (Sistem, Adaçayı, Porselen, Kil, Lavanta, Zeytin, Nane,
  Şeftali) · **Kâğıt** (Beyaz, Saman, Krem + `classic`, `newsprint`, `notebook`, `graphite`,
  `ledger`) · **Canlı** (Okyanus, Gül, Mandalina, Zümrüt, Ametist). Önizleme kartı ve alçak
  levha davranışı (kullanıcı isteği 2026-09-26, 2026-11-06) AYNEN; alçak levhada grup adı
  yerine 12 dp boşluk.
- Kabul: `telefon-ana.png`, `telefon-ayarlar.png`, `telefon-n4-paylas.png` önce/sonra;
  bekçiler yeşil; koyu turda aynı sahneler okunur.

---

## FAZ 74 — Ana ekran cilası [Opus · P35 · A/B liste · `[apk]`]

**Önce oku:** `dashboard_shelf.dart`, `home_calendar_strip.dart`, `due_banner.dart`,
`note_card.dart`, `card_preview.dart`, `docs/hafiza/arayuz.md` ("Klasör şeridi sabit"),
`docs/hafiza/akicilik.md` (kart önbelleği). **Önce `istek_tara.py` (protokol 0).**
Bekçiler: `folder_strip_chips_test`, `folder_strip_fixed_test`, `card_checked_item_test`,
`perf_budget_test`, `accessibility_test`.

Yerleşim DEĞİŞMEZ (arama hapı, şeritler, çipler, "+" paneli bugünkü yerinde ve biçiminde —
§4 Y1–Y4, Y14, Y16). `dashboard_screen.dart`'a girilmez (P19'un alanı — Ek D.1).

- [x] **F74.1 Ev düğmesi sessizleşir (D4, K-D3).** *(2026-11-12: `primaryContainer` + `onPrimaryContainer`, boy klasördekiyle aynı (IconButton 40/48) — `folder_strip_chips_test` renk + boy.)* `dashboard_shelf.dart`: `home-strip-at-home`
  `IconButton.filled` → 40 dp, zemin `primaryContainer`, simge `onPrimaryContainer` (dolu
  ev); `home-strip-go-home` bugünkü `filledTonal`, 40 dp. Dokunma hedefi 48 (`MinTapTarget`),
  şerit yüksekliği ve düğmenin kapladığı YATAY yer aynı kalsın (giriş/çıkışta şerit
  sıçramasın — 2026-11-07 kök nedeni). Koyu temada da bak (`telefon-ana-koyu.png`).
- [x] **F74.2 Takvim şeridinde gün adı (D7, K-D4).** *(2026-11-12: üç harf `badge` 11 pt; hücre içi < 24 dp'de tek harf — 360'ta sığıyor; `calendar_backdrop_themes_test`.)* `home_calendar_strip.dart` `_DayCell`:
  dar düzende `weekday.characters.first` yerine `weekday` (üç harf: Pzt, Sal, Çar…), `badge`
  rolü 11 pt. Gün sayısı (10) ve iki satır yükseklik AYNI. 360 dp'de hücre 36 dp — sığdığını
  `telefon-kucuk-ana.png`'de gör; sığmıyorsa yalnız 360'ın altında tek harfe düş.
- [x] **F74.3 Zamanı gelen şeridi.** *(2026-11-12: köşe m, `label`/`meta`/`badge`, ✕ `MinTapTarget` 48; şerit 44 dp aynı — `due_items_test`.)* Renk F73.1'de. Köşe `m`, başlık `label`, tarih `meta`;
  ✕ hedefi 48 (görünen simge 18). Tek satır ve "+N" davranışı (kullanıcı isteği 2026-11-08)
  aynen.
- [x] **F74.4 Kart sakinleşmesi (D6, K-D5).** *(2026-11-12: `cardItemSlice` (card_preview) + `_CardDoneLine`; sıralı listede özet yok; `card_show_checked` `CardDisplay`'e girdi (kart env'i); ⋮ %60 / 28 dp %32 daire — `card_checked_collapse_test` yeni; tahmini kart boyu özeti bilmiyor, sabah bakılacak.)*
  (a) `card_preview.dart`: işaretsiz madde varsa önce onlar (dilim sınırı aynı), işaretliler
  tek satır "✓ N tamamlandı" (`meta`, `NoteAccent` tonunda). Hepsi işaretliyse: ilk 2 madde
  üstü çizili + "✓ Hepsi tamam (N)". Yeni tercih `card_show_checked` (varsayılan kapalı;
  açıkken bugünkü görünüm) Ayarlar → Kartlar'da, `card_show_*` kalıbıyla. P32 kuralı
  (kartta işaretli kutuya dokunmak notu açar) ve P26 (gizli eke yazılı özet) aynen.
  *Tuzak (kasma listesi 1–2):* yeni tercih kart önbelleği anahtarına girsin;
  `perf_budget_test` yeşil.
  (b) Kart ⋮: düz kartta simge 18, renk `onSurfaceVariant` %60; görselli kartta daire 28,
  zemin siyah %32. Dokunma hedefi 48 KALIR.
- [x] **F74.5 "+" kümesi.** *(2026-11-12: `_DashVoiceButton` `surfaceContainerHigh` + `onSurface`; bekçi `color_roles_test`.)* "+" tek dolu birincil yüzey (bugünkü). Yanındaki mikrofonun
  zemini `primaryContainer` → `surfaceContainerHigh`, simge `onSurface`. Panel ve davranış
  aynı.
- [x] **F74.6 Boş ana ekran (D23).** *(2026-11-12: `HomeEmptyNotes` ana sayfada "İlk notunu yaz" (createNote(text)); `EmptyState`'in §2.3 ölçüsü F79.6'ya (P40, Ek D.2) kaldı; tur `TOUR_EMPTY=1` → `ana-bos`.)* Hiç not yokken `EmptyState` (§2.3) + tek düğme "İlk
  notunu yaz" ("+" panelindeki Metin notu işi; yeni iş yok). Tura `TOUR_EMPTY=1` (`ana-bos`).
- Kabul: `telefon-ana.png` ve `-koyu` — dolu `primary` yüzey yalnız "+" ve bugünün günü;
  gün adları üç harf; ilk iki kartta işaretsiz madde okunuyor; `ab_liste.py` + `ab_klavye.py`
  regresyon yok.

---

## FAZ 75 — Not ekranı alt çubuğu [Fable · P36 · A/B · `[apk]`]

**Önce oku:** CLAUDE.md "Kasma kontrol listesi", `note_editor_toolbar.dart`,
`editor_bar_layout.dart` (`planEditorBar` + testi), `note_editor_screen.dart`'ta YALNIZ alt
çubuğun kurulduğu yer (Grep `editor-ai-capsule`, `planEditorBar(`), `editor_quick_row.dart`
(kalem düğmesinin çağırdığı iş), `docs/hafiza/arayuz.md` ("Not vurgusu", "Okunurluk").
**Önce `istek_tara.py`.** Bekçiler: `keyboard_jank_guard_test`, `perf_budget_test`,
`note_accent_consistency_test`, `accessibility_test`.

**Kapsam çiti:** bu faz yalnız `note_editor_toolbar.dart`, `editor_bar_layout.dart` ve
`note_editor_screen.dart`'taki alt çubuk bloğuna dokunur. Üst çubuk, başlık satırı, sabit
ek çubuğu, hızlı satır, çubuk YÜKSEKLİĞİ ve klavyeyle gizlenme (P23, P25; OTURTMA F67.4 —
P18'in işi) DEĞİŞMEZ.

- [ ] **F75.1 Sol kapsülde Kalem (D8, K-D6).** Sıra: Biçim · Ekle · **Kalem** · Ara ·
  (Ekler) · (☑|Seç). Kalem = hızlı satırdaki kalem düğmesinin yaptığı iş (aynı işlev
  çağrılır; yeni durum yok). Paylaş kapsülden çıkar (`planEditorBar`'ın `share` alanı ve
  "önce Paylaş'ı düşür" adımı kalkar; "Ara'yı düşür" kalır). Belge notundaki ayrı kalem
  düğmesi (`_penWidth`) bu segmentle birleşir — iki kalem düğmesi yan yana durmaz.
  `planEditorBar` testine 360 / 393 / 412 dp: taşma yok.
  HAFIZA `arayuz.md`'deki "Alt çubuk sırası sabit: …" satırı yeni sırayla güncellenir.
- [ ] **F75.2 Dokunma hedefi (D8).** Segmentin GÖRÜNEN boyu ve çubuk yüksekliği aynı kalır;
  her segment `MinTapTarget` ile 48 dp'lik dokunma alanı alır (komşu alanlar çakışmasın:
  yatayda segment + boşluk payı, dikeyde çubuğun tamamı). `accessibility_test`'e not ekranı
  alt çubuğu satırı.
- [ ] **F75.3 Renkli notta kapsül rengi (D8, K-D6).** `NoteAccent` doluyken (renkli not):
  sol kapsül zemini `Color.alphaBlend(noteInk %8, sayfa rengi)`, çerçeve `noteInk %12`; sağ
  kapsül (`_aiCapsule`) `noteInk %14`, çerçevesiz; simgeler `noteInk`; etkin segment
  `noteInk %18`; "+" rozeti `noteInk %18`. Renksiz notta bugünkü renkler (F73.1'in rozet
  düzeltmesi dışında) AYNEN. Renkler `_themeOf(context)` ve var olan `NoteAccent`'ten; yeni
  sağlayıcı yok; hesap her build'de yeni nesne üretip alt ağaca "yeni girdi" vermesin
  (`_editorInk` gibi önbelleğe bağla). Kanıt: `telefon-n1.png` (mor) ve `telefon-n4.png`
  (sarı) — çubukta petrol kalmaz; `-koyu` karşılıkları da.
- Kabul: tur `telefon-n1/n2/n4` + `telefon-kucuk` önce/sonra; A/B `ab_klavye.py` hiçbir
  evrede +%20 yok; `perf_budget_test` yeşil.

---

## FAZ 76 — Levhalar: ortak başlık, ortak karo [Opus · P37 · `[apk]`]

**Önce oku:** `core/widgets/action_menu_sheet.dart`, `core/menu_layout.dart`, paylaş levhası,
not içi AI levhası (Grep `Bugünkü puan` ARB anahtarı), `test/note_menu_model_test.dart`,
`test/undo_over_sheet_test.dart`. **Önce `istek_tara.py`.**

- [x] **F76.1 `ActionMenu` ölü alanı (D11, K-D7, K-D10).** *(2026-11-12: tutamak yok (başlıklı menüde), ⚙ açılır menü (Menüyü düzenle · Ekranı düzenle · Ayarlar), Sil `DestructiveRow`, `SheetHeader` 56 dp / 16 dp / `sheetTitle` 18; 412×915 levha **774 → 670 dp (−104)**, 360×640'ta Sil'e **50 dp** kaydırma (önce 96) — bekçi `test/note_menu_sheet_height_test.dart`. `SectionLabel` iç dolgusu (üst 20 / alt 8) YAPILMADI: menüyü 4×16 dp uzatır, kabulle çelişir — sabah bakılacak.)* Simge ızgarası (hızlı satır + 3
  sütun daire + alt etiket) AYNEN (§4 Y6). Değişenler: tutamak yok (F72.5); bölüm adları
  `section` rolü (F72.5 ile kendiliğinden); alttaki "Ekranı düzenle" + "Ayarlar" satırı
  kalkar, başlıktaki ⚙ küçük açılır menü olur (Menüyü düzenle · Ekranı düzenle · Ayarlar);
  "Sil" `DestructiveRow`. Düzen kipi (`menu_layout_v1`) davranışı aynı.
  Kabul: `telefon-n4-menu.png` levha yüksekliği bugünkünden ≥ 100 dp kısa;
  `telefon-kucuk-n4-menu.png`'de "Sil"e ≤ 120 dp kaydırmayla ulaşılır; `note_menu_model_test`
  yeşil.
- [x] **F76.2 AI levhası ve Paylaş levhası (D12).** *(2026-11-12: AI satırları `SheetTile.rich`, "Bu not" kutuları çerçevesiz `surfaceContainer` köşe `m`; Paylaş bölüm adları `SectionLabel` (12 → 14 pt), 6 alt satır `SheetTile.rich` (misafir kilidi `badge`); ikisinde de tutamak yok. `SheetTile` artık `AppIcons.glyph` çizer (AI sesli not simgesi).)* Yerleşim ve sıra AYNI; yalnız kılık:
  AI levhasındaki çerçeveli kartlar → `SheetTile.rich` (zeminli, çerçevesiz); "Bu not"
  işleri aynı 2 sütunda aynı açıklamalarıyla, çerçeve yerine `surfaceContainer` zemin.
  Paylaş: üst sıra daireler F73.1 renkleri; "Ayarlı PDF / Word", "Not paketi", "Arkadaşa
  gönder", "Birlikte düzenle" → `SheetTile.rich`.
- [x] **F76.3 Kalan levhaların dökümü.** *(2026-11-12: 84 `showAppSheet` çağrısı `docs/deneyim/levhalar.md`'de; kapsam içinde tutamak + ✕ birlikte kalan YOK. **Sabah bakılacak:** kapsam dışı Ekle/tema/takvim editörleri/kalem tepsisinde hâlâ tutamak + ✕; 34 levha el yazısı 16 pt başlıkla (✕'siz, K-D7'ye uyuyor) — `SheetHeader`'a çevirme ayrı paket; 8 doğrudan `showModalBottomSheet`.)* `showAppSheet` çağıran yerler (Grep): her biri
  `SheetHeader` + `SectionLabel` kullanıyor mu, tutamak + ✕ birlikte mi, alt güvenli alan
  var mı. Uymayanlar çevrilir. KAPSAM DIŞI: kalem tepsisi, biçim çubuğu, takvim editörleri,
  tema levhası, Ekle levhası ve "+" paneli (§4 Y16). Döküm `docs/deneyim/levhalar.md`.
- [x] **F76.4 Onay pencereleri.** *(2026-11-12: `dialogTheme` başlık `sheetTitle` (24 → 18 pt), gövde `body`; `core/widgets/confirm_dialog.dart` `showConfirmDialog(destructive:)`; klasör sil ×2 ve kalıcı sil `error` tonuna çekildi, etiket sil + çöpü boşalt yardımcıya geçti. 5 yıkıcı onay `error`'suz — döküm dosyasında, sabah bakılacak.)* `showDialog` kullanımlarının dökümü: başlık `sheetTitle`,
  gövde `body`, düğmeler sağda; yıkıcı onay `FilledButton` + `error` tonu, vazgeç
  `TextButton`. Ortak yardımcı varsa ona, yoksa `core/widgets/`'e tek yardımcı.
  *Tuzak:* profil levhasına `FilledButton` koyma (test onay kutusunu onunla bulur).
- Kabul: `n4-menu`, `n4-ai`, `n4-paylas`, `ana-kart-menu` turunda başlık ve bölüm adı aynı
  puntoda; tutamak + ✕ birlikte hiçbir levhada yok.

---

## FAZ 77 — Hareket ve dokunsal dil [Opus · P38 · A/B · `[apk]`]

**Önce oku:** `app_tokens.dart` `AppMotion`, `core/a11y/motion.dart`, `core/widgets/`
(`press_scale`, `pop_in`, `scale_settle`, `color_fade`, `expand_reveal`,
`hold_progress_ring`, `app_sheet`, `smooth_routes`), `docs/hafiza/akicilik.md`.

| İş | Süre | Eğri | Not |
|---|---|---|---|
| Basma tepkisi (kart, karo, çip) | `instant` 100 | `standard` | ölçek 0,98 (kart) / 0,97 (çip, karo) |
| Durum değişimi (kutucuk, iğne, çip seçimi, sayı) | `quick` 150 | `standard` | |
| Belirme / açılma | `short` 200 | `enter` | çıkış 150 `exit` |
| Levha, menü | `medium` 300 / 200 | `enter` / `exit` | var |
| Tam ekran medya | 320 / 240 | `enter` / `exit` | var (`MediaRoute`) |
| Sayfa (not açılışı, yan kayma) | 420 / 360 | var olan | DOKUNMA |
| Sıralı giriş | öğe başı 30 ms, en çok 6 öğe | `enter` | |

- [ ] **F77.1 Süre/eğri göçü (D13).** F72.6'nın hareket kısmı burada: `core/`, `settings/`,
  `calendar/`, `folders/`, `ai/`, ana ekran widget'ları. KAPSAM DIŞI (cihazda ayarlı):
  `editor/`, `viewers/`, `keyboard_snap.dart`, `note_open_route.dart`, `FolderSwipe`
  (2026-11-06 "akan geçiş"), `PinchColumns`, P29'un uzun basış halkası, P30'un çöp efekti.
- [ ] **F77.2 `AppHaptics` (D13).** `lib/core/haptics.dart`: `tick()` = `selectionClick`
  (seçim, çip, anahtar, eşik) · `thud()` = `lightImpact` (iş TAMAMLANDI: madde işaretlendi,
  sabitlendi, kart bırakıldı, hatırlatıcı kuruldu) · `heavy()` = `mediumImpact` (uzun
  basışla tutma, yıkıcı onay, çöpe atma). 86 doğrudan çağrı buna ÇEVRİLİR — bugünkü çağrının
  TÜRÜ değişmez (selectionClick → `tick`, mediumImpact → `heavy`); P29'un iki aşamalı
  titreşimi dahil hiçbir yerde "daha uygun" diye tür değiştirme. Mandal: `haptic` bütçesi →
  `haptics.dart` dışı 0. Eksik denetimi (yoksa ekle): madde işaretleme `thud`, sabitle/
  yıldızla `tick`, kart bırakma `thud`, hatırlatıcı kaydet `thud`.
- [ ] **F77.3 Eksik mikro-etkileşimler** (önce var mı bak; varsa dokunma):
  1. İğne/yıldız: dokununca `ScaleSettle` 1 → 1,15 → 1 (`quick`) + `ColorFade`.
  2. Klasör çipi ve levha karoları: `PressScale(scale: 0.97)`.
  3. Çip/başlık sayı rozetleri: sayı değişince `AnimatedSwitcher` (`quick`, solma). Kart
     İÇİNDE YOK (kart önbelleği).
  4. Bulut/senkron simgesi: durum değişiminde `AnimatedSwitcher` 150 ms solma.
  5. Bildirim şeridi (`showMessage`): alttan 8 dp kayarak + solma (`short`).
  *Yapma:* boy animasyonu; liste yeniden dizilişini canlandırma; ışıltı; paralaks; "+"
  panelinin ve çöp/arşiv efektinin (P30) hareketini değiştirme.
- [ ] **F77.4 Hareketi azalt.** Yeni her hareket `AppMotion.of/curveOf`'tan geçer; test:
  `MediaQuery(disableAnimations: true)` altında süre ≤ 150.
- Kabul: A/B regresyon yok; mandalda titreşim 0; `docs/cihaz_turu.md`'ye elle bakılacak 4
  adım (işaretle, sabitle, sürükle-bırak, çöpe at: her birinde tek titreşim).

---

## FAZ 78 — Hız hissi [Fable · P39 · cihaz · `[apk]`]

**Önce oku:** `docs/hafiza/akicilik.md`, `tool/perf/README.md`, `prof_cold.py`, `prof_oc.py`,
`android/app/src/main/res/` (`launch_bg`, `styles.xml`), `MainActivity`,
`pinned_media_pane.dart` (yükleme hâli), `note_card.dart` (görsel yer tutucusu).

- [x] *(2026-11-12: yazıldı, cihazda doğrulanmadı — `LaunchTheme` = `Theme.SplashScreen` (ad korundu, manifest aynı), `MainActivity` `installSplashScreen` + ilk kareye dek tut (3 sn emniyet); debug APK derlendi. Yürütücü `screenrecord` ile beyaz kare sayar; kalıyorsa commit geri alınır.)* **F78.1 Beyaz açılış (D14, K-D8; OTURTMA F60.7).** `androidx.core:core-splashscreen`:
  `Theme.App.Starting` (`windowSplashScreenBackground` = Adaçayı zemini `#EAF0EB`,
  `values-night` karşılığı; simge uygulama simgesi), `postSplashScreenTheme` = bugünkü
  `NormalTheme`; `MainActivity.onCreate`'te `installSplashScreen()` +
  `setKeepOnScreenCondition { !ilkKareGeldi }`. Kanıt (önce/sonra): `adb shell screenrecord`
  + ffmpeg ile kare kare beyaz kare sayısı (HAFIZA: `screencap` yanıltır). Beyaz kare
  kalıyorsa GERİ AL, maddeye yaz.
  *Tuzak:* `FlutterFragmentActivity`; iki uygulama kimliği (kişisel / `dev.kaimau.notlar.olcum`);
  P10'un güncelleme yolu (`ApkGuncelleme.kt`, `GuncellemeSonrasiAc.kt`) açılışla aynı
  Activity'yi kullanır — güncelleme sonrası açılışı da dene.
- [x] *(2026-11-12: `tool/perf/prof_new.py` yazıldı, cihazda ölçülmedi — sayı yok; ≤ 450 ms ise kod gerekmez, üstündeyse kök neden ayrı iş. Sabah bakılacak.)* **F78.2 "Yeni not" süresi.** Yeni ölçüm `tool/perf/prof_new.py`: "+" → "Metin notu"
  dokunuşundan editörün ilk karesi + klavye görünür (`dumpsys input_method` `mInputShown`)
  olana dek. 5 koşu ortanca. Hedef ≤ 450 ms. Üstündeyse kök neden + düzeltme; altındaysa
  yalnız sayı yazılır, kod yok.
- [x] *(2026-11-12: (a) 20 içerik halkası `DelayedSpinner`, döküm `docs/deneyim/yukleme.md`; (b) `MediaLoadingCover` — sabit/gömülü PDF + sabit video; (c) yerel görsel `fadeInFrame` 150 ms, kart kapağı boyu zaten ekin oranından. `test/loading_states_test.dart`.)* **F78.3 Yükleme hâlleri (D15).** (a) `DelayedSpinner`: içerik alanındaki halkalar
  (liste, levha gövdesi, önizleme kutusu) buna çevrilir; düğme içi halkalar kalır. Döküm
  `docs/deneyim/yukleme.md`. (b) Sabit/gömülü PDF ve video bölmesi yüklenirken gri kutu
  yerine ekin `thumbUrl`/yerel küçük resmi (P17/F65.5 ile var) + %24 siyah perde +
  `DelayedSpinner`; küçük resim yoksa `surfaceContainer` + tür simgesi. Bölmenin boyu ve
  çubuğu DEĞİŞMEZ. (c) Kart ve görüntüleyicide görseller 150 ms solarak gelir; yer tutucu
  görselin en/boy oranında (test: görsel gelmeden ve geldikten sonra kart yüksekliği aynı).
- [x] *(2026-11-12: 42 `GestureDetector(onTap:)` dökümü `docs/deneyim/dokunus.md`; başka yere götüren 3 yüzey `PressScale` (paylaşım hedefi kartı, not hedefi hücresi, sohbet görseli); gerisi aynı karede durum değiştiriyor ya da kapsam dışı.)* **F78.4 Dokunuş tepkisi denetimi.** `GestureDetector(onTap:` kullanımları: görünür
  basma tepkisi olmayanların dökümü; sık dokunulan yüzeyler düzeltilir. Jest alanları
  (kalem yüzeyi, ayraç, tutamak) kapsam dışı.
- [x] *(2026-11-12: kanıt yeşil, kod değişmedi — bütün yollar ateşle-unut (`updateFields`/`batchUpdate` beklenmiyor). `test/optimistic_actions_test.dart`: onayı hiç gelmeyen depoyla arşivle/sabitle/yıldızla/çöp/madde + toplu yazımı `await` eden arayüze kaynak bekçisi.)* **F78.5 İyimser işlemler.** Sabitle, yıldızla, arşivle, çöpe at, madde işaretle,
  klasöre taşı: arayüz ağ beklemeden aynı karede değişiyor mu — yavaş sahte depoyla widget
  testi; bekleyen varsa kök neden + düzeltme.
- Kabul: soğuk açılışta beyaz kare 0; `prof_new.py` sayısı dosyada; sabit PDF turunda gri
  kutu yok; A/B regresyon yok.

---

## FAZ 79 — İkincil ekranlar + boş/çevrimdışı hâller [Opus · P40 · `[apk]`]

**Önce oku:** `calendar_views.dart` (ajanda satırı), `calendar_entry_delete.dart`,
`settings_screen.dart` (`_settingsGroups`), `settings_sections/settings_account.dart`
(`_ProfileCard`), `folders_screen.dart`, `folder_tile.dart`, `trash_screen.dart`,
`archive_screen.dart`, `inbox_screen.dart`. **Önce `istek_tara.py`** (takvim ve ayarlar
dosyaları kullanıcı isteğiyle dolu — §4 Y11–Y13).

- [x] **F79.1 Ajanda satırı (D16).** *(2026-11-12: `_EntryShell` 56/64 dp, başlık `rowTitle`, alt `meta`, durum simgeleri 18; `QuickDeleteButton` 18 dp %60, hedef 48 — çöp kaldı; gün levhası da aynı satırı kullanır. Test `calendar_screen_test`.)* Yerleşim aynı; yalnız ölçü birliği: başlık her türde
  `rowTitle` (16), alt satır `meta`; satır yüksekliği tek satırlıda 56, iki satırlıda 64;
  sağdaki durum simgeleri (🔔 ↻) 18 dp `onSurfaceVariant`. Çöp düğmesi (`QuickDeleteButton`)
  KALIR (§4 Y11); simgesi 18 dp, `onSurfaceVariant` %60 (sessiz ama görünür), hedef 48.
  Ay/hafta/yıl görünümlerine ve takvim başlığına DOKUNMA (§4 Y12, Y13).
- [x] **F79.2 Ayarlar (D18).** *(2026-11-12: `_AreaIcon` köşe `m`, `_CategoryTile` `rowTitle`+`meta`, kısayollar kategori kartıyla aynı nötr zemin; misafir kartı "Misafir" + "Yalnız bu cihazda" + "Giriş yap" (`linkGuestAccount`). Test `settings_profile_card_test`. Turda misafir hâli yok — cihazda doğrulanmadı.)* Kök: simge kutuları nötr (F73.1-5), 40 dp, köşe `m`; satır
  başlığı `rowTitle`, alt yazı `meta`; "Kullanım kılavuzu" ve "Kişiselleştir" kartları AYNI
  nötr ton. `_ProfileCard` misafirde: "Misafir · Yalnız bu cihazda" + "Giriş yap" düğmesi
  (var olan giriş akışı). Sıra ve gruplar (Hesap en üstte, ayar arama sabit — kullanıcı
  istekleri) AYNEN.
- [x] **F79.3 Klasörler (D19).** *(2026-11-12: satır satır ızgara (sıra korunur), boş kart 72 dp "Boş", ızgaradaki Yeni klasör karosu kalktı; sırala düğmesinin ipucu zaten vardı. Test `folders_screen_test`.)* Üstteki "Yeni klasör" düğmesi kalır (F73.1-3 tonu);
  ızgaradaki "Yeni klasör" karosu kalkar. Boş klasör kartı 72 dp (simge + ad + "Boş"),
  dolu kart bugünkü 128 dp. Sıralama simgesine `Tooltip`.
- [x] **F79.4 Çöp / Arşiv / Gelen (D19).** *(2026-11-12: Çöp ⋮ = Akıllı analiz · Hepsini geri yükle · Çöpü boşalt (`error`); kartta etiketli "Geri al" · "Sil" (dar kartta birlikte küçülür). Arşiv ⋮ = özet + sıralama (`NoteSortMenu(extras:)`). Gelen'in tek düğmesi (hepsini okundu) olduğu gibi. Test `trash_archive_bar_test`.)* Üst çubuk: Ara + ⋮ (Analiz, Geçmiş, Çöpü boşalt
  ⋮'e; "Çöpü boşalt" `error` renkli). Çöp kartının altı: iki ETİKETLİ metin düğmesi "Geri
  al" · "Sil" (`error`). Düzenli ızgara (kullanıcı isteği 2026-09-23) aynen.
- [x] **F79.5 Boş hâller (D23).** *(2026-11-12: `EmptyState` §2.3 ölçüsü (72 dp nötr daire, simge 32, `rowTitle` + `body`, dikeyde %38); bütün boş hâl başlıkları "Burada … yok", açıklama tek cümle — bekçi `terminology_test` (koddaki `EmptyState(` çağrılarından toplar). Tur `TOUR_EMPTY=1`: ana-bos, klasor-bos, arsiv-bos, cop-bos, gelen-bos, arama-bos.)* `EmptyState` kullanımları: metinler tek kalıp — başlık
  "Burada … yok", açıklama bir cümle, düğme bir sonraki adım (`terminology_test`). Tura
  `TOUR_EMPTY=1`: boş ana ekran, boş klasör, boş arşiv, boş çöp, boş Gelen, boş arama
  sonucu.
- [x] **F79.6 Çevrimdışı / hata hâlleri (OTURTMA F66.6 — P18'den buraya taşındı).** *(2026-11-12: tur `TOUR_OFFLINE=1` → cevrimdisi-ana, -n1, -ek, -ai, -cop, -gelen. Bulgular: (1) `ErrorState` başlığı üç satırlık "Bir şeyler ters gitti: …" paragrafıydı → kısa başlık ("Bağlantı yok" / "Yüklenemedi") + açıklama, çevrimdışıyken bulut simgesi — DÜZELDİ; (2) Gelen ve paylaşılanlar okuma hatasında "burada not yok" diyordu → hata görünümü + Tekrar dene — DÜZELDİ; (3) ana ekranın "Gelen" süzgecinde (`dashboard_slivers._hubSlivers`, P19 alanı) aynı kalıp — **sabah bakılacak**; (4) AI levhası çevrimdışıyken düğmeleri etkin gösteriyor, hata ancak dokununca bildirim (levha P37 alanı) — **sabah bakılacak**; (5) bekleyen ek şeridi bağlantı yokken de "yükleniyor" diyor — bağlantı algısı yeni özellik (K-O1), **sabah bakılacak**; (6) editörün bulut simgesi (bekliyor = yükleme bulutu %90) tutarlı; ek rozeti turda görünmüyor (turda oturum yok) — cihazda doğrulanmadı.)*
  Çevrimdışıyken not ekranı bulut simgesi, bekleyen ek, AI düğmeleri ne gösteriyor; tura
  `TOUR_OFFLINE=1` ile 6 görüntü. Tutarsızlıklar madde olur ve §2.3 bileşenleriyle
  düzeltilir. OTURTMA'da F66.6 `[x]` + "→ DENEYIM F79.6".
- Kabul: `takvim-telefon-agenda`, `telefon-ayarlar`, `telefon-klasorler`, `telefon-cop`
  önce/sonra; boş hâl turu 6 sahne; çevrimdışı turu 6 sahne.

---

## FAZ 80 — Koyu tema, küçük ekran, web cilası [Sonnet döküm + Opus düzeltme · P42 · `[apk]`]

- [ ] **F80.1 Koyu tema (D24).** `TOUR_DARK=1` 3 boyutta (telefon, matepad-yatay, masaustu).
  Bu incelemede görülenler (dosya adı `telefon-<sahne>-koyu.png`):
  1. İki parlak yüzey (ev düğmesi + "+") — F74.1 çözer; doğrula.
  2. Koyu renkli not kartı koyu zeminde kayboluyor (`telefon-ana-koyu.png` sol üst mor
     kart): renkli kartın kenar çizgisi koyu temada `noteInk` %16 (renksiz kart değişmez).
  3. PDF önizlemesi koyu ekranda bembeyaz (aynı görüntü, sağ alt): koyu temada belge
     ÖNİZLEMESİNİN üstüne %8 siyah perde (açık belgenin kendisi değil; görsel kartları
     değil).
  4. "Sil" satırı dolu koyu kırmızı blok (`telefon-n4-menu-koyu.png`) — `DestructiveRow`
     çözer; doğrula.
  5. Kart–zemin ayrımı (ölç): 20 ailenin koyusunda `card` ile `ground` OKLCH L farkı
     < 0,04 olanlar dökülür; düzeltme palet değerinde, `theme_contrast_test`'e "kart
     zeminden en az 0,04 L açık" satırı. Ölçmeden değer değiştirme.
  Döküm `docs/deneyim/koyu.md`.
- [ ] **F80.2 Küçük ekran + büyük yazı.** OTURTMA F66.4'ü P18 yaptı (2026-11-12:
  telefon-kucuk/uzun turu taşmasız) — o iş TEKRARLANMAZ. Burada yalnız: bu planın krom
  değişikliklerinden SONRA aynı turun yeniden koşulması (`TOUR_SIZES=telefon-kucuk,
  telefon-uzun` + `TOUR_COMPARE`) ve yeni olan büyük yazı turu (tura `TOUR_FONT=1.3`):
  taşan/kesilen her yer madde olur ve düzeltilir.
- [ ] **F80.3 Web / masaüstü (OTURTMA F67.7 — P18'den buraya taşındı).** (a) D22: bölüm
  çizgisi ızgara genişliğinde bitsin ya da ≥ 840 dp'de çizilmesin (turda hangisi temizse).
  (b) Fareyle üstüne gelme: kart, karo, satır, çip — yalnız `touchFirst == false`. (c) Odak
  halkası: klavyeyle gezinirken 2 dp `primary`. (d) F67.7'nin kalanı: kısayol levhası
  (Ctrl+/; `app.dart` `shortcuts` haritasından üretilir), kart ve maddede sağ tık = uzun
  basış menüsü, Tab sırası. OTURTMA'da F67.7 `[x]` + "→ DENEYIM F80.3".
- [ ] **F80.4 Dokunma hedefi taraması.** `accessibility_test` kalıbıyla: ana ekran, not
  ekranı (klavyeli/klavyesiz), menü, takvim, ayarlar — 48 dp altı hedef 0 (istisna listesi
  testte, gerekçeli).
- [ ] **F80.5 Önce/sonra dosyası.** `docs/deneyim/once-sonra.md`: 12 sahnenin önce/sonra
  görüntü adları + ölçülen sayılar (mandal bütçeleri, A/B tabloları, `prof_new.py`, beyaz
  kare). `docs/cihaz_turu.md`'ye bu planın elle bakılacak adımları. **HAFIZA / CLAUDE.md /
  KALANLAR toparlaması BURADA YAPILMAZ — P21'in (F69.5) işidir; tek kapanış.**

---

## Yapılmayacaklar (genel)

- §4'teki 16 fikir.
- Yeni özellik, yeni ekran, yeni ayar sayfası. (İzinli tek yeni tercih: `card_show_checked`.)
- Yeni paket. İzinli tek yerel bağımlılık: `core-splashscreen` (K-D8).
- Bulanıklık (`BackdropFilter` — "+" panelinden 2026-10-15'te kasma yüzünden kaldırıldı),
  bulanık gölge, gradyan zemin, ışıltı, paralaks, zıplayan eğri.
- Boy animasyonu — hiçbir yerde. Çubuk yüksekliği değişimi — hiçbir yerde.
- Not başlığı/gövdesi stilini, kalem tepsisini, biçim çubuğunu, sayfa geçiş sürelerini
  değiştirmek.
- 20 tema ailesinden birini silmek ya da renklerini "iyileştirmek" (F80.1'in ölçümlü koyu
  düzeltmeleri hariç).
- `UiItem`, `menuId`, `ValueKey` kimliklerini değiştirmek.
- `dart format lib`, tam test takımını yerelde koşmak, CI kırmızıyken birleştirmek,
  ölçmeden "akıcı" yazmak.

---

## Ek A — Kabul ölçütleri

| Ölçüt | Bugün | Hedef | Nasıl ölçülür |
|---|---|---|---|
| Köşe değeri (elle, editör hariç göç sonrası) | 344 / 28 farklı | ≤ 120 | `token_sayim.py` |
| Punto (elle) | 215 / 19 farklı | ≤ 70 | aynı |
| Süre (elle) | 219 / 39 farklı | ≤ 110 | aynı |
| Krom kalınlığı w700+ | 116 | ≤ 60 (editör + içerik biçimleri) | aynı |
| Doğrudan `HapticFeedback` çağrısı | 86 | 0 | mandal |
| Ana ekranda dolu birincil yüzey | 3 (ev, +, bugün) | 2 (+, bugün) | tur |
| Kartta okunan işaretsiz madde | çizili satırlar arasında | en üstte | tur |
| Not alt çubuğu dokunma hedefi | 40 dp | 48 dp | `accessibility_test` |
| Renkli notta çubukta tema vurgusu | var | yok | tur (`n1`, `n4`) |
| Menü levhası (412×915) | ≈ %85 | ≥ 100 dp kısa | tur |
| Levhalarda başlık / bölüm adı dili | 4 | 1 | tur |
| Soğuk açılışta beyaz kare | ~0,6 sn | 0 | `screenrecord` |
| Yeni not (2. dokunuş → imleç) | ölçülmedi | ≤ 450 ms | `prof_new.py` |
| A/B (klavye, yazma, kapanış, liste) | taban | hiçbir evre > +%20 | `ab_klavye.py`, `ab_liste.py` |
| Taşma (9 boyut × açık/koyu) | 0 istisna | 0 | tur |

## Ek B — Paket → madde eşlemesi (OTOMASYON kuyruğu)

| No | Paket | Model | Maddeler | Cihaz | APK |
|---|---|---|---|---|---|
| P33 | Tasarım zemini: belirteç, mandal, ortak bileşen | opus | F72.1–F72.5 | | |
| P34 | Renk rolleri + sakin tipografi | opus | F73.1–F73.4 | | evet |
| P35 | Ana ekran cilası | opus | F74.1–F74.6 | A/B | evet |
| P36 | Not ekranı alt çubuğu | fable | F75.1–F75.3 | A/B | evet |
| P37 | Levhalar: ortak başlık, ortak karo | opus | F76.1–F76.4 | | evet |
| P38 | Hareket ve dokunsal dil | opus | F77.1–F77.4 | A/B | evet |
| P39 | Hız hissi | fable | F78.1–F78.5 | cihaz | evet |
| P40 | İkincil ekranlar + boş/çevrimdışı hâller | opus | F79.1–F79.6 (F66.6 dahil) | | evet |
| P41 | Belirteç göçü (mekanik; editör hariç) | sonnet | F72.6 | | |
| P42 | Koyu tema, küçük ekran, web cilası | sonnet + opus | F80.1–F80.5 (F67.7 dahil) | | evet |

## Ek C — Tuzaklar (HAFIZA'dan, bu planın dokunduğu yerler)

- Editör ve kart dosyalarında `Theme.of(context)` yazma → `_themeOf` / `_cardInk`.
- `ItemsEditor` satır önbelleği: bu planın hiçbir maddesi satıra yeni alan eklemez.
- Editörün kök `setState`'i yok; yerel durum `ValueNotifier` + dar dinleyici.
- `KeyboardSwitch` alt ağacı sökmez (`Offstage`); `MediaQuery.of(context)` kök bağlamda
  okunmaz.
- Klasör şeridi ızgaranın dışında sabit başlık; giriş/çıkışta genişlik sıçramasın.
- "+" düğmesine `tooltip` verme; profil levhasına `FilledButton` koyma;
  `SegmentedButton`'a `VisualDensity.compact` verme.
- Yeni metin: `lib/l10n/*.arb` tr + en, `flutter gen-l10n`; `arb_case_test`,
  `terminology_test`; üretilen klasör `dart format`.
- Yeni worktree'de önce `flutter pub get`; push'tan önce TAM `flutter analyze`.
- Tur `debugDisableShadows` ile çizer: "+" ve panel çevresindeki koyu halka GERÇEK DEĞİL.
- Betik yazarken ters bölü: Bash heredoc bozar, dosyayı `Write` ile yaz.

## Ek D — Çakışma ve tekrar haritası (2026-11-12 taraması)

Amaç: aynı dosyaya iki paket girip birbirinin işini bozmasın, aynı iş iki kez yapılmasın.
Yürütücü TEK olduğu için birleştirme çakışması değil **yeniden iş** riski var; aşağıdaki
kurallar onu keser.

### D.1 Paket × dosya (kim nereye dokunur)

| Alan (dosyalar) | Sahibi | Diğer paketlere kural |
|---|---|---|
| `dashboard_screen.dart` gövdesi, `notes_providers.dart` | **P19** (F68.1–F68.2, sürüyor) | P35 bu dosyaya GİRMEZ; yalnız `dashboard_shelf`, `home_calendar_strip`, `due_banner`, `note_card`, `card_preview` |
| Bölünmüş görünümde liste bölmesi (şeritler, arama hapı kısalması, tek "+") | **P18** (F67.3) | P35 arama hapına ve şerit görünürlüğüne dokunmaz |
| Editör çubuk YÜKSEKLİKLERİ, yatay + klavye bütçesi | **P18** (F67.4); klavye davranışı P23/P25 (bitti) | P36 yükseklik ve gizlenmeye dokunmaz; yalnız kapsül içeriği, dokunma alanı, renk |
| `split_shell.dart` (liste sağa) | **P18** (F67.9) | — |
| `note_editor_toolbar.dart`, `editor_bar_layout.dart`, editörde alt çubuk bloğu | **P36** | P20 bölge çıkarırken bu bloğu "alt çubuk" bölgesi olarak AYNEN taşır, yeniden tasarlamaz |
| `note_editor_screen.dart` yapısı (bölge çıkarma, `_mutate`) | **P20** (Faz 64) — P36'dan SONRA | P34/P38/P41 `editor/` klasörüne girmez |
| Sabit ek çubuğu (`pinned_media_pane.dart` çubuğu) | **kimse** (K-O6 kullanıcıda) | P36 ve P22 dokunmaz; yalnız F78.3(b) yükleme hâli (çubuk değil, bölmenin içi) |
| `action_menu_sheet.dart`, paylaş ve AI levhaları | **P37** | P28'in "+" paneli düzen kipi (bitti) ve Ekle karoları değişmez |
| Takvim görünümleri | **P40 yalnız ajanda satırı** | P31 (bitti) kaydırma ayarı aynen; ay/hafta/yıl kimsede değil |
| `card_preview.dart`, `note_card.dart` | **P35** | P26, P32 (bitti) davranışları korunur; OTURTMA F68.4 (kart katman sayımı) P35'TEN SONRA ölçülür (P22) |
| Titreşim/hareket çağrıları | **P38** | P29 (uzun bas iki aşama), P30 (çöp efekti), P27 (sürüklerken çöp) değerleri değişmez, yalnız `AppHaptics`'e sarılır |
| Açılış (Android `styles.xml`, `MainActivity`) | **P39** | P10 güncelleme yolu aynen |
| Bütün `lib/` (editör hariç) literal göçü | **P41** | başlarken açık dal olmayacak |
| Plan/HAFIZA/CLAUDE toparlaması, cihaz turu, konsol listesi | **P21** (F69.4–F69.5) | P42 yalnız `docs/deneyim/` yazar |

### D.2 Başka paketten BU plana taşınan maddeler (orada yapılmaz)

| OTURTMA maddesi | Eski paket | Yeni yeri | Neden |
|---|---|---|---|
| F66.4 küçük telefon turu | P18 | P18'de YAPILDI (dalda, 2026-11-12) | F80.2 yalnız krom sonrası yeniden tur + büyük yazı |
| F66.6 boş/hata/çevrimdışı hâller | P18 | F79.6 (P40) | `EmptyState` yeni ölçüsüyle bir kez yapılsın |
| F67.7 klavye ve fare | P18 | F80.3 (P42) | üstüne gelme/odak halkası aynı tur |
| F60.7 beyaz açılış (K-O14) | P22 | F78.1 (P39) | karar verildi (K-D8) |
| F63.5 / F66.2 alt çubukta kalem (K-O5) | P22 | F75.1 (P36) | karar verildi (K-D6) |
| F66.1 ana ekran tepesi (K-O10) | P22 | kapanır: "bugünkü" (K-D4) + F74.2 | şerit kullanıcı isteği |
| F66.3 kartta işaretliler (K-O11) | P22 | F74.4 (P35) | karar verildi (K-D5) |

**P18'in dalı (`oto/P18-telefon-tablet`, 2026-11-12 01:17) F67.3, F67.4, F67.9 ve F66.4'ü
yapmış durumda; sırada bekleyen F66.6 ve F67.7'yi YAPMADAN doğrulanıp birleştirilir.**
P18'in getirdikleri bu planın sınırıdır: dar liste bölmesinde (< 420 dp) arama hapında AI
ve süz gizli (`kNarrowListPane`), kısa pencerede klavyeyle alt çubuk gizli
(`ShortKeyboardBarHide`), pencere < 480 dp iken üst çubuk 40 dp — P35/P36 bunlara dokunmaz.
P22'de bu plandan dolayı ATLANACAK: yukarıdaki maddeler + K-O5, K-O10, K-O11, K-O14. **K-O6 / F65.1 P22'de de yapılmaz** (kullanıcıda açık).
OTURTMA F66.5 (tek elle erişim raporu) P22'de yalnız RAPOR olarak kalır; §4 Y7–Y8 gereği
"+" ve geri oku için değişiklik önermez.

### D.3 Sıra ve gerekçe

1. **P19** ve **P18** (ikisi de dalda, 2026-11-12): önce yerleşimi değiştiren işler bitsin (pano bölünmesi,
   liste bölmesi, çubuk yükseklikleri). Cila onların ÜSTÜNE gelir; tersi olursa cila iki
   kez yapılır.
2. **P33** hemen ardından: sonraki her paket onun bileşenlerini kullanır. P33 görünümü
   değiştirmez, P18 ile sırası değişebilir (limit durumuna göre) — ama P34–P40'tan önce
   bitmiş olmalı.
3. **P34 → P35 → P36 → P37 → P38 → P39 → P40**: her biri farklı dosya kümesi (D.1);
   Fable paketleri (P36, P39) limit %55'in üstündeyken başlatılmaz, sıradaki Opus paketi
   öne alınır — P34–P40 arasında sıra değişimi serbest, tek şart P33 bitmiş olsun.
4. **P41** (göç) P40'tan sonra, açık dal yokken: krom işleri bitmeden göç yapılırsa aynı
   satırlar iki kez değişir.
5. **P42**: göçten sonra son tur (koyu, küçük ekran, web) — taranan ekran son hâli olsun.
6. **P20** (editör çekirdeği) P36'dan ve P42'den sonra: en riskli iş sonda (OTURTMA kararı);
   alt çubuk o sırada yerleşmiş olur, P20 onu yalnız taşır.
7. **P21 → P22**: tek kapanış; P22 açıkta kalanları değerlendirirken D.2'yi atlar.

### D.4 Bitmiş paketlerle uyum (geri alma yok)

Bu plan şu bitmiş işlerin davranışını DEĞİŞTİRMEZ; dokunduğu yerde korur: P04 ("Tümü" çipi
dokun/uzun bas), P06 (PDF dikey), P07 (`WindowClass`), P17 (PDF küçük resmi — F78.3
kullanır), P23 (`KeyboardInsetScope`), P24/P29 (uzun bas), P25 (yazarken panel gizleme
ayarları), P26 (gizli eke özet), P27 (sürüklerken çöp), P28 ("+" düzen kipi), P30 (çöp
efekti), P31 (takvim kaydırma ayarı), P32 (kartta işaretli kutu).
