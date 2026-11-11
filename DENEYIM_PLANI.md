# DENEYİM PLANI — Faz 72–80 (görünüş · his · hız · tutarlılık)

**Tarih:** 2026-11-12 · **Taban commit:** `d2491206` · **Yazan:** Fable 5.2 incelemesi
(ekran turu 9 boyut × 31 sahne + takvim + koyu tema = 320 görüntü; kod sayımı
`tool/design/token_sayim.py`; tema, hareket, levha ve editör kromu kodunun okunması).

**Kullanıcı isteği (2026-11-12):** "Son kullanıcının gördüğü ve uygulamayı kullanırken
hissettiği her şeyi baştan sona incele: renk, tasarım, animasyon, hız, boyut, işlev.
'Vay, bu uygulama çok iyi kullanılıyor' dedirtecek; abartılı olmayan, kullanışlı,
mükemmelleştirilmiş bir uygulama. Hepsini tespit et, ne ve nasıl yapılacağını belirle,
fazların üzerine ekle; süren oturum main'den devralıp yapacak. Tasarım sende, ıvır zıvır
işleri alt modeller yapabilir. Her konuda serbestsin."

Bu dosya `OTURTMA_PLANI.md`'nin DEVAMIDIR (Faz 58–71 orada). Yürütme düzeni yine
`OTOMASYON.md` (kuyruk P33–P42). Hedef görünüm: **`docs/deneyim/hedef.html`** (tarayıcıda
aç; ölçüler oradaki CSS değişkenleriyle bu dosyadaki tablolar AYNI — çelişirse bu dosya
geçerli).

> Satır numaraları `d2491206` içindir ve kayar. Bir yeri bulamazsan ADIYLA ara.

---

## Bu dosya nasıl kullanılır (protokol)

`OTURTMA_PLANI.md` protokolü aynen geçerli (kanıtı üret → düzelt → aynı kanıt yeşil →
`[x]` + tek satır → commit; faz sonu regresyon turu). Bu plana özgü ekler:

1. **Görsel kanıt = ekran turu.** İşe başlamadan `flutter test tool/tour/screen_tour_test.dart`
   çıktısını `build/tour-once/`'ye kopyala; iş bitince `TOUR_COMPARE=build/tour-once` ile
   yeniden koş. Değişmesi BEKLENMEYEN sahnede fark > %0,5 ise neden bak. Maddenin
   kabulünde adı geçen PNG'ye `Read` ile kendin bak (alt ajan raporuna güvenme).
   Koyu tema: `TOUR_DARK=1 TOUR_SIZES=telefon TOUR_OUT=build/tour-koyu`.
2. **Kararlar VERİLDİ.** §3'teki K-D kararlarını kullanıcı "tasarım sende, her konuda
   serbestsin" diyerek Fable'a bıraktı (2026-11-12). Gözetimsiz oturum bunları SORMADAN
   uygular; `OTOMASYON.md`'deki "KARAR → en güvenli" kuralı yalnız bu dosyada OLMAYAN yeni
   bir karar çıkarsa geçerlidir. Her K-D **tek başına geri alınabilir tek commit** olur
   (kullanıcı beğenmezse `git revert`); commit başlığında karar numarası geçer.
3. **Yeni özellik yok** (K-O1 dondurması sürüyor). Bu plan var olanı sadeleştirir,
   hizalar, hızlandırır. Bir madde yeni yetenek gerektiriyorsa yapılmaz, maddeye yazılır.
4. **Akıcılık kapısı bağlayıcı.** Editör, klavye, alt/üst çubuk, ana ekran listesi ya da
   geçişe dokunan paket CLAUDE.md "ÖLÇÜM KAPISI"ndan geçer; "Kasma kontrol listesi"nin 8
   maddesi her editör/ızgara değişikliğinde tek tek işaretlenir. Bu planın hiçbir maddesi
   boy animasyonu, kök `setState`, koşula göre değişen ağaç şekli GEREKTİRMEZ — gerektiğini
   düşünüyorsan yanlış yoldasın, maddeyi yeniden oku.
5. **Model:** tasarım kararı bu dosyada bitti; uygulayıcı tasarlamaz, ölçüye uyar. Editör
   ve liste performansına dokunan paketler Fable'da (kullanıcı kararı 2026-11-09), gerisi
   Opus; mekanik göç ve tur dökümü Sonnet.
6. Kullanıcıya görünen her paket `[apk]` + sürüm notu (tr + en, kullanıcı diliyle).

---

## Durum

| Faz | Konu | Paket | Model | Durum |
|---|---|---|---|---|
| 72 | Zemin: belirteçler, mandal testi, ortak bileşenler | P33 | Opus | Bekliyor |
| 73 | Renk rolleri + sakin tipografi | P34 | Opus | Bekliyor |
| 74 | Ana ekran (telefon önce) | P35 | Fable | Bekliyor |
| 75 | Not ekranı kromu | P36 | Fable | Bekliyor |
| 76 | Levhalar ve menüler tek dil | P37 | Opus | Bekliyor |
| 77 | Hareket ve dokunsal dil | P38 | Opus | Bekliyor |
| 78 | Hız hissi (açılış, yeni not, yükleme hâlleri) | P39 | Fable | Bekliyor |
| 79 | İkincil ekranlar (takvim, ayarlar, klasörler, çöp, AI, boş hâller) | P40 | Opus | Bekliyor |
| 72.6 | Belirteç göçü (mekanik) | P41 | Sonnet | Bekliyor |
| 80 | Koyu tema, küçük ekran, web cilası, kapanış turu | P42 | Sonnet + Opus | Bekliyor |

**Sıra:** 72 → 73 → 74 → 75 → 76 → 77 → 78 → 79 → 72.6 → 80. Faz 72 önce: sonraki her faz
onun bileşenlerini kullanır. Faz 74, `OTURTMA` P19'dan (pano gövdesini böl, F68.2) SONRA
gelirse başlık yığını ayrı widget olur ve iş kolaylaşır; P19 yapılmadıysa da başlanır.

---

## 0. Değerlendirme

### İyi olan (dokunma, üstüne kur)

- **Görsel fikir doğru:** "masa ve kâğıt" (zemin orta ton, kart açık), not rengi kartta ve
  açık notta aynı, mürekkep saf siyah değil. Tur görüntülerinde ekran kirli ya da soğuk
  durmuyor.
- **Asıl hareketler yerinde:** kart → not genişleyerek açılıyor (`note_open_route.dart`),
  levhalar tek eğriyle geliyor (`app_sheet.dart`), kart basınca %2 çöküyor (`PressScale`),
  madde işaretlenince `_CheckPop`/`_CheckMove`. Bunlar ölçülerek yazılmış; yeniden yazma.
- **Altyapı hazır:** tek simge sözlüğü, tek menü kataloğu (`noteMenuModel`), tek Ekle
  kataloğu (`addCatalog`), `SheetHeader`/`SectionLabel`, `EmptyState`, `showUndoSnackBar`,
  kontrast/erişilebilirlik/terim bekçileri, 9 boyutlu ekran turu + önce/sonra farkı.

### "Vay" dedirtmeyi engelleyen (bu planın gerekçesi)

1. **Değerler elle, ölçek yok.** Tek ekranda 3–4 farklı köşe, yarım puntolu yazılar, 39
   farklı süre. Tek tek hiçbiri hata değil; toplamı "tam oturmamış" hissi (§1 D1).
2. **Krom içerikten yüksek sesle konuşuyor.** Ana ekranda en koyu, en büyük şey notlar
   değil 56 dp'lik ev düğmesi ve "+"; not ekranında en doygun yüzey yazı değil sağ alttaki
   petrol kapsül; mor notta bile petrol (D4, D9).
3. **Aynı iş dört kılıkta.** Dört levhada dört ayrı karo dili (D12). Üç vurgu rengi
   kuralsız dağılmış: "oluştur" bir yerde petrol, iki yerde şeftali; hatırlatıcı mor (D3).
4. **Yoğunluk iki uçta.** Menü levhası 360×640'ta ekranı aşıyor (D11); telefonda alt çubuk
   8 etiketsiz simge, sabit ekli notta 10 tane daha (D8, D10). Öte yanda kartların her
   birinde ⋮, işaretli maddelerin üstü çizili satırları (D6).
5. **İlk yarım saniye.** MIUI'de ~0,6 sn beyaz açılış (HAFIZA, çözülmedi); sabit PDF'te gri
   kutu + dönen halka (D15).
6. **İkincil ekranlar ana ekranın düzeyinde değil.** Ajandada her satırda çöp kutusu, ay
   görünümünde 42 çerçeveli kart, ayarlarda rastgele renkli simge kutuları (D16–D19).

Hiçbiri yeniden yazım gerektirmiyor: ölçek + rol kuralı + dört ekranın kromunun
sadeleşmesi + ortak karo. Büyük his kazancı Faz 73–76'da; Faz 72 onların zemini.

---

## 1. Kanıtlı bulgular

Sayılar `python tool/design/token_sayim.py` çıktısıdır (tanım dosyaları ve çeviriler
hariç). Görüntüler `build/tour/` (koyu: `build/tour-koyu/`); yeniden üretmek için protokol 1.

