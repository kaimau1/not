# Plan — K32 (iki not yan yana) + K34 (kalem ucu tahmini + parmağa ayrı araç)

Yazıldı: 2026-11-14 (Fable karar evresi; KOD YAZILMADI). Uygulayan: iki AYRI Opus alt ajanı,
paralel, her biri önce `isci` skill'ini uygular. Bu dosya kendi başına okunur; satır numaraları
`0059c178` (main) içindir — kod ilerlediyse adı `Grep` ile bul.

Kaynak kararlar (kullanıcı, 2026-11-12; `docs/arsiv/planlar/OTURTMA_PLANI.md:253-264`):
- **K-O12:** "Tablet yatayda iki not yan yana OLSUN (ikinci not bölmesi; F67.6 yapılır)."
- **K-O4:** "Uç tahmini yazılır" — F62.6 (`OTURTMA_PLANI.md:812`): "son iki noktadan doğrusal 1
  karelik tahmin parçası (yalnız boyanır, çizgiye EKLENMEZ, sonraki olayda düzelir); cihaz
  tercihi `ink_predict`."
- **F63.6:** "Parmağa ayrı araç YAZILIR ve release'e girer; kapalı bırakılmaz." Biçim YORUM
  F55.1: "Parmak: kaydır / sil / çiz seçeneği, 'yalnız kalem'in yanında."
- Genel ilke (aynı yer): hiçbir özellik kapalı bayrakla bekletilmez; varsayılan AÇIK gelir,
  sürüm notuna girer, bayrak yalnız Ayarlar'da kapatma seçeneğidir.

## 0. Paket bölümü (dosya çakışmasız)

| | Paket A = K32 | Paket B = K34 |
|---|---|---|
| Dal | `oto/K32-iki-not` | `oto/K34-kalem-tahmin-parmak` |
| `lib/` | `app/second_note.dart` (YENİ), `app/split_shell.dart`, `app/router.dart`, `features/notes/presentation/editor/note_editor_screen.dart` + onun `part` dosyaları, `note_menu_model.dart`, `note_actions_sheet.dart` | `features/notes/presentation/viewers/ink_layer.dart`, `viewers/ink_tools.dart`, `editor/pen_tray.dart`, `editor/drawing_screen.dart`, `editor/stylus_toggle.dart`, `features/settings/presentation/settings_sections/settings_writing.dart` |
| `test/` | `second_note_test.dart` (YENİ), `split_layout_rules_test.dart`, `note_route_test.dart` | `ink_predict_test.dart` (YENİ), `ink_finger_tool_test.dart` (YENİ), `ink_stylus_tools_test.dart`, `pen_tray_controls_test.dart` |
| Bütçe senaryosu | **S27** — `perf_budget_test.dart`'ta S26'nın HEMEN ALTINA; `budgets.json`'da `"S26"`dan sonra | **S28** — S15'in HEMEN ALTINA; `budgets.json`'da `"S15"`ten sonra |
| ARB anahtarları | `listPaneMoveRight` anahtarının hemen altına | `inkPenOnlyInfo` anahtarının hemen altına |

Yasak geçişler: **B, `note_editor_screen.dart` ve `app/` altına DOKUNMAZ; A, `viewers/` ve
`pen_tray.dart`'a DOKUNMAZ.** Ortak dosyalar (`perf_budget_test.dart`, `budgets.json`,
`app_tr.arb`/`app_en.arb`, `lib/l10n/generated/*`) yukarıdaki AYRI yerlere yazılır → git
kendiliğinden birleştirir. İkinci birleşen paket birleştirmeden sonra `flutter gen-l10n` +
`dart format lib/l10n/generated` koşar. Sürüm notu (`assets/guide/release_notes_*.md`),
`docs/regresyon_listesi.md`, `KONTROL_LISTEM.md` aynı bölüme düşerse ikinci birleşen elle çözer
(yalnız satır ekleme). Her paket Kuyruk'ta YALNIZ kendi satırını günceller.

Her iki paket için ortak kapılar: değişen testler + `flutter analyze` → push → CI yeşil;
`kasma-kontrol` skill'i (8 madde) push'tan önce; `[apk]` öncesi `ab-olcum` (telefon A/B —
iki iş de editör/kalem yüzeyine dokunuyor; telefonda davranış DEĞİŞMEMELİ, kötüleşme sıfır).
Tablet kullanıcıda: tablet gerektiren doğrulama "yazıldı, tablette doğrulanmadı" +
`KONTROL_LISTEM.md` "Tablette bak"a madde.

---

## §K32 — İki not yan yana (tablet yatay)

### Bugünkü yapı (kanıt)

- Geniş düzen `SplitShell` (`lib/app/split_shell.dart:216`): `Row[ liste (TweenAnimationBuilder
  + ClipRect/Align/Offstage, :434-479) · _PaneDivider (:480) · Expanded(widget.child) (:526) ]`.
  `widget.child` = go_router'ın iç gezgini; açık not `/note/:id` sayfası
  (`lib/app/router.dart:169-191`). Liste TEK örnek, hep solda (HAFIZA kural 10; `arayuz.md`
  "Tek liste örneği").
