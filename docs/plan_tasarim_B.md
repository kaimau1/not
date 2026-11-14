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
| Kenar rayı hedefleri (tablet/web) | düzenlenemez | `app_frame.dart:617-647` | **SABAH BAKILACAK** (SB1) — varsayılan: dokunma |
| Not üst çubuğu ⋮ ve klavye düğmesi | bilinçli sabit | `personalize.dart:286-287` | **SABİT** (menüye giriş kaybolmasın) |
| Biçim çubuğu düğmeleri (12) | düzenlenemez | `format_bar.dart:647-811` | **SABİT** — genel yapılmayacak: "biçim çubuğunu değiştirmek"; SB2 |
| Kalem tepsisi araçları (7) | düzenlenemez | `pen_tray.dart:23, 324, 589, 961` (`PenTrayTool.values`) | **YAP** (§3.4): hangi kalemler tepside dursun — `UiItem.penTool(<ad>)` |
| Sabit ek çubuğu (T, balon, görünüm, kalem, tam ekran, bağlantı…) | yalnız `videoNoteAt` sarmalı | `pinned_media_pane.dart:1412-1689`; sarma `:1565` | **YAP**: gizlenebilir (varsayılan AYNI; Y10 "⋮'e indirme" yasağı varsayılanı korur, kullanıcının kendi gizlemesi K-O6) — `UiItem.pinned(<ad>)` |
| Sabit ek ⋮ menüsü | `menuId` yok → `MenuLayouts` çalışmaz | `pinned_media_pane.dart` `_openSheet`; `ActionMenu(` yalnız 4 yerde: `dashboard_menu.dart:33,170`, `note_editor_actions.dart:95`, `note_menu_model.dart:49` | **YAP**: `menuId: 'pinned.menu'` |
| Balon dok düğmeleri | düzenlenemez | `bubble_dock.dart:461-724` | **SABİT** (seçime bağlı bağlam çubuğu; gizlemek işlevi kaybettirir) |
| Sesli yakalama levhası | düzenlenemez | `voice_capture_sheet.dart` | **SABİT** (§4'te yeniden tasarım) |
| Not kartı alanları | tek tercih `card_show_checked` | `arayuz.md` "izinli tek yeni tercih" | kapsam dışı (SB3) |

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
  `item_divider_style.dart:44-53`). Rozet 20 dp, simge 12, göz/çizili göz KALIR (SB4).
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
  AI rozetindeki iki renkli dolgu (`:90-98`) → **SB6 sabah bakılacak**; güvenli seçenek: KALIR
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

**SB7 sabah bakılacak:** dikte kartına "akıllı komutlar" yardım düğmesi (levhadaki
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

---

## 5. Madde altı çizgiler ve menüsü

### 5.1 Mevcut durum (kanıt)

Model `domain/note_item.dart:189-229` (`ItemDivider`: `kind` + `color` + `weight` 0.5–3; beş tür
`kinds` `:204-210`: solid, dashed, dotted, double, wavy). Çizim tek işlev `paintItemDivider`
(`presentation/item_divider_style.dart:17-97`), üç kullanıcı: editör satırı
(`editor/items_editor_widgets.dart:360-384` `_ItemDividerPainter`, `left 8 / right −8`,
`y = height − 1`, `baseWidth 2.2`; satıra `foregroundPainter` olarak `items_editor_row.dart:331-337`,
renk vurgu × 0.75 elle), kart (`note_card.dart:1560-1594` `_CardDividerPainter`, `baseWidth 1.2`,
`AppAlpha.muted`), ayar levhası önizlemesi (`item_divider_style.dart:327-347`).

Menü iki parça:
- **Biçim çubuğu tepsisi** `_DividerRow` (`editor/format_bar.dart:945-1016`; açan düğme `:791-798`,
  tepsi seçimi `:583-587`; bağlandığı yer `note_editor_screen.dart:4443-4452` →
  `ItemsEditorState.dividerKindOf/setDividerOf/editDividerStyleOf`, `items_editor.dart:1410-1424`).
- **Çizgi ayarları levhası** `showItemDividerSheet` / `_ItemDividerSheet`
  (`item_divider_style.dart:124-325`), çağıran `items_editor_actions.dart:165-187`
  (`_editDividerStyle`); tür değiştirme/kaldırma `_setDivider` `:147-161`.

Bulgular:
1. Tepside yalnız ÜÇ tür var (`format_bar.dart:1000-1002`: solid/dashed/dotted); çift ve dalgalı
   ancak levhadan seçilir — levhaya giden yol 20 px'lik `Icons.tune` (`:1003-1010`).
2. Tepsideki örnek çizim gerçek çizimle AYNI DEĞİL: `_DividerSwatchPainter` (`:1019-1045`) kendi
   döngüsüyle çiziyor (noktalı = 0.5 px'lik tire, tire başına ayrı `drawLine`), `paintItemDivider`
   kullanmıyor; renk/kalınlık da yansımıyor. Elle ölçüler: köşe 10 (`:967, :973`), boy 32/42
   (`:970, :989`), kalınlık 1.6, iç pay 10.
3. Levha ortak levha değil: çıplak `showModalBottomSheet` + `showDragHandle` (`:127-131`); başlık
   elle `Text` (`:220-225`, `SheetHeader` değil).
4. Levhada tür seçimi YAZILI çip (`ChoiceChip`, `:251-259`) — çizginin kendisi çipte görünmüyor;
   yalnız üstteki 52 dp önizleme kutusu (`:228-243`).
5. Renk noktası 32 dp, seçilince kenar 1 → 3 (`:185-195`); kalem tepsisindeki `_Swatch` ile ayrı
   kılık (§3 bulgu 6) — aynı iş iki kılık. Sabit renkler `_swatches` (`:146-155`) izinli istisna
   (kullanıcının çizgi rengi).
6. Alt satır üç düğme: "Çizgiyi kaldır" `Icons.format_strikethrough` simgesiyle (`:302-307` — yanlış
   simge: üstü çizili yazı), "Tüm çizgilere uygula" metin (`:309-312`), "Tamam" dolu (`:314-317`).
   Değişiklik ancak "Tamam"la uygulanıyor (P50 "anında kaydet" kalıbıyla çelişir — taslak hedef:
   canlı uygula, sayfadaki satırda anında görünür).
7. Çizgi eklenince/kalkınca geçiş yok (satır `CustomPaint` bir karede değişir).
8. Elle ölçüler levhada: dolgu 16/0/16/16 (`:215`), aralıklar 12/14/6/8, önizleme boyu 52.
9. Seçili tür zemini `secondaryContainer` (`format_bar.dart:972`) — aynı çubuğun öbür seçili/açık
   hâllerinin HEPSİ `primaryContainer` (`:856, :1135, :1179, :1250, :1714`); çizgi tepsisi çubuğun
   içinde tek aykırı renk (P62 kuralı da seçim = `primaryContainer`, P62 planı §2.2).
10. "Tema rengi (otomatik)" noktasının işareti `Icons.auto_awesome` (`item_divider_style.dart:198`) —
    uygulamada yapay zekâ simgesi (rol sözleşmesi: ✨ / `tertiary` yalnız AI).
11. Vurgu saydamlığı elle 0.75, üç yerde ayrı yazılı: satır (`items_editor_row.dart:336`), levha
    noktası (`item_divider_style.dart:189`), levha önizlemesi (`:337`).
12. Biçim çubuğu yalnız TÜRÜ biliyor (`FormatBar.dividerKind`, `format_bar.dart:72`;
    `ItemsEditorState.dividerKindOf`, `items_editor.dart:1411-1415`) — renk/kalınlık tepsiye hiç
    ulaşmıyor, örnekler bu yüzden hep gri ve aynı kalınlıkta.
13. Tepsilerin açılışı boy animasyonu: `AnimatedSize`, elle 220 ms + `easeOutCubic`
    (`format_bar.dart:626-636`); çubuk editör gövdesiyle aynı sütunda (`note_editor_screen.dart:4337`
    `Flexible`). Kasma md. 6 adayı — *hipotez: gövdenin tepsi açılırken her karede yeniden dizildiği
    ölçülmedi*. Dört tepsinin ortak kabuğu; "biçim çubuğunu değiştirmek" yasağı kapsamında → bu planda
    DÜZELTİLMEZ, PBT S44 tabanında ölçülür ve `docs/regresyon_listesi.md`'ye not düşülür (§7 "sonraya").

Satır yapısı (beliriş kararı için doğrulandı): satır ayrı bir `State` DEĞİL — `ItemsEditorState`'in
`part` dosyasındaki kurucu işlev (`items_editor_row.dart:1` `part of`, `rowBody` `:326`); çizgi satırı
saran KOŞULSUZ `CustomPaint`'in `foregroundPainter`'ı (`:331-337`, çizgisizde `null`). Satır içinde
kendi ticker'ı olan küçük durumlu parçalar zaten var (`_CheckPop`, `_CheckMove`,
`items_editor_widgets.dart:400-525`; üstü çizili geçişi `items_editor_row.dart:425`). `divider` dizesi
üç karşılaştırmada da var (`note_editor_screen.dart:287`, `items_editor.dart:728`,
`domain/text_merge.dart:151`) ve satır önbelleği anahtarında (`items_editor.dart:1986`).
Çift ve dalgalı tür çizgiyi verilen `y`'nin ÜSTÜNE çizer (`item_divider_style.dart:62-66, 73`).
Beş türün kısa adları çeviride hazır (`dividerKindSolid/Dashed/Dotted/Double/Wavy`,
`app_tr.arb:2888-2892`).

Korunacak istekler (`istek_tara.py`, 2026-11-14'te `format_bar.dart`, `items_editor_row.dart`,
`item_divider_style.dart`, `items_editor_actions.dart`, `items_editor_widgets.dart` yeniden süzüldü): "alta çizgi ekle biçim menüsüne taşındı" (`format_bar.dart:69`,
2026-10-30; `items_editor_actions.dart:75`) · madde menüsü SADE kalır, çizgi türleri oraya dönmez
(`:77`, 2026-10-28) · iki sıra + açılır tepsi, panel küçük (`format_bar.dart:591`, 2026-11-05) ·
TEK ÇİZİM ÇAĞRISI kasma düzeltmesi (`item_divider_style.dart:35`, 2026-11-13: tür başına en çok bir
`drawPoints`/`drawPath`) — bozulmaz. Genel yapılmayacak "biçim çubuğunu değiştirmek": kapsam YALNIZ
`_DividerRow` tepsisinin içi; çubuğun iki sırası, düğmeleri, sırası değişmez.
Bekçi testler: `test/item_divider_paint_test.dart`, `item_divider_style_test.dart`,
`items_editor_divider_test.dart`; anahtarlar `format-divider-<tür>`, `format-divider-style`.

Satır tarafında korunacaklar (`items_editor_row.dart`): satırı opaklık katmanıyla SARMA kasma kök
nedeniydi (`:351`, 2026-10-30) → beliriş katman açmaz; kutucuk/tutamaç hizaları (`:267, :302`) ve
seçim kipinde "satırın her yeri seçer" sarmalayıcısının KOŞULSUZ oluşu (`:320-325`) değişmez.

### 5.2 Hedef

**Tek tür seçici — `DividerKindPicker`** (iskelet §6.5; tepside ve levhada AYNI bileşen,
`_DividerSwatchPainter` silinir):

```
tepsi (boy 42 — DEĞİŞMEZ):   Alt çizgi  [────] [─ ─ ─] [· · · ·] [════] [∿∿∿∿]  (⚙)
levha:                       [────]  [─ ─ ─]  [· · · ·]  [════]  [∿∿∿∿]
                              Düz    Kesikli   Noktalı    Çift    Dalgalı
```

- Beş türün HEPSİ (`ItemDivider.kinds` sırasıyla); her hücre gerçek çizimle — tek
  `paintItemDivider` çağrısı (2026-11-13 "tek çizim çağrısı" kuralı hücrede de geçerli).
- Hücre: `Expanded`, aralık `AppSpace.xs`, çizgi iç payı `AppSpace.s`. Tepside (`compact: true`)
  yükseklik 32, köşe `AppRadius.s`, `baseWidth` 1.6, etiket yok (ipucu + erişilebilirlik adı
  `dividerKind*`). Levhada yükseklik 44, köşe `AppRadius.m`, `baseWidth` 2.2 (satırdaki gerçek değer),
  altında tek satır tür adı (`AppText.meta`, `maxLines: 1`, taşma `ellipsis`) — bugünkü yazılı çiplerin
  bilgisi kaybolmaz.
- Örnekler maddenin KENDİ biçimini taşır (bulgu 12): renk = çizginin rengi (yoksa seçili hücrede
  `onPrimaryContainer`, öbürlerinde `onSurfaceVariant`); kalınlık = çizginin çarpanı — tepside en çok
  1.5'e kırpılır (28 dp'lik hücrede ×3 kesikli tek tire kalıyor; gerçek kalınlık satırda ve levha
  önizlemesinde görünür). Çift ve dalgalı türde `y`, `AppSpace.xxs` aşağı alınır (ortalı dursun).
