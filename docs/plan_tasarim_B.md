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

---

## 3. Kalem seti görünümü

### 3.1 Mevcut durum (kanıt)

Tek bileşen: `lib/features/notes/presentation/editor/pen_tray.dart` (1528 satır, `PenTray`), kalem
resimleri `pen_icons.dart` (`PenToolPainter`), araç hafızası `viewers/ink_tools.dart`
(`InkToolMemory`, `InkPreset`), gerçek çizgi boyaması `viewers/ink_stroke_paint.dart`
(`paintInkStroke`, `:21`), ayar levhası `viewers/ink_layer.dart:2525` (`InkSettingsSheet`).
Üç yerleşim, 9 çağrı yeri:

| Yerleşim | Kurucu | Nerede | Kanıt |
|---|---|---|---|
| Kapsül + hap (yüzen) | `_buildDock` `:371-707` | not sayfası kalem kipi | `note_editor_screen.dart:5631` (`dock: true`) |
| Sütun (tablet) | `_buildRail` `:309-355` | çizim ekranı, PDF bölmesi | `drawing_screen.dart:304`, `pdf_note_pane.dart:452` |
| Alt şerit | `_build` `:930-984` | çizim ekranı (telefon), PDF/slayt/görsel | `drawing_screen.dart:342`, `pdf_viewer_screen.dart:464`, `slide_viewer_screen.dart:347`, `image_viewer.dart:735`, `pdf_note_pane.dart:459`, `slide_note_pane.dart:556` |

**Bulgular:**

1. **Zıplayan eğri üç yerde** (genel yapılmayacak): hap ↔ kapsül `Curves.easeOutBack` (`:677`),
   kapsülde kalemin kalkışı (`_DockTool`, `:1030`), şeritte kalemin kalkışı (`_TrayTool`, `:1165`).