- Geniş ekranda not notun YERİNE açılır, geri = liste (`router.dart:102-112`, tablet bulgusu
  2026-11-09: "geri dediğimde bir önceki not dönüyor, ana menüye en son dönüyor").
- Notun en dar hâli zaten 380 dp (`_minNoteDetailWidth`, `split_shell.dart:159`): editör bugün
  de "geniş pencere, 380 dp bölme" ile çalışıyor → yarım bölme yeni bir koşul DEĞİL.
- Liste gizleme/geri getirme düzeni var: `listAutoHidesFor` + `listPeekLocationProvider`
  (`split_shell.dart:28-59`), editörde ☰ (`note_editor_screen.dart:2472-2504`).
- Editör rotaya bağlı noktalar (`note_editor_screen.dart`): kendi kendini kapatma
  `context.pop()` :1431, :3125; `maybePop` :2699, :4999-5002; `PopScope` :4979-5014; sol yuva
  `_listLeading` :5067; `goHome` :5177; tam ekran `noteFullscreenProvider` :2462-2467, :4966-4973.
- Editör başına durum ayrık: `ValueKey('note-<id>')` (`router.dart:397-400`); açık notlar
  `openEditorNoteIds` (küme) ve `openNoteIdsProvider` (yığın, `notes_providers.dart:655`) zaten
  ÇOĞUL. Kalem aracı tek ve ortak (`InkToolMemory`, `ink_tools.dart:249-266`;
  `InkController.active` son dokunulan yüzey, `ink_layer.dart:64,1102`) → iki editörde tek araç
  durumu kendiliğinden doğru.
- Bütçeler: S12/S12b/S26 (1280×800 bölünmüş; `test/perf_budget_test.dart:659,736,783`).

### Mimari kararlar

1. **İkinci not URL'de DEĞİL, `SplitShell`'in üçüncü sütunu.** `Row[ liste · ayraç · birincil
   (iç gezgin, bugünkü) · ayraç2 · ikinci not ]`. İkinci bölme iç içe `Navigator` KURMAZ:
   `NoteEditorScreen` doğrudan gömülür (alt sayfaları — PDF görüntüleyici, çizim ekranı —
   bugünkü gibi kabuğun gezginine, tüm içerik alanına açılır). Gerekçe: go_router'da ikinci
   kabuk sayfası siyah ekran kök nedeniydi (`router.dart:65-76`); derin bağlantı/geri/web
   geçmişi yolu DEĞİŞMEZ.
2. **Durum:** `secondNoteProvider` (bellekte; `id`, `ownerId`, `readOnly`). Kalıcı değil
   (uygulama yeniden açılınca yok) — en güvenli; *sabah bakılacak*.
3. **Ne zaman:** birincil not açık + `splitActiveFor` + pencere YATAY (`width > height`) +
   içerik genişliği (LayoutBuilder `box.maxWidth`) ≥ 2×380 + 24 = **784 dp**. Koşul düşerse
   (dikeye dönme, pencere daralma) bölme kurulmaz (editör `dispose`ta kaydeder), sağlayıcı
   durur; koşul dönünce yeniden kurulur. Dikey tablette yok (K-O12 "yatayda") — *sabah bakılacak*.
4. **Liste:** iki not açıkken liste, üçü sığmıyorsa (içerik < liste + 24 + 380 + 24 + 380)
   kendiliğinden çekilir — var olan `listAutoHides` + ☰ "göz atma" düzeni. ☰ ile liste
   açılınca ikinci bölme GİZLENİR (Offstage, State korunur), liste + birincil görünür; karta
   dokunmak birincili değiştirir (bugünkü `pushReplacement`), liste yine çekilir, ikinci geri
   gelir. Üçü sığıyorsa (web/geniş) liste yerinde kalır. Saf işlev:
   ```dart
   enum TwoNoteLayout { off, twoOnly, listAndTwo }
   TwoNoteLayout twoNoteLayoutFor({required double content, required double list,
       required bool landscape, required bool secondOpen});
   ```
5. **Geri tuşu:** bugünkü zincir aynen (birincilin `PopScope`u) → birincil kapanır → **ikinci
   bölme de kapanır, liste tam genişlik** ("geri = liste" 2026-11-09 kuralı). İkinci editörün
   `PopScope`u hiçbir şeyi ENGELLEMEZ (`canPop: true`). İkinci bölmenin kendi kapatması: üst
   çubuğunun sol yuvasında ✕. *Sabah bakılacak* (istersen "geri önce yandakini kapatsın").
6. **Aynı not iki bölmede OLMAZ** (iki editör aynı belgeye yazar → `text_merge` yankı
   çakışması). "Yanda aç" birincil not için gösterilmez; birincil, ikinci bölmedeki nota
   geçerse ikinci bölme ÖNCE kapanır (kaydı biter), sonra birincil açılır.
7. **Tam ekran** (`noteFullscreenProvider`, kullanıcı isteği 2026-11-02 — korunur): birincil
   tam ekran olunca ikinci bölme liste gibi gizlenir (Offstage); tam ekrandan çıkınca döner.
   İkinci editörde tam ekran düğmesi, ☰ ve "ana ekran" düğmesi YOK.
