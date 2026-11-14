# Görsel tasarım A — plan (P62)

**Durum:** YARIM (2026-11-14, Fable limit): §0–§5 + iskelet yazıldı; §6 kaydırma, §7 kasma+bütçe, §8 paketler YAZILMADI — kanıt ve paket taslağı dosyanın sonundaki "YARIM" bölümünde. Uygulama YAPILMADI.
**Kullanıcı isteği (2026-11-14):** görsel tasarım son kullanıcı için hazır olsun — tertemiz, premium, güzel animasyonlu, göze hitap eden; kasma olmasın; ara commit atılsın.
**Kapsam:** (1) ayarlar ekranlarının hepsi · (2) ana ekrandaki hesap levhası · (3) Ayarlar → Hesap · (4) ipucu ve uyarıların görünümü/yeri · (5) sağa-sola kaydırma hissi.
**Kapsam DIŞI (P63'te, dokunma):** `lib/core/widgets/customizable.dart`, `lib/core/personalize.dart`, `lib/features/settings/presentation/personalize_screen.dart`, `personalize_bar_list.dart`, `quick_row_editor.dart`, şablon / kalem / sesle yazma / madde çizgisi dosyaları, `lib/features/notes/presentation/editor/**` ve `viewers/**`.

## 0. Bu planı uygulayan için kurallar (önce oku)

1. Depo kuralları: `CLAUDE.md`, `isci` skill'i. Flutter: `C:/src/flutter/bin/flutter.bat`. `dart format lib` YOK; tam test takımı yerelde koşulmaz.
2. **Görünüş/yer değiştirmeden önce** `python tool/design/istek_tara.py <dosya>`; dosyadaki "kullanıcı isteği/bulgusu" yorumuyla çelişen iş yapılmaz. Bu plandaki her madde tarandı (çelişki notları maddelerde); yine de dokunduğun dosyada yeniden çalıştır.
3. **Yasaklar** (`docs/hafiza/arayuz.md` sonu): bulanıklık / bulanık gölge / gradyan / paralaks / zıplayan eğri yok; **boy animasyonu yok** (hareket yalnız `Transform` / `FractionalTranslation` / `Opacity`); sayfa geçiş süreleri (`page_transitions.dart` 420/360 ms, `MediaRoute` 320/240) DEĞİŞMEZ; yeni ekran, yeni ayar sayfası, yeni paket, yeni özellik yok; `ValueKey` / `menuId` / `UiItem` kimlikleri değişmez (testler ve tur bunlara bağlı); 20 tema ailesine dokunulmaz.
4. **Ölçü elle yazılmaz:** köşe / boşluk / punto / süre / eğri / saydamlık `AppRadius` / `AppSpace` / `AppText` / `AppMotion` / `AppAlpha` / `AppIconSize` + §1'deki yeni adlar. Mandal `test/design_tokens_guard_test.dart` (elle değer sayısı yalnız düşer) — dokunduğun satırdaki elle değeri belirtece çevir, bütçeyi `python tool/design/token_sayim.py --json` ile DÜŞÜR.
5. Renk rolü: `primary` = eylem / seçim; `secondary` = zaman, dikkat, etiket; `tertiary` = YALNIZ yapay zekâ; `error` = hata / geri dönüşsüz; gerisi nötr. Ekran başına tek dolu birincil düğme. Krom yazısında en kalın `AppWeight.strong`.
6. Görsel kanıt (önce / sonra, açık + koyu, üç boyut):
   `TOUR_ONLY=<sahneler> TOUR_SIZES=telefon-kucuk,matepad-yatay,masaustu TOUR_OUT=build/tour_once flutter test tool/tour/screen_tour_test.dart`, işten sonra `TOUR_OUT=build/tour_sonra TOUR_COMPARE=build/tour_once` (koyu: `TOUR_DARK=1`, büyük yazı: `TOUR_FONT=1.3`). Sahneler: `ayarlar`, `ayarlar-gorunum`, `ayarlar-account|friends|ai|notes|writing|sound|sync|permissions|updates`, `hesap-levhasi`, `ana`.
7. Her madde AYRI commit + push; `DEVIR.md` güncel. Telefonda bakılamayan her görünür değişiklik `KONTROL_LISTEM.md` "Telefonda bak"a yazılır.
8. "Sabah bakılacak" işaretli zevk kararlarında planda yazan **güvenli seçenek** uygulanır, kullanıcıya soru sorulmaz.

## 1. Ortak tasarım dili (P62 sahipliğinde; P63 de bunları kullanır)

İskelet kuruldu, derleniyor, testi yeşil (`test/app_notice_test.dart`). Var olanlar `lib/app/theme/app_tokens.dart`'ta, yeniler aşağıda.

| Ad | Dosya | Ne | Kim kullanır |
|---|---|---|---|
| `AppMotion.selection` (200 ms) | `app_tokens.dart` | seçim halkası, seçili karo/çip vurgusu | P62, P63 |
| `AppMotion.emphasized` (`easeOutCubic`) | `app_tokens.dart` | "vurgulu" oturma eğrisi; TAŞMAZ (yay/zıplama yasak — P63'ün istediği "yay" bu) | P62, P63 |
| `AppMotion.exitOf(d)` | `app_tokens.dart` | çıkış = girişin 2/3'ü (ilke 4) | hepsi |
| `AppMotion.enter` / `exit` / `standard`, `instant` 100 · `quick` 150 · `short` 200 · `medium` 300 · `long` 420, `of()` / `curveOf()` (hareketi azalt) | `app_tokens.dart` (vardı) | süre + eğri | hepsi |
| `AppTone { neutral, action, attention, ai, danger }` + `.colors(scheme)` → `(bg, fg)` | `lib/app/theme/app_design.dart` | şerit / bildirim renk rolü | P62 şeritler, P63 düzenleme modu ipucu satırı |
| `AppSurface.group(theme)` | `app_design.dart` | grup kartı: `surfaceContainerLow`, köşe `AppRadius.l`, çizgisiz | ayarlar, levha içi gruplar |
| `AppSurface.paper(theme)` | `app_design.dart` | kâğıt: `AppTokens.card` + `hairline` + `cardShadow`, köşe `cardRadius` | kimlik kartı, karolar |
| `AppSurface.floating(theme, {color, radius})` + `AppSurface.floatingShadow(theme)` | `app_design.dart` | yüzen yüzey: ince çizgi + 2 dp BULANIKSIZ alt gölge | bildirim; P63: kalem kapsülü, dinleme kartı |
| `AppSwipe.commitFraction` 0.22 · `flingVelocity` 300 · `rubber` 0.25 · `settleMin/Max` · `commits()` · `settleFor()` | `app_design.dart` | yana kaydırma kararı + oturma süresi | §6 |
| `AppBanner` | `lib/core/widgets/app_banner.dart` | akışta duran KALICI şerit (ton, simge, başlık, alt yazı, sağ parça, ilerleme) | §5; P63 düzenleme modu ipucu satırı |
| `AppNoticeController` / `appNotice` / `AppNoticeData` / `AppNoticeKind { tip, announce, message }` / `AppNoticeHost` / `noticeTopInset` | `lib/core/widgets/app_notice.dart` | GEÇİCİ bildirimlerin tek kapısı | §5 |
| `AppText.sheetTitle` (18/24 strong) · `AppText.section` (14/20 strong, `primary`) · `rowTitle` 16/22 · `body` 14/20 · `label` 13/18 · `meta` 12/16 · `badge` 11/14 | `app_tokens.dart` (vardı) | levha başlığı, bölüm etiketi (`SectionLabel`), satır | hepsi |
| `PressScale`, `PopIn`, `TogglePop`, `ExpandReveal`, `SectionLabel`, `SheetTile`, `SheetHeader` | `lib/core/widgets/` (vardı) | basınca çökme, belirme, aç/kapa | yeniden YAZMA, bunları kullan |

Hareket sözlüğü (bütün paketler için):

| Durum | Hareket | Süre / eğri |
|---|---|---|
| Basma (karo, satır, düğme) | `PressScale` (0.97) | `AppMotion.instant` |
| Seçim (çip, karo, segment, kategori) | zemin rengi solması (`AnimatedContainer` YALNIZ renk — boy/dolgu sabit) | `AppMotion.selection`, `standard` |
| Belirme (bildirim, rozet, şerit içeriği) | solma + kendi boyunun ¼'ü kayma (`SlideTransition`) | giriş `short` + `enter`; çıkış `exitOf` + `exit` |
| Sayfa içi geçiş (ayarlar kök ↔ alan) | solma + %6 yatay kayma | giriş `medium` + `enter`; çıkış `exitOf(medium)` + `exit` |
| Yana çekiş oturması | `Transform.translate` | `AppSwipe.settleFor`, `AppMotion.emphasized` |
| Aç/kapa (iç bölüm) | `ExpandReveal` (var; tek izinli boy hareketi, ayarlarda) | değişmez |

"Hareketi azalt" açıkken: süre `AppMotion.of`, eğri `AppMotion.curveOf`; kayma yok, yalnız solma.

## 2. Ayarlar ekranları

### 2.1 Mevcut durum (kanıt: `build/tour_p62/telefon-kucuk-ayarlar*.png`, `matepad-yatay-ayarlar-gorunum.png`)

Kök sayfa derli toplu (arama, profil kartı, iki kısayol, üç grup). Sorun alan sayfalarında ve ayrıntıda:

| # | Bulgu | Kanıt |
|---|---|---|
| A1 | Alan sayfası TEK dev kart; içinde gruplama, ayraç, hizalama yok. Satırlar anahtarlı satır, metin düğmesi, segment, kırmızı uyarı yazısı karışık dizili | `settings_area.dart:225-262` (`_RowsCard`), `:318` |
| A2 | Hesap alanı beş yeşil `TextButton.icon` (Oturumu kapat, Hesabı sil, Gizlilik, Lisanslar, Hata günlüğü) — bağlantı yığını gibi, satır değil | `settings_account.dart:781-801, 827` (dosyada 16 `TextButton`) |
| A3 | "Not kilidi" / "Uygulama kilidi" Hesap alanında başlıksız duruyor (KT-10) | `settings_screen.dart:205-214` |
| A4 | Segment seçimi sıcak şeftali (`secondaryContainer`) — rol sözleşmesinde `secondary` = zaman/dikkat; seçim `primary` olmalı. Dar telefonda "Parma / k izi" kelime ortasından kırılıyor | tur `ayarlar-account`; M3 varsayılanı (temada `segmentedButtonTheme` YOK, `app_theme.dart`) |
| A5 | Geniş ekranda seçili kategori de `secondaryContainer` | `settings_area.dart:175` |
| A6 | Köşeler dağınık: grup 20, profil 18, arama 14, kısayol `AppRadius.l` | `settings_area.dart:130, 239`; `settings_account.dart:105`; `settings_screen.dart:1028` |
| A7 | Profil kartı `primaryContainer` %50 + çizgi; hesap levhasındaki kimlik kartı kâğıt (`tokens.card`). Aynı şey iki kılıkta (ilke 3) | `settings_account.dart:102-107` ↔ `account_sheet.dart:132-137` |
| A8 | Alan başlığı satırı (36 dp simge + özet) kartın üstünde yetim; "Güncelleme" alanında içerik ortalı üç parça, satır dili yok | `settings_area.dart:292-317`, `:485-526` |
| A9 | Senkron alanında uyarılar kırmızı düz yazı (iki satır), şerit değil | tur `ayarlar-sync`; `settings_account.dart:430-498` (`_BackupStatus`) |
| A10 | Geniş ekran: arama iki bölmenin ortasında (sol sütunla hizasız); ayrıntı 720 dp ortalı → listeyle arasında boşluk (KT-10); alan değişimi animasyonsuz | `settings_screen.dart:826-838, 896-899` |
| A11 | Kök ↔ alan geçişi elle 200 ms + `easeOutCubic/easeInCubic` | `settings_screen.dart:845-861` |
| A12 | Yan ekranlar ham `Card` + `ListTile`: Premium 5 kart, Kişiler 5 kart, kılavuz 3 kart | `premium_screen.dart:47,102,112,213,255`; `friends_screen.dart`; `guide_screen.dart` |

`istek_tara` sonuçları (uyulacak): hesap EN ÜSTTE (`settings_screen.dart:189`); alanlar KAPALI gelir (`:146`); ayar arama en üstte sabit (`:889`); AI arama kipi (`:153`); misafirde "Giriş yap" profil kartında (`settings_account.dart:175`); örnek metin Görünüm'ün en üstünde (`settings_screen.dart:307`); tema seçici önizlemeli kartlar (`theme_picker.dart:139`); eklenti anahtarları ayarlarda da (`settings_screen.dart:441`); seslendirme tek blokta (`:574`); sürüme dokun → güncelle (`settings_area.dart:433`); **satırlar karelere yayılarak kurulur** (`settings_area.dart:602` — kasma kök nedeni, KORUNACAK); yazı boyutu dört kademe (`settings_appearance.dart:697`). Bu planda hiçbiri tersine çevrilmiyor: satırların YERİ ve SIRASI aynı, yalnız kılık değişiyor.

### 2.2 Hedef

**Satır dili (tek kalıp, her alanda):**
- Alan sayfası = dikey gruplar. Her grup: isteğe bağlı `SectionLabel` (üst boşluk `AppSpace.xl`, alt `AppSpace.s`, yatay `AppSpace.s`) + bir `AppSurface.group` kartı (köşe `AppRadius.l`, `Clip.antiAlias`). Gruplar arası `AppSpace.m`.
- Kart içinde satırlar arası 1 dp ayraç: `outlineVariant` × `AppAlpha.muted`, baştan girinti = satır simgesi varsa `AppSpace.l + AppIconSize.l + AppSpace.m`, yoksa `AppSpace.l`.
- Satır: en az 56 dp; yatay dolgu `AppSpace.l`, dikey `AppSpace.m`; başta simge `AppIconSize.m`, `onSurfaceVariant`, kutusuz; başlık `AppText.rowTitle`; açıklama `AppText.meta` (en çok 3 satır); sonda YA anahtar YA değer (`AppText.body`, `onSurfaceVariant`) + `chevron_right` YA hiçbir şey.
- Eylem satırı (gezinme, dışa açılan iş): simge + başlık + ok. Metin düğmesi DEĞİL.
- Geri dönüşsüz eylem (Hesabı sil): sayfanın SON grubunda tek satır, başlık + simge `error`, ok yok, onay diyaloğu aynen.
- Alan içi uyarı: `AppBanner` (ton `attention`; veri kaybı riski `danger`), grubun ÜSTÜNDE, kartın dışında.
- Segment: seçili dilim `primaryContainer` / `onPrimaryContainer`; etiket tek satır (`maxLines: 1`, `softWrap: false`, sığmazsa simge düşer). **Sabah bakılacak:** temaya genel `segmentedButtonTheme` eklemek bütün uygulamayı etkiler (editör, takvim). Güvenli seçenek: yalnız ayarlar sayfasını saran `Theme` ile (`_AreaPage` içinde `SegmentedButtonTheme`).

**Kök sayfa:**
- Profil kartı → ortak `AccountIdentityCard` (§3.2), `AppSurface.paper`. Misafirde altındaki dolu "Giriş yap" düğmesi KALIR (2026-10-28).
- Grup kartları ve arama kutusu: köşe `AppRadius.l` (arama `AppRadius.m`), `AppSurface.group`. Kategori satırı aynen (40 dp nötr simge kutusu, `rowTitle` + `meta` özet, ok); basınca `PressScale` YOK (uzun listede kaydırırken titrer), yalnız mürekkep.
- Sürüm satırı aynen.

**Geniş ekran (≥ 900 dp, `_kSettingsWide`):**
- Seçili kategori: zemin `primaryContainer`, yazı/simge `onPrimaryContainer`; geçiş `AnimatedContainer` (yalnız renk) `AppMotion.selection`.
- Arama kutusu sol sütunun (380 dp) içinde, sütunla aynı hizada.
- Ayrıntı bölmesi: `Alignment.topCenter` → `AlignmentDirectional.topStart`, `maxWidth` 720 aynı (KT-10 boşluğu). **Sabah bakılacak** (zevk): ortalı mı yaslı mı; güvenli = yaslı (keşif turu bulgusu).
- Alan değişimi: `AnimatedSwitcher`, yalnız solma, `AppMotion.quick`.

**Dar ekran geçişi (kök ↔ alan):** aynı düzen (solma + %6 kayma, yön aynı), süre `AppMotion.medium` giriş / `exitOf(medium)` çıkış, eğriler `AppMotion.enter` / `exit`, `AppMotion.of` / `curveOf` ile.

**Alan başlığı:** dar ekranda başlık üst çubukta zaten var → kartın üstündeki simge + özet satırı KALKAR (özet kök sayfada görünüyor). Geniş ekranda büyük başlık + özet kalır, simge kutusu 48 → 40 dp.

**Alanlar (satır sırası DEĞİŞMEZ; yalnız grup başlığı ve kılık):**

| Alan (`id`) | Gruplar (bölüm etiketi) |
|---|---|
| `account` | §4 |
| `friends` | (etiketsiz) Kişiler, Gelen · "Gizlilik ve bildirim": Bulunabilirlik, Paylaşım bildirimleri |
| `ai` | (etiketsiz) durum/puan · "Kendiliğinden": Brifing, Oto etiket, Oto başlık, Asistan sesi, İşaretlileri atla · "Gelişmiş" (var olan `_ExpandTile`) |
| `appearance` | örnek metin (kartın DIŞINDA, en üstte, `AppSurface.paper`) · "Tema" · "Yazı" · kalan satırlar "Liste ve kartlar" |
| `notes` | `notes_settings.dart`'taki mevcut alt başlıklar `SectionLabel`'a |
| `writing` | "Kalem" · "Yazım" · "Ekran" (dosyadaki sıra) |
| `sound` | "Seslendirme" (tek blok — 2026-08-09) · "Sesle yazma" |
| `sync` | uyarılar `AppBanner` · "Bu cihazda" (depolama dökümü: satır = ad + sağda değer) · "Ekler" · "Yedek" (Tam yedek al / Geri yükle / Başka uygulamadan al = eylem satırları) |
| `permissions` | her izin bir satır: simge + ad + açıklama + sağda durum (verildi: `check_circle` `primary`; verilmedi: "İzin ver" metin düğmesi) |
| `updates` | "Sürüm": satır "Notlar · v…" + durum alt yazısı (dokun: denetle; indirme çizgisi satırın dibinde) · Sürüm notları (eylem satırı) · Otomatik güncelle (anahtar) · Yeniden açılma izni (eylem satırı / onaylı) |

Grup etiketi için yeni l10n anahtarı gerekirse `app_tr.arb` + `app_en.arb` (pubspec/.arb değişince CI tam takım koşar — beklenen). Var olan anahtar varsa onu kullan (`settingsThemeHeader` gibi `_SubHeader` metinleri).

**Yan ekranlar** (aynı dil; içerik/sıra aynı): `premium_screen.dart`, `privacy_screen.dart`, `guide_screen.dart`, `friends_screen.dart`, `account_required.dart`, `backup_ui.dart` diyalogları, `theme_picker.dart`, `typing_bar_settings.dart`, `app_lock.dart` karoları: ham `Card` → `AppSurface.group` / `paper`; başlık `AppText`; elle köşe/punto → belirteç. Premium ekranında tek dolu düğme (satın al / yükselt) kalır, ayrıcalık satırları tek grup kartında ayraçlı.

### 2.3 Uygulama notu (kasma kök nedeni korunur)

- `_SettingRow`'a `group` (String?, bölüm etiketi) eklenir; `_AreaPage` ardışık aynı `group`'lu satırları bir karta toplar. **Yayma korunur:** `_StaggeredRows` bugün satır sayar; grup düzeninde de "ilk karede ilk iki SATIR, sonraki her karede bir satır" kuralı aynen işlemeli (grup kartı, içindeki ilk satır kurulunca belirir). Tek karede bütün alanı kurmak 2026-10-20 kasmasını geri getirir.
- Kılığın çoğu TEK yerden gelir: `_RowsCard`'daki `ListTileTheme.merge` (başlık/alt yazı stili, `contentPadding`, `minVerticalPadding`, `horizontalTitleGap`) — 60+ satır widget'ına tek tek dokunmadan. Sonra alan alan yalnız kalıba uymayanlar (metin düğmeleri, ortalı parçalar, kırmızı yazılar) düzeltilir.
- Arama sonuçları (`_searchResults`) düz tek kart kalır (grup etiketi gösterilmez).
- `ValueKey('settings-cat-*')`, `settings-area-*`, `settings-search`, `settings-version-*`, `profile-google-sign-in`, `settings-auto-update` … aynen.

### 2.4 Kabul ölçütleri

- Tur (`ayarlar`, `ayarlar-gorunum`, dokuz `ayarlar-<alan>`): üç boyut × açık/koyu × yazı 1.0/1.3'te taşma istisnası yok; hiçbir alanda kart içinde kart yok (örnek metin hariç değil — o da dışarıda); metin düğmesi yığını yok; kelime ortasından kırılan etiket yok.
- `python tool/design/token_sayim.py`: `lib/features/settings/**` ve `lib/features/auth/presentation/**` içinde elle köşe / `fontSize` / `FontWeight.w*` / süre SIFIR (bugün: `settings_account` r3 fs3, `settings_ai` r2 fs5, `settings_appearance` r3 fs2, `theme_picker` r3, `settings_area` r2, `account_sheet` r1 fs2 …).
- Var olan ayar testleri yeşil (`test/settings*_test.dart`, `test/guide_screen_test.dart`); satır sırası ve anahtarlar değişmediği için test düzeltmesi yalnız bulucu türü (ör. `TextButton` → `ListTile`) olabilir.
- Bütçe: §7 S28.

## 3. Ana ekrandaki hesap levhası

### 3.1 Mevcut durum (kanıt: `build/tour_p62/telefon-kucuk-hesap-levhasi.png`)

2026-11-06'da "masa ve kâğıt" diliyle baştan yazıldı (`account_sheet.dart:95-101`) — iskelet doğru; kalan pürüzler:

| # | Bulgu | Kanıt |
|---|---|---|
| H1 | Premium karosunun alt yazısı tek satır, kesiliyor ("Ücretsiz sürümü kulla…"); misafir durum hapı da kesilebiliyor (KT-7) | `account_sheet.dart:379-386`, `:313-323` |
| H2 | Misafir durum hapı `tertiary` (yalnız yapay zekâ rolü) | `:197` |
| H3 | Elle değerler: hap punto 12 / w600, rozet köşe 10, karo başlığı `titleSmall` w600 | `:317-320`, `:411`, `:375-377` |
| H4 | Kimlik kartı ayarlardaki profil kartıyla farklı kılıkta (A7) | §2.1 |
| H5 | Karolarda basma tepkisi yalnız mürekkep; avatar fotoğrafı ağdan gelince "pat" diye beliriyor | `:354-357`, `:160-162` |
| H6 | Çıkış düğmesi kenarlı, misafirde kırmızı — DOĞRU (onay diyaloğuyla karışmasın yorumu), KALIR | `:262-279` |

`istek_tara`: avatar girişte foto / misafirde kişi simgesi (`:18`); tek avatar + sayı rozeti (`:36`); levhada "Oturumu kapat" ve "Hesap değiştir" (`sign_out_actions.dart:10`); levha kapanınca onay çalışmalı (`:17` — `go()` kalıbı AYNEN kalır).

### 3.2 Hedef

- **`AccountIdentityCard`** (yeni, `lib/features/auth/presentation/account_identity_card.dart`): avatar (yarıçap 28), ad `AppText.rowTitle` (strong), e-posta `AppText.meta`, durum hapı. `AppSurface.paper`. Hem levhada hem ayarlar kökünde hem Ayarlar → Hesap'ın tepesinde (§4) kullanılır. İsteğe bağlı `footer` (ayarlar kökünde misafirin "Giriş yap" düğmesi).
- Durum hapı: girişli → simge `cloud_done_outlined`, renk `primary`; misafir → `smartphone`, ton `AppTone.attention` renkleri. Yazı `AppText.badge` boyutunda değil `AppText.meta` + `AppWeight.strong`; en çok 2 satır; köşe `AppRadius.pill`; zemin = renk × `AppAlpha.pressed`.
- Karolar (Kişiler, Premium): `PressScale` sarmalı; başlık `AppText.label` (strong); alt yazı `AppText.meta`, **en çok 2 satır** (boş alt yazıda karo boyu eşit kalsın diye iki karo `IntrinsicHeight` + `stretch`); rozet köşe `AppRadius.pill`, yazı `AppText.badge`; rozet ilk belirişte `PopIn`.
- Gruplu satırlar ve çıkış düğmesi: kılık aynen; satır başlığı `AppText.rowTitle`.
- Avatar fotoğrafı: `Image.network` + `frameBuilder` ile solarak (`AppMotion.quick`); altında kişi simgesi yer tutucu (boyut değişmez).
- Levha içi boşluklar `AppSpace.m` / `AppSpace.l`.
- Geniş ekran: `showAppSheet` genişlik davranışına DOKUNMA (levha altyapısı ortak; KT-2 ayrı iş).
- Avatar düğmesi (`AccountAvatarButton`): aynen; bekleyen rozeti `PopIn` (ilk belirişte), `ValueKey('home-account-avatar')` aynı.

### 3.3 Kabul

Tur `hesap-levhasi` (üç boyut, açık/koyu, yazı 1.3): kesik metin yok; elle değer sıfır; `test/account_sheet*_test.dart` ve `sign_out` testleri yeşil; bütçe §7 S29 (levha açılırken ana ekran kartı kurulmaz).

## 4. Ayarlar → Hesap

Mevcut: A2, A3, A9 (kanıt `build/tour_p62/telefon-kucuk-ayarlar-account.png`). Hedef sayfa (yukarıdan aşağı; var olan satırların sırası korunur, yalnız gruplanır):

1. `AccountIdentityCard` (kök sayfadakiyle aynı bileşen).
2. Misafirse: `AppBanner(tone: attention, icon: cloud_off_outlined, title: <"yalnız bu cihazda" metni — var olan l10n>, trailing: "Google hesabı bağla" metin düğmesi)` — bugünkü tonlu `Card` + `FilledButton.tonalIcon` (`settings_account.dart:745-770` civarı) yerine. Kökte dolu "Giriş yap" zaten var; burada ikinci dolu düğme olmaz (ilke 2).
3. Grup "Oturum": Oturumu kapat (eylem satırı; misafirde başlık `error` — veri kaybı).
4. Grup "Kilit" (yeni `SectionLabel`; KT-10): Not kilidi (başlık + açıklama + altında tam genişlik segment + açıklama notu `AppText.meta`), Uygulama kilidi (anahtar). **Yeni kategori AÇILMAZ** (yeni ayar sayfası yasak) — yalnız aynı sayfada başlıklı grup. **Sabah bakılacak:** kilidi ayrı "Güvenlik" kategorisine taşımak kullanıcı kararı.
5. Grup "Hakkında": Gizlilik politikası, Açık kaynak lisansları, Hata günlüğünü paylaş (eylem satırları, ok).
6. Son grup (etiketsiz): Hesabımı ve verilerimi sil (`error`, ok yok).

Sıra notu: bugün "Hesabı sil" ikinci sırada. Geri dönüşsüz eylemi en alta almak yer değişikliğidir; `istek_tara settings_account.dart` bu satırın yeri için kullanıcı isteği göstermiyor (yalnız "hesap ayarları üstte" — alanın kendisi). Güvenli seçenek uygulanır: en alta. **Sabah bakılacak.**

Kabul: tur `ayarlar-account` (misafir + girişli; girişli sahne turda yoksa widget testiyle), `test/` altındaki hesap silme / çıkış / bağlama testleri yeşil; anahtarlar aynı.

## 5. İpucu ve uyarıların görünümü / yeri

### 5.1 Mevcut durum (kanıt)

Sayım (yorum satırları ve tanım dosyaları hariç; 2026-11-14): `showMessage` / `showAppMessage` 177 çağrı / 74 dosya · `showUndoSnackBar` 26 / 15 · `timedSnackBar` 10 / 9 · ham `showSnackBar` 16 / 14 · `TipOnce.show` 8 / 6 → **237 çağrı / 94 dosya** (DEVIR'deki 156 / 68 dar sayımdı). Bunların 70'i P63 çitinde (`editor/**`, `viewers/**`, `note_template_sheet.dart`). Ayrıca 81 `hideCurrentSnackBar` (51 dosya).

| # | Bulgu | Kanıt |
|---|---|---|
| B1 | İpucu ekranın en tepesinde (`top + 8`): ana ekranda 50 dp'lik arama hapını, editörde üst çubuğu 5 sn örter | `tips.dart:196-199`; hap `dashboard_widgets.dart:339` (`height: 50`), `dashboard_screen.dart:1767` |
| B2 | DÖRT ayrı yol, aralarında sıra / koordinasyon yok: ipucu kök `Overlay`e girer (`tips.dart:96-118`), "Geri al" KÖK messenger'da (`undo_snackbar.dart:118-135`), levha açıkken ayrı bir `OverlayEntry` (`_OverlayUndo`, `:103-116`, `:274-389`), düz ileti EN YAKIN messenger'da (`:222-257`). İpucu + ileti + levha üstü "Geri al" aynı anda görünebilir | aynı satırlar |
| B3 | Dört ayrı kılık: M3 varsayılan `SnackBar`, `timedSnackBar` (dolgu 0, 3 dp şerit), `_OverlayUndo` (`elevation: 6`, geri sayım ÇİZGİSİ YOK), `_TipBanner` (`elevation: 4`, elle 12 / 8 / 14 / 10 / 18 / 560 / 220 ms). `elevation` = bulanık gölge (yasak) | `undo_snackbar.dart:156-217`, `:353-357`; `tips.dart:194-236` |
| B4 | Eylemli ham `SnackBar` iki yerde `timedSnackBar`sız: bu Flutter sürümünde eylemli `SnackBar` varsayılan `persist: true` → kendiliğinden kapanmaz (kök neden notu `undo_snackbar.dart:141-148`, kullanıcı bulgusu 2026-10-17). **Hipotez** (koddan çıkarım, cihazda bakılmadı) | `app_update.dart:452-461` ("kuruluma hazır"), `line_task_chip.dart:209-218` (görev silindi + Geri al) |
| B5 | Dipteki bildirimi klavyenin üstüne çıkarmak için odaktaki alanın atalarında `Scaffold` aranıyor (kırılgan); levhadan çağrılan düz ileti levhanın ARKASINDA kalıyor (yalnız "Geri al" için çözülmüş) | `undo_snackbar.dart:33-47`, `:98-117` |
| B6 | "Yenilikler" tostu elle kurulmuş sütun (boşluk 4 / 2, saydamlık 0.75) | `release_notes_toast.dart:73-112` |
| B7 | KALICI şeritler beş kılıkta: yeni sürüm (köşe 14, 13 / w600, `primaryContainer`), zamanı gelenler (`AppRadius.m`, 44 dp, `secondaryContainer`), bekleyen ekler (köşe 10, 12 / w600), web ekleri (köşe 14, `secondaryContainer` × 0.7), eski sürüm kapısı (`errorContainer`, kenardan kenara); ayarlarda kırmızı düz yazı (A9) | `app_update.dart:540-585`, `:596-628`; `due_banner.dart:72-160`; `dashboard_widgets.dart:1721-1794`; `drive_ui.dart:327-365` |
| B8 | Bekleyen ekler şeridi `AnimatedSize` (200 ms) — ana ekranın SABİT başlık sütununda, altında `Expanded` ızgara: şerit belirirken / kalkarken ızgara her karede yeniden dizilir (boy animasyonu yasağı; kasma listesi md. 6'nın ana ekrandaki eşi) | `dashboard_widgets.dart:1721`, `dashboard_screen.dart:1855, 1885` |

`istek_tara` (uyulacak): ipuçları ÜSTTE ve DOKUNUŞ GEÇİRGEN (2026-11-08, `tips.dart:91`); eylemli bildirim GERİ SAYIMLA kapanır (2026-10-17, `undo_snackbar.dart:141`); kalem ipuçları (2026-11-08, `tips.dart:50`); "Yenilikler" ana ekranda TOST (2026-11-10, `release_notes_toast.dart:17`); zamanı gelenler TEK SATIR şerit (2026-11-08, `due_banner.dart:15`); web ek şeridi (2026-11-02, `drive_ui.dart:261`); bildirim kalem tepsisini KAPATMAZ (2026-11-12, `undo_snackbar.dart:49`). Hiçbiri tersine çevrilmiyor.

### 5.2 Hedef: iki tür, iki araç

**Kural:** kendiliğinden kalkan her şey `appNotice`ten (GEÇİCİ), kalkmayan her şey `AppBanner`dan (KALICI, içerikle aynı akışta) geçer. Üçüncü yol yok.

**Geçici bildirim** — `AppNoticeHost` (Navigator'ın ÜSTÜNDE tek şerit; levha ve diyalog da altında kalır), aynı anda EN ÇOK BİR bildirim:

| Tür (`AppNoticeKind`) | Yer | Süre | Dokunuş | Sıra kuralı |
|---|---|---|---|---|
| `tip` (ipucu) | ÜSTTE, üst kromun (`noticeTopInset`, varsayılan 56 dp) ALTINDA, ortada, en çok 480 dp | 5 sn; ekrana ilk dokunuşta kalkar | GEÇİRGEN (`IgnorePointer`) | yalnız şerit boşken çıkar; çıkamazsa "gösterildi" SAYILMAZ |
| `message` (kaydedildi, silindi + Geri al, hata) | DİPTE, alt-BAŞ köşe; klavyenin ve dibe yapışık panelin (`snackBarBottomObstacle`) üstünde | 4 sn; hata 6 sn; eylemlide dipte incelen geri sayım çizgisi | eylem düğmesi dokunulur | en yeni kazanır (görüneni değiştirir) |
| `announce` ("Yenilikler") | DİPTE, tam genişlik (en çok 480 dp), yüzen düğme satırının ÜSTÜNDE | 12 sn | "Tümünü gör" | şerit boşalana dek bekler; ileti araya girerse sıranın başına döner |

- **Yüzen düğme bölgesi** (iskelette, testli — commit 07f9429e): ekranın alt-SON köşesindeki 144 × 72 dp'ye (`AppNoticeHost.fabReserve` × `fabRow`: ana ekranın mikrofon / "+" / yapay zekâ satırı, öbür ekranların "+"sı) hiçbir bildirim girmez — ileti YANINDA, duyuru ÜSTÜNDE. Bugünkü "Geri al"ın `end: 144` payı (`undo_snackbar.dart:129-133`) bütün iletilere genellendi.
- Kılık (iskelette): `AppSurface.floating` (`inverseSurface`, köşe `AppRadius.m`, ince çizgi + 2 dp BULANIKSIZ alt gölge — `elevation` yok), simge `inversePrimary` (ipucunda `lightbulb_outline`), yazı `AppText.body`, en çok 4 satır; eylem `TextButton` (`inversePrimary`); geri sayım 2 dp, yalnız ölçek (`Transform.scale`).
- Hareket: §1 "belirme" (solma + kendi boyunun ¼'ü; ipucu yukarıdan, ileti aşağıdan); "hareketi azalt"ta yalnız solma.
- Erişilebilirlik: `Semantics(liveRegion: true)` (iskelette); ipucu dokunma hedefi değildir; eylem düğmesi 48 dp.

**Kalıcı şerit** — `AppBanner` (§1): hiçbir şeyin üstüne binmez, yer kaplar; boyu ANİMASYONSUZ (görünür / gizli tek adımda; içerik değişimi yalnız metin). Renk yalnız `AppTone`dan.

### 5.3 Göç: çağrı yerlerine DOKUNMADAN, huniden

237 çağrının imzası DEĞİŞMEZ (70'i P63 çitinde, dokunulamaz). Dört huni işlevinin GÖVDESİ değişir:

| Huni | Yeni gövde | Not |
|---|---|---|
| `TipOnce.show` (`tips.dart:80`) | `due` → `appNotice.show(AppNoticeData(kind: tip, text, duration))`; **dönüş true ise** `markShown` | Bugün `markShown` eklemeden ÖNCE çağrılıyor (`:98`); sıra ters çevrilir — şerit doluysa ipucu yanmaz, sonraki fırsatta çıkar. `_TipBanner` ve `_current` SİLİNİR. `appNotice.hosted` false ise (yalın test) false döner, `markShown` çağrılmaz |
| `AppMessages.showMessage` (`undo_snackbar.dart:223`) | `appNotice.hosted` ise `appNotice.show(AppNoticeData(text, actionLabel / onAction ← SnackBarAction, duration))`, değilse BUGÜNKÜ gövde | `errorDetailFor` (ham ayrıntıyı kopyala, 6 sn) aynen; `SnackBarAction` parametresi imzada kalır |
| `showUndoSnackBar` (`:91`) | `hosted` ise `appNotice.show(...)`; `PopupRoute` dalı ve `_OverlayUndo` SİLİNİR (şerit zaten levhanın üstünde) | `hosted` değilse bugünkü kök messenger yolu |
| `timedSnackBar` (`:149`) | gövdenin BAŞINDA `appNotice.dismiss()` | çit içindeki 7 çağrı `SnackBar` kalır; iki bildirim üst üste binmesin |

Ek olarak:
- `showMessage` / `showUndoSnackBar` şerit yoluna girmeden önce görünen `SnackBar`ı kapatır: `rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar()`.
- Çit DIŞINDAKİ 7 ham `showSnackBar` elle çevrilir: `release_notes_toast.dart:74` → `appNotice.show(AppNoticeData(kind: announce, text: başlık, details: en çok 3 madde (+ "N tane daha" satırı), actionLabel, onAction, duration: 12 sn))`; `app_update.dart:452` ve `:495`, `line_task_chip.dart:209`, `gmail_screen.dart:832`, `dashboard_screen.dart:1131`, `duplicates_sheet.dart:118` → `showMessage(metin, action: …)` (B4 böylece kapanır).
- Tek başına `hideCurrentSnackBar();` ("hazırlanıyor…" iletisini iş bitince kapatan) çit dışı 6 yer (`drive_ui.dart:101, 437`; `quick_add_actions.dart:232, 608, 651, 770`): `undo_snackbar.dart`a `extension` yöntemi `hideMessage()` = `hideCurrentSnackBar()` + `appNotice.dismiss()`; bu altı yer onu çağırır. Çit içindeki 3 yer (`attachment_clipboard.dart:185`, `note_editor_media_view.dart:657, 734`) kuyruk paketine kalır — o güne dek "hazırlanıyor" iletisi süresini (4 sn) doldurur (zararsız).
- Şeridin yeri `app.dart`: `UpdateRequiredBanner(child: AppNoticeHost(child: NoteWriteIssueListener(…)))` (`app.dart:273-275`). Kapı şeridinin ALTINDA (üst güvenli alanı o tüketir, ipucu yeri kendiliğinden doğru), uygulama kilidinin (`AppLockGate`) İÇİNDE (kilitliyken bildirim görünmez).
- Çitte kalan 9 ham `showSnackBar` + 3 `hideCurrentSnackBar` → kuyruk paketi (P63 birleştikten sonra).
- Reddedilen yol: kök `ScaffoldMessenger`ı alt sınıfla değiştirip `showSnackBar` / `hideCurrentSnackBar`ı orada yakalamak — çağrı yerine hiç dokunmaz ama çerçeve sınıfının iç davranışına yaslanır (kırılgan); huni + kuyruk paketi yeter.

**Mandal** (yeni `test/notice_paths_guard_test.dart`, kaynak taraması, yalnız DÜŞER): `lib/` içinde `undo_snackbar.dart` dışındaki `showSnackBar(` sayısı ≤ 9 (kuyruk paketi sonrası 0); `tips.dart`ta `OverlayEntry` 0; `lib/app/app.dart`ta `AppNoticeHost(` tam 1.

**Testler** (önce kırmızı yazılır): `tip_once_test.dart` "show" (şeritle sar; şerit doluyken `show` false ve `due` hâlâ true), `pen_hint_once_test.dart` 1. test (bildirim kalem panelinin üstünde — `SnackBar` bulucusu yerine şerit kartı), `snackbar_over_keyboard_test.dart` (ilk iki test şeritle; üçüncüsü şerit `Scaffold`dan bağımsız olduğu için "klavyesiz ekranda dipte" testine döner), `undo_over_sheet_test.dart` (şeritle; bulucu `overlay-undo` → `notice-action`), `app_messages_test.dart`, `release_notes_toast_test.dart`. Şeritsiz (yalın `MaterialApp`) kuran öbür testler `hosted == false` dalıyla bugünkü gibi yeşil kalır.

**Tuzaklar:**
- `snackBarBottomObstacle` DİZİLİM sırasında yazılır (`undo_snackbar.dart:67-74`): dinleyici EKLEME ("setState during layout"). Şerit değeri bildirim kurulurken okur.
- `appNotice` süreç-genel: şerit sökülürken `clear()` çağırır (iskelette, testli) — testte bekleyen zamanlayıcı kalmaz.
- `test/perf_budget_test.dart` `_pumpHome` şeritsiz kurar → `TipOnce.show` false döner, ipucu yanmaz; S24 / S13 sayıları değişmemeli (değişirse nedenini yaz, mandalı yükseltme).
- `jank_patterns_guard_test.dart` `lib/app/app.dart` için `MediaQuery.of(` mandalı 1: `app.dart`a `MediaQuery.of` EKLEME (şerit `viewInsetsOf` / `paddingOf`u kendi küçük öğesinde okur).
- `await` sonrası `messenger.showMessage` kalıbı aynen çalışır (denetleyici bağlamsız); çağrı yerlerinde `ScaffoldMessenger.of(context)`i KALDIRMA (imza değişmez kuralı).
- P63 düzenleme modu şeridi (`CustomizeModeHost`, `app.dart:269`) şeridin DIŞINDA, üstte: mod açıkken ipucu onun altında kalmasın diye P63 `noticeTopInset`i yazar (P62 dokunmaz).

### 5.4 Kalıcı şeritlerin tek kılığı (`AppBanner`)

| Şerit | Ton · simge | Sağ parça | Değişmeyen |
|---|---|---|---|
| Yeni sürüm (`UpdateBanner`, `app_update.dart:472`) | `action` · `system_update` | ok; indirirken yok; `_busy` iken 18 dp çark | `ValueKey('update-banner')`, üç `ValueNotifier` dinleme düzeni, `progress` = yüzde / 100 |
| Zamanı gelenler (`DueBanner`, `due_banner.dart:19`) | `attention` · `alarm_rounded` / `task_alt_rounded` | "+N" rozeti (`AppText.badge`, köşe `AppRadius.pill`) + ✕ (`MinTapTarget`) | TEK SATIR, 44 dp (`due_items_test.dart:137`), `due-banner`, `due-banner-close`, `select`li izleme |
| Bekleyen ekler (`_PendingUploadsBar`, `dashboard_widgets.dart:1692`) | `attention`; başarısızda `danger` · bugünkü simgeler | `link` / `info_outline` | `pendingUploadsBarLabel`, "dönen çark yok" kararı, `_autoAsked`; **`AnimatedSize` KALKAR** (B8) |
| Web ekleri (`WebAttachmentsBanner`, `drive_ui.dart:268`) | `attention` (saydamlık çarpanı kalkar) | "Göster" metin düğmesi | iki anahtar, iki durumun metni |
| Eski sürüm kapısı (`UpdateRequiredBanner`, `app_update.dart:588`) | `danger` | "Güncelle" | kenardan kenara ve güvenli alan düzeni AYNEN (köşesiz); yalnız boşluk / yazı belirteçleri |
| Ayarlar: yedek / senkron uyarıları, misafir | §2.2, §4 | — | — |

- `DueBanner` başlığı iki stilli tek satır (başlık `label`, tarih `meta` — F74.3): `AppBanner`a `detail` (String?, başlıkla AYNI satırda `Text.rich`, `meta` stili; verilince `maxLines: 1`) eklenir. Başka şerit kullanmaz.
- Ana ekrandaki dizilim (sıra aynen, `dashboard_screen.dart:1842-1855`): her şerit `Padding(horizontal: kGridInset, top: AppSpace.s)` içinde; şerit yokken `SizedBox.shrink` (sıfır yer).

### 5.5 Sabah bakılacak (zevk; güvenli seçenek uygulanır)

- **K5-1** Dip bildirimi alt-BAŞ köşede, yüzen düğmelerin yanında (bugünkü "Geri al" yerleşiminin geneli) — ortada / düğmelerin üstünde değil.
- **K5-2** Editörde ipucu üst çubuğun ALTINDA (notun ilk satırlarının üstünde 5 sn, dokunuş geçirgen); bugün çubuğun üstündeydi.
- **K5-3** "Yenilikler" TOST kalır (2026-11-10 isteği); ana ekranda kalıcı şeride çevirmek YAPILMAZ.

### 5.6 Kabul ölçütleri

- `app_notice_test.dart` + yukarıdaki altı test yeşil; mandal testi yeşil.
- Tur `ana` (telefon-kucuk, açık / koyu): ipucu arama hapının ALTINDA (hapla kesişmez); "Geri al" "+" satırıyla kesişmez. Turda sahne yoksa `tool/tour/screen_tour_test.dart`a `ana-ipucu`, `ana-gerial` eklenir.
- `token_sayim`: `tips.dart`, `release_notes_toast.dart`, `due_banner.dart`, `UpdateBanner`, `_PendingUploadsBar`, `WebAttachmentsBanner` içinde elle köşe / punto / ağırlık / süre SIFIR.
- Bütçe (§7'de yazılacak): bildirim göster / kaldır ana ekranı kurmaz; şerit belirince ızgara boy karesi ≤ 1.

---

## YARIM — §6, §7, §8 YAZILMADI (limit; kalanı Opus yazar). Toplanan kanıt ve verilmiş kararlar:

**Numara düzeltmesi:** §2.4 "S28" ve §3.3 "S29" atıfları YANLIŞ — P62'ye ayrılan numaralar **S29–S39** (P63: S40–S44; S28 boş bırakılır). Öneri: S29 ayar alanı açılışı, S30 hesap levhası, S31 bildirim göster/kaldır, S32 şerit belirişi (ızgara boy karesi), S33 ana ekran yana çekiş oturması, S34 takvim mini ay kaydırma, S35 mini ay aç/kapa boy karesi. Bütçeler `test/perf_budget/budgets.json` (mandal: yalnız düşer), yardımcılar `_frames`, `_count`, `_expectBudget`, `_pumpHome` (`perf_budget_test.dart:181-203, 399-430, 295+`); örnek kalıplar S22 (`:1140`), S23 (`:1200`).

**§6 Kaydırma — kanıt:**
- Ana ekran `FolderSwipe` (`dashboard_widgets.dart:1243-1500`) parmağı ZATEN izler (tek `Transform`, etiket + dolum çubuğu). Kalan: eşikler elle — `commitFraction = 0.22` (`:1273`), fiske `300` (`:1371`), lastik `0.25` (`:1356`), sınır `_width * 0.4` (`:1354`); geri oturma sabit `AppMotion.short` + `standard` (`:1390-1392`) → `AppSwipe.commits` / `AppSwipe.rubber` / `AppSwipe.settleFor` + `AppMotion.emphasized` (`FolderSwipe.commitFraction` testte kullanılıyor: `AppSwipe.commitFraction`a takma ad olarak KALSIN). Etiket kartı elle köşe 14, simge 16, boşluk 10 / 8 / 5 (`:1436-1500`). Fiskeyle (eşik aşılmadan) geçişte titreşim yok (`AppHaptics.tick` yalnız `_past` değişince, `:1363-1366`). Geçişin kendisi `dashboard_screen.dart:1931-1990` (`AnimatedSwitcher`, `_continueSwipe` `:359-371`) — DOKUNMA (2026-11-06 "akan geçiş" isteği, bütçe S23).
- Liste görünümünde `Dismissible` (`dashboard_widgets.dart:1632-1660`): arşiv zemini `tertiaryContainer` (rol ihlali: tertiary yalnız yapay zekâ) → güvenli seçenek `surfaceContainerHighest` + "Sabah bakılacak"; elle `FontWeight.w600`, simge 20, boşluk 8 / 20.
- Takvim ajandasındaki mini ay `MonthGrid` (`month_grid.dart:62-70`): yalnız `primaryVelocity` ±200, parmağı İZLEMEZ, ay "pat" diye değişir. Hücre boyu sabit 44 dp × 6 satır = 264 dp (`month_grid.dart:114, 184`) → hedef: gün satırlarını `PageView` (takvimin öbür görünümleri gibi — `_PagedView`, `calendar_screen.dart:904-968`; `PageScrollPhysics` / kapalıyken `NeverScrollableScrollPhysics`, `calendarSwipeProvider`), hafta günü başlığı sabit kalır; `busy` kümesi komşu ayları da kapsasın (`calendar_screen.dart:826-831` aralığı genişlet); dışarıdan ay değişince (`onMonthChange`, başlık okları) `didUpdateWidget` → `animateToPage`. Elle eğri: `Curves.easeOutCubic` `calendar_screen.dart:942, 1731, 884` → `AppMotion.emphasized`.
- Aynı yerde **boy animasyonu**: telefonda mini ay `AnimatedSize` ile açılıyor, altında `Expanded(list)` (`calendar_screen.dart:882-887`) → tek adım + yalnız boyama (S35).
- Çerçeve (`app_frame.dart`): tam ekrandan çıkış `_exitPull > 56 || v > 300` (`:393-394`), çekmece `v > 200 || value > 0.4` (`:418-420`), süre elle 220 ms (`:288`), eğri `Curves.easeOutCubic` (`:432`) → `AppSwipe.flingVelocity` / `AppSwipe.commits(extent: 240)` / `AppMotion` belirteçleri. Bölme ayracı (`split_shell.dart:830-834`) doğrudan izliyor — dokunma.
- Çit içi (DOKUNMA): `pen_tray.dart:633`, `pinned_side.dart:116`, `page_swipe.dart`, görüntüleyici `PageView`leri.
- Testler: `test/home_gestures_test.dart`, `swipe_stops_test.dart`, `calendar_screen_test.dart` (`MonthGrid` bulucuları `:265-282`), `perf_budget` S22 / S23.

**§7 Kasma — bulunan riskler:** B8 (`_PendingUploadsBar` `AnimatedSize`), takvim mini ay `AnimatedSize`, ayarlarda `_StaggeredRows` yayması KORUNACAK (`settings_area.dart:600-656`: ilk karede 2 satır, sonra kare başına 1), bildirim şeridi `child`ı kurmaz (yalnız `_NoticeLane`), `app.dart`a `MediaQuery.of` eklenmez. `kasma-kontrol` 8 maddesi her yüzey için tabloya dökülecek.

**§8 Paket taslağı (dosya kümeleri ayrık; ayar bölümleri `settings_screen.dart`ın `part`ları — aynı kitaplık, ayrı dosya):**
- PA1 (Opus high, ÖNCE): ayar satır dili — `settings_area.dart`, `settings_screen.dart` (+ S29).
- PA2 (Opus): hesap — `account_sheet.dart`, yeni `account_identity_card.dart`, `settings_account.dart`, `sign_out_actions.dart` (+ S30). PA1'den sonra.
- PA3 (Sonnet): öbür alanlar — `settings_ai / appearance / switches / voice / writing.dart`, `notes_settings.dart`, `theme_picker.dart`, `typing_bar_settings.dart`, `app_lock.dart`. PA1'den sonra, PA2 ile paralel.
- PA4 (Sonnet): yan ekranlar — `premium_screen`, `privacy_screen`, `guide_screen`, `friends_screen`, `account_required`, `backup_ui`. Bağımsız.
- PA5 (Opus high): bildirim hunisi — `tips.dart`, `undo_snackbar.dart`, `app.dart`, `release_notes_toast.dart`, `line_task_chip.dart`, `gmail_screen.dart`, `duplicates_sheet.dart`, `drive_ui.dart` (yalnız `hideMessage`), `quick_add_actions.dart`, testler + mandal (+ S31). Bağımsız.
- PA6 (Sonnet): kalıcı şeritler — `app_banner.dart` (`detail`), `app_update.dart`, `due_banner.dart`, `drive_ui.dart` (şerit), `dashboard_widgets.dart` (`_PendingUploadsBar`) (+ S32). PA5'ten sonra (`app_update.dart`, `drive_ui.dart` ortak).
- PA7 (Opus high, cihaz A/B): ana ekran kaydırma — `dashboard_widgets.dart` (`FolderSwipe`, `Dismissible`), `app_frame.dart` (+ S33). PA6'dan sonra (`dashboard_widgets.dart` ortak).
- PA8 (Opus high): takvim mini ay — `month_grid.dart`, `calendar_screen.dart` (+ S34, S35). Bağımsız.
- PA9 (Sonnet, P63 birleşince): çitte kalan 9 `showSnackBar` + 3 `hideCurrentSnackBar`, mandal 0.
`dashboard_screen.dart`a yalnız PA5 dokunur (`:1131`). P63 de `dashboard_*` / `app.dart`a dokunabilir — sırayla birleştir.