2. **Boy/yerleşim animasyonu:** ayar paneli `AnimatedSize` ile açılıyor — kapsülde (`:644-657`) ve alt
   şeritte (`:948-955`; şerit belgeyle aynı Column'da olduğu ekranlarda belge her karede yeniden
   dizilir — *hipotez: çağrı yerlerinin Column'u tek tek doğrulanmadı, PB3 ilk iş olarak bakar*).
   `_DockTool` kalemi `AnimatedPositioned` ile kaldırıyor (`:1028-1031`, yerleşim animasyonu); renk
   noktası seçilince 28 → 32 büyüyor (`:1240-1243`), kalınlık noktası `AnimatedContainer` ile
   boy değiştiriyor (`:1376-1379`).
3. **Bulanık gölge + sabit siyah:** kapsül yüzeyi iki katlı bulanık gölge (`:392-403`, bulanıklık 20
   ve 3, `Colors.black`), renk düğmesi (`:842-848`, bulanıklık 6).
4. **Belirteç yok:** süreler elle 240/160/300/320/200/180/120 ms (`:627, 676, 1029, 1164, 1184, 832,
   1083, 1241, 1377`), köşe 24 (`:618`), çizgi 0.8 × alfa 0.5 (`:384-386`), dolgu/ölçülerin tamamı
   elle. "Hareketi azalt" yalnız kapsülde okunuyor (`:378`); `_TrayTool`, `_DockTool`, `_Swatch`,
   `_colorDot` okumuyor.
5. **Önizleme çizgiyi göstermiyor:** kalınlık önizlemesi bir NOKTA (`:1371-1388`); sabitlenen kalem
   çipi de nokta (`_PresetChip`, `:1452-1528` — tür yalnız yuvarlak/kare ipucundan anlaşılır).
   Fosforlunun saydamlığı, dolma kalemin incelip kalınlaşması görülmüyor; oysa tek çizim yolu
   `paintInkStroke` hazır ve hiçbir önizleme onu kullanmıyor.
6. **Ayar paneli üç kılık** (`_Options`, `:1214-1448`): kalemde etiketsiz iki kaydırıcı (kalınlıkta
   yalnız sayı `:1397-1403`, şeffaflıkta damla simgesi `:1411-1421`), şekilde `ChoiceChip` yığını
   (`:1281-1301`), silgide metin düğmesi + `SwitchListTile` (`:1331-1347`). Renk noktası iki ayrı
   bileşen: panelde `dot()` (`:1229-1255`), kapsülde `_Swatch` (`:1063-1126`), sütunda `_colorDot`
   (`:825-852`).
7. **Sabit kalemler keşfedilmiyor:** "Kalemi sabitle" yalnız ⋯ menüsünde (`:748-756`), kaldırmak
   yalnız uzun basış (`:1488`); satır ayrı yüzen hap (`:658-670`).
8. **Ayar levhası ortak levha değil:** `showInkSettings` telefonda çıplak `showModalBottomSheet`
   (`:55-62`) — tutamak/üst güvenli alan düzeltmesi (`showAppSheet`, 2026-11-14) buraya ulaşmıyor.
9. Tepsideki 7 araç düzenlenemez (`PenTrayTool.values` `:324, 589, 961`) — §1.1 envanteri.

**Korunacak eski istekler (`istek_tara.py pen_tray.dart`, 11 kayıt):** araçlar simge değil TEPSİDE
DURAN KALEMLER, seçili kalem kalkar, ucu çizilen renkte (`:25`, 2026-10-28) · yazarken küçük HAP,
dokununca tek satır KAPSÜL, panel kapsülü yükseltmez (`:357-370`, 2026-11-02/07) · hap 48 dp, ayraç,
48 dp hızlı silgi (`:421, :462`, 2026-11-08) · tablette SOLDA sütun (`:94`, 2026-11-02) · çizim
başlayınca panel/kapsül kapanır (`:158`) · panelin dışına dokununca kapanır (`:282`, 2026-11-09) ·
şeffaflık panelin içinde (`:1406`) · sabit kalem en çok 5 (`ink_tools.dart:217`) · tablette ayarlar
açılır pencere (`:38`). **Genel yapılmayacak "kalem tepsisini değiştirmek":** kullanıcı 2026-11-14'te
kalem setinin GÖRÜNÜMÜNÜ açıkça istedi → kapsam yalnız görünüş ve hareket; yerleşim (üç kip), araç
sırası, jestler, `pen-tray-*`/`pen-dock-*`/`pen-preset-*` anahtarları ve yukarıdaki dokuz istek
DEĞİŞMEZ.

### 3.2 Hedef

**Yüzey (üç kip aynı dil):** kapsül, hap, sabit kalem hapı ve ayar paneli
`AppSurface.floating(theme, radius: …)` — `surfaceContainerHigh`, `hairline` çizgi, 2 dp BULANIKSIZ
alt gölge. Kapsül/hap köşesi `AppRadius.pill`, panel `AppRadius.xl`. Sütun ve alt şerit
`surfaceContainerLow` + sayfa tarafında 1 dp `hairline` (bugünkü `Divider` `:942-946` ve sütunun
çıplak kenarı yerine); gölgesiz.

**Kalem kalkışı (tek kalıp, iki yerde):** `_DockTool` ve `_TrayTool` aynı `AnimatedSlide`'ı kullanır
(yalnız boyama — `AnimatedPositioned` kalkar); süre `AppMotion.of(context, AppMotion.selection)`, eğri
`AppMotion.curveOf(context, AppMotion.emphasized)` (TAŞMAZ). Ölçüler aynı kalır: kapsülde 44 × 52
kırpma içinde 31 × 68 kalem, seçili 12 dp yukarıda (bugünkü `top` 15 → 3 = `Offset(0, 15/68)` →
`Offset(0, 3/68)`); şeritte `Offset(0, 0.24)` → `Offset(0, 0.02)`. Seçili aracın altındaki 22 × 4
renk çizgisi (`:1181-1201`) kalır, `AnimatedOpacity` `AppMotion.quick`.

**Hap ↔ kapsül:** `AnimatedSwitcher` kalır (sayfanın ÜSTÜNDE yüzen katman, sayfa yerleşimine
girmiyor); giriş `AppMotion.short` + `emphasized`, çıkış `AppMotion.exitOf(short)` + `exit`; ölçek
0.85 → 1 yerine 0.92 → 1 (alt ortadan) + solma. Sabit kalem hapı aynı geçişle belirir (bugün
geçişsiz, `:658`).

**Ayar paneli açılışı:** `AnimatedSize` iki yerde de kalkar. Panel yerini TEK ADIMDA alır; içerik
`FadeTransition` + `FractionalTranslation(Offset(0, 0.08) → Offset.zero)`, `AppMotion.short` /
`enter`; kapanışta `exitOf(short)` / `exit`, bitince tek adımda kalkar (durum `_panel` yanında
`AnimationController _panelAnim`; ağaç şekli sabit: panel yuvası hep kurulu, kapalıyken
`SizedBox.shrink`).

**Gerçek çizgi önizlemesi — `PenStrokePreview`** (iskelet §6.3): nokta yerine S biçimli kısa bir
çizgi, `paintInkStroke` ile — ekranda ne çıkacaksa o (fosforlu saydam ve düz uçlu, dolma kalem
incelip kalınlaşır, keçeli dolu).
- Panelde: renk sırasının ÜSTÜNDE tam genişlik, yükseklik 44, zemin `AppTokens.card` (kâğıt), köşe
  `AppRadius.m`, çizgi `hairline`. Sağ ucunda iğne düğmesi (`ValueKey('pen-panel-pin')`,
  `Icons.push_pin_outlined` ↔ `Icons.push_pin`, `AppIconSize.s`): seçili kalem sabit değilse sabitler
  (`_pinCurrent`), sabitse kaldırır — sabitleme artık görünür yerde. ⋯ menüsündeki madde
  (`pen-tray-pin`) kalır; kalem zaten sabitse yazısı "Sabitlemeyi kaldır" olur (yeni l10n anahtarı
  `inkUnpinPen`).
- Sabit kalem çipinde (`_PresetChip`): 40 × 40 dokunma alanı, 30 × 30 daire içinde
  `PenStrokePreview(compact: true)`; seçili = 2 dp `primary` halka. Uzun basışla kaldırma kalır.
- Kalınlık satırının başındaki nokta kalkar (önizleme onu karşılar); yerine `Icons.line_weight_rounded`.

**Panel düzeni (`_Options`) — tek kılık:** dolgu `AppSpace.l` / `AppSpace.m`; bölümler arası
`AppSpace.m`.

```
┌ önizleme (PenStrokePreview 44) ───────────────────────────── [📌] ┐
│ ● ● ● ● ● ● ●  ·son renkler·  (◎ tümü)        ← tek renk noktası: _Swatch(size 28)
│ ≡  ──────●──────────────  12                   ← kalınlık: simge 40 · Slider · değer (AppText.meta, tabular)
│ 💧 ────────●────────────  %80                  ← şeffaflık: aynı satır kalıbı (ValueKey('pen-tray-opacity') korunur)
└────────────────────────────────────────────────────────────────────┘
```

- Renk noktası TEK bileşen `_Swatch`: boy sabit (28); seçili = arada 2 dp boşluklu 2 dp `primary`
  halka, halka rengi `AppMotion.selection` ile solar (boy değişmez). `dot()` ve `_colorDot` silinir;
  sütun/şeritteki renk düğmesi `_Swatch(size: 26, selected: _panel)`.
- Şekil aracı: çipler `radioChip(ChoiceChip)` kalır, simge `AppIconSize.s`, aralık `AppSpace.s`.
- Silgi: "Tümünü temizle" (`TextButton.icon`, `error` rengi DEĞİL — geri alınabilir) + "Kısmi silgi"
  anahtarı; satır yüksekliği kalem satırlarıyla aynı (48).
- Kement: seçim yokken tek satır ipucu (`AppText.meta`), varken iki metin düğmesi (bugünkü).
- Geniş ekrandaki gökkuşağı halkası (`FixedColors.rainbowSweep`, `:549`) KALIR — uygulamanın "özel
  renk" simgesi, zemin değil.

**Hap:** yerleşim aynı (48 dp, yatık kalem 28, renk noktası 16, ayraç, hızlı silgi 48, ok). Yalnız
belirteçler: dolgu `AppSpace.l`/`AppSpace.s`, ayraç `outlineVariant` × `AppAlpha.muted`, simge
`AppIconSize.m`.

**Ayar levhası:** `showInkSettings` telefonda `showAppSheet`'e geçer (`isScrollControlled: true`;
`showDragHandle` argümanı yazılmaz — ortak levha tutamağı kendi çizer). Tablette açılır pencere
kalır. Levhanın İÇERİĞİ (`InkSettingsSheet`, `ink_layer.dart:2525-2720`) bu planın kapsamı DIŞI
(ayar satırı kılığı P62'nin; P62 birleşince ayrı küçük iş — §7 "sonraya").

**3.2.1 Tepside hangi kalemler dursun (§1.1 envanteri "YAP"):** `UiItem.penTool(t.name)` gizliyse o
araç üç kipte de çizilmez. `pen` (tükenmez) ve `eraser` GİZLENEMEZ (hub'da karo çıkmaz — hapın hızlı
silgisi ve "son kalem" dönüşü bunlara bağlı, `:462-473`). O an SEÇİLİ araç gizli olsa da çizilir
(silgi/şekil başka yoldan seçilebilir). Okuma tek yerde: `_PenTrayState`'te
`List<PenTrayTool> get _tools` — `Personalize.current.shows(...)` süzgeci; `build`'deki
`ListenableBuilder` birleşimine `Personalize.listenable` eklenir (kök `setState` yok). Kimlik
üreteci §1.2'de; hub `pen` yüzeyi PB2'nin, tepsi tarafı PB3'ün (PB3, `UiItem.penTool` yoksa
süzgeci yazmaz — bağımlılık §7).