8. **Giriş kapısı tek:** kart menüsünde "Yanda aç" (`noteMenuModel`, yüzey `card`; yalnız
   karar 3 koşulu sağlanıyorken). Sürükle-bırak, kısayol YOK (YAGNI) — *sabah bakılacak*.
9. **Kasma:** bölme genişliği TEK ADIMDA değişir (animasyon yok — kasma listesi 6); Row'un
   çocuk sayısı ve sırası sabit (ikinci bölme yokken de yerinde `SizedBox.shrink` / Offstage
   sarması — madde 4); ayraç sürüklemesi yerel `setState`, kalıcı kayıt bırakınca
   (`split_shell.dart:271-277` kalıbı).

`istek_tara.py` taraması (split_shell, window_class, router, note_menu_model,
note_actions_sheet, note_editor_screen): korunacak istekler — odak modu (`split_shell:176`),
not tam ekran (:185), çekerek tam ekran (:282), dönüş geçişi (:227, P59 `_closing`), "not
açılınca liste solda tek sütun, menü gizli" (`window_class:90`), ☰ "tam ekrandan çıkmak çok
zor" (`note_editor_screen:5065`), biçim paneli geri sırası (:5007). Planın hiçbir adımı
bunları tersine çevirmiyor; ikinci bölme yalnız kullanıcı "Yanda aç" deyince çıkar.

### Adımlar (sırayla; her adım AYRI commit + push)

**A0 — Kanıt: kırmızı testler + geri sırası gerçeği.**
- Dosya: `test/second_note_test.dart` (YENİ). Kabuk pompalama kalıbı
  `test/fullscreen_pull_test.dart` ve `perf_budget_test.dart` `_pumpHome`'dan alınır.
- Yaz (hepsi önce KIRMIZI): (a) `twoNoteLayoutFor` tablosu — 1024×640 yatay + liste 320 →
  `twoOnly`; içerik 1280 → `listAndTwo`; 640×1024 dikey → `off`; içerik 780 → `off`.
  (b) 1024×640, `/note/a` açık, ikinci = `b` → iki `NoteEditorScreen`, bir `DashboardScreen`
  (Offstage). (c) sistem geri → konum `/`, editör 0, `secondNoteProvider == null`.
  (d) ikinci bölmede ✕ → yalnız `b` kapanır, `a` State'i aynı (`identical` State).
  (e) birincil `b`'ye geçerse ikinci kapanır, tek editör `b`.
- Ayrıca bugünkü hâlde ÖLÇ ve DEVIR'e yaz: bölünmüş düzende sistem geri önce iç gezgine mi
  gidiyor (`note_editor_screen.dart:4960-4965` yorumu iç gezginin "tek sayfa" olabildiğini
  söylüyor). Karar 5 bu sıraya BAĞLI DEĞİL (ikinci `canPop: true`), ama test (c) gerçeği kilitler.
- Kabul: testler derleniyor ve beklenen yerden kırmızı.

**A1 — Saf kurallar + durum.**
- Dosya: `lib/app/second_note.dart` (YENİ): `SecondNote` (id, ownerId, readOnly),
  `secondNoteProvider` (`open(SecondNote)`, `close()`), `twoNoteLayoutFor`, sabit
  `kSecondNoteMinWidth = 380`, `secondNoteFractionProvider` (pref `second_note_fraction`,
  varsayılan 0.5, 0.3–0.7'ye kırp), `SecondNotePane` InheritedWidget (`close` geri çağrısı;
  `maybeOf`).
- Test: A0 (a) yeşil. Kabul: `dart analyze lib/app/second_note.dart` temiz.

**A2 — Editör: tek kapanış hunisi + "ikinci bölme" kipi.**
- Dosya: `note_editor_screen.dart` ve `part` dosyaları (`note_editor_actions.dart`,
  `note_editor_flow.dart`…). Önce `Grep` ile editörün KENDİNİ kapattığı her yeri listele
  (`context.pop()`, `context.canPop()`, `Navigator.of(context).maybePop()`, `goHome(` — levha
  kapatan `Navigator.pop`lar HARİÇ) ve DEVIR'e yaz.
- Yap: tek yöntem `_closeEditor()` → `SecondNotePane.maybeOf(context)?.close()` varsa onu,
  yoksa bugünkü `context.pop()` yolunu çağırır; listelenen her yer buna bağlanır (kök neden:
  ikinci bölmede `context.pop()` BİRİNCİL notu kapatır). `bool get _secondary`:
  `PopScope.canPop` → `_secondary || <bugünkü koşul>`; `_listLeading` → ikincide ✕ düğmesi
  (`ValueKey('second-note-close')`, tooltip `noteCloseSide`); tam ekran düğmesi/kısayolu,
  ☰ ve `goHome` düğmesi ikincide çizilmez. Ağaç şekli sabit kalsın (koşulda `SizedBox.shrink`).
- Test: A0 (d); `test/home_editor_guards_test.dart`, `editor_leak_test.dart`,
  `back_closes_test.dart` yeşil kalır (telefon yolu değişmedi).
