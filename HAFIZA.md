# Not Uygulaması — Hafıza (geçerli kararlar ve tuzaklar)

İş başında oku; iş sonunda kalıcı karar / kök neden / tuzak varsa ilgili
bölüme EKLE (tarihli, kısa). Sır/anahtar/kişisel veri YAZILMAZ. Hedef
≤ 30 KB. Tarihçe ve uzun gerekçe: `HAFIZA_ARSIV.md` (→ 2026-10-19) ve
`HAFIZA_ARSIV_2.md` (→ 2026-11-02, F18.24'te sıkıştırılmadan önceki TAM
hâl) — ikisi de dondurulmuş, `grep` ile ara. Kural değişince buradaki
maddeyi GÜNCELLE.

## Ortam ve araçlar
- Flutter **3.47.7** (CI ile aynı). Bulutta SDK yok: linux arşivini
  scratchpad'e indir (CLAUDE.md). Windows'ta `C:\src\flutter\bin\flutter.bat`.
  pdfrx 2.6 Flutter ≥ 3.47 ister.
- **`dart format` yalnız değiştirdiğin/yeni dosyaya** (`lib/l10n/generated`
  hariç: `flutter gen-l10n` sonrası hep formatla).
- `flutter test -j 4` (~2 dk). Yerel Flutter yolu uzunsa `flutter analyze`
  patlar → `dart analyze lib test`. CI `flutter analyze` BİLGİ (info) düzeyini
  de hata sayar — push'tan önce bilgi satırı da kalmasın.
- `flutter install` DERLEMEZ. Yerel APK'da `--build-number` (yoksa
  versionCode 1 → DOWNGRADE) ve `--dart-define-from-file=env.json` (yoksa
  Google girişi çöker) ZORUNLU.