### 3.3 Durumlar

Hap · kapsül · kapsül + panel · sütun · alt şerit (`controls` açık/kapalı) · 7 aracın her biri seçili
· silgi seçili (uç ve alt çizgi `primary`) · kement seçimli/seçimsiz · sabit kalem 0 / 1 / 5 · dar
(< 640: tek renk düğmesi, yinele ⋯'de) / geniş (4 hızlı renk + gökkuşağı) · koyu tema (kalem gövdesi
`dark: true`; beyaz mürekkep) · açık zeminde beyaz mürekkep (nokta kenarı `onSurface` × 0.18 korunur,
önizleme kâğıdında `hairline` içinde görünür) · fosforlu (şeffaflık kaydırıcısı kapalı, %40) · dolma
kalem (şeffaflık kapalı) · hareketi azalt (kalkış ve geçişler ≤ 150 ms, kaymasız) · yazı 1.3 (panel
değer metni taşmaz: genişlik 36, `FittedBox` yok — tabular rakam) · gizlenmiş araçlı tepsi (5 kalem).

### 3.4 Kabul ölçütleri

- [ ] `pen_tray.dart`'ta `easeOutBack` 0, `AnimatedSize` 0, `AnimatedPositioned` 0, `blurRadius` 0,
      `Colors.black` 0, elle `Duration(milliseconds:` 0 (grep ile).