- Kasma: 3 (kök `setState` ekleme), 4 (şekil sabit). Kabul: telefon/tek not davranışı birebir.

**A3 — `SplitShell`: üçüncü sütun.**
- Dosya: `lib/app/split_shell.dart`. `Expanded(Stack[widget.child, ipucu])`ın SAĞINA (liste
  sağdaysa Row zaten ters dizilir, `:403-408`) HEP var olan iki çocuk: `ayraç2` ve ikinci
  bölme. İkinci bölme: `SizedBox(width: w2)` → `Offstage(offstage: !visible)` →
  `SecondNotePane(close: …, child: NoteEditorScreen(key: ValueKey('note-<id>'), …))`; ikinci
  yokken `w2 = 0` ve çocuk `SizedBox.shrink`. `w2 = (not alanı − 24) × oran`, iki yan ≥ 380.
  Genişlik animasyonsuz. `visible` = karar 3 ∧ ¬tam ekran ∧ ¬(liste göz atmada ∧ `twoOnly`).
- Liste: `twoOnly` iken `autoHides` doğru sayılır (`:351-360` hesabına `||` ile) — ☰/göz atma
  bugünkü kodla çalışır. `SplitScope`a yeni alan EKLEME (gereksizse); gerekiyorsa
  `updateShouldNotify`a da ekle.
- Kapanış: rota not olmaktan çıkınca (`:305-316`) `_closing` süresi bitince
  `secondNoteProvider.close()` — bölme 300 ms birincille birlikte durur, sonra TEK ADIMDA gider
  (P59 kuralı, bütçe S26).
- Ayraç2: `_PaneDivider` yeniden kullanılır (`onMoveSide`/`moveSideLabel` isteğe bağlı yapılır;
  çift tık = 0.5). Sürükleme yerel `setState`, bırakınca pref.
- Test: A0 (b)(c); `fullscreen_pull_test.dart`, `split_layout_rules_test.dart`, bütçe S12,
  S12b, S26 yeşil (ikinci not YOKKEN sayılar değişmemeli — şekil sabit kanıtı).
- Kasma: 4, 6, 7 (`MediaQuery.of` kök bağlamda okunmaz). **Tablette doğrulanır.**

**A4 — Giriş: "Yanda aç" + aynı-not kuralı.**
- Dosya: `note_menu_model.dart` (yeni `bool canOpenSide = false`; yüzey `card`, `menuSectionOrganize`
  bölümünün başına `MenuAction('side', l10n.noteOpenSide, Icons.vertical_split_outlined)`),
  `note_actions_sheet.dart` (`_runNoteAction` → `secondNoteProvider.open`; `canOpenSide` =
  karar 3 koşulu ∧ not ≠ birincil ∧ paylaşılan notta `ownerId`/`readOnly` taşınır),
  `lib/app/router.dart` (`NoteContextPush.pushNote` + `NoteRoutePush.pushNote`: hedef not
  ikinci bölmedeyse önce `close()`), ARB: `noteOpenSide` "Yanda aç" / "Open side by side",
  `noteCloseSide` "Yandaki notu kapat" / "Close side note".
- Test: A0 (e); `test/note_route_test.dart`'a aynı-not durumu; menü modeli testi (telefon
  boyutunda `side` YOK).
- Kabul: telefonda ve dikey tablette menüde yeni satır görünmez.

