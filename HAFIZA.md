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
- Biçim paneli üç sabit sıra (Stil · Renk · Yazı), açılır menü YOK; kapsam
  `FormatScope` (İmleç/Kelime/Satır/Tümü). Panel açıkken geri paneli kapatır.
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
- Görsele çizim + açık metin (`PageBubble.plain`) dışa aktarmada/paylaşımda
  görselin üstüne BASILIR (`image_annotations.dart`, PNG; F18.13).

- Taranmış PDF OCR (2026-11-03): işler TEK KUYRUKTA + 40 sn zaman aşımı
  (eşzamanlı çizim+ML Kit ilk açılışta takılıyordu); disk önbellek anahtarı
  `v2`, damga yalnız dosya BOYU (mtime yeniden indirmede değişip her açılışta
  baştan tanıtıyordu).

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
- **Tema (TEMA_PLANI, 2026-11-04):** üç aile `ThemeFamily` (Adaçayı
  varsayılan, Porselen, Kil) × açık/koyu, renkler `app_palette.dart`,
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
- **AI hata metni (F36.5):** `aiErrorText(l10n, e)` — `aiError(friendlyError())`
  YAZMA (okunur `GeminiException` çift başlık alıyordu). Daire jesti AI yoksa
  bir kez `gestureFixNeedsAi`, sonra oturum boyu sessiz; karalama silmesi
  bildirimde Geri al.
- **Bölüm başlığı (F36.7):** tek `SectionLabel`, cümle düzeni (büyük harf
  yalnız rozet: BALONLU PDF, SUNUM, VİDEO, YENİ); Başlık Düzeni ad yok
  ("Çöp kutusu"). Sayı 0 → rozet çizilmez; boş klasör solması renkte
  (`Opacity` yok).
- **Ekran turu (F36.3):** `tool/tour/screen_tour_test.dart` (CI dışı) →
  `build/tour/*.png`, 4 boyut. TUZAK: testte `debugDisableShadows` → FAB/panel
  çevresinde koyu halka çizilir, GERÇEK DEĞİL.
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

- **Ek senkronu v2 (F28.2, 2026-11-04):** yeni yapı `domain/attachment_sync.dart` (durum makinesi, saf) + `data/drive_files_api.dart` (`drive.file`, görünür "Notlar" klasörü) + `data/attachment_thumb.dart`; Storage'ta yalnız `users/{uid}/thumbs/` ≤ 40 KB. HENÜZ BAĞLI DEĞİL — canlı yol hâlâ `UploadQueue` + `drive_store` (`drive.appdata`). TUZAK: Storage kuralları OR'lanır; genel `users/{uid}/**` 50 MB kuralı thumbs yolunu `request.resource.name` ile dışlamazsa 40 KB tavanı boşa düşer. Kayıt sıfırlama (C) gece görevinde ÇALIŞTIRILMAZ (F19.E1).
- **Gmail (F28.1, 2026-11-04):** `features/gmail/`, yalnız GET (`gmail_test` doğrular), kapsam `gmail.readonly` Drive'dan AYRI istenir. TUZAK: `http.Response.body` charset başlığı yoksa latin1 çözer → Gmail JSON'unu `utf8.decode(bodyBytes)` ile oku. Jeton önbelleği `DriveTokenCache` (adı Drive ama kapsamdan bağımsız).

## Merkezi asistan bırakıldı (2026-11-02)
- Kullanıcı: asistan (`com.ses.asistan`) çok pil yiyordu; ses her uygulamanın içinde. Kişisel alıcıdan
  `ASISTAN_SORGU` ve asistan sertifikası silindi; `HARITA_NOT` (Harita, Kanallarım) aynen. `image` eki
  şimdilik gönderen yok (yalnız asistan yolluyordu) — Kanallarım/Dosya Okuyucu notunda kullanılabilir.

## Açık sorular / bilinen
- Misafir notunda üst çubuk "Senkronize", ana ekran "yalnız bu cihazda"
  diyor — karara bağlanmadı (2026-11-01).
- **Kare ölçümü tabanı** (F18.7, koşu 41422268562, emülatör): ana ekran fırlatma build p90 4,12 / raster p90 6,33 ms; editör yazma build p90 0,26 / raster p90 6,28 ms; kaçan kare 0. Karşılaştırma koşudan koşuya (mutlak değer cihazda farklı). Ölçüm işi `NOTLAR_ALL_ABIS=1` + `--no-dds` ister.
- Cihaz doğrulama listesi `KALANLAR.md` §2 (F18.31 duman testi).
