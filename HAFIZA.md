# Not Uygulaması — Hafıza (geçerli kararlar ve tuzaklar)

İş başında oku; iş sonunda kalıcı karar / kök neden / tuzak varsa ilgili
bölüme EKLE (tarihli, kısa). Sır/anahtar/kişisel veri YAZILMAZ. Hedef
≤ 30 KB. Tarihçe ve uzun gerekçe: `HAFIZA_ARSIV.md` (→ 2026-10-19) ve
`HAFIZA_ARSIV_2.md` (→ 2026-11-02, F18.24'te sıkıştırılmadan önceki TAM
hâl) — ikisi de dondurulmuş, `grep` ile ara. Kural değişince buradaki
maddeyi GÜNCELLE.

## Ortam ve araçlar
- Flutter **3.47.9** (CI ile aynı). Bulutta SDK yok: linux arşivini
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
- **Sürüm adı (2026-11-05, kullanıcı kararı):** eskiden `1.1.<koşu no>`; artık `ANA.ARA.N` —
  ANA.ARA pubspec `version:` (1.2'ye çıkarıldı), N = o tabandan bu yana main'de `[apk]` başlıklı
  commit sayısı (`tool/surum_hesapla.sh`, marker → android + web). `[minor]` → ARA +1. `v<ad>`
  etiketi varsa N artar (çakışma yok). versionCode / `latestBuild` yine koşu no.
- **Test seçimi (2026-11-05, kullanıcı kararı):** dalda yalnız etkilenen testler
  (`tool/etkilenen_testler.py`: import grafiği + test kaynağındaki yol dizeleri;
  taban = main'le ortak ata, son push DEĞİL — iptal edilen koşunun değişikliği
  kaçmasın). main'de ağaç yeşil dal başıyla aynıysa `atla` (adımlar koşmaz, iş
  yeşil biter — `needs.test` bekleyenler bozulmasın). `[tam]` başlığı tam takım.
  `hooks/pre-push` (yerel tam takım) kaldırıldı. Aynı betikler dosya-okuyucu'da.
