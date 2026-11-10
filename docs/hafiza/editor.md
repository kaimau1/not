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
- Yazım düzelt: `core/utils/spell_fix.dart` (saf kurallar, testli) + `auto_spell.dart` (aktif alana `_setFormatTarget`'tan bağlanır, başlık hariç; Android'de `DefaultSpellCheckService` ilk önerisi, Levenshtein ≤2). Tek karakter yazımında çalışır; yapıştırma/dikte dokunulmaz.
- Not paketi: metinde `AttachmentKind.text` + `extras.package` (etiketi `📎 ad`, ADLA eşleşir → `packageName` çakışmada numaralar); listede `NoteItem.package` (kapalı paket: ilk satır özet, kalanlar SIFIR yükseklik — sürükleme dizinleri bozulmasın diye satır kaldırılmaz; açıkken `TapRegion` dışarı dokununca daraltır).

## 2026-11-08 — Oturum D (18 maddelik ikinci tur)
- **Not paketi kendiliğinden kalkıyordu — kök neden:** `_sameItem` (text_merge), `ItemsEditor._sameItems`, `sameItemsVisually` `package` alanına bakmıyordu → birleştirme yerelin paketlemesini "değişmedi" sayıp uzaktaki paketsiz kopyayı yazıyordu. Yeni GÖRÜNÜR madde alanı → bu ÜÇÜNE de ekle. Açık pakette Enter/yeni madde paketi miras alır; paketin boş son maddesinde Enter paketten çıkarır.
- **Esc = geri:** `EscBackIntent` (app.dart `shortcuts`) — `DismissIntent`'e BAĞLAMA: metin alanı odaktayken `EditableText`'in DismissIntent eylemi `Actions.invoke` ile sayfa rotasının DEVRE DIŞI eyleminde durur, Esc hiçbir şey yapmaz. Eylem: açılır rota (PopupRoute) → kapat; değilse kök yönlendiricinin `backButtonDispatcher.invokeCallback`.
- **Tablette hızlı satır gelmiyordu:** yüzen/ayrık/fiziksel klavyede `viewInsets.bottom` 0. `KeyboardSwitch(editing:)` tablette (en kısa kenar ≥ 600, web değil) alan odaktaysa da açar (`_fieldFocusedN`, FocusManager dinleyicisi). Test yüzeyi 800×600 = TABLET sayılır: telefon davranışı testlerinde `tester.view.physicalSize = 400×800`.
- **Sürükleme tutamağı** web/tablette hep görünür (`_pinHandles`, satır önbelleği ortam anahtarında); soldaki 12 dp dolgu 2'ye iner.
- **Öğrenen yazım düzeltme** (`core/utils/spell_learn.dart`, saf; `auto_spell.dart` bağlar): kişisel sözlük (yazılan + notlardan `seedCounts`, `compute` ile oturumda bir kez) + kelime düzeltmeleri (biten kelimeye geri dönüp değiştirme = öğren; otomatik düzeltmeyi geri alma = `reject`, bir daha dokunma) + harf karışıklıkları (`alignSubstitutions` → `confusions`, mesafede ucuzlar). Klavye düzenli ağırlıklı Damerau–Levenshtein (`keyCost`: komşu 0,45, şapka 0,3, boşluk komşusu cvbnm). Boşluk yerine n: `splitMissedSpace` (iki parça da bilinen) + Android'de cihaz denetçisiyle `_nativeSplit`. TÜRKÇE EK TUZAĞI: aday yazılanın ön eki/uzantısıysa ("kalemi"/"kalem") düzeltilmez; yalnız yazılmış kelime 3 görülmeden "bilinen" sayılmaz. Çince: bulanık yok, yalnız açık düzeltme. Hafıza dosyada (`appSupportPath/spell_memory.json`, web'de tercih), 4 sn erteli yazma. Başlık: `titleFixAt` (kelime başı büyük) + `textCapitalization.words`. Hızlı satırda yazım düğmesine basılı tut = ayarlar levhası.
- Alt çubuk yazarken 1,1 sn sonra; yeni alana geçince ve klavye kapanınca (KeyboardSnap builder'ında inset 0) HEMEN (`_showBarNow`).

## 2026-11-08 — Oturum E (15+2 maddelik üçüncü tur)
- Alt çubuk 50 dp; yazarken gizleme 3 art arda değişiklikten sonra (`_typedBurst`). Seçim çubuğunda "Pakete al" (`togglePackage`), düğmeler compact. Kısayol adı/simgesi `stripRichMarkers`. Gmail "İletiyi çevir/Orijinali göster" (Gemini `translateText`, bir kez çevrilir). Klasör çekiş menüsünde Yeni klasör + Sırala·sil (`FolderOrderPanel` satırında sil). 5 sade klasik tema (`classic/newsprint/notebook/graphite/ledger`, koyu = beyazın koyusu; vurgu doygunluğu > 0,2 testi).

## 2026-11-09 — Oturum F (yeni özellik denetimi)
- **Yazım öğrenme TUZAĞI:** öğrenilmiş düzeltme BİLİNEN kelimede de uygulanır (`suggest`, best ≥ 2) → klavye önerisinden öğrenme (`replacedWord`) bilinen kelimede kapalı ("kalemi" → "kalemde" ek değişimi her geçerli "kalemi"yi bozacaktı).
- **Uzun liste notunda not içi arama eksikti:** `searchFields` yalnız kurulmuş satırların denetleyicisini veriyordu → ekran dışı maddeler aranmıyordu; artık hepsi (`_controllerFor`). Kurulmamış satıra gidiş `ItemsEditorState.revealItem/revealFocus`: satırın bağlamı yoksa EN YAKIN GERÇEKTEN KAYAN ataya (liste çoğu kipte uzunluğu 0 olan iç Scrollable) tahmini konuma atla + kare bekle, en çok 4 deneme.
- Not rotası yeni parametreler: `?item=<madde>` (zamanı gelenler şeridi), `?find=<sorgu>` (F56.1, kilitli notta taşınmaz).
- **Üstüne yazı (açık metin) her görünümde:** `AttachmentAction.addText` (şerit/gömülü/sağ tık menüsü; yüzen ve sabitte menüde değil çubukta "T"). Tam ekran `ImageViewerScreen/PdfViewerScreen(startText:)` açık metin bırakma kipiyle açılır; PDF tam ekranda ayrıca "T" düğmesi (`pdf-quick-text`; balon düğmesi artık `plainMode` false yapar). Sabit bölme: `pinned-quick-text` → `_startAdding(plain: true)`.

## 2026-11-09 — Oturum H (tablet cihaz turu dönüşü)
- **Tablet klavye karmaşası** KÖK NEDEN: `SplitShell._split` Scaffold'u gövdeyi klavyede kısaltıyordu → listenin `removeViewInsets` sarması boşa; `resizeToAvoidBottomInset: false` (editör `KeyboardSnap`, defter kendi Scaffold'u).
- **Esc** KÖK NEDEN: editörün `CallbackShortcuts` Esc'i `Navigator.maybePop` ile yutuyordu (kabuk iç gezgini tek sayfa) → kaldırıldı, uygulama `EscBackAction` (geri dağıtıcı) çalışır.
- **Paket**: × ile çöz (`unpackGroup`). Kasma izole ölçümde ÜRETİLEMEDİ (30 madde, açık/kapalı paket, yazarken fazladan satır kurulumu yok) — cihazda hangi adımda olduğu bekleniyor.

