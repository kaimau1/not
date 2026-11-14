# Plan — Görsel tasarım B (P63)

> Kullanıcı isteği 2026-11-14: "görsel tasarım artık son kullanıcı için hazır olacak — tertemiz,
> premium, güzel animasyonlu, göze hitap eden. Kasma sorunu olmayacak."
> Kapsam (B): **1** düzenleme modu · **2** şablonlar · **3** kalem seti · **4** sesle yazmanın etkin
> menüsü · **5** madde altı çizgiler ve menüsü. (A = P62: ayarlar, hesap, ipucu/uyarı, sağa-sola
> kaydırma — ortak tasarım dili P62'de.)
>
> Bu belge PLAN + İSKELET'tir (Fable). Uygulamayı Opus/Sonnet alt ajanlar §7'deki paketlerle yapar.
> Her paket bu belgeyi ve `isci` skill'ini okuyarak, başka bağlam olmadan uygulanabilir.

## 0. Her paket için ortak kurallar (önce bunu oku)

**Bağlayıcı belgeler:** `CLAUDE.md`, `isci` skill'i, `kasma-kontrol` skill'i (8 madde), `ab-olcum`
skill'i, `docs/hafiza/arayuz.md` sonu (5 ilke + Y1–Y16 + genel yapılmayacaklar),
`docs/hafiza/akicilik.md` sonu (hız sözleşmesi), `docs/hafiza/kalem.md`, `docs/hafiza/editor.md`.

**Tasarım dili (mevcut belirteçler — `lib/app/theme/app_tokens.dart`; bu dosyaya DOKUNMA, P62'nin):**

| İş | Belirteç |
|---|---|
| Boşluk | `AppSpace.xxs 2 · xs 4 · s 8 · m 12 · l 16 · xl 20 · xxl 24 · xxxl 32` |
| Köşe | `AppRadius.hair 2 · xs 4 · s 8 · m 12 · l 16 · xl 24 · pill` |
| Simge | `AppIconSize.xs 16 · s 18 · m 20 · l 24` |
| Saydamlık | `AppAlpha.hairline .08 · pressed .12 · soft .24 · disabled .38 · muted .60 · strong .85` |
| Ağırlık | `AppWeight.regular/medium/strong` (krom en kalın w600) |
| Hareket | `AppMotion.instant 100 · quick 150 · short 200 · medium 300 · long 420`; eğri `standard/enter/exit`; HER animasyon `AppMotion.of(context, …)` + `AppMotion.curveOf` (hareketi azalt) |
| Yazı | `AppText.*(theme)` rolleri (editör/kart dosyalarında `Theme.of(context)` yasak → `_themeOf`) |

Elle ölçü YAZILMAZ (`test/design_tokens_guard_test.dart` mandalı yalnız düşer). Dokunduğun dosyadaki
eski elle değerleri (bu planda satır satır sayılanları) belirtece çevirmek paketin işidir.

**Hareket kuralları (ilke 4 + kasma 6):** giriş 200–300 ms, çıkış 2/3'ü; YALNIZ BOYAMA
(`Transform`/`FractionalTranslation`/`Opacity`/`CustomPaint`). Boy animasyonu (`AnimatedSize`,
`AnimatedContainer` boyu, `heightFactor`) editör gövdesiyle aynı Column/Row'da YASAK; boy tek adımda
değişir. Bulanıklık (`BackdropFilter`), bulanık gölge, gradyan ZEMİN, ışıltı, paralaks, zıplayan eğri
(`easeOutBack`, `elasticOut`) YOK. Sürekli dönen her animasyon kendi `RepaintBoundary`'sinde, tek
ticker + tek `CustomPaint` (örnek: `ListeningWaveform`, `listening_visuals.dart:266-347`).

**Karanlık/aydınlık:** renk yalnız `ColorScheme` + `AppTokens`'tan; sabit `Colors.black…`/hex yok
(istisna: kullanıcının seçtiği mürekkep/çizgi rengi ve şablon vurgu renkleri). Her yeni yüzey
`TOUR_DARK=1` turunda da çekilir.

**Boyutlar:** telefon 360–412 dp, tablet dikey 800, yatay 1024–1280 (ray + bölünmüş), web 1440.
Levhalar `showAppSheet` ile açılır (`useSafeArea` varsayılanı true — argüman yazma), geniş ekranda
`constraints: BoxConstraints(maxWidth: 640)`.

**Dokunulmayacak kimlikler:** `UiItem.*`, `menuId`, `ValueKey` adları DEĞİŞMEZ (testler ve kayıtlı
tercihler bağlı). Yeni öğe yeni kimlik alır.

**Doğrulama:** ilgili test `--reporter failures-only` + `flutter analyze` (tam) → push → CI yeşil.
Her paket: (a) dokunduğu yüzeyin bütçe senaryosu `test/perf_budget_test.dart`'ta (aşağıda S40–S44
tanımlı; P62 S30–S39'u kullanır, S28 boş kalmıştır), (b) `tool/tour/screen_tour_test.dart`'a yüzeyin
görüntüsü (bugün tur bu beş yüzeyin HİÇBİRİNİ çekmiyor: `screen_tour_test.dart:656-676` yalnız
`ana`, `n1…n4`, `n1-menu`, `n4-ekle`, `n4-ai`, `n4-bicim`, `ana-menu`, `ana-hizli`, `n4-paylas`),
(c) `istek_tara.py` çıktısındaki istekler bozulmadı, (d) Cihaz=A/B yazan pakette `ab-olcum`.
`[apk]` başına en çok 5 görünür değişiklik (F58.4) — paketler buna göre bölündü.

**P62 ortak belirteçleri** (§8): yoksa paket, dosyanın başında `// P62 belirteci gelince değiştir`
notlu GEÇİCİ YEREL SABİT kullanır; `app_tokens.dart`'a ekleme yapmaz.

---

## 1. Düzenleme modu

### 1.1 Mevcut durum (kanıt)

Düzenek: `lib/core/personalize.dart` (`UiPrefs`, `UiItem`, `Personalize`), sarmalayıcı
`lib/core/widgets/customizable.dart` (`Customizable`, `CustomizeFrame`, `CustomizeModeHost`,
`_CustomizeStrip`), ayar ekranı `lib/features/settings/presentation/personalize_screen.dart`.
Mod girişi yalnız iki yerden: Ayarlar → Kişiselleştir kartı (`personalize_screen.dart:200`) ve not ⋮ →
"customize" (`note_editor_actions.dart:493-497`); ana ekran ⋮ yalnız ayar ekranına götürür
(`dashboard_menu.dart:118,156`).

**Kök bulgu — aynı iş için BEŞ ayrı düzenleme arayüzü var (ilke 3 ihlali):**

| # | Arayüz | Ne yapar | Kanıt |
|---|---|---|---|
| a | Yerinde mod: çerçeve + göz rozeti | yalnız gizle/göster | `customizable.dart:57-73, 78-147` |
| b | Menünün kendi "Düzenle"si (`MenuLayouts`) | gizle + sırala + hızlı satır, `ReorderableListView` | `action_menu_sheet.dart:560-702`, `core/menu_layout.dart` |
| c | Hızlı satır düzenleyici (karolar, "Menüde/Eklenebilir") | gizle/göster; SIRA YOK | `quick_row_editor.dart:111-265` |
| d | Alt/üst çubuk listesi (ayarlar) | sırala + gizle + kapsül değiştir | `personalize_bar_list.dart:23-232` |
| e | "+" paneli kendi sıralaması | gizle + sırala | `quick_add_fab.dart:595-721` |

**Düzenlenemeyenler / eksikler (envanter):**

| Öğe | Bugün | Kanıt | Karar |
|---|---|---|---|
| Hızlı satır düğme SIRASI | katalog sırası sabit | `quick_row_editor.dart:122-126` (`shown` katalogdan süzülür); `UiPrefs`'te alan yok (`personalize.dart:39-46`) | **YAP**: `UiPrefs.quickOrder` |
| Ekle levhası SIRASI | yalnız gizle/göster | `attach_sheet.dart:63-69, 133` | **YAP**: `UiPrefs.attachOrder` |
| Video denetimi: hız, süre | yalnız Ayarlar'daki çip; yerinde sarma yok | `video_transport.dart:162, 203` (`prefs.shows`), `personalize_screen.dart:606-611` | **YAP**: `Customizable` ile sar |
| Ortak çalışan düğmesi | yerinde sarma yok | `note_editor_screen.dart:3428` (`Customizable.shows`) | **YAP**: sar |
| `UiItem.topTheme` | tanımlı, hiçbir yerde kullanılmıyor (ölü kimlik) | `personalize.dart:280`; `grep UiItem.topTheme lib` = yalnız tanım | dokunma (kimlik silinmez); envantere not |
| Ana ekran ✨ (AI) | `homeAi` yalnız ⋮ maddesini gizler; haptaki düğme hep görünür | `dashboard_menu.dart:40`, `dashboard_widgets.dart:598` | **SABİT** (Y1: "boştayken AI tuşu görünmüyor" → hep görünür) |
| Ana ekran takvim şeridi | ayrı tercih (`home_calendar_strip`), modda dokunulamaz | `dashboard_screen.dart:1845`, `settings_providers.dart:306` | **YAP**: düzen panosunda "Ana ekran" yüzeyine anahtar olarak bağla (yeni kimlik yok, var olan tercihi sürer) |
| Hızlı yakalama satırı | ayrı anahtar (ayarlar) | `dashboard_screen.dart:1878`, `personalize_screen.dart:688-694` | **YAP**: aynı (panoda anahtar) |
| Klasör şeridi, ev düğmesi | düzenlenemez | `dashboard_shelf.dart:197, 214` | **SABİT** (Y3, Y14) |
| "+" düğmesi, başa dön | düzenlenemez | `dashboard_screen.dart:2338, 2283` | **SABİT** (ilke 2: tek birincil eylem) |
| Kenar rayı hedefleri (tablet/web) | düzenlenemez | `app_frame.dart:617-647` | **SABAH BAKILACAK** (S1) — varsayılan: dokunma |
| Not üst çubuğu ⋮ ve klavye düğmesi | bilinçli sabit | `personalize.dart:286-287` | **SABİT** (menüye giriş kaybolmasın) |
| Biçim çubuğu düğmeleri (12) | düzenlenemez | `format_bar.dart:647-811` | **SABİT** — genel yapılmayacak: "biçim çubuğunu değiştirmek"; S2'de soruldu |
| Kalem tepsisi araçları (7) | düzenlenemez | `pen_tray.dart:23, 324, 589, 961` (`PenTrayTool.values`) | **YAP** (§3.4): hangi kalemler tepside dursun — `UiItem.penTool(<ad>)` |
| Sabit ek çubuğu (T, balon, görünüm, kalem, tam ekran, bağlantı…) | yalnız `videoNoteAt` sarmalı | `pinned_media_pane.dart:1412-1689`; sarma `:1565` | **YAP**: gizlenebilir (varsayılan AYNI; Y10 "⋮'e indirme" yasağı varsayılanı korur, kullanıcının kendi gizlemesi K-O6) — `UiItem.pinned(<ad>)` |
| Sabit ek ⋮ menüsü | `menuId` yok → `MenuLayouts` çalışmaz | `pinned_media_pane.dart` `_openSheet`; `ActionMenu(` yalnız 4 yerde: `dashboard_menu.dart:33,170`, `note_editor_actions.dart:95`, `note_menu_model.dart:49` | **YAP**: `menuId: 'pinned.menu'` |
| Balon dok düğmeleri | düzenlenemez | `bubble_dock.dart:461-724` | **SABİT** (seçime bağlı bağlam çubuğu; gizlemek işlevi kaybettirir) |
| Sesli yakalama levhası | düzenlenemez | `voice_capture_sheet.dart` | **SABİT** (§4'te yeniden tasarım) |
| Not kartı alanları | tek tercih `card_show_checked` | `arayuz.md` "izinli tek yeni tercih" | kapsam dışı (S3) |

**Mod deneyimi/görünüm eksikleri:**

1. Mod yalnız gizle/göster yapar; sıralamak için ayarlara ya da o menünün kendi "Düzenle"sine
   gitmek gerekir (yukarıdaki b–e). Şeritte bunu söyleyen/götüren hiçbir şey yok
   (`customizable.dart:216-281`: yalnız "Geri al" + "Bitti").
2. Levha içindeki öğeler (Ekle, "+" paneli, video) ancak o levha açılınca düzenlenir; mod bunu
   söylemez. Klavye kapalıyken hızlı satır hiç görünmez (2026-11-13 bulgusu, `quick_row_editor.dart:87`).
3. Rozet 18 dp, simgesi 11 px (`customizable.dart:128-141`); çerçeve köşesi elle 10 (`:113`),
   opaklık elle 0.32 (`:108`); şerit ölçüleri elle (`:227` dolgu 12/4/6, yazı 13/12 `:243, 253`),
   `elevation: 3` bulanık gölge (`:226`).
4. Mod açılış/kapanışında hiçbir geçiş yok: çerçeveler ve şerit bir karede belirir.
5. Ayar ekranı (`personalize_screen.dart`) 8 bölümlük uzun liste; bölümlerin her biri farklı kılıkta
   (çip, anahtar, sürüklenen liste, karo). Baş kartta gradyan zemin (`:141-150` — genel yapılmayacak:
   "gradyan zemin").

### 1.2 Hedef

**Tek bileşen, tek kılık: `CustomizeBoard`** (iskelet: `lib/core/widgets/customize_board.dart`).
Hızlı satır düzenleyicisinin (c) kullanıcının 2026-11-13'te istediği "aç-düzenle-kaydet değil,
modern" kalıbı genelleştirilir ve b, c, d, e'nin yerine geçer:

```
┌ Önizleme şeridi (yüzey gerçekte nasıl duracak) — SÜRÜKLE = sırala ──────────┐
│  [B] [+] [✎] [🔍] [☑]                                                        │  48 dp, surfaceContainerHigh, AppRadius.l
└──────────────────────────────────────────────────────────────────────────────┘
 Görünenler · 5          dokun = çıkar           (karo: secondaryContainer dolu + "−")
 Eklenebilir · 9         dokun = ekle            (karo: çerçeveli + "+")
                                              [↺ Varsayılana dön]
```

- Karo: yükseklik 40, köşe `AppRadius.m`, dolgu `AppSpace.m/s`, simge `AppIconSize.s`, yazı
  `labelLarge`. Görünen: `secondaryContainer` zemin; eklenebilir: `surface` + `outlineVariant` çizgi.
- Önizleme şeridi yatay `ReorderableListView` (`buildDefaultDragHandles: false`, her simge
  `ReorderableDelayedDragStartListener`); `onReorder == null` ise sürüklenmez (sırası olmayan yüzey).
- Değişiklik ANINDA kaydedilir (P50 kuralı). Karo yer değiştirirken geçiş: karo `AnimatedSwitcher`
  DEĞİL — yalnız `AnimatedOpacity` `AppMotion.quick` (Wrap içinde boy animasyonu yok).
- İmza (iskelette derlenir, testli):

```dart
typedef CustomizeEntry = ({String id, IconData icon, String label});
class CustomizeBoard extends StatelessWidget {
  const CustomizeBoard({
    required this.entries,        // yüzeyin TÜM öğeleri (varsayılan sırada)
    required this.shown,          // görünenlerin kimlikleri, EKRAN sırasıyla
    required this.onToggle,       // (id, visible)
    this.onReorder,               // (oldIndex, newIndex) görünenler içinde; null = sırasız
    this.onReset,
    required this.shownLabel, required this.availableLabel,
    this.emptyLabel, this.resetLabel,
  });
}
```

**Düzen merkezi: `CustomizeHub`** (yeni dosya `lib/features/settings/presentation/customize_hub.dart`,
paket D2 yazar): üstte yatay yüzey çipleri, altında o yüzeyin `CustomizeBoard`'u.

| Yüzey (`CustomizeSurface`) | Öğeler | Sıra kaynağı | Görünürlük |
|---|---|---|---|
| `bottomBar` | `UiItem.barLeftDefault + barRightDefault` | `barOrder/aiOrder` (`UiPrefs.barSides`; iki önizleme şeridi: sol kapsül, sağ kapsül — karoya uzun bas = öbür kapsüle taşı, `withBarSide`) | `shows` |
| `topBar` | `UiItem.topDefault` + tarih, etiket, ortak çalışan | `topOrder` | `shows` |
| `quickRow` | `quickRowCatalog` | **yeni** `quickOrder` | `shows(UiItem.quickRow(k))` |
| `addPanel` ("+") | `addCatalog(AddContext.home)` | `MenuLayouts` (bugünkü `quick_add_fab.dart:619-634` yolu) | bugünkü |
| `attach` (Ekle) | `addCatalog(AddContext.inNote)` | **yeni** `attachOrder` | `shows(UiItem.attach(id))` |
| `home` | hesap, süz, mikrofon + takvim şeridi, hızlı yakalama (anahtar) | sırasız | `shows` / kendi tercihleri |
| `video` | hız, süre, "not al"; geri/ileri sarma süreleri (bugünkü seçici korunur) | sırasız | `shows` |
| `pinned` | sabit ek çubuğu düğmeleri | sırasız | **yeni** `UiItem.pinned(k)` |
| `pen` | tepsideki kalemler | sırasız | **yeni** `UiItem.penTool(k)` |
| `modules` | eklentiler (`UiModule.all`) | sırasız | `withModule` |

- Hub iki yerde aynı bileşen: **(i)** Ayarlar → Kişiselleştir ekranının gövdesi (bugünkü 8 bölümün
  yerine; baş kart düz `surfaceContainerLow` + `AppRadius.l`, gradyan kalkar), **(ii)** mod şeridindeki
  yeni **"Sırala"** düğmesinin açtığı levha (`showAppSheet`, `DraggableScrollableSheet` 0.7/0.4/0.95).
  Levha açılırken yüzey çipi o anki ekrana göre seçilir: yönlendirici konumu not rotası → `bottomBar`,
  kök → `home`, klavye açık + not → `quickRow` (karar tablosu hub dosyasının başında tek fonksiyon:
  `CustomizeSurface surfaceFor(String location, {required bool keyboard})`).
- Menülerin kendi "Düzenle"si (b) KALIR (kullanıcı menünün içinden ulaşıyor), ama gövdesi
  `CustomizeBoard`'a çevrilir (`action_menu_sheet.dart:560-702`): "hızlı satır" = birinci önizleme
  şeridi (en çok `MenuLayout.maxQuick`), gruplar = ikinci. `MenuLayout` veri biçimi değişmez.

**Yerinde mod (şerit + çerçeve) yeniden biçim:**

- Şerit (`_CustomizeStrip`): tek satır, yükseklik üst güvenli alan + 48; zemin `inverseSurface`
  (durum rengi — korunur), `elevation: 0`, altta 1 dp `onInverseSurface` × `AppAlpha.pressed` çizgi.
  Sol: `Icons.tune_rounded` (`AppIconSize.s`) + başlık (`labelLarge`, `AppWeight.strong`) + gizli
  sayısı hapı (`AppRadius.pill`, zemin `onInverseSurface` × `AppAlpha.pressed`, yalnız sayı > 0).
  Sağ: "Geri al" (metin) · **"Sırala"** (`IconButton`, `Icons.swap_vert_rounded`,
  `ValueKey('customize-reorder')`) · "Bitti" (dolu, `inversePrimary`). İkinci satır (ipucu) kalkar;
  ipucu ilk girişte P62 ipucu bileşeniyle bir kez gösterilir ("Dokun: gizle/göster · Sırala: yerini
  değiştir"). Dolgu `AppSpace.m` / `AppSpace.xs`.
- Şerit hareketi: yuva boyu TEK ADIMDA açılır (bugünkü gibi — `CustomizeModeHost` Column'u, ağaç şekli
  sabit kalır); içerik `FractionalTranslation(0,-1 → 0,0)` + `FadeTransition`, `AppMotion.short` /
  `enter`; kapanışta `quick` / `exit`, bitince yuva tek adımda kapanır.
- Çerçeve (`CustomizeFrame`): köşe `AppRadius.m`; görünür öğe = `primary` × `AppAlpha.hairline`
  yıkama + 1 dp `primary` × `AppAlpha.muted` çizgi; gizli öğe = içerik opaklığı `AppAlpha.disabled`
  + KESİKLİ çizgi (`outline`; tek `drawPoints(PointMode.lines)` — `paintItemDivider` kesikli kalıbı,
  `item_divider_style.dart:44-53`). Rozet 20 dp, simge 12, göz/çizili göz KALIR (S4).
- Çerçeve hareketi: mod açılınca çerçeve ve rozet `FadeTransition` `AppMotion.short`; dokunuşta rozet
  `ScaleTransition` 0.85 → 1 `AppMotion.instant`, içerik opaklığı `AppMotion.quick` (bugünkü).
  **Titreme/sallanma YOK** (zıplayan eğri yasağı).
- `Customizable` normal kipte (mod kapalı) BUGÜNKÜ gibi çıplak `child` döndürür — sarmalayıcı
  eklenmez (editörün ilk karesi: `customizable.dart:17-19` P20 notu).

**Yeni kayıt alanları (`UiPrefs`):** `quickOrder`, `attachOrder` (`List<String>`, boş = varsayılan;
`orderOf` ile birleştirilir; `toJson` yalnız doluysa yazar; `==`/`hashCode`/`copyWith`/`fromJson`'a
eklenir). Yeni kimlik üreteçleri: `UiItem.pinned(String key)` → `'pinned.$key'`,
`UiItem.penTool(String key)` → `'pen.tool.$key'`. Eski kayıt aynen okunur (bilinmeyen alan yok sayılır).

### 1.3 Durumlar

Mod kapalı · mod açık/temiz ("Geri al" soluk) · mod açık/değişmiş · hub levhası açık · yüzeyde hiç
görünen yok (`emptyLabel`) · tüm öğeler görünür ("Eklenebilir · 0" başlığı ve boş Wrap çizilmez) ·
hareketi azalt (geçişler ≤ 150 ms, doğrusal) · klavye açıkken mod (şerit üstte, klavye altta; hub
levhası açılırken klavye kapatılır — `note_editor_actions.dart:496` kalıbı).

### 1.4 Kabul ölçütleri

- [ ] b, c, d, e'nin dördü de `CustomizeBoard` çizer; `grep -c "ReorderableListView" lib` yalnız
      `customize_board.dart` (+ notla ilgisiz yerler) verir.
- [ ] Envanterde **YAP** yazan her satır hub'dan düzenlenir ve yerinde modda çerçevelenir.
- [ ] Hızlı satır ve Ekle levhası sıralanır; sıra uygulama yeniden açılınca korunur
      (`test/personalize_order_test.dart` yeni: `quickOrder`/`attachOrder` gidiş-dönüş + eski kayıt).
- [ ] Var olan testler değişmeden yeşil: `editor_bar_customize_test`, `editor_top_customize_test`,
      `personalize_top_order_test`, `page_panel_personalize_test`, `quick_row_editor_test`,
      `personalize_bubble_focus_test` (anahtar adları korunur: `customize-undo`, `customize-done`,
      `quick-row-edit-<k>`, `personalize-start-edit`, `personalize-reset`).
- [ ] `customizable.dart`, `personalize_screen.dart`, `quick_row_editor.dart`'ta elle ölçü 0.
- [ ] Tur: `duzen-serit`, `duzen-hub-altcubuk`, `duzen-hub-hizli`, `kisisellestir` (açık + koyu).

### 1.5 Kasma riski + bütçe (kasma-kontrol 8 madde)

1 (alan karşılaştırma): not alanı eklenmiyor → yok. 2 (satır önbelleği): yok. 3: şerit/çerçeve
durumu `Personalize.listenable`'dan, editör kökü `setState` almaz — DİKKAT `note_editor_screen.dart:4555`
(`final editingUi = Personalize.editing`) alt çubuk kurucusunda okunuyor; yeni sarmalar bu kalıbı
kullanır, kök `build`'e yeni `Personalize` okuması eklenmez. 4: `Customizable` mod kapalıyken çıplak
çocuk, açıkken çerçeve — ağaç şekli değişir ama yalnız mod geçişinde ve alt ağaç düğme (metin alanı
değil); metin alanı içeren hiçbir şey `Customizable` ile sarılmaz. 6: şerit boyu tek adım. 7: hızlı
satırın `KeyboardSwitch` düzeni değişmez; `quickOrder` satırın `_syncRowCache`'ine değil, hızlı satırın
kendi kurucusuna girer (`editor_quick_row.dart:247` listesi) — sıra listesi her build'de YENİ nesne
üretilmez (`Personalize.prefs` değişince bir kez hesaplanıp `State`'te tutulur).

**S40 (yeni) — "Düzen modu: aç → 3 öğe gizle/göster → Bitti (30 maddeli not, telefon)".** Ölç:
`NoteEditorScreen`, `NotePageCanvas`, `ItemsEditor` kurulum sayısı ve `_ItemRow` kurulumu.
Bütçe: mod aç/kapa'da gövde kurulumu ≤ 1 (MediaQuery boyu değiştiği için tek yeniden dizilim),
dokunuş başına gövde kurulumu 0, satır kurulumu 0. (Kalıp: `perf_budget_test.dart` S20, `:1080-1096`.)

Cihaz A/B: **evet** (editör alt/üst çubuğu ve hızlı satır) — `ab_hepsi.py --altin`, evreler klavye
aç/kapa + not aç; mod kapalıyken ölçülür (mod kapalı yol hızlanmasa da yavaşlamamalı).

---

## 2. Şablonlar

### 2.1 Mevcut durum (kanıt)

Galeri + önizleme tek levhada: `lib/features/notes/presentation/note_template_sheet.dart`
(1219 satır); kendi şablonum düzenleyicisi `template_editor_screen.dart` (398); veri
`domain/note_templates.dart` (16 hazır şablon, 3 bölüm), `data/user_templates.dart`.

1. Kart yalnız simge kutusu + ad + tek satır açıklama; şablonun NE getireceği görünmüyor
   (`note_template_sheet.dart:712-822`; açıklama `Tooltip`'e itilmiş `:744`). Kartta elle ölçüler:
   köşe 14 (`:748`), dolgu 10/10/10/8 (`:761`), kutu 32 + köşe 10 (`:766-771`), yazı 12 (`:790`).
2. Galeri → önizleme geçişi elle süre/eğri (`:110-112`: 220 ms, `easeOutCubic`) + yatay 0.04 kayma;
   `AppMotion` kullanılmıyor, "hareketi azalt" yok.
3. Önizleme adımı (`TemplateComposer`, `:843-1219`) form gibi: çerçeveli başlık alanı (`:1001-1011`),
   `SegmentedButton`, `FilterChip`, `CheckboxListTile` listesi (`:1071-1090`), en altta sola yaslı
   "Oluştur" (`:1017-1029`). Uzun listede "Oluştur" kaydırmanın altında kalır.
4. Yazı şablonunda önizleme düz metin kutusu (`_textPreview`); başlık/alt başlık görünüşü not
   sayfasındakine benzemiyor.
5. Kendi şablonum menüsü uzun basışta gizli (`:757` `onLongPress: onMenu ?? onFavorite`) — keşfedilmez;
   kartta menü olduğunu gösteren iz yok.
6. Boş "Şablonlarım" (`_EmptyMine`, `:674-710`) ve arama sonuçsuz (`:268-281`) hâlleri ayrı kılıkta.
7. Düzenleyici (`template_editor_screen.dart:194-398`): çerçeveli `TextField`'lar; kaydet düğmesi
   uygulama çubuğunda dolu düğme (ilke 2 ile uyumlu), ama satır ekleme/çıkarma animasyonsuz ve
   önizleme yok.
8. Levha `showAppSheet` ile açılıyor (iyi, `:40-53`), `maxWidth: 640`.

**Korunacak eski istekler (`istek_tara.py`):** küçük kartlar — telefonda 3, genişte 4 sütun
(`:433`, 2026-11-05); favori en çok 4 ve "+" menüsünde (`user_templates.dart:281`,
`quick_add_fab.dart:212`); iki sütunlu açma (`:884`); grup içi alfabetik öneri çipleri
(`note_templates.dart:171`); iki adım — önce önizle, sonra oluştur (`:20-37`, 2026-09-29); kendi
şablonum oluştur/düzenle (`template_editor_screen.dart:8`).

### 2.2 Hedef

**Kart = küçük kâğıt (`TemplatePreviewCard`, iskelet `lib/features/notes/presentation/template_preview_card.dart`).**
Şablonun içeriği kartın üstünde MİNYATÜR SAYFA olarak çizilir: metin değil, satır iskeleti
(başlık çubuğu, kutucuk + çizgi, numara + çizgi, düz satır). Tek `CustomPaint`, metin dizimi yok.

```
┌───────────────┐   genişlik: (levha − 2×AppSpace.l − (n−1)×AppSpace.s) / n   (n = 3 telefon, 4 geniş — KORUNUR)
│ ▬▬▬▬▬         │   minyatür sayfa: yükseklik 64, zemin AppTokens.card, köşe AppRadius.s,
│ ☐ ▬▬▬▬▬▬▬     │     çizgi AppTokens.hairline; satır: 4 dp kalın, aralık 9 dp, en çok 5 satır;
│ ☐ ▬▬▬▬▬       │     başlık çubuğu vurgu renginde (%AppAlpha.strong), gövde onSurface × AppAlpha.soft
│ ☐ ▬▬▬▬▬▬      │
├───────────────┤
│ ◉ Alışveriş ★ │   alt bant: simge noktası 16 (vurgu), ad labelLarge/strong 1 satır, favori yıldızı 18
└───────────────┘   kart: surfaceContainerLow, köşe AppRadius.m, çizgi outlineVariant × AppAlpha.muted
```

- Satır türleri saf fonksiyondan gelir (iskelette testli):
  `List<TemplateLineKind> templatePreviewLines({required NoteType type, required String body, required List<String> items, int max = 5})`
  — liste notunda her madde `check`/`number`; yazı notunda satır başı `# `/`## ` → `heading`,
  `☐` → `check`, `•`/`-`/`*` → `bullet`, boş satır → `gap`, diğeri → `text`.
- Favori kart: çizgi vurgu renginde (bugünkü `:750-752` korunur) + yıldız dolu.
- Kendi şablonum kartında sağ altta 16'lık `Icons.more_horiz` (menü ipucu); dokunuş hedefi kartın
  alt bandının sağ 40 dp'si → `onMenu`. Uzun basış da çalışmaya devam eder.
- Basış: `InkWell` + ölçek YOK (ızgarada 16+ kart; basış efekti mürekkep dalgası yeter).

**Galeri düzeni:**

- Başlık satırı: `SheetHeader`-uyumlu başlık "Şablonlar" + sağda "Yeni şablon" (metin düğmesi, `+`).
- Arama alanı: dolu (`surfaceContainerHigh`), köşe `AppRadius.pill`, yükseklik 44, çerçevesiz.
- Bölüm çipleri tek satır yatay kaydırma (Tümü · Listeler · Planlama · Yazı · Şablonlarım); seçili
  çip `secondaryContainer`. Değişimde ızgara `FadeTransition` `AppMotion.quick` (kayma yok).
- Bölüm etiketi (`_SectionLabel`): P62 "bölüm etiketi" yazı rolü (yoksa `labelLarge` + `onSurfaceVariant`).
- Boş hâller tek bileşen (`_EmptyState`: simge 40 `outline`, tek satır yazı, isteğe bağlı düğme) —
  boş Şablonlarım ve sonuçsuz arama aynı kılık.

**Önizleme adımı (`TemplateComposer`) — "gerçek sayfa" görünüşü:**

- Üst satır: geri oku (yalnız galeriden gelindiyse) · simge noktası · şablon adı (`titleMedium`) ·
  yer imi/düzenle düğmesi (bugünkü `tpl-save-as`).
- Gövde, not sayfası gibi bir KÂĞIT kartın içinde (zemin `AppTokens.card`, köşe `AppRadius.l`, çizgi
  `hairline`, iç dolgu `AppSpace.l`): başlık alanı çerçevesiz, not başlığı stilinde; liste
  şablonunda maddeler `CheckboxListTile` yerine sıkı satırlar (kutucuk 20 + metin; seçili değilse
  metin `AppAlpha.disabled`, üstü çizili — bugünkü anlam korunur); "Madde ekle" kâğıdın son satırı.
- Seçenekler kâğıdın ALTINDA tek satır çip: tür (☑ / 1.) iki çipli seçim, "İki sütun" çipi.
- Öneriler: bugünkü reyon başlıklı çipler (alfabetik — korunur), bölüm etiketi yeni rolde.
- **"Oluştur" SABİT ALT BANT:** levhanın dibine yapışık (kaydırmanın dışında), tam genişlik dolu
  düğme, yükseklik 48, köşe `AppRadius.m`, üstünde 1 dp `hairline`; yazı bugünkü sayaçlı metin
  (`templateCreateWithCount`). Klavye açıkken bandın üstüne oturur (levha zaten
  `viewInsets.bottom` dolgulu, `:47-50`).
- Geçiş galeri ↔ önizleme: `AnimatedSwitcher` kalır; süre `AppMotion.of(context, AppMotion.short)`,
  eğri `AppMotion.curveOf(context, AppMotion.enter/exit)`; kayma 0.04 → `Offset(0.03, 0)` yalnız
  girişte, çıkış düz solma.

**Düzenleyici ekran (`TemplateEditorScreen`):** aynı kâğıt kart + aynı satır bileşeni (önizlemedeki
liste satırı düzenlenebilir hâliyle); üstte ad alanı dolu/çerçevesiz; tür seçimi üç çip; satır
ekle/çıkar `AnimatedOpacity` `AppMotion.quick` (boy tek adım). Sağda (≥ 840 dp genişlikte) canlı
`TemplatePreviewCard` önizlemesi — dar ekranda yok.

### 2.3 Durumlar

Galeri (tümü/bölüm/Şablonlarım) · arama (sonuçlu/sonuçsuz) · boş Şablonlarım · favori dolu (4) —
bugünkü `templateFavoritesFull` duyurusu korunur · önizleme liste/yazı · hiçbir madde seçili değil
("Oluştur" etkin, sayaçsız metin — bugünkü davranış) · doğrudan önizleme (`initial`/`initialUser`,
geri oku yok) · koyu tema (minyatür sayfa `AppTokens.card` koyuda zeminden açık kalır) · yazı 1.3
(alt bant adı tek satır, taşma `ellipsis`) · telefon 3 / geniş 4 sütun · web fare üstü (kart
`hoverColor` `primary` × `AppAlpha.hairline`).

### 2.4 Kabul ölçütleri

- [ ] 16 hazır şablonun her kartında içeriğiyle tutarlı minyatür (liste → kutucuklu satırlar; toplantı
      → başlık + satırlar). `test/template_preview_lines_test.dart` (iskelette var) + kart widget testi.
- [ ] `test/note_templates_test.dart` (19 KB) değişmeden yeşil — anahtarlar korunur: `tpl-card-<key>`,
      `tpl-fav-<ad>`, `tpl-save-as`, `tpl-two-columns`, `tpl-item-<i>-<metin>`, `tpl-editor-*`.
- [ ] "Oluştur" 30 maddeli şablonda kaydırmadan görünür (widget testi: düğme ilk karede görünür alanda).
- [ ] `note_template_sheet.dart` ve `template_editor_screen.dart`'ta elle ölçü 0, elle süre 0.
- [ ] Tur: `sablon-galeri`, `sablon-onizleme-liste`, `sablon-onizleme-yazi`, `sablon-bos`,
      `sablon-duzenle` (açık + koyu, telefon + tablet).

### 2.5 Kasma riski + bütçe

Editör dışı levha; kasma listesi 1–7 uygulanmaz. Risk: ızgarada 16–30 kartın her harfte yeniden
kurulması ve minyatür boyaması. Tedbir: kart `const` kurucu + `RepaintBoundary` YOK (durağan);
`templatePreviewLines` sonucu şablon başına bir kez hesaplanır (`State`'te `Map<String, List<…>>`
önbellek — hazır şablonlar için dil değişmedikçe sabit).

**S41 (yeni) — "Şablon galerisi (telefon, 16 hazır + 6 kendi): aç → 'Planlama' çipi → aramaya 3 harf →
karta dokun".** Bütçe: harf başına kurulan `TemplatePreviewCard` ≤ o harfte görünen kart sayısı;
çip değişiminde kurulan kart ≤ yeni bölümün kart sayısı; levha açılışından ilk kareye kadar dizilen
`RenderParagraph` ≤ görünen kart × 1 (minyatürde metin yok). Kalıp: S21 (`perf_budget_test.dart:1098-1137`).

Cihaz A/B: **hayır** (editör/klavye/çubuk/liste/geçiş değil); `ab_hepsi.py`'ye "şablon levhası aç"
evresi eklenir (hız sözleşmesi tedbir 4), yürütücü `[apk]` öncesi tam ölçümde görür.
