# Hafıza — Editör, klavye, metin

HAFIZA.md'den cümle değiştirilmeden taşındı (F58.2, 2026-11-10). Tam eski hâl: `HAFIZA_ARSIV_3.md`.

## Editör, klavye, metin
- **KASMA REGRESYONU 2026-11-10 (A/B ölçüldü, tablette telefon düzeni):** 11-06 tabanı → 11-09: yazarken UI işi ×3,3 (62→327 kare), klavye aç/kapa +%65, not kapanışı aynı. KÖK 1: "yazarken alt çubuk gizlenir" (`TypingBarHide`, 11-08) çubuğun BOYUNU 420/320 ms kare kare değiştiriyordu — çubuk gövdeyle aynı Column'da → bütün gövde her karede yeniden dizildi; `AnimatedSize` içinde olduğu için tek adımlık değişim de animasyona dönüyordu; `t == 1` dalı ağaç şeklini değiştirip çubuğu her seferinde sıfırdan kuruyordu. Düzeltme: boy tek adımda (gizleme bitince / gösterme başlarken), hareket `FractionalTranslation`+`Opacity`, `TypingBarHide` `AnimatedSize`'ın DIŞINDA. KÖK 2: `KeyboardSwitch` her açılışta hızlı satırı kurup söküyordu → iki taraf `Offstage` ile kurulu kalır (hızlı satır ilk açılışta bir kez). KÖK 3: `fixedTypography` `MediaQuery.of`'u MaterialApp.builder bağlamında okuyordu → klavyenin her karesinde AppLockGate…AppServices zinciri yeniden kuruluyordu → ayrı `_FixedTypography` öğesi. SONUÇ (aynı cihaz): klavye kapa ×3 UI 218→143 ms (taban 132), aç ×3 325→182 (taban 193), yazma 677→534 ms (taban 203 — fark, kullanıcının istediği yumuşak çubuk animasyonunun kareleri, kare başı ~1,6 ms; boyama −%65, yerleşim −%29), kaydırma tabanla aynı. Dikey tablet: gizli liste dar/tek sütun tutulduğu için not kapanışında 108 ms kare (LAYOUT 85) → gizliyken tam genişlikte bekler (`listNarrow`, split_shell) → 31–47 ms; kalan, kapanıştaki kayıt sonrası dashboard'un 200 notluk ızgarayı (`sliverBalancedNoteColumns`, `dateBuckets`) yeniden hesaplaması — tabanda da var, iyileştirme adayı. Telefonda not kapanışı tabanla aynı (regresyon yok). Kapı ve kurallar CLAUDE.md "Kasma kontrol listesi" 6–7 + ÖLÇÜM KAPISI; araç `tool/perf/ab_klavye.py`.
- Alt çubuk klavye ALTINDA: `KeyboardSnap/KeyboardSlide`, hareket ile
  yerleşim ayrık. Çubuk düğmesi odak çalmasın: `Focus(canRequestFocus:
  false)` + `TextFieldTapRegion`.
- Düzenlenebilir span'e `TapGestureRecognizer` çalışmaz → dokunuş `onTap`'te
  imleçten + `TapPointTracker` konumundan çözülür (etiket, bağlantı, video
  damgası, not bağlantısı). Okurken açar, yazarken "Aç" önerir.
- Geri alma notun tamamını saklar. Editör `part` dosyalarına bölünmüş
  (`extension _EditorX on _NoteEditorScreenState`): uzantıda `_update`,
  statik `_NoteEditorScreenState._x`, YENİ ALAN sınıfa. Dashboard ve
  ItemsEditor de aynı desen.
- Yeni GÖRÜNÜR not alanı → `sameRenderedNote` VE `_sameVisual`.
- Üst çubuk sade (2026-11-05): palet ⋮ menüsünde; geri al/yinele yalnız
  `_canUndo || _canRedo` iken; tarih kısa (`editorBarDate`: bugün saat).
- **Başlık üst çubukta** (2026-11-03) medya sabitken ya da balonlu belgede
  (`_titleInBar`; tarih yerine, 18 pt, meta çip tek simge; sabitle/tema
  gizli, yinele yalnız doluyken); balonluda görünüm
  anahtarı çip satırının sağında. Üst çubuk 48 dp, alt çubuk 56 dp,
  sabit bölme çubuğu 40 dp. Yeni yüzen ek `_mutate`te yakalanır
  (`_placementHintId`) → tuval seçer, görünüm anahtarı nabızlı + "nerede
  dursun?" satırı.
- Klavye açılınca üst parçalar yeniden ölçülmez (`KeyboardClipWindow`);
  sabit görsel ölçeklenir, metin/PDF kırpılır.
- Not açılışı: önbellekteki hafif notla açılır, akış değişikliği ~450 ms
  sonra (`_setStateAfterOpening`; `ModalRoute.of` kullanma). Not karttan
  genişleyerek açılır (`NoteOpenPage`, geçiş ağacı her karede AYNI yapı;
  `SnapshotWidget` yalnız açılışta bir kez).
