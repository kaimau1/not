# Görsel tasarım A — plan (P62)

**Durum:** plan + iskelet yazıldı (2026-11-14, Fable). Uygulama YAPILMADI; §8'deki paketler alt modellerde (Opus/Sonnet) yürür.
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
