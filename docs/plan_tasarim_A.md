# Görsel tasarım A — plan (P62)

**Durum:** YARIM (2026-11-14, Fable limit): §0–§7 + iskelet yazıldı; §8 paketler YAZILMADI — kanıt ve paket taslağı dosyanın sonundaki "YARIM" bölümünde. Uygulama YAPILMADI.
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
- Bütçe: §7 S29 (alan açılışı), S36 (geniş ekranda kategori değişimi).

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

Tur `hesap-levhasi` (üç boyut, açık/koyu, yazı 1.3): kesik metin yok; elle değer sıfır; `test/account_sheet*_test.dart` ve `sign_out` testleri yeşil; bütçe §7 S30 (levha açılırken ana ekran kartı kurulmaz).

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
- Bütçe §7 S31 / S32: bildirim göster / kaldır ana ekranı kurmaz; şerit belirince ızgara boy karesi ≤ 1.

## 6. Sağa-sola kaydırma hissi / animasyonu

### 6.1 Mevcut durum (kanıt)

Çit dışındaki bütün yana çekişler tarandı (`onHorizontalDrag*`, `PageView`, `Dismissible`; 2026-11-14): ana ekran `FolderSwipe`, liste satırı `Dismissible`, takvim mini ayı, takvim dönem sayfaları, geniş ekran çerçevesi (çekmece + tam ekrandan çıkış), bölme ayracı. Ortak karar kuralı iskelette hazır (`AppSwipe`, `lib/app/theme/app_design.dart:75-116`) ama HİÇBİR yüzey onu kullanmıyor.

| # | Bulgu | Kanıt |
|---|---|---|
| K1 | Ana ekran ızgarası parmağı ZATEN izliyor (tek `Transform`, etiket + dolum çubuğu) — iskelet doğru. Karar sayıları elle ve `AppSwipe` ile iki kopya: eşik `0.22`, fiske `300`, lastik `0.25`, sınır `_width * 0.4`, etiket eni `_width * 0.36` | `dashboard_widgets.dart:1273`, `:1370`, `:1356`, `:1354`, `:1351` |
| K2 | Geri oturma süresi SABİT 200 ms + `standard`: 20 dp'lik çekiş de 160 dp'lik çekiş de aynı sürede döner, bırakış hızı hesaba katılmaz. **Hipotez** (koddan çıkarım, cihazda bakılmadı): kısa çekişte "ağır", hızlı bırakışta "kopuk" his | `dashboard_widgets.dart:1389-1392` |
| K3 | Titreşim yalnız eşik aşılınca (`_past` değişimi). Eşiği aşmadan FİSKEYLE geçişte titreşim yok — aynı geçiş iki ayrı his veriyor | `dashboard_widgets.dart:1363-1366` ↔ `:1370-1371` |
| K4 | Etiket kartı tek karede belirir / kaybolur (`if (label != null)`), eşikte rengi tek karede değişir; elle değerler: köşe 14, dolgu 10 / 8, kenar payı 12, simge 16, boşluk 5, çubuk 3 dp, yazı `labelLarge` | `dashboard_widgets.dart:1424`, `:1437-1438`, `:1443-1444`, `:1428-1429`, `:1457`, `:1483`, `:1490`, `:1495`, `:1471` |
| K5 | Liste görünümünde satır çekişi (`Dismissible`): arşiv zemini `tertiaryContainer` (rol ihlali: `tertiary` yalnız yapay zekâ); eşikte (%35) titreşim yok; elle `FontWeight.w600`, simge 20, boşluk 8 / 20, kenar 8 / 1 | `dashboard_widgets.dart:1632-1660`, `:1651`, `:1636-1639`, `:1627`, `:1623-1624`, `:1613-1614` |
| K6 | Takvim ajandasındaki mini ay parmağı İZLEMEZ: yalnız bırakış hızına bakar (±200), ay "pat" diye değişir. Takvimin öbür görünümleri (`_PagedView`, `PageView`) izliyor — aynı ekranda iki ayrı his | `month_grid.dart:62-70` ↔ `calendar_screen.dart:904-968` |
| K7 | Telefonda mini ay `AnimatedSize` ile açılıp kapanıyor, altında `Expanded(list)`: açılış / kapanış boyunca ajanda listesi HER KAREDE yeniden diziliyor (boy animasyonu yasağı) | `calendar_screen.dart:883-888`, `:896` |
| K8 | Takvimde elle eğri: `Curves.easeOutCubic` (ay ızgarası boyu, sayfa çevirme, gün sayfası adımı) | `calendar_screen.dart:885`, `:942`, `:1728` |
| K9 | Geniş ekran çerçevesi: tam ekrandan çıkış `_exitPull > 56` ya da hız `300`; çekmece hız `200` ya da `value > 0.4`; çekmece eni `240` iki yerde elle; süre elle 220 ms; eğri `Curves.easeOutCubic` | `app_frame.dart:394`, `:419-420`, `:414`, `:288`, `:432` |
| K10 | İyi olan, DOKUNULMAYACAK: ana ekranın "akan geçişi" (`AnimatedSwitcher` + `_continueSwipe`), takvim dönem sayfaları, bölme ayracı (doğrudan izliyor), kıstırma geçişi | `dashboard_screen.dart:1931-1990`, `:360-372`; `calendar_screen.dart:711-719`, `:960-967`, `:770-773`; `split_shell.dart:830-834` |