- Biçim paneli İKİ SIRA (2026-11-05, kullanıcı: "çok yer kaplıyor, açılır
  pencere olsun"): Stil⇅ · B I U · Renk▾ / Kapsam⇅ · Aa · A− % A+ · temizle ·
  (çizgi) · kapat. Stil ve Kapsam hapı TEPSİ AÇMAZ, basınca SIRAYLA geçer
  (Metin→Başlık→Alt başlık; İmleç→Kelime→Satır→Tümü; elle seçimde ilk basış
  seçimi bırakır). Kapsam ekranda soluk zeminle önizlenir
  (`WrapTextController.setScopePreview`, yalnız çizim; temizliği bir kare
  sonra — dispose'ta bildirim ağacı kilitliyken alanı kurdururdu). Boş
  satırda başlık = bekleyen boy+kalın (`setPendingFormats`). Renk, çizgi,
  yazı tipi panelin ÜSTÜNDEKİ tepside — menü ROTASI YOK (odak/klavye gider). Kapsam `FormatScope` seçimi
  GEÇİCİ: yalnız biçim uygulanırken imleçten açılır, sonra imleç döner
  (kalıcı seçim yazınca kelimeyi siliyor, "elle seçim" sanılıp kapsamı
  kilitliyordu). Panel açıkken geri paneli kapatır.
- **Ara başlık** (2026-11-05): `NoteItem.header` (yalnız true yazılır):
  kutucuksuz, kalın, işaretlenmez, ilerlemeye girmez; sıralı listede numara
  her başlıktan sonra 1'den (`itemOrderNumber`). "Yeni madde" satırında
  "Ara başlık" + uzun basış menüsünde "Başlık yap / Maddeye çevir". Madde
  kopyalayan yer (`duplicateNote`) alanı da taşısın.
- Ara başlık KONUMU (2026-11-05 gece): "Ara başlık" odaktaki ya da SON
  odaklanan (`_lastFocusedItemId`; düğme odağı alabilir) işaretsiz maddenin
  ALTINA girer. HİZA `NoteItem.align` ('' / center / end, yalnız doluyken
  yazılır): başlığa basılı tut → menüde üçlü düğme; kartta `Align`. Yeni
  madde alanı → karşılaştırmalar (`_sameItems`, `sameItemsVisually`,
  `_sameItem`), satır önbelleği anahtarı, kopyalayanlar (`duplicateNote`,
  sayfa kopyası, Gelen) — hepsine eklendi.
- **CÜMLE GENİŞLETİCİ TUZAĞI** (2026-11-05 gece, "kelime kapsamında boyut
  tüm satıra / başka kelimeye gidiyor"): `attachSentenceSelection` her
  PROGRAMLI tek kelimelik seçimi çift dokunuş sanıp cümleye büyütür.
  Kodla kelime seçen yer `withoutSentenceExpansion(() => c.selection = …)`
  ile sarmalı (biçim panelinin geçici kapsamı böyle).
- Geri bağlantı çipi yalnız varken çip listesine girer: boş `SizedBox`
  çip bile şeridi "dolu" saydırıp başlığın altında 36 dp boşluk bırakıyordu.
  Etiket hapı tek yerden (`core/widgets/tag_pill.dart`): renksizde temanın
  `secondaryContainer`ı, renkli notta vurgu %14.
- **Şablon favorileri** (2026-11-05 gece): `favoriteTemplatesProvider`
  (`favorite_templates`, en çok 4, anahtar `b:`/`u:`; hiç seçilmediyse
  `b:shopping` = eski sabit karo). "+" menüsünde Şablon bölümünün başında
  (`favoriteTemplateOptions`), galeride "Favoriler" bölümü + kart yıldızı;
  kartlar dikey/küçük (3–4 sütun). `NoteTemplateContent.columns` = "İki
  sütun" (`createNote(listColumns:)`, tek yazım). Öneriler grup içinde
  `sortedForLocale` (Türkçe harf sırası).
- Etiketler üst çubukta tarihin SOLUNDA (`EditorBarTags`, dokun = kaldır);
  başlık çubuktayken (`titleInBar`) çip şeridinde. Sabit ekte tutamağa
  dokunmak = sığdır (`_fitRatio`: video/sunum 16:9 yedek, görsel, PDF ilk
  sayfa); görsel/sunum da video gibi doğal boyunu AŞMAZ (PDF aşar, kayar).
- ItemsEditor: işaretli blok da `_cachedItemRow`'dan; soluk hâl renk
  alfasıyla (kalıcı Opacity katmanı YOK). Madde Enter'ı `_enterAt` (böler),
  başta Backspace üst maddeye birleşir. Jestler kipsiz (`classifyInkGesture`).
- Yazı tipi ilk kullanımda bütün metni yeniden yerleştirir → `main` yalnız
  genel yazı tipini bekler (≤ 400 ms), kalanı seçici açılınca
  (`preloadRemainingNoteFonts`, F25.1: açılış 5,2 MB → 295 KB). Yeni seçici de çağırsın.
- Canlı dikte TAM metni yollar ("değiştir"); bipler MainActivity'de
  susturulur. Tek mikrofonu son açan alır.
- Sayfa üstü el yazısı `Note.pageInk` (sahte `_page_ink` eki; `isEmpty`
  ona bakar). `InkPageLayer(uniform: true)` → y de genişliğe bölünür.
  Kalem `EagerGestureRecognizer` altsınıfıyla arenayı kazanır, parmak metne.
  **Not editöründe kalemler ALTTA KAPSÜLDE** (`PenTray(dock: true)`, 2026-11-07 sıfırdan:
  yazarken 44 dp hap = seçili kalem + renk; dokununca/yukarı çekince tek satır yüzen
  kapsül: kalemler · 4 hızlı renk + gökkuşağı halkası (geniş) · geri al · ⋯; dar ekranda
  tek renk noktası; çizim başlayınca/6 sn sonra hapa döner; ayar kartı kapsülün üstünde).
  Simge sözlüğü: palet simgesi = görünüm, kalem rengi için kullanılamaz. Mürekkep katmanında fare imleci `precise` (metnin I imleci kalınca
  çizgi "tıkladığım yerin üstünde" görünüyordu; koordinat doğru, testli). Belge/görsel/çizim ekranları eski şerit/sütunu kullanır
  (`PenTray.useRail` = PENCERE ≥ 600 dp). Tam ekran `noteFullscreenProvider`.
  "Ekle → Ayrı çizim (görsel)" = ayrı `DrawingScreen` → PNG görsel eki;
  "Sayfaya yaz (kalem)" (`handwriting`, "+"ta `draw`) = kalem kipi.
- Gömme: `_applyEmbed` (ek ya da `noteId`), `_startPendingEmbed` bağlama kipi.
- **Liste maddesi + görsel iki katmanlı sarma** (2026-11-02): görsel maddenin
  İLK satırına değiyorsa `_FloatRow` satırı bütün kaydırır; maddenin içinde
  (bir satır boyu aşağıda) başlıyorsa satır kaymaz, alanın kendi sarma planı
  (`WrapFieldMeasure.minTop`) yalnız hizadaki satırları girintiler. Bir görseli
  YALNIZ biri işler (ikisi birden metni kutucuktan koparıyordu).
- Editör parçaları (F18.23): `note_editor_flow/embed/video.dart` uzantılar.
  TUZAK: uzantı yönteminin tear-off'u her seferinde YENİ kapanış —
  `addListener/removeListener`a verilen ya da `setState` çağıran yöntem
  sınıfta kalır.

## Kısa kurallar (sıkıştırmada tek satıra inenler)
- ☑ `_toggleChecklistLine`: gövde hep maddelerin üstünde.
- Editör başlığı sığmazsa küçülür (`fitTitleFontSize`, en az 14).
- **Arama + klasör satırı (2026-11-06, 2. tur):** arama kutusundaki AI anahtarı HEP görünür; klavye açıkken solda geri oku YOK (kutu kayıyordu) — sağda hesap+⋮ yerine `search-done` (klavyeyi kapat) — TUZAK: `TextFieldTapRegion` içinde olmalı, yoksa pointer-down'da odak düşer, düğme kaybolur, dokunuş kutuya geçip klavyeyi geri açar. Kutu düzeni: AI hapı (42×30) | ayıraç | düz simgeler (süz pasifken kutusuz). Klasör satırı ⋮ → "Klasör satırını gizle" (`homeFolderStripHiddenProvider`); gizliyken sliver hiç çizilmez (boşluk kalmaz), klasörlere sol alt düğmeyle.

## 2026-11-07 — Tablet turu (HUAWEI MatePad 11, GMS'siz, M-Pencil) — kök nedenler
- Bölünmüş görünümde not klavyesi listeyi daraltmaz (`MediaQuery.removeViewInsets`, sarma hep var — ağaç şekli sabit). Rayda klavye kısayolları yalnız web'de (M-Pencil kendini "klavye" diye tanıtıyor).

## 2026-11-07 — Tablet: avuç, kalem tıkı, fiziksel klavye
- **Fiziksel klavye:** `HardKeyboard` (kanal `dev.kaimau.notlar/keyboard`). Yalnız HARİCİ HARF klavyesi sayılır (M-Pencil, ses/güç tuşları da "klavye"); kapak arkaya katlıyken (`hardKeyboardHidden`) yok. Takılıyken `TextInput.setInputControl(boş denetim)`: alan bağlı kalır, giriş türü `none` gider, sanal klavye açılmaz; not üst çubuğunda ⌨ düğmesi (`editor-soft-keyboard`) açar/kapar (odak bir kare bırakılıp geri alınır ki alan yeni türle bağlansın). Sistem kanalının Dart işleyicisi PiP'te: yeni olay için AYRI kanal aç.

## 2026-11-08 — Kalem, satır hatırlatıcısı, bildirim düzeyi, kapanış kasması
- **Yazarken üst hızlı satır** (`editor_quick_row.dart`): `KeyboardSwitch` yaprağı yalnız `MediaQuery.viewInsetsOf`'a bağlı; hazır verilen alt ağaçlar aynı örnek → klavye karelerinde alt ağaç kurulmaz (F38.7 bekçisi yeşil). TUZAK: `KeyboardSnap.onSettled` klavye KAPANIRKEN çağrılmaz (inset canlıya hemen iner) — kapalı/açık durumu ona bağlama.

## 2026-11-08 — Oturum B (arama, yazı tipi, Gmail, takvim pratikliği)
- **Alt çubuk yazarken gizli:** `_typingN` ValueNotifier + `_TypingHide` (boy/opaklık, setState YOK); `_mutate(immediate:false)` + klavye açıkken tetikler, 650 ms sessizlikte döner. Ayar `hideBarWhileTypingProvider` (varsayılan açık), ipucu `TipOnce.typingBarHide`.

## 2026-11-08 — Oturum C (12 maddelik istek listesi)
- Hızlı satıra "sonradan eklenen" düğmeler: `UiItem.optIn` varsayılan GİZLİ, açılınca `hidden` kümesinde `+kimlik` (kayıt biçimi aynı). Satır sonundaki ⚙ = `Personalize.startEditing`.
- Yazım düzelt: `core/utils/spell_fix.dart` (saf kurallar) + `spell_engine.dart` (karar) + `auto_spell.dart` (aktif alana `_setFormatTarget`tan bağlanır). Tek karakter yazımında çalışır; yapıştırma/dikte dokunulmaz.
- Not paketi: metinde `AttachmentKind.text` + `extras.package` (etiketi `📎 ad`, ADLA eşleşir → `packageName` çakışmada numaralar); listede `NoteItem.package` (kapalı paket: ilk satır özet, kalanlar SIFIR yükseklik — sürükleme dizinleri bozulmasın diye satır kaldırılmaz; açıkken `TapRegion` dışarı dokununca daraltır).

## 2026-11-08 — Oturum D (18 maddelik ikinci tur)
- **Not paketi kendiliğinden kalkıyordu — kök neden:** `_sameItem` (text_merge), `ItemsEditor._sameItems`, `sameItemsVisually` `package` alanına bakmıyordu → birleştirme yerelin paketlemesini "değişmedi" sayıp uzaktaki paketsiz kopyayı yazıyordu. Yeni GÖRÜNÜR madde alanı → bu ÜÇÜNE de ekle. Açık pakette Enter/yeni madde paketi miras alır; paketin boş son maddesinde Enter paketten çıkarır.
- **Esc = geri:** `EscBackIntent` (app.dart `shortcuts`) — `DismissIntent`'e BAĞLAMA: metin alanı odaktayken `EditableText`'in DismissIntent eylemi `Actions.invoke` ile sayfa rotasının DEVRE DIŞI eyleminde durur, Esc hiçbir şey yapmaz. Eylem: açılır rota (PopupRoute) → kapat; değilse kök yönlendiricinin `backButtonDispatcher.invokeCallback`.
- **Tablette hızlı satır gelmiyordu:** yüzen/ayrık/fiziksel klavyede `viewInsets.bottom` 0. `KeyboardSwitch(editing:)` tablette (en kısa kenar ≥ 600, web değil) alan odaktaysa da açar (`_fieldFocusedN`, FocusManager dinleyicisi). Test yüzeyi 800×600 = TABLET sayılır: telefon davranışı testlerinde `tester.view.physicalSize = 400×800`.
- **Sürükleme tutamağı** web/tablette hep görünür (`_pinHandles`, satır önbelleği ortam anahtarında); soldaki 12 dp dolgu 2'ye iner.
- **Yazım v2 (Faz 70, 2026-11-11 — eski "öğrenen yazım" maddelerinin yerine):** karar TEK yerde `core/utils/spell_engine.dart` `SpellEngine.decide` (sıra: notta/genel dokunulmaz → öğretilen (n ≥ 2 ya da onaylı) → kural tablosu → [yalnız kurallar/başlık/Çince/bilinen = dur] → boşluk komşusu bölme → TEK adaylı bulanık (`confidenceMargin` 0,3) ya da tek yakın cihaz önerisi); reddedilen çift (`a>b`) hiçbir aşamada uygulanmaz. `auto_spell.dart` yalnız bağlama: önce büyük harf/noktalama (`spellFixAt(fixWord: kimlik)`), sonra motor; son 30 biten kelime izlenir (`_track` kaydırır, değince `touched`, düzenleme başka yere geçince `_settle`). **KÖK NEDEN (ısrar):** v1 yalnız SON kelimeyi ve yalnız silmeyle izliyordu; bulanık aday her seferinde aynıydı. Hafıza v2 `spell_memory.json` (v1 → `.v1` yedeği; web `spell_memory_v2`), harf karışıklıkları kalktı. Test kalıbı: `test/spell_engine_test.dart` `_Kb` (denetleyiciyi klavye gibi sürer).
- Alt çubuk yazarken 1,1 sn sonra; yeni alana geçince ve klavye kapanınca (KeyboardSnap builder'ında inset 0) HEMEN (`_showBarNow`).

## 2026-11-08 — Oturum E (15+2 maddelik üçüncü tur)
- Alt çubuk 50 dp; yazarken gizleme 3 art arda değişiklikten sonra (`_typedBurst`). Seçim çubuğunda "Pakete al" (`togglePackage`), düğmeler compact. Kısayol adı/simgesi `stripRichMarkers`. Gmail "İletiyi çevir/Orijinali göster" (Gemini `translateText`, bir kez çevrilir). Klasör çekiş menüsünde Yeni klasör + Sırala·sil (`FolderOrderPanel` satırında sil). 5 sade klasik tema (`classic/newsprint/notebook/graphite/ledger`, koyu = beyazın koyusu; vurgu doygunluğu > 0,2 testi).

## 2026-11-09 — Oturum F (yeni özellik denetimi)
- **Uzun liste notunda not içi arama eksikti:** `searchFields` yalnız kurulmuş satırların denetleyicisini veriyordu → ekran dışı maddeler aranmıyordu; artık hepsi (`_controllerFor`). Kurulmamış satıra gidiş `ItemsEditorState.revealItem/revealFocus`: satırın bağlamı yoksa EN YAKIN GERÇEKTEN KAYAN ataya (liste çoğu kipte uzunluğu 0 olan iç Scrollable) tahmini konuma atla + kare bekle, en çok 4 deneme.
- Not rotası yeni parametreler: `?item=<madde>` (zamanı gelenler şeridi), `?find=<sorgu>` (F56.1, kilitli notta taşınmaz).
- **Üstüne yazı (açık metin) her görünümde:** `AttachmentAction.addText` (şerit/gömülü/sağ tık menüsü; yüzen ve sabitte menüde değil çubukta "T"). Tam ekran `ImageViewerScreen/PdfViewerScreen(startText:)` açık metin bırakma kipiyle açılır; PDF tam ekranda ayrıca "T" düğmesi (`pdf-quick-text`; balon düğmesi artık `plainMode` false yapar). Sabit bölme: `pinned-quick-text` → `_startAdding(plain: true)`.

## 2026-11-09 — Oturum H (tablet cihaz turu dönüşü)
- **Tablet klavye karmaşası** KÖK NEDEN: `SplitShell._split` Scaffold'u gövdeyi klavyede kısaltıyordu → listenin `removeViewInsets` sarması boşa; `resizeToAvoidBottomInset: false` (editör `KeyboardSnap`, defter kendi Scaffold'u).
- **Esc** KÖK NEDEN: editörün `CallbackShortcuts` Esc'i `Navigator.maybePop` ile yutuyordu (kabuk iç gezgini tek sayfa) → kaldırıldı, uygulama `EscBackAction` (geri dağıtıcı) çalışır.
- **Paket**: × ile çöz (`unpackGroup`). Kasma izole ölçümde ÜRETİLEMEDİ (30 madde, açık/kapalı paket, yazarken fazladan satır kurulumu yok) — cihazda hangi adımda olduğu bekleniyor.
- **Paket kapanması — kök neden (F60.2, 2026-11-10):** `TapRegion` grubu paket başına (`note-package-$pkg`) ve yalnız üyelerdi → editör çubuğuna (Biçim) dokunmak "dışarı" sayılıp paketi kapatıyordu. Grup TEK sabit `kNotePackageTapGroup`; alt çubuk, hızlı satır, biçim paneli, kalem tepsisi `TapRegion(groupId:)` ile HEP sarılı. Yeni editör çubuğu/paneli eklersen o gruba kat. `togglePackage`'da `_rowCache.clear()` yok (anahtar `package`+sıra içeriyor). Bekçi `note_package_open_test` (S10).

## 2026-11-09 — Oturum J (tablet senkron + hızlı satır sadeleşmesi)
- **Fiziksel klavye + sanal klavye döngüsü** KÖK NEDEN: Bluetooth klavye boşta uyuyunca Android "çıkarıldı" bildiriyor → `HardKeyboard` platform girişine dönüp sanal klavyeyi açıyordu, tuşla uyanınca geri. `HardKeyboard.report`: son tuştan 15 dk içinde gelen "çıktı" yok sayılır, süre dolunca yerel durum yeniden sorulur.
- **Hızlı satır sade varsayılan**: pen · spell · package · attach (Ekle levhası) · bold · color; gerisi `UiItem.optIn`. Renk düğmesi `NoteFormatMemory.favoriteColor` (1 = palet kırmızısı, özel renk ARGB); basılı tut `showColorPaletteSheet` → favori.

## 2026-11-09 — Baştan sona inceleme → `docs/arsiv/planlar/OTURTMA_PLANI.md` (Faz 58–69)
- **Koddan doğrulanan kökler (düzeltilmedi, plan maddesi):** (1) sabit/gömülü eke her çizgi `_updateAttachment` → `_mutate(immediate: true)` → `_sameVisual`'da `identical(attachments)` false → editörün TAMAMI kurulur + anında tam kayıt (F60.1). (2) Mürekkep `double` dizisi (nokta başına 16–24 bayt), notun tüm mürekkebi tek `heavy/data` belgesinde; her kayıt hepsini ana iş parçacığında gezer/kodlar; 1 MiB'e ~1–2 ekran yoğun el yazısında dayanır (hesap; F61.0 ölçer). (3) `InkPainter` her kalem hareketinde sayfanın bütün çizgilerini boyar; basınçlı çizgi nokta başına `drawLine` (Faz 62). (4) Paket: açık paketin `TapRegion` grubunda yalnız paket satırları var — araç çubuğuna dokunmak paketi kapatıyor olabilir (hipotez, F60.2). (5) Ana ekran tepesi telefonda sabit `Column` (~210 dp), kaydırınca çekilmiyor (F66.1).
- **F60.S2 "gir-çıkla artan klavye kasması" (2026-11-10):** dinleyici/nesne sızıntısı cihazsız YOK — `test/editor_leak_test.dart` (gerçek kabuk, 28 aç-kapa, 6 not türü) nesne, genel dinleyici ve klavye turu kurulumlarında artış görmedi; yeniden "sızıntı" aramadan önce cihazda taze ↔ 30 gir-çık sonrası `ab_klavye.py` farkını ölç. Sızıntı bekçisi kalıbı: `FlutterMemoryAllocations` ile yaratılan − atılan, tür başına BÜYÜME (sabit kalıntı ve Layer/Picture sayılmaz).


## 2026-11-13 — Hızlı satır: etkin biçim, yeni düzenleme levhası
- `EditorQuickRow.target` (= editörün `_formatTargetN`): satır kendi State'inde hedef denetleyiciyi dinler, `activeRichFormats`/`activeRichHeading` DEĞİŞİNCE yalnız satır çizilir (kök kurulmaz). Basılı: kalın, eğik, altı çizili, vurgu, renk, başlık/ara başlık. Madde imi/onay kutusu için durum yok (yapılmadı).
- Düzenleme: `quick_row_editor.dart` — `quickRowCatalog` + `QuickRowEditor` (levha ya da `inline`), anında `Personalize.update` (taslak/kaydet YOK). ⋮ "Hızlı menüyü düzenle" bunu açar; Kişiselleştir ekranında da bölüm. Eski satır içi düzenleme kipi (Personalize.startEditing) başka yüzeyler için duruyor.
- Tablet dönüşü: `SplitShell._back` — not kapanınca listeye Fade(0,35→1)+Slide(0,04→0), AppMotion.medium; yalnız boyama.

## 2026-11-13 — P50: düzenleme modu anında, kapsül taşıma
- **Düzenleme modu taslak DEĞİL** (kullanıcı: "aç, düzenle, kaydet değil"): `Personalize.toggle` → `update` (hemen `prefs` + disk). `draft` yalnız "mod açık" işareti (değeri kayıtla aynı); `_before` modun açıldığı andaki kayıt. Şerit: `customize-undo` (`revert`, mod açık kalır, `dirty` değilse sönük) + `customize-done` (`done`). `save`/`cancel` KALKTI.
- **Kapsül tarafı** `UiPrefs.barSides`: kimlik `aiOrder`'daysa sağ, `barOrder`'daysa sol, hiçbirinde yoksa varsayılan tarafı; `withBarSide` öbür kapsülün sonuna taşır. Yeni alan yok — iki liste yabancı kimlik de taşır (eski sürüm `orderOf`'ta atlar). Editörde `spec(id)` (simge, ad, iş, etkin) tek kaynak; `leftOf` araç segmenti (Biçim/Ekle/Kalem/Ekler özel), `rightOf` `_voiceButton` (AI özel). Plan: sağa taşınan Ara/Kalem düşürülmez (`planEditorBar(search:)`), sağdaki her düğme `aiButtons`'a sayılır.
- **Yanlış yol:** `spec` içine `() => _update(...)` yazmak kök setState mandalını (53) aştı → ortak `_toggleAnnotate`. Çubuğa yeni iş eklerken var olan yöntemi geçir.
- Tam ekran AÇIKKEN `topFullscreen` gizlenmez (çıkış yolu). ⋮ (`editor-more`) hiç sarılmaz.
- Yapılmadı: ana ekran sarmaları (P56 çiti), üst çubuk sıralama (yapı P20'nin), düzenleme modunda yerinde sürükle-sırala (sıra Ayarlar listesinde).

## 2026-11-14 — P20: editör çekirdeği dar dinleme (KURAL, F64.5)
- **KURAL:** editöre yeni görünür parça = `NoteSlice` (`editor/note_slice.dart`, `_noteN`'den dilim) ya da kendi notifier'ını dinleyen ayrı widget; `_NoteEditorScreenState`'e alan/`_update` eklenmez; madde sırasına bağlı değer satır önbelleğine girmez (`_RowSlot`). Bekçi `test/editor_core_guard_test.dart` (`_update(` ≤ 32 satır, `_sameVisual` ≤ 32 terim, `note.starred/pinned` build'de yok).
- `_note` = `_noteN` (`LateSafeValue`: dispose SONRASI yazım sessiz — `_saveNow`/geç geri çağrılar yazıyor; düz `ValueNotifier` dispose edilince assert, edilmeyince `editor_leak_test` kırmızı). Geri al/yinele `_undoN` (yığını değiştiren 3 yerde `_syncUndoN`): S1 kök 1→0; metin geri alınınca yinele bayat `null` kalıyordu (kök kurulmuyordu) → çözüldü. Yıldız/iğne `NoteSlice` + `TogglePop` (S14 tuval 1→0); biçim kipi `_formatOpenN` + `_formatPanelL` (kip+hedef) (S9 tuval 2→0).
- **TUZAK:** `NoteSlice` builder'ı dışında kökün yerel `note`'u yeni alanlar için BAYAT olabilir (kök kurulmuyor). Tarih şeridi (yıldız orada) yalnız `updatedAt`/etiket varken çizilir — testte `updatedAt` ver.
- **Bütçe dengesi:** her dar dinleyici ilk karede +1 kurulum (S18). `Customizable` StatelessWidget+ListenableBuilder → tek StatefulWidget yapıldı (öğe başına −1; editör ilk karesi −11, ana ekran −3) — yeni sarmalayıcı gerekirse önce böyle yer aç.
- **M6 (sabah bakılacak):** `_sameVisual`/`sameRenderedNote` SİLİNMEDİ, daraldı (pinned/starred çıktı). Tam silme = bütün `note.` okumalarının dilime geçmesi (tuval çıkarma) — kullanıcı kararı. **M7:** kural CLAUDE.md'ye/`kasma-kontrol` md. 1'e işlensin mi — sabah bakılacak.
- **Üst çubuk sırası (adım 9):** `actions:` = `for id in UiPrefs.orderOf(UiItem.topDefault, _topOrder)` + `switch` kolları (öğe kodu yerinde). Kök yalnız `topOrder` değişince kurulur (`Personalize.listenable` → `_onTopOrder`, `listEquals`); gizle/göster öğenin kendi `Customizable`'ında. ⌨ ve ortak düzenleyen Ana sayfa yuvasına bağlı, ⋮ hep sonda.
- **Ana ekran sarmaları:** tek aday AI anahtarı; `Customizable` S24 ilk kareyi 927→928 yaptı → yapılmadı. Ana ekran ilk karesine sarmalayıcı = S24 +1; önce başka yerden kurulum düşür.
- **Kök neden (akicilik):** S3/S4'te 23 satırın kökü sıra numarasının satır önbellek anahtarında olması + `SliverReorderableList`'in dizinli `GlobalKey`'iydi (`_RowSlot` + tutamaçsız düz `ListView`).

## 2026-11-15 — P63 G2: madde çizgileri (PB6) + şablonlar (PB4)
- **Çizgi seçici TEK bileşen:** `DividerKindPicker` (tepside `compact`, levhada adlı); tepside örnekler maddenin renk/kalınlığını taşır → `FormatBar.dividerStyle` (kaynak `ItemsEditorState.dividerOf`). Tepsi boyu 42, çubuğun iki sırası değişmez.
- **Vurgu saydamlığı tek sabit** `kItemDividerAccentAlpha` (`item_divider_style.dart`, `AppAlpha.strong`); kart (`note_card.dart`) `AppAlpha.muted` ile ayrı kalır.
- **Beliriş** `_DividerReveal` (`items_editor_widgets.dart`): koşulsuz sarmalayıcı, tetik yalnız `didUpdateWidget` boş→dolu, denetleyici tembel, boyayıcı `repaint:` ile dinler, `clipRect` (katman YOK). Geri alma = tek commit ("PB6 4").
- **Ölçüm (S44):** seçim başına 1 kök kurulumu bugünkü yol (`setDividerOf` → `_update`); tepsi kabuğunun `AnimatedSize`'ı gövdeyi 14 karede diziyor — düzeltilmedi, regresyon listesinde.
- **Şablon levhası (PB4):** `note_templates_test` `CheckboxListTile`/`Icons.check`/`Icons.star_outline` bulucularına bağlı — önizlemede `CheckboxListTile` korundu; "Oluştur" levhanın sabit alt bandında (Column + Flexible kaydırma).

## 2026-11-15 — Hızlı giriş: liste şablonu sayfası + "Hızlı ekle" (kullanıcı isteği, AI'sız)
- **Ayrıştırıcı** `notes/domain/quick_entry.dart` (saf, `test/quick_entry_test.dart`): virgül/`;`/satır = KESİN ayırıcı, boşluk yumuşak. Sözlük (`QuickLexicon`) öbeği en uzun eşleşmeyle; Türkçe harfsiz yazım (`quickAscii`) birebir sayılır; yapışık yazım sözlükten bölünür; yakın eşleşme 4–6 harfte 1, 7+ harfte 2 hata (2 hatada ilk harf tutmalı, eşit adayda KARAR YOK); sözlükte olmayan ardışık kelimeler kesin ayırıcıya/bilinen kelimeye kadar TEK madde; miktar "2 süt / 3 kg domates / domates 3 kg / iki ekmek" → `Ad (miktar)`; niteleyici ("yağsız", "organik") sonraki maddeye yapışır. Canlı kip: tamamlanmayan kısım `rest` olarak alanda kalır; öbek başı ("süt" → "süt tozu") devamını bekler, `QuickEntryBar.idleDelay` (720 ms) sonra `idle: true` ile bırakılır.
- **Sözlük** `quick_lexicon_data.dart`: elle derlenmiş ~1100 market maddesi (TR + EN), `QuickAisle` reyon sırasıyla; alışveriş şablonunun öneri grupları `kShoppingSuggestionAisles` ile reyonlara eşlenir. Yeni madde eklemek = ilgili reyon dizesine yazmak.
- **Hafıza** `data/quick_entry_memory.dart` (`quick_entry_memory_v1`, cihaz yerel, senkron YOK): tür başına (`b:shopping`, `u:<id>`, `drop`) eklenen maddeler + sayı → "Sık eklediklerin" ve sözlük; geri alınan düzeltme çiftleri. **Yazım hafızası bağı** (`buildQuickParser`): `SpellMemory.learned` uygulanır, kullanıcının kendi kelimesi (kişisel sayaç ≥ 3 ya da `keep`) ve reddedilen çift düzeltilmez; kabul edilen düzeltme `learnFix` gözlemi, geri alınan `rejectPair` olur (`teachSpellFromQuickItems`, `QuickEntryMemoryNotifier.reject`). TUZAK: `SpellMemory.known` yerleşik sık kelimeleri de sayar — yakın eşleşmeyi kapatmasın diye bilerek kullanılmadı.
- **Ekranlar:** `QuickEntryBar` (ortak satır; yazı + `VoiceListenSession` ile cihaz tanıması; `raw` kipinde metni tüketmez), `QuickListScreen` (`showQuickList`, kök gezgin; iki sütun notla aynı yarı-yarıya düzen; geri = kaydet, boşsa not oluşmaz; hazır maddeler listeye girmez, "Sık"ın tohumu), `QuickDropSheet` ("+" kataloğu `quickdrop`; hedef `parseDropTarget`: "ad: içerik", "…<ad>e … ekle", "add X to Y"; yazım `updateFields` ile yalnız `items`/`body`; alışverişe benzemeyen listede `phrasesOnly`). Şablon kapısı `pickTemplate` (liste → hızlı liste, yazı → levha önizlemesi).
- **Temizlik borcu KAPANDI (2026-11-17 T15):** `TemplateComposer` yalnız YAZI şablonu önizlemesi (liste dalı, `showNoteTemplateSheet`, `NoteTemplateSheet.quickLists` silindi; `composeTemplateContent(base, title:)` yalnız başlık biçer). Galeriye tek kapı `pickTemplate(context, ref)`; testler/tur/S41/S48 ona geçti (tur sahnesi `sablon-hizli-liste`). `templateCreateWithCount`/`templateTwoColumns`/`templateSuggestionsInfo` .arb anahtarları artık kullanılmıyor — .arb değişikliği tam takımı tetiklediği için bırakıldı (sonraki .arb işinde silinebilir).
- **Sınırlar:** hızlı ekle sayfalı yazı notuna, kilitli/arşivli nota eklemez; ses yalnız Android (web'de mikrofon düğmesi yok). Cihazda doğrulanmadı.

## 2026-11-16 — Hızlı ekle hedefi, Akıllı liste, hızlı liste klavye kanalı (ccr-f6c2108b)
- **Hedef SONDA** (`parseDropTarget`, kullanıcı: "isim tanıma en başta değil en son"): sonda ek/işaret ya da komut; başta ancak ek/işaret VE komut ("markete ekmek ekle"); ortada/kanıtsız = içerik. Eşleme kökten (`quickStem`: kaynaştırma harfli ek y/n/s yalnız ünlüden sonra atılır — "dosya" "dos" olmasın); başa baş kalanlar `ties` (sorulur). Dönüş kaydı `({index, content, ties, command})`.
- **Konuşma sonu** (`QuickDropSheet._onSpeechEnd`): hemen eklemez — 1,6 sn geri sayım + Bekle; "… ekle" dendi ama ad yok/başa baş → `quickDropAiProvider` açık ve AI hazırsa `GeminiService.pickDropTarget` (AiTask.short, YALNIZ başlıklar; yanıt `sıra | içerik`, içerik ancak söylenen kelimelerden oluşuyorsa kullanılır), yoksa "Hangi nota eklensin?". Art arda maddeler `quickDropSeparate` ("bir de/ayrıca/ve sonra" → virgül; düz "ve" bölmez).
- **Akıllı liste** = `QuickListScreen(args.smart)` + `smart_list.dart` (saf): market (grup 0–99) + bavul sözlüğü (`kPackingGroupBase` 200+); tür `smartKindOf` (yalnız TEK türe ait maddeler sayılır) ya da "bavul listesi" öbeği (`smartKindFromPhrase`, madde olmaz); başlık kullanıcı elle değiştirmediyse türle değişir; sıra `smartRank`. Alt başlık YOK (kullanıcı kararı: S6 çıktı).
- **KÖK NEDEN (şablon kasması, 2026-11-16):** `QuickListScreen` Scaffold'u klavyenin her karesinde gövdeyi kısaltıyordu (F60.S5'in aynısı). Artık `KeyboardInsetScope` + `resizeToAvoidBottomInset: false` + `KeyboardSnap` (gövde parçaları builder DIŞINDA bir kez kurulur) + öneri şeridi `KeyboardSlide`. S49 ölçümü oturma karesini de sayar: 438/168 → 341/99. Yeni levha/sayfa klavyeli + altta şerit = bu kalıp.
- **Liste ↔ numaralı:** alt çubuğun türe özgü yuvası `UiItem.barCheckbox` (metin notunda ☑) → `_toggleListKind` (`_mutate`, yeni `_update` yok). Çubuk dar telefonda Ara'yı düşürür (plan).

## 2026-11-16 — Not ⋮ sadeleşme, üstte Notta ara, biçim paneli geri, numaralı ✓, sesle "bitti", bildirim kapanışı (ccr-829c4834)
- **Klavye açıkken geri tuşunu Android klavyesi (IME) alır**, `PopScope`a ulaşmaz. Biçim paneli kuralı için `ImeHideDetector` (`editor/ime_hide_detector.dart`) editörün `didChangeMetrics`inde klavye inişini izler (zirvenin yarısının altı, iniş başına bir kez); odak hâlâ `EditableText`teyse paneli kapatıp `TextInput.show` ile klavyeyi geri açar. Alan dışına dokunuşta odak önce gider → dokunmaz. Cihazda denenmedi.
- **Hız bütçesi (S18/S19/S45/S50) yeni üst çubuk düğmesiyle kırıldı**: `IconButton` (InkWell) testte donanım tuşu odak vurgu kipini değiştirince yeniden kuruluyor; `AfterRouteTransition` rotaya bağımlılık kurup kapanış karesinde +1 veriyor. Çözüm: InkWell/ipucusuz `GestureDetector` + `Semantics`, sabit örnek, `_RevealAfterOpen` (zamanlayıcıyla, bağımlılıksız) — bütçeye dokunmadan yeşil. Bütçe yükseltmek otomatik izinde reddedildi: kullanıcı kararı.
- **Bildirim şeridi** (`app_notice.dart`): kart dokunuş/yana/aşağı itişle kapanır — tanıyıcılar `_DragPaint` render nesnesinde (widget sayısı S31 kare_kurulum 20'de kalsın diye; `GestureDetector`+VLB+Opacity 24 yapıyordu). Geri sayım `SteppedCountdown` (saniyede 8 adım, `CustomPaint` dinler): eski `TweenAnimationBuilder` bildirim boyunca her karede tüm sahneyi rasterletiyordu (kullanıcının "bildirim varken kasma" bulgusu; cihazda ölçülmedi).
- **Numaralı listede işaretli** madde `itemOrderNumber` → null, sayım atlar; editörde ✓ (`item-done-<id>`, dokununca işaret kalkar), kartta ✓ + üstü çizili.
- **Not ⋮**: hızlı satır önem sırası (pin?, renk, çerçeve, paylaş, klasör, yıldız; `maxQuick` aşanı Düzenle başına), `ActionMenu.collapsible` (ilk grup açık, oturumda hatırlanır `_folds`), 'search' hep `visibleElsewhere`.
- **"bitti"**: `stripDoneWord` (`domain/done_word.dart`, yalnız SONDAKİ söz); `QuickEntryBar.onDoneWord` oturumu İPTAL eder (stop son sonucu "bitti"yle yeniden getirirdi).

## 2026-11-16 — Notta ara anında, arama satırı üstte, klavye açıkken levha sırası (ccr-66e231d6)
- **Notta ara düğmesi `GlyphButton`** (`editor/glyph_button.dart`): simge + dokunma (`TapGestureRecognizer`) + Semantics tek `RenderBox`ta; RenderObjectElement build etmez → S18/S19 bütçesine girmeden İLK karede. Eski `_RevealAfterOpen` (300 ms zamanlayıcı) "yarım saniye sonra pat diye geliyor" bulgusunun kök nedeniydi — kaldırıldı.
- **Arama satırı gövde Column'unun TEPESİNDE** (`findSlot`, KeyboardSnap dışında kurulan aynı örnek; kapalıyken `SizedBox.shrink`). Alt çubuk aramada yerinde kalır. `_findOpen` artık `_findOpenN` bildiricisi: aç/kapa kök setState yapmaz (arama_ac haritası NoteEditorScreen=0); PopScope `_popL`, biçim paneli `_formatPanelL` dinler. Pencereli gövde açılışta elle `exit()` edilir (eskiden kök kurulumu yapıyordu).
- **Klavye açıkken ⋮ / "+"**: `_dismissKeyboardAfterSheet` — levha `requestFocus: false` ile açılır, klavye levhanın ilk karesinden sonra (post-frame) iner. Not: `ModalRoute.didPush` route.requestFocus değil navigator.requestFocus'a bakar ama o anda kapsam kurulmamış olduğundan etkisiz; odağı alan levha değil editörün kendi `unfocus`u. Test ortamında iki sürüm (9738fc1c / fea856fe) aynı yükte — kullanıcının "son güncellemeden sonra" kasma bulgusunun kök nedeni testte görünmedi; cihazda ölçülmedi.

## 2026-11-17 — Hızlı ekle / akıllı liste hataları
- H9: `koy/yaz/kaydet/not et/not al` hedef bulunamazsa içerikten SİLİNMEZ, `command:false`; yalnız
  `ekle` ailesi tek başına komut kanıtı (`_addCommand`, `quick_drop.dart`).
- H10: hızlı ekle notun GÜNCEL hâlini akıştan okur (`_noteOf`); geri al `quickDropUndoFields`:
  yalnız eklenen maddeleri çıkarır, değiştirdiği madde hâlâ yazdığı hâldeyse eskisine döner.
- Akıllı liste ayrıştırıcısına market sözlüğü katılır (`grocery || smart`, `quick_list_screen.dart`).

## 2026-11-17 — Akıllı liste AL-1 (T5, dal oto/P65-telefonsuz-kod)
- **§5.1 sözlük hatası** daha önce düzeltilmişti (`grocery: args.grocery || args.smart`, `smart_list_test` "boşlukla yazılan market maddeleri").
- **Sık eklenenler türe bölündü:** kayıt `smartMemoryKind(kind, tür)` → `smart:market` / `smart:bavul` (düz/şablon liste kendi anahtarında). Şerit tür başına bir kez hesaplanır (`_frequentBy`); tür belli değilken market + bavul + eski ortak `smart` karışık (sırayla), türde ilgili anahtar + eski ortak kaydın o türe süzülmüşü. Sözlüğe (`learned`) üç anahtar da girer.
- **Geçen seferden kalanlar akıllı listede TÜRE göre** (`quickLeftoversWhere` + maddelerden `smartKindOf`): başlığı "Antalya" yapılmış bavul listesi bulunur; düz tür (henüz belli değil) kalan göstermez. Düz/şablon liste eskisi gibi başlıkla.
- **Boş akıllı listede ipucu** `smartListHint` ("bavul listesi" de). **Bütçe** S49 `acilis_kurulum` 634, `akilli_acilis_kurulum` 688 (K-41; AL-1 öncesi/sonrası aynı). Cihazda ölçülmedi.

## 2026-11-18 — P75 editör istekleri (U7/U6/U2/U3/U5, KW-11)
- **Seçim menüsü sırası tek kurucuda** (`arrangeSelectionMenu`, tag_tap.dart): Kopyala · Kes · Yapıştır · Tümünü seç → bizim işler → platform ekleri. Tümünü seç Android'de vardı ama Biçim/Ek göm'ün arkasında ⋮'ye düşüyordu.
- **Alt kapsül telefonda 4 yuva** (`kEditorBarPhoneSlots`): ilk üç + ⋯ (`_barOverflow`, `showMenu`, GlobalKey ile konum — `Builder` eklemek S17 bütçesini +1 aşıyor). Tablette (`PenTray.useRail`) ve düzen kipinde hepsi.
- **Sayfa çevirme jest karışması (U3) KÖK NEDEN:** `PageSwipeDetector` ham `Listener` — arenaya girmediği için başka işin kullandığı hareketi bilmiyordu. Arenaya katılmak çözüm DEĞİL: Android'de metin alanının `TapAndHorizontalDragGestureRecognizer`'ı her yatay sürüklemeyi kazanır, metin üstünde çekiş hiç çalışmazdı. Çözüm: dokunuş sırasında kaydırma bildirimi / odaklı alanın seçim değişimi / basılı kalem-fare imleci çekişi geçersiz kılar. Bildirim dinleyicisi `Listener` alt sınıfının öğesinde (`NotifiableElementMixin`) — ayrı `NotificationListener` editörün her kurulumunda +1 öğe (S17 kırmızı).
- **Geri sayım (U5):** `SteppedCountdown` artık tek `AnimationController` (ressam `repaint:`; kurulum yok). TUZAK: eylemli bildirim açıkken `pumpAndSettle` süre bitene dek pompalar ve bildirimi kapatır — testte `pump()` + `pump(500 ms)`.
- **Kalemde Ctrl+Z (KW-11) — üç kök neden:** (1) metin alanı bırakılınca birincil odak ROTANIN kapsamı; editörün `CallbackShortcuts`'ı altında kaldığından tuş ulaşmıyordu → odaksızken `HardwareKeyboard` işleyicisi (`_onHardKey`). YANLIŞ YOL: ağaca `Focus(autofocus)` tuş düğümü eklemek — kapanan editörün odaklı düğümü yeni editörün kurulumunda `KeyboardSlide._textFocused` atılmış bağlama baktırıyordu (S12b vb. 14 bütçe testi kırmızı). `_routeScope` `Focus.maybeOf(createDependency: false)` ile (bağımlılık = her odak değişiminde editör kurulumu). (2) `_sameVisual` çizgiye bakmaz → geri alınan çizgi "saf yazım", ekran kurulmuyor, `_pageInkOf` eşitlemesi çalışmıyordu → `_syncPageInk`. (3) `structureKey`'de çizgi yoktu, 900 ms'de çizilen çizgiler tek adımdı → `ink:<sayı>`.
- **U2 yanlış yol:** hızlı satırı telefonda `fit: true` yapmak — `LayoutBuilder` klavye hareketinde satırı yeniden kuruyor (S17 37→70, S45, S50 aştı).

## 2026-11-19 — P78 tablet bulguları (KT-15/16/18)
- **Bildirim + yeni açılan alt panel AYNI karede = panel örtülür** (KT-16): `SnackBarObstacle` yüksekliği dizilimde yazılır, bildirim KURULURKEN okur. Paneli açan işlemde ipucu göstereceksen `addPostFrameCallback` ile göster (`_penModeOpened`). Aynı karede iki ipucu varsa sırayı koru (sonraki öncekini siler).
- **Yüzen kalem düğmesi payı** (KT-15): `StylusToggleOverlay` → `StylusGutter.endOf(context)` (düğme sağ kenardayken 52 dp, değilse 0). Satır sonu eylemi olan yeni satır eklersen bu payı uygula; değer yalnız düğme kenara/ortaya taşınınca değişir (kurulum maliyeti yok).
- **⌨ durumu = sanal klavye görünür mü** (KT-18): `HardKeyboard._onInset` istenmiş klavyenin payı sıfıra inince `softWanted=false`. Yanlış yol: GERİ'yi Flutter'da yakalamaya çalışmak — IME kapanışı Flutter'a geri olayı olarak gelmez, tek sinyal pay.

## 2026-11-19 — Alt çubuk ⋯ hepsini taşır, menüler yerinde düzenlenir (dal ccr-1122edca)
- **⋯ menüsü (`editor_bar_more_menu.dart`):** taşan düğmeler + çubuktan kaldırılmış (gizli/optIn) ama bu notta çalışan HER düğme (`usable` anahtarı, AI kapalıysa AI öğeleri yok, silgi hiç). Telefonda ⋯ varsa yerinde 3 düğme. Tablette de ⋯ çıkar (yalnız menüdekiler). "Düzenle" AYNI açılır menüyü listeye çevirir: 📌 = `withVisible` (çubuk ↔ menü; yeni kayıt alanı YOK, gizli = menüde), sürükle = `barOrder`/`aiOrder` (`onReorderItem`). Açılır menü içeriğin içsel genişliğini sorar → düzen listesi sabit 280 dp `SizedBox` (kayan liste içsel genişlik veremez).
- **Not ⋮ (`ActionMenu`) yerinde düzenleme:** ayrı `_MenuLayoutEditor` levhası kalktı → `_EditableMenu` (⚙ "Menüyü düzenle" ya da karoya basılı tut). Kipte `LongPressDraggable`/`DragTarget` karolar; hızlı satıra bırakmak satıra alır (taşan son öğe ızgaraya döner), "Gizlenenler"e bırakmak gizler. Kayıt biçimi aynı (`MenuLayout`), anahtarlar `menu-visible-*`, `menu-edit-quick-*`, `menu-edit-save/reset` korundu.
- **Üst çubuk:** yinele yalnız `canRedo`; Notta ara yazarken gizli. YANLIŞ YOL: aramaya ayrı `_hideWhileTyping` (KeyboardSwitch) S45 `klavye_dizilme` 174 → 177 (Stack + 2 Offstage). Doğrusu: sabitlenin yazarken-gizle anahtarına aynı `Row`da katıldı (başlık üst çubuktayken sabitle yok → ayrı anahtar). 174 korundu.
- **"+" paneli:** birincil satır (Metin/Liste/Sıralı) en üstte; `SingleChildScrollView(reverse: true)` kalktı (kayınca da üst görünsün). `ab_hepsi` `sablon` evresi Şablon grubunu artık birincilin ALTINDA bulur (cihazda denenmedi).

## 2026-11-19 gece — Hızlı satır ☑ her türde, alt çubuk sol↔sağ, not başına menü düzeni (dal ccr-e8813ece)
- **KÖK NEDEN (☑ "menüde" ama yok):** `EditorQuickRow` düğmeyi YALNIZ geri çağrısı verilince çizer; `onCheckbox` yalnız metin notunda veriliyordu → liste notunda düğme sessizce yoktu, düzenleme levhası ise katalogdan "Menüde" gösteriyordu. Şimdi `_quickRowCheckbox` (metin: satır↔madde, liste: odaktaki maddeyi işaretle, numaralı: onay kutulu listeye çevir); belge notunda yok. GENEL KURAL: türde çizilmeyen düğme levhada `unavailable` ile "Bu notta görünmez: …" diye yazılır (`showQuickRowEditor(unavailable:)`, satır `quickRowCatalog` − çizilenler). Bekçi `menu_layout_per_note_test`.
- **Sol ↔ sağ:** ⋯ Düzenle'de grup başlıkları + düğme başına »/« (`withBarSide`, yeni kayıt yok); sağ grup boşken de başlığı durur.
- **Not başına düzen:** `Personalize.noteOverride` (SharedPreferences `note_ui_layout_v1`, not kimliği → yalnız düzen alanları: `editor.bar.*`/`editor.quick.*` gizlemeleri + `barOrder`/`aiOrder`/`quickOrder`). `Personalize.current` örtüyü önbellekli uygular; editör `enterNote(id, this)`/`leaveNote(this)` (sahip kimliği: aynı not yeniden açılırken eskinin geç dispose'u silmesin). Bildirim yalnız değer değişince (özel düzensiz nottan nota geçişte dinleyici uyanmaz — açılış bütçeleri değişmedi). Düzenleme yerleri `updateLayout` (notun düzeni varsa ona); Ayarlar → Kişiselleştir genel düzeni yazar. Seçici `NoteLayoutScopeBar` (Tümüne uygula / Yalnız bu nota / sıfırla). Firestore/göç YOK. Sınır (sabah bakılacak): yan yana iki notta son açılanın düzeni ikisinde de geçerli; silinen notun yerel düzen kaydı kalır (küçük).
