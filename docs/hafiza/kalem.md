# Hafıza — Kalem, şekil, avuç

HAFIZA.md'den cümle değiştirilmeden taşındı (F58.2, 2026-11-10). Tam eski hâl: `HAFIZA_ARSIV_3.md`.

## Kısa kurallar (sıkıştırmada tek satıra inenler)
- Kalem: ayarlar cihazda `InkToolMemory`; "yalnız kalemle yaz", yan düğme =
  geçici silgi; S Note araçları (şekil tanıma, kement, kısmi silgi, havada
  önizleme); "Kalemi otomatik algıla" varsayılan açık. Tek tepsi `PenTray`.

## 2026-11-07 — Tablet turu (HUAWEI MatePad 11, GMS'siz, M-Pencil) — kök nedenler
- **Kare tuval `Align` içinde sıkışıyordu** (iki yerde, aynı kök): `InkPageLayer(uniform)` ve kart önizlemesi (`CardPageInk`) kare `CustomPaint`'i katmanın/kutunun boyuna sıkıştırıyordu → kalem kipi kapanınca (sayfa altı boşluğu gidince) çizim dikeyde basılıp kayıyor, kartta yassı. `OverflowBox` ile kare. Kart önizlemesi çizimin tepesinden başlar.
- **Kalem tepsisi tutamağı** aşağıdayken gezinme çubuğunun İÇİNE iniyordu (dokunuş sisteme gidiyordu). Kapsül tasarımında (aşağıda) hap/kapsül hep `bottomInset + _kDockGap` üstünde durur.

## 2026-11-07 — Tablet: avuç, kalem tıkı, fiziksel klavye
- **Avuç reddi `InkController`'da (ortak):** kalem ekrandayken ya da son kalem olayından (havada yaklaşma dahil) 400 ms içinde gelen parmak = avuç: çizmez, metne/madde jestine de gitmez (`claims`). Avuç kalemden ÖNCE değdiyse kalem inince avucun işi geri alınır (`_dropPalms`). Sistemin iptal ettiği dokunuş (`pointerCancel`) çizgi bırakmaz. KÖK NEDEN: avuç "ikinci parmak" sayılıp kalemin çizgisini iptal ediyordu ("kalem algılanmıyor"). Testlerde kalemden hemen sonra parmak dokunuşu için ≥ 400 ms gerçek bekleme gerekir (`tester.runAsync`).
- **Kalem kipi kapalıyken kalemin tek başına tıkı** (son çizgiden ≥ 1,2 sn sonra, ≤ 4 dp kayma) çizmez, alttaki metne/kutucuğa gider (`stylusTapMayPass`, `_InkClaimRecognizer` artık eager değil: kayınca kazanır, kalkınca bırakır). Yazı arasındaki i/ö noktası çizilir. Tabletteki notta kalem tıklarından kalmış başıboş noktalar görüldü.

## 2026-11-08 — Kalem, satır hatırlatıcısı, bildirim düzeyi, kapanış kasması
- **Kalem kipinde geri ana ekrana atlıyordu — kök neden:** kalem kipinin `BackCloses` kaydı ALT ÇUBUKTAYDI; kalem kipinde (`_pagePen`) alt çubuk hiç kurulmuyor → kayıt yok → geri notu kapatıyordu. Kayıt artık kalem tepsisinin çevresinde; tepsinin kendi kaydı (ayar kartı, açık kapsül) içte → LIFO sıra doğru. Bekçi `editor_pen_tablet_test`.
- **Şekil/tik/çarpı önerisi** `viewers/ink_recognize.dart` (saf geometri: RDP köşe, `recognizeInkShape` uyum hatası). Öneri `InkController.suggestion` (ayrı `ValueNotifier`, çizgileri yeniden boyatmaz); işaretçi katmanda Listener'ın ÜSTÜNDE (dokunuşu çizime gitmez). ZAMANLAYICI YOK: sonraki dokunuşta/geri alda kalkar (6 sn'lik Timer testleri "pending timer" ile düşürdü). Tik/çarpı `InkToolMemory.markFix` üç durumlu: null = ilk algılamada sor, varsayılan kapalı. Harf boyu (< 36 dp) şekil sayılmaz; artı (+) çarpı sayılmaz (kollar yataya 20–70°).
- **Eke çizgi = saf değişiklik (F60.1, 2026-11-09):** sabit/gömülü PDF'e çizgi `onInkChanged` → `_updateAttachmentInk` → `_mutate(inkOnly: true)`: kök kurulmaz, kayıt debounce'lu (eskiden çizgi başına tam editör kurulumu + anında kayıt). TUZAK: kök kurulmadığı için bölme/kutunun elindeki ek BAYAT mürekkepli; oradan gelen mürekkep dışı değişiklik (sayfa çevirme, balon) çizgileri silmesin diye `_updateAttachment` `_withLiveInk`'ten geçer (`_staleInk`, kök build'inde boşalır), denetleyiciler bayat `a.ink`'i kimlikle yutar (`_inkSeen`, `_docInkSeen`). Yeni mürekkep yüzeyi eklerken ikisini de kur. Bekçi `perf_budget_test` S6/S7.
- **Sabit kalemler** `InkToolMemory.presets` (`tür|renk|kalınlık`, en çok 5, cihaz tercihi `ink_presets`).

