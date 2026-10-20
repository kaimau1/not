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
- **`kClientDataVersion` = 2** (Faz 3). `config/app.minClient` konsoldan elle;
  telefonlar güncellenince 2 yazılmalı.
- `merge: true` yazımında kaldırılabilir/varsayılana dönebilen alanlar
  KOŞULSUZ yazılır (`fontScale`, `textOpacity`, `backgroundImageId` null…) —
  yoksa eski değer Firestore'da kalır.
- Her paylaşılan-yol bulut yazımı `updatedBy == auth.uid` taşır; 'write'
  rolü yalnız `createdBy == uid` notu günceller (F1.4). Yeni yazım yolu
  eklerken `updatedBy`'ı unutma.
- `updateNote`: ek listesinin özeti son başarılı yazımla aynıysa
  `attachments` yazılmaz (`identical` değil özet — editör her yankıda yeni
  liste kuruyor). `localPath` Firestore'a yazılmaz, cihazda türetilir.
- 1 MiB sınırı: ≥ 900 KB'ta kullanıcı uyarılır (en büyük kalem adıyla);
  yazım reddi yutulmaz (günlük + Crashlytics + bildirim).
- **Ağır alanlar ayrı belgede (F3.13):** ağır kısmı (ek `ink`/`bubbles`/
  `pdfMarks`) 96 KB'ı aşan not bölünür: ana belgede hafif ekler + `heavyRef`,
  `notes/{id}/heavy/data`da ek kimliğine göre ağır alanlar. Liste akışı HAFİF
  not verir (`heavyMissing`); editör akışı (`watchNote`) birleştirir.
  **TUZAK:** hafif not yazılırken ağır belgeye DOKUNULMAZ (eksik veriyle
  üstüne yazma yolu kapalı). Listedeki notla çizim/balon gereken iş
  (paylaşım, arkadaşa gönder, yalnız bu cihaz) önce `hydrateNote`. Belge
  silmek alt koleksiyonu silmez → kalıcı silme ve hesap silme ağır belgeyi
  ayrıca siler. Metin (`text`, `pageNotes`) ana belgede kalır (arama).
- **Kavram göçleri (F3.6):** `starred` → sabitli (okumada `pinned||starred`;
  sabitleme her yazımda `starred: false`). Zemin + çerçeve → TEK renk +
  "kenarı vurgula" (`frameColor` = vurguda `color`ın aynısı); yalnız
  çerçeveli eski not okunurken çerçeve rengini zemin alır.
- **Defter (F3.5):** ayrı defter editörü (`NoteType.archive`) kalktı; defter
  = `Note.paged` (kâğıt deseni `archivePaper` + hep görünen sayfa çubuğu).
  Eski defter `notebookToPagedNote` ile çevrilir (adlı sayfa → `textPages`,
  ad başlık satırı; yazı + bloklar gövdeye; ekler `section` = sayfa kimliği,
  öksüzler ilk sayfaya). Editör açılışta, `dataMigrationsProvider` arka
  planda bir kez çevirir. `/notebook/:id` eski bağlantılar için editörü açar.
- **Bir defalık göçler** `lib/features/notes/data/data_migrations.dart`:
  bayrak cihazda (`migration_<ad>_<uid>`), hata olursa yazılmaz (yeniden
  denenir); göç `updatedAt`e dokunmaz.
- Notun sayfaları (`textPages`): ETKİN sayfanın içeriği `body`/`items`'ta,
  listedeki girdisi boş; geçiş içerikleri yer değiştirir. İlk sayfa kimliği
  hep ''.
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
  yöntemi, cihazın İLK eşitlemesinde bulut kazanır. Tercih sağlayıcıları
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
- `ConsumerState.dispose` içinde `ref` kullanılamaz (istisna) — denetleyiciyi
  build'de alana al.
- Türetilmiş sağlayıcılar içerik aynıysa ÖNCEKİ örneği döner (`StableBox`,
  not listelerinde örnek kimliği — `sameInstances`).
- Toplu işlemler tek `WriteBatch` (`batchUpdateEach`, 450'lik parçalar).
- Ana ekran ızgarası: deterministik sütun ataması (`balancedColumnAssignment`,
  tahmini yükseklik) + sütun başına tembel `SliverList`. Masonry kartı
  yerleşim anında atıyordu → kaymalar/boşluklar.
- `planTextWrap` yalnız bandı kapsayan öneki ölçer (eskiden O(satır×metin));
  imleç ve ipucu dolgusu TEK işlevden (`wrapLineIndents`) — "ipucu ile imleç
  ayrı yerde" bildirimi gelirse önce iki hesabın aynı kaynaktan beslendiğine
  bak.
- Animasyonda `Timer` değil `FrameLoop` (Ticker; adım 60 Hz'e göre ölçekli).
- `DateFormat` kart başına kurulmaz (desen+dil anahtarlı önbellek; `static
  final` olamaz — dili dondurur).
- Kopya taraması `compute` ile; web'de `<<` 32 bit → trigram kodu çarpmayla.

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
- Editör yeniden çizimi `sameRenderedNote`'a bakar: yeni GÖRÜNÜR ek alanı
  eklenince oraya da ekle.
- Uzun basış CÜMLE seçer (`sentence_select.dart`).
- Canlı dikte: tanıyıcı her olayda TAM metni yollar ve düzeltir → "ekle" değil
  "değiştir". Akıllı komutlar ham metni her olayda baştan işler.
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

## Ses ve yapay zekâ
- Seslendirme TEK kapı `SpeechService` (F3.9): motor ayardan (cihaz / AI);
  AI düşerse cihaza geçer ve sebebi söyler.
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

## Arayüz kararları (Faz 3, 2026-10-19)
- Ana ekranda TEK mikrofon (F3.1): dokunuş son kipi (sesli not / doğrudan
  yazdır) açar, basılı tutmak öbürünü (`homeMicDictateProvider`); klasörde
  sesli not "+" menüsünde.
- "+" menüsü dört kapı (F3.2): Metin · Liste · Kamera · Dosya ekle · Şablon.
  Dosya ekle tek seçici; seçilen dosya akışın kendi seçicisine
  `DocPicker.preselect` ile verilir (akış sonunda temizlenir).
- Balonlu/Klasik levhası yalnız ilk sefer; seçim varsayılan
  (`capture_mode_default`), Ayarlar → Notlar ve klasörler.
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
- Geri tuşu: `HomeFirstRouteInformationProvider` (go_router görünmez
  geçmiş kayıtları yazıyordu).
- Web'de Drive ekleri (F4.4): `WebDriveAuth` Google penceresiyle Drive
  kapsamlı jeton (bellekte, ~1 sa); ek `blob:` adresiyle açılır, `blob:`
  `toMap`'te buluta yazılmaz. Web Drive'a yazmaz (ekleri Storage'a).
  Yerel notlar/video yok.
- Yerel sunucu: `python -m http.server --directory <mutlak>` (silinip yeniden
  kurulan klasörü eski hâliyle sunar).

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

## Test tuzakları
- Veri katmanı testi: `fake_cloud_firestore` (`notes_repository_data_test`).
- Widget testinde `Picture.toImage` / `rootBundle` / PNG kodlama sahte zamanda
  ilerlemez → `tester.runAsync`.
- Test binding'i en_US koşar; Türkçe metin bekleyen testte `locale: tr`.
- Tembel `ListView` ekran dışını kurmaz → `ensureVisible` bulamaz.
- Yerleşim testi tasarım değişince kırılır, kırılmalıdır da: niyete göre
  güncelle.