## 2026-11-09 — Oturum J (tablet senkron + hızlı satır sadeleşmesi)
- **Fiziksel klavye + sanal klavye döngüsü** KÖK NEDEN: Bluetooth klavye boşta uyuyunca Android "çıkarıldı" bildiriyor → `HardKeyboard` platform girişine dönüp sanal klavyeyi açıyordu, tuşla uyanınca geri. `HardKeyboard.report`: son tuştan 15 dk içinde gelen "çıktı" yok sayılır, süre dolunca yerel durum yeniden sorulur.
- **Hızlı satır sade varsayılan**: pen · spell · package · attach (Ekle levhası) · bold · color; gerisi `UiItem.optIn`. Renk düğmesi `NoteFormatMemory.favoriteColor` (1 = palet kırmızısı, özel renk ARGB); basılı tut `showColorPaletteSheet` → favori.
- **Yazım**: `SpellMemory.changesTooMuch` (düz Levenshtein > uzunluk/3) bulanık + cihaz önerisini keser (öğretilen düzeltmeler hariç); otomatik düzeltmenin üstüne başka kelime yazılınca `unlearnFix`.

## 2026-11-09 — Baştan sona inceleme → `OTURTMA_PLANI.md` (Faz 58–69)
- **Koddan doğrulanan kökler (düzeltilmedi, plan maddesi):** (1) sabit/gömülü eke her çizgi `_updateAttachment` → `_mutate(immediate: true)` → `_sameVisual`'da `identical(attachments)` false → editörün TAMAMI kurulur + anında tam kayıt (F60.1). (2) Mürekkep `double` dizisi (nokta başına 16–24 bayt), notun tüm mürekkebi tek `heavy/data` belgesinde; her kayıt hepsini ana iş parçacığında gezer/kodlar; 1 MiB'e ~1–2 ekran yoğun el yazısında dayanır (hesap; F61.0 ölçer). (3) `InkPainter` her kalem hareketinde sayfanın bütün çizgilerini boyar; basınçlı çizgi nokta başına `drawLine` (Faz 62). (4) Paket: açık paketin `TapRegion` grubunda yalnız paket satırları var — araç çubuğuna dokunmak paketi kapatıyor olabilir (hipotez, F60.2). (5) Ana ekran tepesi telefonda sabit `Column` (~210 dp), kaydırınca çekilmiyor (F66.1).
- **F60.S2 "gir-çıkla artan klavye kasması" (2026-11-10):** dinleyici/nesne sızıntısı cihazsız YOK — `test/editor_leak_test.dart` (gerçek kabuk, 28 aç-kapa, 6 not türü) nesne, genel dinleyici ve klavye turu kurulumlarında artış görmedi; yeniden "sızıntı" aramadan önce cihazda taze ↔ 30 gir-çık sonrası `ab_klavye.py` farkını ölç. Sızıntı bekçisi kalıbı: `FlutterMemoryAllocations` ile yaratılan − atılan, tür başına BÜYÜME (sabit kalıntı ve Layer/Picture sayılmaz).