- [ ] Panelde ve sabit kalem çipinde önizleme `paintInkStroke` ile çizilir
      (`test/pen_stroke_preview_test.dart`, iskelette; fosforluda boyanan renk alfa 0x66).
- [ ] Var olan testler değişmeden yeşil: `pen_tray_controls_test`, `pen_single_tool_test`,
      `pen_icons_test`, `editor_pen_tablet_test`, `handwriting_pen_test` (anahtarlar: `pen-tray-<araç>`,
      `pen-tray-color`, `pen-tray-undo`, `pen-tray-more`, `pen-tray-pin`, `pen-tray-settings`,
      `pen-tray-opacity`, `pen-dock-peek`, `pen-dock-open/closed`, `pen-dock-quick-eraser`,
      `pen-preset-<kod>`, `page-pen-dock`).
- [ ] `pen-panel-pin` sabitler/kaldırır; 6. kalem en eskiyi düşürür (bugünkü kural, yeni widget testi).
- [ ] Gizlenen araç üç kipte de yok; seçili araç gizlense de görünür; `pen`/`eraser` gizlenemez
      (`test/pen_tray_tools_pref_test.dart` yeni).
- [ ] Tur: `kalem-hap`, `kalem-kapsul`, `kalem-panel`, `kalem-sekil-panel`, `kalem-sutun` (tablet),
      `cizim-serit` (açık + koyu).

### 3.5 Kasma riski + bütçe (kasma-kontrol 8 madde)

1–2: not alanı/satır yok. 3: panel/kapsül durumu `_PenTrayState`'te kalır; editör kökü `setState`
almaz (bugün de öyle — tepsi `InkController` + `toolRev` dinler, `:291-303`). 4: panel yuvası ve
sabit kalem hapı koşulsuz kurulu (`SizedBox.shrink`), `_tools` süzgeci yalnız düğme listesini
değiştirir (metin alanı yok). 5: önizleme için "aynı (tür, renk, kalınlık, şeffaflık) → aynı
`InkStroke` örneği" testi (geometri önbelleği `_geom` örneğe bağlı, `ink_stroke_paint.dart:85`).
6: `AnimatedSize` kalkıyor (yukarıda). 7: klavye yok. 8: aşağıda.

Önizleme boyaması: `PenStrokePreview` kendi `RepaintBoundary`'sinde; kaydırıcı sürüklenirken yalnız
o katman boyanır. Kalem resimleri (`PenToolPainter`) kalkış sırasında yeniden BOYANMAZ: `AnimatedSlide`
çocuğu sabit, `shouldRepaint` yalnız `selected/ink/dark` değişince (doğrula: `pen_icons.dart`).

**S42 (yeni) — "Kalem kipi (telefon, 3 sayfalık not): kapsülü aç → 3 araç değiştir → paneli aç →
kalınlığı 5 adım sürükle → renk seç → 1 çizgi (kapsül kapanır)".** Ölç: `NoteEditorScreen`,
`NotePageCanvas` kurulumu ve `PenTray` kurulumu. Bütçe: editör kökü 0, sayfa tuvali 0; `PenTray`
kurulumu ≤ etkileşim sayısı + 2 (araç 3 + panel 1 + kaydırıcı 5 + renk 1 + kapanış 1 = 11 → ≤ 13).
Kalıp: S5 (`perf_budget_test.dart:520-554`, `_stylusDevice` + `pumpEditor`) ve S9 (`:598`).

Cihaz A/B: **evet** (not sayfasının üstünde yüzen katman; kalemle yazma gecikmesi en hassas yüzey).
`ab_hepsi.py`'de kalem evresi yoksa "kalem kipi aç → 10 çizgi → kapsül aç/kapa ×3" evresi eklenir
(*hipotez: evre listesi okunmadı; PB3 `tool/perf/ab_hepsi.py:155` adım tablosuna bakar*).

---

## 4. Sesle yazmanın etkin menüsü (hareketli ses alanı + tüm menü)