**A5 — Bütçe S27 + yankı yalıtımı.**
- Dosya: `test/perf_budget_test.dart` (S26'nın altına), `test/perf_budget/budgets.json`.
- Senaryo **S27: 1280×800, iki not açık — birincile 20 karakter + kayıt.** Ölç: ikinci
  `NoteEditorScreen` kök kurulumu, `DashboardScreen` kurulumu, `NoteCard`. Hedef: ikinci kök
  **0**, pano S12 ile aynı. Önce ölç (DEVIR'e ham sayı); 0 değilse kök nedeni bul (beklenen
  aday: `notesStreamProvider` yankısı — editör kendi notu değişmediyse kurulmamalı; S11 kalıbı),
  düzelt, mandalı ölçülen değere koy (yalnız düşer).
- Ayrıca S8 kalıbıyla klavye aç/kapa: iki bölmede inset karesi başına kök kurulum bugünkü tek
  not değerinin 2 katını aşmaz.
- Kasma: 8. Kabul: `flutter test test/perf_budget_test.dart --reporter failures-only` yeşil.

**A6 — Kenar durumlar (her biri test ya da "üretilemedi" notu).**
- İkinci bölmedeki not başka yerden silinirse (`note_editor_screen.dart:1417-1433` dalı)
  `_closeEditor()` yalnız bölmeyi kapatır, birincil durur.
- Tek mikrofon: birincilde ses kaydı/dikte sürerken ikincide başlatma → var olan korumayı
  bul (`DeviceSpeech`, ses kaydedici); yoksa ikinci başlatma reddedilir (bildirim). İkinci
  bölme `start*` niyetleriyle AÇILMAZ.
- Klavye: odak hangi bölmedeyse o yazar; öbür bölme boyunu TEK adımda verir (`KeyboardSnap`).
- Görsel tur: `tool/tour/screen_tour_test.dart`'a `matepad-yatay` iki notlu kare; taşma yok.
- `openNoteIdsProvider` yığınında listede yalnız SON açılan kart vurgulu kalır (bugünkü
  `ids.last` kuralı, `dashboard_slivers.dart:618`) — dokunma; *sabah bakılacak*.

**A7 — Kapanış.** `isci` "Bitiş": Kuyruk K32 satırı, `PLAN.md` (C) maddesi, `KONTROL_LISTEM.md`
32 → "Tablette bak"a doğrulama maddeleri (aşağıda), `docs/hafiza/arayuz.md` (karar 1, 5, 6 +
"ikinci bölmede `context.pop()` birincili kapatır" tuzağı), `docs/regresyon_listesi.md`, sürüm
notu ("Tablette yatayda iki notu yan yana açabilirsin: kartın menüsünden 'Yanda aç'"). Telefon
A/B (`ab-olcum`): editör ve liste yüzeyi — fark beklenmez; > %20 = birleştirme yok.

### Tablette (kullanıcı) doğrulanacaklar — K32
A3 (düzen, ayraç, döndürme, ☰ göz atma), A4 (menü), A6 (klavye iki bölme, kalemle iki notta
yazma), tam ekran giriş/çıkış, geri tuşu. Yapılamazsa "tablette doğrulanmadı".

### Riskler — K32
- **Editör 5600 satır ve rotaya bağlı**: kaçan bir `context.pop()` ikinci bölmeden birincili
  kapatır → A2'deki liste + A0 (d) testi tek güvence; yeni kapanış yolu ekleyen `_closeEditor`
  kullanır (hafızaya yazılır).
- Aynı belgeye iki editör (karar 6 delinirse) veri kaybı riski → A0 (e) + A4 testi zorunlu.
- İkinci bölmenin `PopScope`u kabuk sayfasına kayıt olur; `canPop: false` kalırsa uygulamadan
  çıkış/geri kilitlenir → `_secondary` iken hep `true`.
- Genel sağlayıcılar tekil (`noteFullscreenProvider`, `listPeekLocationProvider`,
  `noteRouteClosing`): ikinci editör bunları YAZMAZ (A2).
- 1024 dp'de iki bölme ~500 dp: sabit ekin yan yerleşimi (`kPinnedSideMinWidth` 560) kapanır,
  üstte açılır — beklenen; turda bak.

---

## §K34 — Kalem ucu tahmini + parmağa ayrı araç

### Bugünkü yapı (kanıt)

- Girdi yolu: `InkPageLayer` `Listener` → `InkController.pointerDown/Move/Up/Cancel`
  (`ink_layer.dart:1940-1963` → `:1069`, `:1318`, `:1536`, `:1520`). Serbest çizimde nokta
  ekleme `:1431-1455` (0.002'den yakın nokta atlanır, `:1433-1439`).
- Boyama iki katman (F62.1): `CommittedInkPainter` yalnız `committedRev` ile (`:2280`),
  `ActiveInkPainter` her bildirimde etkin çizgiyi `paintInkStroke(…, cache: false)` ile
  (`:2302-2315`). Tek çizim yolu `ink_stroke_paint.dart:21` (çizgi başına 1 çizim çağrısı).
  Bütçe **S15 = 1 çizim çağrısı** (`budgets.json:121`, mandal yalnız düşer).
- Parmak bugün iki hâlli: "yalnız kalem" (`InkToolMemory.penOnly`, `ink_tools.dart:235`,
  kullanıcı isteği 2026-10-23, `ink_layer.dart:366`) → parmak çizmez, tek parmak kaydırır
  (`InkNavLayer`, `:2728-2757`); kapalıyken parmak kalemin aracıyla çizer. Süzgeç
  `accepts` (`:1047`), yüzey kuralı `PenPolicy` (`pen_policy.dart:59-113`, `penOnly`den okur).
- Geçici silgi ZATEN var: kalemin yan düğmesi/ters ucu `_tempEraser` (`:689-692`, `:1127`,
  girdi `:1949-1951`).
- Avuç güvenliği var: `isPalm` (kalem ekranda/400 ms içinde → parmak yok sayılır, `:660`),
  `_dropPalms` (kalem inince parmağın başlattığı her şey `_gestureBase`e geri alınır,
  `:1499-1516`), `pointerCancel` (Android avuç iptali → geri al, `:1520-1534`).
- `penOnly` arayüzü: `InkSettingsSheet` anahtarı (`ink_layer.dart:2546-2553`), tepsi menüsü ve
  ray düğmesi (`pen_tray.dart:729-746`, `:870-892`), çizim ekranı menüsü
  (`drawing_screen.dart:239-251`), Ayarlar → Kalem (`settings_writing.dart:32-38`), "parmak da
  yazıyor" hapı (`stylus_toggle.dart:92`, kullanıcı isteği 2026-11-13).
- F55.1 neden ertelenmişti (`docs/hafiza/kalem.md:40`): "parmak silgi avuç içiyle çizgi siler,
  tek parmak kaydırmayla çakışır". Karar 2026-11-12 ile aşıldı; riskler aşağıda kapatılıyor.

### Mimari kararlar

**Uç tahmini**
1. Flutter Android'in "predicted points"ini vermez → F62.6'daki gibi **doğrusal, 1 karelik**
   tahmin: son iki HAM olaydan hız, `uç = son + hız × ufuk`. Ufuk sabiti
   `kInkPredictHorizon = 16 ms` (kalibrasyon düğmesi; tablette 240 fps ölçümüyle ayarlanır).
   Sınır: tahmin boyu ≤ min(2 × son adım, sayfa genişliğinin %3'ü); olay aralığı ≤ 0 ya da
   > 50 ms ise tahmin yok. Saf işlev `inkPredictTip(...)` (`ink_tools.dart`).
2. **Yalnız boyanır, çizgiye girmez:** denetleyici `Offset? predictedTip` tutar;
   `ActiveInkPainter.paint` etkin çizginin `points` (ve varsa `pressures`) listesine tahmin
   noktasını EKLER, `paintInkStroke` çağırır, `finally` içinde GERİ ÇIKARIR. Böylece tek
   `Path`, tek çizim çağrısı (S15 = 1 korunur; fosforluda çift saydamlık bindirmesi olmaz),
   `ink_stroke_paint.dart`'a dokunulmaz. Kayda/geri al'a/RDP sadeleştirmeye tahmin sızmaz.
3. Tahmin yalnız serbest çizimde (ok, şekil, kement, silgi, oturmuş çizgi `_snapped` → yok).
   `pointerDown/Up/Cancel`, `beginNav`, `_dropPalms`, `_snapActive`'te `null`. Zamanlayıcı YOK
   (test tuzağı): kalem durunca gelen küçük olaylar tahmini kendiliğinden sıfıra indirir;
   0.002 ölü bölgesine düşen olayda tahmin `null` + bildirim.
4. Tercih `InkToolMemory.predict` (pref `ink_predict`, **varsayılan AÇIK** — genel ilke);
   kapatma yeri `InkSettingsSheet` + Ayarlar → Kalem. *Sabah bakılacak.*

**Parmağa ayrı araç**
5. Üç seçenek: **Kaydırır** (= bugünkü "yalnız kalem"), **Çizer** (= bugünkü kapalı hâl,
   kalemin aracıyla), **Siler** (YENİ). Depolama geriye uyumlu: `ink_pen_only` aynen + yeni
   `ink_finger_eraser` (bool). `enum FingerTool { scroll, draw, erase }` yalnız TÜRETİLMİŞ
   görünüm (`InkToolMemory.fingerTool` get; `InkController.setFingerTool`). `penOnly` okuyan
   dosyalar ve `PenPolicy` DEĞİŞMEZ ("Siler" = `penOnly == false` → parmak katmana gider).
   Kement/fosforlu gibi başka araç atama YOK — *sabah bakılacak*.
6. "Siler" = parmak için `_tempEraser` (var olan yan düğme yolu): `pointerDown`'da seçim
   tutamağı/taşıma dalından (`:1129-1160`) SONRA, kement dalından (`:1165`) ÖNCE
   `kind == touch && fingerErases && !penOnly` ise `_tempEraser = true`. Parmak seçimi yine
   taşıyabilir; kalem aracı (kement dahil) kalemde kalır. Kısmi silgi ayarı aynen geçerli.
7. Avuç/çakışma güvenliği: (a) `isPalm`, `_dropPalms`, `pointerCancel` aynen çalışır (silinen
   çizgiler `_gestureBase`ten döner — testle kilitle); (b) İKİNCİ parmak inince (yakınlaştırma
   niyeti: `:1110-1121` ve `beginNav` `:1026`) parmak-silgi jesti `_gestureBase`e GERİ ALINIR
   (bugün yalnız `_active` siliniyor); (c) geniş temas avuçtur: `PointerEvent.radiusMajor` >
   `kFingerEraserPalmRadius` (22 dp, kalibrasyon düğmesi; 0 = cihaz bildirmiyor → süzme) ise
   dokunuş silmez; (d) her silme tek "geri al" adımı (var olan geçmiş).
8. Silgi kipinde tek parmak kaydırmaz (Çizer'deki gibi iki parmak) — F55.1'in "kaydırmayla
   çakışır" itirazının çözümü: kaydırmak isteyen "Kaydırır"ı seçer. *Sabah bakılacak.*
9. Arayüz: yeni DÜĞME YOK (tepsi tek satır, `pen_tray:357` isteği). `InkSettingsSheet` ve
   Ayarlar → Kalem'de "yalnız kalem" anahtarının YERİNE üçlü `SegmentedButton` ("Parmak:
   Kaydırır · Çizer · Siler"; `VisualDensity.compact` VERME — 48 dp kuralı, `arayuz.md`
   tuzağı). Var olan hızlı aç/kapa'lar (tepsi, çizim menüsü) Kaydırır ↔ son seçilen öbür hâl
   arasında gider; etiket/ipucu "Siler"de `inkFingerEraseOn`. `stylus_toggle` hapı "Siler"de
   "parmak siliyor" der (hap kaldırılmaz — 2026-11-13 isteği).

`istek_tara.py` taraması (ink_layer, pen_tray, settings_writing, drawing_screen,
stylus_toggle): "yalnız kalem" (2026-10-23) = Kaydırır olarak aynen; "bas-tut = silgi önerisi"
(2026-11-08, `ink_layer:106`) Çizer'de aynen; tepsi tek satır/kapsül (2026-11-02/07/08) —
tepsiye düğme eklenmiyor; "her ayar Ayarlar'da da olsun" (2026-11-10, `settings_writing:3`) —
iki yeni ayar oraya da; "parmak yazıyor" hapı (2026-11-13) korunur. Çelişen madde yok.

### Adımlar (sırayla; her adım AYRI commit + push)

**B0 — Kanıt: kırmızı testler (+ varsa taban gecikme ölçümü).**
- Dosya: `test/ink_predict_test.dart`, `test/ink_finger_tool_test.dart` (YENİ; kalıp
  `test/ink_stylus_tools_test.dart`, `InkToolMemory.reset()`).
- Tahmin (kırmızı): sabit hızla 3 hareket → `predictedTip` son noktanın ilerisinde, boyu
  sınırın içinde; 60 ms aralıklı olay → `null`; `pointerUp` sonrası `null` ve kaydedilen
  çizginin `points` uzunluğu tahminsiz hâlle AYNI; `ActiveInkPainter.paint` öncesi/sonrası
  `points.length` eşit; şekil/ok/silgi/kementte `null`; `predict = false` → hep `null`.
- Parmak (kırmızı): Siler'de parmak çizgiyi siler, kalem çizer; kalem ekrandayken parmak
  silmez; parmak sildikten sonra kalem inince çizgi geri gelir (`_dropPalms`); ikinci parmak
  inince silinen geri gelir; `pointerCancel` geri getirir; seçim tutamağını parmak hâlâ taşır;
  Kaydırır'da parmak ne çizer ne siler; eski pref (`ink_pen_only` true/false, yeni anahtar
  yok) → Kaydırır/Çizer.
- Tablet eldeyse F62.6 taban ölçümü (240 fps ağır çekim: uç–çizgi mesafesi / hız = ms) DEVIR'e;
  yoksa "ölçülemedi: tablet kullanıcıda" yaz, devam et (karar verilmiş, ölçüm kapısı değil).

**B1 — Tahmin: model.**
- Dosya: `viewers/ink_tools.dart` (`inkPredictTip`, `kInkPredictHorizon`, `predict` +
  `_kPredict` pref, `attach`/`reset`/`savePredict`), `viewers/ink_layer.dart`
  (`pointerMove`'a isteğe bağlı `Duration? timeStamp`; `_rawLast/_rawAt/_predict`;
  `predictedTip` get; karar 3'teki sıfırlama yerleri; `InkPageLayer` `onPointerMove` →
  `timeStamp: e.timeStamp`).
- Test: B0 tahmin testleri (boyama hariç) yeşil. `pointerMove`'un başka çağıranları
  (`Grep "\.pointerMove("`) derlenmeye devam eder (parametre isteğe bağlı).

**B2 — Tahmin: boyama + bütçe S28.**
- Dosya: `viewers/ink_layer.dart` (`ActiveInkPainter.paint` — karar 2, `try/finally`),
  `test/perf_budget_test.dart` (S15'in altına), `budgets.json`.
- **S28: 2000 çizgi, tahmin AÇIK, etkin çizgiye 1 nokta** → çizim çağrısı **1**; boyama
  sonrası `points.length` değişmedi. S15 (tahminsiz yol) 1 kalır.
- Kasma: 8; yeni widget/sarmalayıcı yok. Kabul: iki senaryo yeşil.

**B3 — Tahmin: ayar.**
- Dosya: `ink_layer.dart` `InkSettingsSheet` (basınç anahtarının altına `SwitchListTile`,
  `ValueKey('ink-predict')`), `settings_writing.dart` (aynı ayar + arama anahtar sözcükleri),
  ARB: `inkPredictTitle` "Kalem ucu tahmini" / "Pen tip prediction", `inkPredictInfo` "Çizgi
  kalemin ucuna daha yakın görünür. Garip gelirse kapat." (EN karşılığı).
- Test: `pen_tray_controls_test.dart` kalıbıyla anahtar aç/kapa → `InkToolMemory.predict`.

**B4 — Parmak aracı: model.**
- Dosya: `ink_tools.dart` (`fingerErases` + `_kFingerEraser`, `FingerTool`, `fingerTool` get,
  `saveFingerTool`), `ink_layer.dart` (`setFingerTool`; `pointerDown` — karar 6; ikinci parmak
  ve `beginNav` geri alma — karar 7b; `pointerDown`'a isteğe bağlı `double? touchRadius`,
  `InkPageLayer` → `e.radiusMajor`; `kFingerEraserPalmRadius`).
- Test: B0 parmak testleri yeşil; `ink_stylus_tools_test.dart`, `pen_policy_test.dart`,
  `ink_eraser_fix_test.dart`, `ink_eraser_offer_test.dart` yeşil kalır.

**B5 — Parmak aracı: arayüz.**
- Dosya: `ink_layer.dart` (`InkSettingsSheet` :2546 anahtarı → üçlü seçim,
  `ValueKey('ink-finger-tool')`), `settings_writing.dart` (:32-38 → üçlü seçim),
  `pen_tray.dart` (:745-746, :870-892 etiket/ipucu/simge "Siler" hâli), `drawing_screen.dart`
  (:249-251 etiket), `stylus_toggle.dart` (hap metni), ARB: `inkFingerToolTitle` "Parmak",
  `inkFingerScroll` "Kaydırır", `inkFingerDraw` "Çizer", `inkFingerErase` "Siler",
  `inkFingerEraseOn` "Parmak siler", `inkFingerErasingPill` "Parmak siliyor" (EN karşılıkları).
- Test: `pen_tray_controls_test.dart`, `stylus_toggle_hints_test.dart`, `accessibility_test.dart`
  (48 dp), `arb_case_test.dart`.
- Kasma: 3 (yerel durum `toolRev` ile, kök `setState` yok), 4.
- Bilinen boşluk (B'nin dosya çiti): editördeki "kalem kipi açıldı" ipucu
  (`note_editor_screen.dart:2400-2422`) "Siler"i söylemez — iki paket birleşince tek satırlık
  iş; Kuyruk sonucuna "sabah bakılacak" olarak yaz.

**B6 — Kapanış.** `isci` "Bitiş": Kuyruk K34, `PLAN.md` (C) iki madde, `KONTROL_LISTEM.md` 34
→ "Tablette bak" maddeleri, `docs/hafiza/kalem.md` (karar 2 "tahmin boyamada ekle-çıkar",
karar 6-7; `:40`'taki "bilerek yapılmadı: F55.1" satırı GÜNCELLENİR), regresyon listesi, sürüm
notu ("Kalem çizgisi ucu daha yakından izler (Ayarlar'dan kapatılabilir)"; "Parmağa ayrı iş
verebilirsin: kaydırır, çizer ya da siler"). Telefon A/B: `tool/perf/ab_kalem.py` (dolu/boş
sayfa UI+raster ms; F62 kabulü ≤ %20) + `ab_hepsi.py --altin`.

### Tablette (kullanıcı, gerçek kalem) doğrulanacaklar — K34
- B2/B3: tahmin açık/kapalı his karşılaştırması; hızlı dönüşlerde uç taşması var mı; 240 fps
  ile gecikme (hedef ≤ 2 kare / 33 ms) → `kInkPredictHorizon` ayarı.
- B4: kalemle yazarken avuç SİLMİYOR mu (asıl risk); `radiusMajor` tablette dolu mu, parmak
  ucu / avuç değerleri → `kFingerEraserPalmRadius`; iki parmak yakınlaştırırken silinme yok.
- B5: üçlü seçim, hap metni, tepsi düğmesi.
Telefonda (parmak) yapılabilen: Siler kipinde silme, iki parmak geri alma, A/B.

### Riskler — K34
- **Avuçla silme** (F55.1'in erteleme nedeni): kalemden > 400 ms önce inen ve Android'in iptal
  etmediği avuç siler; kalem inince `_dropPalms` geri getirir, kalem hiç inmezse "geri al"
  kalır. Yarıçap süzgeci cihaza bağlı → tablette doğrulanmadan "güvenli" DENMEZ.
- Tahmin taşması: keskin dönüş/ani duruşta uç bir kare ileri gider, sonraki olayda düzelir
  (tasarım gereği); sınır (karar 1) bunu ≤ 2 adımla tutar. Beğenilmezse ayardan kapalı.
- Boyamada ekle-çıkar hilesi: `paint` içinde istisna olursa nokta kalırdı → `try/finally` +
  S28 uzunluk iddiası. Etkin çizgi listesi başka yerde boyama SIRASINDA okunmaz (senkron).
- `timeStamp` vermeyen çağıran (test, eski yol) → tahmin yok, davranış bugünkü.
- `penOnly` kendiliğinden açılması (`:1089-1093`, ilk kalem dokunuşu, seçilmemişse) "Siler"i
  ezmez: üçlü seçim `chosen: true` yazar — testle kilitle.

---

## Sabah bakılacaklar (yeni kararlar — en güvenli seçenek uygulandı/planlandı)

K32: (1) geri tuşu iki notu birden kapatıp listeye döner; (2) yalnız yatay ve içerik ≥ 784 dp
(dikey tablette yok); (3) tek giriş kart menüsünde "Yanda aç"; (4) ikinci not hatırlanmaz;
(5) listede yalnız son açılan kart vurgulu; (6) tam ekranda ve ☰ göz atmada yandaki not gizlenir.

K34: (1) tahmin varsayılan AÇIK, ufuk 16 ms; (2) parmak araçları yalnız Kaydırır/Çizer/Siler;
(3) avuç yarıçap eşiği 22 dp tahminî, tablette ayarlanacak; (4) Siler'de tek parmak kaydırmaz;
(5) editör ipucu metni "Siler"i söylemiyor (paketler birleşince); (6) PLAN.md K34'ü "fable"
diyordu, bu plan Opus'a göre yazıldı.