- Seçili hücre: zemin `primaryContainer` (bulgu 9 — çubuğun kendi dili), `AnimatedContainer` YALNIZ
  renk, `AppMotion.selection` (boy/dolgu sabit). Basış: `InkWell` mürekkebi; ölçek yok.
- Kural aynı: aynı türe yeniden dokunmak çizgiyi kaldırır (`format_bar.dart:69`,
  `items_editor_actions.dart:147-161`); tür değişince renk/kalınlık korunur.
- Anahtarlar: tepside `format-divider-<tür>` (üçü var; `double`, `wavy` yeni), levhada
  `divider-sheet-kind-<tür>`; `format-divider-menu`, `format-divider-style` aynen.

**Tepsi (`_DividerRow`, `format_bar.dart:945-1016`) — yalnız içi:** `Alt çizgi` etiketi
(`labelMedium`, kalır) · `DividerKindPicker(compact: true)` · ayar düğmesi (`Icons.tune_rounded`,
`AppIconSize.m`, `VisualDensity.compact` kalır). Dolgu `AppSpace.m`, etiket–seçici arası `AppSpace.s`.
Tepsi boyu 42 ve çubuğun iki sırası, düğmeleri, sırası DEĞİŞMEZ (2026-11-05 "panel küçük" isteği +
genel yasak). `FormatBar`'a tek yeni isteğe bağlı girdi: `ItemDivider? dividerStyle` (hedef maddenin
biçimi; kaynak `ItemsEditorState.dividerOf(id)` — PBT ekler); `dividerKind` aynen kalır.

**Çizgi ayarları levhası (`_ItemDividerSheet`) — tek sütun, dört parça:**

```
┌ SheetHeader: Çizgi ayarları ───────────────────────────── [×] ┐
│ ┌ kâğıt önizleme (52) ─────────────────────────────────────┐  │  AppTokens.card + hairline, AppRadius.m
│ │ Örnek madde                                               │  │  çizgi: satırdakiyle AYNI geometri
│ │ ───────────────────────────────────────────────────────── │  │  (left 8 / right −8, baseWidth 2.2)
│ └───────────────────────────────────────────────────────────┘  │
│ [────] [─ ─ ─] [· · ·] [════] [∿∿∿]      ← DividerKindPicker (adlı)
│ (A) ● ● ● ● ● ● ● ●  (◎ tümü)            ← ColorDot 28 (§6.6); (A) = tema rengi
│ ≡  ──────●──────────────  1.5×           ← kalınlık: §3 panel satır kalıbı (simge 40 · Slider · değer)
│ [🗑 Çizgiyi kaldır]            [Tüm çizgilere]  [ Tamam ]      │  OverflowBar: sığmazsa alt alta
└────────────────────────────────────────────────────────────────┘
```

- `showAppSheet` (`isScrollControlled: true`, `constraints: BoxConstraints(maxWidth: 640)`;
  `showDragHandle` yazılmaz) + `SheetHeader(title: dividerSettings)`. Bölüm başlıkları ("Tür", "Renk",
  "Kalınlık") KALKAR — parçalar kendini anlatıyor; erişilebilirlik adları `Semantics(label:)` ile
  aynı çeviri anahtarlarından (`dividerKind`, `dividerColor`, `dividerWeight`).
- Dolgu `AppSpace.l`; parçalar arası `AppSpace.m`. Önizleme boyu 52 bugünkü değerde taşınır (yeni
  elle değer eklenmez).
- Renk: `ColorDot` (boy SABİT 28; seçili = 2 dp boşluk + 2 dp `primary` halka, halka
  `AppMotion.selection` ile solar). Sekiz sabit renk (`_swatches`, izinli istisna) + palet dışı özel
  renk + `PaletteButton` aynen. Tema rengi noktası: `primary` × `kItemDividerAccentAlpha`, işareti
  `Icons.brightness_auto_rounded` (bulgu 10).
- Vurgu saydamlığı tek sabit: `const kItemDividerAccentAlpha = AppAlpha.strong`
  (`item_divider_style.dart` başında); satır, levha noktası ve önizleme onu kullanır (bulgu 11;
  0.75 → 0.85 — kart tarafı `AppAlpha.muted` ile AYNEN kalır, `note_card.dart`'a dokunulmaz).
- Kalınlık satırı: `Icons.line_weight_rounded` (40 dp yuva) · `Slider` (`divisions: 10`, sınırlar
  `ItemDivider.minWeight/maxWeight`) · değer `1.5×` (`AppText.meta`, tabular rakam, genişlik 36).
- Alt satır `OverflowBar` (`alignment: end`, `spacing: AppSpace.s`): "Çizgiyi kaldır"
  (`TextButton.icon`, `Icons.delete_outline_rounded` — bulgu 6; `error` rengi DEĞİL, geri alınabilir)
  · "Tüm çizgilere" (`TextButton`) · "Tamam" (`FilledButton` — levhanın tek dolu düğmesi).
- **SB9 sabah bakılacak — canlı uygulama:** seçim satıra anında mı yansısın ("Tamam"sız, P50 kalıbı)?
  Güvenli seçenek: **"Tamam" KALIR** — canlı uygulama kaydırıcının her adımında `_update` + `_commit`
  (satır kurulumu + kayıt) demek, ölçülmedi; levhanın kendi önizlemesi zaten canlı (`:236-242`).

**Çizginin belirişi (PB6 son adımı, AYRI commit — ölçüm kapısı var):** çizgisiz maddeye çizgi
eklenince çizgi soldan sağa çizilir; YALNIZ BOYAMA.
- `items_editor_row.dart:331`'deki `CustomPaint` yerine KOŞULSUZ `_DividerReveal(raw:, color:, child:)`
  (`items_editor_widgets.dart`, `_CheckPop` kalıbı: `SingleTickerProviderStateMixin`,
  `didUpdateWidget`). Çizgisiz satırda da aynı sarmalayıcı (painter `null`) — ağaç şekli koşula bağlı
  değişmez.
- Tetik YALNIZ `didUpdateWidget`'ta `old.raw.isEmpty && raw.isNotEmpty`. `initState`'te oynamaz (not
  açılışı, kaydırmayla gelen satır, "Tüm çizgilere" → animasyon YOK). Tür/renk/kalınlık değişimi ve
  kaldırma tek karede.
- Denetleyici tembel kurulur (ilk tetikte); süre `AppMotion.of(context, AppMotion.short)`, eğri
  `AppMotion.curveOf(context, AppMotion.enter)`; hareketi azalt → doğrudan tam çizgi.
- `_ItemDividerPainter` denetleyiciyi `repaint:` ile dinler (kurulum yok); çizimden önce
  `canvas.clipRect(Rect.fromLTRB(0, 0, size.width × t, size.height))` — `saveLayer`/opaklık katmanı
  YOK (`:351` kök nedeni). Yönlülük: sağdan-sola dilde kırpma sağdan başlar.
- **Kapı:** S44 "beliriş" ölçüsü (aşağıda) + cihaz A/B `kb` ve `bicim` evreleri. Biri kötüleşirse
  bu commit geri alınır; plan maddesine "beliriş: ölçümde kaldı" yazılır, kalan iş etkilenmez.

**Kapsam dışı (dokunma):** ana ekran kartındaki çizgi (`note_card.dart:1560-1594`) · `ItemDivider`
veri biçimi ve `paintItemDivider`'ın çizimi (görünüş bekçisi `item_divider_paint_test.dart:62`) ·
madde uzun basış menüsü (çizgi oraya DÖNMEZ, 2026-10-28) · biçim çubuğunun öbür tepsileri ve
tepsi kabuğu (bulgu 13).

### 5.3 Durumlar

Tepsi: çizgisiz madde (hiçbir hücre seçili değil) · beş türün her biri seçili · kullanıcı renkli çizgi
(sarı, açık zeminde) · kalınlık ×3 (hücrede 1.5'e kırpılı) · hedef başlık/gövde (çizgi düğmesi hiç
yok — `dividerKind == null`, `format_bar.dart:791`) · 360 dp + yazı 1.3 (etiket tek satır, hücrede en
az 24 dp çizgi) · tablet okuma sütunu · koyu tema · hareketi azalt.
Levha: çizgisiz maddeden açılış (düz + son kullanılan renk/kalınlık — `ItemDividerMemory.fresh`,
`items_editor_actions.dart:166-168`) · var olan çizgi · tema rengi · sabit renk · palet dışı özel
renk (dokuzuncu nokta, `:210-211, :272`) · kalınlık 0.5 / 1 / 3 · "Tüm çizgilere" · kaldır · vazgeç
(dışına dokun / geri / × → değişiklik yok) · yazı 1.3 (alt düğmeler alt alta) · geniş ekran (640
ortalı) · koyu tema.
Satır: çizgi beliriyor · tür değişti (anında) · kalktı (anında) · çizgili defter (`paperLines`: çizgi
satır çizgisinin üstüne düşer, `items_editor_widgets.dart:373-375`) · işaretliler bloğu · seçim kipi ·
sürüklenen satır · sağdan-sola dil.

### 5.4 Kabul ölçütleri

- [ ] Tepside ve levhada beş tür; hücre başına tek `paintItemDivider` çağrısı
      (`test/divider_kind_picker_test.dart`, iskelette: beş anahtar, seçili hücre, dokunuş →
      `onPick(tür)`, verilen renk/kalınlık boyamaya ulaşır, tepside kalınlık ≤ 1.5).
- [ ] `format_bar.dart`'ta `_DividerSwatchPainter` yok; `_DividerRow` içinde elle köşe/dolgu 0 (tepsi
      boyu 42 dışında); seçili zemin `primaryContainer`.