Düzeltme (YARIM notundaki yanlış): `FolderSwipe.commitFraction` testlerde KULLANILMIYOR (`@visibleForTesting` ama tek kullanım `dashboard_widgets.dart:1360, 1362`; `test/home_gestures_test.dart` yalnız davranışı sınar) → takma ad gerekmez, sabit silinir.

`istek_tara` (uyulacak): "akan geçiş" — hızlı geçişte takılma olmasın (2026-11-06, `dashboard_widgets.dart:1255`); etikette DOLUM ÇUBUĞU (2026-11-09, `:1291`); liste satırında sağa çek = sabitle, sola çek = arşivle, geri alınabilir (2026-09-23, `:1573`); takvimde sayfa çevirince SEÇİM DEĞİŞMEZ (2026-11-08, `calendar_screen.dart:722`); telefonda ‹ › okları kalır (2026-11-07, `:539`, Y13); güne dokununca gün sayfası (2026-11-07, `:207`); çekmece (2026-11-02, `app_frame.dart:261`). `month_grid.dart`ta kullanıcı isteği yorumu yok. Hiçbiri tersine çevrilmiyor: jestlerin NE yaptığı aynı, yalnız his.

### 6.2 Hedef: tek karar kuralı, dört yüzey

**Kural:** yana çekişte "geçer mi" kararı `AppSwipe.commits`ten, durak yokken direnç `AppSwipe.rubber`dan, bırakıştan sonraki oturma `AppSwipe.settleFor` + `AppMotion.emphasized`ten gelir. İçerik parmağı İZLER (yalnız `Transform` / kaydırma konumu — dizilim yok). Bırakışta ya geçer ya döner; ortada kalmaz. Geçiş kararı anında tek hafif titreşim (`AppHaptics.tick`).

| Yüzey | İzleme | Karar | Oturma | Titreşim | Değişen |
|---|---|---|---|---|---|
| Ana ekran (`FolderSwipe`) | var (aynen) | `AppSwipe.commits(dragged: _raw, extent: _width, velocity)` | geri dönüş `AppSwipe.settleFor(distance: _dx.value, velocity)` + `emphasized` | eşikte (aynen) + fiskeyle geçişte | sayılar belirtece, geri dönüş süresi, etiket kılığı |
| Liste satırı (`Dismissible`) | var (çerçeveninki) | %35 (aynen — yanlışlıkla arşiv olmasın) | çerçeveninki | eşik aşılınca (`onUpdate`: `reached && !previousReached`) | titreşim, arşiv zemini, belirteçler |
| Takvim mini ayı (`MonthGrid`) | YENİ: `PageView` | `PageScrollPhysics` (takvimin öbür sayfalarıyla aynı) | `PageView` | yok (öbür takvim sayfalarında da yok) | parmağı izler; aç / kapa boyamada |
| Çerçeve (çekmece, tam ekrandan çıkış) | çekmece var; çıkış yok (BİLEREK) | `AppSwipe.commits(extent: çekmece eni)` | denetleyici (aynen, kalan yolla orantılı) | çıkışta `heavy` (aynen) | yalnız belirteçler |

**Ana ekran — `FolderSwipe` (`dashboard_widgets.dart:1243-1529`):**
- `_follow`: `_raw * 0.25` → `_raw * AppSwipe.rubber`; eşik hesapları `FolderSwipe.commitFraction` → `AppSwipe.commitFraction` (sınıftaki sabit silinir). Sınır `_width * 0.4` ve etiket eni `_width * 0.36` düzen oranıdır: dosya içi adlı sabit (`_kFollowLimit`, `_kLabelWidth`), belirteç değil.
- `_finish`: `final commit = _label != null && AppSwipe.commits(dragged: _raw, extent: _width, velocity: velocity);` — bugünkü `_past || fling` ile aynı sonuç (aynı sayılar). `_past` durumu etiket rengi için KALIR.
- Fiskeyle geçiş: `commit && !_past` ise `AppHaptics.tick()` (`_past` sıfırlanmadan önce oku).
- Geri dönüş: `_dx.animateTo(0, duration: AppSwipe.settleFor(distance: _dx.value, velocity: velocity), curve: AppMotion.emphasized)`. "Hareketi azalt"ta `_dx` zaten 0 (`:1357`).
- Yerinde geçiş dalı (`continuesInPlace` true → `_dx.value = 0`, `:1380-1387`) AYNEN: ayrılan görünümü `dashboard_screen` sürdürür (2026-11-06).
- Etiket kartı: `AppSurface.paper` kılığı (zemin `tokens.card` + `hairline`), köşe `AppRadius.m`, dolgu `AppSpace.m` / `AppSpace.s`, kenar payı `AppSpace.m`, simge `AppIconSize.xs`, yazı `AppText.label`, çubuk üstü boşluk `AppSpace.xs`. Eşik aşılınca zemin `primaryContainer` (aynen) ama renk `AppMotion.selection` ile solar (§1 "seçim"; `ColorFade` ya da yalnız renk taşıyan `AnimatedContainer` — boy / dolgu sabit). Beliriş: kart `_progress`e bağlı solar (`Opacity`, `(p * 2).clamp(0, 1)` — çekişin ilk yarısında tam görünür olur); ayrı denetleyici YOK, `_progress` dinleyicisi zaten var (`:1496`).
- Dolum çubuğu (`swipe-progress`), `swipe-next-label` anahtarı, tekerlek zamanlayıcıları (160 / 240 ms — hareket süresi değil, sessizlik eşiği; `:1319`, `:1327`) AYNEN.

