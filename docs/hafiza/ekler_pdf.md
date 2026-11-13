# Hafıza — PDF, balon, görüntüleyici, ek modeli

HAFIZA.md'den cümle değiştirilmeden taşındı (F58.2, 2026-11-10). Tam eski hâl: `HAFIZA_ARSIV_3.md`.

## PDF, balon, görüntüleyici
- **SABİT/GÖMÜLÜ PDF'E KALEM YAZMIYORDU (2026-11-10, cihazda `adb shell input stylus swipe` ile doğrulandı):** `InkPageLayer` `IgnorePointer(ignoring: !controller.editing)`; sabit (`pinned_media_pane._inkFor`), gömülü (`note_images._docInkFor`) ve not paketi denetleyicisi `setEditing(true)` almıyordu → kalem kipi açılıyor, hiçbir girdi iz bırakmıyordu. Bekçi `test/ink_editing_guard_test.dart` (InkController kuran her dosya `setEditing(` çağırır). Aynı turda: `penOnly` her build'de `InkToolMemory`'den (kurulum kopyası bayattı), dışarıdan değişen çizgi (tam ekran/geri al) `replace` ile alınır (kimlik `_inkSeen` + içerik), yüzen düğme "dokunur" → `_ownPen=false`, kalemsiz cihazda otomatik kalem katmanı yok (basılı tut seçim parmakta kalsın: katman varken `pdf_page_box` seçim katmanını kaldırır), avuç reddi `InkClaim` (gövdedeki `_InkClaimRecognizer`), tam ekran `initialPage: pdfPage` + `onPageChanged` (⛶ yolu `note_editor_embed`; ⋮ yolu zaten veriyordu), sayfa dibinde/tepesinde dikey çekişle sayfa geçişi (`_onPageScroll`, yalnız sürüklemede). Plan ve kalan fazlar `KALEM_PLANI.md`. Tablette kalem: `input stylus …`, parmak: `input touchscreen …`.
- PDF YAZMA yalnız Syncfusion (`pdf_edit.dart`, `NotePdf`), görüntüleme pdfrx;
  gömülü PT Sans şart. `PdfBitmap` yalnız JPEG/PNG.
- pdfrx'in kendi metin seçimi KAPALI (seçim `PdfSelectLayer`);
  `scrollPhysics` VER; `pageOverlaysBuilder` her matris değişiminde çağrılır
  → `pdfLayerParams` sayfa başına aynı örnek.
- Dışarı dokununca kapatma `GestureDetector(onTap)` ile değil, ham
  `Listener` (`TapToCollapse`). Çizim PDF'e gömülmez (ayrı katman).
- Bölme yazımları CANLI ek taşır (`_live()`); `dispose`ta kayıt yapma.
- **PDF okuma notu** (2026-11-03): sabit bölmede PDF GENİŞLİĞE oturur
  (`PdfPageBox.fitWidth`, sayfa dikeyde kayar; mürekkep sayfa katmanında)
  ve basılı tutunca `PdfSelectLayer` seçer → tepede "Not al · Kopyala ·
  Vurgula". Not satırı `📖 s.12 · 5. satır “alıntı”` (`core/utils/pdf_ref.dart`;
  satır = aynı sütundaki parça bantları, `pdfLineNumber`); referans
  `linkSpans`ta damga gibi çizilir, dokununca sabit/ilk PDF'in `pdfPage`i
  yazılır. Çubuktaki "Not al" seçimsiz o anki sayfa. Okuma kipinde
  yakınlaştırma (`InteractiveViewer`, yakınken çevirme/kaydırma kilitli,
  çift dokunuş 2,5×), şerit saydam hap ve 2,5 sn'de söner, "balon ekle"
  düğmesi katmanı düzenlenebilir yapar. Seçim tutamacı `EagerGestureRecognizer`
  + `Listener` (onPan kaydırmaya yeniliyordu).
- **Web fare tekerleği** (2026-11-03): `InteractiveViewer` tekerlek sinyalini
  PointerSignalResolver'sız DOĞRUDAN zoom sayar → sabit PDF'te tekerlek hep
  zoom yapıyor, yakınlaşınca kaydırma da kilitleniyordu. `WheelScrollViewer`
  (core/widgets) sarar: tekerlek kaydırır, zoom yalnız Ctrl+tekerlek;
  dokunmatik/trackpad dokunulmaz. Slayt `ZoomBox`/resim görüntüleyicide
  tekerlek zoom'u bilerek kalıyor. `scaleFactor`'ı büyütme: pinch ataleti bozulur.