- [ ] `item_divider_style.dart`'ta `showModalBottomSheet` 0, `Icons.format_strikethrough` 0,
      `Icons.auto_awesome` 0, elle dolgu/aralık 0 (önizleme boyu 52 ve `_swatches` renkleri dışında);
      elle `0.75` üç yerde de 0.
- [ ] Var olan testler DEĞİŞMEDEN yeşil: `item_divider_paint_test`, `item_divider_style_test`,
      `items_editor_divider_test`, `format_bar_test`, `items_editor_row_cache_test`,
      `forward_compat_test`, `jank_patterns_guard_test`, `keyboard_jank_guard_test`.
- [ ] Yeni `test/item_divider_sheet_test.dart`: tür hücresi → önizleme o türde; "Tamam" →
      `(style, applyAll: false)`; "Tüm çizgilere" → `applyAll: true`; kaldır → `style: null`; dışına
      dokun → `null`; 360 dp + yazı 1.3'te taşma hatası yok.
- [ ] Beliriş (yapıldıysa): boş → çizgili geçişte animasyon bir kez oynar ve durur; 10 çizgili not
      AÇILIRKEN ilk karede çizgiler tam (ticker yok); hareketi azalt açıkken tek kare
      (`test/item_divider_reveal_test.dart`).
- [ ] Tur: `cizgi-tepsi`, `cizgi-levha`, `cizgi-satirlar` (beş tür aynı notta) — açık + koyu, telefon
      + tablet.

### 5.5 Kasma riski + bütçe (kasma-kontrol 8 madde)