| # | Bulgu | Kanıt | Faz |
|---|---|---|---|
| **D1** | Görsel değerlerde ölçek yok | köşe 344 kullanım / **28** farklı değer (12×57, 10×53, 14×47, 16×32…); `fontSize` 215 / **19** (12,5 · 13,5 · 14,5 · 10,5 · 11,5 · 9,5 · 8,5 dahil); süre 219 / **39** (200, 220, 240, 260, 280 ayrı ayrı); eğri 95 çıplak `Curves.` (easeOutCubic 59) — `AppMotion` yalnız 44 yerde; simge boyutu 509 / 30; saydamlık 241 / 39 | 72 |
| **D2** | Krom fazla kalın | `FontWeight.w700` 107, `w800` 9, `w600` 86, `w500` 19: arayüz yazısının yarısı kalın. Tur `telefon-ayarlar.png` (satır başlıkları), `telefon-n4-menu.png` (bölüm adları) | 73 |
| **D3** | Üç vurgu rengi kuralsız | palet ilkesi (`app_palette.dart` başlığı): serin vurgu = dokunulacak yer, sıcak vurgu = dikkat (sabitli, yıldız, hatırlatıcı). Uygulamada: zamanı gelen şeridi **mor** (`due_banner.dart:73` `tertiaryContainer`); editörde "+" ve Klasörler'de "Yeni klasör" **şeftali** (`_addToolButton`, `telefon-klasorler.png`); etiket hapı şeftali (`tag_pill.dart:17` `secondaryContainer`); paylaş levhasında Kopyala/PDF/Görsel şeftali daire; ayarlarda simge kutuları petrol/mor/şeftali/gri karışık (`telefon-ayarlar.png`) | 73 |
| **D4** | Ana ekranda en ağır öğe içerik değil | `telefon-ana.png`: 56 dp dolu ev düğmesi (`dashboard_shelf.dart` `home-strip-at-home`) + dolu "+" + mikrofon; ev düğmesi 2026-11-10'dan beri "Tümü" çipiyle AYNI işi yapıyor (F60.S3: dokun = bütün notlar + `goHome`) | 74 |
| **D5** | Arama hapı 5 denetim taşıyor | `telefon-ana.png`: 🔍 · ✨ · süz · hesap · ⋮ (`dashboard_widgets.dart` `_SearchField.trailing`); süz zaten ⋮ → "Görünüm ve süz"de; 320 dp liste bölmesinde ipucu "Notlard…" diye kesiliyor (`matepad-yatay-n1.png`) | 74 |
| **D6** | Kart gürültüsü | her kartta ⋮ (ekranda 16 düğme); işaretli maddeler üstü çizili 5–6 satır (`telefon-ana.png` ilk iki kart — okunacak tek satır yok); klasör çipinde sayı simgenin üstüne binmiş 9–10 pt rozet | 74 |
| **D7** | Takvim şeridinde gün harfi belirsiz | telefonda `weekday.characters.first` (`home_calendar_strip.dart:286`): "P C C P P S Ç P C C" — Pazartesi/Perşembe/Pazar üçü de P, Cuma/Cumartesi ikisi de C | 74 |
| **D8** | Not alt çubuğu: 8 etiketsiz simge, 40 dp hedef, renk çatışması | `telefon-n4.png`; `kEditorBarSegment = 40` (`editor_bar_layout.dart:24`) — 48 dp kuralının altında; ses dalgası ile mikrofonun farkı simgeden anlaşılmıyor; sağ kapsül `primaryContainer` dolu: mor notta petrol (`telefon-n1.png`), sarı notta petrol (`telefon-n4.png`) | 75 |
| **D9** | Telefonda not ekranında geri düğmesi yok; iki ayrı "+" | `_listLeading` telefonda `null` döner (`note_editor_screen.dart` ~2424); başlık satırındaki "+" (`note-meta-chip`, etiket/hatırlatıcı menüsü) ile alt çubuktaki "+" (ek ekle) aynı simge, farklı iş | 75 |
| **D10** | Sabit ek çubuğu 10 denetim | `telefon-e-pdf-sabit.png`: ⛶ · ✏ · • · not al · T · balon · [üç görünüm] · bağlantı · ⋮ (OTURTMA F65.1, K-O6 açık) | 75 |
| **D11** | Menü levhası ekrandan uzun | `telefon-kucuk-n4-menu.png`: 360×640'ta "Koruma ve depolama" başlığında kesiliyor, "Sil" görünmüyor; 412×915'te ekranın %85'i. 60 dp gri dairelerde 16–20 iş: hepsi aynı görünüyor, etiket simgenin altında ortalı (taranması zor). Altta "Ekranı düzenle" + "Ayarlar" + başlıkta ⚙: üç ayrı düzenleme kapısı | 76 |
| **D12** | Dört levha, dört karo dili | Ekle: dolu tonlu karo, içinde daireli simge, 3'lü dikey + 2'li yatay + tam genişlik karışık (`telefon-n4-ekle.png`); AI: çerçeveli kart + açıklama (`telefon-n4-ai.png`); Menü: daire + alt etiket (`telefon-n4-menu.png`); Paylaş: şeftali daire + kutusuz büyük satır (`telefon-n4-paylas.png`). Bölüm adı menüde ~18 pt, paylaşta ~14 pt. Tutamak + ✕ birlikte: üstte ~50 dp ölü şerit | 76 |
| **D13** | Hareket dili dağınık | D1 süre/eğri sayıları; `elasticOut` 1, `easeOutBack` 6; `HapticFeedback` 86 doğrudan çağrı (selectionClick 68, mediumImpact 16, lightImpact 2) — hangi iş hangi titreşim, kural yok | 77 |
| **D14** | Beyaz açılış | HAFIZA arayüz "Beyaz açılış (ÇÖZÜLMEDİ)": MIUI 13'te ~0,6 sn; OTURTMA K-O14 açık | 78 |
| **D15** | Yükleme hâli = gri kutu + halka | `telefon-e-pdf-sabit.png` (sabit PDF bölmesi); `CircularProgressIndicator` 74 yerde, gecikmesiz: 100 ms'lik işte de yanıp sönüyor | 78 |
| **D16** | Ajandada her satırda çöp kutusu | `takvim-telefon-agenda.png`; `QuickDeleteButton` (`calendar_entry_delete.dart:127`): ekranda 9 yıkıcı düğme; satır boyları ve başlık puntoları türe göre farklı (görev 16 pt, etkinlik 20 pt) | 79 |
| **D17** | Ay görünümü 42 çerçeveli kart; başlık görünüme göre değişiyor | `takvim-telefon-month.png` (her gün köşeli kart; telefonda çipler iki satır 10 pt); ayda "‹ Kasım 2026 ›", ajandada "Kasım 2026 ▾" | 79 |
| **D18** | Ayarlar: rastgele renkli simge kutuları, iki farklı tonda üst kart, misafirde boş profil kartı | `telefon-ayarlar.png` | 79 |
| **D19** | Klasörler: "Yeni klasör" iki kez; boş klasör kartı 128 dp boşluk. Çöp: üstte 4 etiketsiz simge, kartta etiketsiz iki çöp simgesi | `telefon-klasorler.png`, `telefon-cop.png` | 79 |
| **D20** | 12 pt altı yazı | `fontSize` 9–11,5 arası 45 kullanım (kural: okunan metin ≥ 12 pt — `docs/hafiza/arayuz.md`) | 73 |
| **D21** | Tema seçici 20 aile tek ızgarada | `telefon-ayarlar-gorunum.png`: sıra ekleniş tarihine göre, grup yok | 73 |
| **D22** | Geniş ekranda bölüm çizgisi ızgaranın ortasında bitiyor | `masaustu-ana.png` ("Sabit · 3" çizgisi 1165/2000 pikselde); `kSectionHeaderMaxWidth` (`dashboard_slivers.dart`) | 80 |
| **D23** | İlk açılış / boş ana ekran turda yok | tur veri setinde boş hesap sahnesi yok; `EmptyState` 27 yerde kullanılıyor, görünüşleri karşılaştırılmadı | 79 |
| **D24** | Koyu tema: krom ve kartlar turda ayrı incelenmedi | `build/tour-koyu/` bu inceleme sırasında üretildi; bulgular F80.1'de | 80 |

---

## 2. Tasarım dili (sözleşme)

Beş ilke — tereddütte bunlara bak:

1. **İçerik konuşur, krom susar.** Bir ekranda en koyu/en doygun yüzey kullanıcının
   notudur. Çubuk, çip, düğme nötr tondadır; renk yalnız DURUM ya da TEK birincil eylemdir.
2. **Ekran başına tek dolu birincil düğme.** Ana ekranda "+", başka hiçbir şey dolu petrol
   değil.
3. **Aynı iş her yerde aynı kılıkta.** Karo, satır, bölüm adı, levha başlığı tek bileşen.
4. **Hareket yön söyler, süs değildir.** Giriş 200–300 ms, çıkış girişin 2/3'ü; yalnız
   boyama (dönüşüm/saydamlık), asla boy. Zıplama yok.
5. **Dokunuşa 100 ms'de cevap, 300 ms altı işte halka yok.**

### 2.1 Belirteçler (`lib/app/theme/app_tokens.dart`'a eklenir — F72.1)

```dart
abstract final class AppSpace { // boşluk ve dolgu
  static const double xxs = 2, xs = 4, s = 8, m = 12, l = 16, xl = 20, xxl = 24, xxxl = 32;
}
abstract final class AppRadius {
  static const double hair = 2;  // ilerleme çubuğu, imleç, ince şerit
  static const double xs = 4;    // kutucuk, küçük rozet
  static const double s = 8;     // çip, etiket hapı köşesi, ipucu
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
// AppMotion'a eklenir (var olanlar kalır: instant 100, short 200, medium 300, reduced 150):
//   static const quick = Duration(milliseconds: 150);  // kutucuk, çip, sayı değişimi
//   static const long  = Duration(milliseconds: 420);  // sayfa (bugünkü not açılışı)
```

**Yazı rolleri** — `AppText` (aynı dosya). `ThemeData` alır, `BuildContext` DEĞİL (editör
ve kart dosyalarında `Theme.of(context)` yasak — `_themeOf` kullanılır; HAFIZA "Okunurluk"):

| Rol | pt / satır | Ağırlık | Renk | Nerede |
|---|---|---|---|---|
| `badge` | 11 / 14 | strong | — | sayı rozeti, sayfa hapı (okunan metin DEĞİL) |
| `meta` | 12 / 16 | regular | `onSurfaceVariant` | tarih, alt bilgi, açıklama altı |
| `label` | 13 / 18 | medium | `onSurface` | çip, karo adı, küçük düğme |
| `body` | 14 / 20 | regular | `onSurface` | levha metni, satır açıklaması |
| `section` | 14 / 20 | strong | `primary` | bölüm adı (`SectionLabel`) — her levhada ve ana ekranda AYNI |
| `rowTitle` | 16 / 22 | medium | `onSurface` | ayar satırı, liste satırı, zengin karo başlığı |
| `sheetTitle` | 18 / 24 | strong | `onSurface` | levha başlığı, pencere başlığı |
| `screenTitle` | 20 / 26 | strong | `onSurface` | üst çubuk başlığı |

Not başlığı ve gövdesi bu tabloda YOK: onlar `noteTitleStyle` ve kullanıcının yazı ayarı.
Kullanıcının notta yazdığı **kalın** w700 kalır; kural yalnız arayüz kromu içindir.

**Göç eşlemesi** (F72.6 bununla yapılır; tabloda olmayan değer en yakınına):

| Tür | Eski → yeni |
|---|---|
| Köşe | 1–3 → `hair` · 4–5 → `xs` · 6–9 → `s` · 10–14 → `m` · 15–18 → `l` · 20–28 → `xl` · ≥ 32 → `pill` |
| Punto | ≤ 11,5 → 11 (yalnız rozet; okunan metinse 12) · 12–12,5 → 12 · 13–13,5 → 13 · 14–14,5 → 14 · 15–16 → 16 · 17–18 → 18 |
| Ağırlık | krom içinde w700/w800/bold → `strong` (w600); w500 kalır |
| Süre | ≤ 110 → `instant` · 120–170 → `quick` · 180–260 → `short` · 280–350 → `medium` · 380–500 → `long` · > 500 dokunma (bekleme/zamanlayıcıdır, hareket değil — yanına `// bekleme` yaz) |
| Eğri | easeOut/easeOutCubic → `AppMotion.enter` · easeIn/easeInCubic → `exit` · easeInOut* → `standard` · easeOutBack kalır (yalnız onay "pop"u) · elasticOut → `enter` |
| Simge | 11–15 → 16 (`xs`) yalnız satır içi; 17–19 → 18 · 20–22 → 20 · 24–28 → 24; ≥ 30 resim/boş hâl simgesidir, dokunma |
| Saydamlık | 0,05–0,10 → `hairline` · 0,12–0,18 → `pressed` · 0,2–0,3 → `soft` · 0,32–0,45 → `disabled` · 0,5–0,7 → `muted` · 0,75–0,9 → `strong` |