**Liste satırı — `_SwipeActions` (`dashboard_widgets.dart:1585-1665`):**
- `Dismissible`e `onUpdate: (d) { if (d.reached && !d.previousReached) unawaited(AppHaptics.tick()); }`.
- Arşiv zemini `tertiaryContainer` → `surfaceContainerHighest` / `onSurface` (**Sabah bakılacak**, K6-1). Sabitle zemini `secondaryContainer` AYNEN.
- Zemin etiketi: `AppText.label` + `AppWeight.strong`, simge `AppIconSize.m`, boşluklar `AppSpace.s` / `AppSpace.xl`, kenar `AppSpace.s`.
- `dismissThresholds` %35, `confirmDismiss` false kalıbı, `ValueKey('swipe-<id>')` AYNEN.

**Takvim mini ayı — `MonthGrid` (`month_grid.dart`):**
- `StatelessWidget` → `StatefulWidget` + `PageController(initialPage: monthIndexOf(widget.month))`. Hafta günü başlığı ve (geniş ekrandaki) ay başlığı SABİT kalır; yalnız altı gün satırı `SizedBox(height: 6 × hücre boyu)` içinde `PageView.builder(itemCount: kMonthPages)` olur — sayfa = `monthAtIndex(i)` (`calendar_views.dart:60-70`; yeni dizin hesabı YAZMA).
- `physics`: `swipeEnabled ? PageScrollPhysics() : NeverScrollableScrollPhysics()` (`calendarSwipeProvider`, `_PagedView` ile aynı, `calendar_screen.dart:962-964`). `allowImplicitScrolling` varsayılan (false) kalır: komşu ay yalnız çekiş başlayınca kurulur.
- Ay bildirimi MUTLAK olur: `onMonthChange(int delta)` → `onMonthChanged(DateTime month)`; `onPageChanged: (i) => widget.onMonthChanged(monthAtIndex(i))`; çağıran `setState(() => _month = month)`. (Delta ile programlı çok sayfalı geçişte ara sayfalar yanlış ay üretirdi; mutlak bildirim kendiliğinden tutarlı.)
- Dışarıdan ay değişince (gri güne dokunuş, "Bugün", başlık okları): `didUpdateWidget`ta `monthIndexOf(widget.month) != _controller.page?.round()` ise `_PagedView.animateToPage` kuralı (`calendar_screen.dart:931-946`): fark > 3 → `jumpToPage`, değilse `animateToPage(duration: AppMotion.of(context, AppMotion.medium), curve: AppMotion.emphasized)`. Geniş ekrandaki ‹ › okları doğrudan denetleyiciyi sürer.
- Dolu gün noktaları: `busy: Set<String>` → `busyOf: Set<String> Function(DateTime month)`; sayfa KURULURKEN bir kez çağrılır (hücre başına değil — sınıf notundaki "hücre başına sağlayıcı yok" kuralı korunur). Çağıran bugünkü hesabı (`calendar_screen.dart:824-831`) aya göre işleve çevirir.
- Seçim DEĞİŞMEZ (2026-11-08): sayfa çevirmek yalnız `_month`u değiştirir.
- Hücre: `InkResponse(radius: 22)` / 44 / 32 / 1.5 / `alpha: 0.55` → hücre boyu dosya içi tek sabit (iki yerde yazılmasın), saydamlık `AppAlpha`, yazı `AppText.meta` (başlık) — `token_sayim` düşer.
- Elle eğriler `calendar_screen.dart:942`, `:1728` → `AppMotion.emphasized` (aynı eğri, görünüş değişmez). `:772-773` (kıstırma geçişi: `easeOutCubic` / `easeInCubic`) DOKUNMA — çıkış eğrisinin belirteç karşılığı farklı.