**1:** yeni madde alanı yok (`divider` dizesi üç karşılaştırmada var — §5.1). **2:** önbellek
anahtarında `item.divider` var (`items_editor.dart:1986`); beliriş durumu anahtara GİRMEZ
(`_DividerReveal`'in kendi `State`'i; satır widget'ı aynı örnek). `dividerStyle` her build'de yeni
nesne olsa da satır env'ine girmiyor (yalnız `FormatBar` girdisi). **3:** tepside seçim yeni kök
`setState` EKLEMEZ; bugünkü yol (`setDividerOf` → `_update` + `_commit`) aynen — *hipotez: seçimden
sonra tepsinin seçili hücresini tazeleyen şey kök kurulumu; PBT tabanda `kok_kurulum`'u ölçer, PB6
onu aşamaz*. **4:** `CustomPaint` → `_DividerReveal` değişimi koşulsuz (her satırda, her kipte).
**5:** "çizgi eklenen satır dışındaki 29 satır `identical`" testi (`items_editor_row_cache_test`
kalıbı, `:106-127`). **6:** tepsi boyu 42 sabit; seçici boy değiştirmez; beliriş yalnız boyama.
Tepsi kabuğunun `AnimatedSize`'ı var olan, kapsam dışı (bulgu 13). **7:** seçici
`TextFieldTapRegion` içinde kalır (`format_bar.dart:611` — odak ve klavye düşmez); klavyeye bağlı
yeni gizleme yok. **8:** aşağıda.

**S44 (yeni) — "30 maddeli liste (telefon), 10 maddesi çizgili (her türden iki): bir maddeye odaklan
→ Biçim → çizgi tepsisini aç → düz seç → dalgalıya çevir → aynı türe dokun (kaldır) → tepsiyi kapat
→ klavye aç/kapa ×1 (S8 kareleri)".** Ölç: `NoteEditorScreen`, `ItemsEditor`, satır (S2'nin `satir`
sayacı) ve klavye karelerinde gövde türleri (S8'in `_bodyTypes`). Bütçe: seçim başına satır kurulumu
≤ 1 (üç seçim → ≤ 3), öbür 29 satır `identical`; tepsi aç/kapa'da satır 0; klavye karelerinde gövde
kurulumu S8 bütçesinden kötü olamaz (çizgili liste = çizgisiz liste); kök ve `ItemsEditor` kurulumu
PBT'nin ölçtüğü BUGÜNKÜ değeri aşamaz. Beliriş ölçüsü: çizgi eklendikten sonraki 200 ms'de (12 kare)
satır kurulumu 0, `ItemsEditor` kurulumu 0. Kalıp: S8 (`perf_budget_test.dart:557-596`) + S2.

Cihaz A/B: **evet** — klavye açılışında çizgili liste 2026-11-13 bulgusunun yüzeyi. Evreler: var olan
`kb` + yeni `bicim` (not aç → klavye → Biçim → çizgi tepsisi aç/kapa ×3 → tür seç ×3; PBT ekler),
ölçüm notu çizgili olmalı (HAZIRLIK notuna 10 çizgi).

## 6. İskelet tanımı (PB0 yazar; bu belgede KOD YOK, yalnız sözleşme)

İskelet = altı küçük, kendi başına derlenen ve testli bileşen. Hiçbiri bir ekrana BAĞLANMAZ (bağlamak
paketlerin işi); böylece PB0 görünür değişiklik üretmez, `[apk]` gerektirmez.

### 6.0 Ortak kurallar ve P62 uyumu

- **P62 iskeleti main'de DEĞİL** (2026-11-14): `origin/oto/P62-tasarim-A` dalında
  `lib/app/theme/app_design.dart` (`AppTone`, `AppSurface.group/paper/floating/floatingShadow`,
  `AppSwipe`), `app_tokens.dart` ekleri (`AppMotion.selection = short`,
  `AppMotion.emphasized = Curves.easeOutCubic`, `AppMotion.exitOf(d) = d × 2/3`),
  `lib/core/widgets/app_banner.dart`, `app_notice.dart`. Sözleşme: P62 planı
  (`git show origin/oto/P62-tasarim-A:docs/plan_tasarim_A.md`) §1.
- **PB0 P62'ye bağımlı OLMAZ:** iskelet dosyaları `app_design.dart`'ı içe aktarmaz. P62 adı gereken
  yerde EŞDEĞER var olan belirteç + satır sonu notu yazılır, paket (PB3/PB5/PB6) P62 main'e girince
  çevirir:

  | P62 adı | İskelette yazılacak eşdeğer | Not |
  |---|---|---|
  | `AppMotion.selection` | `AppMotion.short` | `// P62: AppMotion.selection` |
  | `AppMotion.emphasized` | `AppMotion.enter` | `// P62: AppMotion.emphasized` |
  | `AppMotion.exitOf(d)` | `AppMotion.quick` (short'un çıkışı) | `// P62: AppMotion.exitOf` |
  | `AppSurface.paper(theme)` | `AppTokens.fromTheme(theme)` → `card` + `hairline` (`app_tokens.dart:69, 72, 85`) | kâğıt zemin |
  | `AppSurface.floating(...)` | iskelette KULLANILMAZ (kapsül/kart kabuğu PB3/PB5'in) | — |

- **Seçim rengi tek kural (P62 planı §2.2):** seçili hücre/segment zemini `primaryContainer` /
  `onPrimaryContainer`, geçiş yalnız renk + `AppMotion.selection`. `DividerKindPicker` ve `ColorDot`
  halkası buna uyar. İSTİSNA (bugünkü kılık korunur, SB8): `CustomizeBoard`'un "görünen" karosu
  `secondaryContainer` (kullanıcının 2026-11-13'te istediği hızlı satır düzenleyicisinin kılığı,
  `quick_row_editor.dart:286`) ve M3 çiplerinin varsayılan seçili rengi (§2.2 bölüm çipleri).
- Elle ölçü yok; her animasyon `AppMotion.of` + `AppMotion.curveOf`; editör/kart dosyalarından
  çağrılacak bileşenler `Theme.of(context)` yerine girdi olarak `ThemeData`/renk alır ya da çağıranın
  `_themeOf` kalıbına uyar (§0).
- Yeni dosyalara `dart format` (yalnız kendi dosyan). `lib/l10n/generated` elle düzenlenmez
  (`flutter gen-l10n` + `dart format lib/l10n/generated`).
- Her iskelet dosyasının başında tek satır: `// P63 iskelet — docs/plan_tasarim_B.md §6.x`.

### 6.1 `CustomizeBoard` — `lib/core/widgets/customize_board.dart` (§1.2)

```dart
typedef CustomizeEntry = ({String id, IconData icon, String label});

class CustomizeBoard extends StatelessWidget {
  const CustomizeBoard({
    super.key,
    required this.entries,         // yüzeyin TÜM öğeleri, varsayılan sırada
    required this.shown,           // görünenlerin kimlikleri, EKRAN sırasıyla
    required this.onToggle,        // void Function(String id, bool visible)
    this.onReorder,                // void Function(int oldIndex, int newIndex); null = sırasız
    this.onReset,                  // null = "Varsayılana dön" çizilmez
    required this.shownLabel,
    required this.availableLabel,
    this.emptyLabel,
    this.resetLabel,
    this.keyPrefix = 'customize-', // karo: '$keyPrefix<id>', önizleme: '${keyPrefix}preview', sıfırla: '${keyPrefix}reset'
    this.trailingOf,               // Widget? Function(String id): karonun sonundaki ikincil düğme
  });
}
```

Doğrulanmış kod gerçekleri:
- Bugünkü karo kılığı `_Tile` (`quick_row_editor.dart:266-300`): `Material`, köşe `AppRadius.m`,
  menüde `secondaryContainer`, değilse `surface` + `outlineVariant` çizgi — pano bunu AYNEN taşır.
- Anahtar uyumu zorunlu (testler dokunuyor): hızlı satır `quick-row-edit-<k>`, `quick-row-edit-reset`,
  `quick-row-editor-preview` (`quick_row_editor.dart:162, 204, 219, 231`) → çağıran
  `keyPrefix: 'quick-row-edit-'` verir, önizleme anahtarını `KeyedSubtree` ile kendi sarar. Çubuk
  listesi `bar-switch-<id>`, `bar-move-<id>`, `personalize-bar-<grup>`, `personalize-bar-reset`
  (`personalize_bar_list.dart:88, 154, 174, 192`; `test/editor_bar_customize_test.dart:183-231`) →
  `keyPrefix: 'bar-switch-'`, "öbür kapsüle taşı" `trailingOf` ile `bar-move-<id>` düğmesi olarak
  KALIR (§1.2'deki "uzun bas = taşı" ek kısayoldur, düğmenin yerine geçmez).
- Sıra birleştirme `UiPrefs.orderOf(defaults, saved)` (`personalize.dart:66-78`) — pano sıra
  HESAPLAMAZ, yalnız `shown` listesini çizer.
- Önizleme şeridi yatay `ReorderableListView` (`buildDefaultDragHandles: false`); `onReorder == null`
  ise düz `Row`.

Test `test/customize_board_test.dart`: karoya dokun → `onToggle(id, !visible)`; görünenler `shown`
sırasında; `onReorder == null` iken sürükleme tutamağı yok; tümü görünürken "Eklenebilir" başlığı
çizilmez; hiç görünen yokken `emptyLabel`; anahtar öneki.

### 6.2 `TemplatePreviewCard` — `lib/features/notes/presentation/template_preview_card.dart` (§2.2)

```dart
enum TemplateLineKind { heading, check, number, bullet, text, gap }

List<TemplateLineKind> templatePreviewLines({
  required NoteType type, required String body, required List<String> items, int max = 5,
});

class TemplatePreviewCard extends StatelessWidget {
  const TemplatePreviewCard({
    super.key,                     // çağıran verir: ValueKey('tpl-card-<key>')
    required this.lines, required this.accent, required this.icon, required this.name,
    required this.onTap,
    this.favorite = false, this.onFavorite, this.favoriteKey,   // ValueKey('tpl-fav-<ad>')
    this.onMenu, this.onLongPress,
  });
}
```

Doğrulanmış kod gerçekleri: içerik türü `NoteTemplateContent = ({NoteType type, String title, String
body, List<String> items, int columns})` (`domain/note_templates.dart:49-55`); 16 hazır şablon
`enum NoteTemplate` (`:26-43`), kimlik `key => name`; kendi şablonu `UserTemplate{id, name, type,
title, body, items}` (`data/user_templates.dart:29-37`); `NoteType { text, checklist, ordered, … }`
(`domain/note_type.dart:10`). Bugünkü kart `_TemplateCard` (`note_template_sheet.dart:712`) — PB4 onu
bu bileşenle değiştirir. Minyatür tek `CustomPaint`, metin dizimi YOK (`RenderParagraph` yalnız alt
banttaki ad).

Test `test/template_preview_lines_test.dart`: liste → `check`×n; sıralı → `number`; `# ` → `heading`;
`☐`/`•`/`-` satırları; boş satır → `gap`; `max` kırpması; boş içerik → boş liste. Kart widget testi:
`favorite` yıldızı, `onMenu` hedefi (alt bandın sağ 40 dp'si), yazı 1.3'te ad tek satır.

### 6.3 `PenStrokePreview` — `lib/features/notes/presentation/editor/pen_stroke_preview.dart` (§3.2)

```dart
class PenStrokePreview extends StatefulWidget {
  const PenStrokePreview({
    super.key,
    required this.argb,      // kalemin SON rengi (saydamlık uygulanmış): InkController.penColor.toARGB32()
    required this.widthPx,   // InkController.widthPx
    this.compact = false,    // sabit kalem çipi: 30 × 30 daire içinde kısa çizgi
  });
}

/// S eğrisi; [size] önizleme kutusu. Saf işlev — testte doğrudan çağrılır.
InkStroke penPreviewStroke({required int argb, required double widthPx, required Size size, bool compact = false});
```

Doğrulanmış kod gerçekleri:
- Tek çizim yolu `paintInkStroke(Canvas, Size, InkStroke, {bool cache = true})`
  (`viewers/ink_stroke_paint.dart:21-26`); kalem TÜRÜ renkten okunur — ayrı tür girdisi GEREKMEZ:
  fosforlu = alfa tam 0x66 → düz uç (`viewers/ink_pen.dart:80-88`, `InkPen.highlighter` `:34`), dolma
  kalem = alfa 0xFE → değişken kalınlık (`inkIsFountain` `:91`, `ink_stroke_paint.dart:48-49`,
  `fountainRadii`).
- `InkStroke.width` sayfa GENİŞLİĞİNİN oranı (`domain/attachment.dart:70-71`); ekranda
  `widthPx / size.width` ile yazılır (`viewers/ink_layer.dart:1257`) → önizlemede de
  `width = widthPx / size.width` (ekrandaki gerçek kalınlık). `compact`'ta `widthPx`, kutu boyunun
  %45'ine kırpılır (46 px'lik fosforlu 30 px daireden taşmasın).
- Son renk `InkController.penColor` (`ink_layer.dart:575-577`: sabit saydamlıklı kalemde
  `pen.apply(color)`, öbürlerinde `color.withAlpha(pen.alpha × opacity)`). Sabit kalem kaydı
  SAYDAMLIKSIZ rengi tutar (`currentPreset`, `ink_layer.dart:880-881`; `InkPreset{pen, color, width}`
  `ink_tools.dart:470-479`) → çipte `argb = InkPen.values[p.pen].apply(Color(p.color)).toARGB32()`.
- Geometri önbelleği çizgi ÖRNEĞİNE bağlı (`_geom` `Expando`, `ink_stroke_paint.dart:85`) → bileşen
  `StatefulWidget`: `InkStroke` yalnız `(argb, widthPx, compact, boyut)` değişince yeniden üretilir
  (aynı girdi → `identical` örnek; kaydırıcı sürüklenirken adım başına bir kez). Kendi
  `RepaintBoundary`'si.
- *Hipotez:* dolma kalemin "hızlı çizgide incelir" etkisi nokta aralığından türüyor
  (`fountainRadii` okunmadı) — PB0 okur; öyleyse S eğrisinin uçlarında nokta aralığı açılır, değilse
  örnek `pressures` verilir.

Test `test/pen_stroke_preview_test.dart`: fosforlu girdide boyanan renk alfası 0x66; aynı girdiyle iki
kurulumda `InkStroke` `identical`; `widthPx` değişince yeni örnek; `compact` kırpması.

### 6.4 `VoiceLevelWave` — `lib/features/notes/presentation/voice_level_wave.dart` (§4.2)

```dart
class VoiceLevelWave extends StatefulWidget {
  const VoiceLevelWave({
    super.key,
    required this.active,          // false: noktalar, ticker DURUR
    required this.color,
    this.level,                    // ValueListenable<double>? (0–1); null = sabit 0.5
    this.idleColor,                // varsayılan outlineVariant
    this.height = 32,
  });
}

int waveBarsFor(double width);                                        // (width / 7).floor().clamp(16, 64)
double smoothLevel(double current, double target, Duration dt);       // yükseliş ~80 ms, düşüş ~320 ms
double waveBarFactor(int i, int n, double level, Duration t, {bool reduceMotion = false});  // 0–1
```

Doğrulanmış kod gerçekleri: yerini alacağı `ListeningWaveform` (`listening_visuals.dart:271-290`:
`active`, `color`, `idleColor`, `height = 48`, `bars = 24`; tek `Ticker` + `ValueNotifier<Duration>` +
tek `CustomPaint`) — kalıp aynen korunur, yalnız girdi ve çarpan değişir. İskelette eski sınıf
SİLİNMEZ (PB5 siler; `test/listening_card_bubble_theme_test.dart:61` o türe bakıyor). Düzey kaynağı
PBT'de eklenir: `VoiceListenSession.level` / `.silence` (`ValueNotifier<double>`), besleme noktaları
`data/voice_listen_session.dart:113-114` (cihaz tanıması), `:150` (`reportLevel`), `:152` (`_tick`),
kapanış `:184-199` (`stop`).

Test `test/voice_level_wave_test.dart`: `waveBarsFor(360) == 51`, `waveBarsFor(1280) == 64`,
`waveBarsFor(80) == 16`; `smoothLevel` yükselişte düşüşten hızlı; düzey 0 → çarpan tabanda (≤ 0.2),
1 → tavanda (≥ 0.8 orta çubukta); `reduceMotion` → zamanla değişmez; widget: `active: false` iken
`tester.binding.hasScheduledFrame` yanlış; düzey olayı gelince widget KURULMAZ (yalnız boyama).

### 6.5 `DividerKindPicker` — `lib/features/notes/presentation/divider_kind_picker.dart` (§5.2)

```dart
class DividerKindPicker extends StatelessWidget {
  const DividerKindPicker({
    super.key,
    required this.selected,                 // '' = çizgi yok
    required this.onPick,                   // ValueChanged<String> (tür)
    this.style,                             // ItemDivider?: renk + kalınlık örneklere yansır
    this.compact = false,                   // tepsi: 32 dp, adsız, kalınlık ≤ 1.5; levha: 44 dp + ad
    this.keyPrefix = 'format-divider-',
  });
}

String dividerKindLabel(AppLocalizations l10n, String kind);   // dividerKind* — levhadaki _kindLabel'ın açığa çıkmışı
```

Doğrulanmış kod gerçekleri: türler `ItemDivider.kinds` (`domain/note_item.dart:204-210`); çizim
`paintItemDivider(canvas, style:, fallbackColor:, left:, right:, y:, baseWidth:)`
(`item_divider_style.dart:17-25`); çift/dalgalı `y`'nin üstüne çizer (`:62-66, 73`); adlar
`_kindLabel` (`:157-166`). Dosya `format_bar.dart`'tan (editör) ve `item_divider_style.dart`'tan
çağrılır → `Theme.of(context)` yerine renkleri `ColorScheme` girdisiyle ya da `_themeOf` kalıbıyla
alır (§0 kuralı; `format_bar.dart` bugün `Theme.of` kullanıyor `:601` — PB6 var olanı bozmaz, yenisini
eklemez).

Test `test/divider_kind_picker_test.dart`: §5.4 birinci madde.

### 6.6 `ColorDot` — `lib/core/widgets/color_dot.dart` (§3.2 "tek renk noktası", §5.2)

```dart
class ColorDot extends StatelessWidget {
  const ColorDot({
    super.key,
    required this.color,
    required this.selected,
    this.size = 28,          // nokta çapı; kapladığı alan HER ZAMAN size + 8 (halka payı) — seçilince boy değişmez
    this.onTap, this.tooltip,
    this.child,              // ortadaki işaret (ör. tema rengi simgesi)
  });
}
```

Aynı iş bugün dört ayrı kılıkta: kalem tepsisi `_Swatch` (`pen_tray.dart:1063-1126`), panel `dot()`
(`:1229-1255`), sütun `_colorDot` (`:825-852`), çizgi levhası `_swatch` (`item_divider_style.dart:173-202`).
§3.2'de "`_Swatch`" diye geçen bileşen BUDUR: PB3 üçünü, PB6 dördüncüsünü `ColorDot`'a çevirir.
Seçili = 2 dp boşluk + 2 dp `primary` halka (halka rengi `AppMotion.selection` ile solar); açık renkli
noktanın ince kenarı `pen_tray.dart` `_Swatch`'taki bugünkü değerle taşınır. Renk paletinin kendi
`_Swatch`'ı (`core/widgets/color_palette.dart:184`) kapsam DIŞI (§7 "sonraya").

Test `test/color_dot_test.dart`: seçili/seçisiz aynı boyut; dokunuş; `child` ortalı.

### 6.7 Çeviri anahtarları (hepsi PB0'da, iki `.arb` + üretilmiş dosyalar; sonraki paketler `.arb`'ye DOKUNMAZ)

`.arb` değişimi CI'da tam takımı koşturur ve paketler arası çakışmanın baş kaynağıdır. PB0 önce
`grep` ile var olanı arar; yalnız OLMAYANI ekler (tr + en, `test/arb_case_test.dart` ve
`test/terminology_test.dart` yeşil):

| Nerede | Metin (tr) | Aday anahtar | Not |
|---|---|---|---|
| §1.2 mod şeridi | "Sırala" | `customizeReorder` | düğme ipucu |
| §1.2 ilk giriş ipucu | "Dokun: gizle/göster · Sırala: yerini değiştir" | `customizeHint` | P62 ipucu bileşeniyle gösterilir |
| §1.2 pano başlıkları | "Görünenler · {n}", "Eklenebilir · {n}", "Varsayılana dön" | var olanı ara (hızlı satır düzenleyicisi "Menüde / Eklenebilir") | yoksa `customizeShown/Available/Reset` |
| §1.2 hub yüzey adları | Alt çubuk, Üst çubuk, Hızlı satır, "+" paneli, Ekle, Ana ekran, Video, Sabit ek, Kalemler, Eklentiler | var olanı ara (Kişiselleştir bölüm başlıkları) | yoksa `customizeSurface*` |
| §3.2 | "Sabitlemeyi kaldır" | `inkUnpinPen` | `inkPinPen` var (`app_tr.arb:3671`) |
| §4.2 | — | — | `voiceAutoStopSoon` var (`:2406`) |
| §5.2 | — | — | `dividerKind*`, `dividerSettings`, `itemDividerRemove`, `dividerApplyAll` var (`:2705, :2882-2892`) |

Paket sırasında yeni metin gerekirse: paket onu KENDİ dalında ekler ve commit başlığına `[tam]` yazar;
yürütücü o dalı tek başına birleştirir (paralel `.arb` değişimi yok).

## 7. Uygulama paketleri

### 7.0 Bölme, model, sıra

**Model kuralı (kullanıcı kararı 2026-11-14):** GÖRÜNÜŞÜ belirleyen her paket **fable** (Opus ve Sonnet
görsel işi güzel yapamıyor). **opus** yalnız görsel olmayan altyapı ve kasma/ölçüm işleri; **sonnet**
yalnız CI, test koşturma, birleştirme, sürüm notu gibi mekanik işler. Fable paketleri gece limit
frenine tabidir: her alt adım AYRI commit + push, `DEVIR.md` güncel — kesilirse sıradaki tur DEVIR'den
sürer (bu belgenin kendisi iki kez limitte kesildi).

| Paket | İş | Dosya kümesi | Model | Bağımlılık | Görünür | Cihaz A/B | Bütçe |
|---|---|---|---|---|---|---|---|
| PB0 | iskelet: altı bileşen + testleri + tüm çeviri anahtarları (§6) | §6.1–6.6 dosyaları, `test/*` (altı yeni test), `lib/l10n/*` | fable | — | hayır | hayır | — |
| PBT | taban ölçüm + görsel olmayan altyapı | `core/personalize.dart`, `data/voice_listen_session.dart`, `editor/items_editor.dart` (yalnız `dividerOf`), `test/perf_budget_test.dart`, `test/perf_budget/budgets.json`, `tool/tour/screen_tour_test.dart`, `tool/perf/ab_hepsi.py`, `test/personalize_order_test.dart` (yeni) | opus | — (PB0 ile PARALEL) | hayır | hayır (evreler A=A ile denenir) | S40–S44 tabanı |
| PB1 | düzen modu: şerit + çerçeve (§1.2 "yerinde mod") | `core/widgets/customizable.dart` | fable | PB0, PBT; **P62 iskeleti main'de** | evet | evet | S40 |
| PB2 | düzen merkezi + panolar (§1.2 `CustomizeHub`, b–e) | `settings/presentation/customize_hub.dart` (yeni), `personalize_screen.dart`, `personalize_bar_list.dart`, `editor/quick_row_editor.dart`, `action_menu_sheet.dart` (yalnız düzenle gövdesi `:560-702`), `quick_add_fab.dart` (yalnız düzenle gövdesi `:595-721`) | fable | PB1 | evet | hayır | S40 |
| PB3 | kalem seti (§3) | `editor/pen_tray.dart` | fable | PB0, PBT; **P62 iskeleti main'de** | evet | evet | S42 |
| PB4 | şablonlar (§2) | `note_template_sheet.dart`, `template_editor_screen.dart` | fable | PB0, PBT | evet | hayır | S41 |
| PB5 | sesle yazma (§4) | `listening_visuals.dart`, `voice_capture_sheet.dart`, `editor/note_editor_parts.dart` (`_DictationPanel`), `editor/note_editor_voice.dart` (yalnız oturum kurulumu), `editor/note_editor_screen.dart` (yalnız `:4291-4295`) | fable | PB0, PBT; **P62 iskeleti main'de** | evet | evet | S43 |
| PB6 | madde çizgileri (§5) | `item_divider_style.dart`, `editor/format_bar.dart` (yalnız `_DividerRow` + bir girdi), `editor/items_editor_row.dart` (yalnız `:331-337`), `editor/items_editor_widgets.dart` (`_ItemDividerPainter` + `_DividerReveal`), `editor/note_editor_screen.dart` (yalnız `:4443-4452`) | fable | PB0, PBT | evet | evet | S44 |
| PB7 | yeni sarmalar + sıralar (§1.1 envanter "YAP") | `editor/editor_quick_row.dart`, `attach_sheet.dart`, `video_transport.dart`, `editor/note_editor_screen.dart` (yalnız `:3428` çevresi), `editor/pinned_media_pane.dart`, `dashboard_screen.dart` (yalnız takvim şeridi / hızlı yakalama anahtar bağlantısı gerekiyorsa) | opus (high) | PB1, PB2 | yalnız düzen modunda | evet | S40 |
| — | CI izleme dışı mekanik işler: birleştirme, `[apk]`, sürüm notu, Kuyruk | — | sonnet (yürütücünün tek CI ajanı) | her paket | — | — | — |

**Sıra:**

```
PB0 ∥ PBT ──► PB4 ∥ PB6                      (P62 beklemez)
        └──► [P62 iskeleti main'de] ──► PB1 ∥ PB3 ∥ PB5
                                        PB1 ──► PB2 ──► PB7
```

- "P62 iskeleti main'de" = `lib/app/theme/app_design.dart` ve `AppMotion.selection/emphasized/exitOf`
  main'de derleniyor (P62'nin 12b1842d + 07f9429e commit'leri; P62'nin uygulama paketleri PA1–PA9
  BEKLENMEZ). PB1/PB3/PB5 başlarken `git grep -n "class AppSurface" origin/main -- lib` boşsa paket
  BAŞLAMAZ (§0'daki "geçici yerel sabit" kaçışı yalnız PB4/PB6 içindir).
- Paralel koşanların dosya kümeleri kesişmez; TEK istisna `editor/note_editor_screen.dart` — PB5
  (`:4291`), PB6 (`:4443`), PB7 (`:3428`) ayrı satırlara dokunur. İkinci birleşen dal önce
  `git merge origin/main` yapar; `test/jank_patterns_guard_test.dart` (kök dosyadaki
  `AnimatedSize`/`AnimatedContainer` sayacı) yeşil kalmalı.
- Ortak dosyalar: `test/perf_budget_test.dart`, `budgets.json` (senaryoları PBT yazar; paketler yalnız
  KENDİ senaryosunun sayılarını düşürür), `tool/tour/screen_tour_test.dart` (sahneleri PBT yazar;
  paketler yalnız kendi sahnesinin adımlarını düzeltir). Çakışmada iki taraf da alınır.
- **`[apk]` öbekleri (F58.4: en çok 5 görünür değişiklik):** (1) PB4 + PB6 · (2) PB3 + PB5 ·
  (3) PB1 + PB2 + PB7. PB0 ve PBT tek başına `[apk]` üretmez. Her öbekten önce bütçe testleri yeşil +
  tam ölçüm (`ab-olcum`: önceki `[apk]` %20, altın taban %15).
- Her paketin sonu (`isci` "Bitiş"): Kuyruk satırı, bu belgede ilgili kabul kutuları `[x]` + tarih,
  `docs/regresyon_listesi.md`, ilgili `docs/hafiza/*.md` (PB1/PB2/PB7 → `arayuz.md`; PB3 → `kalem.md`;
  PB5 → `ai_ses.md`; PB6 → `editor.md`; ölçümler → `akicilik.md`), sürüm notu taslağı (tr + en),
  cihazda bakılamayan her görünür değişiklik `KONTROL_LISTEM.md` "Telefonda bak".

### 7.1 PB0 — iskelet (fable)

- **Kanıt:** §6 (imzalar ve doğrulanmış kod gerçekleri). Bugün altı bileşenin hiçbiri yok
  (`ls lib/core/widgets/customize_board.dart …` → yok).
- **Önce üret:** altı test dosyası KIRMIZI (derlenmez): `customize_board_test`,
  `template_preview_lines_test`, `pen_stroke_preview_test`, `voice_level_wave_test`,
  `divider_kind_picker_test`, `color_dot_test` (içerikleri §6.1–6.6 "Test" satırları).
- **Kabul:** altı test yeşil; `flutter analyze` temiz; `test/design_tokens_guard_test.dart` mandalı
  YÜKSELMEZ (yeni dosyalarda elle ölçü 0 — §6.2 minyatürün 4/9/64'ü ve §6.4 dalganın 3/4/7'si dosya
  başında adlandırılmış `const`); `test/arb_case_test.dart`, `terminology_test.dart`,
  `localization_test.dart` yeşil; hiçbir var olan dosya iskeleti içe aktarmıyor (bağlama yok).
- **Tuzaklar:** P62'yi içe aktarma (§6.0 tablosu) · `.arb` değişimi tam takımı koşturur — tek commit'te
  topla · üretilmiş çeviri dosyasını elle düzenleme · `PenStrokePreview` `viewers/ink_stroke_paint.dart`'ı
  içe aktarır (editör → viewers yönü zaten var: `pen_tray.dart:18`) · `ColorDot` `core/`'da — `features/`
  içe aktaramaz · iskelette yeni `Theme.of(context)` editör dosyasına sızmasın (bileşenler ayrı dosyada).
- **A/B / bütçe:** yok (görünür değişiklik yok).

### 7.2 PBT — taban ölçüm + görsel olmayan altyapı (opus)

Amaç: protokolün "önce kanıtı üret" adımını BEŞ yüzey için tek seferde, görünüş değişmeden yapmak;
fable paketlerine yalnız görsel iş kalsın. Her alt adım ayrı commit.

1. **Tercih alanları** (`core/personalize.dart`): `UiPrefs.quickOrder`, `attachOrder`
   (`List<String>`, boş = varsayılan; `orderOf` `:66-78` ile birleşir; `toJson` yalnız doluysa yazar;
   `==`/`hashCode`/`copyWith`/`fromJson`); `UiItem.pinned(key)` → `'pinned.$key'`,
   `UiItem.penTool(key)` → `'pen.tool.$key'` (kalıp `UiItem.quickRow` `:323`, `attach` `:361`).
   Test `test/personalize_order_test.dart`: gidiş-dönüş, eski kayıt (alan yok) aynen okunur, bilinmeyen
   kimlik atlanır. HİÇBİR ekran bu alanları henüz okumaz.
2. **Ses düzeyi yayını** (`data/voice_listen_session.dart`): `final ValueNotifier<double> level`,
   `silence`; `:113-114` ve `reportLevel` (`:150`) `level`'ı, `_tick` (`:152`) `silence`'ı besler;
   `stop` (`:184-199`) ikisini sıfırlar; `onSilence` geri çağrısı AYNEN kalır. Test: sahte akışla
   düzey olayı → `level.value`; oturum bitince 0.
3. **Çizgi biçimi okuma** (`editor/items_editor.dart`): `ItemDivider? dividerOf(String id)`
   (`dividerKindOf` `:1411-1415` yanına; o değişmez).
4. **Tur altyapısı** (`tool/tour/screen_tour_test.dart`): tek dokunuşlu sahne listesine DOKUNMA
   (P62 aynı listeye satır ekliyor, `:656-695`); ikinci liste `_stepScenes`:
   `(String id, String location, Future<void> Function(WidgetTester) steps)` + aynı çekim döngüsü.
   Örnek notlara bir çizgili liste (beş türden birer çizgi) eklenir. Sahneler (BUGÜNKÜ arayüzle,
   "önce" görüntüsü): `duzen-serit`, `kisisellestir`, `sablon-galeri`, `sablon-onizleme-liste`,
   `sablon-onizleme-yazi`, `sablon-bos`, `kalem-hap`, `kalem-kapsul`, `kalem-panel`, `kalem-sutun`,
   `cizim-serit`, `dikte-kart`, `ses-levha-dinliyor`, `ses-levha-hazir`, `cizgi-tepsi`, `cizgi-levha`,
   `cizgi-satirlar`. Konuşma kanalı taklidi: `test/voice_unavailable_test.dart:13-27` kalıbı. Bir
   sahne üretilemezse satırına "üretilemedi: <ne denendi>" yazılır, paket devralır.
   Komut: `TOUR_ONLY=<sahneler> TOUR_SIZES=telefon-kucuk,matepad-yatay TOUR_OUT=build/tour_p63_once
   flutter test tool/tour/screen_tour_test.dart` (+ `TOUR_DARK=1`); paketler `TOUR_COMPARE` ile kıyaslar.
5. **Bütçe tabanları** (`test/perf_budget_test.dart`, `budgets.json`): S40–S44 senaryoları §1.5, §2.5,
   §3.5, §4.5, §5.5'teki tanımlarla, BUGÜNKÜ kodda koşar; ölçülen değer bütçe ("bugun" alanı tarihli),
   plandaki sayı "hedef". Sayaç tür ADIYLA sayar (`BuildCounter`, `test/support/editor_harness.dart:25-39`)
   → özel türler de sayılır (`_TemplateCard`, `_DictationPanel`, `PenTray`). Bugünkü değer plandaki
   hedeften kötüyse paket onu hedefe İNDİRİR; iyiyse bütçe bugünkü değerdir (mandal yalnız düşer).
   S44'te ayrıca "tepsi açılırken gövde kurulumu" ölçülür (§5.1 bulgu 13 hipotezinin kanıtı).
6. **Cihaz evreleri** (`tool/perf/ab_hepsi.py`): bugün evreler `liste, menu, arama, klasor, yeni_not,
   not_ac, kb, yaz, not_kapa, sabit_ac, sabit_kay, sabit_kb` (`run_once`, `:180-287`) — kalem, biçim,
   düzen modu, şablon, dikte evresi YOK (§3.5'teki hipotez doğrulandı). Eklenecek: `kalem` (kalem kipi
   aç → 10 çizgi → kapsül aç/kapa ×3), `bicim` (klavye açık → Biçim → çizgi tepsisi aç/kapa ×3 → tür
   seç ×3), `duzen` (not ⋮ → düzen modu aç → 3 öğe gizle/göster → Bitti), `sablon` (levha aç → çip →
   kapat). Dikte evresi mikrofon ister → eklenmez; PB5 "yazıldı, cihazda doğrulanmadı" yazar.
   Yeni evreler eski evrelerin SONUNA eklenir (var olan evrelerin sayıları kaymasın — altın taban).
   Telefon varsa bir A=A koşusu (`ab-olcum`); yoksa `KONTROL_LISTEM.md`.

- **Kabul:** yeni/var olan testler yeşil; S40–S44 `budgets.json`'da tabanlı; tur "önce" görüntü listesi
  ve ölçülen ham sayılar `DEVIR.md`'de; `git diff --stat` içinde `presentation/` altında yalnız
  `items_editor.dart` (+`dividerOf`).
- **Tuzaklar:** `budgets.json` mandalı — yeni senaryo eklemek serbest, var olanı yükseltmek `[butce]`
  ister · tur dosyasında P62 ile çakışma (ana listeye dokunma) · `ab_hepsi.py` evre SIRASI ·
  `UiPrefs` eşitliği (`==`) yeni alanları kapsamazsa `Personalize` dinleyicileri tetiklenmez ·
  `level` notifier'ı oturum kapanınca `dispose` EDİLMEZ (dinleyen kart bir kare daha yaşayabilir) —
  sıfırlanır.
- **Model:** opus. **A/B:** paket görünür değişiklik yapmaz; yalnız evrelerin çalıştığı denenir.

### 7.3 PB1 — düzen modu: şerit + çerçeve (fable)

- **Kanıt:** §1.1 "Mod deneyimi/görünüm eksikleri" 1, 3, 4 (`customizable.dart:57-147, 216-281`).
- **Önce üret:** tur `duzen-serit` (PBT'den, açık + koyu, telefon + tablet) "önce"; S40 tabanı;
  yeni `test/customize_strip_test.dart` KIRMIZI: şerit tek satır (yükseklik = üst güvenli alan + 48),
  `customize-reorder` düğmesi var, gizli sayısı hapı yalnız sayı > 0 iken, hareketi azalt açıkken
  geçiş ≤ 150 ms.
- **Kabul:** §1.4'ün şerit/çerçeve maddeleri; `customizable.dart`'ta elle ölçü 0, `elevation` 0;
  `Customizable` mod kapalıyken çıplak `child` (`customizable.dart:17-19` P20 notu — `identical`
  testi); `editor_bar_customize_test`, `editor_top_customize_test`, `personalize_bubble_focus_test`,
  `page_panel_personalize_test` DEĞİŞMEDEN yeşil (`customize-undo`, `customize-done`); S40 ≤ taban.
- **Tuzaklar:** şerit yuvası TEK ADIMDA açılır (kasma md. 6; `CustomizeModeHost` Column'u editör
  gövdesiyle aynı sütunda) · kök `build`'e yeni `Personalize` okuması ekleme
  (`note_editor_screen.dart:4555` kalıbı) · metin alanı içeren hiçbir şeyi `Customizable` ile sarma ·
  "Sırala" düğmesi PB2 gelene dek hub yerine BUGÜNKÜ Kişiselleştir ekranını açar (yarım özellik
  bırakma) · ilk giriş ipucu var olan huniden (`TipOnce.show`, `core/tips.dart:82`) — P62'nin PA5'i huniyi
  göç ettirince kılık kendiliğinden gelir, `appNotice`'i doğrudan çağırma (`app.dart`'a bağlı değil) ·
  kesikli çerçeve tek `drawPoints` (`item_divider_style.dart:44-53` kalıbı) · rozet göz simgesi KALIR (SB4).
- **A/B:** evet — `kb`, `not_ac`, `duzen` evreleri; mod kapalı yol yavaşlamamalı. **Bütçe:** S40.

### 7.4 PB2 — düzen merkezi + panolar (fable)

- **Kanıt:** §1.1 kök bulgu tablosu (b–e) ve envanter; §1.2 `CustomizeHub` tablosu.
- **Önce üret:** tur `kisisellestir`, `duzen-hub-altcubuk`, `duzen-hub-hizli` "önce" (hub yokken
  bugünkü ekran/levha); yeni `test/customize_hub_test.dart` KIRMIZI: `surfaceFor(location,
  keyboard:)` karar tablosu (saf işlev), yüzey çipi değişince pano değişir, `home` yüzeyinde takvim
  şeridi/hızlı yakalama anahtarları var olan tercihi sürer.
- **Kabul:** §1.4'ün tamamı (PB7'ye kalan "YAP" sarmaları hariç); b, c, d, e `CustomizeBoard` çizer;
  `personalize_screen.dart`, `quick_row_editor.dart`, `personalize_bar_list.dart`'ta elle ölçü 0;
  baş karttaki gradyan (`personalize_screen.dart:141-150`) yok.
- **Tuzaklar:** **§1.4 "var olan testler değişmeden yeşil" ancak anahtar uyumuyla tutar** (§6.1):
  `bar-switch-<id>`, `bar-move-<id>` (teste dokunuluyor, `editor_bar_customize_test.dart:206`),
  `personalize-bar-<grup>` (gizli düğme de KENDİ grubunun içinde bulunmalı, `:202-203`),
  `personalize-bar-reset`, `quick-row-edit-<k>`, `quick-row-editor-preview`, `personalize-start-edit`,
  `personalize-reset` · `MenuLayout` veri biçimi değişmez (`core/menu_layout.dart`) · menülerin kendi
  "Düzenle"si KALIR, yalnız gövdesi pano olur · `ActionMenu`/`quick_add_fab` dosyalarında yalnız
  düzenle gövdesi — menünün kendisine dokunma (Y-listesi, `arayuz.md`) · değişiklik ANINDA kaydedilir
  (P50) · Wrap içinde boy animasyonu yok (yalnız `AnimatedOpacity`) · hub levhası açılırken klavye
  kapatılır (`note_editor_actions.dart:496`) · PB1'deki "Sırala" düğmesi artık hub'ı açar.
- **A/B:** hayır (ayar ekranı + levha; editör yolu değişmez). **Bütçe:** S40 (hub açıp kapamak gövdeyi
  kurmaz — senaryoya eklenir).

### 7.5 PB3 — kalem seti (fable)

- **Kanıt:** §3.1 bulgu 1–9.
- **Önce üret:** tur `kalem-hap`, `kalem-kapsul`, `kalem-panel`, `kalem-sekil-panel`, `kalem-sutun`,
  `cizim-serit` "önce"; S42 tabanı; grep sayımı DEVIR'e (`easeOutBack`, `AnimatedSize`,
  `AnimatedPositioned`, `blurRadius`, `Colors.black`, `Duration(milliseconds:` — bugünkü sayılar);
  yeni testler KIRMIZI: `test/pen_tray_tools_pref_test.dart` (§3.4), `pen-panel-pin` testi.
- **İlk iş (hipotez kapatma):** alt şeridin (`_build`, `pen_tray.dart:930-984`) altı çağrı yerinde
  şeridin belgeyle AYNI Column'da olup olmadığına bak (`drawing_screen.dart:342`,
  `pdf_viewer_screen.dart:464`, `slide_viewer_screen.dart:347`, `image_viewer.dart:735`,
  `pdf_note_pane.dart:459`, `slide_note_pane.dart:556`); sonucu §3.1 bulgu 2'ye yaz.
- **Kabul:** §3.4'ün tamamı; S42 ≤ taban ve ≤ 13.
- **Tuzaklar:** kapsam YALNIZ görünüş + hareket: üç yerleşim, araç sırası, jestler, anahtarlar ve
  §3.1 sonundaki dokuz istek DEĞİŞMEZ ("kalem tepsisini değiştirmek" yasağı) · `AnimatedSlide` ölçüleri
  bugünkü `top` değerlerinden türetilir (§3.2) — kırpma kutusu aynı kalmalı (`pen_icons_test`) ·
  panel yuvası ve sabit kalem hapı KOŞULSUZ kurulu (`SizedBox.shrink`) · `PenStrokePreview` kendi
  `RepaintBoundary`'sinde; `PenToolPainter.shouldRepaint` kalkışta yeniden boyamamalı (doğrula:
  `pen_icons.dart`) · `pen`/`eraser` gizlenemez; seçili araç gizli olsa da çizilir · `_tools` süzgeci
  `Personalize.listenable`'ı `build`'deki `ListenableBuilder` birleşimine ekler, kök `setState` yok ·
  `showInkSettings` → `showAppSheet` yalnız telefon dalı (`pen_tray.dart:55-62`); levhanın İÇERİĞİ
  (`ink_layer.dart:2525-2720`) kapsam dışı · sabit kalem çipinde renk saydamlıksız kayıtlı (§6.3) ·
  `kalem.md`'deki gecikme/avuç içi kurallarına dokunma.