- APK yalnız main'de, commit **BAŞLIĞINDA** `[apk]`; dalda derlenmez.
  TUZAK (2026-11-03): main'e ARDINDAN etiketsiz commit itmek koşan `[apk]`
  koşusunu İPTAL eder (concurrency) → Release çıkmaz. Hafıza/ek düzeltme
  aynı commit'e girsin ya da sonraki commit de `[apk]` taşısın. APK
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
- **Takvim + görevler** (TAKVIM_PLANI, 2026-11-06, K1–K10 hepsi önerilen):
  `lib/features/calendar/`. Koleksiyonlar `events`, `tasks`, `taskLists`,
  `dayLinks/{YYYY-MM-DD}` (genel `users/{uid}/**` kuralı yeter; silme listesinde).
  `Note`'a alan EKLENMEDİ: bağ kayıt tarafında (`noteIds`, `noteId`, `dayLinks`).
  Tüm gün = gün dizesi, bitiş HARİÇ; tekrar `Recurrence` = `reminderRepeat`
  dizesi + `;every=;until=;count=` (notlara YAZILMAZ). Tekrarlı görevi
  tamamlamak ilerletir + geçmiş kopyası (`completeTask`). Veri küçük: dört
  koleksiyon tek dinleyici, aralık bellekte (`buildAgenda`). Takvim bildirimi
  `ReminderService`te, yük `cal:` (yalnız cihazda). Rayda Hatırlatıcılar'ın
  yerine Takvim (`/reminders` takvim bölümü sayılır).
  Görünümler yıl/ay/hafta/ajanda; iki parmak `PinchZoomDetector` = `Listener`
  (yarışmaya girmez, kaydırma bozulmaz; iki parmak inince `PageView`
  kilitlenir). Hedef `ZoomTargets` (GlobalKey → tarih). TUZAK: aynı görünümü
  yeniden açmak (aynı tür iki sayfa geçişte birlikte) GlobalKey çakıştırır —
  aynı görünüme geçiş engelli; eski görünümün `itemBuilder`ı `_view`i değil
  yerel kopyayı okur.
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
- **Uzun liste (F24.3, 2026-11-04):** madde düz `RichText` (`items_editor_lazy.dart`), dokununca/`requestFocus`la gerçek alan. Odak için `_LazyFocusNode` (yeni odak yolu da `requestFocus` kullansın). Düz çizim gerçek alanla birebir: `windowedFieldStyle` + 3 dp imleç payı. Düz çizimin bilmediği görünüm/dokunuş ekleyen satır `_needsRealField`e. Testler `debugEagerItemFields` ile gerçek alan kurar. Kademeli: ilk 16, 500 ms sonra kare başına 2 (100 düz satır bile tek karede 163 ms). Ölçüm tuzağı: SF'deki açılış "680 ms" donma değil bekleme boşluğuydu.
- **Akıcılık ölçümü (2026-11-03, `AKICILIK_PLANI.md`, araçlar `tool/perf/`):**
  Flutter 3.47 Android'de Dart UI = ana iş parçacığı (birleşik, KAPATILAMAZ:
  `DisableMergedPlatformUIThread` motorda yasak) → her platform kanalı
  çağrısının Java tarafı kareyi bekletir. Adreno ≤ 650 → Impeller OpenGLES
  (motor kara listesi). Release'te Skia A/B `am start … --ez enable-impeller
  false` ile; kaydırmada fark yok (sorun Dart). Release'te Dart zaman çizelgesi
  yok; profilde CPU örnekleyici `setFlag profiler true` ister. Test telefonunda
  yan yana "Notlar Ölçüm" (`dev.kaimau.notlar.olcum`, 244 not) kurulu.
  Varsayılan kimlikle `flutter run/drive` o telefonda ASLA (kaldır-kur → veri gider).
- **Kart önizlemesi DİLİM (F21, 2026-11-03):** kart notun yalnız baştaki
  dilimini işler (`card_preview.dart`: `previewSlice` 5 satır / 300 kod
  birimi, grafem sınırında; madde 120). `maxLines` şekillendirmeyi KISMAZ —
  kartta TAM metni maske/biçim/`Text`ten geçiren kod yazma. Örtme dilimden
  64 karakter taşar (kesimde bölünen numara açık kalmasın). `CardPreview.of`
  not ÖRNEĞİ başına (Expando): dilim + TAM metinde parola taraması bir kez.
  Aramada eşleşme görünen başta değilse kesit (`searchExcerpt`; gövde+konum
  süzgecin önbelleğinden, `bodySearchMatch`). Kart TEK abonelik:
  `_cardEnvProvider` + `select` (kayıt `==`) — yeni kart ayarı oraya, karta
  ayrı `ref.watch` koyma; ana ekran halesi de oradan (`NoteCard.frame`,
  hücrede `Consumer` yok). Dilimi 600→300 indirmek LAYOUT'u değiştirmedi:
  kalan kaydırma takılması 33 ms'lik tek vsync, ana + raster BİRLİKTE (K7).
- **Ölçülen kök nedenler (2026-11-03):** kart önizlemesi (F21'de çözüldü,
  yukarıda); tek `TextField` tuş başına
  O(n) (35 KB'ta 90–110 ms); FlutterFire her olayda TÜM koleksiyonu ana iş
  parçacığında kodluyor + `serverTimestamp` kayıt başına 2 olay (27–56 ms
  blok); HeroController her geçişte tüm ağacı geziyor (elle Hero yok, yalnız
  FAB `heroTag`ları). Zamanlama/parça
  hileleri (ilk N madde, kare başına K) belirti yaması — önce kök neden.
- **AKICILIK bulut turu (2026-11-04, cihazda ölçülmedi):** editör kaydı
  2 sn / en geç 10 sn (`kEditorSaveDelay/MaxWait`), otomatik kayıt
  `updateNote(clientTime: true)` (istemci saati → kayıt başına 2. olay yok),
  kapanış/`paused`ta bir kez sunucu damgası; not kapanırken zamanlayıcı
  `Debouncer.pause` (rota kalkınca yazar). Hero: `HeroControllerScope.none`
  go_router'da İŞLEMEZ (her gezginin kendi HeroController'ı) → sayfalar
  `withoutHeroWalk` (`HeroMode(false)`); `lib`te elle `Hero(` yasak (test).
  Arama vurgusu `SearchHighlight` boya katmanı (span değil): kart önbelleği
  anahtarı "arama var mı", canlı sorgu `_liveQuery` — vurgu metne span olarak
  geri KONMAZ (sorgu başına kart kurulumu/şekillendirme, 139 ms).
- **AKICILIK 2. tur (2026-11-04, cihazda ölçülmedi):** editörün not akışı +
  senkron göstergesi TEK yerel dinleyici (`_DocHub`, Firestore örneği başına;
  not akışı metadata-only olayı `deepDataEquals` ile eler) — yeni tek-belge
  dinleyicisi açma, `_sharedDoc`u kullan. Not geçişinde `Opacity` YOK
  (görüntü boya alfası, `_FadeSnapshotPainter`). Açık not sıralamada
  TUTULUR (`sortHeldNoteIdsProvider`), kapanış başında bırakılır. Açılışta
  servisler kare başına bir (`AppServices` kademeleri; kilit/derin bağlantı/
  paylaş ilk karede) — yeni servis kademeye eklenir. Segment geçişinde
  ayrılan ızgara `SnapshotWhenLeaving`. Kanal sayacı: debug/profil
  `ext.notlar.channels` (`VM.channels()`). F24.2 saf pencere modeli
  `text_window.dart` (bağlı değil). Bulutta YAPILMAYANLAR + gerekçe:
  F23.5, F24.3, F25.2, F22.4 → KALAN_ISLER F19.F1–F3.
- **Pencereli yazma (F24.2, 2026-11-04, telefonda LAYOUT p90 122→12 ms):** `editor/windowed_body.dart`. MODEL HEP `_bodyController`; alan `_bodyField` (yazarken `BodyWindow.win`). Yalnız odaklıyken, ilk tuştan sonra, ≥ 6000 krk; ek etiketi (📎), yüzen görsel, not içi arama, bekleyen biçim, sayfalı/mürekkepli not → tek alan (`_windowAllowed`). `displayText` veren yerde `_bodyField.text` kullan. TUZAK: alan State'i `_bodyFieldKey` ile taşınır (yoksa klavye kapanır); parça `RenderEditable` genişliği için sağdan 3 dp pay + birleşmiş giriş stili ister (yoksa satır zıplar, test sabitler); alt parça kimliği SONDAN uzaklık (baştan olsa yazınca bütün alt parçalar yeniden yerleşir, yeri de bayatlar); klavyeden gelen eski pencere durumu `_isStale` ile yazılmaz (paragraf çoğalırdı). Gerçek klavye önerisi/dikte denenmedi (KALANLAR #47).
- **Anında içerik (F25.2, 2026-11-04):** `home_snapshot.dart`, arka plana geçişte ilk 30 kartın KISALTILMIŞ kopyası tercihte; yalnız dashboard `loading` dalında, `SliverIgnorePointer` ile çizilir. TUZAK: depo akışına ya da editöre SOKMA (kısaltılmış not tam notun üstüne yazılır; eksik liste hatırlatıcıları "silinmiş" sanır). Kilitli/parola notu içeriği yazılmaz; sabitliler önce girer (yoksa liste gelince zıplar). Tercih anahtarı `home_snapshot`, hesap çıkışında silinmez (uid eşleşmezse okunmaz).
- **Metin eşiği (F24.1, ölçüldü):** tek alanda LAYOUT ~5 ms/KB → pencere eşiği 2500, pencere 1500; 4–6 KB tahmini yanlıştı. Firestore olayı not sayısıyla doğrusal: 200 not 593 KB / 11 ms Dart, 414 not ~1,2 MB / 21–27 ms (F22.4'ün gerekçesi). Açılışta ana iş parçacığına düşen saf hesap arıyorsan `prof_cold.py` (boş çöpte parmak izi böyle bulundu).
- **Ölçüm tuzakları (2026-11-04):** kapanış "99 ms donma" yanılgıydı (AKICILIK Ek B notu). Uzun ölçüm + şarj telefonu 52 °C'ye çıkardı, MIUI "Aşırı ısınıyor" verdi: sayılar geçersiz; `dumpsys battery | grep temperature` ile bak (derleme arasında `KEYCODE_SLEEP`). Telefon yan dönebilir: release uygulaması döner (senaryo koordinatları bozulur, `dumpsys input | grep SurfaceOrientation`), profil derlemesi dikey kilitli. Veri setini ikinci kez içe aktarmak kopya sayılır; `OLCUM_SEED` ile başka set. Ölçüm uygulamasında (`.olcum`) artık 414 not var, stres notları dipte: arama ile bul. Soğuk açılış profili: `am start … --ez start-paused true`, sonra profiler + `resume`.
- **Klavye turu ölçümü (F38.7, 2026-11-05):** `tool/perf/klavye.py`: birikim yok, kare başına ana ≤ 15 ms, raster ≤ 10 ms; yalnız `Scaffold` kabuğu kurulur. Kapanış sonu 33 ms ×4–5 uygulama işi değil (tahmin: sistem). SF aralığında ~500 ms imleç yanıp sönmesi, ilk aralık boşta bekleme: takılma sayma. `note_screen_chrome_test` 20 turu sabitler. TUZAK: Bash aracında tırnak içeren heredoc ve `rtk grep` + glob takılabiliyor: uzun betiği Write ile dosyaya yaz.
- **Klavye/kapanış kasması (2026-11-03)**: madde büyümesi klavye oynarken
  320 ms bekler (`_keyboardMoving`); örtülü pano `FreezeWhenHidden` ile
  donar (MediaQuery geçirmez); yetişme `noteRouteClosing` bitince +120 ms.
  Cihazsız tanı: `tester.view.viewInsets` kare kare + `debugOnRebuildDirtyWidget`.
  TUZAK: debug'da `MediaQuery` bildirimi pahalı, release'te değil.
- Ana ekran ızgarası deterministik sütun ataması (`balancedColumnAssignment`).
  Kesme noktası geçişinde `DashboardScreen` başka yerde yeniden kurulur →
  kaydırma `DashboardScrollMemory`de ORANLA taşınır (F18.11).

- Levha kapandıktan sonra sağlayıcı okunacaksa levhanın `ref`i DEĞİL, açan
  ekranın `ProviderScope.containerOf`u (2026-11-03: hesap levhasında "Oturumu
  kapat/Hesap değiştir" bu yüzden sessizce çalışmıyordu).

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

## PDF, balon, görüntüleyici
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
- **Tema (TEMA_PLANI, 2026-11-04):** beş aile `ThemeFamily` (Adaçayı
  varsayılan, Porselen, Kil; 2026-11-05 gece + Lavanta, Zeytin) × açık/koyu
  (Sistem ve Koyu yine Adaçayı koyusu; seçici dar ekranda 4+3), renkler `app_palette.dart`,
  şemada olmayanlar `AppTokens` (kart, kart çizgisi, gölge, köşe 16).
  "Masa ve kâğıt": açık temada kart zeminden AÇIK — `surfaceContainerLow`
  zeminden açık (levha), High/Highest koyu; renksiz not kartı
  `AppTokens.card` (eski `surfaceContainerLow` değil). Eski kırık beyaz /
  kağıt / beyaz `AppThemeChoice.fromStored`'da okunurken eşlenir, kayıt
  değişmez. Kart gölgesi bulanıksız 1 dp (GLES; bulanık gölge ölçülmeden
  açılmaz). `theme_contrast_test` her rol + not paleti kontrastını korur.
- **Hareket (TEMA Faz 34, 2026-11-05):** `AppMotion` + `kGridInset/kGridGap` `app_tokens.dart`. Tema geçişi ÖLÇÜLDÜ, kare başına 50–66 ms → `themeAnimationDuration: Duration.zero`, geri açma. Renk solması `ColorFade` (denetleyici ilk değişimde; `identity` temayı da içerir, yoksa tema değişiminde her kart animasyona girer). TUZAK: editörde üst çubuk ve Scaffold HEP saydam, sayfa rengi arkadaki `ColoredBox`ta; yeni saydam `AppBar` `systemOverlayStyle` vermezse durum simgesi beyaz kalır. ΔE ≥ 0,08 K5 paletinde tutmuyor, test bugünkü ayrımı korur (kullanıcı kararı bekliyor).
- **Beyaz açılış (2026-11-05, ÇÖZÜLMEDİ):** `NormalTheme` + v31 `windowSplashScreenBackground` `launch_bg` ama MIUI 13'te ~0,6 sn beyaz sürüyor. Tahmin MIUI sistem penceresi; ilk Flutter karesi elenmedi. Ölçüm: `screenrecord` + ffmpeg; aynı saniyede `screencap` yanıltıyor (ana ekran da aynı renk).
- **Worktree tuzağı:** yeni worktree'de `.dart_tool` yok; `dart analyze` yanıltıcı "URI yok" verir. Önce `flutter pub get`.
- **Okunurluk (2026-11-04 kök neden):** özel renk kâğıda sabit oranda
  karışıp yazı hep tema mürekkebinde kalıyordu → `NoteColors.customSurface`
  + `inkThemeFor` (zıt parlaklıktaki AYNI tema, önbellekten). Editör
  `_editorInk` / kart `_cardInk` Expando + `_themeOf` — bu dosyalarda
  ekranın kendi bağlamından `Theme.of(context)` YAZMA (dış temayı okur,
  yazı stili okunmaz kalır). Editör ağacı hep `Theme` ile sarılı (renk eşiği
  aşılınca alt ağaç yeniden kurulmasın). Renkli yazı `RichTextTheme.background`
  → `markStyle` → `readableOn` (≥ 4,5, ton korunur). Renkli kartın koyu tonu
  `NoteColors.noteInk` (hap, kutucuk, ilerleme, defter çizgisi `PaperInks`).
- **Not vurgusu — kart = açık not (TUTARLILIK F36.1, 2026-11-04):** içerik
  öğeleri (kutucuk, "Yeni madde", etiket/klasör/hatırlatıcı hapı, raptiye,
  madde ayırıcı) `NoteAccent`'ten: renkli notta `noteInk`, renksizde null →
  temanın vurgusu; kutucuk `NoteCheckColors` (işaretli soluk dolgu).
  Editör ağacı `NoteAccent` ile sarılı, değer DIŞ temadan (zıt temada zemin
  yanlış çıkar); ItemsEditor `_accent` satır önbelleği anahtarında. Krom
  (çubuk, levha, menü) temanın. Test `note_accent_consistency_test`.
- **Not her yerde aynı (TUTARLILIK Faz 37, 2026-11-05):** başlık tek stil `noteTitleStyle` (`editor/title_fit.dart`), yeni yüzey de bunu kullansın. TUZAK: `AppTheme.opposite` (zıt okunurluk) `Theme.of`tan geçmemiş HAM temadır, M3 ölçüleri (`letterSpacing`, `height`, kimi `fontSize`) onda null; ondan ölçü okuyan yer sabit yedek versin. Liste satırı artık notun rengini taşır. PDF/görsel `PdfNoteStyle.forNote` (temanın AÇIK hâlinden; renksiz not boyanmaz). Kural `note_everywhere_same_test`. TUZAK: `Flexible` + `Spacer` boşluğu oranla böler, kullanılmayan pay boş kalır (tarih ortada durur, saat yer varken kesilir): sol grup `Expanded`.
- **Başlık sığdırma ölçümü (F36.2 kök neden):** `TextField` M3'te stilini
  `bodyLarge`ın ÜSTÜNE birleştirir (harf aralığı 0,5 miras) → ölçüm
  `fieldMergedStyle(bodyLarge, stil)` ile; yoksa uzun başlık çipin altına taşar.
- **AI hata metni (F36.5, F42.3):** tek kapı `aiErrorText(l10n, e)`; `e.message` ya da `aiError(friendlyError())` YAZMA. Veri katmanı metin yazmaz: `GeminiException.of(kind)`, metin ARB'de (`localized`). `GeminiException('…')` yalnız zaten yerelleşmiş metinle (test tarar). Daire jesti AI yoksa bir kez `gestureFixNeedsAi`, sonra oturum boyu sessiz; karalama silmesi bildirimde Geri al.
- **AI durumu (F42.2, 2026-11-05):** tek kaynak `aiAvailabilityProvider`; yeni AI düğmesi `ensureAiReady(context, ref)` ile başlar, simgesi `AiIcon`. Arka plan işi çağırmaz, sessiz geçer. AI'sız yola düşen kapı (AI sesli not, anlamsal arama) kilitlenmez. Kota kilidi yalnız yenilenme saati biliniyorsa (son söz sunucu sayacında). Web'de "dahili kapalı" istekten öğrenilir (`aiBuiltInOffProvider`, 24 saat); site anahtarı yokluğu kapalı demek DEĞİL.
- **Ses simgeleri (F42.1, K7):** `AppIcons.dictation/aiVoiceNote/voiceRecord/listen/voiceCommand`, `IconData` alan satır `AppIcons.glyph` ile çizer (AI sesli not bileşik). Jest: parmak yalnız işaretler, `inkGestureAllowed` (K10). TUZAK: Bash heredoc'una yazılan Python betiğinde ters bölüler yarıya iniyor (`\\b` → backspace): betiği Write ile yaz.
- **Ek tek model (F40, 2026-11-05):** menü sırası yalnız `attachmentActionsFor`; yeni ek işi oraya + `AttachmentAction`. Görünüm geçişi menü maddesi değil anahtar (K6; "Sayfaya göm/Ek olarak taşı/Nota aktar" YOK), her geçiş `_setAttachmentView` → "A → B · Geri al". Durum tek dil `attachmentStatusOf` + rozet; ek kutusuna tıklanabilir yer tutucu koyma (yüzende dokunuş seçer, kartta notu açar; `interactive: false` + köşe rozeti). Araç satırı zemini `PdfReadStyle.barColor`. Video dönüşü oturumluk (`NoteVideoHub.rotate`). Web dosya bırakma `listenFileDrops` → `useFiles`.
- **Paylaşılan klasör = süzgeç (K8, F43.2, 2026-11-05):** `openFolder` (`folder_nav.dart`) tek kapı; `selectedSharedFolderProvider` açıkken `selectedFolderProvider` null. Izgara `sharedFolderSlivers`, kart `ownerId` taşır (seçim yok). TUZAK: ana ekranda not oluşturan yol kendi koleksiyona yazar, bu yüzden açıkken mikrofon ve "+" yerine `SharedFolderFab`; yeni kapı eklersen bak. Yana çekiş durağı `sharedFolderStopId` (`sahip/klasör`). `NoteListRow` sahibi taşımaz: paylaşılan yüzeyde liste görünümü kullanma. Ek paylaşımı tek `shareAttachmentFiles`; misafir kilidi `AccountLockBadge` (`MenuAction.badge`, ray `locked`).
- **Bölüm başlığı (F36.7):** tek `SectionLabel`, cümle düzeni (büyük harf
  yalnız rozet: BALONLU PDF, SUNUM, VİDEO, YENİ); Başlık Düzeni ad yok
  ("Çöp kutusu"). Sayı 0 → rozet çizilmez; boş klasör solması renkte
  (`Opacity` yok).
- **Ekran turu (F36.3):** `tool/tour/screen_tour_test.dart` (CI dışı) →
  `build/tour/*.png`, 4 boyut. TUZAK: testte `debugDisableShadows` → FAB/panel
  çevresinde koyu halka çizilir, GERÇEK DEĞİL.
- **Ana ekran jestleri (F39, 2026-11-05):** zoom ve yana çekiş jest boyunca YALNIZ `Transform` (`PinchColumns`, `FolderSwipe`), yerleşim bırakınca bir kez; jestte ikinci ızgara kurma. TUZAK: `Row`da `Flexible` + `Expanded` boş alanı yarı yarıya böler; `build` içinde `context.size` assert atar. Çoklu dokunuş ölçümü: `adb input` iki parmak bilmez, `InputManager.injectInputEvent` + `app_process` küçük dex (`tool/perf/Pinch.java`).
- Ana ekran tek mikrofon = doğrudan yazdır; AI sesli not Yapay zekâ
  ekranının en üstünde. "+" tek panel. Dosya akışı tek levha
  `showFileUseSheet`; HEIC → PNG.
- "Tümü" çipi kalıcı; kendi klasörüm = süzgeçli ana ekran; "Gelen" çipi ana
  ekranı süzer (`sharedHubOnHomeProvider`), "Gelen" klasörü cihaz tercihi.
  Çip sayısı listeyle AYNI süzgeç (`sharedNotesVisibleCountProvider`: çöpteki/
  silinmiş/kendi aynası sayılmaz — 2026-11-05 "boşken 1 görünüyor").
  Paylaşılanlar ayrı bölüm (`home_show_shared`, yer
  `homeSharedAtBottomProvider`).
- Süz düğmesi arama kutusunun içinde; varsayılan sıralama "Son güncellenen"
  (`migrateDefaultNoteSort`).
- Kartta görünenler `card_show_*`; kart TEK semantik düğüm, ⋮ ayrı.
- Menüler `ActionMenu`; not ⋮ ve kart ⋮ TEK katalog `noteMenuModel` (F38.1): yeni iş oraya + iki handler (`note_menu_model_test` ölü düğmeyi yakalar). Çok işlemli = levha, tek seçimli ya da ≤ 4 madde = açılır menü (F38.6). Hızlı satır en çok 5: 6'da dar ekranda ad kesilir. Alt çubuk
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
- **Tek Ekle kataloğu (F41, 2026-11-05):** "+" paneli ve Ekle levhası `addCatalog` + `AddTile`; yeni seçenek oraya yazılır (kimlikler `UiItem.quickAdd`/`attach`, değiştirme). Web dosya bırakma/yapıştırma `addFileDropHandler`: en son açılan yüzey alır (not > ana ekran). Paylaşımdan gelen ek `?place=<id>` ile ipucuyla açılır.
- Misafir: hesap isteyen giriş gizlenmez (`AccountLockBadge`); dahili AI
  misafire kapalı (`aiAvailabilityProvider`).
- "Yeni sürüm var" (F18.21, yalnız Android): `config/app.latestBuild` >
  kurulu derleme (yerel 1 sayılmaz) → sürüm başına bir kez bildirim
  (`update_notice_shown_for`) + Ayarlar → Hakkında satırı.

- **Cihaz turu kök nedenleri (2026-11-05):** `resizeToAvoidBottomInset: false` ekranda bildirim klavyenin arkasında kalır: yeni bildirim `timedSnackBar`/`showMessage` ile ya da `snackBarMarginOverKeyboard`. Tembel listede `maxScrollExtent` ilk karelerde tahmin: oranı tahmin oturana dek yeniden uygula (`_restoreScroll`). Biçimli metni `substring` ile bölme: `splitRichText` (klavye "İleri" `_enterAt`, donanım Enter `_splitMultiline`: ikisi ayrı yol). Düz madde satırında (F24.3) odak düğümünün `context`i boş: satırı bulan kod `rowContext` kullansın; testler `debugEagerItemFields` ile bunu GİZLER, yeni satır davranışını `items_editor_lazy_test`e de yaz. Aramada geri aramayı kapatır (`PopScope`). Sabit video: döndür < 430 dp ⋮ menüsünde, üstünde çubukta (telefonda çubukta ⋮ taşıyordu).
- **Cihaz turu tuzakları:** Bash heredoc'ta ters bölü bozulur, yama betiğini Write ile yaz. `adb` Enter donanım yoludur, Gboard "İleri" değil. Koordinat basarken klavyeye bak. Ekran 30 sn'de kapanır, `dump` boş döner. Telefon `taban.py` + şarjla 49 °C'ye çıkar (sayı geçersiz), önce < 37 °C bekle. "Yalnız kalem" o telefonda açık kalmıştı: adb çizgi bırakmıyordu, hata değil. MIUI otomatik başlatma izni `appops` ile verilemiyor. Dosya seçici Dosya Okuyucu'yu açar, "Diğer" sistem seçicisi. Kişisel dosyalar açmaktan kaçın (video denemesi gerçek bir videoyu açtı, görüntüler silindi; test videosu it).

- **Klasör silme kök nedeni (2026-11-06):** `folderShares` aynası silmesi klasörle AYNI batch'teydi; aynası olmayan (hiç paylaşılmamış) klasörde kural `resource.data` null'da reddediyor, batch bütünüyle geri alınıyordu (klasör yerelde kaybolup geri geliyordu). Ayna artık ayrı, en iyi çabayla silinir; kural `resource == null` silmeye izin verir. TUZAK: batch'e "var olmayabilir" belgeye silme koyma.
- **Klasör halkası (2026-11-06):** yarıçap küçültüp çipi aynı boyda bırakmak çakıştırıyordu. `radialRadiiFor` gerçek çip boyutlarıyla (TextPainter) çakışmasız oval arar; sığmazsa ızgara levha (`folder-grid-menu`). Test 13 durakta çakışma olmadığını ölçer.
- **Ayarlar kabuğu baştan (2026-11-06):** akordeon kalktı. Kök = profil + kısayollar + gruplu kategoriler (`_settingsGroups`: Hesap · Uygulama · Veri ve gizlilik; gruplanmamış yeni alan "Diğer"e düşer). Dar ekranda alan AYNI ekranda açılır (`_open`, `PopScope` geri → kök; rota değil, satırlar ebeveyn build'iyle tazelensin), ≥ 900 dp iki bölme. `?area=` doğrudan alan sayfası. Satır bileşenleri değişmedi.
- **Gmail / Kişiler baştan (2026-11-06):** Gmail süzgeç çipleri `gmailQuery` (süzgeçte `in:inbox`), tarih kümeleri `gmailDayOf`, okunmamış/yıldız `labelIds`'ten yalnız gösterim. Kişiler saf yardımcıları `friend_list.dart` (Türkçe sıra/İ-ı). Ekleme tek alan; tam e-posta yazınca doğrudan istek satırı.
- **Klasör şeridi + tema + hatırlatıcı (2026-11-06 gece):** klasör İÇİNDEYKEN (kendi/Gelen/paylaşılan) şerit gizli tercihe rağmen çizilir, başında SABİT ana sayfa düğmesi (`home-strip-go-home`); "Tümü" çipi DOKUN → `/folders`, UZUN BAS → bütün notlar (eski dokunuş). Sağdaki "Tüm klasörler" simgesi kalktı. Klasör menüsü (düğme + yukarıdan çekiş) Gelen'i şeritteki yerinde gösterir (`kSharedHubFolderId` → `showSharedHubOnHome`). Klasörler ekranı kartı 128 dp (simge adın yanında, 2 önizleme). Başlıksız `ActionMenu`'de ⚙ ilk bölüm başlığının sağında (ayrı satır yok). Tema: `theme_picker.dart` tek seçenek listesi (`themeChoiceOptions`), ana ⋮ → Tema = perdesiz alçak levha, canlı uygular, Vazgeç geri alır. 5 canlı aile Okyanus/Gül/Mandalina/Zümrüt/Ametist (renkler betikle üretildi, kontrast testli). Hatırlatıcı TEK levha `showReminderSheet` (zaman + tarih/saat + tekrar + Kaldır/Kaydet, `applyReminderChoice` kaldırmada Geri al); `pickReminderWhen` artık kullanılmıyor. `showAppSheet` HER levhaya alt `SafeArea` sarar (gezinme çubuğu altına girme kök nedeni: kenardan kenara + levhada alt dolgu yok).
- TUZAK: `dart format` `HomeInBar(appBar:`'ı alt satıra bölüyor; `rail_scope_menu_test` artık regex ile bakar.

## Web
- `--wasm` (skwasm, JS yedeği); COOP/COEP yok. Wasm'da `int` 64, JS'de 53 bit.
- Geri tuşu `HomeFirstRouteInformationProvider`. Açılış `notlar-ready`
  olayında (`signalWebReady`). Açılış katmanı GERÇEK simgeyi
  (`icons/Icon-192.png`) gösterir — simge değişince `index.html`i de
  güncelle. `web/_headers`: simge + `google_fonts` 1 hafta önbellek
  (`/assets/fonts/` HAYIR: MaterialIcons her derlemede değişir).
- Drive ekleri `WebDriveAuth`/`WebDriveGate` (`blob:` buluta yazılmaz). Jeton
  SEKMEDE (`sessionStorage`, uid'e bağlı, ~55 dk — yenilemede yeniden izin
  sormaz); notta `WebAttachmentsBanner`: "N ek Drive'da · Göster" (tek
  dokunuş hepsini indirir) ya da "telefondan çıkmamış" uyarısı (Android'de
  Drive bağlı değilse ekler cihazda bekler — web'in yapabileceği yok). Web
  Drive'a yazmaz; yerel not/video yok.
- Web Drive (2026-11-03): bağlanma/indirme hatası artık SNACKBAR + ErrorLog
  (`web-drive-connect`/`web-drive-fetch`; eskiden sessizdi → "gelmiyor"un
  kökü görülemedi). Yeni jetonla düşen ekler yeniden denenir. Kök neden hâlâ
  doğrulanmadı: sıradaki turda kullanıcıdan ekrandaki hata metnini iste.
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
- İşaretli blok 10'ar
  (`_checkedShown`, "İşaretlileri göster (N gizli)"), açılışa özgü.
- Dinleme alanı tek kart `ListeningCard`; başlık düğmesi
  `ListeningHeaderButton` (34 dp).
- Ayar alanları `ExpandReveal` (+ `_StaggeredRows`, `_followIntoView`);
  arama + ✨ AI kipi (`matchSettings`, yalnız ayar adları).
- Paylaşım iki kavram: Birlikte düzenle / Kopya gönder. Paylaş levhası
  Dışarı gönder / Kişilerle (F43.1); web'de "Görsel" `pngPages`.
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
- **Geniş ekran kapıları (F44, 2026-11-05):** yeni not kapıları rayda (K3), ana ekran FAB'ları `AppRailScope.visible` ise çizilmez; iş ana ekranda, ray ve kısayol `homeDoors` (`HomeDoors`) ile çağırır (dar↔geniş geçişinde yeni örnek önce kurulur, `dispose` yalnız kendisiyse siler). "Notlar" = `goHome` (K4). Dar web 🏠 `HomeInBar`: yeni çubuklu bölüm ekranı sarılır + `kHomeInBarLocations` (K5). Sütun `readingColumn`/`readingMargin`: sabit medyada ve belgede çubuklar bölmeyi doldurur. Dikey < 960 dp not açılınca liste çekilir (`listAutoHidesFor`, `listPeekLocationProvider`); editör `SplitScope.listHidden` okur, sağlayıcı değil. TUZAK: kökteki `AppShortcuts` metin alanının kısayollarından ÖNCE yakalar (`DefaultTextEditingShortcuts` daha yukarıda): Ctrl+A/Delete gibi metinde de anlamlı tuşu koşulsuz bağlama. TUZAK: `DashboardScreen` gizli listede hiç kurulmayabilir (`FreezeWhenHidden`): `ref` okuyan tembel alan `dispose`ta patlar, `initState`te kur. Web'de Ctrl+tekerlek ve kıstırma `PointerScaleEvent` gelir (`exp(-dy/200)`), yatay kaydırma tekerlek olayı (bırakma yok, sessizlikle biter).
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

- **Ek senkronu — TEK YOL (F28.2/F19.E1, 2026-11-06, kullanıcı kararı "herkese aç + eskiyi sil"):** `UploadQueue` + `DriveStore` tek kuyruk; Drive yüklemesi `drive.file` ile kökteki GÖRÜNÜR "Notlar" klasörüne (`ensureFolder`, oturumda önbellek). Kapsam ikisi birden (`kDriveScopes` = file + appdata) TEK jetonla: eski gizli klasördeki ekler kimlikle okunmaya devam eder, göç/sıfırlama YOK (kayıt silinmedi). KÖK NEDEN ("telefondaki ek web'e gelmiyor / sürekli bekliyor"): Google hesabında ekler yalnız Ayarlar'da elle "Bağla" denince yükleniyordu → artık `DriveConnectedNotifier` izin önceden verilmişse sessiz bağlanır, ana ekran şeridi bekleyen ek varken izni oturumda bir kez kendisi sorar, `no-token` hatası bağlantıyı düşürür (şerit yeniden sorar). Görsele ≤ 40 KB önizleme `users/{uid}/thumbs/{ekId}.jpg` → `Attachment.thumbUrl`: kart her yerde, web'de izinsiz hemen; `WebDriveGate` asıl dosya inene dek önizlemeyi çizer. Web yüklemesi BİLİNÇLİ olarak Storage'da kaldı (web jetonu ~55 dk + açılır pencere ister). Bayraklı ikinci motor (`attachment_sync_service`, `drive_files_api`, `domain/attachment_sync`, sıfırlama göçü, Ayarlar deneme anahtarı) SİLİNDİ; jeton önbelleği `ScopeTokenCache` (`google_scope_auth.dart`, Gmail kullanır). TUZAK: Storage kuralları OR'lanır; genel `users/{uid}/**` 50 MB kuralı thumbs yolunu dışlamazsa 40 KB tavanı boşa düşer. Tahmin (doğrulanmadı): `drive.file` erişimi Cloud PROJESİ düzeyinde — web istemcisi Android'in açtığı dosyayı okuyabilir. İKİNCİ KÖK NEDEN (cihazda, v1.2.1): izinsizken düşen deneme üstel beklemeye giriyor, `UploadQueue`'da zamanlayıcı olmadığı için bir sonraki not değişikliğine dek HİÇ denenmiyordu → `_scheduleRetry` + bağlantı gelince `_lastFailure.clear()`; Drive adımlarında zaman aşımı + `ErrorLog` (`upload`, `thumb-upload`). Cihazda doğrulama yöntemi: Firebase CLI oturumuyla Firestore REST (`firebase-tools/lib/auth.js` `getAccessToken`) → ekte `driveId`/`thumbUrl`; başka cihaz benzetimi = aynı `driveId`li, telefonda dosyası olmayan kayıt yazmak.
- **Gmail (F28.1, 2026-11-04):** `features/gmail/`, yalnız GET (`gmail_test` doğrular), kapsam `gmail.readonly` Drive'dan AYRI istenir. TUZAK: `http.Response.body` charset başlığı yoksa latin1 çözer → Gmail JSON'unu `utf8.decode(bodyBytes)` ile oku. Jeton önbelleği `DriveTokenCache` (adı Drive ama kapsamdan bağımsız).
- **Ek görünüm geçişinde Geri al (2026-11-06, kullanıcı bulgusu):** `_setAttachmentView` eki nottan id ile GÜNCEL hâline çözer. KÖK NEDEN: Geri al geçişten önceki kopyayla çağrılıyordu → `_viewOf` hâlâ "sabit" deyip `from == view` erken dönüyordu (bütün kip geçişlerinde). TUZAK: kapanışta (bildirim eylemi) yakalanan `Attachment` bayattır; kimlikle yeniden oku.
- **Tema aileleri 7 (2026-11-06):** + `white` (klasik beyaz: gri masa, beyaz kâğıt, mavi) ve `straw` (saman kâğıdı: saman masa, krem kâğıt, sepya). Kayıt adları `white`/`straw` — eski `light`/`paper` göç eşlemesi (→ Porselen/Kil) DEĞİŞMEDİ. Seçici dar ekranda 3 × 3.
- **Takvim zemini (2026-11-06):** `DashboardBackground.calendar` (`dashboard_bg_calendar`) → `CalendarBackdrop` (ayın ızgarası + günün ilk 3 kaydı, tek abonelik, IgnorePointer + RepaintBoundary) renk/desen/görselin yerini alır; `CardSeeThrough` (InheritedWidget, ızgaranın üstünde bir kez) kartta zemini %22, başlık dışı içeriği TEK `Opacity` (0,3) ile soldurur, gölgeyi kapatır. Yalnız ızgara kartı (liste satırı değil). Opacity katmanı kart başına — bu kip açıkken GLES'te kaydırma maliyeti ölçülmedi.
- **Takvimden not açma (2026-11-07):** `/calendar` SplitShell DIŞINDA — not HİÇBİR ZAMAN ham `router.push(noteRoutePath(..))` ile açılmaz (ikinci kabuk → siyah ekran; "Bu güne not" böyle bozuktu). `router.pushNote`/`context.pushNote`; sayfasız rotadan (gün sayfası `CalendarDayScreen`, `Navigator.push`) `kOutsideShellNotePrefix`. Ay hücresi çift dokunuş → gün sayfası (`WeekPage(dayCount: 1)`); veri `calendarDataProvider`.
- **Takvim tatilleri (2026-11-07):** yerleşik tablo `domain/holidays.dart` (sabit resmî + Diyanet bayram ilk günleri 2024–2032; 2028+ `estimated`). UZATMA / İDARİ İZİN / kesin tarih → `tool/tatiller.json` düzenle + main'e push: CI `deploy` `tool/set_holidays.js` ile `config/holidays`'e yazar (değişmediyse yazmaz), uygulama canlı okur (`holidayOverridesProvider`, APK gerekmez). Tatil AgendaEntry DEĞİL: `CalendarData.holidays` (`HolidayCalendar`, yıl başına önbellek); ⋮ menüsünde aç/kapa (`calendar_holidays`). Hafta başlığı dokunuşu → gün sayfası. Ay şeridi 9,5 pt, yer varsa 2 satır (`kMonthChipTwoLine`); kısa ad sığmalı ("29 Ekim Bayramı", sözcük ortadan bölünmesin).
- **Dar sütun kartı + Gelen adı (2026-11-07):** ana ekran `NoteCardWidth(width: cellWidth)` verir; `noteCardSqueezeFor` 0 (≥150 dp) / 1 (3 sütun) / 2 (<112, 4 sütun): başlık 16/14,5/13, "+N madde daha" → "+N", dar kartta etiket hapı + hatırlatıcı yazısı gizli (hap sıfıra sıkışıp boş leke oluyordu), çok darda tek durum simgesi, belge kartında ad yok. Gelen = `sharedHubOnHomeProvider` (selectedFolder DEĞİL) → `appliedFilterLabels` ayrıca okur, `resetFilters` kapatır. Tur: `TOUR_COLUMNS=3|4`.
- **Sola kaydırınca takvim (2026-11-06):** `swipeLeftCalendarProvider` (`swipe_left_calendar`, varsayılan açık) — yalnız Tümü görünümünde İLERİ yön (sola çekiş) `/calendar` açar (`swipeOpensCalendar` saf); klasör/süzgeçte durak gezer. `FolderSwipe` mod kapalıyken de bu yüzden etkin.
- **Takvim taşıma + yedek (F47.5/F46.5):** `movedToDay`/`canMoveEntry` (agenda.dart) — tekrarlı ve Google etkinliği taşınmaz. Yedek `yedek.json` `calendar` alanı (`calendar_backup.dart`, Timestamp → `{"$ts"}`), geri yüklemede not kimliği eşlemesi (atlanan not da karşılığına).
- **Google Takvim (Faz 48):** Firestore'a YAZILMAZ; önbellek SharedPreferences `gcal_cache_<uid>`; kimlik `g:<takvim>/<id>` (`fromGoogle`); bağlı notlar `eventLinks/{googleEventId}`. Testte `GoogleCalendarController.authOverride/clientOverride`. TUZAK: `googleCalendarAvailableProvider` Firebase `authStateProvider` okur — testte override yoksa denetleyici boş durum döner (sorun değil).
- **CI deploy:** Cloudflare Pages "Unknown internal error" (2026-11-06, koşu 748) kodla ilgisiz; sonraki main push yeniden yayınlar. Main'e APK işi sürerken push ETME: `cancel-in-progress` APK'yı iptal eder.
- **Push öncesi `flutter analyze` (tam, ~11 sn)**: CI analizi `info` düzeyinde de kırmızı (avoid_redundant_argument_values) — yalnız değişen dosyayı analiz etmek yetmedi (2026-11-06, iki kırmızı koşu). arb_case_test: özel adlar (Google Takvim) `titleCaseOk`'a.
- **Google yazma/eşleme (F50.4/Faz 51):** Görevler `planTaskSync` saf (içerik aynıysa yazım yok — ping-pong önlemi; "değişti" = `updatedAt` > son eşleme / Google `updated` > bağdaki `updated`). Takvim yazımı ayrı kapsam `calendar.events` (`connectWrite`), iyimser + kalıcı kuyruk (`gcal_cache_<uid>` içinde `queue`), geçici kimlik `tmp-…`.
- **Menü düzeni (2026-11-06):** `ActionMenu(menuId:)` → başlıkta ⚙ "Menüyü düzenle": sırala (sürükle), gizle (göz), hızlı satıra al (yıldız, en çok 5). Kayıt `menu_layout_v1` (`MenuLayouts`, main'de `attach`). Kimlikler: `note.card`, `note.editor`, `note.add`, `home.menu`, `home.selection`. Varsayılan hızlı satırdan çıkarılan işlem "Diğer" grubuna düşer (kaybolmaz). PopupMenuButton menüleri kapsam dışı.
- **Takvim SAĞA kaydırınca (2026-11-06, ilk sürüm sola idi):** `swipeOpensCalendar` `direction < 0`; ayar anahtarı adı eski (`swipe_left_calendar`).
- **Klasör düğmesi (2026-11-06, 5. tur):** ana ekran sol alt `FolderHoldButton` + liste TEPEDEYKEN aşağı çekiş (≥ 80 dp parmak, bırakınca; `_trackFolderPull`, gösterge `FolderPullIndicator`) — ikisi de `openFolderMenu` (tek kapı). Menü KOMPAKT: sabit 74×76 karo (renkli simge dairesi + sayı rozeti + tek satır ad), orta daire 76, oval en çok %30 uzun; sığmazsa (telefonda ~11+) aynı karolarla ızgara levha. Izgaraya `AlwaysScrollableScrollPhysics` (az notta da çekilsin). Çekiş seçim/sıralama/arama/paylaşılan klasörde kapalı (`_folderPullAllowed`). TUZAK: FAB'a `tooltip` verme.
- **Yana kaydırma akan geçiş (2026-11-06):** KÖK NEDEN "hızlı geçişte takılma": bırakınca ızgara merkeze geri sekerken yeni içerik AnimatedSwitcher'da ters yönden geliyordu (gelen liste parmağın tersine kayıyordu). `FolderSwipe.continuesInPlace(direction, oran)` true dönerse ızgara sekmez; ana ekran ayrılan görünümü bırakılan orandan aynı yöne sürdürür (`_leavingKey/_leavingFrom`, 2×medium sonra temizlenir), gelen 0,3 uzaktan girer. Takvim açan çekişte eski davranış.
- **Geri önce paneli kapatır — GENEL (2026-11-06, kullanıcı: "tek tek değil hepsi"):** `core/widgets/back_closes.dart` `BackCloses(open, onClose)`: rota içi panel açıkken kaydolur (LIFO), geri yalnız SON açılanı kapatır (aynı olayda ikincisi `_consumed` ile atlanır). Ekranın kendi `PopScope`u (editör, ana ekran, madde seçimi) işe başlamadan `BackCloses.handling(context)` sorar. Bağlı: ek şeridi (yalnız BU ekranda açıldıysa — kalıcı tercihle açık gelen yakalamaz, `_stripOpenedHere`), sayfa üstüne yazma kipi, kalem tepsisi paneli, biçim çubuğu tepsisi, sayfa notu alanı, takvim ay paneli. YENİ satır içi panel eklersen `BackCloses` ile sar (gövde yoksa `child: SizedBox.shrink()`).
- **Google 403 ayrımı (2026-11-06):** "Google Takvim bağlanamadı" kök nedeni F19.B10 — konsolda Calendar API kapalı; 403 hep `unauthorized` sayıldığı için hata yutuluyordu. `google_api_problem.dart`: `SERVICE_DISABLED` artık yetkisiz DEĞİL, `showGoogleConnectFailure` nedeni + "Etkinleştir" (konsol adresi gövdeden). Görevler bağlanınca API kapalıysa bağlantı geri alınır.
- **Levha klavyesi (2026-11-06, yeni etkinlik kasması):** `core/widgets/sheet_keyboard.dart` — `SheetInsetPadding` (viewInsets yalnız ince dolguda) + `focusAfterRouteOpens` (autofocus yerine; klavye levha animasyonu BİTİNCE). Takvim `Scaffold(resizeToAvoidBottomInset: false)`. Yeni yazı alanlı levhada bu ikisini kullan.
- **Profil levhası (2026-11-06, baştan):** `showAccountSheet` kâğıt kartlar (AppTokens card/hairline/cardRadius): kimlik kartı + durum hapı, 2 kare kısayol (Kişiler/Premium), gruplu satırlar (Ayarlar/Hesap değiştir), en altta OutlinedButton çıkış. TUZAK: levhaya FilledButton koyma — test onay kutusunu `find.byType(FilledButton)` ile bulur.
- **Arama + klasör satırı (2026-11-06, 2. tur):** arama kutusundaki AI anahtarı HEP görünür; klavye açıkken solda geri oku YOK (kutu kayıyordu) — sağda hesap+⋮ yerine `search-done` (klavyeyi kapat) — TUZAK: `TextFieldTapRegion` içinde olmalı, yoksa pointer-down'da odak düşer, düğme kaybolur, dokunuş kutuya geçip klavyeyi geri açar. Kutu düzeni: AI hapı (42×30) | ayıraç | düz simgeler (süz pasifken kutusuz). Klasör satırı ⋮ → "Klasör satırını gizle" (`homeFolderStripHiddenProvider`); gizliyken sliver hiç çizilmez (boşluk kalmaz), klasörlere sol alt düğmeyle.
- **Ana ekran üst çubuğu (2026-11-06):** arama hapı (50 dp, yuvarlak) hesap + ⋮'yi İÇİNE alır (`_SearchField.trailing`); AppBar `actions` boş. ⋮ → "Görünüm ve süz" = `showFilterSheet`. Takvimde dar ekranda görevler/hatırlatıcılar/rutinler/Google ⋮'te (başlık sıfıra sıkışıyordu); rutin simgesi `kRoutineIcon`.
- **Tema aileleri 10:** + `cream` (açık saman), `peach` (sıcak pastel — okuma/disleksi önerisi), `mint` (yeşil-mavi, düşük yorgunluk). TUZAK: `balloon_list_theme_fixes_test` vurgu doygunluğu > 0,2 ister.

## Merkezi asistan bırakıldı (2026-11-02)
- Kullanıcı: asistan (`com.ses.asistan`) çok pil yiyordu; ses her uygulamanın içinde. Kişisel alıcıdan
  `ASISTAN_SORGU` ve asistan sertifikası silindi; `HARITA_NOT` (Harita, Kanallarım) aynen. `image` eki
  şimdilik gönderen yok (yalnız asistan yolluyordu) — Kanallarım/Dosya Okuyucu notunda kullanılabilir.

## Açık sorular / bilinen
- Misafir notunda üst çubuk "Senkronize", ana ekran "yalnız bu cihazda"
  diyor — karara bağlanmadı (2026-11-01).
- **Kare ölçümü tabanı** (F18.7, koşu 41422268562, emülatör): ana ekran fırlatma build p90 4,12 / raster p90 6,33 ms; editör yazma build p90 0,26 / raster p90 6,28 ms; kaçan kare 0. Karşılaştırma koşudan koşuya (mutlak değer cihazda farklı). Ölçüm işi `NOTLAR_ALL_ABIS=1` + `--no-dds` ister.
- Cihaz doğrulama listesi `KALANLAR.md` §2 (F18.31 duman testi).
- **2026-11-06 cihaz turu tuzakları:** (1) Not ekranı İÇ İÇE gezginde: kök gezgine açılan levha varken `ModalRoute.of(context).isCurrent` yine true → "levha kapanınca göster" denetimi yanıltır; bildirimi akışın SONUNDA (kayıttan sonra) çağır (`maybeShowAutoStartHint`). (2) Paylaşım alıcısı ikili dosyayı uzantıyla eliyordu; `.notyedek` "PK..." metin notu oldu → `looksLikeZip` imza denetimi. (3) Tam yedek Android'de `saveDocument` (sistem Kaydet) ile; paylaşım levhası yalnız web. (4) adb'nin `am start SEND` ile verdiği media URI'sını uygulama okuyamaz (doğru eleniyor) — paylaşımı Dosyalar uygulamasından dene. (5) Bash aracında heredoc içindeki `\` rtk/kabukta teke iner: düzenli ifade içeren Python'u satır tabanlı yaz.

## 2026-11-07 — Klasör şeridi sabit, sabit bölmede PDF şeridi alt satırda, izinsiz tarama
- **Klasör şeridi** yana kaydırılan ızgaranın DIŞINDA (sabit başlık, `shelfAsStrip`); ızgarada yalnız kök KARO rafı. Kök neden: şerit segmentKey'li `CustomScrollView`'in sliver'ıydı → çekişte parmakla kayıyor, geçişte solup yeniden kuruluyor, yatay konumu sıfırdan seçili çipe kayıyordu. Seçili çip artık ORTALANMAZ (`_EnsureVisible` en kısa kaydırma, +24 dp pay). Ev düğmesi ana sayfada da yerinde (dolu) — eskiden giriş/çıkışta şerit 56 dp sıçrıyordu. Bekçi: `test/folder_strip_fixed_test.dart`.
- **Sabit bölmede PDF:** kutunun yüzen gri şeridi yok; `PdfBoxBar` köprüsüyle ‹ n/N › · balon göster/gizle · yer imi (≥400 dp) · belge menüsü (📖) bölme çubuğunda. Dar çubukta "Not al" yazısı düşer (<420 dp). Yüzen kutuda (sayfa içi) eski şerit duruyor.
- **Belge tarama izinsiz** (dosya-okuyucu davranışı): `cunning_document_scanner` `getPictures` önce kamera izni istiyor, reddedince fırlatıyordu; Google tarayıcısı izinsiz çalışır. `DocumentScan.scanPages` eklentinin kanalını doğrudan çağırır; PlatformException'da eski izinli yola düşer. TUZAK: Play Hizmetleri olmayan cihazda eklentinin kendi kameralı yedek etkinliği izin isteyebilir (cihazda doğrulanmadı).

## 2026-11-07 — Tablet turu (HUAWEI MatePad 11, GMS'siz, M-Pencil) — kök nedenler
- **Veri kaybı — ek yüklemesi el yazısını siliyordu:** `Note.attachments` sayfa üstü el yazısı kaydını (`_page_ink`) İÇERMEZ; `patchAttachment`/`patchAttachmentSync`/yerel `appendAttachments`/YouTube metni listeyi ondan kurup yazınca bütün el yazısı gidiyordu (görsel Drive'a yüklenir yüklenmez). Ek listesini yeniden yazan HER yol `note.attachmentsField([...])` kullanır. Bekçi: `notes_repository_data_test` "el yazısı korunur". Eski sürümlerde bu yolla kaybolan çizim geri gelmez.
- **Kare tuval `Align` içinde sıkışıyordu** (iki yerde, aynı kök): `InkPageLayer(uniform)` ve kart önizlemesi (`CardPageInk`) kare `CustomPaint`'i katmanın/kutunun boyuna sıkıştırıyordu → kalem kipi kapanınca (sayfa altı boşluğu gidince) çizim dikeyde basılıp kayıyor, kartta yassı. `OverflowBox` ile kare. Kart önizlemesi çizimin tepesinden başlar.
- **Ayarlar/uygulama gri ekran:** web'de JS `1.0`'ı Firestore'a TAMSAYI yazıyor; ayar senkronu `setInt` → `getDouble('font_scale')` çöküyordu (senkron gelir gelmez bütün uygulama). `writeLocalPref` `kDoublePrefKeys`'te double yazar, `FontScaleNotifier` num okur. Yeni ondalık senkron tercih eklenirse `kDoublePrefKeys`'e ekle.
- **GMS'siz Android (Huawei/HarmonyOS; GBox uygulamaya GMS vermez):** `gmsInstalled()` (yerel `gmsInstalled`, manifestte `<queries>` gms). Yoksa giriş doğrudan tarayıcı; Drive/Gmail/Takvim jetonu `browserScopeToken` → yerel `googleScopeToken` (Firebase `startActivityForReauthenticateWithProvider`, kapsamlı). TUZAK: FlutterFire Google'da `credential.accessToken`'ı HEP null verir (GoogleAuthCredential, OAuthCredential değil) → jeton Kotlin'de Parcel'dan `ya29.` dizesi olarak çıkarılır. Jeton ~55 dk şifreli depoda (uid'e bağlı); dolunca "bağla" yeniden ister (yenileme anahtarı yok). FCM/App Check GMS'siz çalışmaz (yakalanıyor).
- **Huawei tarayıcısı özel sekmeyi AYRI görevde açar:** Firebase dönüşü sekmeyi kapatmıyor, kullanıcı boş "about:blank"ta kalıyordu. Tarayıcı akışları `browserFlow()` / yerel `bringToFront` (`moveTaskToFront`, REORDER_TASKS; etkinlik az önce bittiği için 10 sn arka plan izni) ile uygulamayı öne alır.
- **Kalem tepsisi tutamağı** aşağıdayken gezinme çubuğunun İÇİNE iniyordu (dokunuş sisteme gidiyordu). Kapsül tasarımında (aşağıda) hap/kapsül hep `bottomInset + _kDockGap` üstünde durur.
- Bölünmüş görünümde not klavyesi listeyi daraltmaz (`MediaQuery.removeViewInsets`, sarma hep var — ağaç şekli sabit). Rayda klavye kısayolları yalnız web'de (M-Pencil kendini "klavye" diye tanıtıyor).
- Cihaz notları: MatePad 11 = 1600×2560, 400 dpi (yatay 1024×640 dp); Huawei `adb install` iki onay penceresi ister ("Devam et" → "Yükle"); `input stylus` Android 12'de kalem türü üretmez, `/dev/input` SELinux'la kapalı → gerçek kalem davranışı elle denenmeli. Avast mağaza dışı APK'yı "şüpheli" bildiriyor (sezgisel).

## 2026-11-07 — Tablet: avuç, kalem tıkı, fiziksel klavye
- **Avuç reddi `InkController`'da (ortak):** kalem ekrandayken ya da son kalem olayından (havada yaklaşma dahil) 400 ms içinde gelen parmak = avuç: çizmez, metne/madde jestine de gitmez (`claims`). Avuç kalemden ÖNCE değdiyse kalem inince avucun işi geri alınır (`_dropPalms`). Sistemin iptal ettiği dokunuş (`pointerCancel`) çizgi bırakmaz. KÖK NEDEN: avuç "ikinci parmak" sayılıp kalemin çizgisini iptal ediyordu ("kalem algılanmıyor"). Testlerde kalemden hemen sonra parmak dokunuşu için ≥ 400 ms gerçek bekleme gerekir (`tester.runAsync`).
- **Kalem kipi kapalıyken kalemin tek başına tıkı** (son çizgiden ≥ 1,2 sn sonra, ≤ 4 dp kayma) çizmez, alttaki metne/kutucuğa gider (`stylusTapMayPass`, `_InkClaimRecognizer` artık eager değil: kayınca kazanır, kalkınca bırakır). Yazı arasındaki i/ö noktası çizilir. Tabletteki notta kalem tıklarından kalmış başıboş noktalar görüldü.
- **Fiziksel klavye:** `HardKeyboard` (kanal `dev.kaimau.notlar/keyboard`). Yalnız HARİCİ HARF klavyesi sayılır (M-Pencil, ses/güç tuşları da "klavye"); kapak arkaya katlıyken (`hardKeyboardHidden`) yok. Takılıyken `TextInput.setInputControl(boş denetim)`: alan bağlı kalır, giriş türü `none` gider, sanal klavye açılmaz; not üst çubuğunda ⌨ düğmesi (`editor-soft-keyboard`) açar/kapar (odak bir kare bırakılıp geri alınır ki alan yeni türle bağlansın). Sistem kanalının Dart işleyicisi PiP'te: yeni olay için AYRI kanal aç.
- Play yorum analizi ve sonraki fazlar: `YORUM_ANALIZI_PLANI.md`.

## 2026-11-08 — Kalem, satır hatırlatıcısı, bildirim düzeyi, kapanış kasması
- **Kalem kipinde geri ana ekrana atlıyordu — kök neden:** kalem kipinin `BackCloses` kaydı ALT ÇUBUKTAYDI; kalem kipinde (`_pagePen`) alt çubuk hiç kurulmuyor → kayıt yok → geri notu kapatıyordu. Kayıt artık kalem tepsisinin çevresinde; tepsinin kendi kaydı (ayar kartı, açık kapsül) içte → LIFO sıra doğru. Bekçi `editor_pen_tablet_test`.
- **Şekil/tik/çarpı önerisi** `viewers/ink_recognize.dart` (saf geometri: RDP köşe, `recognizeInkShape` uyum hatası). Öneri `InkController.suggestion` (ayrı `ValueNotifier`, çizgileri yeniden boyatmaz); işaretçi katmanda Listener'ın ÜSTÜNDE (dokunuşu çizime gitmez). ZAMANLAYICI YOK: sonraki dokunuşta/geri alda kalkar (6 sn'lik Timer testleri "pending timer" ile düşürdü). Tik/çarpı `InkToolMemory.markFix` üç durumlu: null = ilk algılamada sor, varsayılan kapalı. Harf boyu (< 36 dp) şekil sayılmaz; artı (+) çarpı sayılmaz (kollar yataya 20–70°).
- **Sabit kalemler** `InkToolMemory.presets` (`tür|renk|kalınlık`, en çok 5, cihaz tercihi `ink_presets`).
- **Bildirim önem düzeyi = kanal** (`domain/reminder_level.dart`): Android kanalının önemi kurulduktan sonra DEĞİŞMEZ, o yüzden düzey başına ayrı kanal. '' = `high` = eski `reminders` kanalı (eski hatırlatıcılar değişmeden çalar; "Sık" etiketi). Acil = `Importance.max` + `fullScreenIntent` + alarm; `USE_FULL_SCREEN_INTENT` YALNIZ `src/kisisel` manifestinde (Play beyanı ister). `showWhenLocked` BİLEREK yok (kilitli notlar kilit ekranında açılmasın). Not alanı `reminderLevel` (gerçek alan, `toMap` koşulsuz).
- **Satır hatırlatıcısı = `tasks` kaydı** (TAKVIM_PLANI §10); `TaskItem.level/contact/gmailLink` boşken yazılmaz. `reminderTimePrefix` artık `@visibleForTesting` değil (çip ve şerit kullanıyor).
- **Ana ekran şeridi + rozet** (`data/due_state.dart`, `domain/due_items.dart`): "şimdi" (`dueClockProvider`) yalnız sonraki hatırlatıcı anına kurulan tek seferlik Timer ve `AppLifecycleListener.onResume` ile ilerler. Rozet için YENİ BAĞIMLILIK YOK: başlatıcılar rozeti bildirimden çizer → sessiz düşük önemli tek özet bildirimi (`badge` kanalı, `number`, yük `due` — `note:` değil, mutabakat dokunmasın). Bedel: sayı > 0 iken perdede bir satır. Web'de şerit `tasksStreamProvider`ı da dinler (eskiden web'de görev dinleyicisi yoktu).
- **Yazarken üst hızlı satır** (`editor_quick_row.dart`): `KeyboardSwitch` yaprağı yalnız `MediaQuery.viewInsetsOf`'a bağlı; hazır verilen alt ağaçlar aynı örnek → klavye karelerinde alt ağaç kurulmaz (F38.7 bekçisi yeşil). TUZAK: `KeyboardSnap.onSettled` klavye KAPANIRKEN çağrılmaz (inset canlıya hemen iner) — kapalı/açık durumu ona bağlama.
- **Not kapanış kasması — kök neden:** sıralama tutması (`sortHeldNoteIds`) kapanışın İLK karesinde bırakılıyordu → abonelikler sürerken zaten yeniden hesaplanan `filteredNotesProvider` ikinci kez hesaplanıp pano ekranı kuruluyordu; pano o sırada `FreezeWhenHidden` ile donuk olduğundan görünür faydası yoktu. Bırakma `dispose`ta; kapanıştaki tarih önerisi ayrıştırması +700 ms. Cihazda ölçülmedi (KALANLAR §2 A12).
## 2026-11-08 — Oturum B (arama, yazı tipi, Gmail, takvim pratikliği)
- **Arama çubuğu:** tüm hap tek `GestureDetector` iken sağdaki düğmelerin boşluğu da aramayı başlatıyordu; odak jesti yalnız sol kısımda (`_SearchField`).
- **Yazı tipi seçici = tema levhası** (`_showAppFontSheet`: perdesiz alçak levha, `_FontChoiceCard` "Aa", anında uygula, Vazgeç).
- **Seçim modu + geri:** tek seçim modu ana ekranda (`selectedNoteIdsProvider`; PopScope VAR) ve madde seçimi; PDF sayfa düzenleyicisine PopScope eklendi. Klavye açıkken ilk geri klavyeyi kapatır (sistem), ikincisi seçimi.
- **Hayalet ek sayacı:** editör ataç rozeti/şeridi zemin görselini (`backgroundImageId`) ek sayıyordu; kart/dışa aktarma saymıyordu → `Note.attachmentsWithoutBackground` ortak kural. TUZAK: yeni "ek" sayan yer bunu kullanmalı.
- **Dikte:** `_writeDictationAtCaret` sonunda `_revealCaretSoon()`; panel açılışında da.
- **Alt çubuk yazarken gizli:** `_typingN` ValueNotifier + `_TypingHide` (boy/opaklık, setState YOK); `_mutate(immediate:false)` + klavye açıkken tetikler, 650 ms sessizlikte döner. Ayar `hideBarWhileTypingProvider` (varsayılan açık), ipucu `TipOnce.typingBarHide`.
- **Takvim tekerlek:** `PinchZoomDetector.wheelZoom` yalnız yıl/ay görünümünde; `PointerSignalResolver` sayesinde kaydırılabilir alan tekeri önce alır. Hafta görünümünde yakınlaştırma artık gün (ajanda) açar.
- **Not seçici** `NoteTargetPicker`/`showNoteTargetPicker` (note_target_picker.dart): yeniden kullanılabilir; Gmail "Nota ekle", takvim "Mevcut notu bağla", nottan rutin bunu kullanır.
- **Gmail:** `gmail_smart.dart` (tarih/saat ayıklama, gönderen); iletiden oluşan not = gövdesinde ileti `webUrl`i olan not (ilgili not çipi bununla bulur).


## 2026-11-08 — Oturum C (12 maddelik istek listesi)
- **Kalem işaretçisi kök neden:** kalemin İNİŞİ önce çizimi başlatıp öneriyi siliyordu (`pointerDown` → `dismissSuggestion`), işaretçinin `onPointerUp`'ı hiç gelmiyordu. Çözüm: işaretçi inişte uygular + `InkController.claimPointer` o dokunuşu çizime vermez.
- Düzeltilmiş şekil (tik/çarpı/kare…) SEÇİLİ kalır (`_fixEdit`): kutusundan taşınır, sağ alt tutamaktan boyutlanır; tutamak kement seçiminde de var. Kare/çember eşikleri gevşetildi (açıklık %30, elips %14, dikdörtgen %9).
- Hızlı satıra "sonradan eklenen" düğmeler: `UiItem.optIn` varsayılan GİZLİ, açılınca `hidden` kümesinde `+kimlik` (kayıt biçimi aynı). Satır sonundaki ⚙ = `Personalize.startEditing`.
- Yazım düzelt: `core/utils/spell_fix.dart` (saf kurallar, testli) + `auto_spell.dart` (aktif alana `_setFormatTarget`'tan bağlanır, başlık hariç; Android'de `DefaultSpellCheckService` ilk önerisi, Levenshtein ≤2). Tek karakter yazımında çalışır; yapıştırma/dikte dokunulmaz.
- Not paketi: metinde `AttachmentKind.text` + `extras.package` (etiketi `📎 ad`, ADLA eşleşir → `packageName` çakışmada numaralar); listede `NoteItem.package` (kapalı paket: ilk satır özet, kalanlar SIFIR yükseklik — sürükleme dizinleri bozulmasın diye satır kaldırılmaz; açıkken `TapRegion` dışarı dokununca daraltır).
- Gmail çoklu hesap yalnız Android: `AccountManager.newChooseAccountIntent` → e-posta → `googleScopeAuth(account:)`; uygulamanın giriş hesabı değişmez. Jeton anahtarı hesaba göre.
- Balon el yazısı: `HandwriteField` kalemi alır (parmak alana gider), 0,9 sn sonra çizgiyi PNG'ye basıp mevcut ML Kit OCR'ından geçirir — yeni bağımlılık yok; bitişik yazıda zayıf (yükseltme: ML Kit Digital Ink).
- Sabit PDF'e kalem: `PdfPageBox.ink` verilince sayfa katmanı etkileşimli; kalem kaydırmaz (`ScrollConfiguration.dragDevices`), parmak "yalnız kalem"de kaydırır. Görsel için YOK (BoxFit.contain koordinatı) — sonra.

## 2026-11-08 — Oturum D (18 maddelik ikinci tur)
- **Not paketi kendiliğinden kalkıyordu — kök neden:** `_sameItem` (text_merge), `ItemsEditor._sameItems`, `sameItemsVisually` `package` alanına bakmıyordu → birleştirme yerelin paketlemesini "değişmedi" sayıp uzaktaki paketsiz kopyayı yazıyordu. Yeni GÖRÜNÜR madde alanı → bu ÜÇÜNE de ekle. Açık pakette Enter/yeni madde paketi miras alır; paketin boş son maddesinde Enter paketten çıkarır.
- **Sabit PDF'e kalem yazmıyordu — kök neden:** `PdfPageBox._pageOverlay`'de mürekkep katmanı seçim + balon katmanlarının ALTINDA; dokunuşu seçim katmanı alıyordu. Kalem açıkken mürekkep EN ÜSTTE, seçim katmanı yok, balonlar salt okunur.
- **Kare/çember karışması — kök neden:** eski tanıyıcı eksene hizalı kutuya göre ölçüyordu (yuvarlak köşeli kare elips hatasında düşük; eğik dikdörtgen hiç). `recognizeClosedShape` (ink_recognize): dışbükey zarf → en küçük döndürülmüş kutu; elips/dikdörtgen/dörtgen/üçgen ortalama uzaklık/köşegen ile yarışır (dörtgen ×1,25 ceza). En/boy ≤ 1,18 → kare/daire (`regular`), dik açılı değilse serbest dörtgen (`InkFixKind.quad`), eksene < 10° eğim düzelir. Basılı tut-şekle-dönüştür de bunu kullanır. Şekil aracına Üçgen + Tablo (3×3, tek çizgi, kenardan geçer).
- **Esc = geri:** `EscBackIntent` (app.dart `shortcuts`) — `DismissIntent`'e BAĞLAMA: metin alanı odaktayken `EditableText`'in DismissIntent eylemi `Actions.invoke` ile sayfa rotasının DEVRE DIŞI eyleminde durur, Esc hiçbir şey yapmaz. Eylem: açılır rota (PopupRoute) → kapat; değilse kök yönlendiricinin `backButtonDispatcher.invokeCallback`.
- **Tablette hızlı satır gelmiyordu:** yüzen/ayrık/fiziksel klavyede `viewInsets.bottom` 0. `KeyboardSwitch(editing:)` tablette (en kısa kenar ≥ 600, web değil) alan odaktaysa da açar (`_fieldFocusedN`, FocusManager dinleyicisi). Test yüzeyi 800×600 = TABLET sayılır: telefon davranışı testlerinde `tester.view.physicalSize = 400×800`.
- **Sürükleme tutamağı** web/tablette hep görünür (`_pinHandles`, satır önbelleği ortam anahtarında); soldaki 12 dp dolgu 2'ye iner.
- **Öğrenen yazım düzeltme** (`core/utils/spell_learn.dart`, saf; `auto_spell.dart` bağlar): kişisel sözlük (yazılan + notlardan `seedCounts`, `compute` ile oturumda bir kez) + kelime düzeltmeleri (biten kelimeye geri dönüp değiştirme = öğren; otomatik düzeltmeyi geri alma = `reject`, bir daha dokunma) + harf karışıklıkları (`alignSubstitutions` → `confusions`, mesafede ucuzlar). Klavye düzenli ağırlıklı Damerau–Levenshtein (`keyCost`: komşu 0,45, şapka 0,3, boşluk komşusu cvbnm). Boşluk yerine n: `splitMissedSpace` (iki parça da bilinen) + Android'de cihaz denetçisiyle `_nativeSplit`. TÜRKÇE EK TUZAĞI: aday yazılanın ön eki/uzantısıysa ("kalemi"/"kalem") düzeltilmez; yalnız yazılmış kelime 3 görülmeden "bilinen" sayılmaz. Çince: bulanık yok, yalnız açık düzeltme. Hafıza dosyada (`appSupportPath/spell_memory.json`, web'de tercih), 4 sn erteli yazma. Başlık: `titleFixAt` (kelime başı büyük) + `textCapitalization.words`. Hızlı satırda yazım düğmesine basılı tut = ayarlar levhası.
- Alt çubuk yazarken 1,1 sn sonra; yeni alana geçince ve klavye kapanınca (KeyboardSnap builder'ında inset 0) HEMEN (`_showBarNow`).
- Balondaki kalemle yaz → metin (`handwrite_field.dart`) kaldırıldı. Kalem hapı 48 dp + ayraç + 48 dp silgi hedefi. Hızlı satır: kalem yalnız simge; Fotoğraf çek, Tarih/saat ekle varsayılan; Belge tara sonradan eklenir. Satır hatırlatıcı çipi 22 dp sabit, ilk satıra ortalı; dokun = menü (zaman, tamamlandı, ayrıntı, SİL + geri al).


## 2026-11-08 — Oturum E (15+2 maddelik üçüncü tur)
- **Seçimde geri tuşu çalışmıyordu — kök neden `BackCloses`:** Flutter rotadaki BÜTÜN PopScope'ları çağırır; KAPALI bir `BackCloses` (ör. kalem kipi kapalı) `_onPop`'ta `orElse: this` ile kendini "kapatıp" `_consumed = true` yapıyordu → ekranın kendi geri işi (`BackCloses.handling` true) hiç çalışmıyordu. Açık panel yoksa artık olay tüketilmez. Bekçi `items_selection_back_editor_test`.
- **Takvim zemini KALDIRILDI** (`calendar_backdrop.dart` silindi; `DashboardBackground.calendar` yok). Yerine `HomeCalendarStrip` (ana ekran tepesi, 10 gün, `homeCalendarStripProvider` varsayılan açık, `homeCalendarStripOpenProvider` daralt). Takvim aboneliği yalnız şerit AÇIKKEN (`calendarDataProvider`). Güne dokun = `showCalendarDaySheet`, basılı tut = `/calendar?day=`. `CardSeeThrough` sınıfı duruyor ama artık hiçbir yerde açılmıyor.
- **Gün levhası canlı veri** (`calendarDataProvider`; eskiden açılıştaki anlık görüntü) + satır başına çöp (`calendar_entry_delete.dart`, geri alınır; tekrarlayan = yalnız bu/hepsi; Google = onay). Ay sayfası çevirince seçim değişmez; "Yeni" seçili gün görünen ayda değilse ayın 1'i/bugün.
- **İpuçları (TipOnce) artık ÜSTTE ve dokunuş geçirgen** (OverlayEntry, IgnorePointer; ilk dokunuşta kalkar). Eskiden alttaki SnackBar ek menüsünü/alt çubuğu örtüyordu. Kalem ipuçları: `penToggle`, `penShapeHold` (2. çizgi), `penEraserHold` (5. çizgi).
- **Kalem:** hızlı satırdaki kalem aç/kapa (`_togglePen`, diğer yollar `_openPen` = aç). Parmak var olan çizgide 550 ms kıpırdamadan durursa `InkController.eraserOffer` → silgi düğmesi (inişte kabul + `claimPointer`); yakınlık yeni nokta eklenmeden ölçülür.
- **Ana ekran:** basılı tut = doğrudan sürükle (`_ReorderableNoteCell`, seçim kapalıyken de). Yer değişmediyse ve yol < 12 dp → eski iş (seçim), sıra KAYDEDİLMEZ (ölçüt "elle"ye dönmez). Süzgeç/klasör/aramada yalnız seçim (alt kümede sıra anlamsız).
- **Yazım:** `AutoSpell.replacedWord` (tek adımda kelimenin yerine yakın başka kelime = klavye önerisi/yerinde düzeltme → `learnFix`; tamamlama sayılmaz). Ayarlar → Öğrenilen yazımlar (`SpellLearnedScreen`: liste, elle `addManualFix` ilk görüşte uygulanır, sil, dokunulmayanlar). Boşluk komşusu `cvbnmö`.
- Alt çubuk 50 dp; yazarken gizleme 3 art arda değişiklikten sonra (`_typedBurst`). Seçim çubuğunda "Pakete al" (`togglePackage`), düğmeler compact. Kısayol adı/simgesi `stripRichMarkers`. Gmail "İletiyi çevir/Orijinali göster" (Gemini `translateText`, bir kez çevrilir). Klasör çekiş menüsünde Yeni klasör + Sırala·sil (`FolderOrderPanel` satırında sil). 5 sade klasik tema (`classic/newsprint/notebook/graphite/ledger`, koyu = beyazın koyusu; vurgu doygunluğu > 0,2 testi).