**Mini ay aç / kapa (telefon; `calendar_screen.dart:881-898`):** boy TEK ADIMDA, hareket boyamada.
- `Column[AnimatedSize(grid), Divider, BackCloses, Expanded(list)]` → `Stack`: altta ızgara + ayraç (üste yaslı; yalnız açıkken ve kapanış sürerken ağaçta), üstte opak zeminli liste (`Positioned.fill(top: açık ve oturmuş ? ızgara boyu : 0)` içinde `Transform.translate`).
- Açılış: ızgara listenin ALTINDA kurulur ve ölçülür (liste boyu değişmez) → sonraki karede liste `Transform` ile ızgara boyu kadar aşağı kayar (`AppMotion.short` + `AppMotion.enter`) → animasyon bitince liste üst payı ızgara boyu olur, öteleme 0 (liste boyu BİR kez değişir; üst kenarı aynı pikselde, sıçrama görünmez).
- Kapanış: liste üst payı hemen 0 (boy BİR kez değişir), öteleme ızgara boyundan 0'a (`exitOf(short)` + `AppMotion.exit`); bitince ızgara ağaçtan düşer.
- Izgara boyu ölçülür (`GlobalKey` → `context.size`, hafta günü satırı yazı ölçeğine bağlı); animasyon içerik kurulduktan SONRAKİ karede başlar (`ExpandReveal` kalıbı, `expand_reveal.dart:68-75`).
- "Hareketi azalt": öteleme yok, tek adım.
- `ValueKey('calendar-month-toggle')`, `BackCloses`, güne dokununca kapanma (`:837`) AYNEN; kapalıyken `MonthGrid` ağaçta YOK (`calendar_screen_test.dart:265, 271`).
- Geniş ekran (`:872-879`) düzeni aynen (ızgara hep açık).

**Çerçeve (`app_frame.dart`):** his değişmez, yalnız sayılar tek kaynağa bağlanır.
- Çekmece eni `240` → dosya içi tek sabit (`:414` ve çekmecenin kendi genişliği).
- Çekmece bırakışı: `AppSwipe.commits(dragged: _drawer.value * en, extent: en, velocity: rtl ? -v : v)` (**Sabah bakılacak** K6-3: eşik %40 → %22, fiske 200 → 300).
- Tam ekrandan çıkış: `AppSwipe.commits(dragged: _exitPull, extent: en, velocity: rtl ? -v : v)` (56 dp → 52,8 dp; fark hissedilmez — **hipotez**). Parmağı izletme: çıkış bölme düzenini değiştirir (dizilim), izletmek her karede dizilim demek — YAPILMAZ.
- `Duration(milliseconds: 220)` → `AppMotion.short`; `Curves.easeOutCubic.transform` → `AppMotion.emphasized.transform`.
- Bölme ayracı (`split_shell.dart`) DOKUNMA.

### 6.3 Tuzaklar

- `FolderSwipe`in `setState`i yalnız kendi `build`ini çalıştırır; `widget.child` aynı örnek kaldıkça ızgara kurulmaz. Etikete eklenen her şey `Stack`in ikinci çocuğunda kalsın; `child`ı SARMA (yeni `Opacity` / `ClipRect` ızgaranın üstüne gelirse kart boyaması katman değiştirir — S23 / S33).
- Etiket `Opacity`si `_progress` dinleyicisinin İÇİNDE olsun (çekiş karesinde `FolderSwipe` kurulmaz, yalnız etiket boyanır).
- `S23` (fiskeyle geçiş) sayıları DEĞİŞMEMELİ: `_finish`in geçiş dalına kurulum ekleme.
- `PageView` komşu ayı çekiş başlarken kurar: `busyOf` o karede bir kez `buildAgenda` çalıştırır (42 gün). Aynı sayfa için her yeniden kurulumda yeniden hesaplanır (bugünkü maliyetle aynı); önbellek EKLEME, ölç (S34).
- `MonthGrid` geniş ekranda `SingleChildScrollView` içinde (`calendar_screen.dart:875`): `PageView`in boyu sabit `SizedBox` ile verilmezse "sınırsız yükseklik" hatası.
- `calendar_screen_test.dart:269` güne `find.text('20')` ile dokunuyor: komşu ay sayfası önceden kurulursa iki "20" bulunur — `allowImplicitScrolling` açma.
- Mini ay `Stack`inde listenin anahtarı ve ağaçtaki yeri iki durumda da AYNI kalmalı (`_AgendaList` kaydırma konumu; kasma listesi md. 4): ızgarayı koşulla ekle / çıkar ama listeyi sarmalayan zincir (`Positioned` → `Transform` → zemin → liste) değişmesin.
- Açılışta ızgara bir kare listenin altında durur: liste zemini OPAK olmalı (`ColoredBox(scaffoldBackgroundColor)`), yoksa ilk karede ızgara listenin içinden görünür.
- `app_frame.dart` kabuk dosyası: `MediaQuery.of(` mandalı 1 (`jank_patterns_guard_test.dart:33`) — yeni `MediaQuery.of` ekleme.
- `_exitPull` yöne göre düzeltilmiş (ileri = artı), `primaryVelocity` fiziksel: `commits`e hız `rtl ? -v : v` olarak ver.

