# Not Uygulaması — Hafıza (geçerli kararlar ve tuzaklar)

İş başında oku; iş sonunda kalıcı karar / kök neden / tuzak varsa ilgili
bölüme EKLE (tarihli, kısa). Sır/anahtar/kişisel veri YAZILMAZ. Hedef boyut
≤ 30 KB — tarihçe ve uzun anlatı `HAFIZA_ARSIV.md`de (2026-10-19'a kadar,
dondurulmuş; `grep` ile ara). Bir kural değişince buradaki maddeyi GÜNCELLE,
eskisini arşive taşıma.

## Ortam ve araçlar
- Flutter **3.47.7** (CI ile aynı). Bulut oturumunda SDK yok: linux arşivini
  storage.googleapis.com'dan scratchpad'e indir (CLAUDE.md). Windows'ta
  `C:\src\flutter\bin\flutter.bat` (PATH'te değil).
- `pdfrx 2.6` Flutter ≥ 3.47 / Dart ≥ 3.13 ister (2026-10-19, F3.15).
- **`dart format` yalnız değiştirdiğin/yeni dosyaya.** Depo tek biçimde değil;
  `dart format lib` yüzlerce ilgisiz dosyaya dokunur (üç kez yaşandı).
  `lib/l10n/generated` istisna: `flutter gen-l10n` biçimsiz yazar → ardından
  `dart format lib/l10n/generated`.
- `flutter test -j 4`: package:test varsayılanı çekirdeklerin yarısı; 4
  çekirdekte ~200 sn → ~90 sn.
- `flutter install` DERLEMEZ, var olan APK'yı kurar. Yerel APK'da
  `--build-number` ZORUNLU (yoksa versionCode 1 → `INSTALL_FAILED_VERSION_DOWNGRADE`)
  ve `--dart-define-from-file=env.json` ZORUNLU (yoksa Google girişi çöker).
- graphify grafiği 2026-07-30'dan beri bayat; satır/dosya bilgisini koddan
  doğrula.
- Bulut ortamında dl.google.com engelli: Android SDK kurulamıyor, APK yalnız
  CI'da derlenir. Oturumun GitHub izinleri `workflow_dispatch` tetiklemeye
  yetmiyor (403) — Android doğrulaması main'deki `[apk]` koşusunda.

## CI (`.github/workflows/build.yml`)
- APK işi ilk adımda kullanılmayan araç zincirlerini siler (2026-10-20,
  koşu #490 "No space left on device" — Gradle önbellekleri + NDK r28c).
- Sürüm adı (2026-10-20): pubspec ANA.ARA (1.1) + koşu numarası → `1.1.N`
  (`--build-name`), Release etiketi `v1.1.N`, web de aynı. Büyük adımda
  pubspec'teki ara sayı elle artar. versionCode yine koşu numarası.
- APK yalnız main'de, commit **BAŞLIĞINDA** `[apk]` varken (gövdedeki söz
  tetiklemez — eskiden `contains(message)` tetikliyordu). Dalda derlenmez
  (dal + main ağır işleri yan yana koşunca runner kapanıyordu).
- 2026-10-19: APK işi testi BEKLEMEZ (`marker` işi işareti okur), Release
  TASLAK oluşur; `release` işi testler yeşilse yayınlar, kırmızıysa siler.
  Artifact yalnız elle tetiklenen koşuda (depo artifact kotası sık dolu).
- Gradle: bağımlılık önbelleği restore/save AYRI adımlar (post adımı runner
  kapanınca çalışmaz); yapı önbelleği (`build-cache-1`) her başarılı
  derlemeden sonra kaydedilir.
- `secrets` bağlamı step `if:` içinde kullanılamaz → bash adımında kontrol.
- Mimari: yalnız arm64 (`--target-platform android-arm64` + `packaging.jniLibs.excludes`;
  `abiFilters` tek başına eklenti .so'larını elemiyor). Rapor adımı 32 bit
  sızarsa düşer.
- Deploy (main): web (Cloudflare Pages `build/` dizininden — kökte
  `functions/` Firebase'in, wrangler onu Pages Functions sanıyordu), Firestore/
  Storage kuralları, Cloud Functions (`continue-on-error`, Blaze ister).
- `rules` işi (F4.9): `rules-test/` Firestore+Storage emülatörü (Java 21) +
  functions saf testleri; deploy `[test, rules]` bekler. Yerelde:
  `cd rules-test && npm ci && npm test`.

## Veri modeli ve Firestore
- **İleri uyum (F1.5):** `Attachment`/`NoteItem`/`Note` tanımadığı anahtarları
  `extras`ta saklayıp `toMap`'te aynen yazar; yeni alan eklerken `knownKeys`e
  de ekle (`forward_compat_test`). Bilinmeyen ek türü `unknown` + `rawKind`.
- **`kClientDataVersion` = 3** (2026-10-20: yıldız/çerçeve ayrı alanlar).
  `config/app.minClient` konsoldan elle; telefonlar güncellenince 3
  yazılmalı (2'deki istemci `starred`ı sabit sayıp her yazımda siler).
- `merge: true` yazımında kaldırılabilir/varsayılana dönebilen alanlar
  KOŞULSUZ yazılır (`fontScale`, `textOpacity`, `backgroundImageId` null…) —
  yoksa eski değer Firestore'da kalır.
- Her paylaşılan-yol bulut yazımı `updatedBy == auth.uid` taşır; 'write'
  rolü yalnız `createdBy == uid` notu günceller (F1.4). Yeni yazım yolu
  eklerken `updatedBy`'ı unutma.
- `updateNote`: ek listesi son BAŞARILI yazımın DERİN KOPYASIYLA
  (`copyFirestoreValue`) içerikçe aynıysa (`sameFirestoreValue`)
  `attachments` yazılmaz (2026-10-20 F6.1; eskiden JSON+SHA-1 özet, büyük
  notta ~50 ms). **TUZAK:** kopya ŞART — etkin çizginin nokta listesi
  YERİNDE büyüyor (`InkController`), aynı liste örneği saklanırsa büyümüş
  çizgi "değişmedi" görünür ve yazım atlanır. Ek örneğine `Expando` önbelleği
  işe yaramaz: editör her yankıda ekleri yeniden kuruyor. Editör kapanınca
  `releaseNote` bu kopyaları bırakır. `localPath` Firestore'a yazılmaz,
  cihazda türetilir.
- Çizim noktaları (F7.2): kayıttan okunan `InkStroke.points` `Float32List`
  (~1e-8 yuvarlama; testte `closeTo`). **TUZAK:** `toMap` tipli diziyi
  DOĞRUDAN vermez (Firestore kodlayıcısı `float[]` yollar, sunucu reddeder)
  → `UnmodifiableListView`. Kayıttan okunan çizgiyi YERİNDE değiştirme
  (sabit uzunluk); yalnız çizim sürerken kurulan çizgi büyür.
- 1 MiB sınırı: ≥ 900 KB'ta kullanıcı uyarılır (en büyük kalem adıyla);
  yazım reddi yutulmaz (günlük + Crashlytics + bildirim).
- **Ağır alanlar ayrı belgede (F3.13):** ağır kısmı (ek `ink`/`bubbles`/
  `pdfMarks`) 16 KB'ı aşan not bölünür (2026-10-20 F7.3: 96 → 16 KB,
  kullanıcı kararı; bölünen not birleşmez): ana belgede hafif ekler + `heavyRef`,
  `notes/{id}/heavy/data`da ek kimliğine göre ağır alanlar. Liste akışı HAFİF
  not verir (`heavyMissing`); editör akışı (`watchNote`) birleştirir.
  **TUZAK:** hafif not yazılırken ağır belgeye DOKUNULMAZ (eksik veriyle
  üstüne yazma yolu kapalı). Listedeki notla çizim/balon gereken iş
  (paylaşım, arkadaşa gönder, yalnız bu cihaz) önce `hydrateNote`. Belge
  silmek alt koleksiyonu silmez → kalıcı silme, "yalnız bu cihaz"a alma
  (F5.4) ve hesap silme ağır belgeyi, sürümleri, `presence`i ayrıca siler
  (ortak `_deleteCloudCopy`; yeni alt koleksiyonu oraya da ekle). Metin (`text`, `pageNotes`) ana belgede kalır (arama).
- **Yıldız ve çerçeve GERİ (2026-10-20, F3.6 geri alındı — kullanıcı
  kararı):** `starred` sabitlemeden AYRI bayrak (Süz → Yıldızlı, kartta
  yıldız, menülerde Yıldızla); `frameColor` zeminden BAĞIMSIZ ve YALNIZ ana
  ekran kartında çizilir (editörde çerçeve yok). 'f36' göçü kaldırıldı —
  bayrak cihaz başına, yeni kurulumda yeniden koşup yeni yıldızları
  sabitliye çevirirdi. Okumada çeviri yok (`pinned`/`starred`/`color`
  olduğu gibi). F3.6 döneminde yıldızlılar sabitliye dönmüştü — geri
  kazanılamaz.
- **Defter (F3.5):** ayrı defter editörü (`NoteType.archive`) kalktı; defter
  = `Note.paged` (kâğıt deseni `archivePaper` + hep görünen sayfa çubuğu).
  Eski defter `notebookToPagedNote` ile çevrilir (adlı sayfa → `textPages`,
  ad başlık satırı; yazı + bloklar gövdeye; ekler `section` = sayfa kimliği,
  öksüzler ilk sayfaya). Editör açılışta, `dataMigrationsProvider` arka
  planda bir kez çevirir. `/notebook/:id` eski bağlantılar için editörü açar.
- **Bir defalık göçler** `lib/features/notes/data/data_migrations.dart`:
  bayrak cihazda (`migration_<ad>_<uid>`), hata olursa yazılmaz (yeniden
  denenir); göç `updatedAt`e dokunmaz.
- Defter kâğıdı (`ArchivePaper`): çizgili, kesikli, kareli, noktalı, düz +
  bloknot, milimetrik, izometrik. Bilinmeyen kimlik çizgiliye düşer.
  **Çizgili desenler (`ruled`) satırı İÇERİK çizer (2026-10-20, "yazılar
  çizgilerle üst üste")**: `RuledLines` yerleşimden sonra her
  `RenderEditable` satırının altına çizgi koyar, arayı eşit adımla doldurur,
  düz yazıdan (düğme etiketi) geçmez; kartta `anchorParagraphs`. Arka plan
  (`contentRuled`) yalnız kenar/cilt. Defterde `ItemsEditor.paperLines`:
  dolgu 0, kutu 24 dp → madde = satır × aralık. Aralık textScaler'lı
  (`_paperGap`). Kareli/noktalı serbest ızgara kalır.
- Madde altı ayırıcı `NoteItem.divider` ('' / solid / dashed / dotted;
  yalnız doluyken yazılır); `sameItemsVisually`, `_sameItems`, `_sameItem`
  (birleştirme) ve `ItemsEditor` satır önbelleğinin anahtarı ona da
  bakar (anahtarda yokken çizgi hiç görünmüyordu). Satırı çizen YENİ alan
  → `_cachedItemRow` anahtarına ekle.
- Notun sayfaları (`textPages`): ETKİN sayfanın içeriği `body`/`items`'ta,
  listedeki girdisi boş; geçiş içerikleri yer değiştirir. İlk sayfa kimliği
  hep ''. Yana çekiş `PageSwipeDetector` (ham `Listener`, jest yarışına
  girmez); madde taşıma `moveItemToPage` (2026-10-20).
- **Özel renk (2026-10-20, "renk paleti"):** satır içi `%%#RRGGBB:..%%` /
  `==#RRGGBB:..==` — `RichMark.color` ARGB tutar, `isCustomRichColor`
  (> 0xFFFFFF) ayırır; palet indeksi tek hane kalır. Not zemini/çerçevesi
  `customColor`/`customFrameColor` (+ defter `lineSpacing`) KOŞULSUZ yazılır;
  çizim `NoteColors.noteSurface/noteFrame`. Palet tek levha
  (`core/widgets/color_palette.dart`, `PaletteButton`).
- Satır içi biçim metnin İÇİNDE işaretle (`**kalın**`, `_italik_`, `~altı~`,
  `==k:vurgu==`, `%%k:renk%%`, `##k:boy##`, `&&k:opaklık&&`); başlık =
  boy kademesi + kalın (`setLineHeading`). Önekli işaretler önek olmadan
  eşleşmez (düz metindeki `## x ##` kaybolmasın).
- Yerel (yalnız bu cihaz) notlar `LocalNotesStore`; **TUZAK:** haritayı
  YERİNDE değiştirme, yenisini koy (ayrıştırma önbelleği harita kimliğiyle).
- Hesap silme listeleri `AccountService` sabitlerinde; yeni koleksiyon
  eklenince `account_deletion_test` kırılır (bilinçli). `aiQuota`/
  `rateLimits` bilerek kalır.
- `premiumUntil` istemciden yazılamaz (kural) — premium konsoldan.
  TUZAK (F4.9 testi yakaladı): rules_version 2'de `{document=**}` SIFIR
  parçayı da eşler; genel blok `users/{uid}/{collection}/{document=**}`
  olmalı, yoksa `users/{uid}` belgesinin kendisine her şey yazılır.
- Not alt koleksiyonları (`heavy`, `versions`, `presence`) tek kural
  bloğunda (`{sub}` + izin listesi); bilinmeyen alt koleksiyon kapalı.
- Sürümler (F4.2): `notes/{id}/versions`, yalnız METİN; açıldığı hâl ilk
  değişiklikte, sonra 30 dk'da bir, AI öncesi, geri dönüş öncesi; 30 tavan
  (sahip budar). Depo `rememberVersionBase` (editör açılışta verir).
- Eşzamanlı düzenleme (F4.1): editör üç yönlü birleştirir (taban = son
  ortak görülen içerik, `text_merge.dart`); kendi yankısını depo
  `isOwnEcho` ile ayırır. Kalan risk: yazım uçuştayken gelen başka yazım
  sunucuda ezilebilir (pencere ~yüzlerce ms). "Düzenliyor" nabzı
  `presence/{uid}` 25 sn'de bir.
- Ayar senkronu (F4.5): `users/{uid}/meta/prefs.values`; anlık görüntü
  yöntemi, cihazın İLK eşitlemesinde bulut kazanır. 20 sn yoklama yalnız ön
  planda; anlık görüntü yalnız değişince yazılır (F6.4). Tercih sağlayıcıları
  `watchPrefs(ref)` ile okur (dışarıdan değişince yeniden kurulur).
  Cihaza özgü anahtar listeye EKLENMEZ.
- Not kilidi (F4.8): cihaz / şifre / desen (`note_lock`, PBKDF2 özeti, ayar
  senkronuyla). ŞİFRELEME DEĞİL — arayüzde açıkça yazar. "Unuttum" Google
  yeniden doğrulaması ister (misafirde yok).
- FCM (F4.6): jeton `users/{uid}/fcmTokens/{jeton}`; `functions/push.js`
  klasör sohbeti/davet, ortak not, gelen not. Not DÜZENLEMESİ için itme
  bilerek YOK (yazım sıklığı). Hesap değişince `deleteToken`.
- Kişi araması (F1.1): anonim red, dakikada 10, e-posta TAM / ad ≥ 3 harf
  kelime öneki; "Adımla bulunabilirim" kapalıyken `userSearch/{uid}` silinir.

## Riverpod / performans
- **Riverpod 3 görünmeyen ekranın aboneliklerini DURAKLATIR** (`TickerMode`):
  oturum boyu canlı servisler bir EKRANIN build'ine bağlanmaz →
  `lib/app/app_services.dart` (`ref.listen`, uid yokken hiçbiri).
- **TUZAK (2026-10-20, deneyle doğrulandı — F5.1 YAPILDI):** Riverpod 3.3'te
  `.family` (ve düz) sağlayıcılar varsayılan KALICI; son dinleyici gidince
  yok edilmez, DURAKLATILIR (`subscription.pause()`). `onPause` vermeyen
  `StreamController`'lı akışlarımızda (`_withLocal`, `_hydratedDoc`) kaynak
  dinleyici açık kalır, `merge` her olayda koşar, olaylar birikir ve yeniden
  açılışta topluca oynatılır. Tek nota/klasöre bağlı akışların hepsi artık
  `.autoDispose.family`; YENİ eklerken de öyle. autoDispose sağlayıcıyı
  `ref.read` ile okuma (dinleyen yoksa "yükleniyor") — istisna: başka bir
  canlı sağlayıcı onu izliyorsa (`shared_activity_service`).
- Notifier örneği yeniden kurulumda KORUNUR (Riverpod 3.3:
  `classListenable.result ??=`) — alanlardaki önbellek build'ler arası kalır.
- Hesap değişince (F5.5) `AppServices` arama gövdesi önbelleğini temizler ve
  öbür hesapların `LocalNotesStore`larını bırakır; hesaba bağlı bellek
  önbelleği eklersen ya `currentUidProvider`ı izlesin ya oraya ekle.
- Kart küçük resimleri (F7.1) 64 adet + 6 MB bayt bütçesi; PDF kapağı
  JPEG (izolede). PDF sayfası çizen her yol `data/pdf/pdf_page_render.dart`
  (F8.4) — `PdfImage.dispose` sırası orada. Düşük RAM'li Android'de görsel
  önbelleği 50 MB (F7.6, `ImageCacheBudget`). Teşhis sayaçları yalnız
  debug/profil: `Diagnostics` (Ayarlar → Hakkında, F9.2).
- Görsel çözme (F5.2): tam boy `Image.file/memory`/`FileImage` KULLANMA —
  `boundedImage(...)` ya da `cacheWidth: decodeWidthBucket(...)`
  (`note_images.dart`). 12 MP ≈ 48 MB bitmap.
- Ana izoleyi tutan iş (F6.3/F6.5/F6.6): büyük JSON kodlama/çözme ve PDF
  metni `compute`/`Isolate.run`'da. `Isolate.run` kapanışını STATİK
  yardımcıda kur (örnek alanı yakalarsa gönderilemez — akış denetleyicisi).
- `localFileExists` "yok" sonucunu 2 sn önbellekler (F6.9): dosya YAZAN yol
  `forgetLocalFile` çağırmalı (ya da toplu indirmede
  `localFilesRevisionProvider` bump) — yoksa yeni dosya 2 sn görünmez.
- `ConsumerState.dispose` içinde `ref` kullanılamaz (istisna) — denetleyiciyi
  build'de alana al.
- Türetilmiş sağlayıcılar içerik aynıysa ÖNCEKİ örneği döner (`StableBox`,
  not listelerinde örnek kimliği — `sameInstances`).
- Toplu işlemler tek `WriteBatch` (450'lik parçalar).
- Ana ekran ızgarası: deterministik sütun ataması (`balancedColumnAssignment`,
  tahmini yükseklik) + sütun başına tembel `SliverList`. Masonry kartı
  yerleşim anında atıyordu → kaymalar/boşluklar.
- `planTextWrap` yalnız bandı kapsayan öneki ölçer (eskiden O(satır×metin));
  imleç ve ipucu dolgusu TEK işlevden (`wrapLineIndents`) — "ipucu ile imleç
  ayrı yerde" bildirimi gelirse önce iki hesabın aynı kaynaktan beslendiğine
  bak.
- Animasyonda `Timer` değil `FrameLoop` (Ticker; adım 60 Hz'e göre ölçekli).
- `DateFormat` kart başına kurulmaz (desen+dil anahtarlı önbellek).
- Kopya taraması `compute` ile; web'de `<<` 32 bit → trigram çarpmayla.

## Editör, klavye, metin
- Scaffold `bottomNavigationBar` klavyenin ALTINDA kalır; alt çubuk
  `KeyboardSnap`/`KeyboardSlide` ile, HAREKET ile YERLEŞİM ayrık. Çubuk içi
  `SafeArea` klavyede kare kare değişir → pay elle verilir.
- Çubuktaki düğme odağı çalarsa seçim gider: `Focus(canRequestFocus: false)`
  + `TextFieldTapRegion`.
- Düzenlenebilir `TextField` span'ine `TapGestureRecognizer` çalışmaz →
  bağlantı/etiket için seçim menüsü ve üst katman.
- Geri alma NOTUN TAMAMINI saklar (`note_undo.dart`); parmak izine öğe sırası
  konmaz. Eki silince baytlar editör kapanırken silinir (geri al için).
- Biçim paneli (2026-10-20 SIFIRDAN): kaymayan eşit bölünmüş ana satır
  (Başlık·B·I·U·Renk·Aa·Temizle·Sayfa·⌄) + üstünde satır içi TEPSİ
  (başlık / renk iki satır / yazı tipi + ayrı boyut-şeffaflık). Açılır
  MENÜ YOK — dar menü kutusunda palet düğmesi taşıp basılamıyordu.
  Panel açıkken alt çubuk GİZLİ; kaydırıcı önizlemesi 70 ms'de bir. Panel
  kapalıyken etkin biçim rozetleri `ActiveFormatBadges` (`_formatTargetN`
  ile — editör setState'i değil). Kalın, tabanı ≥ w500 olan metinde w800
  (başlık w500).
- Dashboard (`dashboard_selection/menu/shelf/slivers`) ve ItemsEditor
  (`items_editor_row/actions`) de part + uzantı (C1, 2026-10-20); uzantıda
  statik `ItemsEditorState._kX` diye nitelenir, `setState` → `_update`.
- **Editör konu dosyalarına bölündü (F9.3, 2026-10-20):** `note_editor_screen.dart`
  yalnız durum (alanlar), yaşam döngüsü, biçim, `_mutate`, kanvas ve
  `build`; yöntemler `part` dosyalarında `extension _EditorX on
  _NoteEditorScreenState` (`ai`, `attachments`, `actions`, `media_view`,
  `appearance`, `toolbar`, `find`, `voice`). Uzantıda: `setState` yerine
  `_update` (korumalı üye), sınıf statiği `_NoteEditorScreenState._x` diye
  nitelenir, YENİ ALAN sınıfa eklenir (uzantı alan tutamaz). Not içi arama
  durumu `NoteFindController` + `ListenableBuilder`.
- Editör yeniden çizimi `sameRenderedNote`'a ve `_mutate`'in "saf yazım"
  kararı `_sameVisual`'a bakar: yeni GÖRÜNÜR not alanı eklenince İKİSİNE de
  ekle. TUZAK (2026-10-20): `paged`/`archivePaper` ikisinde de yoktu →
  "kâğıt seçimi çalışmıyor" (ilk değişiklikten sonra setState atlanıyordu).
- Klavye açılınca üst parçalar (sabit medya, balonlu belge bölmesi) yeniden
  ÖLÇÜLMEZ: klavyesiz boyda yerleşir, yalnız görünür penceresi
  `KeyboardClipWindow` ile daralır; evre `KeyboardPhaseListener`dan (kare
  kare değil, açılış/kapanışta). Gövde KeyboardSnap ile oturunca tek seferde
  kısalır — boyu ona bağlanan parça zıplar.
  Sabit görsel/video/sunum pencerede KIRPILMAZ, ölçeklenir (`shrink:` —
  Transform, yeniden ölçüm yok; metin/PDF/ses kırpılır). TUZAK
  (2026-10-20 "çubuk önce yukarı gidip sonra iniyor"): klavye kapalıyken
  alt çubuğun altında gezinme payı var, oturunca yok → gövde klavye eksi
  gezinme payı kadar kısalır; açılış tahmini de payı düşmeli.
  Sabit video bölmesi genişlikteki doğal boyu (16:9 ya da ölçüsü) AŞMAZ;
  YouTube kapağı (`hqdefault` 4:3 şeritli) `contain`de 16:9 `cover` kırpılır.
- Not açılışı: editör önbellekteki hafif notla açılır; akıştan gelen ilk
  değişiklik çizimi açılıştan ~450 ms sonraya ertelenir
  (`_setStateAfterOpening`; `ModalRoute.of` KULLANMA — editörü rota
  durumuna bağlar). Ağır medya `AfterRouteTransition` ile geçiş sonunda.
  TUZAK: itilen rotanın İLK karesinde Hero sayfayı `offstage` kurar,
  animasyon "tamamlandı" görünür — durum tek başına yetmez.
- Uzun basış CÜMLE seçer (`sentence_select.dart`).
- Canlı dikte: tanıyıcı her olayda TAM metni yollar ve düzeltir → "ekle" değil
  "değiştir". Akıllı komutlar ham metni her olayda baştan işler.
- Dikte bipleri (2026-10-20): tanıyıcı her sessizlikte yeniden kuruluyor ve
  Google HER açılış/kapanışta bip çalıyor. MainActivity ilk
  `onReadyForSpeech`ten 700 ms sonra MUSIC/SYSTEM/NOTIFICATION akışlarını
  susturur (zil kipi normal değilse yalnız MUSIC), oturum bitince yalnız
  kendi susturduklarını açar; süreç ölürse `notlar_speech.muted` kaydından
  sonraki açılışta açılır.
- Android'de tek mikrofonu SON açan istemci alır: dikte ile kayıt aynı anda
  açılmaz.

## PDF, balon, görüntüleyici
- PDF YAZMA tek kütüphane: **Syncfusion** (`pdf_edit.dart`, `NotePdf`,
  `ScanPdf`); görüntüleme `pdfrx`. `pdf` paketi 2026-10-19'da kalktı. Gömülü
  PT Sans ŞART (hazır Helvetica'da ı ğ ş İ yok). Taranmış PDF'in görünmez
  OCR katmanı saydamlıkla (`/ca 0`) — Syncfusion metin çizim kipi vermiyor.
- `PdfBitmap` yalnız JPEG/PNG okur; diğerleri `image` ile PNG'ye çevrilir.
- pdfrx 2: `render(backgroundColor:)` int, `PdfImage.pixels` BGRA,
  `loadText()` → `PdfPageRawText?` (seçim katmanı `loadStructuredText`),
  `PdfRect` ters kutuyu kurucuda reddeder.
- Tam ekran görüntüleyici ve PDF bölmesi ortak `PdfDocumentView` (F3.4);
  katmanlar `pdfLayerParams`tan. Görüntüleyici örneği SAKLANIR (her pano
  setState'inde yeniden kurulmasın).
- Çizim PDF'e GÖMÜLMEZ (ayrı vektör katmanı, ekte); damgalı paylaşımda
  geri okunabilir damga.
- `ScrollController.position` sayfa çevirirken iki/sıfır konumla patlar →
  `positions` dolaş (kâğıt deseni boyacısı).
- İki parmak kaydırma çizim kipinde: `InkNavLayer` (InteractiveViewer
  `panEnabled:false`'ta jesti yutuyordu).
- **pdfrx'in KENDİ metin seçimi KAPALI** (`pdfLayerParams`, 2026-10-20):
  varsayılan açıktı → çizim her karede önbellekteki her sayfanın metnini
  render işçisinde ayrıştırıyordu (PDF kasması), ~500 ms basılı tutuş pdfrx
  kelime seçimi/menüsü tetikliyordu ("basılı tut → balon" 450 ms ile
  çakışma) ve görüntüleyici ODAK istiyordu (yeni balonun yazı alanı odağı
  düşüyor, klavye gelmiyordu). Seçim yalnız `PdfSelectLayer`. Dokunmatikte
  `keyHandlerParams.canRequestFocus: false`, `buildContextMenu` null döner.
- **Dışarı dokununca kapatma `GestureDetector(onTap)` İLE YAPILMAZ**
  (2026-10-20, "balon gecikmeli kapanıyor"): alttaki görüntüleyicinin çift
  dokunuş tanıyıcısıyla yarışır, tap ~300 ms bekler. Ham `Listener`
  (`TapToCollapse`, bubble_layer.dart) — yarışa girmez, parmak kalkınca.
- **pdfrx'e `scrollPhysics` VER** (`_pdfScrollPhysics`: Android Clamping,
  iOS Bouncing; 2026-10-20 "PDF'yi zorla kaydırıyorum"). Verilmezse
  InteractiveViewer sürtünmesi fırlatmayı birkaç santimde durduruyor.
- **TUZAK: pdfrx `pageOverlaysBuilder`ı HER matris değişiminde (kaydırma
  karesi) çağırır.** Yeni widget dönersek görünen sayfaların seçim/kalem/
  balon katmanları kare başına yeniden kurulur. `pdfLayerParams` sayfa
  başına (sayfa nesnesi + yarım piksele yuvarlanmış boy) AYNI örneği döner.
- Balon paleti koyu/kırık tonlar, varsayılan `BubbleController.defaultColor`;
  eski amber (`legacyDefault`) EKRANDA yeni varsayılanla çizilir
  (`displayColor`), veri değişmez. Yazma kartı (`_KeyboardFollow`) gezinme
  çubuğunun da üstünde.

## Ses ve yapay zekâ
- Seslendirme TEK kapı `SpeechService` (F3.9): motor ayardan (cihaz / AI /
  Antalia); seçilen düşerse cihaza geçer ve sebebi söyler.
- Antalia Türkçe ses (2026-10-21, `ai/data/antalia/`): cloud0day3/antalia-mini
  ONNX'i (fr0stb1rd/antalia-mini-web-onnx, ~50 MB) Ayarlar'dan İSTEĞE BAĞLI
  indirilir, `flutter_onnxruntime` ile cihazda; yalnız Android (web eklentisi
  int64 almıyor) ve yalnız `tr` (başka dil → cihaz sesi). Normalleştirici
  normalize.js'in Dart portu — Python örnekleriyle birebir test edilir
  (`test/fixtures/antalia_*`); deseni sadeleştirme. R8: `ai.onnxruntime` keep.
- Sohbet TEK ekran `AiChatScreen` (F3.3): kapsam (Tüm notlar / Bu not / Bu
  belge) + kip (Soru-cevap / Beyin fırtınası). "Tüm notlar" konuşması
  `chatProvider`'da (merkez kartla ortak).
- AI istek biçimi içeride Gemini `contents`; sağlayıcı teline çağrı anında
  çevrilir. Araç döngüsü Gemini dışı sağlayıcılarda ayrı (`_runToolLoopCompat`).
- HTTP tek istemci `package:http` (`core/net/json_http.dart`; dio kalktı).
  **TUZAK:** `StreamedRequest` gövdesini `listen(...).asFuture()` ile
  beslemek `onDone`'u ezer → gövde kapanmaz, yükleme asılı kalır
  (`addStream` + `whenComplete(close)`).
- Asistan modele not TARİHLERİNİ de verir; hatırlatıcı zamanı kullanıcının
  cümlesinden yerelde de çıkarılır (model atlarsa). Silme aracı onaylı.
- AI kota sayacı sunucu saatli `aiQuota/{uid}` (istemci silemez).
- AI çıktıları cihazda önbellekli (`AiCache`), Firestore'a yazılmaz.
- Ek metni indeksi (F6.3): önbellek `<destek>/attachment_text_<uid>.json`
  (eski SharedPreferences anahtarı `attachment_text_v1` bir kez taşınıp
  silinir); süzgeç katlanmış kopyayı `attachmentFoldedTextProvider`dan okur.
- Hatırlatıcılar (F5.3): ilk eşitlemede planlı bildirimlerle mutabakat —
  `note:` yüklü olup istenmeyen/kimliği kaymış olan iptal. Yeni planlı
  bildirim türü eklersen yükü `note:` ile BAŞLATMA.

## Arayüz kararları (Faz 3, 2026-10-19)
- Ana ekranda TEK mikrofon (F3.1) = DOĞRUDAN YAZDIR (2026-10-20, kullanıcı
  kararı). Basılı tutmak AI ile sesli notu açar. ✨ yüzen düğme KALKTI
  (B2, 2026-10-20): Yapay Zekâ ⋮ hızlı satırında ilk (`UiItem.homeAi` onu
  gizler); mikrofon "+"nın solunda tek satır, ızgara alt payı 96. AI ile sesli not: Yapay Zekâ ekranının EN
  ÜSTÜNDE (dokunuş `/`'a döner + `voiceAutostartProvider`) ve editörde AI
  levhasının EN ÜST satırında (`onVoiceNote`); editör alt çubuğunda parıltılı
  mikrofon YOK (`UiItem.barVoiceAi` kimliği yalnız eski tercihler için).
  Klasörde sesli not "+" menüsünde.
- "+" menüsü TEK PANEL (2026-10-20; F3.2'nin kapı levhaları kalktı):
  Diğer (şablon, alışveriş, el yazısı, defter) · Kamera · Dosya (geniş) ·
  birincil Metin/Liste/Sıralı. ≤2 seçenekli bölüm geniş düğme.
- Dosya akışı (2026-10-20): seçici → TEK levha `showFileUseSheet` (özet,
  başlık, türe göre seçenek; varsayılan kip başta) → akışa `preset` kip.
  Ses artık sorulmadan metne dökülmez (ek / metne dök; editör `?afile=1`).
  HEIC `normalizeHeicImages` ile PNG (akış seçicisi HEIC'i tanımıyor, seçici
  ikinci kez açılıyordu). Editörün Ekle levhasında türü kendi tanıyan
  "Dosya ekle" — 2026-10-20'den beri TEK dosya kapısı: PDF/Slayt/Ses
  dosyası/Galeriden video/Görseli ek olarak/Metne dök düğmeleri kalktı,
  görsel ve ses-video için `_askFileUse` sorar ("Belgeler" eklentisi de
  kalktı). Seçilen dosya akışa `DocPicker.preselect` ile verilir.
- "Tümü" çipi (`showAllNotesProvider`, kalıcı): "klasördeki not ana
  ekranda durmaz" kuralının istisnası; açıkken elle sıralama kapalı.
  Çöp analizi `domain/trash_analysis.dart` (cihaz kuralları) + AI
  `analyzeTrash` (kilitli not gitmez). Arşiv/çöp/klasör araması TEK yüzey
  `screen_search.dart` + `scopedSemanticSearchProvider` (B4). Çöp
  hatırlatması `trashReminderPlan` (bildirim 999002, yük `trash`). Kartta
  hassas içerik `sensitive_text.dart` (yalnız gösterim, ayar
  `card_hide_sensitive`); kart kutucuğu `toggleCardItem` ile işaretler.
- Süz düğmesi arama kutusunun İÇİNDE: süzgeç yokken simge, varken adı + ×.
  Görünüm (ızgara/liste, Tümü'de klasöre göre grupla) Süz levhasında.
  Favori süzgeç kısayolları KALKTI (2026-10-20, kullanıcı kararı).
- Menü ızgaraları: `ActionMenu` 3 sütun; editörün Ekle levhası 4 sütun.
  Ana ekran ⋮ `wideSections` (iki sütun geniş satır — ikişerli gruplar 3
  sütunda sola yığılıyordu).
- Kartta görünenler tek tek ayar (`card_show_*`, `cardDisplayProvider`
  kaydı; ilerleme sayacı varsayılan KAPALI). Yeni kart öğesi → oraya ekle.
- Uzun listeli not açılışı: `ItemsEditor` shrinkWrap'te HEPSİNİ kurar →
  `_rowBudget` ilk karede 18 madde, 380 ms sonra kare başına 14.
- Dinleme alanları TEK KART `ListeningCard` (`listening_visuals.dart`):
  editör diktesi ve sesli yakalama levhası aynı kart (~120 px). Başlık
  satırına düğme: `ListeningHeaderButton` (34 dp; M3 IconButton 48 dp yiyip
  başlığı kesiyordu).
- Ayar alanları `ExpandReveal` (animasyon içerik kurulduktan SONRAKİ
  karede; `FadeTransition` yok → `RepaintBoundary`; satırlar
  `_StaggeredRows` ile kare başına 1). Açılan alanın başlığı dokunuşun
  ilk karesinden itibaren KARE KARE tepeye izlenir (`_followIntoView`;
  animasyon bitince kaydırmak geç kalıyordu). Alanlar varsayılan KAPALI;
  arama AppBar'da sabit + ✨ AI kipi (`matchSettings`, yalnız ayar adları).
- Paylaşım iki kavram (F3.7): Birlikte düzenle (ortak not / klasör) ve Kopya
  gönder (gelen kutusu).
- Arayüz dilleri yalnız **tr + en** (F3.14); diğer 14 dil silindi. Kılavuz
  `assets/guide/guide_<dil>.md`. Sesli tarih ayrıştırıcısı ve AI çeviri
  hedefleri çok dilli kalır.
- Modüller yeni kullanıcıda da açık (F3.16 — kullanıcı kararı: değişmez).
- Açık/kapalı cihaz tercihleri `boolPref(anahtar, defaultValue:)` (anahtar
  adları eski sınıflarla aynı).
- Menüler ortak `ActionMenu`; üst/alt çubukta duran iş menüde tekrar edilmez.
- Kişiselleştirme (`Customizable`, `UiItem`): kimlikler kalıcı tercih
  anahtarıdır — değiştirme (`homeMic` = eski `home.voiceAi`).

## Web
- Web derlemesi `--wasm` (F9.4, 2026-10-20): WasmGC'li tarayıcıda skwasm,
  diğerinde aynı çıktının JS yedeği. COOP/COEP başlığı KONMAZ (Firebase
  giriş penceresi, dış görseller) → skwasm tek iş parçacığı. Wasm'da `int`
  64 bit, JS yedeğinde 53 bit — bit işlemlerinde ikisini de düşün.
- Geri tuşu: `HomeFirstRouteInformationProvider` (go_router görünmez
  geçmiş kayıtları yazıyordu).
- Web'de Drive ekleri (F4.4): `WebDriveAuth` Google penceresiyle Drive
  kapsamlı jeton (bellekte, ~1 sa); ek `blob:` adresiyle açılır, `blob:`
  `toMap`'te buluta yazılmaz. Web Drive'a yazmaz (ekleri Storage'a).
  Yerel notlar/video yok.

## Android
- `USE_EXACT_ALARM` yok (Play); izin yoksa hatırlatıcı inexact'e düşer.
- QR ve OCR modelleri Play Hizmetleri'nden (APK küçük; Play Hizmetleri yoksa
  çalışmaz).
- FlutterFire paketleri BİRLİKTE yükseltilir (`flutter pub upgrade
  firebase_core firebase_auth …` hepsi): 2026-10-20'de yalnız
  firebase_messaging eklenince firebase_core 4.15'e çıktı, eski
  firebase_auth/app_check Android'de DERLENMEDİ (testler/web yeşildi —
  yalnız APK işi yakalar).
- Crashlytics: google-services + crashlytics Gradle eklentileri; ayrı Firebase
  BoM EKLENMEZ (FlutterFire `firebase_core`un BoM'unu kullanıyor).
- Kesin geri tuşu davranışı `alwaysHandleBack` (iç kabuk Navigator'ı sayfasız
  rota açınca bildirim yanlış Navigator'dan gidiyordu).
- `SnackBar(action:)` varsayılanı `persist: true` → `timedSnackBar`.
- Bildirim (F8.3): düz metin için `messenger.showMessage(metin)` /
  `showAppMessage(context, metin)`; eylemliyse `action:` (geri sayımlı).
  Elle `SnackBar(content: Text(...))` kurma.

## Kod hijyeni (Faz 8, 2026-10-20)
- Lint: `unawaited_futures`, `cancel_subscriptions`, `unnecessary_lambdas`,
  `unnecessary_breaks`, `avoid_redundant_argument_values` açık; kasıtlı
  ateşle-unut `unawaited(...)`. **TUZAK:** `dart fix --apply` gereksiz
  argümanı silerken üstündeki AÇIKLAMA YORUMUNU da siler — diff'te silinen
  yorumlara bak; bilinçli açık değer `// ignore: avoid_redundant_argument_values`.
- Boş `catch (_) {}` yok: veri katmanı `ErrorLog.record`, arayüz gerekçeli
  yorum.
- `KALANLAR.md` tek cihaz doğrulama listesi; eski turlar `KALANLAR_ARSIV.md`.

## Test tuzakları
- Test dosyasına TARİH adı verilmez (F3.17, F8.1) — özellik adı.
- Veri katmanı testi: `fake_cloud_firestore` (`notes_repository_data_test`).
- Widget testinde `Picture.toImage` / `rootBundle` / PNG kodlama sahte zamanda
  ilerlemez → `tester.runAsync`.
- Test binding'i en_US koşar; Türkçe metin bekleyen testte `locale: tr`.
- Tembel `ListView` ekran dışını kurmaz → `ensureVisible` bulamaz.
- Yerleşim testi tasarım değişince kırılır, kırılmalıdır da: niyete göre
  güncelle.
