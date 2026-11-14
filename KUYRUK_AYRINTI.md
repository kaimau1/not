# KUYRUK_AYRINTI — Kuyruk satırlarının tam metni

OTOMASYON.md Kuyruk satırları kısa özettir; asıl kapsam, KORU çitleri ve kullanıcı istekleri burada, AYNEN. Alt ajana paketin satırı + bu dosyadaki `## P..` bölümü verilir.


## P43 — Hız: tek komutla tam ölçüm + otomatik karar + altın taban + cihazsız bekçiler (P44 katıldı, tek ajan)

Model: opus · Cihaz: cihaz · APK: -

**Plan maddeleri:** HIZ_PLANI F81.1–F81.5 + F82.1–F82.3

**Durum (2026-11-13):** F82 main'de; F81 aracı + ilk tam A/B + altın taban dalda (`oto/P43-hiz-olcum`); **F81 kabulü KALDI** (aynı APK A=A'da `yaz` LAYOUT yanlış alarm, altına karşı +%22–40 sıcaklık kayması — HIZ_PLANI F81 Durum, sabah bakılacak); 2. tur (sabah): eşik %20 + < 34 °C + 6 koşulu altın → A/B A=A 2/2 GEÇTİ, altına karşı `yaz` LAYOUT +%16 → hâlâ KALDI (HIZ_PLANI F81 Durum 2); F68.4 ölçüldü: liste > 16 ms %2,3–3,3, hedef %2 tutmadı → P46. Eski durum: önce F82 (cihazsız bekçiler S18–S25, kasma kalıpları, uzun oturum), sonra F81 (cihazda ölçüm + altın taban); senaryolara "sabit görsel/PDF + klavye aç/kapa" evresi de girer (kullanıcı 2026-11-12; düzeltmesi P49'da — sabit ek dosyasına tek paket dokunsun); OTURTMA F68.4 kaydırma kabulü ölçümü (`ab_liste.py`) de burada (P22'den alındı)

## P45 — Hız: her [apk]'da ölçüm + geçmiş + CI kare ölçümü kararı

Model: sonnet · Cihaz: cihaz · APK: -

**Plan maddeleri:** HIZ_PLANI F83.1–F83.3