### 6.4 Sabah bakılacak (zevk; güvenli seçenek uygulanır)

- **K6-1** Liste satırında arşiv çekişinin zemini nötr (`surfaceContainerHighest`); bugün `tertiaryContainer` (yapay zekâ rengi). Sabitle zemini değişmez.
- **K6-2** Telefonda mini ay açılırken liste aşağı KAYAR (boyamada); alternatif: tek adımda belirme + solma.
- **K6-3** Tablet çekmecesi %22 çekişte açılır (bugün %40), fiske eşiği 300 (bugün 200) — bütün yana çekişler aynı sayıda.
- **K6-4** Ana ekranda fiskeyle geçişte de hafif titreşim (bugün yalnız yavaş çekip eşiği aşınca).

### 6.5 Kabul ölçütleri

- `test/home_gestures_test.dart` "FolderSwipe" grubu AYNEN yeşil (izleme, yerinde geçiş, eşik altı dönüş, kısa fiske, lastik, sağdan sola, kapalı); eklenir: "fiskeyle geçişte titreşim bir kez", "kısa çekişin dönüş süresi uzun çekişinkinden kısa" (`AppSwipe.settleFor` üzerinden; önce kırmızı).
- `test/app_design_test.dart` (yoksa yaz): `AppSwipe.commits` / `settleFor` sınırları (0 çekiş, ters yönde fiske, alt / üst süre).
- `test/calendar_screen_test.dart` eklenir (önce kırmızı): mini ay parmağı izler (bırakmadan 100 dp çekişte komşu ayın günü görünür); yarıdan az çekip bırakınca aynı ay; fiske → başlık sonraki ay ve SEÇİM değişmez; kaydırma ayarı kapalıyken sayfa kaymaz; geniş ekranda ‹ › animasyonla geçer. Var olan `:259-283` testleri yeşil.
- Bütçe §7: S33 (ana ekran çekişi), S34 (mini ay kaydırma), S35 (mini ay aç / kapa); S22 ve S23 sayıları değişmez.
- `token_sayim`: `FolderSwipe`, `_SwipeActions`, `month_grid.dart`, `app_frame.dart`ın dokunulan satırlarında elle köşe / punto / ağırlık / süre / eğri SIFIR; `calendar_screen.dart`ta `Curves.` 5 → 2 (kalan: kıstırma geçişi).
- Hareket turla görülmez (tur durağan kare çeker): `KONTROL_LISTEM.md` "Telefonda bak"a üç madde — ana ekranda yana çekiş (yavaş / fiske / durak yokken), liste satırı çekişi, takvim ajandasında mini ay (kaydır, aç / kapa); tablette çekmece. Cihaz A/B: §7.4.

## 7. Kasma: riskler, kontrol listesi, bütçe senaryoları

Kural (HIZ SÖZLEŞMESİ): dokunulan her yüzeyin cihazsız bütçe senaryosu `test/perf_budget_test.dart`ta olmalı; mandallar (`test/perf_budget/budgets.json`, `test/design_tokens/budget.json`) yalnız DÜŞER; ölçmeden "akıcı" denmez. P62'nin numaraları **S29–S39** (S28 boş: kalem ucu tahmini çıkarıldı; P63: S40–S44).

### 7.1 Bulunan riskler (kanıt)