- **Bulutta APK derlenebilir** (2026-11-02'de yine yapıldı, ~15 dk ilk derleme):
  Maven 429 için init betiği YETMEZ — Flutter'ın kendi `flutter_tools/gradle`
  dahil derlemesi ayrı; scratchpad'deki SDK'nın `settings.gradle.kts`ine ayna
  `maven {}` satırı (pluginManagement + dependencyResolution) elle eklenir. scratchpad'e cmdline-tools → `sdkmanager
  "platform-tools" "platforms;android-37.0" "build-tools;36.0.0"
  "ndk;28.2.13676358"`, `flutter config --android-sdk`. Maven Central 429 →
  `$GRADLE_USER_HOME/init.d` betiğiyle Google aynası (depo EKLEME; Flutter
  PREFER_SETTINGS). Anahtar deposu yok → DEBUG imzalı, telefondaki CI
  sürümünün üstüne kurulmaz. Oturum `workflow_dispatch` tetikleyemez (403)
  → CI işleri commit BAŞLIĞI etiketiyle (`[apk]`, `[perf]`).
- graphify grafiği elle (`graphify update .`; bulutta `pip install graphifyy` ile venv'e); satır bilgisini koddan doğrula.

## CI (`.github/workflows/build.yml`)
- APK yalnız main'de, commit **BAŞLIĞINDA** `[apk]`; dalda derlenmez. APK
  testi beklemez; Release TASLAK, `release` işi testler yeşilse yayınlar
  (+ F18.21: `tool/set_latest_build.js` → `config/app.latestBuild/
  latestName`), kırmızıysa siler. Sürüm adı `1.1.<koşu>`, versionCode koşu no.
- **`[perf]`** (F18.7, 2026-11-02): başlıkta varsa kare ölçümü HER dalda
  koşar; özet iş günlüğüne de basılır. **KÖK NEDEN (2. oturum):** yayın APK'sı
  yalnız arm64 paketliyor (`abiFilters` + `jniLibs.excludes`) → x86_64
  emülatörde `libflutter.so` yok, uygulama açılışta çöküyor, `flutter drive`
  sonsuza dek bekliyordu (`| tail` de çıktıyı saklıyordu). Ölçüm işi
  `NOTLAR_ALL_ABIS=1` verir; drive 20 dk'da kesilir. TUZAK: odaktaki metin alanının
  imleci sürekli kare ister → `pumpAndSettle` HİÇ bitmez (ilk koşu 34 dk
  çıktısız kaldı) — `integration_test/perf_test.dart` sabit süreli pompalar.
  `workflow_dispatch` perf Deploy+Release'i de koşturur.
- APK işi kullanılmayan araç zincirlerini siler (disk). `.so` sıkıştırılır;
  yalnız arm64 (`packaging.jniLibs.excludes`). Artifact yalnız elle koşuda.
- Gradle önbelleği restore/save ayrı adım. `secrets` step `if:`'inde yok →
  bash'te kontrol.
- Deploy (main): web (Cloudflare Pages, `build/`), kurallar, Functions
  (`continue-on-error`, Blaze). Web derlemesi `RECAPTCHA_SITE_KEY` secret'ını
  geçer (F18.1). `rules` işi emülatörde (Java 21); yerel `cd rules-test &&
  npm ci && npm test`.

## Veri modeli ve Firestore
- **İleri uyum (F1.5):** `Note`/`Attachment`/`NoteItem` tanımadığını
  `extras`ta saklayıp aynen yazar; yeni alan → `knownKeys` (`forward_compat_test`).
  Bilinmeyen ek türü `unknown` + `rawKind`.
- **`kClientDataVersion` = 3**; `config/app.minClient` konsoldan elle
  (telefonlar v1.1.N'e geçince 3).
- `merge` yazımında kaldırılabilir alan KOŞULSUZ yazılır (`fontScale`,
  `theme`, `customColor`, `cardMediaHidden`, `reminderRepeat`, `cards`…).
- Paylaşılan-yol yazımı `updatedBy == auth.uid` taşır; 'write' rolü yalnız
  `createdBy == uid` notu günceller (F1.4).
- `updateNote`: ek listesi son başarılı yazımın DERİN KOPYASIYLA aynıysa
  `attachments` yazılmaz. TUZAK: kopya şart (etkin çizgi listesi yerinde
  büyür). `localPath` Firestore'a yazılmaz.
- Ek `createdAt` boşsa `toMap` dizinin içine `serverTimestamp` yazar —
  Firestore dizide kabul etmez: paket/yedek içe aktarma (`NoteShare.import`)
  boş tarihi doldurur (F18.4).
- Çizim noktaları kayıttan `Float32List`; `toMap` `UnmodifiableListView`
  verir (tipli dizi sunucuda reddedilir); kayıttan okunanı yerinde
  değiştirme. Kalem basıncı `pressures` (`q`).
- 1 MiB sınırı: ≥ 900 KB'ta uyarı; yazım reddi yutulmaz.
- **Ağır alanlar ayrı belgede (F3.13):** ek `ink/bubbles/pdfMarks` 16 KB'ı
  aşınca `notes/{id}/heavy/data`, ana belgede `heavyRef`. Liste akışı HAFİF
  not verir (`heavyMissing`); dışarı metin/veri üreten her yol önce
  `hydrateNote` (paylaş, kopya, toplu seçim — F18.12, yedek). Hafif not
  yazılırken ağır belgeye dokunulmaz. Kalıcı silme / yalnız bu cihaz / hesap
  silme alt koleksiyonları (`heavy`, `versions`, `presence`) ayrıca siler
  (`_deleteCloudCopy`).
- `starred` sabitlemeden ayrı; `frameColor` yalnız ana ekran kartında.
- Defter = `Note.paged` (+ `archivePaper`); eski defter `notebookToPagedNote`.
  Bir defalık göçler `data_migrations.dart` (bayrak cihazda; `updatedAt`e
  dokunmaz). Çizgili kâğıt satırı İÇERİKTEN çizer (`RuledLines`).
- Madde ayırıcı `NoteItem.divider` = `tür|c:AARRGGBB|w:1.50`; satırı çizen
  YENİ alan `_cachedItemRow` anahtarına + `sameItemsVisually`e.
- Sayfalar `textPages`: ETKİN sayfa içeriği `body/items`'ta; ilk sayfa
  kimliği ''. Kopya (`duplicateNote`) sayfaları da taşır (F18.8 yakaladı).
- Satır içi biçim metnin İÇİNDE işaretle (`**`, `_`, `~`, `==k:`, `%%k:`,
  `##k:`, `&&k:`; özel renk `#RRGGBB`); önekli işaret öneksiz eşleşmez.
- **Ek etiketi / not bağlantısı:** metinde `📎 etiket`, notta `tagLinks`
  (label → `attachmentId`). Not bağlantısında kimlik `note:<id>` (F18.16) —
  bağ KİMLİKLE, başlık değişse de kalır; eski sürüm düz metin görür. Geri
  bağlantılar istemcide türetilir (`backlinksTo`). `[[` not seçiciyi açar.
- Yerel notlar `LocalNotesStore` (haritayı yerinde değiştirme).
- `authStateProvider` `userChanges` üzerinden (anonim → Google bağlanınca
  uid aynı, `authStateChanges` tetiklenmez).
- Hesap silme listeleri `AccountService`'te; yeni koleksiyon
  `account_deletion_test`i kırar (bilinçli). `premiumUntil` istemciden
  yazılamaz. Kural tuzağı: `{document=**}` sıfır parçayı da eşler.
- Sürümler (F4.2) `notes/{id}/versions` yalnız metin, 30 tavan. Eşzamanlı
  düzenleme üç yönlü birleştirme (`text_merge.dart`), `presence/{uid}`.
- Ayar senkronu `users/{uid}/meta/prefs.values`; cihaza özgü anahtar
  (kalem, uygulama kilidi, Gelen klasörü…) listeye EKLENMEZ.
- Not kilidi (F4.8) cihaz/şifre/desen, ŞİFRELEME DEĞİL. **Uygulama kilidi**
  (F18.6, varsayılan kapalı, cihaza özgü `app_lock_*`): aynı yöntem,
  `AppLockGate` kapağı gezginin ÜSTÜNDE (bildirim/widget/kısayol açılışı
  da takılır) ve kendi `Navigator`ü var (şifre penceresi kapağın üstünde).
  Web'de cihaz kilidi yok → yalnız şifre/desenle. Biyometrik pencere yaşam
  döngüsünü oynatır: sorarken sayaç başlamaz. Android `setSecure`
  (FLAG_SECURE).
- FCM jetonu `users/{uid}/fcmTokens`; not düzenlemesi için itme yok.
- **Tekrarlayan hatırlatıcı** (F18.14): `reminderAt` hep SONRAKİ çalma,
  `reminderRepeat` dizesi (`daily`, `weekdays`, `weekly:1,3`, `monthly:31`,
  `yearly:2-29`) — ay/yıl GÜNÜ dizede (çapa kısa ayda 28'e kıstırılır).
  Servis sonraki 7 çalmayı önceden kurar (kimlik `noteId#k`), geçmişte
  kalanı nota ilerletir; "Tamam" sonrakine kaydırır, "Ertele" tek seferlik
  `#snooze` bildirimi (reminderAt'i kaydırmak saati kaydırırdı).
  `orphanReminderIds` not başına kimlik KÜMESİ alır. Yeni planlı bildirim
  türünün yükü `note:` ile BAŞLAMAZ. Eski istemci yalnız ilk çalmayı bilir.
- **Aralıklı tekrar kartları** (F18.19, kullanıcı: basit sürüm): `Note.cards`
  (`StudyCard`, SM-2 `reviewCard`), yeni koleksiyon yok (hesap silme/kural
  değişmedi). Editör ⋮ "Kart üret" (AI), `/cards` "Bugünün kartları".

## Yedek ve içe aktarma (F18.4/F18.5/F18.15, 2026-11-02)
- Tam yedek `.notyedek` (ZIP): `yedek.json` (`kind: full-backup`, not
  girdisi = `encodeNoteJson` + hesap alanları + içerik özeti) +
  `dosyalar/<not>/<ek>`. Cihazda `FileBackupSink` dosyaya akıtır, web'de
  bellekte. Geri yükleme kimlik / `restoredFrom` / içerik özetiyle (`noteDigest`:
  tür+başlık+gövde+madde) çift kaydı atlar; klasörler ADLA eşlenir. Eski
  JSON yedek de okunur (`sniffBackup`: `PK` / `{`). Kilitli not varsa dışa
  aktarma kimlik ister.
- `BackupService` arayüzden bağımsız; misafir → var olan Google hesabı
  (`credential-already-in-use`) "Notları yanıma al": giriş ÖNCESİ bellekte
  yedek, sonra hedefe yükleme. Misafirin bulut kopyası kalır (oturum
  değişince silinemez).
- İçe aktarma `import_service.dart`: Keep Takeout (renk eşlemesi, sabit,
  arşiv, çöp, etiket, görsel/ses, tarih), Markdown/txt (`# başlık`,
  `- [ ]`, `__x__`→`**x**`, `*x*`→`_x_`), Evernote `.enex` (ENML → metin).
  Aynı özet atlaması.

## Riverpod / performans
- Riverpod 3 görünmeyen ekranın ve DİNLENMEYEN sağlayıcının aboneliğini
  DURAKLATIR: oturum boyu servisler `lib/app/app_services.dart`ta; testte
  sağlayıcıyı okumadan önce `container.listen`. Tek nota/klasöre bağlı akış
  `.autoDispose.family`; autoDispose'u `ref.read` ile okuma.
- Notifier örneği yeniden kurulumda korunur. Hesaba bağlı bellek önbelleği
  `currentUidProvider`ı izlesin (F5.5).
- Kart küçük resmi bütçesi 64 adet / 6 MB; PDF sayfası çizen her yol
  `data/pdf/pdf_page_render.dart`. Tam boy `Image.file/memory` KULLANMA →
  `boundedImage` / `cacheWidth: decodeWidthBucket`.
- Ağır iş `runHeavy` (`core/utils/run_heavy.dart`) — `Isolate.run` doğrudan
  yazılmaz (web'de yok); kapanış statik yardımcıda. Web'de
  `getTemporaryDirectory` yok → `XFile.fromData`.
- `localFileExists` "yok"u 2 sn önbellekler → dosya yazan `forgetLocalFile`.
- `ConsumerState.dispose` içinde `ref` yok. Türetilmiş sağlayıcı içerik
  aynıysa önceki örneği döner (`StableBox`). Toplu işlem tek `WriteBatch`
  (450'lik). Animasyonda `FrameLoop`.
- Ana ekran ızgarası deterministik sütun ataması (`balancedColumnAssignment`).
  Kesme noktası geçişinde `DashboardScreen` başka yerde yeniden kurulur →
  kaydırma `DashboardScrollMemory`de ORANLA taşınır (F18.11).

## Editör, klavye, metin
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
- Klavye açılınca üst parçalar yeniden ölçülmez (`KeyboardClipWindow`);
  sabit görsel ölçeklenir, metin/PDF kırpılır.
- Not açılışı: önbellekteki hafif notla açılır, akış değişikliği ~450 ms
  sonra (`_setStateAfterOpening`; `ModalRoute.of` kullanma). Not karttan
  genişleyerek açılır (`NoteOpenPage`, geçiş ağacı her karede AYNI yapı;
  `SnapshotWidget` yalnız açılışta bir kez).
- Biçim paneli üç sabit sıra (Stil · Renk · Yazı), açılır menü YOK; kapsam
  `FormatScope` (İmleç/Kelime/Satır/Tümü). Panel açıkken geri paneli kapatır.
- ItemsEditor: işaretli blok da `_cachedItemRow`'dan; soluk hâl renk
  alfasıyla (kalıcı Opacity katmanı YOK). Madde Enter'ı `_enterAt` (böler),
  başta Backspace üst maddeye birleşir. Jestler kipsiz (`classifyInkGesture`).
- Yazı tipi ilk kullanımda bütün metni yeniden yerleştirir →
  `preloadNoteFonts` main'de, ≤ 400 ms.
- Canlı dikte TAM metni yollar ("değiştir"); bipler MainActivity'de
  susturulur. Tek mikrofonu son açan alır.
- Sayfa üstü el yazısı `Note.pageInk` (sahte `_page_ink` eki; `isEmpty`
  ona bakar). `InkPageLayer(uniform: true)` → y de genişliğe bölünür.
  Kalem `EagerGestureRecognizer` altsınıfıyla arenayı kazanır, parmak metne.
  **Not editöründe kalemler ALTTA çekmecede** (`PenTray(dock: true)`, kullanıcı
  isteği 2026-11-02 — tablet sol sütunu kalktı): sayfanın ÜSTÜNDE yüzer
  (yerleşim değişmez), çizim başlayınca/6 sn dokunulmayınca iner (açık renk
  paneli de kapanır — panel açıkken inmiyordu), yalnız tutamak + seçili renk
  noktası görünür; tek dokunuşla açar. 2026-11-02 yeniden tasarım: TEK SATIR
  (tutamak 24 + şerit 56), dar ekranda yinele/yalnız kalem/ayarlar "⋯"
  menüsünde, ≥640 dp'de içerik kadar ortada; panel tepsinin ÜSTÜNDE ayrı
  kart. Mürekkep katmanında fare imleci `precise` (metnin I imleci kalınca
  çizgi "tıkladığım yerin üstünde" görünüyordu; koordinat doğru, testli). Belge/görsel/çizim ekranları eski şerit/sütunu kullanır
  (`PenTray.useRail` = PENCERE ≥ 600 dp). Tam ekran `noteFullscreenProvider`.
  "+ → Çizim ekle" = ayrı `DrawingScreen` → PNG görsel eki; "Sayfaya el
  yazısı" (`handwriting`) = kalem kipi.
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

## PDF, balon, görüntüleyici
- PDF YAZMA yalnız Syncfusion (`pdf_edit.dart`, `NotePdf`), görüntüleme pdfrx;
  gömülü PT Sans şart. `PdfBitmap` yalnız JPEG/PNG.
- pdfrx'in kendi metin seçimi KAPALI (seçim `PdfSelectLayer`);
  `scrollPhysics` VER; `pageOverlaysBuilder` her matris değişiminde çağrılır
  → `pdfLayerParams` sayfa başına aynı örnek.
- Dışarı dokununca kapatma `GestureDetector(onTap)` ile değil, ham
  `Listener` (`TapToCollapse`). Çizim PDF'e gömülmez (ayrı katman).
- Bölme yazımları CANLI ek taşır (`_live()`); `dispose`ta kayıt yapma.
- Görsele çizim + açık metin (`PageBubble.plain`) dışa aktarmada/paylaşımda
  görselin üstüne BASILIR (`image_annotations.dart`, PNG; F18.13).

## Ses ve yapay zekâ
- Seslendirme tek kapı `SpeechService`; Antalia ONNX isteğe bağlı, yalnız
  Android + tr.
- Sohbet tek ekran `AiChatScreen` (Tüm notlar / Bu not / Bu belge).
  **"Tüm notlar" getirmeli** (F18.18): soruyla alakalı en çok 12 not
  (anlamsal arama; dahili modda gömme yok → kelime örtüşmesi
  `keywordRelevant`) bağlamın başında 1500 karakterle, kalan son notlar
  300 karakterle (toplam 80); yanıtta kaynak not çipleri (`ChatTurn.sources`,
  modele gitmez). İlgili notlar (F18.17) `relatedNotesProvider` aynı yol.
- AI isteği içeride Gemini `contents`; HTTP tek istemci `package:http`
  (`StreamedRequest` gövdesi `addStream` + `whenComplete(close)`).
- Asistan araçlarında `reminderRepeat` argümanı var; tarih ve tekrar
  cümleden yerelde de çıkarılır (`parseSpokenDateTimeNow`,
  `parseSpokenRepeat` tr+en).
- **AI kotası** (kullanıcı kararı 2026-11-02, F18.2/F18.3): sayaç istemcide
  kalır, `aiQuota/{uid}` sunucu saatli YUVARLANAN 24 saat; koruma web App
  Check + Google Cloud kota/bütçe (F19.A1/A2). Ayarlar yenilenme saatini
  gösterir (`aiQuotaRenewsAtProvider`). Sunucu kotası yalnız Play'e çıkılırsa
  (F18.28).
- **App Check** (F18.1): Android Play Integrity (debug sağlayıcısı debug'da),
  web reCAPTCHA Enterprise yalnız `RECAPTCHA_SITE_KEY` derlemeye verildiyse;
  firebase_ai jetonu kendiliğinden taşır. Zorlama konsolda, önce izle
  (elle kurulan APK'yı Play Integrity doğrulayamaz).
- **Google girişi yedeği** (tablet bulgusu 2026-11-02): yerel seçici
  (Credential Manager) yapılandırma hatası verir ya da < 1,5 sn'de "iptal"
  dönerse (seçici hiç açılmadı) Firebase tarayıcı akışına
  (`signInWithProvider`/`linkWithProvider`) düşer
  (`AndroidGoogleAuth.shouldUseBrowserFlow`). Web'de seçici hep
  `prompt: select_account`.
- AI çıktıları `AiCache`te (cihazda). Ek metni indeksi
  `attachment_text_<uid>.json`.

## Arayüz kararları
- Ana ekran tek mikrofon = doğrudan yazdır; AI sesli not Yapay zekâ
  ekranının en üstünde. "+" tek panel. Dosya akışı tek levha
  `showFileUseSheet`; HEIC → PNG.
- "Tümü" çipi kalıcı; kendi klasörüm = süzgeçli ana ekran; "Gelen" çipi ana
  ekranı süzer (`sharedHubOnHomeProvider`), "Gelen" klasörü cihaz tercihi.
  Paylaşılanlar ayrı bölüm (`home_show_shared`, yer
  `homeSharedAtBottomProvider`).
- Süz düğmesi arama kutusunun içinde; varsayılan sıralama "Son güncellenen"
  (`migrateDefaultNoteSort`).
- Kartta görünenler `card_show_*`; kart TEK semantik düğüm, ⋮ ayrı.
- Menüler `ActionMenu`; not ⋮ ve kart ⋮ grupları aynı ad/sıra. Alt çubuk
  sırası sabit: Biçim · Ekle · Ara · Paylaş · Ekler · (☑|Seç).
- Simgeler `lib/core/app_icons.dart` sözlüğünden (`visual_consistency_test`
  doğrudan `Icons.archive/move_to_inbox/…` kullanımını yakalar; F18.15'te
  yakaladı). Levha `SheetHeader` + `SectionLabel` (asla `toUpperCase`).
  Sabit renk yalnız `fixed_colors.dart`. Liste yüklemesi `NoteListSkeleton`
  / `ErrorState`.
- Erişilebilirlik `lib/core/a11y/` (renk adları, çip rolleri, `MinTapTarget`,
  `motionOf`). Okunan metne < 0,8 alfa verme, ≥ 12 punto. Sistem yazı
  boyutu izleme varsayılan kapalı.
- Terimler `TERIMLER.md` (`terminology_test`; Türkçe sınır için Unicode
  bakış, `\b` değil). İpuçları `TipOnce`. Hata metni `friendlyError`.
  Bildirim `messenger.showMessage` (elle SnackBar kurma; kökten
  `rootScaffoldMessengerKey`).
- Arayüz dilleri tr + en. Kılavuz `assets/guide/guide_<dil>.md`
  (`guide_screen_test` eskimiş ifade listesi).
- Kişiselleştirme `UiItem` kimlikleri kalıcı anahtar — değiştirme.
- Misafir: hesap isteyen giriş gizlenmez (`AccountLockBadge`); dahili AI
  misafire kapalı (`aiGuestLockedProvider`).
- "Yeni sürüm var" (F18.21, yalnız Android): `config/app.latestBuild` >
  kurulu derleme (yerel 1 sayılmaz) → sürüm başına bir kez bildirim
  (`update_notice_shown_for`) + Ayarlar → Hakkında satırı.

## Web
- `--wasm` (skwasm, JS yedeği); COOP/COEP yok. Wasm'da `int` 64, JS'de 53 bit.
- Geri tuşu `HomeFirstRouteInformationProvider`. Açılış `notlar-ready`
  olayında (`signalWebReady`).
- Drive ekleri `WebDriveAuth`/`WebDriveGate` (`blob:` buluta yazılmaz). Jeton
  SEKMEDE (`sessionStorage`, uid'e bağlı, ~55 dk — yenilemede yeniden izin
  sormaz); notta `WebAttachmentsBanner`: "N ek Drive'da · Göster" (tek
  dokunuş hepsini indirir) ya da "telefondan çıkmamış" uyarısı (Android'de
  Drive bağlı değilse ekler cihazda bekler — web'in yapabileceği yok). Web
  Drive'a yazmaz; yerel not/video yok.
- **Bulut tarayıcısı TUZAĞI (2026-11-02):** sandbox Chromium'unda yolu `%2F`
  içeren HER Firebase Storage isteği 400 (ön istek dahil; curl'de aynısı
  403/200). Yükleme (`?name=`) geçer, okuma/silme geçmez → web turunda ek
  gösterme, PDF açma ve "Hesabımı sil" ölçülemez/bitmez. Canlı site etkilenmez.
- Web turu: Playwright + semantik ağaç (`KULLANICI_DENEYIMI_PLANI.md` Ek A);
  misafir hesabı tur sonunda sil. App Check web'de anahtarla.

## Android
- `USE_EXACT_ALARM` yok; izin yoksa inexact. QR/OCR Play Hizmetleri'nden.
- **FlutterFire paketleri BİRLİKTE yükseltilir** (tek tek yükseltme APK'yı
  kırdı; testler/web yeşil kalır, yalnız APK işi yakalar). Ayrı Firebase BoM
  eklenmez; köprü sürümü `firebaseSdkVersion()`dan okur.
- **Kişisel köprü** (`android/app/src/kisisel/`, yalnız `NOTLAR_KISISEL=1`):
  Harita / Kanallarım / Asistan "not al" (`HARITA_NOT`, `ASISTAN_SORGU`),
  `dev.kaimau.notlar.izin.ASISTAN` (`signature|knownSigner`) ile korunur.
  Video notu `yt_<videoId>`; transkript `ytTodo/ytPending/ytTranscript`
  akışı (`video_note_transcripts.dart`); YouTube iç API'si kazınmaz. Asistan
  görseli `filesDir/attachments/<not>/<ek>_<ad>`'a, yükleme UploadQueue'da.
  TUZAK: alıcı Firestore'u Dart'tan önce başlatabilir — ayarı main.dart'la
  AYNI olmalı. Ayrıntı `HAFIZA_ARSIV_2.md`.
- AppFunctions `Ajan.kt` (Android 16+): kilitli not ve gizli klasör asla
  dışarı verilmez (`YerelNot.gorunurNotlar`).
- `alwaysHandleBack`; `SnackBar(action:)` → `timedSnackBar`.
- `MainActivity.dropUnreadableShare`: okuma izinsiz `ACTION_SEND` eklentiden
  önce elenir (SecurityException). Kanal `dev.kaimau.notlar/system`
  (`setSecure` dahil).

## Test tuzakları
- Test dosyasına TARİH adı verilmez — özellik adı. Veri katmanı
  `fake_cloud_firestore`; fake, dizideki `serverTimestamp`'i çözmez.
- `Picture.toImage`/PNG/`rootBundle` sahte zamanda ilerlemez →
  `tester.runAsync`. Binding en_US → Türkçe beklenirse `locale: tr`.
- Tembel `ListView` ekran dışını kurmaz. Yerleşim testi tasarımla kırılır:
  niyete göre güncelle.
- Lint: `unawaited_futures`, `unnecessary_lambdas`,
  `avoid_redundant_argument_values`… `dart fix` yorumları da siler.
  Boş `catch` yok (gerekçe yorumu ya da `ErrorLog.record`).
- Cihaz turu (adb/uiautomator): koordinatla basma, levhayı geri tuşuyla
  kapat, `adb input text` boşlukta keser.

## Kısa kurallar (sıkıştırmada tek satıra inenler)
- Ek açıklaması `Attachment.caption` (yalnız doluyken; `withLayoutOf` yereli
  korur), ses dalgası `wave`, not teması `theme` (zemin RENGİ seçen her yol
  `theme: ''` yazar; `noteSurface` temanın alt tonunu verir).
- Görünüm levhası: temalar + "Düz renkler"; "Sade" tema ve rengi kaldırır;
  `isScrollControlled`. Not teması tek kapı üst çubuk palet.
- Kalem: ayarlar cihazda `InkToolMemory`; "yalnız kalemle yaz", yan düğme =
  geçici silgi; S Note araçları (şekil tanıma, kement, kısmi silgi, havada
  önizleme); "Kalemi otomatik algıla" varsayılan açık. Tek tepsi `PenTray`.
- Sesli not kaydı notun içinde (`VoiceNoteRecorder`, hap); kaydedici
  eklentiyi tembel kurar (testte platform kanalı patlar).
- ☑ `_toggleChecklistLine`: gövde hep maddelerin üstünde.
- Görsel açıklaması sayfa düzeninin parçası (`_captionBand`).
- Uzun listeli not ilk karede 18 madde (`_rowBudget`).
- Dinleme alanı tek kart `ListeningCard`; başlık düğmesi
  `ListeningHeaderButton` (34 dp).
- Ayar alanları `ExpandReveal` (+ `_StaggeredRows`, `_followIntoView`);
  arama + ✨ AI kipi (`matchSettings`, yalnız ayar adları).
- Paylaşım iki kavram: Birlikte düzenle / Kopya gönder. Paylaş levhası
  GÖNDER / NOTLAR KULLANICISINA; web'de "Görsel" `pngPages`.
- Ana ekrana yerleştir: `NoteShortcut.pin` → `NotKisayolu.kt` →
  `notlar://note/<id>`.
- Web YouTube iframe `enablejsapi=1`; sekme gizlenince/rota örtülünce
  `pauseVideo`.
- Balon paleti koyu tonlar; eski amber ekranda yeni varsayılanla çizilir.
  `BubbleController._sameContent` başlık/acil/ok/biçimi de karşılaştırır.
- Tek avatar (rozet = yalnız arkadaşlık isteği); geniş ekranda rayda olan
  kapı ⋮'te tekrarlanmaz (`AppRailScope.visible`). Avatar levhasında
  "Hesap değiştir" + "Oturumu kapat" (`sign_out_actions.dart`, Ayarlar da
  aynı kapı; misafirde kırmızı uyarı).
- **Geniş ekran (2026-11-02):** ray 64 dp etiketsiz (adı ipucunda),
  kendiliğinden etiketli ≥ 1600; "Gelen" RAYDA YOK (`railSections`). Not
  açıkken ray ÇEKMECE (sol kenar tutamağı / kenardan çekme, Esc + geri
  kapatır) ve liste TEK SÜTUN solda: yan yana sınırı not açıkken
  `kNoteSplitBreakpoint` 640 (yoksa 840), not kipinin liste genişliği ayrı
  (`note_pane_width`). `/` rotası kararı `SplitScope`tan okur (genişlikten
  değil — liste iki kez kurulmasın). Dikey menteşe (`verticalHingeOf`) varsa
  ayraç menteşeye oturur; AppFrame menteşe koordinatını içerik alanına kaydırır.
  **Tek liste örneği (2026-11-02, kullanıcı isteği "sağda not seç alanı
  kalmasın"):** ≥ 640 dp'de liste HEP kabuğun sol panelinde; not yokken tam
  genişlik (LayoutBuilder — `MediaQuery` genişliği rayı içerir, taşar),
  `/` rotası boş döner; `NoNoteSelected` + `listPaneWidthProvider` silindi.
  Aynı State kaldığı için arama/süzgeç/kaydırma korunur; sütun sayısı
  değişince konum oranla taşınır + açılan/kapatılan notun kartı vurgusuz
  görünür alana gelir (`DashboardPaneScope.anchorNoteId`, `_revealCard`).
  **Liste gizliyken (tam ekran / odak modu) ☰**: editör AppBar `leading`,
  kalem+tam ekranda kalem tepsisinde; Esc ve geri önce tam ekrandan çıkarır,
  Ctrl+Shift+F tam ekran. Başka nota geçince tam ekran SÜRER (dispose'da
  `openEditorNoteIds` boşsa kapanır). Tarayıcı geri tuşu PopScope'a uğramaz
  (go_router popstate) — orada tam ekran önce kapanmaz.
  **Çekerek tam ekran** (2026-11-02): not açıkken ayraç en dar hâlden SOLA
  56 dp itilince ipucu "Bırak: tam ekran" (lastik daralma + titreşim),
  bırakınca `noteFullscreenProvider`; tam ekrandan sol kenardan sağa çekip çık.
  **Ekler (2026-11-02):** metin/liste notunun sayfası `kReadingWidth` 760'ta
  ortada (`_buildCanvas`; görsel x'i ve mürekkep sayfa genişliğine ORANLI →
  hepsi birlikte ölçeklenir, kaydırma tam genişlikte). Açık not listede
  çerçeveli: editör `openNoteIdsProvider` yığınına yazar, hücre `select` ile
  izler (kart önbelleği bozulmaz). Alt+↑/↓ `visibleNoteOrder` (ekranda çizilen
  sıra) ile komşu notu `pushReplacement` eder, kilitliyi atlar; Ctrl+W
  `popRoute` (PopScope'a uyar), derin bağlantıda `go('/')`. TUZAK: tarayıcı
  Ctrl+W/Ctrl+N'yi sayfaya vermez (sekmeyi kapatır) — yalnız Android/kurulu
  PWA'da çalışır. Ayraca çift tık = o kipin varsayılan genişliği.
- Misafir kartı "Sonra" → şerit; 5/20 notta bir kez tam kart.
- `CustomizeModeHost` alanın kendi boyunu `MediaQuery.size` verir (alt çubuk
  ekran dışına itiliyordu).
- Editör başlığı sığmazsa küçülür (`fitTitleFontSize`, en az 14).
- Bekleme penceresi oturum düşüren işte `DialogRoute` + `removeRoute`
  (körlemesine `pop()` alttaki sayfayı atar).
- Kart ⋮ "Görsel önizlemesini gizle" `cardMediaHidden`; hassas içerik
  gizleme `card_hide_sensitive`.
- Çöp analizi `trash_analysis.dart` + AI; çöp hatırlatması bildirim 999002.
- `KALANLAR.md` tek cihaz doğrulama listesi; eski turlar `KALANLAR_ARSIV.md`.

## Açık sorular / bilinen
- Misafir notunda üst çubuk "Senkronize", ana ekran "yalnız bu cihazda"
  diyor — karara bağlanmadı (2026-11-01).
- **Kare ölçümü tabanı** (F18.7, koşu 41422268562, emülatör): ana ekran fırlatma build p90 4,12 / raster p90 6,33 ms; editör yazma build p90 0,26 / raster p90 6,28 ms; kaçan kare 0. Karşılaştırma koşudan koşuya (mutlak değer cihazda farklı). Ölçüm işi `NOTLAR_ALL_ABIS=1` + `--no-dds` ister.
- Cihaz doğrulama listesi `KALANLAR.md` §2 (F18.31 duman testi).