**Durum:** cihaz bekliyor (2026-11-14), dal `oto/P45-olcum-gecmis`: F83.1, F83.2 yazıldı; F83.3 sabah bakılacak (gerekçe HIZ_PLANI'nda).

## P46 — Hız: ölçümün bulduğu yavaşlıkları düzelt

Model: fable (limit %55 üstü → opus) · Cihaz: A/B · APK: evet

**Plan maddeleri:** HIZ_PLANI F84.1–F84.3 + OTURTMA F60.S2, F60.5, F68.3 (P22'den alındı: klavye birikim kasması, yazma ana bloğu, liste akışı K-O13)

**Durum:** bitti (2026-11-13) — cihazsız 6 bekçi bulgusu düzeltildi, dal `oto/P46-hiz-duzelt`: S25 küçük resim çözme 21 → 0; S21 arama harf başına kart 114 → 56; S22 takvim hafta 979 → 509 (WeekPage 3 → 1); S23 süzgeç geçişi en ağır kare 2941 → 2361; S9 biçim paneli gövde boy karesi 34 → 2 (jank mandalı 4 → 2); S18 not açma ikinci kare 788 → 285. CİHAZDA ÖLÇÜLMEDİ (A/B yürütücüde). Ses hapı `AnimatedSize`ı: cihazsız kanıt üretilemedi, dokunulmadı. Cihaz maddeleri (F84.1–3, F60.S2, F60.5, F68.3) → P55. `pinned_media_pane.dart`'a dokunulmadı. Kök nedenler: (1) S21 kart önbelleği anlık sorguyla, hücre sarmalayıcısı geciktirilmiş `searchActive` ile değişiyordu → iki dalga; (2) S25 `thumbUrl` dallarında `memCacheWidth` yoktu; (3) S22 `onPageChanged` → `setState` canlı hafta sayfalarını yeni örnekle baştan kuruyordu → `_weekPage` önbelleği; (4) S23 gelen ızgara ilk karede 1600 px payı da kuruyordu → geçiş boyunca 250 px, 500 ms sonra boşta genişler (`_GridScrollView`); (5) biçim paneli ↔ alt çubuk takasında iki `AnimatedSize` gövdeyi 34 kare diziyordu → boy tek adım, hareket `RevealUp`; (6) S18 `_measureBodyTop` kök `setState` → `_bodyTopN` ValueNotifier, yalnız tuval kurulur. Davranış notu: aramada vurgu artık süzmeyle birlikte (350 ms gecikmeyle) gelir; biçim paneli/alt çubuk boyu anında değişir, içerik süzülerek belirir — cihazda his bakılacak.

**P43 cihaz ölçüm bulguları (2026-11-13, `ab_hepsi.py`, A=9c837495 B=P39 02ebd989, 3'er koşu, ortanca; gürültü ±%15):** P39'da `klasor` LAYOUT 82→108 ms (+%33, aynı APK tekrarında 87 — gerçek olabilir), `menu` LAYOUT 44→50, `sabit_kay` UI 877→967 ms (sabit ek → P49). En ağırlar: `sabit_kb` 2,3–2,5 sn UI/4 klavye geçişi (373 kare; sabit ek → P49), `liste` 1,24–1,37 sn/8 fırlatma, > 16 ms %2,3–3,3 (F68.4), `arama` en uzun kare 62–82 ms, `not_ac` en uzun 61–89 ms, ilk kare 378–413 ms.

**P43 cihazsız bekçi bulguları (2026-11-12, mandallı, düzeltilmedi — düzeltince ilgili mandalı düşür):**
1. S21 arama: harf başına 114 `NoteCard` kuruluyor (görünür 18 — 6 katı).
2. S25 `note_card_media.dart` `_image` `thumbUrl` dalında `memCacheWidth` yok → Drive küçük resmi tam boy çözülüyor (21 kart).
3. S22 takvim hafta fırlatma tek karede ~980 kurulum.
4. S23 süzgeç kaydırma en ağır kare 2941 kurulum.
5. Kasma listesi md. 6: editör kökünde gövdeyle aynı Column'da 3 `AnimatedSize` (ses hapı, biçim paneli, alt çubuk takası — `jank_patterns_guard_test` mandalı 4).
6. S18 not açma geçişinde ikinci kare 788 kurulum (editör iki karede kuruluyor).

## P48 — Web yazı seçimi + takvim senkronu (tek ajan)

Model: opus · Cihaz: cihaz (b) · APK: evet

**Plan maddeleri:** kullanıcı 2026-11-12: (a) "webte yazı seçerken sorunlar var, yazı tipiyle alakalı olabilir"; (b) "telefonda eklediğim takvim etkinlikleri tablette görülmüyor, tablette eklediklerim telefonda görülüyor; webde de aynı"

**Durum:** bitti — dal `oto/P48-web-takvim` CI yeşil (2026-11-13), cihazda doğrulanmadı (telefonda Google Takvim bağlı mı bakılacak). İlk CI kırmızısı: işaretçi takibi `addGlobalRoute` editör sızıntı bekçisinde (`editor_leak_test` globalRoutes 1→2) — uygulama ömürlü tek yol, test tabanı `trackSelectionPointerKind()` sonrası alınır. (a) KÖK NEDEN `lib/core/utils/sentence_select.dart` cümle genişletici: seçimin kaynağına bakmıyordu — webde fareyle kelimeye çift tıklama bütün cümleyi, shift+ok ile 3 harf bütün kelimeyi (token) seçiyordu (yerel `build web --wasm`, misafir kipte üretildi; düz arama alanında çift tıklama doğru). Genişletme artık fare/izleme dörtgeni ve shift basılıyken yapılmaz (`_mouseOrKeyboardSelection`); kanıt `test/sentence_select_test.dart` "fare ve klavye seçimi" kırmızı→yeşil + webde yeniden denendi. Yazı tipi değil. (b) KÖK NEDEN `event_editor.dart` `_toGoogle`: Google Takvim bağlantısı cihaza özgü (`gcal_cache_<uid>` SharedPreferences); bağlı telefonda yeni etkinlik varsayılan Google'a gidiyor, Google'ı bağlamamış tablet/web görmüyordu; "Bu cihaz" etiketi tersini söylüyordu. Varsayılan artık Firestore ("Tüm cihazlar"); kanıt `test/calendar_screen_test.dart` "Google bağlıyken de…" kırmızı→yeşil. **K2 sapması — sabah bakılacak.** Cihazda: telefonda Google Takvim bağlı mı. (c) üretilemedi: web oturumu kullanıcının hesabıyla açılamadı; Firestore REST (salt okuma) ana hesapta: video ekleri hiç yüklenmiyor (tasarım, `skipsUpload`), 3 PDF + 1 görsel yalnız Drive'da önizlemesiz (web Drive bağlanmadan yalnız "Drive'da" kutusu çizer), 1 PDF hiç yüklenmemiş (başka hesapta). Kullanıcının snackbar metni gerekli (F65.6).

## P49 — Sabit ek baştan: tasarım, tuşlar, özellikler

Model: fable (limit %55 üstü → opus) · Cihaz: A/B · APK: evet

**Plan maddeleri:** kullanıcı 2026-11-12: "sabit ek tasarımı, tuşları, özellikleri fable baştan yazdır"

**Durum:** bitti — bulut 2026-11-13, main'e [apk]: (a) tek ⋮ levhası (görünüm anahtarı, balonlar, PDF işleri, ek işleri, Kaldır); (b) ✏ hep görünür, yüzen kalemle senkron (`onPenOff`); (c) bölme kalemi açıkken çubukta silgi/geri al/yinele/ayar; (d) ipuçları kalem tepsisinin üstünde (`SnackBarObstacle`), oturumda durum başına bir kez; (e) klavye kasması S17 düştü; (f) F65.1 K-O6 dar çubuk + F65.2 K-O7 (kullanıcı kararı: geniş yatay pencerede seçilmemişse ek solda), F65.3 K-O8 en güvenli = tek sabit ek, sabah bakılacak; (g) 360/393 dp × 1,3 yazı taşmaz (bekçi `pinned_bar_redesign_test`); cihaz A/B YAPILMADI (bulut, telefon yok) — cihaz bekliyor, KALANLAR L7–L9.

**Eski durum metni:** BAŞTAN TASARIM (yama değil): önce mevcut sabit ek çubuğu/bölmesinin bütün düğmelerini ve özelliklerini (görsel, PDF, video, ses, balon, kalem, yerleşim üst/sol/sağ, sığdır, tam ekran) dök, DENEYIM §2 diliyle yeni düzen öner ve uygula. Kesin istekler: (a) ⋮ ile "sayfalara göz at" menüleri TEK ⋮ menüde; kart düğmesi bizim stilde, yer açılır; (b) yüzen kalem düğmesi ↔ paneldeki kalem TAM senkron (yüzenden açınca paneldeki kayboluyor, panelden açınca yüzen bilmiyor); (c) paneldeki kalem açılınca silgili hızlı kalem menüsü; (d) "kalem yazar, parmak dokunur" gibi ipuçları alt kalem panelini KAPATMASIN, sürekli çıkmasın. (e) SABİT EK + KLAVYE KASMASI (kullanıcı 2026-11-12: "sabit ek varken klavye açılırken hem sabit ek paneli hem klavye kasıyor"; P46'dan alındı, senaryo P43'te): yeni tasarım kasma listesi §6–§7'ye uysun, A/B'de bu evre ölçülsün. (f) P22'den alınanlar (hepsi sabit ek): OTURTMA F65.1 bölme çubuğu sadeleşmesi (K-O6 — bu paketle açıldı), F65.2/F67.5 yatayda yandan sabitleme varsayılanı (K-O7), F65.3 birden çok sabit ek (K-O8); K-O7/K-O8 için en güvenli seçenek + "sabah bakılacak". (g) P42 kalanı: sabit PDF çubuğu 1,3× yazıda ve 360/393 dp'de taşıyor. KORU: P47 ("T" kalktı, balon gizle/göster balon menüsünde, `kPinnedSideMinWidth` 560), P39 F78.3(b) bölmenin içindeki yükleme hâli. `pinned_media_pane.dart`, `ViewerPen`, P15. Önce `istek_tara.py`

**P43 bulgusu (2026-11-12):** S17 sabit görsel/PDF klavye hareket karelerinde sabit bölme diziliyor (görsel 2, PDF 3 sınır: `_RenderLayoutBuilder`, `RenderCustomMultiChildLayoutBox`), editör içi 12/11 (metin 7) — `budgets.json` S17 `sabit_*` mandalları; yeni tasarım bunları düşürsün.

## P50 — Düzenleme modu baştan: her şey düzenlenebilsin + hızlı menü

Model: fable (limit %55 üstü → opus) · Cihaz: - · APK: evet

**Plan maddeleri:** kullanıcı 2026-11-12: "düzenleme modunu fable yaptır her şey düzenlenebilsin"; "hızlı menü ve hızlı menüyü düzenle üzerine çalışılmalı, şu an normal düzenleme modunu açıyor"

**Durum:** bitti (2026-11-13, dal `oto/P50-duzenleme`; cihazda doğrulanmadı — KALANLAR L14). (b) main'de zaten vardı (c34ed0ae: `quick_row_editor.dart`). (a) düzenleme modu ANINDA uygular (`Personalize.toggle` hemen yazar; şerit Geri al / Bitti; `save`/`cancel` kalktı); alt çubuk düğmesi iki kapsül arasında taşınır (`UiPrefs.barSides`/`withBarSide`, Ayarlar listesinde ok — P57 devri); üst çubukta Ana sayfa + Tam ekran sarıldı (`UiItem.topHome`/`topFullscreen`). Testler: `page_panel_personalize_test`, `editor_bar_customize_test`, `editor_top_customize_test`. KALAN: ana ekran sarmaları (P56 çiti nedeniyle dokunulmadı), üst çubuk sıralama listesi (yapı P20'nin), düzenleme modunda yerinde sürükle-sırala — sabah bakılacak. ESKİ TANIM: (a) düzenleme modu (Ekranı/Menüyü düzenle, `customizable.dart`, `UiItem`): ekranda görünen HER düğme/alan gizle/göster/sırala (eksik `Customizable` sarmalarını dök, tamamla); (b) "Hızlı menüyü düzenle" genel düzenleme modunu değil hızlı menünün kendi düzen kipini açsın (P28 "+" paneli düzen kipiyle birleşik dil). Kasma listesi §3–§4: düzen kipi kök `setState` değil, ağaç şekli değişmesin. P49'DAN SONRA: sabit ek çubuğunun `Customizable` sarmalarını P49 yapar, P50 `pinned_media_pane.dart`'a dokunmaz; editör `note_editor_screen.dart` yapısı P20'nin (P50 yalnız sarmalar)

## P38 — Hareket ve dokunsal dil

Model: opus · Cihaz: A/B · APK: evet

**Plan maddeleri:** DENEYIM F77.1–F77.4

**Durum:** bekliyor — P47 çöp sürüklemesindeki `HapticFeedback` ve sıra donması (`_previewCardDrop`) korunur, yalnız `AppHaptics`e sarılır

## P20 — Editör çekirdeği (başlama şartı tutuyorsa)

Model: fable · Cihaz: A/B · APK: evet

**Plan maddeleri:** Faz 64

**Durum:** sürüyor — 1. evre (Fable plan) bitti (aşağıda "Uygulama planı"), 2. evre Opus: adım 1'den. ESKİ: P49 (sabit ek) ve P50 (düzenleme modu) BİTTİKTEN sonra; onların editördeki bloklarını AYNEN taşır

**Katılanlar (yeniden düzen 2026-11-14):** P50 kalanı (üst çubuk sırası; ana ekran `Customizable` sarmaları — P56 çiti kalktı), P38 kalanı: editör `toggle_pop`'u. Başlama şartı: entegrasyon dalı (P55+P56+P38+P50) main'de. P41 aynı anda koşabilir; P41 editör dosyalarına dokunmaz.

### Uygulama planı (Fable, 2026-11-14)

Satır numaraları `faed9f64` (main, 2026-11-14) içindir; kod ilerlediyse adı `Grep` ile bul.
Kısaltma: **EKRAN** = `lib/features/notes/presentation/editor/note_editor_screen.dart` (5521 satır),
**LİSTE** = aynı klasörde `items_editor.dart`, **SATIR** = `items_editor_row.dart`,
**BÜTÇE** = `test/perf_budget_test.dart` + `test/perf_budget/budgets.json`.

#### 0. Başlama kapısı (OTURTMA Faz 64 şartı) — TUTTU

Faz 64 "S3, S4, S9, S14 hedefteyse yapılmaz" der. Bugünkü `budgets.json`: S3 satır **23** (hedef ≤ 2),
S4 satır **23** (≤ 2), S9 tuval **2** (0), S14 tuval **1** (0). Dördü de hedefin üstünde → faz yapılır.
"Cihazda kök `build` < 4 ms" ölçülmedi (cihaz gerekir); senaryo şartı tek başına yettiği için beklenmez.

#### 1. Mimari kararlar (her biri kanıtlı)

**M1 — S3/S4'ün kökü kök `setState` DEĞİL, satır önbelleği anahtarındaki sıra numarası.**
Kanıt: LİSTE:1970–1998 `_cachedItemRow` anahtarında `reorderIndex` ve `orderNumber` var (1985–1986);
çağıran LİSTE:2325–2333 her satıra `reorderIndex: index` veriyor. 8. kutucuk işaretlenince madde işaretli
bloğa taşınır, arkasındaki 22 maddenin `index`'i bir kayar → 22 + kendisi = **23** satır önbellekten düşer
(`budgets.json` S3 "işaretlenen maddeden sonraki bütün satırlar" notu bunu doğruluyor); Enter'da aynı.
`reorderIndex` satırda YALNIZ sürükleme tutamağında (SATIR:134–141), `orderNumber` yalnız numara metninde
(SATIR:253) kullanılıyor. Karar: bu iki değer önbellekli satırın DIŞINDAN, küçük bir `InheritedWidget`
ile verilir; anahtardan çıkar. `NoteSlice` bu senaryoya hiçbir şey kazandırmaz (kök kurulum zaten 1).

**M2 — Tuval bölgesi dosyaya ÇIKARILMAZ; tuvale giden kök kurulumlar kaynağında kesilir.**
Kanıt: tuval `_buildCanvas` (EKRAN:2235) kökün `build`'inde üretilen `pageContent`'i (başlık + çipler +
gövde alanı + `ItemsEditor`, EKRAN:3596–3960; `ItemsEditor`'a ~30 parametre, EKRAN:3837–3960), stilleri
(3175–3207) ve ~20 geri çağrıyı alıyor; `_canvasCache` her kök kurulumda sıfırlanıyor (EKRAN:3018).
Bölgeyi ayrı widget yapmak ~1000 satırı ve P49/P50 bloklarını taşımak demek — Faz 64'ün kendi sınırı
("en pahalı 5 eylem, gerisi dokunulmaz") bunu kapsamıyor. Karar: kökü kuran **üç tetik** dar dinlemeye
alınır (M3–M5); tuval yerinde kalır. Sonuç: P49/P50'nin editör blokları yerinden OYNAMAZ ("AYNEN taşır"
şartı kendiliğinden sağlanır).

**M3 — Geri al/yinele durumu dar dinlenir.** Kanıt: EKRAN:1971–1973 `pureTyping`, `canUndo/canRedo`
değişince kökü kuruyor; ilk değişiklik (yıldız dahil) her zaman `canUndo` false→true yapar → S1'deki
1 kök kurulum ve S14'teki tuval kurulumunun bir nedeni bu. Yığını değiştiren yalnız 3 yer var
(EKRAN:1809 `undo`, 1826 `redoStep`, 1949 `push`); okuyan yerler EKRAN:5241–5290 (üst çubuk) ve
4629/4637 (alt çubuk). Karar: `ValueNotifier<(bool, bool)> _undoN`; okuyanlar `ValueListenableBuilder`.

**M4 — Yıldız/iğne `NoteSlice` ile dinlenir, `_sameVisual`'dan çıkar.** Kanıt: `build` içinde
`note.starred` yalnız EKRAN:5089–5103'te (tarihin yanındaki yıldız), `note.pinned` yalnız 5295–5312'de
(iğne düğmesi) okunuyor; parça dosyalarındaki kullanımlar (`note_editor_actions.dart`:426, 428) yalnız
`_mutate` çağrısı. `_sameVisual` (EKRAN:1857–1858) bu iki alanı karşılaştırdığı için her yıldız/iğne
kökü kuruyor. Mekanizma OTURTMA F64.2'deki `NoteSlice` (iskelet orada, AYNEN). `sameRenderedNote`
(EKRAN:327) DEĞİŞMEZ: uzaktan gelen değişiklik yine kökü kurar (seyrek, güvenli taraf).

**M5 — Biçim paneli kipi `ValueNotifier` olur.** Kanıt: `_formatBarOpen` (EKRAN:932) kök `setState`
ile değişiyor (4326, 4575, 4969; 1077 ve 1126'da panel açıkken hedef değişince de kök kuruluyor).
Okuyanlar: panel (4229), alt çubuk (4394), Biçim düğmesinin "etkin" hâli (4578), `PopScope.canPop`
(4943). Gövde boyu değişince tuval zaten önbellekten geliyor (EKRAN:3984–4008, `_canvasCache` taban
yükseklikle); S9'daki 2 tuval kurulumu yalnız bu kök `setState`'ten. Karar: alan notifier'a sarılır
(`bool get/set _formatBarOpen` korunur — `note_editor_find.dart`:18, 35 gibi eski atamalar bozulmaz),
dört okuyan dar dinler.

**M6 — `_sameVisual` / `sameRenderedNote` bu pakette SİLİNMEZ, daralır. KARAR GEREKİR → en güvenli seçenek,
sabah bakılacak.** F64.4 "silinir" diyor ama bu ancak `build`'deki BÜTÜN `note.` okumaları dilime
geçince doğru olur; F64.1 "en pahalı 5 eylem, gerisi dokunulmaz" sınırıyla çelişiyor. En güvenli:
taşınan alan `_sameVisual`'dan çıkar, kalan alan sayısı bekçi testiyle mandallanır (yalnız düşer).
Tam silme ayrı bir karar (tuval çıkarma = M2'nin tersi) — kullanıcıya.

**M7 — F64.5 kuralı CLAUDE.md'ye değil `docs/hafiza/editor.md`'ye yazılır.** Alt ajan CLAUDE.md ve
`.claude/skills/**` dosyalarına DOKUNMAZ (yapılandırma; yalnız kullanıcı). Kural metni adım 6'da;
"CLAUDE.md / `kasma-kontrol` md. 1'e işlensin mi" sabah bakılacak.

**M8 — Üst çubuk sırası alt çubuğun modelini aynen kullanır; varsayılan sıra BUGÜNKÜ sıra.**
Kanıt: alt çubuk `UiPrefs.barOrder` + `UiPrefs.orderOf` (`lib/core/personalize.dart`:43–101) ve
`PersonalizeBarList` (`lib/features/settings/presentation/personalize_bar_list.dart`) ile sıralanıyor.
Üst çubukta sarılı beş öğe var: `topHome` (EKRAN:5113), `topSync` (5156), `topUndo` (5241), `topPin`
(5295), `topFullscreen` (5329). İstek taraması (`python tool/design/istek_tara.py` EKRAN): "üst alanda
sadeleşme" (475), "SIKI ÜST ÇUBUK 48 dp" (5017), "tam ekrandan çıkmak çok zor → leading" (5022),
"etiketler tarihin solunda" (5053), "üst çubuk notun durumuna ayrıldı" (5314). Hiçbiri sıralanabilirliğe
karşı değil; bu yüzden: yükseklik, `leading`, başlık/tarih/etiket alanı, yazılım klavyesi düğmesi (5132)
ve ⋮ (5336, hep EN SONDA) sıralamaya GİRMEZ; yeni düğme eklenmez. Düzenleme modunda yerinde
sürükle-sırala YAPILMAZ (P50'de "sabah bakılacak" kalmıştı, hâlâ kullanıcı kararı).

**M9 — Editördeki 21 `HapticFeedback` → `AppHaptics`, TÜR değişmeden.** Kanıt:
`test/design_tokens/budget.json` `"haptic": 21`; sayım: `note_editor_media_view.dart` 11,
`note_editor_gestures.dart` 4, LİSTE 2, `items_editor_actions.dart` 2, `note_editor_flow.dart` 1,
EKRAN 1 (3001). Eşleme DENEYIM F77.2: `selectionClick→tick`, `lightImpact→thud`, `mediumImpact→heavy`,
`heavyImpact→heaviest`. `test/items_editor_hold_select_test.dart` `lightImpact` bekliyor — tür
değişmediği için yeşil kalmalı.

**Kapsam dışı (dokunma):** S2 (maddeye yazarken `ItemsEditor` 5 / satır 15 — hedefin fazı yok; adım 1
haritasına yazılır, düzeltilmez), tuvalin/çip şeridinin/sabit bölmenin dosyaya çıkarılması, kalem,
`config/app` bayrakları, veri biçimi.

#### 2. Adımlar (sırayla; adım kırmızıysa sonrakine geçme; her adım AYRI commit + push)

Her adımın sonunda ortak doğrulama: `"C:/src/flutter/bin/flutter.bat" test <adımın testleri> --reporter
failures-only` + `dart analyze <değişen dosyalar>`; push'tan önce tam `flutter analyze`. Tam takım yerelde
koşulmaz (CI). Bütçe mandalı: sayı düştüyse `budgets.json`'da ilgili anahtarı ÖLÇÜLEN değere indir,
`bugun` alanına "(2026-11-.., P20)" ekle; yükseltme yok.

**[x] Adım 1 — Kök kurulum haritası (F64.1; yalnız test, ürün kodu değişmez).** (2026-11-14, 991967bb: öngörü TUTTU — işaretle/Enter satır 23, yıldız/iğne tuval 1, biçim tuval 2, ilk değişiklik kök 1; yeni bulgu: metin geri alınınca kök kurulmuyor → yinele düğmesi `onPressed: null` bayat kalıyor, adım 3 `_undoN` çözer; tablo OTURTMA Ek A "F64.1 haritası")
- Dosyalar: YENİ `test/editor_rebuild_map_test.dart`; `OTURTMA_PLANI.md` Ek A'nın altına "F64.1 haritası" tablosu.
- Ne: `test/support/editor_harness.dart`'taki `pumpEditor` + `BuildCounter` ile (BÜTÇE:181 `_count`
  kalıbı) şu eylemlerin her biri için `NoteEditorScreen` / `NotePageCanvas` / `ItemsEditor` /
  `_LazyItemField` kurulum sayısını yazdır (`debugPrint`, `expect` yalnız "eylem gerçekleşti" için):
  işaretle, madde ekle (Enter), madde sil, sürükle-sırala, kalın uygula, renk, sabitle, yıldız, etiket
  ekle/sil, klasör, hatırlatıcı, ek ekle/sil, ek görünümü değiştir, kalem kipi aç/kapa, arama aç/kapa,
  biçim paneli aç/kapa, sayfa değiştir, geri al, yinele. Testte kurulamayan eylem (dosya seçici vb.)
  tabloya "üretilemedi: <neden>" yazılır, atlanır.
- Niçin: M1–M5 bugünkü bütçelerden çıkarıldı; harita bunları doğrular ve adım 2–5 için "önce" sayısını verir.
- Kabul: tablo Ek A'da; M1–M5'in öngörüsü tutuyor (işaretle/Enter satır ≈ 23, yıldız tuval 1, biçim tuval 2,
  ilk değişiklik kök 1). **Tutmuyorsa DUR**: DEVIR.md'ye farkı yaz, Kuyruk satırını `takıldı — harita
  planla uyuşmuyor` yap; adım 2+ uygulanmaz.

**[x] Adım 2 — Sıra numarası satır önbelleğinin dışına (M1; S3, S4).** (2026-11-14, a865ef1b: S3/S4 satır 23→1, S2 bonus 5/15→1/1. M1 YARIM DOĞRUYDU: anahtar düzeltmesi tek başına 23'ü düşürmedi — `SliverReorderableList` her satırı DİZİN içeren `_ReorderableItemGlobalKey` ile sarıyor, dizin kayınca öğe atılıp baştan kuruluyor. Ek düzeltme: tutamaç yokken (`!_showHandles`: telefon, Seç dışı) düz `ListView` (anahtarlı çocuklar korunur); tutamaçlı kipte (tablet/web, Seç) 23 kalır — sıralama orada lazım. `_RowSlot` `_cachedItemRow` içinde sarılıyor (üç çağrı yeri birden). Bilinen yan etki: Seç kipine giriş/çıkışta liste türü değişir, satır öğeleri yeniden kurulur (önbellek zaten env ile boşalıyordu; metin denetleyicileri durumda, kaybolmaz); erişilebilirlik "yukarı/aşağı taşı" eylemleri yalnız tutamaçlı kipte — sabah bakılacak)
- Dosyalar: LİSTE, SATIR, `items_editor_widgets.dart`, `test/items_editor_row_cache_test.dart`, BÜTÇE (yalnız `budgets.json` S3/S4).
- Önce kanıt (kırmızı): `items_editor_row_cache_test.dart`'a iki test — "kutucuk işaretlenince arkadaki
  satırlar `identical`" ve "araya madde eklenince arkadaki satırlar `identical`" (dosyadaki mevcut
  `identical` kalıbı, satır 84–127). Bugün kırmızı olmalı.
- Ne: `items_editor_widgets.dart`'a iskelet:
  ```dart
  /// Satırın listedeki yeri: önbellekli satırın DIŞINDAN verilir (P20 M1).
  class _RowSlot extends InheritedWidget {
    const _RowSlot({super.key, this.reorderIndex, this.orderNumber, required super.child});
    final int? reorderIndex; final int? orderNumber;
    static _RowSlot? of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<_RowSlot>();
    @override
    bool updateShouldNotify(_RowSlot o) =>
        o.reorderIndex != reorderIndex || o.orderNumber != orderNumber;
  }
  ```
  (a) `_cachedItemRow` anahtarından `reorderIndex` ve `orderNumber` çıkar; yerine `reorderIndex != null`
  (sürüklenebilir mi — bool) girer. (b) LİSTE'deki üç çağrı yeri (2215 işaretli blok, 2265 iki sütun,
  2328 sürüklenen liste) önbellekten dönen satırı `_RowSlot(key: ValueKey('slot-${item.id}'), …, child: satır)`
  ile sarar; `_packagedRow`'a sarılmış hâli verilir (dış anahtar kuralı: `ReorderableListView` çocuğunun
  en dış widget'ı anahtarlı kalmalı — `_packagedRow` paketsiz satırı olduğu gibi döndürüyor, o yüzden
  `_RowSlot` anahtar taşır). (c) SATIR:134–141 tutamaç: `ReorderableDragStartListener(index: …)` küçük bir
  `Builder` içinde `_RowSlot.of(context)!.reorderIndex!` okur; SATIR:253 numara metni aynı şekilde
  `orderNumber` okur. `_itemRow` imzasındaki `reorderIndex` yalnız "sürüklenebilir mi" için kalır
  (bool'a çevir), `orderNumber` parametresi kalkar.
- Kasma listesi: md. 2 (anahtara her kurulumda yeni nesne girmiyor), md. 4 (ağaç şekli: `_RowSlot` HER
  satırda var, koşullu değil), md. 5 (yukarıdaki `identical` testleri).
- Doğrulama: `test/items_editor_row_cache_test.dart`, `test/perf_budget_test.dart`,
  `test/items_editor_hold_select_test.dart`, `test/note_package_open_test.dart`, `test/items_grow_budget_test.dart`
  + `Glob test/items_editor*_test.dart` hepsi.
- Kabul: yeni iki test yeşil; S3 ve S4 `satir` ≤ 2 (taşınan satırın çıkış/varış evresi 3 verirse ölçüleni
  mandalla ve `neden`'e yaz — 23'ten düşüş şart); sürükle-sırala, sıralı liste numaraları ve paket hapı
  testleri yeşil.

**[x] Adım 3 — `_noteN` + `NoteSlice` + geri al dar dinleme (F64.2, M3; S1).** (2026-11-14, 8c4c9a44: S1 kök 1→0, S2 bonus 1/1→0/0; geri al → yinele artık etkin (bekçi `editor_rebuild_map_test`). `_noteN`/`_undoN` = `LateSafeValue` — düz ValueNotifier dispose sonrası yazımda assert, dispose edilmezse `editor_leak_test` kırmızı. Alt çubuk geri al/yinele görünüşü yığına bağlı değil → sarılmadı)
- Dosyalar: EKRAN, YENİ `lib/features/notes/presentation/editor/note_slice.dart`, YENİ `test/note_slice_test.dart`, `budgets.json` (S1).
- Ne: (a) `note_slice.dart`: OTURTMA F64.2'deki iskelet AYNEN (State `source`'u dinler, `select` sonucu
  `equals`/`==` ile aynıysa `setState` yok, `didUpdateWidget`'ta abonelik taşınır, `Note? == null` iken
  son değeri korur). Test: dilim dışı alan değişince `builder` çağrılmaz; kaynak değişince abonelik taşınır.
  (b) EKRAN:622 `Note? _note;` → `final _noteN = ValueNotifier<Note?>(null); Note? get _note => _noteN.value;
  set _note(Note? v) => _noteN.value = v;` (bütün eski `_note = …` atamaları derlenir; davranış aynı),
  `dispose`'ta `_noteN.dispose()` — sıra: `_debouncer.flush()`'tan SONRA (EKRAN `dispose` notuna bak).
  (c) `final _undoN = ValueNotifier<(bool, bool)>((false, false));` + `_syncUndoN()`; EKRAN:1809, 1826,
  1949'daki yığın değişikliklerinden hemen sonra çağır. `pureTyping`'ten (1971–1973) `canUndo/canRedo`
  koşullarını çıkar. EKRAN:5241–5290 (geri al/yinele bölgesi, `Customizable(id: UiItem.topUndo)` İÇİ) ve
  alt çubuktaki geri al/yinele düğmeleri (4629/4637 çevresi) `ValueListenableBuilder<(bool, bool)>` ile
  sarılır; `_barTitle == null || _canRedo` gibi koşullar builder'ın içinde kalır (ağaç şekli bugünküyle aynı).
- Niçin: ilk tuş/ilk değişiklikte kök yalnız geri al düğmesi için kuruluyordu.
- Doğrulama: `test/note_slice_test.dart`, `test/perf_budget_test.dart`, `test/editor_top_customize_test.dart`,
  `test/editor_bar_customize_test.dart`, `test/note_echo_rebuild_test.dart`, `test/editor_typing_perf_test.dart`,
  `Grep "undo" test/` ile çıkan editör testleri.
- Kabul: S1 `kok_kurulum` 0 (mandal 1→0); geri al düğmesi ilk harften sonra etkin, geri al → yinele etkin
  (mevcut testler + yoksa bir `testWidgets` ekle); S5/S6/S7/S11 değişmedi.

**[x] Adım 4 — Yıldız/iğne dilimi + `TogglePop` (F64.3/F64.4 kısmi, M4, P38 kalanı; S14).** (2026-11-14, 63987bd5: S14 tuval 1→0. Dilimler S18 ilk kareye +6 ekledi (mandal 876) → `Customizable` tek StatefulWidget'a indi (öğe başına −1): S18 871, S24 930→927)
- Dosyalar: EKRAN, `budgets.json` (S14), YENİ `test/editor_star_pin_slice_test.dart`.
- Ne: (a) EKRAN:5089–5103 `if (note.starred) IconButton(...)` → `NoteSlice<bool>(source: _noteN,
  select: (n) => n.starred, builder: (context, on) => TogglePop(on: on, child: on ? <aynı IconButton> :
  const SizedBox.shrink()))` (şekil sabit — kasma md. 4). (b) EKRAN:5297–5312 iğne `IconButton`'ı
  `NoteSlice<bool>(select: (n) => n.pinned, …)` içine; simge `TogglePop(on: pinned, child: Icon(...))`.
  `noteAccent` builder'a kapanışla girer (renk değişince kök zaten kurulur). `Customizable`/`_hideWhileTyping`
  sarmaları DIŞARIDA aynen kalır. (c) `_sameVisual`'dan `a.pinned == b.pinned` ve `a.starred == b.starred`
  satırları (1857–1858) silinir. `sameRenderedNote`'a dokunma. (d) `TogglePop` =
  `lib/core/widgets/toggle_pop.dart` (yalnız `Transform`; boy değişmez — kasma md. 6).
- Önce kanıt: yeni testte "üst çubuk iğnesine dokun → `NotePageCanvas` kurulumu 0, simge `push_pin` oldu,
  kayıtta `pinned == true`" ve yıldız için aynısı (⋮ → `menu-quick-star`, S14 kalıbı BÜTÇE:851). Bugün tuval 1.
- Tuzak: kök kurulmadığı için `build`'in yerel `note` değişkenini yakalayan kapanışlar bir önceki notu
  görür — bu saf yazımda zaten böyle; yeni kod `note.pinned`/`note.starred`'ı builder DIŞINDA okumasın
  (`Grep "note\.(starred|pinned)"` EKRAN: yalnız dilim içinde kalmalı).
- Doğrulama: yeni test, `test/perf_budget_test.dart`, `test/toggle_pop_test.dart`, `test/note_accent_consistency_test.dart`,
  `test/note_everywhere_same_test.dart`, `test/editor_top_customize_test.dart`.
- Kabul: S14 `tuval_kurulum` 0; iğne/yıldız görünür tepki veriyor; `haptics_test` yeşil.

**[x] Adım 5 — Biçim paneli kipi dar dinleme (M5; S9).** (2026-11-14, 627a4da6: S9 tuval 2→0, boy karesi 2; S18 874 (3 dar dinleyici, main 876'nın altında). Geri tuşu bekçisi `test/format_panel_back_test.dart`)
- Dosyalar: EKRAN, `budgets.json` (S9).
- Ne: (a) EKRAN:932 → `final _formatOpenN = ValueNotifier<bool>(false); bool get _formatBarOpen =>
  _formatOpenN.value; set _formatBarOpen(bool v) => _formatOpenN.value = v;` (+ dispose). (b) Kök
  `setState`'siz üç tetik: Biçim düğmesi (4574–4577: `_barSwapped = true; _formatBarOpen = !_formatBarOpen;`),
  panel kapat (4326), geri tuşu (4968–4970). (c) Okuyanları sar: panel (4226–4232 `TapRegion` çocuğu),
  alt çubuk (4394 `TypingBarHide` çocuğu — Biçim düğmesinin etkin hâli 4578 bunun içinde) →
  `ValueListenableBuilder<bool>(valueListenable: _formatOpenN, builder: …)`; `PopScope` (4938–4945) →
  `ValueListenableBuilder<bool>(valueListenable: _formatOpenN, child: <bugünkü PopScope.child, yerinde>,
  builder: (context, open, child) => PopScope(canPop: … && !open …, onPopInvokedWithResult: …, child: child!))`;
  `ref.watch(noteFullscreenProvider)` builder'dan ÖNCE yerel değişkene alınır. (d) Panel açıkken hedef
  değişimi (1077, 1126 `setState`): panelin builder'ı `Listenable.merge([_formatOpenN, _formatTargetN])`
  dinler, iki `setState` kalkar (`_formatTargetN` zaten 1068 ve 1109'da güncelleniyor).
- Kasma listesi: md. 3 (yerel kip → notifier), md. 4 (kapalıyken `SizedBox.shrink` bugünkü gibi durur),
  md. 6 (boy TEK adımda: S9 `govde_boy_karesi` 2'yi GEÇMEZ; `AnimatedSize` ekleme).
- Doğrulama: `test/perf_budget_test.dart`, `test/keyboard_jank_guard_test.dart`, `test/note_package_open_test.dart`,
  `test/editor_bar_customize_test.dart`, `test/jank_patterns_guard_test.dart`, `Glob test/*format*_test.dart`,
  `Glob test/*find*_test.dart` (arama açılınca panel kapanır: `note_editor_find.dart`:18, 35).
- Kabul: S9 `tuval_kurulum` 0, `govde_boy_karesi` ≤ 2; geri tuşu sırası (tam ekran → kayıt → biçim → arama → not)
  bozulmadı; panelde etkin biçim vurgusu imleç başka alana geçince güncelleniyor.

**[x] Adım 6 — Kural + bekçiler (F64.5, M6, M7).** (2026-11-14: `test/editor_core_guard_test.dart` (`_update(` ≤ 32, `_sameVisual` ≤ 32 terim, `note.starred/pinned` build'de yok); kural `docs/hafiza/editor.md`; M6/M7 sabah bakılacak)
- Dosyalar: YENİ `test/editor_core_guard_test.dart`, `docs/hafiza/editor.md`, `OTURTMA_PLANI.md` (F64.1–F64.5 `[x]`/not + Durum tablosu Faz 64).
- Ne: bekçi (kaynak dosyayı metin olarak okur, `design_tokens_guard_test.dart` kalıbı): (1) `note_editor_*.dart`
  içindeki `_update(` satır sayısı bugünküyü geçemez (ölç, sabitle; bugün 32 satır); (2) `_sameVisual`
  gövdesindeki karşılaştırma sayısı bugünküyü geçemez; (3) EKRAN'da `note.starred`/`note.pinned` yalnız
  `NoteSlice` builder'ında. `docs/hafiza/editor.md`'ye kural: "Editöre yeni görünür parça = `NoteSlice` ya da
  kendi notifier'ını dinleyen ayrı widget; `_NoteEditorScreenState`'e alan/`_update` eklenmez; madde sırasına
  bağlı değer satır önbelleğine girmez (`_RowSlot`)". F64.4 maddesine M6 notu ("silinmedi, daraldı — sabah bakılacak").
- Kabul: bekçi yeşil; plan maddeleri işaretli.

**Adım 7 — Editör titreşim göçü (M9).**
- Dosyalar: `note_editor_media_view.dart`, `note_editor_gestures.dart`, `note_editor_flow.dart`, LİSTE,
  `items_editor_actions.dart`, EKRAN (yalnız 3001), `test/design_tokens/budget.json` (`haptic` 21→0).
- Ne: 21 çağrıyı M9 eşlemesiyle çevir; tür DEĞİŞMEZ, çağrı eklenmez/silinmez. `lib/core/haptics.dart`'a bak:
  eşleşen yöntem yoksa çağrıyı BIRAK ve bütçeyi kalan sayıya indir.
- Doğrulama: `test/design_tokens_guard_test.dart`, `test/haptics_test.dart`, `test/items_editor_hold_select_test.dart`.
- Kabul: `haptic` bütçesi 0 (ya da gerekçeli kalan); testler yeşil.

**Adım 8 — Üst çubuk sırası: model + Ayarlar listesi (M8; P50 kalanı).**
- Dosyalar: `lib/core/personalize.dart`, `lib/features/settings/presentation/personalize_bar_list.dart`,
  `personalize_screen.dart`, `lib/l10n/*.arb` (+ `flutter gen-l10n`, üretilen dosyalar `dart format`),
  YENİ `test/personalize_top_order_test.dart`.
- Ne: `UiPrefs.topOrder` (`barOrder` ile birebir aynı kalıp: alan, `copyWith`, `toJson` yalnız doluysa,
  `fromJson`, `==`/`hashCode`); `UiItem.topDefault = [topHome, topSync, topUndo, topPin, topFullscreen]`
  (bugünkü ekran sırası). Ayarlar → Kişiselleştir'de alt çubuk listesinin altına "Üst çubuk" grubu:
  aynı satır widget'ı (tutamaçla sürükle-sırala + göster/gizle anahtarı), kapsül oku YOK. Görünüş kararı
  yok: mevcut satırın aynısı. Önce `python tool/design/istek_tara.py` her iki ayar dosyasında.
- Doğrulama: yeni test (varsayılan sıra = `topDefault`; kayıtlı sıra korunur; bilinmeyen kimlik yok sayılır;
  JSON gidiş-dönüş), `test/page_panel_personalize_test.dart`, `test/guide_screen_test.dart` (arb değişti → CI tam takım koşar).
- Kabul: testler yeşil; eski kayıtlı tercih (`topOrder` yok) bugünkü sırayı verir.

**Adım 9 — Üst çubuk sırasını editörde uygula + ana ekran sarmaları (M8; P50 kalanı).**
- Dosyalar: EKRAN (yalnız `actions:` 5107–5340), `dashboard_screen.dart`, `dashboard_widgets.dart`,
  `lib/core/personalize.dart` (yalnız yeni `UiItem.home*` kimlikleri), `personalize_screen.dart` (ana ekran
  öğeleri listesi, 678), `test/editor_top_customize_test.dart`, YENİ `test/home_customize_wraps_test.dart`.
- Ne: (a) `actions:` listesindeki beş sarılı öğe `{kimlik: widget}` haritasına alınır,
  `UiPrefs.orderOf(UiItem.topDefault, prefs.topOrder)` sırasıyla dizilir (alt çubuğun 4560 çevresindeki
  kalıbı); yazılım klavyesi düğmesi bugünkü yerinde (Ana sayfa'nın ardında, sabit), ⋮ en sonda; koşullar
  (`_hideWhileTyping`, geniş ekran, tablet) öğenin KENDİ widget'ında kalır. Adım 3–4'ün dilimleri öğelerin
  içinde aynen durur. (b) Ana ekran: önce döküm — `dashboard_screen.dart` + `dashboard_widgets.dart`'ta
  üst çubuk/araç çubuğu düzeyindeki dokunulabilir öğelerden `Customizable` ile sarılı OLMAYANLAR
  (bugün sarılı: `homeAccount` dashboard_screen:1803, `homeMic` 2317, `homeFilter` dashboard_widgets:444).
  Yalnız SÜREKLİ görünen çubuk öğeleri sarılır (not kartı, klasör çipi, seçim kipi çubuğu, ⋮ menüsü ve
  arama kutusunun kendisi SARILMAZ — gizlenince geri getirilemez ya da S13/S21/S24 bütçesini etkiler).
  Her yeni öğe: yeni `UiItem.home…` kimliği + Ayarlar listesinde satır. Aday yoksa "sarılacak öğe kalmadı"
  yaz, kod yazma.
- Kasma listesi: md. 4 (`Customizable` gizliyken ağaç şekli — mevcut sarmaların davranışıyla aynı olmalı),
  md. 8. Ana ekran bütçeleri S13, S18–S26 DEĞİŞMEMELİ (P38'de klasör çipine sarmalayıcı S24'ü 930→939 bozup
  geri alınmıştı — DENEYIM F77.3 notu): bir sarma S24'ü artırıyorsa o sarma YAPILMAZ, maddeye yazılır.
- Doğrulama: `test/editor_top_customize_test.dart` (+ "kayıtlı sıra uygulanır, ⋮ sonda" testi), yeni ana ekran
  testi, `test/perf_budget_test.dart`.
- Kabul: varsayılan görünüm piksel olarak aynı (`flutter test tool/tour/screen_tour_test.dart` — `TOUR_COMPARE`
  farkı yalnız bilinçli değişiklikte); bütün bütçeler ≤ mandal.

**Adım 10 — Kapanış (işçi kuralları "Bitiş").**
- CI yeşil (`gh run list -b oto/P20-editor-cekirdek -L 1`; kırmızıysa yalnız başarısız işin kuyruğu, en çok 2 tur).
- **Cihaz kapısı (Cihaz = A/B, hız işi → kötüleşme SIFIR):** `ab-olcum` skill'i; `python -u tool/perf/ab_hepsi.py
  <önceki [apk] profil APK> <dal profil APK> --altin`; tablo + son satır DEVIR.md'ye. Cihaz yoksa:
  "yazıldı, cihazda doğrulanmadı" + `KALANLAR.md` §2'ye adım (liste notunda kutucuk işaretle/Enter, yıldız,
  iğne, biçim paneli aç-kapa, üst çubuk sırası) — birleştirme kararı yürütücünün.
- Belgeler: Kuyruk satırı; OTURTMA Durum Faz 64 + Ek A "bugün" sütunu (S1, S3, S4, S9, S14);
  `docs/regresyon_listesi.md` satırı; `docs/hafiza/editor.md` + `akicilik.md` (M1 kök nedeni: "sıra numarası
  önbellek anahtarındaydı"); sürüm notu taslağı `assets/guide/release_notes_tr.md` + `_en.md`
  (`{#2026-11-14}` ya da birleştirme günü; kullanıcı diliyle: uzun listede işaretleme/madde ekleme daha
  akıcı; yıldız/iğne dokununca tepki verir; üst çubuk düğmelerinin sırası Ayarlar'dan değişir).

#### 3. Alt ajan bölümlemesi (dosya çakışmasız)

| Tur | Alt ajan | Adımlar | Dokunduğu ürün dosyaları |
|---|---|---|---|
| 1 | A (Opus) | 1 → 2 | `items_editor*.dart` |
| 2 | B (Opus) | 3 → 4 → 5 → 6 | EKRAN, `note_slice.dart` |
| 2 (B ile AYNI ANDA, alt dal `oto/P20-artik`) | C (Opus) | 7 (EKRAN:3001 HARİÇ) → 8 | editör parça dosyaları, `personalize*.dart`, `.arb` |
| 3 | B ya da yeni (Opus) | C'nin dalını birleştir → 7'nin EKRAN satırı → 9 → 10 | EKRAN `actions:`, `dashboard_*` |

Tur 2'de `budgets.json`'a yalnız B, `design_tokens/budget.json`'a yalnız C yazar. Limit darsa tek ajan
1→10 sırayla da yürür; adım 2 bittiğinde ve adım 6 bittiğinde dal kendi başına birleştirilebilir durumdadır
(yarım kalırsa Kuyruk satırına hangi adımda kalındığı yazılır).

#### 4. Riskler

- **Bayat kapanış (adım 3–5):** kök daha az kurulunca `build`'in yerel `note`/`_formatBarOpen` kopyasını
  yakalayan kapanış eski değeri görür. Kural: taşınan değeri okuyan HER yer dilim/notifier builder'ında;
  adım 6 bekçisi yıldız/iğne için bunu zorlar. Şüphede o tetik kök `setState`'te BIRAKILIR (sayı düşmez ama
  hata çıkmaz) ve maddeye yazılır.
- **`ReorderableListView` anahtarı (adım 2):** dış widget anahtarsız kalırsa çalışma anında assert; odak ve
  `_LazyItemField` durumu `ValueKey(item.id)` altında kaldığı için kaybolmamalı — `items_editor_hold_select_test`
  ve sürükleme testleri kapı.
- **`PopScope` sarması (adım 5):** `child` builder'a `child:` parametresiyle geçmezse bütün iskele her kip
  değişiminde kurulur (S9 düşmez) — kabul ölçütü bunu yakalar.
- **S24 soğuk açılış (adım 9):** ana ekrana eklenen her sarmalayıcı ilk kare sayısını artırabilir; mandal
  yükseltilmez, sarma geri alınır.
- **Cihazsız sayılar süre değildir:** adım 2–5'in kazancı kurulum SAYISI; "akıcı" denmez, A/B tablosu konuşur.
- **Tam hedef dışı kalanlar:** S2 ve `_sameVisual`'ın tam silinmesi (M6) bu paketle kapanmaz — P22 listesine.

## P41 — Belirteç göçü

Model: sonnet · Cihaz: - · APK: -

**Plan maddeleri:** DENEYIM F72.6

**Durum:** bekliyor — mekanik; editör klasörü hariç. Kapanış toparlaması P22'de (P53 katıldı).

**Katılanlar (yeniden düzen 2026-11-14):** P38 kalanı: P55/P56 çitinde bırakılan 35 `HapticFeedback` çağrısı → `AppHaptics` (P38 dalının DEVIR'indeki liste; P47 çöp sürüklemesi davranışı korunur). Şart değişti: "açık dal yokken" yerine P20 ile PARALEL; dosya çiti `lib/features/editor/**`, `note_editor_screen.dart` ve P20'nin değiştirdiği dosyalar.

## P22 — KAPANIŞ: açıkta kalan maddeler + büyük toparlama (P53 katıldı 2026-11-14)

**Yeniden düzen (2026-11-14):** tek ajan, iki evre, aynı dal. 1. evre: aşağıdaki açık maddeler + P45 F83.3 (CI kare ölçümü kararı → kullanıcı listesine). 2. evre: §P53 protokolü (tek plan, tek kullanıcı kontrol listesi, HAFIZA/CLAUDE.md toparlama). Evre arası DEVIR.md ile; limit keserse devralan 2. evreden sürer.

Model: opus · Cihaz: gerekirse · APK: gerekirse

**Plan maddeleri:** Kalan açık `[ ]` maddeler (2026-11-12 ayıklandı): kalem/mürekkep F61.7, F61.8, F62.4, F62.6, F63.6, F63.7 · tablet F67.6, F67.8 · F66.5 (yalnız rapor) · F68.5 (park) · cihaz turu F69.1–F69.3. (P40'ın "sabah bakılacak"ları — Gelen süzgeci hata hâli, AI levhası çevrimdışı, bekleyen ek şeridi — bulutta yapıldı 2026-11-13, DENEYIM F79.6; cihazda doğrulanmadı.) BAŞKA PAKETE TAŞINDI, burada YAPILMAZ: F58.1/F58.4 → P53, F60.5/F60.S2/F68.3 → P46, F68.4 → P43, F65.1/F65.2/F65.3/F67.5 → P49, F65.6 → P48; F60.7, F66.1–3 zaten kapandı (Ek D) + "cihazda doğrulanmadı" / "tablette doğrulanmadı" işaretli maddeler + açık K-O kararları

**Durum:** bekliyor — protokol aşağıda

## P53 — BÜYÜK TOPARLAMA (P22'nin 2. evresi; ayrı paket değil)

Model: opus · Cihaz: - · APK: -

**Plan maddeleri:** kullanıcı 2026-11-12: "bitmişleri sil, eski planları tamamen toparla, tek plana indir, kafa karışıklığı olmasın; benim kontrol etmem gerekenleri madde madde, anlayacağım şekilde bir dosyaya yaz; diğerlerini grupla, kaldır; HAFIZA, CLAUDE.md dahil toparla, main'e gönder" + F69.4, F69.5 (eski P21) + OTURTMA F58.1, F58.4

**Durum:** bekliyor — EN SON (P22'den sonra). Protokol aşağıda (P53 protokolü)

## Protokoller ve paket grubu kuralları (OTOMASYON.md'den taşındı, AYNEN)

**P22 protokolü (kullanıcı isteği 2026-11-10):** P01–P21 bitince `OTURTMA_PLANI.md`'yi baştan tara; `[ ]` kalan HER maddeyi otomatik değerlendir, soru sorma. Her madde için sırayla: (1) kanıtla — kod/test/ölçümle hâlâ geçerli mi, başka işle kapanmış mı; (2) kapanmışsa `[x]` + tek satır kanıt, gereksizse `[~]` + neden; (3) geçerliyse kendi modeli neyse ona uygun işle: kısa maddeleri kendin yap, Fable gerektirenleri (güvenlik/performans/editör/kalem) `Agent` ile `model: "fable"` alt ajana ver, mekanik olanları `sonnet` alt ajana; (4) KARAR çıkarsa plandaki "En güvenli" seçenek + maddeye "sabah bakılacak"; (5) telefon/tablet/hesap gerektirenler yapılamaz → "yazıldı, cihazda doğrulanmadı" + `KALANLAR.md` §2'ye adım. Kullanıcı işi olanları (konsol, hesap, telefon) yapma, yalnız `KALANLAR.md`'ye topla. Küçük commit'ler, CI yeşilse `[apk]`; sonunda plan Durum tablosu + HAFIZA güncelle ve geriye kalanın dürüst listesini yaz.

**P53 protokolü (kullanıcı isteği 2026-11-12):** bütün P'ler (P22 dahil) bitince, EN SON. Kod yazmaz, yalnız belge toparlar; veri/kanıt kaybetmez (silinen her şey git geçmişinde ve arşivde kalır). Sırayla:
1. **Tek plan — `PLAN.md`:** bütün plan dosyalarını (`OTURTMA_PLANI`, `DENEYIM_PLANI`, `HIZ_PLANI`, `KALAN_ISLER_PLANI`, `KUYRUK_AYRINTI.md` (P53 bitince yalnız protokol/kural bölümleri `docs/hafiza/`'ya, açık satır ayrıntıları PLAN.md'ye girer; dosya sonra arşive), `YOL_HARITASI`, `PERFORMANS_TOPARLAMA_PLANI`, `KULLANICI_DENEYIMI_PLANI`, `AKICILIK_PLANI`, `TEMA_PLANI`, `TUTARLILIK_PLANI`, `TAKVIM_PLANI`, `YORUM_ANALIZI_PLANI`, `KALEM_PLANI`, `KALANLAR.md`) madde madde tara. `[x]` bitmişler PLAN'a GİRMEZ. Açık kalan her madde PLAN.md'de tek satır, üç gruptan birinde: **(A) Senin yapacakların** (aşağıdaki listeye işaret), **(B) Bekletilenler / park** (neden + hangi kararla), **(C) Açık kod işi** (varsa; model + kısa kapsam). Her satırın sonunda eski kimliği (ör. `F65.6`) dursun ki geçmişe bakılabilsin.
2. **Senin kontrol listen — `KONTROL_LISTEM.md`:** kullanıcının yapması/bakması gereken HER şey, madde madde, sade Türkçe, teknik terim ve dosya adı olmadan. Her madde: ne (bir cümle) · nerede (uygulamada hangi ekran / hangi konsol sayfası) · nasıl (2–4 adım) · doğruysa ne görmeli · yanlışsa ne yapmalı (ör. "ekran görüntüsü alıp bana gönder"). Gruplar: **Telefonda bak** · **Tablette bak** · **Bilgisayarda (web) bak** · **Konsol/hesap işleri** (Firebase, Google Cloud, GitHub). "Cihazda doğrulanmadı / tablette doğrulanmadı / sabah bakılacak" işaretli bütün maddeler ve açık KARAR'lar buraya (karar maddesinde: seçenekler, şu an uygulanan "en güvenli" seçenek, değiştirmek isterse ne demeli). Kutucuklu (`- [ ]`), en önemlisi üstte; 40 maddeyi geçerse benzerlerini birleştir.
3. **Eski planları kaldır:** yukarıdaki plan dosyalarını `docs/arsiv/planlar/`'a TAŞI (`git mv`, silme). Önce `test/`, `tool/`, `.github/` içinde bu dosya adlarını okuyanları bul (2026-11-12'de: `test/color_roles_test.dart`, `test/design_components_test.dart`, `test/design_tokens_guard_test.dart`, `test/perf_budget/budgets.json`, `tool/design/istek_tara.py`, `tool/design/token_sayim.py`) ve yollarını güncelle — test kırmızıya dönmesin. DENEYIM §2 tasarım sözleşmesi ve §4 "çelişen fikirler" listesi, HIZ hız sözleşmesi gibi KALICI KURALLAR arşive gitmesin: `docs/hafiza/` ilgili konu dosyasına (arayuz, akicilik) taşı.
4. **OTOMASYON.md:** Kuyruk'ta yalnız açık satırlar kalsın; bitmiş P satırları tek satırlık "Biten paketler: P01–P53 (ayrıntı git geçmişinde ve `docs/arsiv/`)" ile değişsin. Yürütme kuralları aynen kalır.
5. **CLAUDE.md:** "Yol haritası" bölümündeki 12 plan maddesi TEK satıra iner: "Açık iş: `PLAN.md`; kullanıcının kontrol listesi: `KONTROL_LISTEM.md`; eski planlar `docs/arsiv/planlar/` (yalnız geçmiş)". F58.1 (dondurma kuralı) ve F58.4 (oturum disiplini) burada eklenir. Kasma kontrol listesi ve ölçüm kapısı gibi geçerli kurallar AYNEN kalır; tarihi geçmiş açıklamaları kısalt.
6. **HAFIZA:** `HAFIZA.md` ve `docs/hafiza/*.md`'de bayatlamış kural (artık olmayan dosya/plan adı, değişmiş eşik) düzelt; tarihçe `HAFIZA_ARSIV_*` dondurulmuş kalır. `test/hafiza_size_test.dart` yeşil kalsın.
7. **F69.4 konsol listesi, F69.5:** KONTROL_LISTEM'in "Konsol/hesap" grubuna gir.
8. Dalda çalış, CI yeşil → main'e birleştir (kod değişmediyse `[apk]` YOK). Kullanıcıya son mesaj: KONTROL_LISTEM.md'nin yolu + kaç madde + ilk 3 madde.

**P33–P42 = `DENEYIM_PLANI.md` (kullanıcı isteği 2026-11-12: "görünen ve hissedilen her
şeyi mükemmelleştir; tasarım Fable'da" + "diğer fazlarla zıt olmasın, aynı yerde tekrar
tekrar çalışmayalım").** Bu paketlerin maddeleri, protokolü ve "Önce oku" listeleri O
dosyadadır (işçiye `OTURTMA_PLANI.md` yerine onu okut). Kurallar: (1) oradaki **K-D
kararları VERİLMİŞTİR** — "en güvenli"ye düşme; her K-D tek başına geri alınabilir tek
commit. (2) **Önce eski isteğe bak:** görünüş/yer değiştirmeden önce `python
tool/design/istek_tara.py <dosya>`; çelişen iş YAPILMAZ (plan §4'teki 16 fikir dahil).
(3) **Kapsam çiti = plan Ek D:** her paket yalnız orada adına yazılı dosyalara dokunur.
(4) **Sıra (kullanıcı kararı 2026-11-12: "Fable işleri limit ilk açıldığında ilk yapılsın"):**
FABLE ÖNCE — P36 → P39 → P49 → P50 → P20, sonra Opus/Sonnet: P37 → P38 → P40 → P48 → P42 → P41 → P22 → P53 (EN SON).
**HIZ (kullanıcı kararı 2026-11-12):** P39 → P43 (P44 katıldı) → P45 → P46 her şeyden önce (plan `HIZ_PLANI.md`; işçiye onu okut).
Fable paketi yalnız 5 saatlik limit taze/düşükken (%55 altı) başlar; %55 üstündeyse sıradaki
Opus/Sonnet paketi yapılır, Fable paketi `bekliyor` kalır ve limit yenilenince (resetsAt sonrası
ilk tur) EN BAŞTA alınır. P20 başlama şartı tutmuyorsa atla; tek şart P33 bitmiş olsun. P41 yalnız Kuyruk'ta `sürüyor`
/ `bulutta:` satırı yokken. (5) Her paket işe başlamadan ekran turunu `build/tour-once/`'ye
alır, bitince `TOUR_COMPARE` ile karşılaştırır; yürütücü kabulde adı geçen PNG'lere kendi
bakar. (6) **P22 ATLAR** (bu planla kapandı ya da taşındı): K-O5, K-O10, K-O11, K-O14,
F60.7, F63.5, F66.1, F66.2, F66.3, F66.4, F66.6, F67.7. **K-O6 / F65.1: kullanıcı 2026-11-12 P49 ile açtı ("sabit ek tasarımı, tuşları, özellikleri baştan")**
(yalnız P49 yapar, P22 dokunmaz). (7) HAFIZA/CLAUDE/KALANLAR/plan toparlaması yalnız P53'te (tek kapanış; eski P21).

Atlananlar (kullanıcı kararı bekliyor, gözetimsiz yapılmaz): K-O1, K-O3 (v2 yazımını açma),
K-O4, K-O6, K-O7, K-O8, K-O10, K-O11, K-O12, K-O14, F63.6, F65.6 (kullanıcıdan hata metni),
F69.1–F69.3 (elle cihaz turu).

## P55 — KASMA KÖKTEN: not aç/kapa, klavye, alt panel titremesi

Model: opus (kullanıcı 2026-11-13) · Cihaz: A/B · APK: evet

**P46'dan katıldı (kullanıcı 2026-11-13):** HIZ_PLANI F84.1–F84.3 + OTURTMA F60.S2 (klavye birikim kasması), F60.5 (yazma ana bloğu), F68.3 (liste akışı K-O13). P46 dalının DEVIR.md'sindeki bulgulardan sür; P46 birleştikten sonra main'den başla.

**Kullanıcı (2026-11-13):** "genel olarak not açılış kapanış, klavye açılış kapanışlarda kasma, akıcı açılamama, titreme sorunları var; bunların artık kökten çözülmesi gerekiyor, ne gerekiyorsa yapın." Ayrıca: (a) "Alt çizgi varken madde altında kasma oluyor klavye açılırken." — **bulutta (2026-11-13) kısmen:** testte ayırıcılı/ayırıcısız madde arasında kurulum ve boyama sayısı farkı YOK (klavye açılışı, 60 madde); kök neden adayı raster: kesikli/noktalı ayırıcı satır başına 30–70 ayrı `drawLine`, dalgalı ~250 noktalı yol — Impeller her karede yeniden üçgenliyor. `paintItemDivider` tek `drawPoints`/`drawPath` (dalga yarım dalga başına tek eğri); bekçi `test/item_divider_paint_test.dart` (önce 7 kırmızı → yeşil). CİHAZDA DOĞRULANMADI: düz çizgide kasma sürüyorsa kök neden başka — timeline izi gerek (protokol 1). (b) "Alt panel hâlâ titriyor — ona özel test yaptır."

**Protokol (yama değil, kök neden):**
1. Kanıt: telefonda (ölçüm kimliği `dev.kaimau.notlar.olcum`, profil derleme) her evre için timeline izi: not aç, not kapat, klavye aç, klavye kapat, yazma, alt çizgili madde + klavye aç. Kare başına en pahalı build/layout/paint düğümlerini ve kaç kez kurulduğunu çıkar (`tool/perf/` araçları, `ab_hepsi.py` evreleri; gerekirse iz ayrıştıran küçük betik). Bulgular DEVIR.md + HIZ_PLANI'na sayılarla.
2. Her kök neden için cihazsız bekçi (`test/perf_budget_test.dart` senaryo + `budgets.json` mandalı ya da `keyboard_jank_guard_test` kalıbı) — önce KIRMIZI.
3. **Alt panel titremesi özel testi:** klavye açılış/kapanış animasyonunu kare kare süren widget testi; alt panelin/alt çubuğun dikey konumu her karede tekdüze (monoton) olmalı, ileri-geri salınım (yön değişimi) ve 1 px üstü sıçrama = KIRMIZI. Hem telefon hem tablet düzeni. Cihazda da: ekran kaydı/kare izinde konum dizisi.
4. Düzelt (CLAUDE.md kasma kontrol listesi 1–8; boy tek adımda, hareket yalnız boyamada; KeyboardSwitch sökmez), aynı kanıt yeşil, cihazda A/B iyileşme. Her kök neden AYRI commit.
4b. P49 bulgusu (2026-11-13): sabit ekli notta ilk klavye açılışında bir `AnimatedSize` 6 kare Scaffold'u dizdiriyor (editör alt çubuğu adaylarından; hangisi belirsiz) — bul ve düzelt.
5. Kapsam: editör açılış geçişi (S18 ikinci kare), kapanış, klavye inset'iyle yeniden dizilen her şey, alt çizgi/biçimli madde satırının klavye açılırken yeniden dizilmesi. `pinned_media_pane.dart` P49'da ise dokunmadan bulguyu P49 satırına yaz.

## P56 — Not sürükle-sırala: iki sütun arasında zıplama

Model: opus · Cihaz: A/B · APK: evet

**Kullanıcı (2026-11-13):** "Not sıralama iki sütunun arasında geldiğinde anlık bir sağa bir sola geçtiği için aşırı zıplamalar oluyor."

**Kök neden adayı:** iki sütunlu ızgarada sürüklenen kart iki sütunun sınırındayken hedef indeks her karede değişiyor (histerezis yok) → kartlar sağ/sol arasında gidip geliyor. Çözüm: hedef değişimine histerezis/eşik (sınırdan belirli pay geçmeden ve kısa süre kalmadan yer değiştirme yok) ve yer değiştirme animasyonu sırasında yeniden hedeflememe. Önce tekrar üreten widget testi (sınırda küçük titreşimli sürükleme → hedef indeks değişim sayısı ≤ 1), sonra düzelt. P47 çöpe sürükleme ve `_previewCardDrop` korunur.

**Durum (2026-11-13, bulut):** dalda bitti — `oto/P56-surukle-zipla`. KÖK NEDEN doğrulandı: `_ReorderableNoteCell` `DragTarget.onMove` her olayda `_previewCardDrop` → anında yer değişimi; yerleşim kayınca parmağın altına komşu gelir, o da geri değiştirir. Düzeltme `reorder_hover_gate.dart` (`ReorderHoverGate`): durma 100 ms + soğuma 300 ms + itilen kart parmak çıkana dek (`DragTarget.onLeave`) kilitli; durgun fare/kalem için zamanlayıcı yeniden dener. Kanıt: ana ekran widget testi `test/reorder_boundary_jitter_test.dart` (iki sütun sınırında ±6 px titreşim, 60 kare: kapı kapalıyken 60 yer değişimi = KIRMIZI, kapıyla ≤ 1 = YEŞİL) + birim `test/reorder_hover_gate_test.dart` (16 ms'de A/B titreşimi: 60 kare → ≤ 1 değişim; eski davranış 60). CİHAZ A/B BEKLİYOR (ana ekran listesi, ÖLÇÜM KAPISI) — elle: iki sütunda notu sınırda tut, zıplama yok; bilinçli taşıma hâlâ akıcı.

## P57 — Alt çubuk: her düğme eklenip çıkarılabilir, sıralanabilir

Model: opus · Cihaz: - · APK: evet

**Kullanıcı (2026-11-13, ekran görüntüsüyle):** "Alt paneldeki tüm butonları değiştirilebilmesi; kişi istediğini koyabilmeli, istediğini çıkarabilmeli; bunu da ayarlarda yapılabilen seçenekler geniş olsun."

**Durum:** bitti (bulut 2026-11-13). `core/personalize.dart`: `UiPrefs.barOrder` / `aiOrder` (boş = varsayılan; `UiPrefs.orderOf` yeni düğmeyi varsayılan yerine göre sona ekler, yinelenen/bilinmeyen kimliği atlar) + `UiItem.barLeftDefault`/`barRightDefault`; eklenebilir (varsayılan gizli, `optIn`) düğmeler: geri al, yinele, hatırlatıcı, fotoğraf, kamera, tara, renk, paylaş (eski `barShare` kimliği). Editör çubuğu kimlik → düğme haritasından kullanıcı sırasıyla dizilir; sığmazsa plan (`planEditorBar`) önce düğmeleri küçültür, sonra kapsül yatay kayar. Ayarlar → Kişiselleştir → "Not ekranı · alt çubuk": iki grup (araçlar / yapay zekâ ve ses), tutamaçla sürükle-sırala, anahtarla ekle/çıkar, "Alt çubuğu varsayılana döndür". Düzenleme modundaki dokunarak gizleme aynen sürer. Testler `test/editor_bar_customize_test.dart`. Kalan (P50'ye): düğmeyi iki kapsül arasında taşıma; üst çubuk için aynı liste.