## 2026-11-08 — Oturum C (12 maddelik istek listesi)
- **Kalem işaretçisi kök neden:** kalemin İNİŞİ önce çizimi başlatıp öneriyi siliyordu (`pointerDown` → `dismissSuggestion`), işaretçinin `onPointerUp`'ı hiç gelmiyordu. Çözüm: işaretçi inişte uygular + `InkController.claimPointer` o dokunuşu çizime vermez.
- Düzeltilmiş şekil (tik/çarpı/kare…) SEÇİLİ kalır (`_fixEdit`): kutusundan taşınır, sağ alt tutamaktan boyutlanır; tutamak kement seçiminde de var. Kare/çember eşikleri gevşetildi (açıklık %30, elips %14, dikdörtgen %9).
- Balon el yazısı: `HandwriteField` kalemi alır (parmak alana gider), 0,9 sn sonra çizgiyi PNG'ye basıp mevcut ML Kit OCR'ından geçirir — yeni bağımlılık yok; bitişik yazıda zayıf (yükseltme: ML Kit Digital Ink).
- Sabit PDF'e kalem: `PdfPageBox.ink` verilince sayfa katmanı etkileşimli; kalem kaydırmaz (`ScrollConfiguration.dragDevices`), parmak "yalnız kalem"de kaydırır. Görsel için YOK (BoxFit.contain koordinatı) — sonra.

## 2026-11-08 — Oturum D (18 maddelik ikinci tur)
- **Sabit PDF'e kalem yazmıyordu — kök neden:** `PdfPageBox._pageOverlay`'de mürekkep katmanı seçim + balon katmanlarının ALTINDA; dokunuşu seçim katmanı alıyordu. Kalem açıkken mürekkep EN ÜSTTE, seçim katmanı yok, balonlar salt okunur.
- Balondaki kalemle yaz → metin (`handwrite_field.dart`) kaldırıldı. Kalem hapı 48 dp + ayraç + 48 dp silgi hedefi. Hızlı satır: kalem yalnız simge; Fotoğraf çek, Tarih/saat ekle varsayılan; Belge tara sonradan eklenir. Satır hatırlatıcı çipi 22 dp sabit, ilk satıra ortalı; dokun = menü (zaman, tamamlandı, ayrıntı, SİL + geri al).

## 2026-11-08 — Oturum E (15+2 maddelik üçüncü tur)
- **Kalem:** hızlı satırdaki kalem aç/kapa (`_togglePen`, diğer yollar `_openPen` = aç). Parmak var olan çizgide 550 ms kıpırdamadan durursa `InkController.eraserOffer` → silgi düğmesi (inişte kabul + `claimPointer`); yakınlık yeni nokta eklenmeden ölçülür.