### 2.2 Renk rolleri (F73.1)

| Rol | Anlam | Kullanıldığı yerler (tam liste) |
|---|---|---|
| `primary` / `primaryContainer` | **eylem, seçim, oluşturma, odak** | "+" (ana ekran, editör, klasör), seçili çip, imleç, bağlantı, bugünün günü, bölüm adı |
| `secondary` / `secondaryContainer` (sıcak) | **zaman ve dikkat** | sabitli iğne, yıldız, hatırlatıcı çipi, zamanı gelen şeridi, bekleyen yükleme |
| `tertiary` / `tertiaryContainer` | **yapay zekâ kimliği** | ✨ simgesi (`AiIcon`), AI levhasındaki simgeler, AI merkezindeki kahraman kart |
| `error` | **yıkıcı** | Sil, kalıcı sil |
| nötr (`surfaceContainer*`, `onSurfaceVariant`) | geri kalan her şey | etiket hapı, karo zemini, simge kutusu, çubuk, kapsül, rozet zemini |

Renkli notun İÇİNDE kural değişmez: içerik öğeleri `NoteAccent` (var), krom nötr (K-D6).

### 2.3 Ortak bileşenler (F72.4, `lib/core/widgets/sheet_tile.dart` + var olanlar)

| Bileşen | Ölçü | Görünüş |
|---|---|---|
| `SheetHeader` (var; güncellenir) | yükseklik 56; başlık `sheetTitle` solda 16 dp; sağda en çok 2 simge (⚙, ✕) | ✕ varsa TUTAMAK YOK (K-D11) |
| `SectionLabel` (var; güncellenir) | üst 20, alt 8 | `section` rolü; sayı `meta` ile "· 3" |
| `QuickCircle` | daire 48, etiket `meta` 2 satıra kadar, hücre genişliği eşit bölünür | zemin `primaryContainer`, seçiliyse `primary`; satırda en çok 5 |
| `SheetTile.action` | yükseklik 48 (360 dp'den dar ekranda 44), simge 20 solda, etiket `label` tek satır + üç nokta | zeminsiz; basınca `pressed`; 2 sütun (≥ 600 dp: 3) |
| `SheetTile.tile` | yükseklik 56, köşe `m`, simge 20 `primary` solda (DAİRESİZ), etiket `label` | zemin `surfaceContainer`; 2 sütun |
| `SheetTile.hero` | yükseklik 72, köşe `m`, simge 24 üstte, etiket altta ortalı | zemin `primaryContainer`; yalnız en sık 3 tür için tek satır |
| `SheetTile.rich` | en az 64, köşe `m`, simge 24 solda, `rowTitle` + `meta` açıklama (2 satır), sağda › | zemin `surfaceContainer`; ÇERÇEVE YOK |
| `DestructiveRow` | yükseklik 48, köşe `m` | zemin `errorContainer` %50, yazı `error` |
| `DelayedSpinner` | 300 ms sonra 150 ms'de belirir | F78.3 |
| `EmptyState` (var; güncellenir) | simge 32, 72 dp nötr dairede; başlık `rowTitle`; açıklama `body` muted; tek düğme | dikeyde %38'de |
| `AppHaptics` (`lib/core/haptics.dart`) | `tick` · `thud` · `heavy` | F77.2 |

---

## 3. Kararlar (hepsi VERİLDİ — protokol 2)

Biçim: **karar** · eski açık karar · alışkanlığı değiştirir mi.

- **K-D1 Renk rolleri §2.2'deki gibi.** Alışkanlık: hayır (yalnız ton).
- **K-D2 Arayüz kromunda en kalın ağırlık w600.** Hayır.
- **K-D3 Ev düğmesi kalkar; "Tümü" çipi şeridin başında SABİT durur ve ev simgesi taşır.**
  Kullanıcının 2026-11-06 isteği ("klasördeyken her zaman görünen ana sayfaya dön")
  korunur: çip kaymaz, her zaman görünür, dokununca bugünkü ev düğmesinin yaptığını yapar.
  Evet (düğmenin yeri aynı, biçimi çip).
- **K-D4 Takvim şeridi KALIR** (kullanıcı 2026-11-08'de istedi); telefonda 10 gün yerine
  7 gün, gün adı üç harf. OTURTMA **K-O10 kapanır: "bugünkü, sıkılaştırılmış"**. Hayır.
- **K-D5 Kartta işaretsiz madde varken işaretliler tek satır "✓ N tamamlandı".** OTURTMA
  **K-O11 kapanır: önerilen.** Evet (Ayarlar → Kartlar'a `card_show_checked` anahtarı:
  açılırsa bugünkü görünüm).
- **K-D6 Not alt çubuğu:** sol kapsül Biçim · Ekle · **Kalem** · Ara · (☑|Seç); Paylaş ⋮
  menüsünün hızlı satırında (zaten orada). Sağ kapsül ✨ · 🎤; ses kaydı ve AI sesli not
  mikrofona BASILI TUTUNCA açılan küçük menüde. İki kapsül de NÖTR; renkli notta notun
  kendi tonundan. OTURTMA **K-O5 kapanır: önerilen.** Evet (ses dalgası düğmesi
  Kişiselleştir'den geri açılabilir — `UiItem` kimliği silinmez, varsayılanı gizli olur).
- **K-D7 Telefonda not ekranının sol üstünde geri oku.** Evet (eklenir; hiçbir şey kalkmaz).
- **K-D8 Başlık satırındaki "+" kalkar; yerine çip satırının SONUNDA "+ Etiket, hatırlatıcı"
  hayalet çipi** (çip varken yalnız "+"). Evet (aynı menü, yeri değişir; `note-meta-chip`
  anahtarı korunur).
- **K-D9 Sabit ek çubuğu telefonda 5 denetim:** ⛶ · tutamak · birincil iş · ✏ · ⋮.
  OTURTMA **K-O6 kapanır: önerilen** (F65.1 bu planın F75.6'sıdır). Evet.
- **K-D10 Menü levhası: hızlı satır (daire) + 2 sütun satır.** Evet (yalnız görünüş;
  sıra/gizleme kaydı `menu_layout_v1` aynen geçerli).
- **K-D11 ✕ düğmesi olan levhada tutamak çizilmez** (aşağı çekerek kapatma çalışmaya
  devam eder). Hayır.
- **K-D12 Açılış: `androidx.core:core-splashscreen`.** OTURTMA **K-O14 kapanır: önerilen**
  — yalnız cihazda `screenrecord` ile beyaz kare kalmadığı görülürse birleştirilir.
- **K-D13 Ajandada satır sonu çöp düğmesi kalkar; satırı sola kaydır = sil + Geri al;
  uzun bas = menü; fareyle üstüne gelince düğme görünür.** Evet.
- **K-D14 Ana ekranda aşağı kaydırınca başlık yığını yukarı çekilir, yukarı kaydırınca
  döner** — yalnız `Transform`, ölçüm kapılı (F74.7). Ölçüm geçmezse yapılmaz.
- **K-D15 Etiket hapı nötr ton** (renkli notta bugünkü gibi notun tonu). Hayır.
- **K-D16 Tema seçicide 20 aile üç grupta** (Sakin · Kâğıt · Canlı); aile silinmez. Hayır.

Açık kalan (kullanıcıya SORULUR, gözetimsiz yapılmaz): yok. Kullanıcı sabah beğenmediği
kararı numarasıyla söyler; o commit geri alınır.

---

## FAZ 72 — Zemin: belirteçler, mandal, ortak bileşenler [Opus · P33]

**Önce oku:** `lib/app/theme/app_tokens.dart`, `app_theme.dart`, `core/widgets/sheet_header.dart`,
`core/widgets/empty_state.dart`, `core/a11y/min_tap_target.dart`, `test/perf_budget_test.dart`
(mandal kalıbı), `tool/design/token_sayim.py`.

Bu faz **ekranda hiçbir şeyi değiştirmez** (kabul: tur farkı her sahnede < %0,5).

- [ ] **F72.1 Belirteçler.** §2.1'deki sınıflar `app_tokens.dart`'a. `AppMotion.quick/long`.
  `AppTheme._base` içindeki elle yazılmış köşeler (10, 12, 14, 16, 18, 24) `AppRadius`'a
  çevrilir — eşlemeyle ÇAKIŞAN yerde (çip 10 → `m` 12, "+" 18 → `l` 16, giriş alanı 14 →
  `m`) değer değişir; bunlar bu fazın TEK görünür farkıdır, tur farkında beklenir.
- [ ] **F72.2 `AppText`.** §2.1 tablosu; `static AppText of(ThemeData theme)`; her rol bir
  `TextStyle` alanı, `TextTheme`'in en yakın rolünden `copyWith` ile (yazı tipi ailesi
  temadan gelsin). Birim testi: 8 rolün pt/ağırlığı tabloyla aynı; `opposite` temada
  (HAFIZA "TUZAK: ham tema, M3 ölçüleri null") null dönmez.
- [ ] **F72.3 Mandal testi.** `test/design_tokens_guard_test.dart` +
  `test/design_tokens/budget.json`. Test `tool/design/token_sayim.py` ile AYNI desenleri
  Dart'ta sayar (desenler betikte; yorum satırı ve tanım dosyaları hariç). Kural: sayı >
  bütçe → kırmızı ("yeni elle değer ekledin: `AppRadius`/`AppText`/`AppMotion` kullan");
  sayı < bütçe → kırmızı ("bütçeyi şu değere indir") — bütçe yalnız DÜŞER
  (`perf_budget_test` kalıbı). Başlangıç bütçesi (2026-11-12 ölçümü; F72.1'den sonra
  yeniden ölç, o sayıyı yaz):
  `{"radius": 344, "fontSize": 215, "duration": 219, "curve": 95, "iconSize": 509, "alpha": 241, "fontWeight": 226, "haptic": 86}`.
  `ortam_ci.md`'ye tek satır.
- [ ] **F72.4 Ortak bileşenler.** `lib/core/widgets/sheet_tile.dart`: §2.3'teki
  `QuickCircle`, `SheetTile.action/.tile/.hero/.rich`, `DestructiveRow`; ızgara yardımcıları
  `SheetTileGrid(columns:)` (2; ≥ 600 dp 3; hücre genişliği `LayoutBuilder` ile — `Wrap`
  değil, satırlar hizalı kalsın). Hepsi `MinTapTarget` ≥ 48, `Semantics(button, label)`,
  fareyle üstüne gelince `pressed` tonu. `DelayedSpinner` (`core/widgets/`): `initState`'te
  300 ms `Timer`, sonra `AnimatedOpacity` 150 ms; hareket azaltılmışsa doğrudan. Widget
  testleri: her karo 360 dp'de taşmaz; uzun etiket ("Şablon olarak kaydet") tek satırda
  üç noktayla biter, `Tooltip` tam adı verir.
- [ ] **F72.5 `SheetHeader` / `SectionLabel` / `EmptyState` ölçüleri** §2.3'e çekilir
  (bileşenin İÇİ; çağıranlar değişmez). `showAppSheet`: `showDragHandle` verilmemişse ve
  levha `SheetHeader(onClose:)` taşıyorsa tutamak yok (K-D11) — en basit yol: `SheetHeader`
  kullanan çağrılarda `showDragHandle: false` (Grep `SheetHeader(` → çağıran `showAppSheet`).
  *Tuzak:* `accessibility_test` 48 dp; `SegmentedButton`'a `VisualDensity.compact` verme.
- [ ] **F72.6 Göç (mekanik) [Sonnet · P41 — Faz 79'dan sonra].** `python
  tool/design/token_sayim.py radius` dökümü üzerinden, KLASÖR KLASÖR (sıra: `core/widgets`
  → `features/settings` → `features/calendar` → `features/folders` + `inbox` + `friends` +
  `gmail` → `features/ai` → `features/notes/presentation` kök → `editor/` → `viewers/`).
  Her klasör ayrı commit; §2.1 eşleme tablosu dışına ÇIKMA, "daha güzel olur" diye değer
  seçme. Her commit'ten sonra: `dart analyze` + o klasörün testleri + tur farkı (beklenen:
  sahne başına < %2; üstündeyse o dosyayı geri al ve maddeye yaz). Editör (`editor/`,
  `items_editor*`, `text_wrap*`) ve mürekkep (`ink_*`, `pen_*`) dosyalarında YALNIZ köşe ve
  saydamlık; süre/eğriye dokunma (ölçülmüş değerler). Sayı düştükçe `budget.json` iner.
  Hedef: köşe ≤ 40, punto ≤ 30, süre ≤ 60, eğri ≤ 15, ağırlık ≤ 40.
- Kabul: tur farkı beklenenler dışında < %0,5; mandal testi yeşil ve bozma denemesinde
  kırmızı (bir dosyaya `BorderRadius.circular(13)` ekle → kırmızı gör → geri al).

---

## FAZ 73 — Renk rolleri ve sakin tipografi [Opus · P34 · `[apk]`]

**Önce oku:** `app_palette.dart` (başlık yorumu + `FamilyTokens`), `test/theme_contrast_test.dart`,
`test/visual_consistency_test.dart`, `test/note_accent_consistency_test.dart`,
`core/widgets/tag_pill.dart`, `due_banner.dart`.

- [ ] **F73.1 Rol sözleşmesi + bekçi (K-D1, K-D15).** §2.2 tablosu `app_palette.dart`
  başlık yorumuna. Düzeltilecek yerler (her biri için önce tur görüntüsünde bugünkü rengi
  gör):
  1. `due_banner.dart`: `tertiaryContainer/onTertiaryContainer` → `secondaryContainer/
     onSecondaryContainer` (7 satır).
  2. `tag_pill.dart` `tagPillColors` (accent null dalı): zemin `surfaceContainerHigh`, yazı
     `onSurfaceVariant`. Renkli not dalı aynı.
  3. `note_editor_toolbar.dart` `_addToolButton`: rozet zemini `primaryContainer`, simge
     `onPrimaryContainer` (kalın yuvarlak uçlu artı ve rozet biçimi KALIR — kullanıcı
     isteği 2026-10-30).
  4. `folders_screen.dart` "Yeni klasör" düğmesi: `FilledButton.tonal` varsayılan tonu
     (`secondaryContainer` DEĞİL; `primaryContainer`).
  5. Paylaş levhası (Grep `shareSheetExternal\|Dışarı gönder` → levha dosyası) Kopyala /
     PDF / Görsel daireleri: nötr `surfaceContainerHigh`; yalnız ilk (Metni paylaş) `primary`.
  6. Ayarlar kök satırlarının simge kutuları (`settings_screen.dart` `_Area` satırı): hepsi
     `surfaceContainerHigh` + `onSurfaceVariant` (F79.4 ile birlikte de yapılabilir).
  7. `AiIcon` ve AI levhası/merkezi simgeleri: `tertiary`.
  Bekçi `test/color_roles_test.dart`: `lib/` içinde `tertiaryContainer|onTertiaryContainer|
  \.tertiary\b` yalnız `features/ai/`, `AiIcon` dosyası ve tema dosyalarında geçer;
  `secondaryContainer` izin listesi: `due_banner`, hatırlatıcı çipi, iğne/yıldız, bekleyen
  yükleme (liste testte, yeni kullanım eklemek testi güncellemeyi gerektirir).
  *Tuzak:* `theme_contrast_test` her rol çiftini 20 ailede dener — nötr hapta
  `onSurfaceVariant` / `surfaceContainerHigh` oranı ≥ 4,5 mi, test et; tutmayan ailede
  yazı `onSurface`. `balloon_list_theme_fixes_test` vurgu doygunluğu > 0,2 ister.
- [ ] **F73.2 Krom ağırlığı (K-D2).** `python tool/design/token_sayim.py fontWeight`
  dökümü: w700/w800/bold → `AppWeight.strong`. DOKUNMA: `rich_text.dart`, `text_wrap*`,
  `format_bar.dart`'ın "B" düğmesi, `noteTitleStyle`, PDF/Word dışa aktarım, takvimde
  bugünün günü. Tur farkı beklenir (ayarlar, menüler, levhalar).
- [ ] **F73.3 Punto (D20).** `token_sayim.py fontSize` dökümü: (a) 12'nin altındaki 45
  kullanımın her biri — okunan metinse 12, rozet/sayıysa 11; 9–10 pt KALMAZ (istisna:
  takvim ay hücresi çipi F79.2'de ele alınır, orada bırak). (b) Yarım puntolar §2.1
  eşlemesiyle. Editör gövdesi ve kullanıcı yazı boyutu ayarına bağlı hesaplara dokunma
  (`fontScale` ile çarpılan değerler).
- [ ] **F73.4 Tema seçici grupları (K-D16).** `theme_picker.dart` `themeChoiceOptions`:
  sıra ve üç `SectionLabel`: **Sakin** (Sistem, Adaçayı, Porselen, Kil, Lavanta, Zeytin,
  Nane, Şeftali) · **Kâğıt** (Beyaz, Saman, Krem, Klasik, Gazete, Defter, Grafit, Defter-i
  kebir) · **Canlı** (Okyanus, Gül, Mandalina, Zümrüt, Ametist). Alçak levhadaki seçici de
  aynı listeyi kullanıyor (tek kaynak) — orada grup adı yerine 12 dp boşluk yeter.
- Kabul: `telefon-ana.png`, `telefon-ayarlar.png`, `telefon-n4-paylas.png` önce/sonra
  dosyada; bekçiler yeşil; koyu turda aynı sahneler okunur.

---

## FAZ 74 — Ana ekran (telefon önce) [Fable · P35 · A/B · `[apk]`]

**Önce oku:** `dashboard_screen.dart` (başlık yığını; P19 yapıldıysa ayrılmış widget),
`dashboard_widgets.dart` `_SearchField`, `dashboard_shelf.dart`, `folder_tile.dart`
`FolderChip`, `home_calendar_strip.dart`, `due_banner.dart`, `note_card.dart`,
`card_preview.dart`, `docs/hafiza/arayuz.md` ("Klasör şeridi sabit", "Ana ekran jestleri",
"Yana kaydırma akan geçiş"), `docs/hafiza/akicilik.md` (kart önbelleği).
Bekçiler: `folder_strip_chips_test`, `folder_strip_fixed_test`, `card_checked_item_test`,
`perf_budget_test` (S-senaryoları), `accessibility_test`.

Hedef düzen (412 dp; ayrıntı `docs/deneyim/hedef.html` "Ana ekran"):

```
 8  ┌──────────────────────────────────────────────┐
    │ 🔍  Notlarda ara                    (👤)  ⋮ │  arama hapı: 48, köşe pill
    └──────────────────────────────────────────────┘
 8   Per   Cum   Cmt   Paz   Pzt   Sal   Çar     ⌃    takvim şeridi: 44 (7 gün)
     (12)  13    14    15    16    17    18
 8  ┌ ⏰ Toplantı notları · 5 Kas 15:17        ✕ ┐     zamanı gelen: 40, sıcak ton
 8  [🏠 Tümü 16] │ Gelen• · Genel 1 · Dualar · İş →    klasör şeridi: 40; ilk çip SABİT
12   Sabit · 3 ─────────────────────────────────
 8  ┌ kart ┐ ┌ kart ┐
```

- [ ] **F74.1 Arama hapı (D5).** Dinlenme hâli: 🔍 · ipucu · hesap dairesi (32) · ⋮.
  ✨ (anlamsal arama kipi) yalnız alan ODAKLIYKEN ya da metin varken hapın içinde görünür
  — yer hep ayrılı (`Visibility(maintainSize…)` ya da `Offstage` + sabit genişlik; ağaç
  şekli değişmesin). Süz düğmesi haptan çıkar: süzgeç ETKİNKEN klasör şeridinin başına
  (sabit "Tümü"den hemen sonra) "Süz · N ✕" çipi gelir (`appliedFilterLabels` sayısı;
  dokun = `showFilterSheet`, ✕ = `resetFilters`). Süzgece giriş ⋮ → "Görünüm ve süz"
  (var). Hap yüksekliği 50 → 48. 320 dp liste bölmesinde ipucu kesilmeden sığar (OTURTMA
  F67.3'ün "arama hapı kısalır" kısmı bununla kapanır).
  *Tuzak:* hesap + ⋮ hapın İÇİNDE (`_SearchField.trailing`, 2026-11-06) — öyle kalır.
- [ ] **F74.2 Takvim şeridi (D7, K-D4).** `WindowClass.compactDevice` iken 7 gün (bugün
  dahil), hücrede üstte üç harfli gün adı (`DateFormat.E()` — bugün zaten hesaplanıyor,
  `characters.first` kalkar) `badge` rolünde 11 pt, altta gün sayısı 15 pt medium; bugün
  28 dp dolu `primary` dairede; kayıt varsa sayının altında 4 dp nokta (bugünkü kayıt
  gösterimi neyse o, yalnız yer). Toplam yükseklik ≤ 44. Geniş ekranda bugünkü ("Per 12").
  Daralt/aç oku ve `homeCalendarStripOpenProvider` aynen.
- [ ] **F74.3 Zamanı gelen şeridi.** Renk F73.1'de. Yükseklik 40, köşe `m`, metin `label`
  (başlık medium) + `meta` (tarih); ✕ hedefi 48 (görünen simge 18).
- [ ] **F74.4 Klasör şeridi (D4, D6, K-D3).** `dashboard_shelf.dart`: `home-strip-go-home`
  / `home-strip-at-home` `IconButton`'ları kalkar; yerine şeridin başında KAYMAYAN "Tümü"
  çipi (şerit `Row` = [sabit çip, 8 dp, ince dikey ayraç 1×20, `Expanded(kayan çipler)`]).
  Çip: simge `home` (ana sayfadayken dolu, klasördeyken çizgili), ad "Tümü", sayı. Seçili
  (ana sayfa) = `primaryContainer`; klasördeyken nötr. Dokun / uzun bas davranışı bugünkü
  "Tümü" çipininki (F60.S3) + bugünkü ev düğmesinin yaptıkları (`selectedSharedFolder`,
  `sharedHubOnHome` sıfırlama, `_closeOpenNote`, titreşim). Anahtarlar: yeni çip
  `home-strip-all`; eski iki anahtarı arayan testler (`folder_strip_*`, `rail_scope_menu`,
  tur) güncellenir.
  Çip sayıları: simgenin üstündeki rozet KALKAR; sayı adın sağında `meta` rolünde
  ("Genel 1"). Yalnız "Gelen"de okunmamış varsa adın sağında 8 dp `error` nokta + sayı.
  Çip yüksekliği 32, köşe `s`, şerit 40.
  *Tuzak:* şerit ızgaranın DIŞINDA sabit başlık kalmalı (2026-11-07 kök nedeni); seçili
  çip ortalanmaz (`_EnsureVisible`); giriş/çıkışta genişlik sıçramasın — sabit çip her
  durumda aynı genişlikte (sayı hanesi değişimi hariç).
- [ ] **F74.5 Kart sakinleşmesi (D6, K-D5).**
  (a) `card_preview.dart`: işaretsiz madde varsa önce onlar (dilim sınırı aynı), işaretliler
  tek satır "✓ N tamamlandı" (`meta`, `NoteAccent` tonunda). Hepsi işaretliyse: ilk 2
  madde üstü çizili + "✓ Hepsi tamam (N)". Yeni tercih `card_show_checked` (varsayılan
  kapalı; açıkken bugünkü görünüm) Ayarlar → Kartlar'da, `card_show_*` ailesiyle aynı
  kalıpta. P32'nin kuralı (kartta işaretli kutuya dokunmak notu açar) aynen.
  *Tuzak (kasma listesi 1–2):* önizleme hesabı kart önbelleğinin girdisi — yeni tercih
  önbellek anahtarına girsin (`card_show_*` nasıl giriyorsa); `perf_budget_test` yeşil.
  (b) Kart ⋮: düz kartta simge 18, renk `onSurfaceVariant` %60 (`AppAlpha.muted`); görselli
  kartta daire 28 (bugün ~32), zemin siyah %32. Dokunma hedefi 48 KALIR.
  (c) Etiket hapı F73.1. Tarih `meta`.
- [ ] **F74.6 "+" kümesi.** "+" 56, köşe `l` (16), `primary` — ekranın TEK dolu birincil
  öğesi. Mikrofon 48, `surfaceContainerHigh` + `onSurface` (bugün `primaryContainer`),
  aralarında 12. Panel (`_QuickAddPanel`) karoları `SheetTile.tile` / `.hero` (F76.3 ile).
  Davranış aynı (dokun = panel).
- [ ] **F74.7 Kaydırınca çekilen başlık (K-D14) — ÖLÇÜM KAPILI.** Başlık yığını (arama +
  takvim + zamanı gelen + şerit) ızgaranın ÜSTÜNDE `Stack`'te; ızgaranın üst dolgusu =
  başlık yüksekliği (yükseklik `ValueNotifier<double>`'da, başlığın `RenderBox`'ından kare
  sonrası bir kez; değişince ızgara dolgusu TEK ADIMDA güncellenir). Kaydırma
  `NotificationListener<ScrollUpdateNotification>` → `ValueNotifier<double> offset`
  (0…yükseklik, `scrollDelta` ile; yukarı kaydırmada hemen döner) →
  `ValueListenableBuilder` içinde yalnız `Transform.translate`. `setState` YOK, boy
  animasyonu YOK (kasma listesi 3, 6). Tepedeyken (`pixels <= 0`) offset 0. Arama odaklı,
  seçim kipi, klasör çekişi (`_trackFolderPull`) ve yana çekiş (`FolderSwipe`) sırasında
  offset 0'a döner ve kilitlenir. Bölünmüş görünümde (liste bölmesi) aynı.
  Kabul: `ab_liste.py` kaydırma evresinde UI ms ve takılma oranı taban +%20'yi aşmıyor;
  aşarsa bu madde GERİ ALINIR ve maddeye sayı yazılır (diğer maddeler kalır). Yeni bütçe
  senaryosu: kaydırma boyunca `DashboardScreen` kurulumu 0.
- [ ] **F74.8 Boş ana ekran (D23).** Hiç not yokken: `EmptyState` (§2.3) + altında üç
  `SheetTile.hero` (Metin notu · Liste · Sesle yaz) — "+" panelindeki AYNI işler
  (`addCatalog`'dan; yeni iş yok). Tura `TOUR_EMPTY=1` sahnesi (`ana-bos`).
- Kabul: `telefon-ana.png` — ilk kartın üst kenarı (zamanı gelen şeridi yokken) ≤ 176 dp
  (bugün ≈ 185), varken ≤ 224 (bugün 233); ekranda dolu `primary` yüzey yalnız "+" ve
  bugünün günü; `telefon-kucuk-ana.png`'de taşma yok; A/B kapısı geçti (klavye + liste).

---

## FAZ 75 — Not ekranı kromu [Fable · P36 · A/B · `[apk]`]

**Önce oku:** CLAUDE.md "Kasma kontrol listesi" (8 madde — her biri bu fazda geçerli),
`note_editor_screen.dart` (AppBar ~4784, `_listLeading`, `_typingTitle`, çip satırı ~3264),
`note_editor_toolbar.dart`, `editor_bar_layout.dart` (`planEditorBar` + testi),
`editor_quick_row.dart`, `pinned_media_pane.dart` (çubuk), `attachment_actions.dart`,
`docs/hafiza/editor.md`, `docs/hafiza/arayuz.md` ("Not vurgusu", "Okunurluk").
Bekçiler: `keyboard_jank_guard_test`, `perf_budget_test`, `items_editor_row_cache_test`,
`note_accent_consistency_test`, `editor_bar_layout` testi, `accessibility_test`.

- [ ] **F75.1 Geri oku (D9, K-D7).** `_listLeading`: `WindowClass.compactDevice` ve liste
  gizli/çekmece durumu yokken `IconButton(Icons.arrow_back_rounded)` (`note-back`,
  `Navigator.maybePop` — `PopScope` zinciri aynen çalışsın; doğrudan `pop()` YOK). AppBar
  `leadingWidth` 44. Klavye açıkken de yerinde (yuva sabit; kasma listesi 4).
  Kanıt/tur: `TOUR_SIZES=telefon-kucuk TOUR_KEYBOARD=300` — hızlı satır 360 dp'de taşıyorsa
  `EditorQuickRow` en çok 4 öğe gösterir (kalanı zaten ⋮'te).
- [ ] **F75.2 Meta çipi (D9, K-D8).** Başlık satırının sağındaki `actionsMenu` "+" kalkar
  (başlık tam genişliği alır; `_collabMarker` çip satırının başına iner). Çip satırının
  SONUNA `note-meta-chip` anahtarlı hayalet çip: satır boşken "+ Etiket, hatırlatıcı"
  (`label`, `onSurfaceVariant`, 1 dp `hairline` çerçeve, yükseklik 32), doluyken yalnız
  "+" (32×32). Başlık üretilirken (`_titleGeneratingN`) çipin içinde 14 dp halka (bugünkü
  mantık). Renkli notta `NoteAccent`.
  *Tuzak:* başlık sığdırma ölçümü (`title_fit.dart`, `fieldMergedStyle`) başlığın
  kullanılabilir genişliğine bakıyor — "+" kalkınca genişlik değişir, ölçüme verilen
  genişliği güncelle (test: uzun başlık çipin altına taşmaz).
- [ ] **F75.3 Alt çubuk düzeni (D8, K-D6).**
  (a) Sol kapsül sırası: Biçim · Ekle · Kalem · Ara · (☑|Seç). Kalem = hızlı satırdaki
  kalem düğmesinin yaptığı (`penToggle`; OTURTMA F63.5 bu maddeyle kapanır). Paylaş
  kapsülden çıkar (⋮ hızlı satırında var; `planEditorBar`'ın "önce Paylaş'ı düşür" adımı
  gereksizleşir → "önce Ara'yı düşür" kalır). Belge notundaki ayrı kalem düğmesi
  (`_penWidth`) bu segmentle birleşir.
  (b) Sağ kapsül: ✨ · 🎤. Mikrofon dokun = bugünkü dikte; BASILI TUT = küçük açılır menü
  (≤ 4 madde → `ActionMenu` açılır biçimi, F38.6): Yazdır · Ses kaydı · AI sesli not ·
  Sesli komut (hangileri bugün varsa; simgeler `AppIcons.dictation/voiceRecord/aiVoiceNote/
  voiceCommand`). Ses dalgası segmentinin `UiItem` kimliği SİLİNMEZ; varsayılanı gizli
  olur (`Personalize`'da "kullanıcı hiç dokunmadıysa gizli" — kullanıcı açıkça göster
  dediyse görünür). Bir kez ipucu (`TipOnce`): "Ses kaydı için mikrofona basılı tut".
  (c) Ölçü: `kEditorBarSegment` 40 → 44; segment `MinTapTarget` ile dikeyde 48; simge 22.
  `planEditorBar` testine 360 / 393 / 412 dp satırları: 360'ta Ara düşer, başka taşma yok.
  (d) Bu madde çubuğun YÜKSEKLİĞİNİ değiştirirse (48 dp hedef için) değişim sabittir,
  animasyon yok; `KeyboardInsetScope` (P23) hesabındaki çubuk yüksekliği sabitini güncelle.
- [ ] **F75.4 Alt çubuk rengi (D8, K-D6).** İki kapsül de nötr:
  - renksiz not: sol `surfaceContainer` + 1 dp `outlineVariant`; sağ `surfaceContainerHigh`
    çerçevesiz. Simgeler `onSurface`; ✨ `tertiary`; "+" rozeti F73.1.
  - renkli not (`NoteAccent` dolu): kapsül zemini `Color.alphaBlend(noteInk %8, sayfa
    rengi)`, sağ kapsül `noteInk %14`; çerçeve `noteInk %12`; simgeler `noteInk`; etkin
    segment `noteInk %18`. ✨ de `noteInk` (renkli notta tek ton).
  Renkler `_themeOf(context)` ve var olan `NoteAccent`/`noteInk`'ten; yeni sağlayıcı yok.
  Kanıt: `telefon-n1.png` (mor not) ve `telefon-n4.png` (sarı not) — çubukta petrol kalmaz.
  *Tuzak:* çubuk `ItemsEditor` dışında, satır önbelleğine girmez; ama renk nesnesini her
  build'de yeniden üretip alt ağaca "yeni girdi" diye verme (hesabı `_editorInk` gibi
  önbelleğe bağla).
- [ ] **F75.5 Üst çubuk.** Simgeler 24 (`AppIconSize.l`), hedef 48; bulut durumu 20,
  `onSurfaceVariant %60`; iğne sabitliyken dolu `secondary`, değilken çizgili
  `onSurfaceVariant`. Tarih `meta`. Durum değişiminde simge `AnimatedSwitcher` 150 ms
  solma (boy yok).
- [ ] **F75.6 Sabit ek çubuğu (D10, K-D9; OTURTMA F65.1).** `< 600 dp` genişlikte çubuk:
  ⛶ · tutamak · birincil iş (PDF/video "Not al", görsel "T") · ✏ · ⋮. ⋮ levhasının
  BAŞINDA görünüm anahtarı (Sabit · Yüzen · Ek — anahtar olarak, eşanlamlı menü maddesi
  yok; TUTARLILIK K6), altında `attachmentActionsFor` sırası (balon, bağlantı, yer imi,
  döndür, paylaş…). ≥ 600 dp bugünkü geniş çubuk. Kabul (OTURTMA Faz 65): telefonda sabit
  ekli notta toplam görünür denetim ≤ 14 (5 + üst 4 + alt 7 = 16 → üst çubukta "+" F75.2
  ile kalktığı için 15; hedefi tutturmak için belge notunda üstteki "+" de çip satırına
  iner).
- Kabul: tur `telefon-n1/n2/n4/e-pdf-sabit` önce/sonra; `telefon-kucuk` + klavye taşmasız;
  A/B `ab_klavye.py` (klavye aç/kapa, yazma, not kapanışı) hiçbir evrede +%20 yok;
  `perf_budget_test` yeşil; mor ve sarı notta çubukta tema vurgusu yok.

---

## FAZ 76 — Levhalar ve menüler tek dil [Opus · P37 · `[apk]`]

**Önce oku:** `core/widgets/action_menu_sheet.dart`, `core/menu_layout.dart`,
`notes/presentation/add_catalog.dart` (`AddTile`, `AddTileGrid`), `quick_add_fab.dart`
(`_QuickAddPanel`), `editor/attach_sheet.dart`, paylaş levhası, not içi AI levhası
(Grep `Bugünkü puan`), `test/note_menu_model_test.dart`, `test/undo_over_sheet_test.dart`.

- [ ] **F76.1 `ActionMenu` düzeni (D11, K-D10).** Levha biçimi: `SheetHeader` (başlık + ⚙
  + ✕; tutamak yok) → hızlı satır `QuickCircle` ×≤5 → gruplar: `SectionLabel` +
  `SheetTileGrid` içinde `SheetTile.action` (2 sütun; ≥ 600 dp 3) → `DestructiveRow`.
  Alttaki "Ekranı düzenle" ve "Ayarlar" bağlantıları kalkar; ⚙ küçük açılır menü olur:
  Menüyü düzenle · Ekranı düzenle · Ayarlar. Düzen kipi (sürükle/gizle/yıldız,
  `menu_layout_v1`) davranışı aynı; yalnız satır görünümü yeni karo. 2 işten az kalan grup
  bir öncekiyle birleşmez (katalog sırası `noteMenuModel`'de) — ama `noteMenuModel`'de
  "Kopyala" (2 iş) ve "Araçlar" (3 iş) grupları TEK "Araçlar" grubu olur.
  Açılır menü biçimi (≤ 4 madde) değişmez.
  Kabul: `telefon-n4-menu.png` levha yüksekliği ≤ ekranın %62'si (bugün ≈ %85);
  `telefon-kucuk-n4-menu.png`'de "Sil"e ≤ 100 dp kaydırmayla ulaşılır; `note_menu_model_test`
  yeşil; 360 dp'de hiçbir etiket iki satıra düşmez.
- [ ] **F76.2 Ekle levhası + "+" paneli (D12).** `AddTile` → `SheetTile.tile`; yalnız en
  üst/alt "tür" satırı (Metin · Liste · …) `SheetTile.hero`. Karonun içindeki daireli
  simge kalkar (simge doğrudan, `primary`). Tek öğeli grup tam genişlik OLMAZ: 2 sütunluk
  ızgarada tek karo (sağı boş) — bütün karolar aynı genişlikte. İki yüzey de `addCatalog`'u
  okumaya devam eder; düzen kipi (F60.S10) aynen.
  *Tuzak:* `UiItem.quickAdd/attach` kimlikleri ve `quickAddMenuId` değişmez.
- [ ] **F76.3 AI levhası ve Paylaş levhası (D12).** AI: çerçeveli kartlar →
  `SheetTile.rich` (AI sesli not, Sohbet) + "Bu not" işleri 2 sütun `SheetTile.tile`
  (açıklama satırı kalkar, `Tooltip`'e iner; ilk kullanımda anlaşılırlık için işin ADI
  yeter: Düzelt · Özetle · Analiz et · Çevir · Geliştir). Puan çubuğu `meta` + 4 dp çubuk.
  Paylaş: üst sıra `QuickCircle` (F73.1 renkleri); "Ayarlı PDF / Word", "Not paketi",
  "Arkadaşa gönder", "Birlikte düzenle" → `SheetTile.rich`.
- [ ] **F76.4 Kalan levhalar.** `showAppSheet` çağıran 85 yerin dökümü (Grep): her biri
  §2.3 anatomisine uyuyor mu (başlık bileşeni, bölüm adı, karo türü, alt güvenli alan)
  — uymayanlar tek tek çevrilir; kalem tepsisi, biçim çubuğu, takvim etkinlik editörü
  KAPSAM DIŞI (kendi düzenleri var). Döküm `docs/deneyim/levhalar.md` (ad · dosya · durum).
- [ ] **F76.5 Onay pencereleri.** `showDialog` 57 yer: başlık `sheetTitle`, gövde `body`,
  düğmeler sağda; yıkıcı onay düğmesi `FilledButton` + `error` tonu, vazgeç `TextButton`;
  köşe `xl`. Tek yardımcı `showConfirmDialog` varsa ona, yoksa `core/widgets/`'e yazılır ve
  elle kurulan onaylar ona çevrilir. *Tuzak:* profil levhasına `FilledButton` koyma
  (HAFIZA: test onay kutusunu `find.byType(FilledButton)` ile bulur).
- Kabul: dört levhanın turu (`n4-menu`, `n4-ekle`, `n4-ai`, `n4-paylas`, `ana-hizli`,
  `ana-kart-menu`) yan yana konduğunda başlık, bölüm adı ve karo aynı; tutamak + ✕ birlikte
  hiçbir levhada yok.

---

## FAZ 77 — Hareket ve dokunsal dil [Opus · P38 · A/B · `[apk]`]

**Önce oku:** `app_tokens.dart` `AppMotion`, `core/a11y/motion.dart`, `core/widgets/`
(`press_scale`, `pop_in`, `scale_settle`, `color_fade`, `expand_reveal`,
`hold_progress_ring`, `app_sheet`, `smooth_routes`), `app/note_open_route.dart`,
`docs/hafiza/akicilik.md`.

Hareket tablosu (bundan başka süre/eğri yazılmaz):

| İş | Süre | Eğri | Not |
|---|---|---|---|
| Basma tepkisi (kart, karo, çip) | `instant` 100 | `standard` | ölçek 0,98 (kart) / 0,97 (çip, karo) |
| Durum değişimi (kutucuk, iğne, çip seçimi, sayı) | `quick` 150 | `standard` | |
| Belirme / açılma (ipucu, çip ekleme, satır açılması) | `short` 200 | `enter` | çıkış 150 `exit` |
| Levha, menü | `medium` 300 / 200 | `enter` / `exit` | var |
| Tam ekran medya | 320 / 240 | `enter` / `exit` | var (`MediaRoute`) |
| Sayfa (not açılışı, yan kayma) | 420 / 360 | var olan | DOKUNMA (ölçülü) |
| Sıralı giriş | öğe başı 30 ms, en çok 6 öğe | `enter` | fazlası birlikte gelir |

- [ ] **F77.1 Süre/eğri göçü (D13).** F72.6'nın hareket kısmı burada, ÖLÇÜMLE: `core/`,
  `settings/`, `calendar/`, `folders/`, `ai/`, ana ekran widget'ları. `editor/`, `viewers/`,
  `keyboard_snap.dart`, `note_open_route.dart`, `FolderSwipe`, `PinchColumns` KAPSAM DIŞI
  (değerleri cihazda ayarlanmış). `elasticOut` → `enter`. `easeOutBack` yalnız `PopIn` ve
  onay "pop"larında (taşma ≤ %5).
- [ ] **F77.2 `AppHaptics` (D13).** `lib/core/haptics.dart`:
  `tick()` = `selectionClick` (seçim, çip, anahtar, eşik geçişi, kaydırıcı adımı) ·
  `thud()` = `lightImpact` (iş TAMAMLANDI: madde işaretlendi, not sabitlendi, kart bırakıldı,
  hatırlatıcı kuruldu) · `heavy()` = `mediumImpact` (uzun basışla tutma, yıkıcı iş onayı,
  çöpe atma). 86 doğrudan çağrı buna çevrilir (bugünkü `selectionClick`'lerden "iş
  tamamlandı" olanlar `thud`'a). Mandal: `haptic` bütçesi → `haptics.dart` dışı 0.
  Eksik denetimi (varsa ekleme, yoksa ekle): madde işaretleme · sabitle/yıldızla · kart
  sürüklemeyi tutma/bırakma · çöpe atma · hatırlatıcı kaydet · yana çekişte eşik · klasör
  çekişinde eşik · kalem/silgi geçişi (kalem yolunda titreşim SENKRON çağrılmaz —
  `unawaited`).
- [ ] **F77.3 Eksik mikro-etkileşimler** (önce var mı bak; varsa dokunma):
  1. İğne/yıldız: dokununca `ScaleSettle` 1 → 1,15 → 1 (`quick`) + renk `ColorFade`.
  2. Çip ve karolar: `PressScale(scale: 0.97)`.
  3. Sayı rozetleri ve "✓ N tamamlandı": sayı değişince `AnimatedSwitcher` (`quick`, 6 dp
     dikey kayma + solma). Kart İÇİNDE YOK (kart önbelleği; ızgarada animasyon başlatma).
  4. Bulut durumu ve iğne: F75.5.
  5. "+" paneli: düğmenin köşesinden ölçek 0,92 → 1 + solma (`short`, `enter`); kapanış 150.
  6. Çöpe/arşive giden kart: `quick` solma + 0,96 ölçek, sonra liste yerleşir (P30'un
     efektiyle çakışıyorsa P30 geçerli).
  7. Bildirim şeridi (`showMessage`): alttan 8 dp kayarak + solma (`short`).
  *Yapma:* satır/kart boyunu animasyonla değiştirme; liste yeniden dizilişini canlandırma;
  parlaklık/ışıltı efektleri; sayfa geçişine paralaks ekleme.
- [ ] **F77.4 Hareketi azalt.** Yeni her hareket `AppMotion.of/curveOf`'tan geçer; test:
  `MediaQuery(disableAnimations: true)` altında yeni bileşenlerde süre ≤ 150.
- Kabul: A/B (klavye + liste) regresyon yok; mandalda süre ≤ 90, eğri ≤ 30, titreşim 0;
  cihazda elle: işaretle, sabitle, sürükle-bırak, çöpe at — her birinde TEK ve farklı
  titreşim (cihaz turu adımı `docs/cihaz_turu.md`'ye eklenir).

---

## FAZ 78 — Hız hissi [Fable · P39 · cihaz · `[apk]`]

**Önce oku:** `docs/hafiza/akicilik.md`, `tool/perf/README.md`, `prof_cold.py`, `prof_oc.py`,
`android/app/src/main/res/` (`launch_bg`, `styles.xml`), `MainActivity`, `quick_add_actions.dart`,
`pinned_media_pane.dart` (yükleme hâli), `note_card.dart` (görsel yer tutucusu).

- [ ] **F78.1 Beyaz açılış (D14, K-D12).** `androidx.core:core-splashscreen`:
  `Theme.App.Starting` (`windowSplashScreenBackground` = Adaçayı zemini `#EAF0EB`, koyu
  `values-night` karşılığı; simge uygulama simgesi), `postSplashScreenTheme` = bugünkü
  `NormalTheme`; `MainActivity.onCreate`'te `installSplashScreen()` +
  `setKeepOnScreenCondition { !ilkKareGeldi }` (ilk Flutter karesi: `FlutterView`
  `addOnFirstFrameRenderedListener` ya da eşdeğeri). Kullanıcının seçtiği tema ailesi
  açılışta bilinmez — zemin rengi son açılışta `SharedPreferences`'a yazılan temaya göre
  SEÇİLEMEZ (tema XML'i sabit); Adaçayı zemini kalır, bilinçli.
  Kanıt (önce/sonra): `adb shell screenrecord` + ffmpeg ile kare kare — beyaz kare sayısı
  (HAFIZA: aynı saniyede `screencap` yanıltır). Beyaz kare kalıyorsa GERİ AL, maddeye yaz.
  *Tuzak:* `FlutterFragmentActivity`; kişisel/olcum iki uygulama kimliği; `USE_FULL_SCREEN_
  INTENT` yalnız `src/kisisel`. Ölçüm uygulaması `dev.kaimau.notlar.olcum`.
- [ ] **F78.2 "Yeni not" süresi.** Yeni ölçüm `tool/perf/prof_new.py`: "+" dokunuşu →
  "Metin notu" dokunuşu → editörün ilk karesi ve klavye görünür (`dumpsys input_method`
  `mInputShown`) arası. 5 koşu ortanca. Hedef ≤ 450 ms (ikinci dokunuştan). Üstündeyse kök
  neden (rota kurulumu mu, ilk kayıt mı, odak isteği mi — `perf.py` izinden) ve düzeltme;
  hedefin altındaysa yalnız sayı yazılır, kod yok.
- [ ] **F78.3 Yükleme hâlleri (D15).** (a) `DelayedSpinner`: içerik alanındaki halkalar
  (liste, levha gövdesi, önizleme kutusu) buna çevrilir; DÜĞME içi halkalar ve "kaydediliyor"
  göstergeleri kalır. Döküm: `CircularProgressIndicator` 74 yer → `docs/deneyim/yukleme.md`
  (dosya · tür · karar). (b) Sabit/gömülü PDF ve video bölmesi yüklenirken: gri kutu yerine
  ekin `thumbUrl`/yerel küçük resmi (F65.5 ile var) `BoxFit.cover` + %24 siyah perde +
  `DelayedSpinner`; küçük resim yoksa `surfaceContainer` + tür simgesi. (c) Kart ve
  görüntüleyicide görseller 150 ms solarak gelir (`frameBuilder`; ilk karede zaten
  hazırsa solma yok); yer tutucu görselin EN/BOY oranında (kart boyu sonradan değişmez —
  test: görsel gelmeden ve geldikten sonra kart yüksekliği aynı).
- [ ] **F78.4 Dokunuş tepkisi denetimi.** `GestureDetector(onTap:` 88 yer: görünür basma
  tepkisi (mürekkep dalgası, `PressScale` ya da ton) olmayanların dökümü; kullanıcının sık
  dokunduğu yüzeyler (kart altı öğeler, çipler, şerit hücreleri, karo, satır) düzeltilir.
  Jest alanları (kalem yüzeyi, ayraç, sürükleme tutamağı) kapsam dışı.
- [ ] **F78.5 İyimser işlemler.** Sabitle, yıldızla, arşivle, çöpe at, madde işaretle,
  klasöre taşı: arayüz ağ beklemeden aynı karede değişiyor mu — yavaş sahte depoyla
  (`Future.delayed(2 sn)`) widget testi; bekleyen varsa kök neden + düzeltme.
- Kabul: cihazda soğuk açılışta beyaz kare 0; `prof_new.py` sayısı dosyada; sabit PDF
  turunda gri kutu yok; A/B regresyon yok.

---

## FAZ 79 — İkincil ekranlar [Opus · P40 · `[apk]`]

**Önce oku:** `calendar_screen.dart`, `calendar_views.dart`, `month_grid.dart`,
`calendar_entry_delete.dart`, `settings_screen.dart` (`_settingsGroups`),
`settings_sections/settings_account.dart` (`_ProfileCard`), `folders_screen.dart`,
`folder_tile.dart`, `trash_screen.dart`, `archive_screen.dart`, `inbox_screen.dart`,
`ai_hub_screen.dart`, `docs/hafiza/takvim_gmail.md`.

- [ ] **F79.1 Ajanda satırı (D16, K-D13).** Tek satır bileşeni, tür ne olursa olsun: sol 4
  dp renk şeridi · (görevde kutucuk / hatırlatıcıda ⏰ / etkinlikte boş 0 dp) · başlık
  `rowTitle` · altında `meta` (saat aralığı · tür) · sağda durum simgeleri (🔔 ↻) 18 dp
  `onSurfaceVariant`. Yükseklik: tek satırlıda 56, iki satırlıda 64. `QuickDeleteButton`
  dokunmatikte çizilmez; satır `Dismissible` (sola, `error` zemin + çöp simgesi, eşik %40)
  → `quickDeleteEntry` + `showUndoSnackBar`; uzun bas = var olan menü; `touchFirst ==
  false` iken (web/fare) üstüne gelince sağda çöp düğmesi belirir. Bir kez ipucu
  (`TipOnce`): "Silmek için sola kaydır".
  *Tuzak:* ajanda levhadan açıldığında Geri al şeridi (`undo_over_sheet_test`); rutin
  girdisi silinmez (`RoutineEntry` dalı).
- [ ] **F79.2 Ay görünümü (D17).** Gün hücresi: çerçeveli kart yerine düz hücre, hücreler
  arası 1 dp `hairline` çizgi (`CustomPaint` tek katman ya da hücre kenarı — 42 ayrı
  `DecoratedBox` + köşe kırpması YOK); hafta sonu sütunu `surfaceContainer` %50; ay dışı
  günler `disabled`. Bugün: sayı 24 dp dolu `primary` dairede (hücre çerçevesi yok).
  Telefonda etkinlik çipi TEK satır 11 pt (`badge`), üç noktalı; hücrede en çok 3 + "+N".
  Geniş ekranda bugünkü çok satırlı çip.
- [ ] **F79.3 Takvim başlığı tek biçim (D17).** Her görünümde: "Kasım 2026 ▾" (dokun = ay
  seçici) · sağda "Bugün" (metin düğmesi; bugün görünürken soluk) · görünüm değiştirici ·
  ⋮. Ay görünümünde ‹ › okları yalnız ≥ 600 dp; telefonda yana kaydırma (var).
- [ ] **F79.4 Ayarlar (D18).** Kök: simge kutuları nötr (F73.1-6), 40 dp, köşe `m`; satır
  başlığı `rowTitle`, alt yazı `meta`, satır 64; "Kullanım kılavuzu" ve "Kişiselleştir"
  kartları AYNI nötr kart (iki farklı ton kalkar), yan yana 2 sütun `SheetTile.tile`.
  `_ProfileCard` misafirde: "Misafir · Yalnız bu cihazda" + "Giriş yap" düğmesi (var olan
  giriş akışı); girişliyken ad + e-posta + senkron durumu. Alt sayfalarda başlık
  `screenTitle`, geri oku her zaman.
- [ ] **F79.5 Klasörler (D19).** Üstteki "Yeni klasör" düğmesi kalır (F73.1-4 tonu);
  ızgaradaki "Yeni klasör" karosu KALKAR. Klasör kartı: boşken 72 dp (simge + ad + "Boş"),
  doluyken bugünkü 128 dp (2 önizleme). Sıralama simgesine `Tooltip` + etiket ("Sırala").
- [ ] **F79.6 Çöp / Arşiv / Gelen (D19).** Üst çubuk: Ara + ⋮ (Analiz, Geçmiş, Çöpü boşalt
  ⋮'e; "Çöpü boşalt" `error` renkli). Çöp kartının altı: iki etiketli metin düğmesi
  "Geri al" · "Sil" (`error`), simge yalnız etiketle birlikte. Açıklama satırı `meta`.
- [ ] **F79.7 AI merkezi.** Kahraman kart yüksekliği ≤ 120 (bugün ~160): tek satır başlık +
  sağında puan halkası; araç satırları `SheetTile.rich` (simge kutuları `tertiary`
  tonunda TEK renk — bugün sarı/yeşil/mavi karışık).
- [ ] **F79.8 Boş hâller (D23).** `EmptyState` 27 kullanım: hepsi §2.3 ölçüsünde (bileşen
  F72.5'te güncellendi); metinler tek kalıp — başlık "Burada … yok", açıklama bir cümle ne
  işe yaradığı, düğme bir sonraki adım (`terminology_test`). Tura `TOUR_EMPTY=1`: boş ana
  ekran, boş klasör, boş arşiv, boş çöp, boş Gelen, boş arama sonucu, boş takvim günü.
- Kabul: `takvim-telefon-agenda/month`, `telefon-ayarlar`, `telefon-klasorler`,
  `telefon-cop`, `telefon-yapay-zeka` önce/sonra; ajandada görünür çöp simgesi 0; boş hâl
  turu 7 sahne.

---

## FAZ 80 — Koyu tema, küçük ekran, web cilası, kapanış [Sonnet döküm + Opus düzeltme · P42 · `[apk]`]

- [ ] **F80.1 Koyu tema turu (D24).** `TOUR_DARK=1` 3 boyutta (telefon, matepad-yatay,
  masaustu). Her sahne için dökülecekler: (a) kart ile zemin ayrışıyor mu (kart zeminden
  AÇIK olmalı), (b) nötr kapsül/karo/hap zeminden ayırt ediliyor mu, (c) renkli notlarda
  yazı ve krom okunuyor mu, (d) perde (levha arkası) yeterince koyu mu, (e) `error` ve
  `secondary` tonları parlamıyor mu. Bu incelemede görülenler aşağıda "Koyu tema ilk
  bulgular"da; döküm `docs/deneyim/koyu.md`, düzeltmeler palet değerinde (bileşende değil).
- [ ] **F80.2 Küçük ekran + büyük yazı.** `TOUR_SIZES=telefon-kucuk` + yazı ölçeği 1,3
  (`fontScaleProvider` — tura `TOUR_FONT=1.3` eklenir): taşan/kesilen her yer madde olur ve
  düzeltilir (OTURTMA F66.4 ile birleşir).
- [ ] **F80.3 Web / masaüstü.** (a) D22: bölüm çizgisi ızgara genişliğinde bitsin
  (`kSectionHeaderMaxWidth` yerine ızgaranın içerik genişliği) ya da ≥ 840 dp'de çizgi
  çizilmesin — hangisi turda temiz duruyorsa. (b) Fareyle üstüne gelme: kart (1 dp
  `outline` çerçeve + imleç), karo, satır, çip — yalnız `touchFirst == false`. (c) Odak
  halkası: klavyeyle gezinirken 2 dp `primary` halka, her tıklanabilir öğede (Tab ile ana
  ekran → not → menü turu). (d) OTURTMA F67.7 (kısayol levhası, sağ tık) buraya bağlanır.
- [ ] **F80.4 Dokunma hedefi taraması.** `accessibility_test` kalıbıyla: ana ekran, not
  ekranı (klavyeli/klavyesiz), menü, Ekle, takvim, ayarlar — 48 dp altı hedef 0 (istisna
  listesi testte, gerekçeli).
- [ ] **F80.5 Kapanış.** `docs/deneyim/once-sonra.md`: 12 ana sahnenin önce/sonra görüntü
  adları + ölçülen sayılar (ilk kart konumu, menü yüksekliği, mandal bütçeleri, A/B
  tabloları, `prof_new.py`, beyaz kare). `docs/cihaz_turu.md`'ye bu planın elle bakılacak
  adımları (titreşimler, geri oku, mikrofon uzun bas, ajanda kaydırma, açılış). HAFIZA
  `arayuz.md`: §2 sözleşmesinin özeti ("Tasarım dili") + bu dosyaya bağlantı; CLAUDE.md'ye
  tek paragraf "Yeni arayüz yazarken". Durum tablosu.

### Koyu tema ilk bulgular (bu incelemede, `build/tour-koyu/`)

Dosya adları `telefon-<sahne>-koyu.png`. F80.1 bunlardan başlar, kalanını döker:

1. **İki parlak yüzey gözü çekiyor** (`telefon-ana-koyu.png`): koyu temada `primary` açık
   nane olduğu için 56 dp ev düğmesi ile "+" ekranın en parlak iki şeyi. K-D3 (F74.4)
   birini kaldırır; "+" kalır.
2. **Koyu renkli not kartı zeminde kayboluyor** (aynı görüntü, sol üst mor kart): kartı
   zeminden ayıran yalnız 1 dp çizgi. Renkli kartın kenar çizgisi koyu temada `noteInk`
   %16 olsun (bugünkü çizgi tonunu Grep `hairline` ile `note_card.dart`'ta bul; renksiz
   kart değişmez).
3. **PDF önizlemesi koyu ekranda bembeyaz** (aynı görüntü, sağ alt kart): koyu temada
   belge önizlemesinin üstüne %8 siyah perde (yalnız kart önizlemesi; açık belgenin kendisi
   değil). Görsel kartlarına dokunma.
4. **"Sil" satırı dolu koyu kırmızı blok** (`telefon-n4-menu-koyu.png`): `DestructiveRow`
   (§2.3) `errorContainer` %50 + `error` yazı ile hafifler.
5. **Kart–zemin ayrımı sınırda** (ölç): Adaçayı koyuda `card` ile `ground` arasındaki
   OKLCH L farkı < 0,04 ise `card` bir kademe açılır; `theme_contrast_test`'e "kart zeminden
   en az 0,04 L açık" satırı (20 aile × koyu). Ölçmeden değer değiştirme.
6. Not ekranı (`telefon-n2-koyu.png`) temiz; alt çubuk bulguları açık temayla aynı (F75).

---

## Yapılmayacaklar (alt modele not)

- Yeni özellik, yeni ekran, yeni ayar sayfası. (İzinli yeni tercihler: `card_show_checked`,
  ses dalgası düğmesinin varsayılanı.)
- Yeni paket. İzinli tek yerel bağımlılık: `core-splashscreen` (K-D12).
- Bulanıklık (`BackdropFilter`), yumuşak/bulanık gölge, gradyan zemin, ışıltı, paralaks,
  zıplayan eğri. Kart gölgesi bugünkü bulanıksız 1 dp kalır (AKICILIK K7).
- Boy animasyonu (`AnimatedSize`/`AnimatedContainer` yüksekliği) — hiçbir yerde, özellikle
  editör sütununda ve ana ekran başlığında.
- Not başlığı/gövdesi stilini, kalem tepsisini, biçim çubuğunu, sayfa geçiş sürelerini
  değiştirmek.
- 20 tema ailesinden herhangi birini silmek ya da renklerini "iyileştirmek" (F80.1'deki
  kanıtlı koyu tema düzeltmeleri hariç).
- `UiItem`, `menuId`, `ValueKey` kimliklerini değiştirmek (kalıcı kayıt ve test anahtarı).
  İstisna bu dosyada adı geçenler.
- `dart format lib`, tam test takımını yerelde koşmak, CI kırmızıyken birleştirmek,
  ölçmeden "akıcı" yazmak.

---

## Ek A — Kabul ölçütleri (plan bittiğinde hepsi doğru)

| Ölçüt | Bugün | Hedef | Nasıl ölçülür |
|---|---|---|---|
| Köşe değeri (elle) | 344 / 28 farklı | ≤ 40 | `token_sayim.py` |
| Punto (elle) | 215 / 19 farklı | ≤ 30 | aynı |
| Süre (elle) | 219 / 39 farklı | ≤ 60 | aynı |
| Krom kalınlığı w700+ | 116 | ≤ 10 (içerik biçimleri) | aynı |
| 12 pt altı okunan metin | 45 aday | 0 | F73.3 dökümü |
| Ana ekranda dolu birincil yüzey | 3 (ev, +, bugün) | 2 (+, bugün) | tur |
| İlk kart üst kenarı (412×915, şeritsiz) | ≈ 185 dp | ≤ 176 dp; kaydırınca 0 | tur |
| Not alt çubuğu denetim | 8, hedef 40 dp | 7, hedef 48 dp | tur + `accessibility_test` |
| Sabit ek çubuğu (telefon) | 10 | 5 | tur |
| Not menüsü yüksekliği (412×915) | ≈ %85 | ≤ %62 | tur |
| Levha karo dili | 4 | 1 (4 çeşit karo, tek bileşen) | tur |
| Ajandada görünür çöp düğmesi | satır başına 1 | 0 | tur |
| Soğuk açılışta beyaz kare | ~0,6 sn | 0 | `screenrecord` |
| Yeni not (2. dokunuş → imleç) | ölçülmedi | ≤ 450 ms | `prof_new.py` |
| A/B (klavye, yazma, kapanış, liste) | taban | hiçbir evre > +%20 | `ab_klavye.py`, `ab_liste.py` |
| Taşma (9 boyut × açık/koyu) | 0 istisna | 0 | tur |

## Ek B — Paket → madde eşlemesi (OTOMASYON kuyruğu)

| No | Paket | Model | Maddeler | Cihaz | APK |
|---|---|---|---|---|---|
| P33 | Tasarım zemini: belirteç, mandal, ortak bileşen | opus | F72.1–F72.5 | | |
| P34 | Renk rolleri + sakin tipografi | opus | F73.1–F73.4 | | evet |
| P35 | Ana ekran (telefon önce) | fable | F74.1–F74.8 | A/B | evet |
| P36 | Not ekranı kromu | fable | F75.1–F75.6 | A/B | evet |
| P37 | Levha ve menüler tek dil | opus | F76.1–F76.5 | | evet |
| P38 | Hareket ve dokunsal dil | opus | F77.1–F77.4 | A/B | evet |
| P39 | Hız hissi | fable | F78.1–F78.5 | cihaz | evet |
| P40 | İkincil ekranlar | opus | F79.1–F79.8 | | evet |
| P41 | Belirteç göçü (mekanik) | sonnet | F72.6 | | |
| P42 | Koyu tema, küçük ekran, web, kapanış | sonnet + opus | F80.1–F80.5 | | evet |

Bu planla KAPANAN OTURTMA maddeleri (yapınca orada da `[x]` + "→ DENEYIM F7x.y"):
K-O5, K-O6, K-O10, K-O11, K-O14 · F63.5 (alt çubukta kalem) · F65.1 · F66.1 · F66.2 ·
F66.3 · F60.7 · F67.3'ün arama hapı kısmı. P18 ve P22 bu maddeleri ATLAR.

## Ek C — Tuzaklar (HAFIZA'dan, bu planın dokunduğu yerler)

- Editör ve kart dosyalarında `Theme.of(context)` yazma → `_themeOf` / `_cardInk`
  (dış temayı okur, renkli notta yazı okunmaz olur).
- `ItemsEditor` satır önbelleği: satırı değiştiren girdi anahtara, liste girdisi env'e;
  env'e her build'de yeni nesne koyma. Bu planın hiçbir maddesi satıra yeni alan eklemez.
- Editörün kök `setState`'i yok; yerel durum `ValueNotifier` + dar dinleyici.
- `KeyboardSwitch` alt ağacı sökmez (`Offstage`); `MediaQuery.of(context)` kök bağlamda
  okunmaz (`viewInsetsOf` / `sizeOf`).
- Şerit ızgaranın dışında sabit başlık; jest boyunca yalnız `Transform`.
- "+" düğmesine `tooltip` verme; profil levhasına `FilledButton` koyma;
  `SegmentedButton`'a `VisualDensity.compact` verme.
- Yeni metin: `lib/l10n/*.arb` tr + en, `flutter gen-l10n`; `arb_case_test`,
  `terminology_test` (`TERIMLER.md`); üretilen klasör `dart format`.
- Yeni worktree'de önce `flutter pub get`; push'tan önce TAM `flutter analyze`.
- Tur `debugDisableShadows` ile çizer: "+" ve panel çevresindeki koyu halka GERÇEK DEĞİL.
- Betik yazarken ters bölü: Bash heredoc bozar, dosyayı `Write` ile yaz.