| # | Risk | Kanıt | Önlem / senaryo |
|---|---|---|---|
| R1 | Bekleyen ekler şeridi `AnimatedSize` (200 ms), ana ekranın SABİT başlık sütununda; altında `Expanded` ızgara → şerit belirirken / kalkarken ızgara her karede yeniden dizilir (B8) | `dashboard_widgets.dart:1721-1723`; `dashboard_screen.dart:1842-1855, 1885` | `AnimatedSize` kalkar (§5.4) · S32 |
| R2 | Takvimde mini ay `AnimatedSize`, altında `Expanded(list)` → ajanda her karede yeniden dizilir (K7) | `calendar_screen.dart:883-888`, `:896` | §6.2 "aç / kapa" · S35 |
| R3 | Ayar alanı TEK karede kurulursa 2026-10-20 kasması geri gelir. Bugün satırlar karelere yayılıyor: ilk karede 2 satır, sonra kare başına 1. Grup kartı düzeni (§2.3) bu yaymayı bozabilir (grup = tek widget → bütün satırları aynı karede) | `settings_area.dart:600-655` (`_first = 2`, `:620`; `_scheduleNext`, `:630-637`) | yayma SATIR bazında kalır · S29 |
| R4 | `AppNoticeHost` Navigator'ın üstünde, kökte: bildirim gösterilince `child` kurulursa bütün uygulama kurulur. İskelette `child` aynı örnek, yalnız iki `_NoticeLane` denetleyiciyi dinliyor — DOĞRU | `app_notice.dart:175-181`, `:193-194` | S31 `kart_kurulum` / `dashboard_kurulum` = 0 |
| R5 | İki `_NoticeLane`, şerit BOŞKEN de `MediaQuery.viewInsetsOf` / `paddingOf` okuyor → klavye açılıp kapanırken her inset karesinde ikisi de kurulur (`Positioned` + `Align` + `ConstrainedBox` + `AnimatedSwitcher`). Okuma koşulsuz: kod gerçeği; maliyetin ölçüde görünüp görünmediği **hipotez** (ölçülmedi) | `app_notice.dart:202-205`, `:211-217` | PA5: inset okuması yalnız bildirim VARKEN kurulan küçük öğeye iner · S31 `klavye_karesi_kurulum` · cihazda `klavye` evresi |
| R6 | `app.dart` ve `app_frame.dart` kabuk dosyaları: `MediaQuery.of(` mandalı 1'er | `jank_patterns_guard_test.dart:32-33` | şerit / çerçeve işinde `MediaQuery.of` EKLEME (`viewInsetsOf` / `sizeOf`, ayrı küçük öğe) |
| R7 | §1 "seçim" hareketi `AnimatedContainer` ile yazılırsa boy / dolgu da animasyona girebilir (kasma listesi md. 6). Bekçi yalnız editör kökünü sayıyor | `jank_patterns_guard_test.dart:41-46`, `:84` | seçimde `ColorFade` (`lib/core/widgets/color_fade.dart`) ya da `AnimatedContainer`a YALNIZ `color` / `decoration` ver; §7.5 mandalı |
| R8 | Hesap levhasında avatar fotoğrafı `frameBuilder` ile solarken ya da karoya `PressScale` eklenirken ana ekrana `setState` sızarsa altta 30 kart kurulur | `account_sheet.dart:102-118` (levha kendi `Consumer`ında) | S30 `kart_kurulum` = 0 |
| R9 | Ana ekran çekişinde etikete eklenen solma / renk geçişi `FolderSwipe.child`ı sararsa ızgara her karede boyanır / kurulur | `dashboard_widgets.dart:1416-1423` (tek `Transform`, `child` aynı örnek) | §6.3 · S33; S23 değişmez |
| R10 | Mini ay `PageView`i komşu ayı çekiş başlarken kurar (42 hücre + bir `buildAgenda`) | `month_grid.dart:114-141`; `calendar_views.dart:44-53` | S34 |
| R11 | İpucu göçü: `_pumpHome` şeritsiz kurar → `TipOnce.show` false döner; soğuk açılış / kaydırma sayıları değişirse neden yazılır, mandal yükseltilmez | `perf_budget_test.dart:295-310` (`TipOnce.resetSession`) | S13 / S24 değişmez |

### 7.2 Kasma kontrol listesi (`kasma-kontrol` skill'i, 8 madde) — yüzey yüzey

P62 editöre ve kart ızgarasının HÜCRESİNE dokunmaz; md. 1 (madde alanı karşılaştırmaları), md. 2 (satır önbelleği), md. 5 (satır `identical` testi) hiçbir pakette uygulanmaz. Kalanlar:

| Yüzey (paket) | md. 3 yerel durum kökte değil | md. 4 ağaç şekli sabit | md. 6 boy animasyonu yok | md. 7 `MediaQuery.of` / söküp takma | md. 8 bütçe |
|---|---|---|---|---|---|
| Ayar alanları (PA1, PA3) | seçili kategori ve arama `SettingsScreen` durumunda (bugünkü gibi); yeni durum ekleme | grup kartı satır eklenirken aynı kart kalır (anahtar = grup adı) | tek izinli: `ExpandReveal` (var); seçim yalnız renk | `sizeOf` (bugün `settings_screen.dart:741`) | S29, S36 |
| Hesap levhası, Hesap sayfası (PA2) | basma tepkisi `PressScale`in kendi durumu | misafir / girişli dalları aynı iskelet (`footer` null → `SizedBox.shrink`) | karo boyu sabit (`IntrinsicHeight` bir kez), rozet `PopIn` | — | S30 |
| Yan ekranlar (PA4) | — | — | yeni animasyon YOK | — | yok (durağan ekran; yeni senaryo gerekmez) |
| Bildirim şeridi (PA5) | denetleyici (`ChangeNotifier`) + dar `ListenableBuilder` | iki şerit hep ağaçta; boşken `SizedBox.shrink` | solma + ¼ kayma (boyama) | R5, R6 | S31; S13 / S24 değişmez |
| Kalıcı şeritler (PA6) | her şerit kendi `Consumer`ı (bugünkü gibi) | şerit yokken `SizedBox.shrink` (sütundaki yeri aynı) | R1: görünür / gizli TEK adım | — | S32 |
| Ana ekran çekişi, çerçeve (PA7) | `_progress` bildiricisi, `FolderSwipe` durumu | `Stack` çocuk sırası aynı; `child` sarılmaz | yalnız `Transform` / `Opacity` | R6 | S33; S23, S12 / S26 / S27 değişmez |
| Takvim mini ayı (PA8) | sayfa konumu `PageController`da; açık / kapalı `_monthOpen` (var) | liste zinciri iki durumda aynı (§6.3) | R2: boy bir kez, öteleme boyamada | — | S34, S35; S22 değişmez |