- Balonlu/klasik BAŞLANGIÇ sorusu yok (2026-11-03): içerikten not hep
  klasik; "BALONLU PDF" kart rozeti ve ayardaki kip satırı kalktı.
- **BALONLU GÖRÜNÜM KALKTI** (2026-11-05, kullanıcı: "tek mod sabitleme,
  balon ekleme orada"): anahtar Sabit · Yüzen · Ek. Eski belge notu
  (`NoteType.pdf/slides`) editörde açılınca (ağır alanlar gelince, salt
  okunur değilse) `_retireBubbleView`: klasiğe döner, belge (görselden
  türetilmişse görsel) sabitlenir, sayfa notları gövdeye `📖 s.N` satırı
  (`movePageNotesToBody`, harita boş dizgiyle). Sabit PDF'te "Balon ekle"
  vardı; sabit görselde de var (balonlar görselin KENDİ ekinde, page 1 —
  ilk düzenlemede türetilmiş belgenin balonları görsele taşınır). Salt
  okunur ortak notta eski balonlu görünüm hâlâ çizilir (yazılamaz).
- **JEST KURALI — GEÇERLİ** (2026-11-05 akşam, kullanıcı kararı; aşağıdaki
  "basılı tut = balon"un YERİNE): her yüzeyde (sabit PDF/görsel, tam ekran
  PDF, slayt) **basılı tut = metin seçimi** (görselde OCR seçim ekranı,
  `onExtractText`), **çift dokunuş = yakınlaştır** (`PdfSelectLayer.
  doubleTapSelects: false`, tam ekranda `pdfDoubleTapZoom`), **balon yalnız
  düğmeyle**: bölme çubuğundaki "Balon ekle" menüsü Balon · Açık metin
  (`addingPlain`) → bırakma kipi, dokunarak. `BubblePageLayer.longPressAdd`
  varsayılanı false, hiçbir yüzey açmıyor. Balon yazılırken sabit bölme
  çubuğu ve alttaki notu gizler (`Offstage`, yer kaplamaz), medya tüm
  bölmeyi alır, editör alt çubuğu `_setImmersiveBubble` ile gizlenir; kart
  kompakt (yazı 1→4 satır, başlık şeridi ~34 dp). TUZAK: yazma bitince
  `KeyboardClipWindow` canlandırılırsa tam boydan iner, çubuk+not bir kare
  taşar → `_snapWindow` ile atlar.
- (ESKİ, yerine yukarıdaki) **SABİT KİP TEK DAVRANIŞ** (2026-11-05, "balonlar taşınamıyor, uzun
  basış metin tanıyor"): yazılabilir sabit PDF/görselde balonlar HEP
  düzenlenebilir (`PdfPageBox.editBubbles`): basılı tut = balon bırak,
  tutamaç basılı tutulup taşınır, okuma kartında Düzenle + Sil; seçim çift
  dokunuşla (yazı yoksa çift dokunuş zoom); görselde iki parmak zoom
  (`WheelScrollViewer`, balonlar içinde). "Balon ekle" (dokunarak bırakma)
  bölme çubuğunda, PDF'e `addingBubbles` ile bağlı; kip denetleyicinin
  `adding`i (ayrı bayrak tutma: "Bitti" düğmesi kapatmıyordu). Görselde
  dokunuş açık kartı kapatır, görüntüleyiciyi açmaz (durum `Listener`
  ile parmak İNERKEN okunur).
- Görsele çizim + açık metin (`PageBubble.plain`) dışa aktarmada/paylaşımda
  görselin üstüne BASILIR (`image_annotations.dart`, PNG; F18.13).

- **OCR çipi sonsuz dönüyordu — KÖK NEDEN** (2026-11-05): `forPage`ta
  `whenComplete(() => _inFlight.remove(key))` ok gövdesi haritadaki
  geleceğin KENDİSİNİ döndürüyor, `whenComplete` onu bekliyor → gelecek
  kendini bekler, hiç bitmez (sonuç önbelleğe yine yazılır: yeniden girişte
  "tanınmış"). TUZAK: `whenComplete`/`then` içinde `remove` ok gövdesiyle
  döndürme, blok yaz. Ek savunma `PdfPageOcr.completed` + `peek`.
- Taranmış PDF OCR (2026-11-03): işler TEK KUYRUKTA + 40 sn zaman aşımı
  (eşzamanlı çizim+ML Kit ilk açılışta takılıyordu); disk önbellek anahtarı
  `v2`, damga yalnız dosya BOYU (mtime yeniden indirmede değişip her açılışta
  baştan tanıtıyordu).

- **Balon yazma kartı geri tuşu** (2026-11-05 gece): `BubbleDock` açıkken
  kendi `PopScope(canPop: false)`ı var, geri = "Bitti". Kart `_DockEntrance`
  ile 200 ms alttan süzülür (yalnız boyama). Bölmenin açılış/kapanış
  geçişi bilerek ANLIK: pencereyi canlandırmak klavye oturmasıyla çakışıp
  sütunu birkaç kare taşırıyor.
- **PDF kaydırma kasması** (2026-11-05 gece): `PdfSelectLayer` sayfa
  metnini `initState`te değil ~500 ms görünür kalınca ya da parmak değince
  yükler (`_loadText`) — kaydırırken her sayfa pdfium işçisine metin işi
  ekleyip görüntüleri geciktiriyordu. Metin gelmeden uzun basış OCR'a
  DÜŞMEZ, yüklenince seçer. Sabit PDF'te sayfa `RepaintBoundary`, ilerlemeli
  yükleme olayları 150 ms'de bir `setState`.

## Kısa kurallar (sıkıştırmada tek satıra inenler)
- Ek açıklaması `Attachment.caption` (yalnız doluyken; `withLayoutOf` yereli
  korur), ses dalgası `wave`, not teması `theme` (zemin RENGİ seçen her yol
  `theme: ''` yazar; `noteSurface` temanın alt tonunu verir).
- Dinleme alanı tek kart `ListeningCard`; başlık düğmesi
  `ListeningHeaderButton` (34 dp).
- Balon paleti koyu tonlar; eski amber ekranda yeni varsayılanla çizilir.
  `BubbleController._sameContent` başlık/acil/ok/biçimi de karşılaştırır.
- Tek avatar (rozet = yalnız arkadaşlık isteği); geniş ekranda rayda olan
  kapı ⋮'te tekrarlanmaz (`AppRailScope.visible`). Avatar levhasında
  "Hesap değiştir" + "Oturumu kapat" (`sign_out_actions.dart`, Ayarlar da
  aynı kapı; misafirde kırmızı uyarı).
- `KALANLAR.md` tek cihaz doğrulama listesi; eski turlar `KALANLAR_ARSIV.md`.

- **Ek senkronu — TEK YOL (F28.2/F19.E1, 2026-11-06, kullanıcı kararı "herkese aç + eskiyi sil"):** `UploadQueue` + `DriveStore` tek kuyruk; Drive yüklemesi `drive.file` ile kökteki GÖRÜNÜR "Notlar" klasörüne (`ensureFolder`, oturumda önbellek). Kapsam ikisi birden (`kDriveScopes` = file + appdata) TEK jetonla: eski gizli klasördeki ekler kimlikle okunmaya devam eder, göç/sıfırlama YOK (kayıt silinmedi). KÖK NEDEN ("telefondaki ek web'e gelmiyor / sürekli bekliyor"): Google hesabında ekler yalnız Ayarlar'da elle "Bağla" denince yükleniyordu → artık `DriveConnectedNotifier` izin önceden verilmişse sessiz bağlanır, ana ekran şeridi bekleyen ek varken izni oturumda bir kez kendisi sorar, `no-token` hatası bağlantıyı düşürür (şerit yeniden sorar). Görsele ≤ 40 KB önizleme `users/{uid}/thumbs/{ekId}.jpg` → `Attachment.thumbUrl`: kart her yerde, web'de izinsiz hemen; `WebDriveGate` asıl dosya inene dek önizlemeyi çizer. Web yüklemesi BİLİNÇLİ olarak Storage'da kaldı (web jetonu ~55 dk + açılır pencere ister). Bayraklı ikinci motor (`attachment_sync_service`, `drive_files_api`, `domain/attachment_sync`, sıfırlama göçü, Ayarlar deneme anahtarı) SİLİNDİ; jeton önbelleği `ScopeTokenCache` (`google_scope_auth.dart`, Gmail kullanır). TUZAK: Storage kuralları OR'lanır; genel `users/{uid}/**` 50 MB kuralı thumbs yolunu dışlamazsa 40 KB tavanı boşa düşer. Tahmin (doğrulanmadı): `drive.file` erişimi Cloud PROJESİ düzeyinde — web istemcisi Android'in açtığı dosyayı okuyabilir. İKİNCİ KÖK NEDEN (cihazda, v1.2.1): izinsizken düşen deneme üstel beklemeye giriyor, `UploadQueue`'da zamanlayıcı olmadığı için bir sonraki not değişikliğine dek HİÇ denenmiyordu → `_scheduleRetry` + bağlantı gelince `_lastFailure.clear()`; Drive adımlarında zaman aşımı + `ErrorLog` (`upload`, `thumb-upload`). Cihazda doğrulama yöntemi: Firebase CLI oturumuyla Firestore REST (`firebase-tools/lib/auth.js` `getAccessToken`) → ekte `driveId`/`thumbUrl`; başka cihaz benzetimi = aynı `driveId`li, telefonda dosyası olmayan kayıt yazmak.
- **Ek görünüm geçişinde Geri al (2026-11-06, kullanıcı bulgusu):** `_setAttachmentView` eki nottan id ile GÜNCEL hâline çözer. KÖK NEDEN: Geri al geçişten önceki kopyayla çağrılıyordu → `_viewOf` hâlâ "sabit" deyip `from == view` erken dönüyordu (bütün kip geçişlerinde). TUZAK: kapanışta (bildirim eylemi) yakalanan `Attachment` bayattır; kimlikle yeniden oku.
- **Geri önce paneli kapatır — GENEL (2026-11-06, kullanıcı: "tek tek değil hepsi"):** `core/widgets/back_closes.dart` `BackCloses(open, onClose)`: rota içi panel açıkken kaydolur (LIFO), geri yalnız SON açılanı kapatır (aynı olayda ikincisi `_consumed` ile atlanır). Ekranın kendi `PopScope`u (editör, ana ekran, madde seçimi) işe başlamadan `BackCloses.handling(context)` sorar. Bağlı: ek şeridi (yalnız BU ekranda açıldıysa — kalıcı tercihle açık gelen yakalamaz, `_stripOpenedHere`), sayfa üstüne yazma kipi, kalem tepsisi paneli, biçim çubuğu tepsisi, sayfa notu alanı, takvim ay paneli. YENİ satır içi panel eklersen `BackCloses` ile sar (gövde yoksa `child: SizedBox.shrink()`).

## 2026-11-07 — Klasör şeridi sabit, sabit bölmede PDF şeridi alt satırda, izinsiz tarama
- **Sabit bölmede PDF:** kutunun yüzen gri şeridi yok; `PdfBoxBar` köprüsüyle balon göster/gizle · yer imi (≥400 dp) · belge menüsü (📖) bölme çubuğunda. Dar çubukta "Not al" yazısı düşer (<420 dp). Yüzen kutuda (sayfa içi) eski şerit duruyor.
- **Sabit PDF sürekli dikey (F65.8, 2026-11-10):** `fitWidth` kipi `PdfPageColumn` (tembel `ListView.builder` + `itemExtentBuilder`; boy = genişlik × oran + 8, ölçüsüz sayfa ilk sayfanın oranı); ‹ n/N › çubuktan çıktı → sağ altta `PdfPagePill` (renk alfası, Opacity yok). Kaydırırken kök `setState` YOK (`_pageShown`/`_pillLit` notifier); `pdfPage` yalnız `ScrollEnd`'de yazılır. Atlama `_columnKey.currentState.showPage`. Tuzak: ilerlemeli yüklemede üstteki sayfanın boyu değişirse ofset kayar (çoğu belge tek boy; sabah bakılacak değil, bilinen sınır).
- **Belge tarama izinsiz** (dosya-okuyucu davranışı): `cunning_document_scanner` `getPictures` önce kamera izni istiyor, reddedince fırlatıyordu; Google tarayıcısı izinsiz çalışır. `DocumentScan.scanPages` eklentinin kanalını doğrudan çağırır; PlatformException'da eski izinli yola düşer. TUZAK: Play Hizmetleri olmayan cihazda eklentinin kendi kameralı yedek etkinliği izin isteyebilir (cihazda doğrulanmadı).

## 2026-11-07 — Tablet turu (HUAWEI MatePad 11, GMS'siz, M-Pencil) — kök nedenler
- **Veri kaybı — ek yüklemesi el yazısını siliyordu:** `Note.attachments` sayfa üstü el yazısı kaydını (`_page_ink`) İÇERMEZ; `patchAttachment`/`patchAttachmentSync`/yerel `appendAttachments`/YouTube metni listeyi ondan kurup yazınca bütün el yazısı gidiyordu (görsel Drive'a yüklenir yüklenmez). Ek listesini yeniden yazan HER yol `note.attachmentsField([...])` kullanır. Bekçi: `notes_repository_data_test` "el yazısı korunur". Eski sürümlerde bu yolla kaybolan çizim geri gelmez.

## 2026-11-08 — Oturum B (arama, yazı tipi, Gmail, takvim pratikliği)
- **Arama çubuğu:** tüm hap tek `GestureDetector` iken sağdaki düğmelerin boşluğu da aramayı başlatıyordu; odak jesti yalnız sol kısımda (`_SearchField`).
- **Seçim modu + geri:** tek seçim modu ana ekranda (`selectedNoteIdsProvider`; PopScope VAR) ve madde seçimi; PDF sayfa düzenleyicisine PopScope eklendi. Klavye açıkken ilk geri klavyeyi kapatır (sistem), ikincisi seçimi.
- **Hayalet ek sayacı:** editör ataç rozeti/şeridi zemin görselini (`backgroundImageId`) ek sayıyordu; kart/dışa aktarma saymıyordu → `Note.attachmentsWithoutBackground` ortak kural. TUZAK: yeni "ek" sayan yer bunu kullanmalı.

## 2026-11-08 — Oturum E (15+2 maddelik üçüncü tur)
- **Yazım:** `SpellEngine.replacedWord` (tek adımda kelimenin yerine yakın başka kelime = klavye önerisi/yerinde düzeltme → `learnFix`; tamamlama sayılmaz). Ayarlar → Öğrenilen yazımlar (`SpellLearnedScreen`: liste, elle `addManualFix` ilk görüşte uygulanır, sil, dokunulmayanlar). Boşluk komşusu `cvbnmö`.

## 2026-11-09 — Oturum H (tablet cihaz turu dönüşü)
- **Uygulama içi güncelleme** (`installAppUpdate`): APK `releaseApkUrl` → önbellek → `installApk` (FileProvider `cache-path`), `REQUEST_INSTALL_PACKAGES` YALNIZ `src/kisisel` manifestinde; `canSelfUpdate` izni manifestten okur. Sessiz kurulum Android'de yok (tek dokunuş "Güncelle").
- **Web ek yedek yolu**: Storage düşerse `DriveStore.uploadBytes` → `driveId`; ikisi de düşerse `WebUploadException` (iki hata metni). Asıl Storage hatası doğrulanmadı.

## 2026-11-09 — Baştan sona inceleme → `OTURTMA_PLANI.md` (Faz 58–69)
- **Ekran turu gerçek tableti çekmiyor:** tur 800×1280 / 1280×800; MatePad 11 = 640×1024 / 1024×640 dp (F67.2).
- Bu dosya 109 KB (hedef 30): bölme işi F58.2; o yapılana dek buraya yalnız kök neden/tuzak, tek satır.
- **PDF referansı yalnız dönülecek PDF varken bağlantı (F60.3, 2026-11-11):** `linkAtPoint(pdfRefs:)` damga (`timestamps`) gibi bayraklı; gövdede `_pdfForRefs(note) != null`. Bayraksızken PDF "Ek"e alınınca `📖 s.N` satırı dokunuşla klavye açmıyordu (silinemiyor). Bekleyen ek bildirimi (F65.4): `ReminderService._armUploadNotice` (`AppLifecycleListener`, id 999004, yük `upload`); PDF bulut önizlemesi (F65.5): `pdfFirstPageThumb` → `thumbs/{id}.jpg`, kart `_PdfFirstPage` dosyasızken çizer.
- **Sabit ek çubuğu (P49, 2026-11-13):** dar (< 600 dp) çubuk ⛶ · [oynatma] · tutamak · Not al · ✏ · ⋮; her şey TEK ⋮ levhasında (`_openSheet`/`_sheet`, PDF işleri `PdfBoxBar.menuActions`). ✏ hep görünür = `PenPolicy.layerActive`; kapatmak `onPenOff` ile editörün kalem kipini kapatır, `InkToolMemory.saveAutoStylus` yüzen düğmeyle ortak. Bölme kalemi (`_ownPen`) açıkken çubuk solu hızlı kalem. Kalem ipuçları `SnackBarObstacle` ile tepsi üstünde; durum başına oturumda bir kez (`InkToolMemory.stylusHintsTold`/`lastPenOnlyHint`). Yan yerleşim: tercih yoksa ≥ 840 dp yatayda sol (`PinnedSideMemory.preferred`, K-O7).