- **A/B:** evet — `kalem` evresi (PBT) + `not_ac`. Kalemle yazma gecikmesi en hassas yüzey:
  kötüleşme SIFIR. **Bütçe:** S42.

### 7.6 PB4 — şablonlar (fable)

- **Kanıt:** §2.1 bulgu 1–8.
- **Önce üret:** tur `sablon-galeri`, `sablon-onizleme-liste`, `sablon-onizleme-yazi`, `sablon-bos`,
  `sablon-duzenle` "önce"; S41 tabanı (bugünkü `_TemplateCard` sayısıyla); yeni widget testi KIRMIZI:
  30 maddeli şablonda "Oluştur" ilk karede görünür alanda (bugün kaydırmanın altında).
- **Kabul:** §2.4'ün tamamı; `test/note_templates_test.dart` DEĞİŞMEDEN yeşil; S41 ≤ taban.
- **Tuzaklar:** küçük kart düzeni korunur — telefonda 3, genişte 4 sütun (2026-11-05) · favori en çok
  4 ve `templateFavoritesFull` duyurusu · iki adım (önce önizle, sonra oluştur) kalır · öneri çipleri
  grup içi alfabetik · anahtarlar `tpl-card-<key>`, `tpl-fav-<ad>`, `tpl-save-as`, `tpl-two-columns`,
  `tpl-item-<i>-<metin>`, `tpl-editor-*` · minyatürde metin dizimi YOK (S41 `RenderParagraph` sınırı) ·
  `templatePreviewLines` sonucu şablon başına bir kez (dil değişince önbellek boşalır) · sabit alt
  bant klavyenin üstüne oturur (levha zaten `viewInsets.bottom` dolgulu, `:47-50`) — çift dolgu verme ·
  şablon vurgu renkleri izinli sabit renk istisnası · `AnimatedSwitcher` kayması yalnız girişte.