### 7.3 Bütçe senaryoları (S29–S39)

Sayılan şey süre değil SAYI (`BuildCounter`, `test/support/editor_harness.dart:25`; yardımcılar `_count` `:182`, `_expectBudget` `:192`, `_frames` `:399`, `_pumpHome` `:295`). "Bugün" sütunu ÖLÇÜLMEDİ — taban PA0'da ölçülür, `budgets.json`a `bugun` + `neden` ile yazılır; aşağıdaki "beklenen" değerler **hipotez**tir. Hedefi tutmayan taban mandal olarak girer, ilgili paket onu hedefe indirir.

| No | Senaryo (düzenek) | Sayılan anahtarlar | Hedef | Beklenen bugün (hipotez) | Tabanı / indiren |
|---|---|---|---|---|---|
| S29 | Ayar alanı açılışı: telefon 412 × 915, doğrudan `SettingsScreen(initialArea: 'ai')` (S22 kalıbı; `_pumpHome`da `/settings` yolu YOK), 40 kare | `ilk_kare_kurulum`, `kare_kurulum` (en ağır kare), `toplam_kurulum` | en ağır kare tabanı AŞMAZ (kılık değişikliği yaymayı bozmadı); toplam en çok grup sarmalayıcıları kadar artar, `neden`e yazılır | yayma çalışıyor: ilk kare 2 satır | PA0 / PA1 |
| S30 | Hesap levhası: `_pumpHome` telefon, 30 not; `home-account-avatar`a dokun → 30 kare → sistem geri → 30 kare (S20 kalıbı, `:1081`) | `kart_kurulum` (`NoteCard`), `dashboard_kurulum`, `kare_kurulum` | kart 0, pano 0 | 0 / 0 | PA0 / PA2 |
| S31 | Bildirim: `_pumpHome` + `AppNoticeHost` (düzeneğe `notices: true` seçeneği); ileti göster → 30 kare → kendiliğinden kalksın; ipucu göster → dokunuşla kalksın; ayrıca şerit BOŞKEN alt inset 0 → 300 → 0 (10 adım) | `kart_kurulum`, `dashboard_kurulum`, `kare_kurulum`, `klavye_karesi_kurulum` (inset karesi başına şeritten kurulan) | 0 / 0 / küçük sabit / 0 | 0 / 0 / ? / > 0 (R5) | PA0 (iskelet tabanı) / PA5 |
| S32 | Kalıcı şerit belirişi: `_pumpHome`, `pendingUploadsProvider` 0 → 2 → 0; her değişimden sonra 30 kare; ızgara kaydırma görünümünün boyunun değiştiği kare sayısı (S9 `govde_boy_karesi` kalıbı, `:598-632`) | `izgara_boy_karesi`, `kart_kurulum` | 2 (belir 1 + kalk 1) / 0 | ~24 (200 ms × 2) / 0 | PA0 / PA6 |
| S33 | Ana ekran çekişi: `_pumpHome` telefon, 30 not, `swipe_mode: filters` (S23 düzeneği); karttan 6 × 10 dp yana çek (eşik altı), bırak, 30 kare | `kart_kurulum`, `dashboard_kurulum`, `kare_kurulum` | 0 / 0 / etiket + `FolderSwipe` kadar | 0 / 0 | PA0 / PA7 |
| S34 | Mini ay kaydırma: telefon, `calendar_view: agenda`, ay açık; mini ayı bir ay ileri fırlat, 40 kare (S22 düzeneği, `:1140`) | `ay_sayfasi` (gün sayfası kurulumu), `gun_hucresi` (`_DayCell`), `kare_kurulum` | komşu ay bir kez kurulur; en ağır kare ≤ mini ayın ilk açılış karesi | bugün izleme yok: ay değişince 42 hücre tek karede | PA8 (taban PA8'in ilk commit'i: değişiklikten önce) |
| S35 | Mini ay aç → kapat: telefon ajanda; `calendar-month-toggle`a iki kez dokun, her birinden sonra 30 kare; ajanda listesinin boyunun değiştiği kare sayısı | `liste_boy_karesi`, `kare_kurulum` | 2 (aç 1 + kapa 1) | ~24 | PA0 / PA8 |
| S36 | Geniş ekran ayarlar: 1280 × 800 `SettingsScreen`; `settings-cat-ai` → `settings-cat-sound`, her birinden sonra 40 kare | `kare_kurulum`, `toplam_kurulum` | en ağır kare ≤ S29 en ağır karesi (alan değişimi de yayılır) | ? | PA0 / PA1 |
| S37–S39 | boş (yedek) — P62 içinde yeni yüzey çıkarsa buradan verilir, P63 numaralarına (S40–S44) girilmez | | | | |