## 2026-11-09 — Oturum G (yorum analizi: çokgen, çizgi ucu, son yazı biçimi)
- **Çokgen (F55.3):** `recognizeClosedShape` elips kazanınca (ya da hiçbiri tutmayınca) düzgün 5–7-gen dener (`_regularPolygonFit`: alan merkezi, ortalama yarıçap, 24 dönüş adımı, ≤ 64 nokta). Kabul: hata ≤ 0,05 VE elipsin %60'ından az VE dikdörtgen/dörtgen/üçgenden iyi. **Sekizgen bilerek YOK:** ölçüldü, düzgün sekizgende oran 0,62 — eşiği gevşetmek elle çizilmiş daireyi çokgene çevirir. `InkFixKind.polygon` (simge `pentagon_outlined`).
- **Düz çizgi ucu (F55.2):** uçta bekleyip çizgiye oturunca (`_snapActive`) kaleme uzak uç `_snapLineFrom`'da sabit, yakın uç `pointerMove`'da kalemi izler; kalkınca/yeni çizgide sıfırlanır. Kapalı şekillerde yok.
- **Bilerek yapılmadı:** F55.1 parmağa silgi (avuç içi çizgi silebilir, tek parmak kaydırma ile çakışır — tablette denenmeden yazılmaz); F57.1/F57.2 sürüm notu/taşınan düğme ipucu (tek kullanıcı, her oturuma kalıcı yük — gereksiz); web tarayıcı geri tuşu tam ekranı kapatmıyor (go_router popstate + `HomeFirstHistory`'ye dokunur, getirisi düşük).

## 2026-11-09 — Oturum H (tablet cihaz turu dönüşü)
- **Kalem yazar/dokunur yüzen düğmesi** (`editor/stylus_toggle.dart`): `InkToolMemory.autoStylus` + `autoStylusListenable`; yer ekran oranı (`penToggleAt`), yalnız bir kez kalem görülen cihazda (`stylusEver`, editörün `_onContentPointerDown`'ı yazar). Kapanınca editör kalem kipi de kapanır. KÖK NEDEN ("kalemle metne dokunamıyorum"): `autoStylus` açıkken kalem, kalem kipi kapalı olsa da sayfaya çiziyordu (`_syncPageInkKinds`).
- **Sabit PDF'e kalem**: `_penOn` artık `autoStylus` ile de açık; kip yokken `allowedKinds` yalnız kalem, `dragDevices` parmak/fare kaydırır.
- **Gömülü PDF'e kalem**: `NotePageCanvas._docInk` (ek başına `InkController`, yalnız kalem) + `PdfPageBox` kapak kutusunda da `ink` alır. Sayfa mürekkebi üstte olduğu için `InkExclusionZone` (page_ink_layer): bölgedeki nokta `_SkipExclusions` isabet testinde sayfa katmanına HİÇ ulaşmaz. TUZAK: Listener sırası en derinden başlar — "üstteki katman sonra claim etsin" çalışmaz, isabet testinde kesilmeli.
- **Şekil**: eksene oturtma 25° (`kInkSnapDegrees`, `_levelOutline` üçgen/dörtgen/çokgende en yatay kenar); çarpı gevşek (`_roughlyStraight`, 15–75°, kesişim 0,15–0,85, oran 0,4–2,5) + tek çizgili çarpı (`_dropCollinear` — RDP eşit uzaklıkta fazladan köşe bırakıyor). Seçimde ÜST ORTA döndürme tutamağı (piksel uzayında döner), çizgiye ÇİFT DOKUNUŞ yeniden seçer (dokunuş noktaları geri alınır).

## 2026-11-09 — Oturum J (tablet senkron + hızlı satır sadeleşmesi)
- **Kalem kipi**: her açılışta `_penModeOpened` "yalnız kalem" durumunu + "Ayarla" söyler (eski tek seferlik `tipPenToggle`/`tipPagePen` yerine) ve `autoStylus`'u açar; yüzen kalem "yazar"a dönünce metin/liste notunda kip açılır.


## 2026-11-10 — P05 (tek araç durumu, `PenPolicy`)
- **Araç tek yerde (F63.2):** `InkController`'ın araç alanları (silgi/ok/şekil/kement/tür/renk/kalınlık/yalnız kalem…) alan DEĞİL, `InkToolMemory`'yi okuyan getter; değişiklik `_toolChanged()` → `InkToolMemory.toolRev` ile bütün açık denetleyicilere gider. KÖK NEDEN ("gömülüde silgi seçili, kalem yazıyor"): araç kurulumda kopyalanıyordu, tepsi yalnız sayfa denetleyicisini sürüyordu. TUZAK: araç artık testler arası da ortak — denetleyiciyi `dispose` etmeyen test `setUp(InkToolMemory.reset)` ister (geçici araç ancak açık denetleyici kalmayınca kaleme döner, `openSession`). Etkin yüzey `InkController.active`; kalem kuralı (`allowedKinds`, katman, parmak kaydırır mı) yalnız `viewers/pen_policy.dart`'tan (bekçi `pen_policy_test`).

## 2026-11-11 — P15 (kalem akışları: sabit görsel, tam ekran, telefon)
- **Sabit görsele kalem (F63.3):** `pinned_media_pane._imageInkLayer` — görselin `contain` dikdörtgeninde (`_imageRect`), yakınlaştırmanın (`WheelScrollViewer`) İÇİNDE; `InkClaim` kalemi/izinli parmağı üstlenir (dokunuş görüntüleyiciyi açmaz), parmak çizerken iki parmak için sarmalamayan `InkNavLayer` kardeşi. KÖK: `_ImageBox` çizimi kutunun TAMAMINA boyuyordu → sabit bölmede `NoteMediaBox(imageInk: false)`, çizimi bölme boyar. Balon bırakma kipinde kalem kapalı.
- **Tam ekranda yüzen düğme (F63.4):** `viewers/viewer_pen.dart` `ViewerPen` karışımı (PDF/görsel/slayt). `PenPolicy.viewer` = sabit belge kuralı. Karışım `setState`'i sarar: ekranların kendi `_ink.setEditing(...)` çağrılarından sonra `syncPen()` son sözü söyler — yeni kip eklerken `setEditing`'i elle çağırmak yetmez, kip `setState`'ten geçmeli (balon bırakma `addingListenable`'dan dinlenir). `stylusEver` artık `InkController.pointerDown`'da da yazılır.
- **TUZAK (test):** avuç reddi (`isPalm`) GERÇEK saate bakar; widget testinde kalemden sonra parmak dokunuşu 400 ms yutulur → `tester.runAsync(Future.delayed)`.
- **Telefon (F63.5):** kalem kipi parmakla açılınca `TipOnce.penTwoFinger`. Alt çubukta kalem YOK (K-O5 açık). Sayfa altı boşluğu `viewport * 0.7` — telefonda yeterli, dokunulmadı.

## 2026-11-13 — Sabit PDF: silgiye basınca yazılar kayboluyordu + renk
- **KÖK:** editör eke yazılan çizgide kökü KURMAZ (F60.1 `_updateAttachmentInk`, inkOnly) → `PinnedMediaPane.widget.media` / `NoteImages` eki ESKİ çizgi listesini tutar. `_inkFor`'un "görülen liste"si (`_inkSeen`, `_docInkSeen`) çizimde denetleyicinin listesine çekiliyordu; sonraki her yeniden çizimde (silgi, ✏, yüzen düğme) eski liste "dışarıdan değişti" sanılıp `replace` ile geri yazılıyor, çizgiler siliniyor; kök kurulunca geri geliyordu. **KURAL:** görülen liste YALNIZ ekin kendi listesinden güncellenir, `onChanged`'de dokunulmaz (`replace` içerik aynıysa zaten işlem yapmaz). Bekçi: `pinned_image_ink_test` "bayat ek".
- Hızlı kalem çubuğu: silgi açıkken dolu `primary` zemin (`_BarButton.filled`), `_InkColorMenu` (MenuAnchor, `kInkPalette`), geniş çubukta (≥ 600) 4 hızlı renk (`_quickInkColors`, tepsiyle aynı kural). Cihazda doğrulanmadı (KALANLAR L10).

- **2. tur (2026-11-13):** kısmi silgi parçaları ÖZGÜN noktalardan/basınçtan kesilir (örneklenmiş liste basıncı düşürüp dolma kalemin hız inceltmesini bozuyordu → yazı boyu değişiyordu); seyrek parçada silgi iki nokta arasından geçerse orada kesilir. Komşu sayfaya taşan çizgi (y<0/y>1) `_pageShift` ile ±1 sayfa kaydırılarak silinir. Yüzen düğme: `_BlinkOnce` (kalıcı `toggleBlinked`; `reset()` testte true), `_FingerWritesChip` (autoStylus && !penOnly). Bekçiler: `ink_eraser_fix_test`, `stylus_toggle_hints_test`.

## 2026-11-14 — P59 silgiden kaleme dönüş
- Silgideyken (geçici kalem-düğmesi silgisi DEĞİL) inişte `_eraserHold` → 550 ms kıpırdamazsa `_offerPen`: basılı tutuşun sildiği çizgiler `_gestureBase`'den geri, `penOffer` → "Kaleme dön" (`acceptPenOffer` = `setPen(pen)`); `_snapped` parmak kalkana dek silmeyi durdurur. İki öneri tek `ListenableBuilder(controller.offers)` — ayrı dinleyici S18 ilk karesini 1 artırıyordu.