### 4.1 Mevcut durum (kanıt)

"Etkin menü" = mikrofon açıkken ekranda duran dinleme kartı. Ortak parçalar
`lib/features/notes/presentation/listening_visuals.dart` (`ListeningCard` `:411-538`, `ListeningBadge`
`:31-154`, `ListeningModeTag` `:157-200`, `ListeningClock` `:204-264`, `ListeningWaveform`
`:271-397`, `ListeningActionButton` `:542-585`, `ListeningHeaderButton` `:589-619`). İki kullanıcı:

| Yer | Kurucu | Kanıt |
|---|---|---|
| Editörde canlı dikte ("Doğrudan yazım") | `_DictationPanel` | `editor/note_editor_parts.dart:222-264`; ağaca giriş `note_editor_screen.dart:4291-4295` (`if (_dictating)`) |
| Yapay zekâ ile sesli not levhası | `_VoiceCaptureSheetState._body` | `voice_capture_sheet.dart:759-939` (dinleme `:869-908`, gözden geçirme `:914-938`) |

Oturum: `data/voice_listen_session.dart` (`VoiceListenSession`), yerli köprü `data/device_speech.dart`.

**Bulgular:**

1. **Dalga SAHTE.** `_WaveformPainter._factor` yalnız geçen süreden hesaplıyor (`:363-369`: çubuk
   başına 560 + i·41 ms periyotlu kosinüs) — fısıldasan da bağırsan da, hiç konuşmasan da aynı
   salınım. Oysa gerçek ses düzeyi (0–1) zaten geliyor: yerli taraf `onRmsChanged`
   (`MainActivity.kt:1692-1699`, 0.04'ten küçük değişimi eler) → `DeviceSpeech.listen` (`level`,
   `device_speech.dart:78-94`) → oturum (`voice_listen_session.dart:113-114`) → YALNIZ sessizlik
   kapısına gidiyor, arayüze hiç ulaşmıyor. Kayıt yolunda da var (`voice_capture_sheet.dart:361`,
   200 ms'de bir `reportLevel`). Kullanıcı "beni duyuyor mu?" sorusunun cevabını ekranda göremiyor.
2. **Geniş ekranda çubuklar şişiyor:** çubuk eni = genişlik / çubuk sayısı (`:374-375`), sayı sabit
   28 (`:526`) → 1200 dp'lik tablet kartında çubuk ~28 dp. Kartın en sınırı yok
   (`note_editor_parts.dart:238-240` yalnız 10 dp kenar payı).
3. **Editör dikte kartında sessizlik geri sayımı yok.** `_toggleDictation` oturuma `onSilence`
   vermiyor (`note_editor_voice.dart:94-122`); levhada var (`voice-silence-bar`,
   `voice_capture_sheet.dart:837-849`). Dikte, kullanıcıya haber vermeden kendiliğinden kapanıyor.
4. **Geçiş yok:** dikte kartı bir karede beliriyor (`note_editor_screen.dart:4291`); levhada dinleme →
   işleniyor → gözden geçirme evreleri sert değişiyor (`_body` üç ayrı `return`).
5. **Aynı kabuk üç kez elle yazılmış:** `ListeningCard`'ın `Material`'ı (`:452-460`), levhanın
   `plainCard`'ı (`voice_capture_sheet.dart:779-795`) ve gözden geçirme başlığı (`_header`,
   `:943-998` = `ListeningCard` başlık satırının `:467-516` kopyası).
6. **Belirteç yok / yasaklı gölge:** köşe 22 (`:458`, `voice_capture_sheet.dart:785`), dolgu
   12/10/10/12 (`:462`), yazı 15/12 ve sabit `FontWeight.w600` (`:480-501, :575`), etiket dolgusu
   7/2 + simge 11 (`:170-181`), nabız 1400 ms (`:51`), `elevation: 6` + `shadowColor: Colors.black45`
   (bulanık gölge; `:455-456`, `voice_capture_sheet.dart:782-783, :872`), saat stili elle
   (`note_editor_parts.dart:248-252`, `voice_capture_sheet.dart:888-895`), hazır düğmeleri 54 dp
   (`:1204, :1238, :1259`), çip köşesi 10 + yazı 12 (`:1403, :1409, :1422, :1432`).
   "Hareketi azalt" hiçbir parçada okunmuyor (nabız ve dalga hep döner).
7. Levha her sessizlik yoklamasında (250 ms) baştan kuruluyor: `onSilence` → `setState`
   (`voice_capture_sheet.dart:304-306`).