Değişmemesi gereken var olan bütçeler: S13 (ana ekran kaydırma), S18 / S19 (not aç / geri), S21 (arama), S23 (yana fırlatma), S24 (soğuk açılış) — PA5, PA6, PA7; S12 / S26 / S27 (bölünmüş kabuk) — PA7 (`app_frame.dart`); S22 (hafta kaydırma) — PA8. Bir sayı YÜKSELİRSE paket durur: kök neden bulunur, mandal yükseltilmez (yükseltme yalnız `[butce]` başlığı + `neden` ile, kullanıcı kararı).

### 7.4 Cihaz ölçümü (ÖLÇÜM KAPISI) ve `[apk]` noktaları

`ab_hepsi.py`nin 13 evresi: açılış, liste, ⋮, arama, klasör (= ızgarada yana çekiş, `tool/perf/ab_hepsi.py:14, 211-212`), yeni not, not aç, klavye, yazma, kapanış, sabit PDF × 3. Ayarlar, hesap levhası ve takvim evrelerde YOK.

| Paket | Kapıya giren yüzey | Paket A/B'si | Bakılacak evre | Cihazda elle (`KONTROL_LISTEM.md`) |
|---|---|---|---|---|
| PA0 | yok (yalnız test) | hayır | — | — |
| PA1, PA2, PA3, PA4 | yok (ayarlar, levha) | hayır | — | ayar alanları arasında gezinme; hesap levhası; Hesap sayfası |
| PA5 | kök (`app.dart`): her ekranın üstünde şerit | **evet** | açılış, liste, klavye, yazma | ipucu arama hapının altında; "Geri al" "+" ile kesişmiyor; levha üstünde bildirim |
| PA6 | ana ekran başlık sütunu | **evet** | açılış, liste | şeritlerin kılığı; bekleyen ek şeridi belirirken liste titremiyor |
| PA7 | ana ekran geçişi, çerçeve | **evet** (hız hissi işi: kötüleşme SIFIR, `klasör` evresi kötüleşmez) | klasör, liste | §6.5'teki üç madde + tablette çekmece |
| PA8 | yok (takvim) | hayır | — | mini ay kaydırma + aç / kapa |
| PA9 | editör / görüntüleyici iletileri | hayır (ileti yolu; gövdeye dokunmaz) | — | — |

- Ölçümü yürütücü KENDİ yapmaz (`ab-olcum` skill'i): iki profil APK + `ab_hepsi.py <A> <B> --altin`, sonnet alt ajan; ham sayılar DEVIR'e.
- `[apk]` başına en çok 5 görünür değişiklik (F58.4) → P62 İKİ `[apk]` noktasına bölünür: **APK-1** = PA1 + PA2 + PA3 + PA4 (ayar satır dili, hesap levhası / kimlik kartı, Hesap sayfası, yan ekranlar); **APK-2** = PA5 + PA6 + PA7 + PA8 (bildirim yeri ve kılığı, kalıcı şeritler, yana çekiş, mini ay). Her `[apk]` öncesi tam ölçüm zorunlu (önceki `[apk]`ya %20, altın tabana %15); telefon yoksa birleştirme `[apk]`sız, satır `cihaz bekliyor`.
- PA5–PA7 aynı dosyalara sırayla dokunduğu için A/B üçü birleşince TEK koşuda yapılabilir (taban = APK-1); kötüleşme çıkarsa paket commit'leri ayrı olduğundan ikiye bölerek aranır.
- Telefonda bakılamayan her görünür değişiklik "yazıldı, cihazda doğrulanmadı" + `KONTROL_LISTEM.md`. **Uyarı:** listede bugün 42 açık madde var (`^- [ ]` sayımı, 2026-11-14) — F58.4 eşiği 40; P62 en az 8 madde daha ekler (yürütücü / kullanıcı kararı: önce cihaz turu).

### 7.5 Mandallar (yalnız düşer)

- `test/perf_budget/budgets.json`: S29–S36 (yukarıda).
- `test/jank_patterns_guard_test.dart`e yeni mandal "ana ekran / takvim boy animasyonu": `dashboard_widgets.dart`, `dashboard_screen.dart`, `due_banner.dart`, `app_update.dart`, `drive_ui.dart`, `app_banner.dart`, `app_notice.dart`, `calendar_screen.dart`, `month_grid.dart` içinde `AnimatedSize(` toplamı — bugün 2 (`dashboard_widgets.dart:1721`, `calendar_screen.dart:883`; ötekiler 0, sayıldı), PA6 sonrası 1, PA8 sonrası 0. Mandalı PA0 kurar (2).
- `test/notice_paths_guard_test.dart` (§5.3): PA5 kurar, PA9 sıfırlar.
- `test/design_tokens/budget.json`: her paket dokunduğu dosyadaki elle değerleri belirtece çevirip `python tool/design/token_sayim.py --json` ile DÜŞÜRÜR (§0.4). Paketler aynı dosyaya (`budget.json`) yazar — birleştirmede çakışırsa sayım yeniden üretilir, elle birleştirilmez.

---

## YARIM — §8 YAZILMADI (limit; kalanı Opus yazar). Toplanan kanıt ve verilmiş kararlar:

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
