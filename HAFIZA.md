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
- **Bulutta APK DERLENEBİLİR (2026-10-29):** dl.google.com artık açık.
  Scratchpad'e cmdline-tools → `sdkmanager "platform-tools"
  "platforms;android-37.0" "build-tools;36.0.0" "ndk;28.2.13676358"`
  (`android-37` adı YOK, `37.0`), `flutter config --android-sdk`.
  Maven Central paylaşılan IP'de 429 veriyor → `$GRADLE_USER_HOME/init.d`
  betiği Google'ın aynasını (`maven-central.storage-download.googleapis.com`)
  pluginManagement'ta ÖNE koyar ve URL'leri yeniden yazar; depo EKLEMEZ
  (Flutter'ın gradle yapısı PREFER_SETTINGS — projeye depo eklemek hata) ve
  `gradlePluginPortal()`ı geri ekler. `env.json` (gitignore) yoksa
  `GOOGLE_SERVER_CLIENT_ID` son Release APK'sının `libapp.so`sundan okunur
  (REST: `api.github.com/repos/<o>/<r>/releases/assets/<id>` +
  `Accept: application/octet-stream`). Anahtar deposu yok → DEBUG imzalı:
  telefondaki CI sürümünün ÜSTÜNE kurulmaz (önce kaldır) ve Google girişi
  için debug SHA-1 Firebase'e eklenmeli. Oturumun GitHub izinleri
  `workflow_dispatch` tetiklemeye yetmiyor (403).

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
- APK'da `.so`'lar SIKIŞTIRILIR (`useLegacyPackaging = true`, 2026-10-23):
  ORT eklenince APK 73 MB oldu (`libonnxruntime.so` 28,6 MB, AGP
  varsayılanı sıkıştırmasız). Bedeli kurulu boyut.
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
- **Görünüm/medya alanları (2026-10-28):** `Attachment.caption` (görsel
  açıklaması; yalnız doluyken yazılır, `withLayoutOf` YEREL açıklamayı
  korur — yazarken yankı harf yemesin; aramaya girer), `Attachment.wave`
  (ses dalgası, 48 çubuk 0–100; boşsa `displayWave` kimlikten kararlı
  desen), `Note.theme` (çizilmiş tema kimliği `NoteThemes`, KOŞULSUZ yazılır;
  tanınmayan kimlik zeminsiz çizilir). `NoteColors.noteSurface` tema varsa
  TEMANIN alt tonunu döner (kart, editör alt çubuğu, açılış geçişi aynı
  rengi görür). Zemin RENGİ seçen her yol (editör, kart menüsü `setColor`,
  toplu seçim) `theme: ''` yazar — yoksa renk temanın altında görünmez.
  Üçü de `sameRenderedNote`/`_sameVisual`te.
- Çizim noktaları (F7.2): kayıttan okunan `InkStroke.points` `Float32List`
  (~1e-8 yuvarlama; testte `closeTo`). **TUZAK:** `toMap` tipli diziyi
  DOĞRUDAN vermez (Firestore kodlayıcısı `float[]` yollar, sunucu reddeder)
  → `UnmodifiableListView`. Kayıttan okunan çizgiyi YERİNDE değiştirme
  (sabit uzunluk); yalnız çizim sürerken kurulan çizgi büyür.
- Kalem basıncı (2026-10-23): `InkStroke.pressures` (`q`, nokta başına
  0–1, yalnız kalemle çizilende); kırp/yerleştir/döndür `copyWith` ile
  taşır. Şekiller (çizgi/dikdörtgen/elips) kayda SIRADAN çizgi yazılır.
  `inkPaint` fosforluyu tam 0x66 alfadan tanır (tükenmez/keçeli artık
  şeffaf olabiliyor).
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
- Madde altı ayırıcı `NoteItem.divider` ('' / solid / dashed / dotted /
  double / wavy; yalnız doluyken yazılır). Renk/kalınlık AYNI dizede
  (2026-10-23): `tür|c:AARRGGBB|w:1.50` (`ItemDivider.parse/encode`; eski
  sürüm tanımadığını düz çizer). Çizim tek yerden `paintItemDivider`; `sameItemsVisually`, `_sameItems`, `_sameItem`
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
- **`authStateProvider` `userChanges` üzerinden** (2026-10-28): anonim
  hesap Google'a BAĞLANINCA uid aynı kalır ve `authStateChanges` HİÇ
  tetiklenmez → arayüz misafir kalıyordu ("giriş yapınca sayfa yenilenmeden
  gelmiyor"). Belirteç tazelemesi (uid/anonim/e-posta/ad/foto özeti aynı)
  süzülür. Yönlendirici yine `authStateChanges` dinler. Misafir giriş kartı
  ana ekranda İLK AÇILIŞTAN itibaren + Ayarlar profil kartında düğme.
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
  **TUZAK (2026-10-30, web'de görüldü):** `Isolate.run` WEB'DE YOK
  (`Unsupported operation: RawReceivePort`) — `pdf_edit.dart` web'de PDF
  eklemeyi, sayfa düzenlemeyi ve balonlu PDF'i kırıyordu. **KURAL
  (2026-10-31, F10.1):** `Isolate.run` doğrudan YAZILMAZ — `runHeavy`
  (`core/utils/run_heavy.dart`; web'de aynı iş parçacığı). Web'de iş UI'ı
  tuttuğu için çağıran gösterge açar. Web'de `getTemporaryDirectory` da yok
  → paylaşımda `XFile.fromData`.
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
- Biçim paneli (2026-10-28 İKİNCİ KEZ SIFIRDAN): ÜÇ SABİT SIRA, sık iş tek
  dokunuş — Stil (Metin·Başlık·Alt başlık hapları + B·I·U) · Renk (yazı/
  vurgu anahtarı + 5 ton + palet + kaldır) · Yazı (Aa tepsisi, boyut −/+,
  temizle, sayfa, ⌄). Tepside yalnız yazı tipi + boyut/şeffaflık
  kaydırıcıları. Açılır MENÜ YOK — dar menü kutusunda palet düğmesi taşıp
  basılamıyordu. Panel açıkken alt çubuk GİZLİ; kaydırıcı önizlemesi 70 ms'de bir. Panel
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
- **Sesli not kaydı notun içinde (2026-10-28):** levha değil, alt şeritte
  hap (`VoiceNoteRecorder` + `VoiceRecordPanel`, `voice_note_recorder.dart`);
  kayıt sürerken yazılır. Bitince ses `_placeNewImage` ile YAZILAN SATIRA,
  `onPage` + tam genişlik HAP olarak girer (belge notunda şeride). Sayfada
  ses kutusunun boyu genişlikten bağımsız 52–76 dp (`_sizeOf`), köşe h/2,
  çerçevesiz. Kayıtta geri tuşu = bitir + ekle + çık (PopScope). Kaydedici
  eklentiyi TEMBEL kurar (kurucusu platform kanalına gider — testte patlar).
  Eski `showAudioRecorderSheet` yalnız AI sohbetinde.
- **☑ (alt çubuk, metin notu):** `_toggleChecklistLine` — gövdedeki satır
  maddelerin BAŞINA taşınır (gövde maddelerin üstünde: son satır yerinde
  kalır); maddede basınca madde gövdenin SONUNA döner. Model ara karışık
  sıralamayı taşımaz (gövde hep maddelerin üstünde).
- Biçim paneli ⇄ alt çubuk aynı `AnimatedSize` süre/eğrisiyle (`_kBarSwap`)
  yer değiştirir; panel içeriği `RevealUp`. Notun yazı ölçeği değişince
  gövde/başlık `ScaleSettle` ile (yalnız boyama) oturur — sayfada yüzen
  görsel varken KAPALI (sarma ölçümü dönüşümden etkilenmesin); ağaçtan
  çıkarılmaz, alanın durumu kaybolmasın.
- Görsel açıklaması sayfa düzeninin parçası: `_captionBand` sarma bandına,
  sayfa boyuna, çarpışmaya ve araç paneli konumuna eklenir.
- **İkinci tur (2026-10-28):** biçim paneli açıkken geri PANELİ kapatır
  (sıra: kayıt → panel → arama → not). Panelde "Tümüne/Maddeye uygula"
  (`_applyToAll`): imleçteki etkin biçimler (bekleyenler dahil; başlık
  hariç) alanın TAMAMINA yazılır, alan tümüyle seçili kalır. Madde
  BAŞINDA Backspace (tuş olayı — Gboard silinecek harf yokken DEL yollar)
  `mergeIntoPrevious` ile üst maddeye birleşir (işaretli/işaretsiz sınırında
  ve ilk maddede yok). Bağlantıya DOKUNUŞ (`tappedLink`/`handleLinkTap`,
  gövde + madde): okurken (alan dokunuştan önce odaksız — `TapPointTracker.
  wasFocused`) açar, yazarken bildirimde "Aç" önerir; bağlantı aranırken
  MANTIKSAL metin (sarma çapası adresin ortasına düşebilir). Gövdeye TEK
  SEFERDE giren YouTube adresi (`pastedYouTubeUrl`) videoyu imlecin satırına
  gömer (bağlantı yazıda kalır, "Geri al" kaldırır). YouTube bağlantısına
  DOKUNUŞ (2026-10-29) "Nota göm / Bağlantıya git" sorar (`handleLinkTap`
  `onEmbedVideo`); "Nota göm" = `_embedLinkedVideo`: video yoksa gömülür,
  üste sabitlenir.
- Görünüm levhası (2026-10-29): temaların altında "Düz renkler" (NoteColor
  kartları + palet, `onColor` canlı; tema kalkar); "Sade" tema VE rengi
  kaldırır. Levha `isScrollControlled` (9/16 sınırına sığmıyordu).
- Madde Enter'ı (2026-10-28) `_enterAt`: imleç ortadaysa madde BÖLÜNÜR
  (sağ kısım yeni maddeye, imleç başına), sondaysa altına boş, baştaysa
  üstüne boş madde. Uzun basış menüsü iki sıra (`_ItemMenuPanel`: yıldız ·
  seç · taşı · sil / çizgi türleri + ayar); aynı türe basmak kaldırır.
- **TUZAK (2026-10-28, "işaretleyince donma kasma"):** ItemsEditor'ın
  İŞARETLİ bloğu `_itemRow` ile önbelleksiz kuruluyordu → her tuşta/
  işarette/görsel eklemede bütün üstü çizili satırlar baştan. Footer'daki
  satırlar da `_cachedItemRow`'dan geçmeli.
- **2026-10-30 tur (10 madde):** bekleyen biçim özel rengi `#RRGGBB`
  yazar (`richIndexToken`; eskiden ARGB ondalığı `%%4290190364:..%%` → ham
  görünüyordu; kalıp eski ondalığı da okur). Belge (balonlu) notunun
  belgesi kalmayınca not METİN notuna döner (`_withoutOrphanDocumentMode`:
  `_mutate`te yalnız belge KAYBOLUNCA — boş "PDF ekle" notu belgeyi henüz
  beklerken dönüştürülmez — ve açılışta `startPdf/startSlides` değilse).
  Ek silinince ona bağlı etiketler çözülür (`_removeAttachment`); eki yok
  olan bağ `attachmentNames`e girmez. Biçim panelinde KAPSAM sırası
  (`FormatScope` İmleç/Kelime/Satır/Tümü, `scopeSelection`; oturum boyu
  statik) — imleç boşken biçim/boyut seçimi kapsama genişletir; seçime
  boyut ± satır içi kademede adım atar. Madde ALT ÇİZGİSİ uzun basış
  menüsünden panele taşındı (`dividerKind/onDivider`, hedef madde
  `itemIdForController`). Madde sil "x"i yer TUTMAZ (`_kTrailingWidth` 8),
  yalnız odaklı BOŞ maddede yüzer. Geri getir (yinele) hep görünür.
  **Jestler KİPSİZ** (ikinci tur, kullanıcı kararı; ayar `item_gestures`,
  varsayılan açık, senkronlu): `ink_gestures.dart` saf `classifyInkGesture`;
  içerik alanının ham `Listener`ı maddede başlayan TEK işaretçinin yolunu
  toplar (jest yarışına girmez). Jest SAYILMAZ: 400 ms'den geç kıpırdama
  (uzun basış/sürükle), dokunmatikte < 120 ms (fiske), sayfa > 6 px kaydıysa,
  alanda yeni dolu seçim açıldıysa, çoklu seçim kipinde. Kalem maddede
  başlarsa el yazısı tuvali açılmaz. Üstünü çiz/✓ → işaretle, karala → sil,
  daire → AI yazım. Örtü (`InkGestureLayer`) yalnız "daire çizerek bağla"da.
  Kapsam: ilk kapsamın açtığı seçim DOLU kaldığı için sonrakiler takılıyordu
  → `_scopedSelection/_scopeCaret` (kapsamın kendi seçimiyse imleçten yeniden
  hesap; biçim işaretleri kaydırınca `_rebaseScope`). Madde "x"i odaklı
  maddede HEP görünür, sabit 28 dp sütunda. Yazı tipi kasması: gömülü
  yazı tipinin İLK kullanımı motora "fontlar değişti" dedirtip BÜTÜN metni
  yeniden yerleştiriyor → `preloadNoteFonts` main'de Firebase'le paralel,
  runApp öncesi ≤ 400 ms beklenir (web'de yok). "Buraya bağla" şeridinde ✍ → daire içine al
  (`editableTextAt` öğe ağacını dolaşır, `selectionInside`). Önizlemede
  "Nota aktar" = bağı çöz + görünüm Yüzen. Madde seçim çubuğunda
  "Kopyala ve işaretle".
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

- **Bölme yazımları CANLI ek taşır (2026-10-30):** `PdfNotePane`/
  `SlideNotePane._live()` ve `PdfPageBox` çizim + balon + gizli bayrağını
  denetleyicilerin O ANKİ hâlinden kurar. TUZAK: `widget.attachment.copyWith`
  bayattır (editör yeni eki sonraki karede verir) — gizli balonların üstüne
  basılı tutup bırakmak "göster"i eski bayrakla geri eziyordu. Tam ekran
  görüntüleyiciler aynı işi `_current` ile yapar. Tam ekrana geçerken önce
  `_bubbles.save()` + `_live()`. Bölmenin `dispose`unda kayıt YAPMA (kilitli
  ağaçta editörün setState'i patlar).
- `BubbleController._sameContent` başlık/acil/ok/biçim/dikdörtgenleri de
  karşılaştırır (eksikti: tam ekrandan dönen başlık değişikliği yutuluyordu);
  `dropEmpty` başlığı olan balonu silmez. Tutamaç ve vurgu dokunuşu ham
  işaretçiyle (`BubbleDragArea._quickTap` < 200 ms, vurguda `TapToCollapse`) —
  arenadaki tap çift dokunuş yüzünden ~300 ms gecikiyordu.

## Ses ve yapay zekâ
- Seslendirme TEK kapı `SpeechService` (F3.9): motor ayardan (cihaz / AI /
  Antalia); seçilen düşerse cihaza geçer ve sebebi söyler. Ayarlardaki
  DENEMELER de `SpeechService.preview` ile (2026-10-23: motorları doğrudan
  çağırınca Antalia + AI sesi üst üste çalıyordu); motor değişince `stop`.
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
  `card_show_media` = görseller, `card_show_files` = dosya ekleri (2026-10-23
  ayrıldı; Süz levhasında da kısayol).
- Klasör ekranı ana ekranla eş (2026-10-28): Süz levhası
  `showFilterSheet(folderId:)` — durum/etiket KLASÖRE özgü
  (`folderFilterProvider`, klasör kimliğine göre harita, oturum boyu),
  görünüm/sıralama ortak; liste görünümü, uzun basışla seçim + seçim
  çubuğu (taşı/arşivle/sil/sabitle/yıldız). Seçim kümesi ortak sağlayıcı:
  klasör kapanınca boşaltılır.
- Paylaşım "Var olan nota": `cardBuilder` verilince ana ekran kartlarıyla
  ızgara (`_PickableCard`: kart dokunuşu kapalı, seçer); testte satır liste.
- Paylaşılanlar ana ekranda (`home_show_shared`, varsayılan kapalı):
  AYRI bölüm `SharedNotesHomeSection` — kendi notlarımın ızgarasına
  karıştırılmaz (seçim/sıralama/toplu iş yalnız kendi koleksiyonumu bilir).
- Kalem (2026-10-23): ayarlar cihazda `InkToolMemory` (main'de attach;
  senkron YOK). "Yalnız kalemle yaz": parmak çizmez, `InkNavLayer` tek
  parmakla kaydırır; ilk kalem dokunuşunda kendiliğinden açılır (elle
  seçilmediyse). Kalem değerken parmaklar (avuç) gezinmede yok sayılır.
  Yan düğme / ters uç = geçici silgi. Geri al/yinele jest başına anlık
  liste (silinen de geri gelir). El yazısı tuvali iki parmakla yakınlaşır.
- **Kalem kipi S Note araçları (2026-10-30):** basılı tut → şekil
  (`recognizeInkShape`, PİKSEL uzayında; 550 ms kıpırtısız, `shapeSnap`),
  kement (`InkController.lasso`: seç/taşı/renk seçince boya/sil; araç değişince
  seçim düşer), kısmi silgi (`partialEraser`, çizgi bölünür; ok bütün silinir),
  havadaki kalem önizlemesi (`hover`, `_InkOverlayPainter`). **Kalemi otomatik
  algıla** (`InkToolMemory.autoStylus`, varsayılan açık): editör içerik
  alanındaki `Listener` — belge notunda `_penMode` açılır, metin notunda
  (klavye kapalıysa) el yazısı tuvali. Tepside `PenTrayTool.lasso` en başta.
- Görüntüleyicilerde "Eki kopyala" (`CopyAttachmentButton`): uygulama içi
  pano + görselde sistem panosu.
- Uzun listeli not açılışı: `ItemsEditor` shrinkWrap'te HEPSİNİ kurar →
  `_rowBudget` ilk karede 18 madde, 380 ms sonra kare başına 14.
- **İşaretli madde soluk hâli KATMANSIZ (2026-10-30):** satırda
  `AnimatedOpacity(0.55)` vardı = madde başına kalıcı OpacityLayer
  (saveLayer); çok işaretli notta kaydırma/geçiş kasıyordu. Solma renk
  alfasında (`_kCheckedDim`, `_dimmed`). Listede kalıcı 0–1 opaklık KULLANMA
  (test: `balloon_list_theme_fixes_test`).
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
- **Not karttan GENİŞLEYEREK açılır (2026-10-28):** `/note/:id` iki yolda da
  `NoteOpenPage` (`lib/app/note_open_route.dart`); `openNoteRoute` kartın
  yerini `NoteOpenOrigin.register` ile bırakır (yalnız PageRoute bağlamı,
  ekranın %60'ından küçük kutu; 2 sn içinde, not kimliği eşleşirse bir kez
  alınır). Dar ekranda kart yerinden büyür, kapanırken kartın O ANKİ yerine
  küçülür (kart yoksa solar); alttaki liste yana çekilmez
  (`canTransitionFrom` false). Geçiş ağacı her karede AYNI yapıda (yalnız
  dönüşüm/kırpma değerleri değişir) — yapı değişirse editörün durumu
  sıfırlanır. Temanın geçişi yine sarılır (üstüne binen ekran, kenardan geri
  çekme jesti). **Kasma (2026-10-29):** geçiş boyunca sayfa `SnapshotWidget`
  (permissive) ile görüntüye alınır; büyüyen kutuda bulanık gölge YOK.
  **2026-10-30:** görüntü yalnız AÇILIŞTA bir kez (t ≥ 0,45) tazelenir,
  kapanışta hiç (her alım ≈10 MB doku; art arda aç-kapa GPU belleğini
  çalkalıyordu). Kapanış boyunca sayfanın `MediaQuery`si donar
  (`_FrozenWhileClosing`) — klavye kapanırken editör kare kare yeniden
  yerleşiyordu.
- **Genel tema varsayılanı KIRIK BEYAZ (2026-10-29):** `AppThemeChoice.offWhite`
  (`AppTheme.offWhite`, ılık beyaz yüzeyler; 2026-10-30'dan beri vurgu
  rolleri ELLE sıcak grafit/toprak/bronz — arduvaz tohumu mavi üretiyordu,
  "mavi detaylar güzel değil"); kayıtlı seçim
  korunur. Arama kutusunun tamamı dokunulur (alan dikey dolgulu + kutuya
  dokunmak odak verir).
- **Not teması (2026-10-28):** palet (üst çubuk `UiItem.topTheme`, biçim
  paneli, Ekle) önce TEMA ŞERİDİ açar (`showNoteThemeSheet`, karartısız,
  dokunulan anında). Temalar dosya değil çizim (`note_themes.dart`): açık/
  koyu tonları ayrı; editörde Scaffold ve üst çubuk saydam, süsleme
  `NoteThemeBackdrop` ile arkada; kartta da çizilir.
- **KENDİ KLASÖRÜM = SÜZGEÇLİ ANA EKRAN (2026-10-28, kullanıcı kararı):**
  `FolderScreen.open` sahibi ben olan klasörde sayfa AÇMAZ,
  `showFolderOnHome` ana ekranı `selectedFolderProvider` ile süzer (durum/
  etiket süzgeçleri bırakılır, okundu damgası atılır, kabuk dışındaysa
  `go('/')`). Geri tuşu süzgeci kaldırır. Paylaşılan klasör (başkasının
  koleksiyonu) hâlâ `FolderScreen`.
- Kart ⋮ "Görsel önizlemesini gizle": `Note.cardMediaHidden` (KOŞULSUZ
  yazılır); kart, liste satırı ve `estimateNoteCardHeight` uyar.
- **Ana ekrana yerleştir:** ⋮ → `NoteShortcut.pin` → kanal
  `pinNoteShortcut` → `NotKisayolu.kt` (`ShortcutManagerCompat`, simge notun
  açık renginde + baş harf) → `notlar://note/<id>`.
- Çizim ekranı (`DrawingScreen`) kalem TEPSİSİ `PenTray`: cetvel(şekiller) ·
  silgi · tükenmez · keçeli · fosforlu; seçili kalem kalkar, ikinci dokunuş
  renk/kalınlık panelini açar. PDF/görsel üstü çizim eski `InkToolbar`da.
- Kişiselleştirme (`Customizable`, `UiItem`): kimlikler kalıcı tercih
  anahtarıdır — değiştirme (`homeMic` = eski `home.voiceAi`).

## Web
- Web derlemesi `--wasm` (F9.4, 2026-10-20): WasmGC'li tarayıcıda skwasm,
  diğerinde aynı çıktının JS yedeği. COOP/COEP başlığı KONMAZ (Firebase
  giriş penceresi, dış görseller) → skwasm tek iş parçacığı. Wasm'da `int`
  64 bit, JS yedeğinde 53 bit — bit işlemlerinde ikisini de düşün.
- Geri tuşu: `HomeFirstRouteInformationProvider` (go_router görünmez
  geçmiş kayıtları yazıyordu).
- Arayüz turu (2026-10-30): yayındaki web sürümü Playwright + Flutter
  semantik ağacıyla gezilebiliyor (yöntem: `KULLANICI_DENEYIMI_PLANI.md`
  Ek A). İlk açılış Firebase'de anonim hesap açar — tur sonunda uygulamadan
  "Hesabımı ve verilerimi sil".
- Açılış (F10.6, 2026-10-31): `#splash` Flutter'ın ilk karesinde DEĞİL,
  `notlar-ready` olayında kalkar (`signalWebReady`: giriş düğmeleri ya da
  `AppFrame`). Yeni bir ilk ekran eklenirse orada da çağır; yoksa 6 sn
  yedeğe kalır. Dil `navigator.language`.
- Web'de Drive ekleri (F4.4): `WebDriveAuth` Google penceresiyle Drive
  kapsamlı jeton (bellekte, ~1 sa); ek `blob:` adresiyle açılır, `blob:`
  `toMap`'te buluta yazılmaz. Web Drive'a yazmaz (ekleri Storage'a).
  Yerel notlar/video yok.
- Web YouTube iframe'i (2026-10-28) `enablejsapi=1` ile kurulur; sekme
  gizlenince (`visibilitychange`) hepsi, rota örtülünce (`TickerMode`
  kapanır) o oynatıcı `postMessage pauseVideo` ile DURUR.

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
  BoM EKLENMEZ (FlutterFire `firebase_core`un BoM'unu kullanıyor). Harita
  köprüsünün yerel Firestore/Auth'u da sürümü `firebase_core`un
  `gradle.properties`indeki `FirebaseSDKVersion`dan OKUR (`firebaseSdkVersion()`).
- **Harita köprüsü — KİŞİSEL, ŞİMDİLİK RELEASE'DE (2026-10-28, kullanıcı
  kararı):** Harita uygulamasında "Hey Harita, not al …" → sıralı yayın →
  `HaritaNotlari.kt`/`HaritaNotAlici` notu Flutter açılmadan, Notlar öne
  gelmeden yerel Firestore ile `users/{uid}/notes`a yazar; klasör "Haritalar"
  (adıyla önbellekte yoksa sabit kimlik `haritalar`). Oturum yoksa cihazda
  sıraya alınır, `configureFlutterEngine`de yazılır. Cevap kodu 1 yazıldı /
  2 sıraya alındı. **Kanallarım da aynı alıcıyı kullanır (2026-10-29):**
  isteğe bağlı ekler `folder` (klasör adı, sabit kimlik = adın küçük harf
  harf/rakamları, ör. `youtube`), `title`, `pinned`; Kanallarım'daki "Not al"
  ve Harita'nın medya panelindeki not düğmesi "YouTube" klasörüne başlığı
  "video · dk:sn · kanal" olan sabitli not yazar. Ekler yoksa eski davranış.
  **Video notu (2026-10-29):** metinde YouTube bağlantısı varsa (`YouTubeNotu`)
  not `yt_<videoId>` kimlikli belgeye gider: yoksa video üste SABİT
  (`pinHeight` = 16:9, ekranın ≤%45'i) ve başlık = videonun adı (" · dk:sn ·
  kanal" kırpılır) ile açılır; varsa (çöpte değilse) "dk:sn metin" satırı
  gövdenin SONUNA eklenir (bağlantı satırdan atılır). Çöpteki aynı kimlikli
  not yenisiyle DEĞİŞİR. Eski (rastgele kimlikli) Kanallarım notları taşınmadı.
  **Transkript (2026-10-29):** köprü her satırı `ytTodo`/`ytPending`
  (`{s, line, note, at}`) olarak işaretler; uygulama AÇIKKEN (yalnız Android)
  `video_note_transcripts.dart` Gemini ile videoyu bağlantıdan CÜMLE başına
  damgalı döker, tam transkripti videonun transkript eki yapar, her satırın
  altına ±10 sn'lik “…” parçasını yazar (AI cümleleri ≤6 sn taşarak
  tamamlar; AI yoksa `TimedTranscript.excerpt`). Yazım işlemde (iki cihaz
  çift yazmaz); döküm 3 kez olmazsa bırakılır. **Kanallarım kendi ±10 sn
  altyazısını** metnin sonunda "Altyazı (1:24 – 1:44):\n<ham>" bloğu olarak
  gönderir (uçları cümle ortasından kesik): köprü bloğu ayırır, satırın
  altına "“…ham…”" yazar ve `cap/from/to` ile işaretler; Dart onu ham
  altyazı + tam transkriptin çevresiyle AI'a verip düzgün cümlelerle
  DEĞİŞTİRİR (`applyVideoExcerpt`; v1.1.535'in satır içi bloğunu da tanır).
  Hatalar `ErrorLog`a ("video dökümü", "video parçası AI").
  **Kanallarım tam altyazıyı da yollar (2026-10-29):** `transcript` eki
  ("[d:ss] metin", ≤150 bin karakter, Kanallarım `Streams.timedTranscript`)
  → köprü `ytTranscript` alanına → Dart onu öncelikli kaynak yapar, tam
  transkript ekini paragraflı (`fullText`) üretir, alanı siler. Gemini
  dökümü yalnız bu yoksa (Harita'nın sesli notu, eski Kanallarım). YouTube iç API'si (altyazı)
  KAZINMAZ — bot korumasına takılıyor (bulut IP'sinde LOGIN_REQUIRED). **GENEL (public) SÜRÜMDE KALDIR:** `HaritaNotlari.kt` +
  manifestteki `HaritaNotAlici` + build.gradle.kts "Harita köprüsü"
  bağımlılıkları/`firebaseSdkVersion()` + MainActivity'deki `flushPending`
  satırı (başka dokunduğu yer yok; dışa açık alıcı herkesin not yazmasına izin
  veriyor). Not yazma ortak `YerelNot.kt`'de; yerel Firestore/Auth Gemini
  işlevleri için de gerekli, köprü silinince ikisi KALIR. **TUZAK:** alıcı Firestore'u Dart'tan önce başlatabilir; ayarı
  main.dart'takinin AYNISI (persistence + `firestoreCacheBytes`) olmalı —
  farklıysa FlutterFire `setFirestoreSettings`te istisna atar.
- **Gemini işlevleri — AppFunctions (2026-10-28):** `Ajan.kt` (Android 16+):
  not ekle / ara / son notlar / notu aç. Flutter açılmaz; yerel Firestore
  (`YerelNot`). **Kilitli notlar ve gizli klasördekiler ajana HİÇ dönmez.**
  Sorgu yalnız `deletedAt == null`, sıralama cihazda (eşitlik + başka alanda
  orderBy bileşik dizin isterdi). `openNote` `notlar://note/<id>` PendingIntent
  döndürür (ajan arka plandan Activity açamaz). 1.0.0-beta01 AGP 9.1+ istedi:
  AGP 9.0.1 → 9.1.0, KSP 2.3.12 eklendi. Kısayollar: "Yeni not", "Yeni liste".
- Kesin geri tuşu davranışı `alwaysHandleBack` (iç kabuk Navigator'ı sayfasız
  rota açınca bildirim yanlış Navigator'dan gidiyordu).
- `SnackBar(action:)` varsayılanı `persist: true` → `timedSnackBar`.
- Bildirim (F8.3): düz metin için `messenger.showMessage(metin)` /
  `showAppMessage(context, metin)`; eylemliyse `action:` (geri sayımlı).
  Elle `SnackBar(content: Text(...))` kurma.

## Faz 10 kararları (2026-10-31)
- **Hata metni (F10.4):** kullanıcıya `'$e'` GİTMEZ — `friendlyError(l10n, e)`
  (`core/friendly_error.dart`); ham metin `ErrorLog`a, `showMessage` az önceki
  hatanın bildirimine "Ayrıntıyı kopyala" ekler (5 sn penceresi). Kendi
  okunur iletisi olan istisna `UserFacingException` uygular.
- **Misafir (F10.5):** hesap isteyen giriş GİZLENMEZ, `AccountLockBadge` ile
  görünür; dokununca `showAccountRequiredSheet` (Google bağla, uid korunur).
  AI: `aiGuestLockedProvider` (misafir + anahtarsız) → `GuestAiCard` +
  `GuestAiDim`.
- **Çok sayfalı not (F10.2):** paylaşım/kopya/PDF-Word metni bütün
  sayfaları yazar ("Sayfa N"; tek sayfada başlık yok). Etkin sayfa
  `body/items`ten.
- **Bekleme penceresi + oturum değişimi (F10.7):** oturumu düşüren işin
  penceresi `DialogRoute` tutulup `isActive` ise `removeRoute` — router
  pencereyi kaldırabilir, körlemesine `pop()` alttaki sayfayı atar.

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