**Korunacak eski istekler (`istek_tara.py`):** iki alan TEK görünüm, fark renk ve simgede
(`listening_visuals.dart:16`, 2026-10-20) · kart ORTA boy (~120 px; `:402`; bekçi
`test/listening_card_bubble_theme_test.dart`: yükseklik 90–150) · döküm alanı üç satır, fazlası kayar
(`voice_capture_sheet.dart:1089`) · bitiş düğmeleri YAN YANA kısa adlarıyla (`:1228`) · üç işlem çipi
"Diğer" altında (`:1394`, 2026-10-31) · dikte metni imlecin olduğu yere yazar
(`note_editor_voice.dart:9`) · mikrofon açıkken KAÇIRILAMAYACAK gösterge + durdurma
(`note_editor_parts.dart:214`) · tablet kasma kök nedeni: kart kendi `RepaintBoundary`'sinde
(`:232-236`, 2026-11-13). Y9 (alt kapsüldeki ses düğmeleri) ve Y15 (AI merkezi) bu bölümün DIŞINDA,
dokunulmaz.

### 4.2 Hedef

**Hareketli ses alanı — `VoiceLevelWave`** (iskelet §6.4; `ListeningWaveform`'un YERİNE geçer, eski
sınıf silinir — iki dalga bileşeni kalmaz):

- Çubuklar GERÇEK ses düzeyini izler. Düzey bir `ValueListenable<double>` (0–1); bileşen kendi
  tek ticker'ında yumuşatır (yükseliş hızlı ~80 ms, düşüş yavaş ~320 ms — olaylar seyrek gelse de
  akıcı). Çubuk boyu = `taban + yumuşatılmış düzey × zarf(i) × titreşim(i, t)`; zarf ortada yüksek,
  uçlarda alçak (çan); titreşim çubuk başına farklı fazlı küçük salınım (canlılık, ±%20).