- **A/B:** hayır (editör/klavye/çubuk/liste/geçiş değil); `sablon` evresi yürütücünün `[apk]` öncesi
  tam ölçümünde görülür. **Bütçe:** S41.

### 7.7 PB5 — sesle yazma (fable)

- **Kanıt:** §4.1 bulgu 1–7.
- **Önce üret:** tur `dikte-kart` (telefon + tablet), `ses-levha-dinliyor`, `ses-levha-hazir`,
  `ses-levha-hata` "önce"; S43 tabanı (metin olayı başına satır kurulumunun BUGÜNKÜ değeri); yeni
  testler KIRMIZI: düzey olayında `_DictationPanel` ve `ListeningCard` kurulmaz; sessizlik sayımı 0 →
  0.5 → 1 iken kart yüksekliği sabit; 1280 dp'de çubuk eni 3 dp.
- **Kabul:** §4.4'ün tamamı; `test/listening_card_bubble_theme_test.dart`'ta TEK izinli değişiklik
  `:61` tür adı; `voice_unavailable_test`, `voice_capture_test`, `voice_commands_test`,
  `compact_menus_listening_test` değişmeden yeşil; S43 ≤ taban.
- **Tuzaklar:** kartın dış `RepaintBoundary`'si KALIR (`note_editor_parts.dart:236`, 2026-11-13 tablet
  kök nedeni) · `if (_dictating)` ağaç şekli bugünkünden farklılaşmaz; belirme `PopIn`
  (`core/widgets/pop_in.dart:14`), çıkış geçişi YOK · levhada `idle` ve `listening` AYNI
  `AnimatedSwitcher` anahtarı (basılı-tut düğmesi ağaçtan kalkmamalı, `voice_capture_sheet.dart:1319-1322`)
  · sessizlik için `setState` yalnız 0 ↔ > 0 geçişinde · dinlerken `error` rengi durum rengidir, KALIR ·
  kart orta boy bekçisi (dikte 90–150, AI 130–260 px) · `ListeningWaveform` SİLİNİR (iki dalga kalmaz)
  · `VoiceRecordPanel`, sesli asistan, Ayarlar → Ses, dikte yazma kuralları kapsam DIŞI;
  `note_editor_screen.dart:4277-4290`'daki `AnimatedSize` regresyon listesine NOT olarak yazılır ·
  alt yazı metni var olan `voiceAutoStopSoon` ("Sessizlik — birazdan biter").