- Üç okunur hâl: **konuşuyor** (çubuklar düzeyle yükselir, vurgu rengi) · **dinliyor ama sessiz**
  (çubuklar %14 tabanda, 2,4 sn'lik hafif nefes ±%4, vurgu × `AppAlpha.muted`) · **kapalı**
  (`active: false`: 3 dp'lik noktalar, `outlineVariant`, ticker DURUR).
- Çubuk eni sabit 3 dp, aralık 4 dp, uç yarıçapı tam; çubuk SAYISI genişlikten türetilir
  (`(genişlik / 7).floor()` → 16–64 arası) — tablette şişmez.
- TEK ticker + TEK `CustomPaint` + kendi `RepaintBoundary`'si (bugünkü kalıp `:266-347` korunur);
  kare başına widget kurulmaz. Yükseklik 32 (kart orta boyda kalır).
- Hareketi azalt: titreşim ve nefes yok; çubuklar yalnız düzey değişince tek adımda güncellenir.
- Düzey kaynağı: `VoiceListenSession`'a `final ValueNotifier<double> level` (ve aynı kalıpla
  `silence`) eklenir; `:113-114` ve `reportLevel` (`:150`) onu da besler, `_tick` sessizlik oranını
  yazar, oturum kapanırken ikisi de `dispose`. `onSilence` geri çağrısı kalır (levha alt başlığı).
  `level == null` verilirse (düzey bilinmiyor) sabit 0.5 varsayılır — dalga yine yaşar.

**Kart (`ListeningCard`) — aynı orta boy, yeni dil:**

```
┌──────────────────────────────────────────────────────────────┐  ListeningSurface (yeni, aynı dosyada):
│ (◉)  Dinliyorum…                            0:07   [ⓘ] [×]   │   AppSurface.floating(radius: AppRadius.xl),
│      ⌨ Doğrudan yazım · Konuştukça imlece yazılır            │   kenar çizgisi vurgu × AppAlpha.soft
│ [canlı döküm — yalnız yapay zekâ kipinde, en çok 3 satır]     │
│ ▁▂▅▇▅▂▁▂▅▇█▇▅▂▁▂▅▇▅▂▁                         [■ Bitir]      │   VoiceLevelWave 32 · eylem hapı 44
│ ▔▔▔▔▔▔ sessizlik geri sayımı (2 dp) ▔▔▔▔▔▔                    │   yuva HEP ayrılmış; yalnız opaklık değişir
└──────────────────────────────────────────────────────────────┘
```

- Kabuk tek bileşen `ListeningSurface({required ListeningMode mode, required Widget child})`:
  `ListeningCard`, levhanın "işleniyor", "hata" ve "gözden geçirme" evreleri aynı kabuğu kullanır
  (`plainCard` silinir). Gölge yalnız `AppSurface.floatingShadow` (bulanıksız); `elevation`
  parametresi kalkar — editördeki şeritte de aynı yüzey (iki yerde tek görünüş, 2026-10-20 isteği).
- Başlık satırı tek bileşen `ListeningHeader` (rozet · başlık + kip etiketi + alt yazı · süre ·
  düğmeler); levhanın `_header`'ı silinir, onu kullanır.
- Yazı: başlık `AppText.rowTitle` + `AppWeight.strong`; alt yazı ve kip etiketi `AppText.meta`;
  süre `AppText.label` + tabular rakam, dinlerken `error` (kayıt durumu rengi — korunur).
- Dolgu `AppSpace.m`; satır arası `AppSpace.s`; rozet 40; etiket dolgusu `AppSpace.s`/`AppSpace.xxs`,
  simge 12, köşe `AppRadius.s`, zemin vurgu × `AppAlpha.pressed`.
- Rozet nabzı: halka `Transform.scale` + solma (bugünkü, yalnız boyama) — döngü süresi dosya başında
  adlandırılmış sabit; hareketi azalt açıkken halka durur (sabit %20 opak halka).
  AI rozetindeki iki renkli dolgu (`:90-98`) → **S6 sabah bakılacak**; güvenli seçenek: KALIR
  (2026-10-20 "farkı ayırt edilebilsin"; rozet 40 dp, zemin değil).
- Sessizlik geri sayımı kartın İÇİNDE, dalganın altında 2 dp çizgi (`ValueKey('voice-silence-bar')`
  korunur), `ValueListenableBuilder` ile yalnız kendisi kurulur; kart `silence` parametresi alır.
  Editör dikte kartı da gösterir (bulgu 3). Sayım başlayınca alt yazı "Sessizlikte bitecek…"
  (`voiceAutoStopSoon`, var olan metin) — iki kipte de.
- En sınırı: kart `ConstrainedBox(maxWidth: 560)` + ortalı (editörde ve levhada) — telefonda etkisiz.
- `ListeningActionButton`: hap 44, yazı `AppWeight.strong`, dolgu `AppSpace.l`; dinlerken `error`
  zemin KALIR (kayıt durumu; "kaçırılamayacak gösterge" isteği). `ListeningHeaderButton` aynı.

**Belirme (editör dikte kartı):** yuva TEK ADIMDA açılır (bugünkü `if (_dictating)` — ağaç şekli
bugünkünden farklılaşmaz); içerik `PopIn` ile (var olan bileşen, `lib/core/widgets/pop_in.dart:14`;
süre `AppMotion.short`, alttan `rise`). **Çıkış geçişi YOK**: mikrofon kapandığı karede kart kalkar —
"hâlâ dinliyor" görünen tek kare bile yanıltıcıdır.

**Levhanın evreleri (`voice_capture_sheet.dart`):**

- Evre değişimi (dinleme ↔ işleniyor ↔ gözden geçirme ↔ hata): `AnimatedSwitcher`, yalnız solma,
  `AppMotion.quick`; boy tek adım. Anahtar EVRE GRUBU: `idle` ve `listening` AYNI anahtar (basılı-tut
  düğmesi ağaçtan kalkmamalı — `:1319-1322` tuzağı).
- İşleniyor: `ListeningSurface` içinde 24 dp'lik gösterge + metin `AppText.body`; dolgu `AppSpace.xxl`.
- Gözden geçirme: `ListeningHeader` + düzenlenebilir döküm (yazı 16/1.45 korunur — okuma metni) +
  bitiş satırı (düğmeler 48 dp, köşe `AppRadius.m`; "yeniden"/"sürdür" kare 48; YAN YANA düzen ve
  renk rolleri aynı) + "Diğer" çipi/çipler (köşe `AppRadius.s`, yazı `AppText.meta` + strong).
- `_silence` için `setState` yalnız 0 ↔ > 0 geçişinde (alt yazı değişimi); oran çizgisi notifier'dan.

**Kapsam dışı (dokunma):** sesli NOT kaydı hapı (`VoiceRecordPanel`, `voice_note_recorder.dart:211` —
ayrı özellik; onu saran `AnimatedSize` `note_editor_screen.dart:4277-4290` kasma md. 6 adayıdır,
**regresyon listesine not** olarak yazılır, bu planda düzeltilmez) · sesli asistan
(`voice_assistant*.dart`) · Ayarlar → Ses (`settings_voice.dart`, P62) · dikte mantığı
(`note_editor_voice.dart` yazma/birleştirme kuralları).

**S7 sabah bakılacak:** dikte kartına "akıllı komutlar" yardım düğmesi (levhadaki
`voice-commands-help`) eklensin mi? Güvenli seçenek: EKLENMEZ (açtığı pencere editör odağını
düşürür; yeni düğme = yeni davranış).

### 4.3 Durumlar

Dikte: sessiz dinliyor · konuşuyor (alçak/yüksek ses) · sessizlik geri sayımı · bitiş (kart tek karede
kalkar) · klavye açık/kapalı · tablet (kart 560 ortalı) · bölünmüş görünümde ikinci bölme.
Levha: bekliyor ("Başla" / "Basılı tut") · dinliyor · kilitli (kısa dokunuş) · işleniyor · gözden
geçirme (metin / ses eki rozeti / söylenen başlık) · hata · komut geri bildirimi (`✓ …`) ·
kayıt yolu (yerleşik tanıma yok — düzey 200 ms'de bir). Her ikisi: koyu tema · yazı 1.3 (başlık tek
satır, etiket alt satırda — `:486-488` kuralı korunur) · 360 dp · hareketi azalt · `level == null`.

### 4.4 Kabul ölçütleri

- [ ] Düzey 0 iken çubuklar tabanda, 1 iken tavanda; düzey olayı gelmese de dalga akıcı
      (`test/voice_level_wave_test.dart`, iskelette: saf işlevler + ticker'lı widget testi).
- [ ] `listening_visuals.dart`, `voice_capture_sheet.dart` (`_body`, `_header`, `_actions`, `_chips`),
      `note_editor_parts.dart` (`_DictationPanel`) içinde elle köşe/dolgu/punto/süre 0;
      `elevation`/`shadowColor`/`Colors.black` 0; `ListeningWaveform` ve `plainCard` yok.
- [ ] Editör dikte kartında sessizlik çizgisi görünür ve kart yüksekliği dinleme boyunca SABİT
      (widget testi: sayım 0 → 0.5 → 1 iken kart yüksekliği aynı).
- [ ] `test/listening_card_bubble_theme_test.dart` (dikte kartı 90–150 px, AI kartı 130–260 px, yazılı
      "Bitir") yeşil — TEK izinli değişiklik `:61` `find.byType(ListeningWaveform)` →
      `VoiceLevelWave`; `test/voice_unavailable_test.dart` değişmeden yeşil; anahtarlar korunur:
      `listening-card-<kip>`, `listening-mode-<kip>`, `dictation-panel`, `dictation-stop`,
      `voice-listen-action`, `voice-silence-bar`, `voice-commands-help`, `voice-continue`,
      `voice-more`, `voice-title`.
- [ ] 1280 dp genişlikte çubuk eni 3 dp (widget testi boyama ölçüsüyle ya da `barsFor(width)`).
- [ ] Tur: `dikte-kart` (telefon + tablet), `ses-levha-dinliyor`, `ses-levha-hazir`, `ses-levha-hata`
      (açık + koyu). Konuşma kanalı taklidi: `EventChannel('dev.kaimau.notlar/speech')` +
      `MockStreamHandler.inline` (kalıp `test/voice_unavailable_test.dart:13-27`).

### 4.5 Kasma riski + bütçe (kasma-kontrol 8 madde)

1–2: not alanı/satır yok. **3:** düzey ve sessizlik `ValueNotifier`'da; editör kökü düzey olayında
`setState` ALMAZ (kök yalnız başlat/bitir'de kurulur — bugünkü `_update`, `note_editor_voice.dart:123,
147`); `_DictationPanel` `StatelessWidget` kalır, düzeyi yalnız `VoiceLevelWave` dinler. **4:** yeni
sarmalayıcı yok; `if (_dictating)` şekli bugünkü. **5:** "düzey olayı → `_DictationPanel` ve
`ListeningCard` yeniden KURULMAZ" testi (kurulum sayacı). **6:** kartın boyu dinlerken değişmez
(sessizlik yuvası hep ayrılmış); belirme yalnız boyama. **7:** klavyeye bağlı gizleme yok; kart
klavyenin üstünde, `_revealCaretSoon` (`:128`) aynen. **8:** aşağıda. Ek: kartın dış
`RepaintBoundary`'si (`note_editor_parts.dart:236`) KALIR; dalga ve rozet kendi sınırlarında.

**S43 (yeni) — "Dikte (telefon, 30 maddeli liste): başlat → 20 düzey olayı → 5 metin olayı (bir
maddeye) → sessizlik sayımı → Bitir".** Ölç: `NoteEditorScreen`, `NotePageCanvas`, `_ItemRow`,
`ListeningCard` kurulumu. Bütçe: düzey ve sessizlik olaylarında dördü de 0; başlat + bitir toplam kök
kurulumu ≤ 2; metin olayı başına satır kurulumu ≤ 1 (yazılan satır — önce BUGÜNKÜ değer ölçülür,
bütçe ondan kötü olamaz). Kalıp: S2 (`perf_budget_test.dart:468`) + konuşma kanalı taklidi.

Cihaz A/B: **evet** — editör gövdesiyle aynı sütun; 2026-11-13 tablet bulgusunun ("sesle yazma
açıkken kasma") yüzeyi. Evre: "dikte açıkken 30 sn kaydır + yaz" (`ab_hepsi.py`'ye eklenir; taklit
düzey akışıyla — mikrofon izni gerektirmeyen `--dart-define` yoksa "yazıldı, cihazda doğrulanmadı" +
`KONTROL_LISTEM.md`).