- **A/B:** evet — `kb`, `yaz` evreleri dikte kapalıyken (kapalı yol yavaşlamamalı); dikte açıkken ölçüm
  mikrofon ister → "yazıldı, cihazda doğrulanmadı" + `KONTROL_LISTEM.md` (tablette sesle yazarken
  kaydırma). **Bütçe:** S43.

### 7.8 PB6 — madde çizgileri (fable)

- **Kanıt:** §5.1 bulgu 1–12.
- **Önce üret:** tur `cizgi-tepsi`, `cizgi-levha`, `cizgi-satirlar` "önce"; S44 tabanı; yeni
  `test/item_divider_sheet_test.dart` KIRMIZI (§5.4); tepside `format-divider-double` /
  `format-divider-wavy` bulunamaz (kırmızı).
- **Adımlar (ayrı commit):** (1) tepsi → `DividerKindPicker` + `dividerStyle` girdisi; (2) levha;
  (3) `kItemDividerAccentAlpha`; (4) beliriş — yalnız (1)–(3) yeşil ve ölçülmüşse, kendi kapısıyla (§5.2).
- **Kabul:** §5.4'ün tamamı; S44 ≤ taban.
- **Tuzaklar:** `format_bar.dart`'ta kapsam YALNIZ `_DividerRow` + bir kurucu girdisi — iki sıra,
  düğmeler, sıra, tepsi kabuğu (`AnimatedSize` `:626-636`) DEĞİŞMEZ · tepsi boyu 42 · çizgi türleri
  madde uzun basış menüsüne DÖNMEZ · `paintItemDivider`'a dokunma (tek çizim çağrısı bekçisi) ·
  `note_card.dart`'a dokunma · seçici `TextFieldTapRegion` içinde kalmalı (dışına taşınırsa dokunuş
  odağı düşürür, klavye kapanır) · levha modal — açılınca editör odağı bugünkü gibi davranır,
  değiştirme · `_DividerReveal` KOŞULSUZ sarmalayıcı; `initState`'te oynamaz; katman/opaklık yok ·
  satır önbelleği anahtarına beliriş durumu girmez · "Tamam" kalır (SB9) · `format_bar.dart` editör
  dosyası: yeni `Theme.of(context)` ekleme.
- **A/B:** evet — `kb` + `bicim` evreleri, çizgili ölçüm notuyla. **Bütçe:** S44.

### 7.9 PB7 — yeni sarmalar + sıralar (opus high)

- **Kanıt:** §1.1 envanterinde **YAP** yazan satırlar: hızlı satır sırası (`quick_row_editor.dart:122-126`
  katalog sırası sabit), Ekle levhası sırası (`attach_sheet.dart:63-69, 133`), video hız/süre
  (`video_transport.dart:162, 203`), ortak çalışan düğmesi (`note_editor_screen.dart:3428`), sabit ek
  çubuğu (`pinned_media_pane.dart:1412-1689`, sarma yalnız `:1565`), sabit ek ⋮ menüsü (`menuId` yok).
- **Önce üret:** yeni testler KIRMIZI: `quickOrder` verilince hızlı satır o sırada; `attachOrder`
  verilince Ekle levhası o sırada; `UiItem.pinned(k)` gizliyken düğme yok, varsayılan AYNI; düzen
  modunda video/ortak çalışan/sabit ek düğmeleri çerçeveli; S40 senaryosuna "sıra değişince satır
  kurulumu 0" eklenir.
- **Kabul:** §1.4 "Envanterde YAP yazan her satır hub'dan düzenlenir ve yerinde modda çerçevelenir" +
  "sıra yeniden açılınca korunur"; varsayılan tercihle ekran görüntüleri PİKSEL AYNI (tur
  `TOUR_COMPARE`: n1, n4, `n4-ekle`, `e-pdf-sabit`, `e-video-sabit` farkı 0); S40 ≤ taban.
- **Tuzaklar:** görünüş paketi DEĞİL — varsayılan görünüm değişmez; yeni kılık gerekirse dur, PB1/PB2
  sahibine yaz · `quickOrder` satırın `_syncRowCache` env'ine GİRMEZ; sıra listesi `Personalize.prefs`
  değişince bir kez hesaplanıp `State`'te tutulur (her build'de yeni liste = önbellek her karede boşalır,
  kasma md. 2) · hızlı satırın `KeyboardSwitch` düzeni değişmez (md. 7; 2026-11-14 "tek KeyboardSwitch"
  commit'i 0200f8cb) · `Customizable` mod kapalıyken çıplak çocuk — sarma editörün ilk karesine yük
  bindirmez · Y10: sabit ek düğmeleri varsayılanda ⋮'e İNMEZ (kullanıcının kendi gizlemesi serbest) ·
  `menuId: 'pinned.menu'` yeni kimlik; var olan kimlikler değişmez · ana ekran ✨, klasör şeridi, "+",
  başa dön, not ⋮, klavye düğmesi, biçim çubuğu, balon dok SABİT (§1.1) · kenar rayı SB1 (dokunma) ·
  `UiItem.topTheme` ölü kimlik, silinmez.
- **Model:** opus (high) — görsel olmayan bağlama + kasma duyarlı editör dosyaları. **A/B:** evet —
  `kb`, `yaz`, `sabit_ac`, `sabit_kb`, `duzen`. **Bütçe:** S40.

### 7.10 Sonraya (bu planın paketi DEĞİL; regresyon listesine/Kuyruk'a not)

- Kalem ayar levhasının içeriği (`InkSettingsSheet`, `ink_layer.dart:2525-2720`) — ayar satırı kılığı
  P62'nin; P62 birleşince ayrı küçük iş (§3.2).
- Sesli not kaydı hapını saran `AnimatedSize` (`note_editor_screen.dart:4277-4290`) — kasma md. 6 adayı.
- Biçim çubuğu tepsi kabuğunun `AnimatedSize`'ı (`format_bar.dart:626-636`) — PBT ölçümü kötüyse
  ayrı düzeltme (çubuğun görünüşü değişmeden: boy tek adım, içerik kayarak belirir).
- Renk paletinin kendi noktası (`core/widgets/color_palette.dart:184`) → `ColorDot`.
- P62'nin PA9'u: P63 çitindeki 9 `showSnackBar` + 3 `hideCurrentSnackBar` (P63 birleşince, P62 planı).

### 7.11 Açık KARAR'lar (sabah bakılacak — hepsinde güvenli seçenek uygulanır, soru sorulmaz)

| # | Karar | Güvenli seçenek (uygulanacak) |
|---|---|---|
| SB1 | Kenar rayı hedefleri (tablet/web) düzenlenebilsin mi | dokunma |
| SB2 | Biçim çubuğu düğmeleri düzenlenebilsin mi | sabit |
| SB3 | Not kartı alanları | kapsam dışı |
| SB4 | Düzen rozeti göz simgesi | kalır |
| SB6 | AI rozetinin iki renkli dolgusu | kalır |
| SB7 | Dikte kartına komut yardımı düğmesi | eklenmez |
| SB8 | Seçim rengi: `CustomizeBoard` "görünen" karosu ve M3 çipleri `secondaryContainer`; P62 seçim = `primaryContainer` | bugünkü kılık kalır (2026-11-13 hızlı satır düzenleyicisi); P62 temaya genel kural koyarsa çipler onunla değişir |
| SB9 | Çizgi levhasında canlı uygulama ("Tamam"sız) | "Tamam" kalır |
| SB10 | Çizgi vurgu saydamlığı 0.75 → `AppAlpha.strong` (0.85) — var olan tema renkli çizgiler bir ton koyulaşır | uygulanır (tek sabit); beğenilmezse sabit tek satırda `AppAlpha.muted`'a çekilir |
| SB11 | Çizginin soldan sağa belirişi | ölçüm kapısını geçerse kalır, geçmezse geri alınır |

(SB5 numarası kullanılmadı. "SB" = sabah bakılacak; bütçe senaryoları S1–S44 ile karışmasın diye ayrı önek.)
