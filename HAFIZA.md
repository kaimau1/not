# Not Uygulaması — Hafızası

Tarihli, append-only. İş başında oku; iş sonunda kalıcı karar/bug-kök/tuzak varsa ekle. Sır/anahtar/kişisel veri YAZILMAZ.

## Kararlar (tarihli, append-only)

- 2026-08-18: **CI otomatik deploy KURULDU VE YEŞİL** (main push → Firebase rules + Cloudflare Pages `notlar-web`, `.github/workflows/build.yml` `deploy` job). Secrets: `FIREBASE_SERVICE_ACCOUNT`, `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`. Çözülen KÖK NEDENLER (üç ayrı 403, sırayla): (1) Firebase servis hesabının `serviceusage.services.get` izni yoktu → GCP IAM'de servis hesabına **Editor** rolü verilerek çözüldü (Service Usage Consumer'dan sonra da devam etti, Editor ile geçti — muhtemelen ilk seferinde rol yanlış hesaba/projeye eklenmişti). (2) Cloudflare API token **Account Resources** seçili değildi (yalnız Zone Resources vardı) → hesap düzeyindeki Pages API'ye 403 veriyordu; token'a **Account → Cloudflare Pages → Edit** + **Zone → DNS/Page Rules → Edit** ve Account Resources'ta hesap seçilerek düzeltildi. (3) `wrangler pages deploy`, var olmayan projeyi OTOMATİK OLUŞTURMUYOR ("Project not found") → proje `POST /accounts/{id}/pages/projects` ile elle oluşturuldu (`notlar-web`, production_branch=main).
- 2026-08-18: **hekimasistani.com artık notlar'ın web sürümü — TAMAMLANDI**. Apex + www ikisi de `notlar-web.pages.dev`'e CNAME (proxied) ile bağlı, Pages custom domain olarak `active`/SSL hazır. Eski placeholder A kayıtları (`192.0.2.1`) silindi. Eski "ahek plus" yönlendirmesi bir **Cloudflare Single Redirect** (Rules → Redirect Rules) kuralıydı — Worker/Page Rule değildi; kullanıcı dashboard'dan elle sildi. TUZAK: Cloudflare API token'ında "Zone Resources" ayrı "Account Resources" ayrıdır — biri seçiliyken diğer kapsamdaki her istek "Authentication error [code: 10000]" verir, mesaj token'ın GEÇERSİZ olduğunu değil YANLIŞ KAPSAMDA olduğunu düşündürür (kafa karıştırıcı).

- 2026-07-25: **Ataç menüsü nav çubuğu altında kalma — KÖK NEDEN**: `_showAttachMenu` (`note_editor_screen.dart`) sheet'i 8'e kadar `ListTile` içeren `Column`u yalnız `SafeArea` ile sarmış, scroll'a sarmamıştı; kardeş sheet'ler (`note_actions_sheet.dart`) `SingleChildScrollView` kullanıyordu. Liste + sistem nav çubuğu ekran yüksekliğini aşınca son seçenekler taşıp nav butonlarının altında kalıyordu. ÇÖZÜM: `Column` `SingleChildScrollView`'a sarıldı. NOT: yereldeki `flutter build apk --release` ile telefona `android/key.properties` + Desktop\notlar-keystore\notlar-release.jks kopyalanarak CI ile AYNI imzayla kuruldu (adb install -r, uygulama silinmeden güncellendi); ikisi de `.gitignore`'da (key.properties zaten vardı, `*.jks` eklendi).

- 2026-07-25: **Altı maddelik düzeltme paketi** (dal: `claude/app-bug-fixes-woipw4`): (1) **KÖK NEDEN — dashboard aşağı kaydırırken liste yukarı sıçraması**: `SliverMasonryGrid` tembeldir ve toplam kaydırma uzunluğunu (`SliverGeometry.scrollExtent`) sona ulaşmadıkça `extrapolateMaxScrollOffset` ile, YALNIZCA o an yerleşmiş kartların ortalama yüksekliğinden tahmin eder. Masonry'de kart boyları çok farklı olduğu için tahmin her yerleşimde oynuyor; tahmin o anki `pixels`'in altına düştüğü an `ScrollPosition.applyContentDimensions` konumu düzeltiyor (= liste yukarı zıplıyor), sona yaklaşırken sıklaşıyor. ÇÖZÜM: dashboard `CustomScrollView`'a `cacheExtent: 10000` — kartların tamamı ilk yerleşimde ölçülür, `reachedEnd` doğru olur, uzunluk tahmin değil GERÇEK olur, düzeltme hiç olmaz. KARAR/TUZAK: bedeli, o pay içindeki kartların önceden kurulması (≈130 kart); bu sınırın ötesinde tembelliğe ve dolayısıyla sıçramaya geri dönülür. Denenip REDDEDİLEN yol: delegenin `estimateMaxScrollOffset`'ini `trailingScrollOffset` döndürecek şekilde ezmek — uzunluk hep eksik kalacağından fling her ~250 px'de duruyor, sıçramadan daha kötü. (2) **Ek şeridi sayfanın dibine + kapanabilir**: `AttachmentStrip` başlıkla gövde arasından çıkıp `bottomNavigationBar`'a taşındı; başlıkta "Ekler (n) · Gizle/Göster" satırı var, tercih `attachmentsExpandedProvider` ile kalıcı. TUZAK: "klavye açıkken şeridi çizme" koşulu editörün build'ine DEĞİL `AttachmentStrip.build`'ine konur — `MediaQuery.viewInsetsOf` editörde okunursa klavye animasyonunun her karesinde tüm editör yeniden kurulur. (3) **QR okuma** `mobile_scanner ^7.4.0` ile: kameradan canlı + galeriden `controller.analyzeImage(path)`. Windows eklentisi YOK → `qrScanSupported` (Android/iOS/macOS) menü girişlerini gizler. QR içeriği nota `_appendPlainText` ile ham girer: `_appendText`'in `stripMarkdown`'ı `#`/`*` taşıyan adresleri bozuyordu. (4) **Foto çek not al**: `(+)` menüsü → `/note/$id?photo=1` → `startPhoto` bekleyen niyeti; ayrıca ataş menüsünde "Fotoğraf çek". Fotoğraf sıradan görsel ektir (sürüklenir, OCR edilir). (5) **Video oynatıcı**: konum/süre etiketleri + sürüklenebilir `Slider` + ±10 sn + görüntüye dokun-oynat/durdur. Sürükleme sırasında konum `_dragMs`'te tutulur; oynatıcının kendi `position`'ını kullanmak kaydırıcıyı parmağın altından kaçırıyordu. (6) **`(+)` menüsünde arka plan bulanıklığı**: bariyer `BackdropFilter` (sigma 10, %18 karartma, 180 ms). TUZAK: bariyer asıl "+" düğmesini de bulanıklaştırdığından üstüne KESKİN bir eş FAB konur; hizası `LayerLink`'e alttan-ORTA demirlenir — bağlantı noktası tüm düğme sütununu sarıyor ve sütun `CrossAxisAlignment.center` olduğundan sağa dayamak 14 px kaydırıyordu. NOT: bu oturumda Flutter SDK ortamda YOKTU; `analyze`/`test` çalıştırılamadı, doğrulama CI'ya bırakıldı — `pubspec.lock` da bu yüzden elden geçmedi, CI `pub get` tazeliyor.

- 2026-07-20: **Dashboard UI paketi** (dal: `claude/dashboard-note-ui-fixes-4bi9f8`): (1) **Not kartı basılı-tut → sürükle-sırala**: NoteCard uzun basışı artık çoklu seçim değil sürükle-sıralamadır (`_ReorderableNoteCell` = `LongPressDraggable`+`DragTarget`, veri = not id; sürükleme yalnız kendi bölümüyle — sabitliler/diğerleri — sınırlı). Yeni sıra `NotesRepository.reorderNotes` ile `orderIndex = i*1000` olarak yazılır; sıralama ölçütü otomatik `manual`'e alınır. KARAR: seçim modu girişi kart uzun-basışından `⋮ → Seç`'e taşındı (note_actions_sheet'te zaten vardı). Sürükle-sırala YALNIZCA süzgeçsiz görünümde açık (filtre=Tümü, etiket/klasör/arama yok) — alt kümede elle sıra anlamsız. (2) **Filtreler arası geçiş animasyonu**: dashboard CustomScrollView `AnimatedSwitcher`'a sarıldı, anahtar = `filtre|klasör|etiket` (arama sorgusu HARİÇ — her tuşta yeniden animasyon olmasın); yatay çekiş yönü `_swipeForward` ile kaydır+soldur yönünü belirler. (3) **İlk not açılış kasması**: editör `initState`'te notu `notesStreamProvider`'dan SENKRON okuyup ilk kareyi dolu kurar (spinner→editör takası ve onunla gelen yerleşim sıçraması kalktı). (4) **Genişletilebilir filtreler**: DashboardChipsRow'a genişlet/daralt düğmesi (`filtersExpandedProvider`); açıkken klasör ve etiketler bölümler hâlinde Wrap ile TAM görünür (yatay kaydırma gerektirmeden), `AnimatedSize` ile yumuşak. (5) **Kart düzeni**: üç nokta düğmesi Stack overlay'iyle SAĞ ÜST KÖŞEye alındı (ikon köşeye hizalı); başlıksız notta boş üst bant çizilmez → içerik tepeden başlar ("yazılar ortaya kayıyor" düzeldi). TUZAK: Flutter l10n `generate: true` → CI `flutter pub get` arb'den yeniden üretir; yerelde flutter yoktu, yeni anahtarlar (foldersSection/tagsSection/expandFilters/collapseFilters) hem arb'ye hem generated dosyalara elle eklendi.


- 2026-07-16: **Proje kuruldu** — Flutter + Firebase not uygulaması (dal: `claude/notes-firebase-sync-app-ihwzev`). Firebase `notlar-kaimau` projesi gerçek değerlerle bağlandı; Firestore/Storage kuralları `firebase.json` üzerinden CLI ile yayınlanabilir.
- 2026-07-16: **Özellik paketi**: hatırlatıcılar, etiketler, arşiv/çöp, ses+çizim, AI sohbet, OCR, widget. **AI paketi**: asistan, sesli komut, semantik arama, günlük brifing, otomatik etiket, notu geliştir, PDF sohbet. **Çeviri**: Gemini 3.5 Live Translate ile canlı konuşma çevirisi. **Sesli hızlı yakalama**: "Hey Google, Notlar'ı aç" + tek dokunuş akışı.
- 2026-07-16: **CI imzalı APK** GitHub Secrets üzerinden kalıcı imza. TUZAK: workflow'da `secrets` bağlamı step `if:` içinde kullanılamaz → kontrol bash adımına taşındı. (Runner arızası yaşandı, yeniden tetiklemeyle çözüldü.)
- 2026-07-16: graphify kod grafı + otomatik tazelik hook'ları kuruldu (usta paketi); CLAUDE.md + bu HAFIZA eklendi.

- 2026-07-17: **Mobil kullanılabilirlik paketi** (dal: `claude/mobile-notes-improvements-8ofm7j`): (1) Liste editöründe Enter'da klavyenin kapanıp açılmasının kökü, `TextInputAction.next`'in varsayılan odak geçişinin metin dışı öğeye gitmesiydi → `onEditingComplete` ile bastırıldı. (2) Dar ekranda arama odaklanınca AppBar aksiyonları gizlenir. (3) Uzun basış artık pin/sil sayfası değil çoklu seçim modu açar; toplu silme + tek "Geri Al". Silme snackbar'ları `fixed` + 3 sn (floating olan FAB'ların üstünde/ortada duruyordu). (4) AI otomatik başlık: editör kapanırken başlıksız nota `fastGeminiModel` (flash-lite) ile başlık; ayarı `auto_title`, varsayılan AÇIK. (5) Hatırlatıcılar ekranı `/reminders` (listele/düzenle/kaldır/manuel ekle). (6) Sesli not bitişinde "Notu aç" — asistan araç yanıtındaki `noteId` yakalanır. (7) Gmail bağlarken `authenticate(scopeHint:)` ile hesap seçici açılır (yalnız `authorizeScopes` seçici göstermeden giriş hesabını kullanıyordu); bağlı e-posta prefs'te (`gmail_account_email`) ve Ayarlar'da gösterilir. TUZAK: OAuth "Testing" modunda 2. Gmail hesabı, Cloud Console'da test kullanıcısı olarak eklenmeden çalışmaz.
- 2026-07-17: pubspec.lock'ta `just_audio_windows` eksikti (pubspec.yaml'a eklenmiş ama lock commit'lenmemiş) → `pub get` ile lock ve Windows plugin registrant dosyaları tazelendi.

- 2026-07-17: **Hız paketi 2**: (1) E-posta yavaşlığının kökü Gmail metadata'larının 25 ardışık istekle çekilmesiydi → `Future.wait` ile paralel; ayrıca `category:primary` sekmesiz kutularda (Workspace) boş dönüyordu → kategorisiz sorguya fallback ("çalışmıyor" algısının nedeni). (2) `importantEmailsProvider` 15 dk, `briefingProvider` 30 dk `keepAlive` önbelleği; brifing e-posta bölümü 20 sn zaman aşımıyla atlanır, notlar `read` ile okunur (her not değişiminde çift AI çağrısı tetiklenmesin). TUZAK: autoDispose provider'ı `ref.read(x.future)` ile beklemek erken dispose riski taşır — bağımlılıkta `watch` kullan. (3) Ana sayfa etiket satırı en sık 8 etiket + "+N" alt sayfası; kartlarda en fazla 2 etiket + "+N" rozeti.

- 2026-07-17: **Android CI derlemesi kronik iptal**: `assembleRelease` art arda 2 kez ~13-16 dk'da "runner shutdown signal" ile kesildi (Windows/Analiz+Test aynı çalışmada sorunsuzdu). Kök neden kota değil hız: (1) Gradle wrapper/bağımlılık önbelleği yoktu → her derleme ~5 dk salt indirme/çözümlemeyle başlıyordu, (2) varsayılan "fat" APK 3 mimari (arm64/armv7/x86_64) için ayrı ayrı Dart AOT derliyordu — en uzun tek adım buydu. Düzeltme: `actions/cache` ile `~/.gradle/{caches,wrapper}` önbellekleniyor, wrapper `-all.zip`→`-bin.zip`, `gradle.properties`'e `org.gradle.parallel`/`caching=true`, ve `flutter build apk`'ya `--target-platform android-arm64` eklendi (kişisel kullanım — tüm güncel telefonlar arm64). TUZAK: GitHub App entegrasyonunun Actions'a yazma izni yok (`rerun_failed_jobs`/`rerun_workflow_run`/`run_workflow` hepsi 403 "Resource not accessible by integration") — yeniden tetiklemek için boş commit push etmek gerekiyor.

- 2026-07-17: **Windows CI'dan çıkarıldı** — kullanıcı isteğiyle her push'ta Windows derlemesi (yavaş, nadiren gerekli) kaldırıldı. Yerine depo kökünde `build-windows.bat` (çift tıkla derle; `--dart-define-from-file=env.json` ile gizli değerleri yerelden okur) + `env.example.json` şablonu. Masaüstü OAuth kimlik bilgileri artık GitHub Secrets'ta değil yalnızca yerel `env.json`'da. Android hâlâ CI'da; `main`'de Release yayınlıyor.

- 2026-07-17: **Boş not + arama daralması**: (1) Boş notlar artık dashboard listesinde hiç gösterilmez (`filteredNotesProvider` eler); arka plan temizliği 1 saat→2 dk cutoff'a indi ve açılışta bir kez değil her snapshot'ta (30 sn throttle) çalışır. Editörde açık boş not yanlışlıkla silinirse editörün merge'lü yazımı dokümanı yeniden oluşturur — güvenli. (2) Arama barı daralmıyordu çünkü sistem geri tuşu klavyeyi kapatsa da odak düşmüyor; `searchExpanded` koşuluna `viewInsets.bottom > 0` (klavye görünürlüğü) eklendi + `onTapOutside` unfocus + genişkenken geri oku. TUZAK: mobilde TextField odağı klavye kapanınca otomatik düşmez — "odaklı mı" yerine "klavye açık mı"ya bakmak gerekir.

- 2026-07-17: **Anahtarsız dahili AI + freemium temeli**: `firebase_ai` (Firebase AI Logic, Gemini Developer API arka ucu) eklendi. Anahtar girilmemişse GeminiService istekleri `FirebaseAiClient`'a yönlendirir (REST map'leri firebase_ai tiplerine çevrilir; istemler tek yerde kalır). `AiGate`: BYOK kapıdan hiç geçmez, premium (`users/{uid}.premiumUntil` Timestamp, şimdilik konsoldan yazılır) serbest, değilse günde `AppConstants.freeDailyAiCalls`(5) yerel hak. Anahtarsız modda desteklenmeyenler: embedding (semantik arama düz aramaya düşer), TTS ve canlı çeviri (anahtar ister, arayüz zaten toleranslı). Kurulum şartı: Firebase konsolunda AI Logic etkinleştirilmeli; App Check enforcement AÇILMAMALI (GitHub APK sideload'da AI kırılır) — Play'e geçerken açılacak. Kota sayacı cihaz-yerel (SharedPreferences) — Play sürümünde sunucu tarafına taşınacak. firestore.rules'a users/{uid} kök doküman kuralı eklendi → `firebase deploy` gerekli.

- 2026-07-17: **Play hazırlığı ②**: Ayarlar'a "Hesabımı ve verilerimi sil" (AccountService: Storage users/{uid} özyinelemeli + Firestore notlar 400'lük batch + kök doküman + Auth delete; `requires-recent-login` gelirse yeniden Google girişi yaptırıp tekrar dener) ve "Açık kaynak lisansları" (showLicensePage) eklendi. Play'in hesap-silme zorunluluğu böylece karşılandı.

- 2026-07-17: **Play hazırlığı ③ (Console hariç)**: (1) PRIVACY_POLICY.md + uygulama içi `/privacy` ekranı (asset olarak yüklenir; tek kaynak). (2) AI çıktısı bildirme: sohbet balonları ve AI sonuç sayfasında bayrak ikonu → `users/{uid}/aiReports` (Play üretken AI politikası). (3) Anahtar zorunluluğu kilitleri kaldırıldı: chat_screen ve ai_sheet artık anahtarsız da açılır (dahili AI). (4) CI: main push'ta `flutter build appbundle` → `notlar-android-aab` artifact'i (Play, APK değil AAB ister). (5) Özgün ikon: PIL ile üretilen not+kıvılcım tasarımı, `flutter_launcher_icons` ile Android adaptive + Windows ico; kaynaklar `assets/icon/`, yenileme `dart run flutter_launcher_icons`.

- 2026-07-17: **Nokta atışı 5 özellik**: (1) Paylaş menüsünden not alma: `receive_sharing_intent` + manifest SEND/SEND_MULTIPLE filtreleri; metin/link gövde, görseller ek olur, editör açılır (`share_intake.dart`, dashboard ayakta tutar). (2) Hatırlatıcı bildirimine "Tamamlandı"/"1 saat ertele" aksiyonları (payload `note:<id>`; düz dokunuş notu açar; `showsUserInterface: true` ile ana izolatta işlenir — arka plan izolatı Firebase init derdi yok). (3) Not kilidi: `Note.locked` + `local_auth` (3.x API: `options` yok, `persistAcrossBackgrounding` parametresi); MainActivity `FlutterFragmentActivity` yapıldı (local_auth şartı), `USE_BIOMETRIC` izni. Kilitli not: kartta içerik gizli, arama yalnız başlıkta, embedding/AI bağlamlarına girmez. (4) Çöp 30 gün sonra otomatik boşalır (`purgeOldTrash`, açılışta); kalıcı silme artık Storage eklerini de siler (`deleteNotePermanently` — önceden dosya sızıntısı vardı). (5) Ayarlar'da "Yedeği dışa aktar (JSON)". TUZAK: cihazda hiç ekran kilidi yoksa `authenticateForNote` engellemez (bilinçli).

- 2026-07-17: **Düzeltmeler**: (1) CI TUZAK: `receive_sharing_intent 1.9.0` compileSdk 37 istiyor, AGP 9.0.1 max 36 → `checkReleaseAarMetadata` hard fail. `1.8.1`e (compileSdk 34, aynı API) sabitlendi. Caret `^1.8.0` yine 1.9.0 çekiyordu, tam sürüm yazıldı. (2) Liste editörü kaydırma sorununun kökü: sürükleme tutamacı `ReorderableDragStartListener` (anlık) idi; tutamaca denk gelen parmak kaydırmayı reorder sanıp yutuyordu → `ReorderableDelayedDragStartListener` (uzun-basış). Regresyon testi: `test/items_editor_scroll_test.dart`. (3) Dahili AI "token invalid": FirebaseAiClient._mapError App Check/token/service-disabled hatalarını "kendi anahtarını gir" öneren Türkçe isAuthError mesajına çevirir. GERÇEK ÇÖZÜM kullanıcı tarafında: Firebase konsolunda App Check enforcement KAPALI olmalı (sideload APK'da attestation yok) VE AI Logic etkin olmalı.

- 2026-07-17: **CI TUZAK 2 → nihai çözüm** (receive_sharing_intent): 1.8.1 Java 11/Kotlin 17 uyuşmazlığı veriyordu; kök `build.gradle.kts`'e eklenen `subprojects { JavaCompile → 17 }` AGP'nin compileOptions'ı tarafından geçersiz kılındı, İŞE YARAMADI (iki tur denendi). NİHAİ: 1.9.0'a dönüldü (Java+Kotlin ikisi de 17, uyuşmazlık yok) + `app/build.gradle.kts` `compileSdk = 37` (1.9.0'ın şartı; Google logda bunu öneriyor; AGP 9.0.1 "önerilen üst 36" yalnız uyarı). Java hack'i kaldırıldı. DERS: modern eklenti + gerekli compileSdk, eski eklenti + JVM hack'inden daha temiz.

- 2026-07-17: **Liste satır sarma + çöp boşaltma**: (1) ItemsEditor TextField varsayılan maxLines:1 idi → uzun satır yatay kayıyordu. `expandItems` param + `expandListItemsProvider` (varsayılan true): true→maxLines null (sarılır), false→odaklıysa null yoksa 1 ("dokununca aç"; FocusNode listener setState). Ayarlar>Görünüm'de anahtar. (2) Çöp ekranına AppBar "Çöpü boşalt" (delete_sweep) → onay → hepsini `deleteNotePermanently` (ekler dahil).

- 2026-07-18: **CI APK derlemesi isteğe bağlı**: Her branch'e her push'ta `android` job'ı (~15 dk) çalışıp GitHub Actions kotasını boşa yakıyordu. `android` job'ına `if: github.event_name == 'workflow_dispatch' || contains(github.event.head_commit.message, '[apk]')` eklendi — APK/AAB/Release yalnız elle tetiklemede veya commit mesajında `[apk]` geçince üretilir. `test` (analiz+test, ~3 dk) her push'ta kalmaya devam eder. Sonuç: main'e merge artık kendiliğinden yeni sürüm YAYINLAMAZ; sürüm istendiğinde Actions → Run workflow (main'de) ya da `[apk]` etiketli commit gerekir.

- 2026-07-18: **"Token invalid" kök neden kesinleşti + çözüldü**: App Check konsolunda Storage/Realtime DB/Authentication "Unenforced" iken yalnız **Firebase AI Logic** satırı "Basic - Enforced" idi (Unverified requests %100) — anahtarsız/dahili AI isteklerinin tamamı bu yüzden reddediliyordu (sideload APK attestation'sız). Kullanıcı App Check → APIs → Firebase AI Logic satırını Unenforced'a çekti. Deploy/kod değişikliği gerekmedi, yalnız konsol ayarı; mevcut APK'lar yeniden derlenmeden düzelir.

- 2026-07-18: **Sesli sistem yerleşik tanımaya taşındı + liste editörü 3 düzeltme (8 madde)**: (1) **KÖK NEDEN — "dikte ettiğim yazılmıyor, geri gelince beliriyor"**: `ItemsEditor.didUpdateWidget` yalnızca öğe kimlikleri TAMAMEN değiştiğinde yerel listeyi yeniliyordu; dikte/hesap makinesi/AI bir öğe eklediğinde eski kimlikler durduğu için koşul tutmuyor, eklenen öğe ekranda hiç görünmüyordu (editör kapanıp açılınca `initState` listeyi baştan kurunca beliriyordu). Veri hep doğru yazılıyordu, sorun tamamen görüntülemedeydi — bu yüzden önceki "dikte akışı" düzeltmeleri sonuç vermedi. Artık `_sameItems` ile içerik farkı varsa senkronlanır (yerel yazımda `_mutate` aynı karede setState ettiğinden döngü riski yok). Regresyon testi: items_editor_checklist_test "Dışarıdan eklenen öğe ANINDA görünür". (2) **KÖK NEDEN — canlı dikte hiç çalışmıyordu**: canlı döküm `LiveDictationSession` (Gemini Live WS) ile yapılıyordu ve BYOK anahtarı şarttı; anahtarsız (dahili AI) kullanıcı hep m4a fallback'e düşüyor, metni ancak bitişte tek seferde alıyordu. (3) **ÇÖZÜM — cihazın yerleşik tanıması**: `MainActivity.kt`'ye EventChannel `dev.kaimau.notlar/speech` (Android SpeechRecognizer) + `device_speech.dart` köprüsü; yeni Dart bağımlılığı YOK (ortamda Flutter SDK olmadığından lock güncellenemiyor). Kotlin biriktirir, Flutter'a her olayda o ana kadarki TAM metin gider; olaylar `{text}` veya `{level}` (rms — mikrofon tanıyıcıda olduğundan ayrıca AudioRecorder açılamaz). TUZAK: tanıyıcı her sessizlikte kendini kapatır, `onResults`'ta hâlâ dinlemedeyse yeniden başlatılır (~200 ms sağırlık; gerekirse Android 13+ EXTRA_SEGMENTED_SESSION). Manifest'e `<queries><action android:name="android.speech.RecognitionService"/>` şart — yoksa `isRecognitionAvailable()` servis kurulu olsa bile false döner. (4) **Sesli asistan artık METİN gönderiyor**: ses doğrudan modele gitmek yerine cihazda metne çevrilip `assistantVoiceNote(transcript:)` ile gidiyor. Kazanç: ses ≈32 token/sn yerine kısa metin; tanıma ücretsiz; **"oluşturdum diyor ama not yok" bugu öldü** — kök nedeni boş-not güvenlik ağının `liveTranscript` şartına bağlı olması, dökümün de yalnız anahtarlı kullanıcıda bulunmasıydı; artık döküm her zaman elde. Windows'ta yerleşik tanıma olmadığından eski ses yolu fallback kalır. `live_dictation_session.dart` kullanılmaz kaldı → SİLİNDİ (rule 4b). (5) Dikte sayfasına hold/tap modu (`voiceButtonModeProvider` yeniden kullanıldı, yeni ayar yok); duraklat/sürdür kaldırıldı. TUZAK: basılı-tut düğmesi idle ve listening evrelerinde AYNI ağaçta kalmalı (`_holdView`) — faz değişince düğme ağaçtan kalkarsa `onLongPressEnd` hiç gelmez ve kayıt bitmez. (6) İşaretlenen öğe artık işaretlilerin EN ÜSTÜne girer (en son işaretlenen üstte); `_toggle` sadeleşti — hem işaretlenen hem işareti kalkan öğe aynı konuma (`_checkedStart`) gider. (7) Checklist'te işaretliler ReorderableListView'ın DIŞINA, footer'a alındı (Keep'in "tamamlananlar" bloğu) — böylece "Yeni öğe" düğmesi doğal olarak işaretsizlerin altında/işaretlilerin üstünde kalır; işaretsizler `_items`'ın başında tutulduğundan reorder index'leri birebir örtüşür. Öğe işlemleri index yerine ID tabanlı. (8) Kartta uzun basış artık HER ZAMAN seçim; hızlı işlemler sağ üstteki üç nokta düğmesinde. (9) Bildirim konumu: FAB'lar `Scaffold.floatingActionButton`'dan Stack'e `Positioned` olarak alındı — Scaffold bir FAB tanıdığında yüzen snackbar'ı onun ÜSTÜne itiyordu; artık bildirim `margin` ile sağda 88px boşluk bırakıp düğmelerin SOLUNDA, ekranın dibinde durur.

- 2026-07-18: **Madde seçim modu + notla sohbet + bildirim/öneri düzeltmeleri (5 madde)**: (1) "Not silindi" bildiriminin süresi dolduğu hâlde kapanmaması: kapatma `ScaffoldMessenger`'ın kendi zamanlayıcısına bırakılmıştı, o da bazı koşullarda (ör. erişilebilirlik modu) hiç başlamıyor. Artık geri sayım göstergesinin `onEnd`'i `hideCurrentSnackBar()` çağırıyor — kapanma bize ait. (2) Kart ⋮ menüsüne yıldız + sabitle. (3) Öneriler/haftalık özet/brifing çıktıları `stripMarkdown`'dan geçiyor VE istemler markdown'ı açıkça yasaklıyor (iki katman; ham `**` sorunu buradaydı — `stripMarkdown` yalnız ai_sheet'te uygulanıyordu). İstemler sıkılaştırıldı: öneriler ≤12 kelime somut iş (genel tavsiye yasak), haftalık özet "ne birikti / bekleyenler / öneri". Öneriler + posta analizi üst bardan ana ⋮ menüsüne taşındı. (4) **Madde seçim modu**: ayrı TextField'lar arasında sistemin metin seçimi geçemediğinden toplu kopyalama/silme imkânsızdı (Keep'te de yok). Satırın SOL bölgesine (tutamak+kutucuk/numara) uzun basış seçim modunu açar, sonraki satırlara dokunuş ekler; `_selected` seti + üstte kopyala/sil çubuğu. Metin alanına uzun basış Android'in kendi metin seçimine bırakıldı — iki davranış çakışmıyor. Seçim modunda sürükleme kapalı. TUZAK: seçim çubuğu ReorderableListView header'ında olduğundan listeyle kayar (`ponytail:` notu düşüldü). (5) **Notla sohbet**: `chatAboutNote` (not metni + PDF/görsel ekleri inline) + `PdfChatScreen` → `DocChatScreen` olarak genelleştirildi (attachment VEYA note; tek ekran iki bağlam, yeni ekran yazılmadı). Ses ekleri bağlama katılmaz, okunamayan ek sessizce atlanır. BİLİNEN SINIR: her soruda ekler yeniden gönderiliyor (mevcut PDF sohbetiyle aynı kalıp) — büyük PDF'te uzun sohbet kotayı hızlı yakar.

- 2026-07-18: **Yerel Windows APK derlemesi kuruldu (GitHub Actions kotası bitince zorunlu oldu)**: Actions "recent account payments have failed / spending limit" ile job başlatmayı reddetti → doğrulama ve APK üretimi yerele taşındı. Kurulum: `C:\src\flutter` (3.44.6, CI ile aynı sürüm — lock uyumu için tag ile clone), Android SDK + Android Studio (Java `\jbr` içinde) zaten vardı. Derleme: `$env:ANDROID_HOME` set + `flutter build apk --release --target-platform android-arm64`. İmza: `android/key.properties` (gitignore'da; storeFile mutlak yol → `Desktop\notlar-keystore\notlar-release.jks`). ÜÇ TUZAK: (1) **SDK klasör adı**: proje `compileSdk = 37`, SDK Manager platformu `android-37.0` adıyla kuruyor, Gradle `android-37` arıyor → `platforms\android-37.0` klasörü `android-37` adıyla kopyalanarak çözüldü (CI imajında bu çıkmıyor). (2) **pdfrx symlink**: `pdfrx/android/CMakeLists.txt` `file(CREATE_LINK ... SYMBOLIC)` ile `.lib/latest` linkini kuruyor; Windows'ta link "başarıyla" oluşuyor ve hedefi de var AMA dizin bayrağı olmadığından enumerate EDİLEMİYOR → `libpdfium.so` bulunamıyor. **Geliştirici Modu bunu ÇÖZMÜYOR** (5 tur bu yanlış teşhisle kaybedildi); `COPY_ON_ERROR` de işe yaramaz çünkü CMake hata döndürmüyor. Çözüm: pub cache'deki CMakeLists'te link yerine `file(REMOVE_RECURSE)+MAKE_DIRECTORY+COPY`. Paket sürümü değişince/`pub cache repair` sonrası yeniden uygulanmalı. Ara düzeltme denerken `latest`e elle dolu klasör koymak da yeni hata verir (`file(REMOVE)` dosya siler, klasör silmez). (3) `2>&1` ile native exe çağırmak PowerShell'de sahte hata üretir — flutter komutlarında kullanma. Yerel doğrulama artık mümkün: `flutter analyze` + `flutter test` (30 test) CI'sız çalışıyor.

- 2026-07-19: **Sesli sistem "algılamıyor" bugu — cihaz logu ile KESİN teşhis**: Dikte ve sesli asistan sesi alıyor, canlı metin akıyor ama "Bitir"de metin kayboluyor / "konuşma algılanmadı" deniyordu. `adb logcat` ile ölçüldü (tahminle iki tur boşa gitti — önce `EXTRA_CALLING_PACKAGE` eksikliği, sonra `firstOrNull` sanıldı, ikisi de YANLIŞTI). GERÇEK KÖK NEDEN: `onPartialResults` dolu metin veriyor (`'bugün markete gidip ekmek almak istiyorum'`) ama `stopListening()` sonrası `onResults` **null** dönüyor (Google SODA'da olağan davranış). Kotlin köprüsü `accumulated`'ı YALNIZ final sonuçtan dolduruyordu → boş kalıyor → Flutter'a boş string gidiyor → o ana kadar yazılmış metnin ÜZERİNE yazıp siliyor. İKİNCİ SIZINTI: tanıyıcı sessizlikte `NO_MATCH` ile kapanıp yeniden başlarken ara sonuç hiçbir yere yazılmadan gidiyordu (uzun konuşmada cümle kayıpları). Düzeltme 3 katman: (1) `lastPartial` alanı — her dolu ara sonuç saklanır; (2) `onResults` null/boşsa `lastPartial` kullanılır, `onError` benign restart'ında da `accumulated`'a eklenir; (3) Dart tarafında `DeviceSpeech.listen` boş metni `null`'a çevirir — boş olay dolu metni asla ezemez. TUZAK: SpeechRecognizer'da ilk `onPartialResults` boş gelir (ısınma), bu normaldir, hata sanılmamalı. DERS: cihaz davranışını koddan tahmin etmek yerine `adb logcat` ile ölçmek üç turu bir tura indirirdi; telefon USB'de + hata ayıklama açıkken teşhis dakikalar sürüyor.
- 2026-07-19: **Editörde dikte doğrudan çalışıyor**: mikrofon düğmesi artık alt sayfa açmıyor; `DeviceSpeech` akışına doğrudan abone olup metni gövdeye anlık yazıyor, ikinci dokunuşta durduruyor (52x52, dinlerken kırmızı stop ikonu). Liste tiplerinde döküm bitişte tek öğe olarak eklenir. Yerleşik tanıma yoksa (Windows) eski `showDictationSheet` fallback korunur. Sesli asistan paneli FAB'ların üstünden SOLUNA alındı (`Positioned(left:8, right:88, bottom:16)`) — bildirimle aynı hizada. Dashboard ⋮ menüsüne `maxHeight = ekran*0.55` sınırı: menü sistem gezinme çubuğunun altında kalıyordu, artık kaydırılıyor.
- 2026-07-19: **Firebase AI "hata veriyor" = billing (kod değil) + premium'a kota**: (1) "Dahili AI çalışmıyor" bir kod hatası DEĞİLDİ — hata metni `Your prepayment credits are depleted` = projenin (`notlar-kaimau`) Gemini API ön ödemeli kredisi bitmiş. Dahili AI (Firebase AI Logic) projenin faturasından ödendiği için kredi bitince TÜM kullanıcılar hata alır; çözüm kodda değil, AI Studio'da kredi eklemek. `firebase_ai_client._mapError`'a billing dalı (`prepay/billing/credit/depleted/resource_exhausted`) eklendi → ham İngilizce yerine Türkçe "kendi anahtarını gir" mesajı. (2) Bunun doğal sonucu: premium artık "sınırsız" DEĞİL — `premiumDailyAiCalls = 100` (free 5 kalır); `AiGate.consume` premium'da erken-return yerine 100 tavanına göre sayıyor. BYOK (kendi anahtarı) muaf — GeminiService anahtar varken bu kapıya gelmez. Kota cihaz-yerel (SharedPreferences); sunucu doğrulaması Play sürümünde eklenecek. `aiBuiltInPremium` l10n'u parametreli yapıldı (premium de kalan hakkı görüyor). (3) `.firebaserc` eklendi (default: `notlar-kaimau`) — CLI kurulu + login (hekimasistanitr@gmail.com) vardı ama proje bağı yoktu → `firebase deploy` artık çalışıyor.
- 2026-07-19: **Ek boyutu premium'a göre (10/50 MB) + dashboard ⋮ compact**: (1) Tek 25 MB sınırı kalktı: `maxFreeAttachmentBytes = 10MB`, `maxPremiumAttachmentBytes = 50MB`. `attachmentRepositoryProvider` premium'u okuyup repository'ye `maxBytes` geçiyor (repository artık sınırı kendi taşıyor, `AppConstants.maxAttachmentBytes` silindi). `readBytes`'taki indirme tavanı premium max'ta sabit — premium'un yüklediği dosya, kullanıcı sonradan premium olmasa da inebilmeli. KARAR: `storage.rules` tek tavan (50 MB) tutuyor, ücretsiz 10 MB sınırı yalnız uygulama tarafında — katı sunucu zorlaması her yüklemede `firestore.get(premiumUntil)` okuması demekti, kişisel not uygulaması için gereksiz maliyet. (2) `attachmentTooLarge` l10n'u parametreli (`{limit}` MB) — mesaj premium'a göre 10/50 diyor. (3) Dashboard ⋮ menüsü: `_selMenuItem` → `_menuItem` olarak genelleşti + compact (`visualDensity.compact`, `horizontalTitleGap: 8`, `minLeadingWidth: 0`, ikon 20px); ana menüdeki 9 inline `ListTile` bu helper'a indirgendi (~60 satır tekrar gitti) ve `minWidth: 200` kaldırıldı — menü artık içeriğe göre daralıyor.
- 2026-07-19: **TUZAK — premium'u kod/CLI ile veremezsin**: `premiumUntil` istemciden yazılamıyor (firestore.rules `create`/`update` içinde `affectedKeys().hasAny(['premiumUntil'])` engeli — bu DOĞRU, kullanıcı kendini premium yapamasın). Firebase CLI'de Firestore doküman YAZMA komutu yok (`firestore:delete`/`indexes` var, set yok), `firebase auth:export` ile uid çekmek de güvenlik sınıflandırıcısınca engellendi (tüm kullanıcıların e-posta/hash'ini döktüğü için makul). SONUÇ: bir hesabı premium yapmak Console işi (Authentication → uid → Firestore `users/{uid}` → `premiumUntil` timestamp) ya da ileride Play Billing Cloud Function işi. Ajan bunu tek başına yapamaz, talimat verir.

- 2026-07-21: **Notu sesli oku + madde seçimi keşfedilebilir + AI sayfası bölümlendi** (kullanıcının 3 maddelik isteği): (1) **Notu sesli oku**: yeni ekran YAZILMADI — `ListenScreen` zaten `(title, loadText)` alacak şekilde genelleştirilmişti (PDF/Word/txt ortak kullanıyor), nota bağlamak tek satır oldu. Giriş iki yerde: kart ⋮/uzun-basış sayfası ve editör ⋮. **`toPlainText()` DEĞİL `toContentText()` verilir** — ilki başlığı ve `- [x]`/numara işaretlerini metne katıyor, TTS onları harfiyen okuyordu ("köşeli parantez x süt"). Kilitli notta kart yolunda biyometri şartı var, editör yolunda YOK (editör açılırken zaten doğruluyor; `_share()` ile aynı desen). Model çağrısı yok, cihaz TTS'i. (2) **Madde seçimi bir özellik eksiği DEĞİLDİ, keşfedilebilirlik sorunuydu**: toplu kopyala/sil 2026-07-18'den beri vardı ama yalnız satırın SOL kenarına (tutamak+kutucuk, ~50px) uzun basışla açılıyordu ve hiçbir yerde yazmıyordu — kullanıcı "yok" sandı. Çözüm: "Yeni öğe" satırının sağına **"Seç" düğmesi**. `_selectionMode` eskiden `_selected.isNotEmpty` idi; düğmeyle açılan mod henüz hiçbir madde seçilmemişken de açık kalmalı → ayrı `_selectMode` bayrağı + `_exitSelection()` şart oldu (kopyala/sil/iptal üçü de onu çağırır). Uzun basış yolu korundu. (3) **ai_sheet bölümlendi**: düz listeydi ve **her ek için dosya adını 3 kez tekrarlayan 3 ayrı satır** açıyordu (2 PDF = 6 uzun satır). Artık "Bu not" / "Ekler" başlıkları + her PDF tek `ExpansionTile` (ad bir kez, içinde Özetle/Sesli dinle/Soru sor); görsel ve seste tek işlem olduğundan açılır satır yerine alt yazı. Adı gövdeye gömen 5 parametrik l10n anahtarı (`aiSummarizePdf`, `aiAskPdf`, `aiExtractImageText`, `aiTranscribeAudio`, `listenToPdf`) kullanılmaz kaldı → SİLİNDİ (rule 4b), yerlerine adsız kısa anahtarlar. **TUZAK (test yazarken çıktı)**: seçim modunda satır metnine dokunmak `AbsorbPointer` yüzünden TextField'a DÜŞMEZ, üstteki GestureDetector yakalar — `tester.tap` bunu "ıskaladı" sanıp uyarı basar; beklenen davranış olduğundan `warnIfMissed: false` gerekir. Doğrulama: `flutter analyze` temiz + 72/72 test (yeni: "Seç düğmesi seçim modunu açar, seçilen madde kopyalanır").

- 2026-07-21: **WEB SÜRÜMÜ AÇILDI (Faz 1) — AHEK Plus entegrasyonunun ilk adımı.** Hedef: Notlar'ı `ahekplus` sitesine sekme olarak gömmek. **DIŞ SİSTEM ŞEMASI (araştırıldı, `kaimau1/hekim-asistani` deposu):** AHEK Plus web = sade JavaScript, ÇOK SAYFALI (SPA değil, menü `<a href="*.html">`), Cloudflare'de; Firebase projesi **`hekim-asistani`** (Auth: e-posta/parola + Google + custom token, Firestore kalıcı önbellekli, Functions us-central1). Ayrıca `hekim-plus-mobil/` = React Native/Expo, aynı projeye bağlı, içinde `react-native-webview` + `portal/`. Notlar ise **`notlar-kaimau`** projesinde → **entegrasyonun asıl işi kod değil, İKİ AYRI FIREBASE PROJESİ.** KARAR: Notlar `hekim-asistani`'ye taşınıp site ile AYNI ORIGIN'den servis edilirse kimlik sorunu çözülmez, ORTADAN KALKAR (Firebase Auth oturumu origin başına tutulur → kullanıcı zaten girişli gelir; custom token köprüsü gerekmez). Kullanıcı tek kişi olduğundan taşıma ucuz. **Faz 2-3 (proje birleştirme + siteye gömme) BAŞLAMADI** — canlı site yoğun kullanımda, kullanıcı riske girmek istemedi. (1) **`flutter build web` İLK DENEMEDE DERLENDİ** — "30 dosya `dart:io` kullanıyor, web'de derlenmez" tahminim YANLIŞTI. DERS: web uyumluluğunu dosya sayarak tahmin etme, derleyiciye sor. Kesin uyumluluk listesi `.dart_tool/flutter_build/*/web_plugin_registrant.dart` dosyasından okunur (web karşılığı OLAN eklentiler orada listelenir). Ölçüm: web'de VAR sanılmayan `record`, `flutter_tts`, `flutter_local_notifications` aslında VAR; YOK olanlar `path_provider`, `local_auth`, `home_widget`, `receive_sharing_intent`, `google_mlkit_translation`, `pasteboard`. `pdfrx` web'i destekliyor (`pdfium.wasm` build'e giriyor). (2) **Firebase web yapılandırması tek satırdı**: konsolda "Notlar Windows" adıyla duran uygulama ZATEN WEB platformunda kayıtlı (`appId ...:web:...`) ve config'i (authDomain dahil) tarayıcı için yeterli → `firebase_options.dart`'a `static const web = windows;` + `kIsWeb` dalı (Platform'DAN ÖNCE gelmeli, `dart:io` web'de yok). Yeni kayıt/anahtar gerekmedi. (3) **BÜYÜK DESEN — üç ayrı bug, tek kök: "Android affediyor, tarayıcı affetmiyor".** Üçü de kodda zaten duran kusurlardı, web sadece görünür yaptı: (a) `google_sign_in` 7.x web'de `authenticate()` DESTEKLEMİYOR (Google Identity Services kendi düğmesinin tıklanmasını şart koşuyor) → giriş düğmesi sessizce hiçbir şey yapmıyordu, hata bile basmıyordu. Çözüm `web_google_auth.dart`: eklenti yerine `_auth.signInWithPopup(GoogleAuthProvider())` — ek yapılandırma (client_id meta etiketi, düğme render'ı) istemiyor; AHEK Plus sitesi de aynı yöntemi kullanıyor. (b) Ek ekleme SESSİZ DONMA: `path_provider` web'de yok + `note_editor_screen`'deki `catch` YALNIZ `FileTooLargeException` yakalıyordu → başka her hata `await`'i tamamlanmadan bırakıyor, ekran donuyor, mesaj çıkmıyordu. Çözüm iki katmanlı: paylaşılan `AttachmentRepository._store()` (cihazda yerel kopya = çevrimdışı-önce korundu, web'de doğrudan `putData` ile Storage) + üç `catch`'in genişletilmesi. **Bu ikinci düzeltme ANDROID'DE DE gizli bir hatayı kapattı** (disk dolu / izin reddi aynı sessiz donmayı veriyordu). `prepareAudio` bilerek `_store` dışında (kaynak zaten diskte, `copy` baytları belleğe almaktan iyi; web'de `record` blob adresi döndürdüğü için kayıt düğmesi tarayıcıda gizlendi). (c) **`ByteData.buffer.asUint8List()` TUZAĞI**: offset/uzunluk verilmeden çağrılınca TÜM arabelleği döndürür; ByteData bir DİLİM ise PNG'ye çöp bayt eklenir. Android'de `toByteData` tam arabellek veriyor, CanvasKit'te dilim veriyor → tarayıcı "EncodingError: The source image cannot be decoded" diyordu. Doğrusu `asUint8List(data.offsetInBytes, data.lengthInBytes)`. Kardeş tarama: `pcm_wav.dart`'taki iki kullanım GÜVENLİ (ByteData sıfırdan oluşturuluyor), dokunulmadı. (4) **TUZAK — `RepaintBoundary.toImage()` CanvasKit'te ekranda görüneni vermiyor**: (c) düzeltildikten sonra çizim bu kez BEYAZ KUTU geldi — zemin yakalanıyor, çizgiler yakalanmıyordu. Zamanlamayla kovalamak yerine yakalama deterministik yapıldı: çizgiler AYNI `DrawingPainter` ile yeni bir `PictureRecorder` tuvaline yeniden çiziliyor, ekran katmanına hiç bakılmıyor. Painter test edilebilsin diye `_Stroke`/`_DrawingPainter` public yapıldı; `test/drawing_capture_test.dart` üretilen görselde beyaz olmayan piksel sayıyor (tek noktalı dokunuş ayrı `drawCircle` dalı olduğundan ayrıca test edilir). (5) **TUZAK — `ShellRoute` builder'ına gelen `state.matchedLocation` ALT rotanın yolu DEĞİL**, kabuk rotasının eşleşmesidir. `matchedLocation.startsWith('/note/')` hiç tutmuyordu → geniş ekranda not açılıyor ama sağ panel yer tutucuda kalıyordu ("not seçince açılmıyor"). Kırılgan metin kontrolü SİLİNDİ: sağ panel her zaman `child`'ı çizer, yer tutucuyu `/` rotasının kendisi üretir (geniş ekranda liste zaten sol panelde). (6) **İki sütunlu masaüstü düzeni** (`app/split_shell.dart`, kullanıcı ortalanmış tek sütun yerine bunu seçti): 900 px üstünde solda liste + sürüklenebilir ayraç + sağda not; **900 px altında `child` tek başına döner, yani telefon davranışı BİREBİR korunur** — düzenin tüm riski geniş ekrana hapsedildi. `ShellRoute` seçildi çünkü düz `Row` ile her not değişiminde sol panel yeniden kurulup liste başa sarıyordu. URL'ler (`/`, `/note/:id`) değişmedi → derin bağlantı ve tarayıcı geri tuşu korundu. (7) **TUZAK — sürüklenebilir ayraçta DELTA kullanma**: `onHorizontalDragUpdate`'te `d.delta.dx`'i build sırasında yakalanmış genişliğe eklemek yanlış; fare tek karede birden çok olay üretiyor ve hepsi aynı bayat değere eklendiğinden yalnız sonuncusu işe yarıyor → panel fareden YAVAŞ kalıyor. Doğrusu `d.globalPosition.dx` (mutlak konum), kare zamanlamasından bağımsız. Ayrıca genişliği her sürükleme karesinde SharedPreferences'a yazmak diske I/O bindiriyordu — kalıcı kayıt yalnız `onDragEnd`'de. (8) **TUZAK — web'i DEBUG derlemesiyle değerlendirme**: "çok geç yükleniyor" şikayetinin sebebi debug paketiydi; `flutter run -d web-server --release` ile düzeldi. Ayrıca debug paketleri agresif önbelleklenir, düzeltmeler kullanıcıya ulaşmayıp "aynı sorun devam ediyor" sanılabilir → test ederken Ctrl+Shift+R. **AHEK Plus'a gömerken DAİMA release.** (9) **KEEP KARŞILAŞTIRMASI (kullanıcı sordu)**: Keep'te sürüklenebilir ayraç ve iki içerik paneli YOK — solda sabit genişlikli gezinme rayı, notlar ızgarada, tıklayınca ORTADA MODAL açılıyor; yani panel genişliği sorunu tasarımla ortadan kaldırılmış. Keep hızlı çünkü Flutter değil, el yazımı web uygulaması (Flutter web CanvasKit ilk yükleme birkaç MB — teknoloji seçiminin sabit bedeli, optimizasyonla kapanmaz). Izgara+modal'a geçmek `split_shell.dart`'ı silmek demek; kullanıcı şimdilik iki sütunda kalmayı seçti ("şuanki stil güzel"). (10) **YAPILMADI**: dashboard'da arama barı `pinned: true` yapıldı ama FİLTRE ÇİPLERİ hâlâ kaydırılıyor — yüksekliği değişken olduğundan (kapalı 40 px, açıkken klasör+etiket blokları) sabit yükseklik isteyen `SliverPersistentHeader` uymuyor; düzgün çözüm başlığı `CustomScrollView`'un tamamen DIŞINA (Column'a) taşımak, bu da 944 satırlık dosyada yapısal değişiklik. Bonus: başlık şu an `AnimatedSwitcher` içinde olduğundan filtre değişiminde arama barı da kayıyor; dışarı taşımak onu da düzeltir. (11) FAB hizası: mikrofon 84 px sabit kutuda, "+" 56 px FAB; sütun `CrossAxisAlignment.end` olduğundan merkezleri 14 px kayıyordu → `center` yapıldı.

- 2026-07-22: **"Oldu seviyesi" cila paketi (20 madde, kullanıcı tespit listesinin tamamını onayladı)**: (1) AYARLAR yeniden örgütlendi: model seçiciler + API anahtarı `_AdvancedAiSection` (ExpansionTile "Gelişmiş") altına katlandı; model adları `_friendlyModel` ile okunur ("3.5 Flash — hızlı"); "Sesli Not Asistanı" grubu üçe ayrıldı (asistan modu / Sesli okuma / Çeviri); brifing ayarına "Brifingi aç" çipi; Yedek ayrı grup oldu + **JSON geri yükleme** eklendi (`_RestoreButton`, file_selector; her kayıt YENİ not — id çakışması yok, ekler atlanır); dışa aktarma web'de `XFile.fromData` (path_provider'sız). (2) **AI HUB** (`/ai`, ai_hub_screen.dart): sohbet/çevirmen/öneriler/e-posta/brifing/belge-oku tek ekranda alt yazılı; üst bardaki çeviri+sohbet ikonları ve ⋮'deki 4 AI maddesi kaldırıldı, yerine tek auto_awesome düğmesi. (3) **Dashboard yapısal**: arama barı + çip satırı `CustomScrollView`'dan ÇIKARILDI (Column başlık + Expanded liste) — SliverAppBar'lar düz AppBar oldu, çipler artık kaydırılmıyor ve filtre animasyonu yalnız listeyi oynatıyor (HAFIZA 07-21 #10'daki "yapılmadı" borcu kapandı). (4) **"+" tek dokunuş = metin notu**, uzun basış tip menüsü (Keep davranışı; `_toggle` silindi). (5) **Dikte listede canlı**: `_syncDictatedItems` — her duraklama (satır) anında ayrı madde; oturumun eklediği id'ler takip edilir, elle yazılan öğelere dokunulmaz; bitişteki tek-öğe ekleme kaldırıldı. (6) **Otomatik başlık geri geldi** (`autoTitleProvider` 'auto_title', varsayılan AÇIK; dispose'da `_autoTitleInBackground`) + "Başlık öner" çipi durur; çip etiketi "Etiket · Başlık · Alarm" oldu. (7) ai_sheet: "Geliştir→Yazım düzeltmesi" SİLİNDİ (üstteki "Notu düzelt" ile mükerrerdi; improveFix l10n anahtarı da silindi), Özetle/Analiz'e ayırt edici alt yazı, **çeviri artık `toContentText` + improvement:true** (işaretler çevrilmiyor, "Notu değiştir" sunuluyor), hata görünümüne "Tekrar dene" (`_retryAction` — _run kendini saklar). (8) `_replaceText` işaret koruması: sayı/sıra değişse de normalize metin eşlemesiyle (`oldChecked` map) checked devralınır. (9) Kart menüsüne "Klasöre taşı" (showFolderPickSheet), editör ⋮'e "PDF dışa aktar". (10) Sesli asistan: boşta düğmede "Asistan" rozeti (dikteyle karışmasın); `start/finish` `genericErrorText` aldı — ham `e.toString()` kullanıcıya çıkmıyor (StateError mesajları Türkçe geçer). Doğrulama: `flutter analyze` temiz + 75/75 test. TUZAK: Column içinde AppBar, SafeArea altında çift status-bar boşluğu YAPMAZ (SafeArea, MediaQuery padding'i sıfırlar).

- 2026-07-22: **4 maddelik ince ayar (kullanıcı isteği, telefona kuruldu)**: (1) **"Notu düzelt" 3 seviye**: ai_sheet üstteki tek düğme `_pickFixLevel` ile SimpleDialog açıyor — Basit (yalnız imla/yazım), Dengeli (cümle yapısı da), Detaylı (baştan aşağı yeniden yaz); üçü de `toContentText` + improvement:true ("Notu değiştir" görünür). Eski tek-istemli `_fixNote` kaldırıldı. (2) **Dashboard toplu seçim + sıralama tek jestte**: `_ReorderableNoteCell` StatelessWidget→StatefulWidget; `Listener.onPointerDown` ilk konumu tutar, `LongPressDraggable.onDraggableCanceled`'da bırakma konumu başlangıca <24px ise SEÇİM (`onSelect`), kaydıysa (boş alana bırakma) hiçbir şey; başka karta bırakma zaten `DragTarget.onAccept`→reorder. Filtre/arama görünümünde (reorder kapalı) kart `GestureDetector.onLongPress`→seçim. Böylece uzun-basış-bırak=çoklu seçim, uzun-basış-sürükle=sıralama (Keep). TUZAK: Listener olayı yutmaz, InkWell tap/açma çalışmaya devam eder. (3) Editör ⋮ menüsüne "Ayarlar" (`context.push('/settings')`). (4) **Etiket geçmişi**: `_addTag` diyaloğu artık `allTagsProvider`'dan bu notta OLMAYAN önceki etiketleri ActionChip olarak gösterir (maxHeight 180 kaydırmalı Wrap); çipe dokunmak diyaloğu kapatıp etiketi ekler, metin kutusu+OK yeni etiket ekler. `_cleanTag`/`_applyTag` yardımcılara ayrıldı. Doğrulama: analyze temiz + 75/75 test, imzalı APK sürüm 111.

- 2026-07-22: **Checklist AI düzenlemesinde işaret koruma + "işaretlileri dışla" ayarı** (kullanıcı: madde modunda düzeltince işaretler kalkıyor): KÖK NEDEN — `toContentText()` checklist'i işaretsiz düz satırlara indiriyor (marker sızmasın diye, bilinçli), AI yeniden yazınca hangi satırın işaretli olduğu geri kurtarılamıyordu; `_replaceText`'teki `oldChecked` metin-eşleme en iyi çaba ama yazım düzeltilince tutmuyor. ÇÖZÜM iki katman: (1) **Ayar `aiSkipCheckedProvider`** ('ai_skip_checked', varsayılan AÇIK) — Ayarlar>Yapay Zeka'da `_AiSkipCheckedSwitch`. Açıkken işaretli maddeler AI'a HİÇ gönderilmez, yerinde korunur. (2) Akış: `Note.toContentText({bool skipChecked})` işaretlileri atlar; ai_sheet `_skipCheckedForNote` (ayar açık + checklist + en az bir işaretli VE bir işaretsiz) → fix/improve(tip değişmezse)/translate `skipChecked` ile içerik gönderir, `keepChecked`'i `_run`→`ReplaceTextCallback`(typedef'e `bool keepChecked` eklendi)→`_replaceText`/`_createNoteFromText`'e taşır. `_replaceText` keepChecked+checklist'te: AI sonucu = yeni işaretsiz maddeler, mevcut işaretliler AYNEN sona eklenir ("işaretliler altta" düzeni). KARAR: ayar KAPALIYKEN eski `oldChecked` en-iyi-çaba metin eşlemesi kalır (kullanıcı tümünü düzenlemeyi seçmiş). Tip dönüştüren geliştirmelerde (bullets/numbered) skip uygulanmaz (tüm içerik yeniden şekillenir). Test: note_test'e toContentText skipChecked 2 testi. Doğrulama: analyze temiz + 77/77 test, APK sürüm 112.

- 2026-07-22: **Sıralı/liste düzeltmede madde çökmesi + "notu değiştir" geri alma** (kullanıcı): (1) KÖK NEDEN — `_pickFixLevel`/`_pickImprovement` promptları liste yapısını korumuyordu; "dengeli/detaylı" düzeltme sıralı listenin 5 maddesini tek paragrafa/tek maddeye birleştiriyordu ("gerekirse paragraflara ayır" ibaresi de bunu körüklüyordu). ÇÖZÜM: ai_sheet `_listStructureConstraint` getter (not tipi text değilse) — prompt sonuna "Bu bir listedir, çıktı girdiyle AYNI sayıda satır içermeli, satırları birleştirme/paragraf yapma, madde ekleme-çıkarma" eklenir; fix üç seviyeye ve improve'un tip-korumalı seçeneklerine (Formal/Kısalt) uygulanır, tip dönüştürene (bullets/numbered) uygulanmaz. (2) **Geri alma**: `_replaceText` artık başta `before = note` anlık görüntüsü alıp mutate sonrası `_offerReplaceUndo(before)` çağırıyor — `showUndoSnackBar` "Not güncellendi / Geri al"; geri al başlık+gövde controller'larını ve `_note`'u eskiye döndürüp repoya yazıyor. `_createNoteFromText`'e undo EKLENMEDİ (orijinal not değişmiyor, yeni not açılıyor). Doğrulama: analyze temiz + 77/77 test, APK sürüm 113.

## Bilinen Riskler / Tuzaklar

- **Keystore repo dışında** (`Desktop\notlar-keystore\`): kaybolursa aynı imzayla güncelleme yayınlanamaz — ayrı yere yedekle.
- Firestore/Storage kural değişikliği deploy edilmeden canlıya yansımaz (`firebase deploy`).

- 2026-07-18: **Otomatik başlık dahili AI'da çalışmıyordu — kök neden model tercihi**: `generateTitle` tek başına `preferModel: fastGeminiModel` ('gemini-3.1-flash-lite') geçen çağrı. Anahtarsız yolda `FirebaseAiClient._withModel` tercih modelini ilk sıraya zorluyor ama o model arka uçta yoksa dönen hata `_shouldTryNext` kalıplarına (not found/quota/…) uymazsa sıradaki modele DÜŞMEDEN fırlatıyordu → diğer AI özellikleri (varsayılan model) çalışırken yalnız otomatik başlık kırık. Düzeltme: `_withModel`'de tercih (prefer) yalnız hız ipucu olduğundan ilk denemenin (i==0, prefer!=null) HER hatası skippable → standart modele düşülür. REST/BYOK zaten güvenliydi (prefer canlı listede yoksa hiç denenmiyor). Özellik kaybı kontrolü: #5→#10 zinciri sağlam, tüm dosyalar yerinde (her PR merge sonrası dal origin/main'den yeniden başlatıldı, kayıp yok).

- 2026-07-18: **Sesli Not Asistanı dashboard'a gömüldü**: /voice ekranına gitmek yerine ana sayfada çalışır. `VoiceAssistantController` (Notifier, notes/presentation/voice_assistant.dart): idle→recording→processing→done/error; büyük interaktif düğme (`VoiceAssistantButton`, FAB sütununda, ses seviyesiyle nefes alır + süre içinde) ve alt durum paneli (`VoiceAssistantPanel`, `bottomNavigationBar` yuvasında; kayıt+canlı döküm/işleme/sonuç+"Notu aç"/hata). İki ses yolu: anahtar VARSA 16k PCM startStream → aynı akış hem LiveDictationSession'a (canlı döküm panelde) hem BytesBuilder'a → bitişte `pcmToWav` ile audio/wav asistana (tek kayıt iki iş); anahtar YOKSA m4a dosyası (canlı döküm yok). Asistan düşerse fallback: canlı döküm varsa AI'sız direkt not, yoksa transcribeAudio. Ayarlar>Sesli Not Asistanı: `VoiceButtonMode` (hold varsayılan / tap); hold=onLongPressStart/End, düz dokunuş ipucu snack'i; tap=dokun-başlat/dokun-bitir. <1 sn kayıt sessizce iptal + "çok kısa" snack (yanlışlıkla basma). /voice rotası widget+"Hey Google" derin bağlantısı için DURUYOR. TUZAK: controller'a BuildContext/l10n taşıma — metinleri parametre olarak çağrandan geçir (start/finish imzaları).

- 2026-07-18: **Ücretsiz kullanıcıda AI içeriği elle + günde 1 kez**: E-posta taraması/öneriler/haftalık özet/brifing ücretsiz kullanıcıda otomatik çalışıp günlük 5 hakkı boşa yakıyordu. `aiUnlimitedProvider` (BYOK anahtar VEYA premium) eklendi; `DailyCacheNotifier.build` sınırsız kullanıcıda yeni günde otomatik üretir, ücretsizde OTOMATİK ÜRETMEZ — `emptyValue` döndürür ve ekran `AiGeneratePrompt` ("Oluştur"/"E-postaları tara") gösterir. `refresh()` ücretsizde `generatedToday` ise no-op (ekran `aiGeneratedTodayInfo` snackbar'ı basar) = günde 1 kez. Sınırsızda eski davranış (otomatik + istediğinde Yenile). TUZAK: iki farklı notifier tipini ternary ile seçince `.notifier` LUB'ı `AsyncNotifier<String>`e düşüp `generatedToday`/`refresh`i kaybedebilir → değişkeni açıkça `DailyCacheNotifier<String>` tiple. Brifing ücretsizde compute içinde `importantEmailsProvider.future` okur ama o da ücretsizde üretmediğinden ekstra kota harcanmaz (yalnız o gün zaten taranmışsa e-posta katılır).

- 2026-07-18: **Editör klavye/dokunma + AI çıktılarının günlük kalıcı önbelleği**: (1) Hesap makinesi (ve genel alt sayfa) kapanınca klavye kendiliğinden geri açılıyordu → `_openCalculator` başında `FocusScope.unfocus()` (odaklı alan kalırsa Flutter modal kapanışında klavyeyi yeniden gösterir). (2) Metin notu gövdesi yalnız üst ~10 satırda dokunulabiliyordu; alt boşluğa dokunmak yazmaya başlatmıyordu → `LayoutBuilder` + `GestureDetector(opaque)` + `ConstrainedBox(minHeight: viewport)` + `Column(min)`; artık gövde en az bir ekran boyu ve tüm alan `_bodyFocus.requestFocus()`'a gider. (3) **AI çıktıları artık günlük kalıcı**: `DailyCacheNotifier<T>` tabanı (ai/data/daily_cache.dart) sonucu+tarihi SharedPreferences'a yazar; `build()` aynı güne ait önbelleği yeniden ÜRETMEDEN döndürür, gün değişince otomatik tazeler, `refresh()` (Yenile) zorlar. importantEmails / suggestions / weeklySummary / briefing hepsi `FutureProvider.autoDispose`+keepAlive-timer'dan bu tabana taşındı. autoDispose OLMADIĞI için başka sekmeye geçilse de tarama arka planda sürer; uygulama yeniden açılışında son sonuç diskten okunur ("hep görünsün, açıp kapatınca gitmesin"). Ekranlardaki Yenile/Retry `ref.invalidate` yerine `notifier.refresh()`. TUZAK: DailyCacheNotifier.compute içinde `ref.read` (watch değil) — not değişiminde AI'ı yeniden tetiklememek için; brifing e-postaları da `ref.read(importantEmailsProvider.future)` + 20 sn timeout ile alır.

- 2026-07-18: **Editör 5'lisi: Temizle + mikrofon konumu + anlık dikte + Kağıt teması + hesap makinesi**: (1) Editör ⋮ menüsüne "Temizle" (onaylı; gövde+liste öğelerini siler, başlık/etiket/ek kalır). (2) Alt bar yeniden: mikrofon sağa `IconButton.filledTonal` (başparmak bölgesi, AI'ın yanı); ses kaydı EKİ ataş menüsüne taşındı — mikrofon artık kayıt değil dikte açar. (3) Anlık dikte: `LiveDictationSession` (ai/data) Live Translate modelini hedef dil `tr` + `echoTargetLanguage:false` ile kullanır → model sessiz kalır, yalnız `inputAudioTranscription` akar = saf canlı transkripsiyon, yeni bağımlılık yok. Anahtarsızda fallback: m4a kaydet → `transcribeAudio` (dahili AI ile de çalışır). Canlı hata düşerse biriken metin KORUNUR ("Bitir ve ekle" çalışmaya devam eder). (4) "Kağıt" teması: `AppThemeChoice` enum'ı (system/light/dark/paper, aynı `theme_mode` prefs anahtarı — geriye uyumlu); `AppTheme.paper()` = açık tema + saman kağıdı yüzeyler (surface 0xFFF5EDD8) + sepya tohum. `themeModeProvider` → `themeChoiceProvider` oldu. (5) Dahili hesap makinesi: `core/utils/calc.dart` özyinelemeli inişli ayrıştırıcı (× ÷ − virgül/nokta ondalık, %10 ve 10% ikisi de yüzde, mod yok) + `calculator_sheet.dart`; sonuç metin notunda İMLECE, listede yeni öğe olarak girer. TUZAK: `_appendText` satır başı rakamları madde numarası sanıp kırpar (`^[-•*\d.]+`) — sayıyla başlayan metni liste notuna eklerken `_appendText` KULLANMA, öğeyi doğrudan ekle. Flutter SDK bu ortamda yoktu → l10n generated dosyaları elle senkronlandı (arb + abstract + tr impl üçlüsü birlikte).

- 2026-07-17: **AI sonuç sayfası düzeltmeleri**: (1) "Nota ekle" çalışmıyordu — kök neden sonuç butonları `Row(end)` içinde taşıyordu (RenderFlex overflow), en sağdaki buton ekran dışında kalıp dokunulamıyordu → `Wrap` (dar ekranda alt satıra sarılır). (2) AI çıktısındaki markdown (`**`, `*`, `#`, `` ` ``) notlara ham giriyordu → `core/utils/markdown.dart` `stripMarkdown`; `_run`'da tek noktada temizlenir (gösterim+kopya+ekle+değiştir hepsi temiz metin), ayrıca note_editor `_replaceText`/`_appendText` güvenlik ağı olarak da temizler. (3) Hızlı "Notu düzelt (yazım + düzen)" — AI sayfasının en üstünde belirgin buton; yazım/imla/noktalama düzeltir, çok hafif düzenler, içerik+madde sayısını korur, düz metin ister.

- 2026-07-18: **Widget paketi + yıldız + tarih + model varsayılanı + güvenlik**: (1) Varsayılan Gemini modeli artık `gemini-3.1-flash-lite` (geminiModelPreference ilk sıra; hem BYOK hem dahili AI aynı listeyi kullanır); canlı çeviri `gemini-3.5-live-translate-preview`'da kaldı. (2) AI "Notu geliştir" menüsüne "Sıralı (numaralı) listeye çevir" eklendi. (3) `Note.starred` (yıldız/favori): editör AppBar'ında yıldız, kartta rozet, masaüstü sağ-tık menüsünde, filtre çubuğunda "Yıldızlı" (NoteFilter.starred). (4) Son güncelleme: kart sağ altında akıllı kısa tarih (`formatNoteDate`: bugünse saat, aynı yılsa "5 Tem"), editörde başlığın altında "Düzenlendi: …". (5) YENİ WIDGET'LAR: `VoiceWidgetProvider` (tek mikrofon, 1x1'den başlar, iki yönde boyutlanır → notlar://voice), `QuickActionsWidgetProvider` (yeni not/liste/sıralı liste/mikrofon → notlar://new?type=…). Derin bağlantı `notlar://new` router'da not oluşturup editörü açar. Mevcut Notlar widget'ına minResize + description eklendi. (6) PİL: tüm widget info'larda `updatePeriodMillis=0` (30 dk'lık periyodik uyanma kalktı; veri zaten WidgetService'ten anında itilir) + WidgetService 2 sn debounce ve payload diff (aynı içerikte widget hiç uyandırılmaz). (7) GÜVENLİK: firestore.rules users/{uid} kök dokümanında `premiumUntil` istemciden yazılamaz (create keys().hasAny + update diff().affectedKeys() — freemium atlatma açığıydı); storage.rules'ta read/delete ile create/update ayrıldı — ESKİ KURALDA `request.resource.size` delete'te null olduğundan kullanıcı kendi ekini SİLEMİYORDU (yetim dosya açığı) + contentType image/pdf/audio ile sınırlandı; Manifest'e `allowBackup=false` (secure storage geri yüklemede çözülemez veri + yedek sızıntısı). KURAL DEĞİŞTİ → `firebase deploy` GEREKLİ. TUZAK: RemoteViews widget'ları yalnız statik XML + PendingIntent; mikrofon widget'ı kaydı ana ekranda YAPAMAZ (Android kısıtı: mikrofon foreground ister) — dokunuş /voice ekranını açar, tasarım gereği. Flutter SDK bu ortamda yok → l10n üçlüsü (arb + abstract + tr) yine elle senkronlandı.

- 2026-07-18: **Ayarlar'a "İzinler" bölümü**: Uygulamanın düzgün çalışması için gereken cihaz izinleri tek yerden yönetilir. Yeni bağımlılık YOK (Flutter SDK ortamda olmadığından lock güncellenemez) — mevcut eklentiler + küçük MethodChannel. `PermissionsService` (settings/data): mikrofon durumu MethodChannel `micPermissionGranted` ile SORMADAN okunur (record.hasPermission ekran açılışında istem açardı), istem `AudioRecorder().hasPermission()` ile; bildirim durumu `areNotificationsEnabled()`, istem `requestNotificationsPermission()`; `openAppSettings`/`openBatterySettings` MethodChannel ile. MainActivity.kt'ye `configureFlutterEngine` + `dev.kaimau.notlar/system` kanalı eklendi: ContextCompat.checkSelfPermission(RECORD_AUDIO) pür okuma, ACTION_APPLICATION_DETAILS_SETTINGS ve ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS (özel izin gerektirmez, Play güvenli; yoksa uygulama detayına fallback). Ayarlar'da `_PermissionsSection` (WidgetsBindingObserver, resume'da tazeler): Mikrofon (sesli not/dikte/canlı çeviri), Bildirimler (hatırlatıcı/brifing), Pil optimizasyonu (muafiyet durumu okunamadığından hep "Ayarları aç"). İstek false dönerse (kalıcı ret olabilir) sistem ayarı açılır. Bölüm yalnız Android'de görünür (`isSupported`). Manifest'te RECORD_AUDIO/POST_NOTIFICATIONS zaten vardı; izin akışı bunları çalıştırıyor. l10n üçlüsü elle senkronlandı.

- 2026-07-18: **Sesli asistan boş not bug'ı**: Kullanıcı "not oluşturdum diyor ama not boş ve dashboard'da yok" bildirdi. Kök neden: asistan create_note aracını çağırıyor (noteId dönüyor, "Notu aç" çıkıyor) ama içerik boş yazılıyor — hafif model (3.1-flash-lite) not TİPİ ile İÇERİĞİ tutarsız veriyor: `type`'ı atlayıp (→ default text) içeriği `items`'a koyunca `_createNote` body'yi (boş) yazıp öğeleri atlıyordu, ya da tersi. Boş not `filteredNotesProvider`'da gizlendiği için dashboard'da da görünmüyordu. Düzeltme 2 katman: (1) `AssistantService._createNote` içerik-tip uyumunu düzeltir (text+items→checklist; liste+body→body satırlarını öğe yap) VE title/body/items üçü de boşsa not OLUŞTURMADAN modele hata döndürür ("içerik boş, tekrar dene") — model içerikle yeniden dener, olmazsa tool-loop GeminiException'a düşüp controller fallback'i transkripsiyonla not oluşturur. (2) `VoiceAssistantController.finish` güvenlik ağı: primary başarılıysa ve canlı döküm eldeyse, oluşan not `isEmpty` ise body'yi canlı dökümle doldurur (ekstra API çağrısı yok). TUZAK: create_note'un empty-doc'u repo.createNote ile önce oluşturuluyordu; artık boş içerik kontrolü createNote'tan ÖNCE yapılıp kalıntı boş doc engelleniyor.

- 2026-07-18: **Ana ekran bildirim/panel UX düzeltmeleri (3 sorun)**: Kullanıcı ekran görüntüleriyle bildirdi. (1) "Not silindi / Geri Al" snackbar'ı `SnackBarBehavior.fixed` ile en dipte, sistem gezinme çubuğunun altında kalıp örtüşüyordu → `showUndoSnackBar` (core/widgets/undo_snackbar.dart) `floating` davranışıyla güvenli alanın üstünde yüzer. dashboard `_deleteSelected` + note_card `_delete` bunu kullanır. (2) "Notu aç" (sesli asistan done paneli) ve "not silindi" çok uzun kalıyordu → ikisine de `CountdownBar` (core/widgets/countdown_bar.dart, TweenAnimationBuilder 1→0 LinearProgressIndicator) eklendi; snackbar süresi görsel geri sayımla akar, done paneli 6 sn/error 8 sn sonra `onEnd: notifier.dismiss` ile kendiliğinden kapanır. (3) "Dinliyorum/nota dönüştürülüyor" paneli en diptenydi → `VoiceAssistantPanel` `bottomNavigationBar`'dan alınıp dashboard `floatingActionButton` sütununa, mikrofon+ekle düğmelerinin ÜSTÜne taşındı (ConstrainedBox maxWidth=ekran-24, crossAxisAlignment.end ile düğmeler sağda kalır). Panelden SafeArea/dış padding kalktı (Scaffold FAB güvenli alanı hesaba katar), arka plan opaklaştı + elevation:3 (okunaklılık). endFloat FAB'ın alt-sağ köşesi sabit olduğundan panel yukarı doğru büyür, düğmeler yerinde kalır. TUZAK: floating snackbar + FAB varsa snackbar FAB'ın üstünde belirir (dipte değil) — örtüşme çözümü de bu.

- 2026-07-18: **Sesli sistem birleştirme + stabilite + widget bas-başlat**: Kullanıcı ana ekran (telefon) mikrofon widget'ının bas-başlat modunda çalışmasını ve dashboard'daki "yeni sistem"in dengesizliğinin giderilmesini istedi. (1) BİRLEŞTİRME: `notlar://voice` derin bağlantısı (widget + app shortcut + "Hey Google") artık ayrı `/voice` ekranını (VoiceCaptureScreen — dead code olarak duruyor) açmak yerine ana sayfaya gidip (`router.go('/')`) `voiceAutostartProvider`'ı tetikler; dashboard YENİ Sesli Not Asistanı panelini (canlı dökümlü) bas-başlat modunda başlatır — tek tutarlı sistem. `voiceAutostartProvider` bool + `take()` (tek seferlik tüketim): uygulama başka ekrandayken/soğuk açılışta gelen istek kaybolmasın (initState post-frame + build ref.listen ikisi de kontrol eder, take çift başlatmayı önler, dashboard'a her dönüşte yeniden tetiklenmez). (2) STABİLİTE: panel FAB sütunundan (düğmeleri resize edip zıplatıyordu = "dengesiz") alınıp body Stack'inde `Positioned(bottom:168)` sabit konuma taşındı; düğmeler floatingActionButton'da basit Column'da kalır, panel açılıp kapanırken yerinden oynamaz. (3) Kayıt sürerken mikrofon düğmesine dokunmak HER modda bitirir (widget'tan başlamış kayıt durdurulabilsin) + kayıt paneline belirgin "Bitir"/"İptal" düğmeleri (mikrofona gitmeye gerek yok). TUZAK: ref.listen yalnız kayıtlıyken gelen değişimi yakalar → mount öncesi gelen isteği kaçırır; tüketilebilir bayrak + initState kontrolü şart. Dashboard button'ın kendi hold/tap ayarı korundu (widget akışı ondan bağımsız bas-başlat).

- 2026-07-18: **UI/UX büyük paket (18 madde) + klasör sistemi** (dal: `claude/notes-app-ui-features-0xdwts`): (1) ANA EKRAN SADELEŞTİRME: eski iki ayrı çip satırı (`_FilterChips` 46px + `_TagChips` 42px) tek kompakt `DashboardChipsRow` (40px, `ChipTheme` ile küçük padding) altında birleşti; filtre menüsü + görünür filtreler + klasör çipleri + en sık etiketler tek yatay kayan satırda. (2) FİLTRELER ÖZELLEŞTİRİLEBİLİR: `visibleNoteFiltersProvider` (SharedPreferences `visible_filters`), varsayılan yalnız {pinned, starred} — tip filtreleri (metin/liste/sıralı) gizli, "Filtreleri düzenle" alt sayfasından açılır. Gizlenen filtre seçiliyse otomatik "Tümü"ye döner. (3-4) KLASÖR SİSTEMİ: yeni `features/folders` (domain `NoteFolder` + `iconChoices` 16 simge, varsayılan 'folder'; `FoldersRepository` users/{uid}/folders; `folder_sheets.dart` oluştur/düzenle/sil/seç). `Note.folderId` alanı eklendi (copyWith'e `type` + `clearFolderId` de eklendi). Klasör silinince notlar SİLİNMEZ, folderId temizlenir. firestore.rules'a dokunulmadı — mevcut `users/{uid}/{document=**}` wildcard folders'ı kapsıyor. (5) `QuickAddFab`: Keep tarzı açılan "+" (metin/madde/sıralı/el yazısı etiketli mini FAB'lar). (6) EL YAZISI: `/note/:id?draw=1` → `NoteEditorScreen.startDrawing` → açılışta mevcut `DrawingScreen` tuvali açılır, çizim görsel eki olur. (7) OTOMATİK BAŞLIK artık genel ayar DEĞİL: `autoTitleProvider` + ayar switch'i + editör dispose'daki `_autoTitleInBackground` kaldırıldı; yerine editör metaChips'te "Başlık öner" ActionChip (etiket öner gibi bağımsız, yalnız içerikli+başlıksız notta). (8) UZUN BASIŞ: `note_actions_sheet.dart` — paylaş/kopyala/arşivle/kilitle/seç/sil (kilitli notta paylaş/kopya öncesi biyometrik). Çoklu seçim aktifken uzun basış eskisi gibi seçim değiştirir. (9) AI LİSTEYE ÇEVİR TİPİ DE DEĞİŞTİRİR: `showAiSheet` onReplaceText imzası `ReplaceTextCallback(String, {NoteType? asType})` oldu; ai_sheet madde/sıralı çevirilerine `replaceAsType` taşır, `_replaceText` notun `type`'ını da checklist/ordered yapar (tip değişince body temizlenir, satırlar öğe olur). (10) TİKLENEN ALTA DÜŞER: `ItemsEditor._toggle` işaretlenen öğeyi listenin en altına, işareti kalkanı işaretsizlerin sonuna taşır. (11-12) X BUTONU: silme "x" artık yalnız satır ODAKLIYKEN görünür (odaksızken `SizedBox(width:48)` yer tutar) — kaydırma/yazma sırasında yanlış basma önlenir; sıralı+checklist ikisi de aynı `ItemsEditor`. (13) SEÇİM: item TextField'ına `contextMenuBuilder` — varsayılan selectAll çıkarılıp "Satırı seç" (o alanı seç) + "Tümünü seç" (tüm notu panoya kopyala) eklendi (ayrı TextField'lar arası gerçek seçim mümkün değil, kopya pratik karşılığı). (18) İŞARETLİLERİ SİL: checklist'te işaretli varsa header'da "İşaretlileri sil (n)" → `_deleteChecked` topluca kaldırır. (14) DİKTE ANLIK: `showDictationSheet(onPartial:)` — canlı döküm biriktikçe editör gövdesine ANINDA yazılır (eskiden yalnız "Bitir"de ekleniyordu → "dashboard'a dönünce ekleniyor" algısı). Metin notunda taban+ayraç üstüne yazılır; liste tiplerinde bitişte öğe. (15) SESLİ NOT BOŞ NOT: `assistantVoiceNote` artık `fastGeminiModel` (lite) yerine `AppConstants.voiceAssistantModel='gemini-3.5-flash'` tercih eder — lite, araç çağrılı yapısal not oluşturmada tip/içerik tutarsızlığıyla boş not üretiyordu; standart flash önce, lite zincirde yedek (mevcut controller/assistant_service boş-not güvenlik ağları korundu). (16) MİMARİ: klasörler ayrı feature; dashboard çipleri/FAB/aksiyon sayfası ayrı dosyalara bölündü. l10n üçlüsü (arb+abstract+tr impl) elle senkronlandı (Flutter SDK ortamda YOK). TUZAK: `firstOrNull` extension'ı package:collection gerektirir; not_editor'da manuel döngüyle değiştirildi. Testler: note_test'e type/folder copyWith; yeni `items_editor_checklist_test.dart` (tikle→alta düş, işaretlileri sil).

- 2026-07-18: **Liste ekranı tasarım paketi (12 madde)** (dal: `claude/liste-ekrani-tasarim-uu0fsg`): (1) **Gmail bağlama "bir sorun oluştu" — kök neden başlatma**: `GmailAuth.connect/getClient` Android'de `GoogleSignIn.instance.authenticate/authorizeScopes` çağırıyordu ama `initialize()` çağrılmamıştı; Firebase oturumu KALICI olduğundan kullanıcı uygulamayı tekrar açınca Google girişinden geçmeyip singleton hiç başlatılmamış oluyordu → hata. Çözüm: `GmailAuth._ensureInitialized()` (tembel, serverClientId ile) authenticate/authorizeScopes ÖNCESİ; ikinci initialize hatası (giriş zaten başlatmışsa) yutulur. (2) `newChecklist` "Alışveriş listesi" → "Liste" (ana ekran + QuickAddFab). (3+12) **QuickAddFab Overlay'e taşındı**: eski tasarım açılınca yerinde büyüyüp üstteki sesli asistan düğmesini ittiriyordu (konum kayması) ve yalnız "+"ya tekrar basınca kapanıyordu. Artık `LayerLink`+`CompositedTransformFollower` ile seçenekler Overlay katmanında FAB'a demirli (layout kaymaz) + tam ekran görünmez `GestureDetector` bariyeri dışarı dokununca kapatır. (4+5) **ItemsEditor buton konumları**: "Yeni öğe" ekle butonu checklist'te en ÜSTe (header, Keep gibi) alındı — işaretliler alta indiğinden altında kalmıyordu; yeni öğe `_addItem` ile işaretsizlerin sonuna (işaretli bloğun üstüne) girer. "İşaretlileri sil" header'dan (çok üstte) FOOTER'a, işaretli öğelerin hemen altına alındı. Sıralı listede (işaretsiz) ekle butonu footer'da kalır. (8) **Liste seçim**: item context menüsünden özel "Satırı seç"/"Tümünü seç" kaldırıldı, VARSAYILAN araçlar (native "Tümünü seç" dahil) korunur → bir satırın metninin tamamı seçilebilir; ayrı "Tüm notu kopyala" (`copyWholeNote`) eklendi. (6) **Undo snackbar kompakt + kök messenger**: `width:320`, geri sayım "Geri al"ın yanında küçük dairesel gösterge, süre dolunca kapanır. "Sayfa değiştirince sayaç sıfırlanıyor" → `rootScaffoldMessengerKey` (MaterialApp.scaffoldMessengerKey) ile bildirim en yakın değil KÖK messenger'da gösterilir, go_router sayfa geçişinden bağımsız. (7) **Editör metaChips tek satır**: `Wrap` (çok satır) yerine yatay kayan tek satır; etiket/öneri EYLEMLERİ (etiket ekle/öner, başlık öner, hatırlat) tek `PopupMenuButton` (`noteMetaMenu`="Ekle / Öner") altında toplanır — kullanıcı hangisini uygulayacağını menüden seçer. (10) **Klavye geri açılması**: renk/görünüm ve ek (ataş) alt sayfaları da hesap makinesi gibi açılmadan önce `_dismissKeyboard()` (primaryFocus.unfocus + post-frame tekrar) çağırır — odaklı alan kalınca modal kapanışında klavye geri açılıyordu. (11) **Sesli asistan ilk kelime**: `VoiceAssistantController.start` canlı yolda mikrofonu HEMEN açar (`_pcm`'de birikir), dikte oturumunu arka planda bağlar ve bağlanınca biriken sesi topluca gönderir (`unawaited(connect().then(sendAudio(_pcm.toBytes())))`) — eskiden connect AWAIT edildiğinden ilk kelimeler kaçıyordu. `voiceProcessing` metni "Söyledikleriniz uygulanıyor..." oldu. (9) **Dikte alt sayfası interaktif**: aynı ilk-kelime backfill'i (`_pending` BytesBuilder + `_connected`) + "Bekle"/"Konuş" duraklat/sürdür (`_paused`, canlı yolda; duraklatınca ses yok sayılır) + "Bitir ve ekle". TUZAK: Flutter SDK ortamda YOK → l10n üçlüsü (arb + abstract getter + tr impl) elle senkronlandı; yeni anahtarlar: copyWholeNote, noteMetaMenu, dictationPaused/Pause/Resume. `onReorderItem` ItemsEditor'da PR #14'ten geliyor (Flutter 3.44.6 API'si), dokunulmadı.

- 2026-07-18: **graphify grafında kalıcı boşluk: `token_store.dart` indekslenmiyor**: Tazelik denetiminde bulundu — graf geri kalanı taze (manifest 134 dosya, mtime uyuşmazlığı 0, son commit'in `pdf_chat_screen`→`doc_chat_screen` yeniden adlandırması yansımış) ama `lib/features/auth/data/token_store.dart` manifest'te YOK. Kök neden bizde değil, upstream'de: `graphify.detect._is_sensitive()` Aşama 3 "generic keyword" heuristiği — `(?<![a-zA-Z0-9])tokens?(?![a-zA-Z])` deseni `token_store` içinde eşleşiyor ve stem 2 kelime olduğu için ("<=2 word" kuralı) dosya credential-store sanılıp SESSİZCE atlanıyor. Dosyada sır yok (31 satırlık `flutter_secure_storage` sarmalayıcısı). Etki: grafta 1 düğüm + 2 kenar eksik — `desktop_google_auth.dart` ve `gmail_auth.dart` grafta var ama `TokenStore` hedefine bağlanamıyor, yani "refresh token nerede saklanıyor" sorusuna graf eksik cevap verir. DENENMEYECEK YOL: `.graphifyinclude` allowlist işe YARAMAZ — detect.py'de `_is_sensitive` kontrolü include'dan SONRA ve koşulsuz çalışır (docstring: "Sensitive files ... are still excluded later"). KARAR: dosya yeniden ADLANDIRILMADI — kaynak kodu grafın isim filtresine yaranmak için değiştirmek 1 düğüm karşılığında 3 dosyalık düzenleme demek, değmez. Boşluk bilinçli kabul edildi; her `graphify update`'te tekrarlanır, tekrar araştırmaya gerek yok.

- 2026-07-18: **DÜZELTME — Flutter SDK bu makinede VAR: `C:\src\flutter` (3.44.6)**: Yukarıdaki birçok maddede geçen "Flutter SDK bu ortamda YOK → l10n üçlüsü elle senkronlandı" bilgisi YANLIŞ/ESKİ, artık ona göre davranılmasın. SDK kurulu ama PATH'te DEĞİL (`flutter`/`dart` komutu "bulunamadı" der; bu yüzden yok sanılmış) — tam yolla çağrılır: `& C:\src\flutter\bin\flutter.bat analyze|test|pub get`. Sonuçlar: (1) l10n üçlüsü ARTIK ELLE SENKRONLANMAYACAK; `flutter analyze` gen-l10n'i `app_tr.arb`'den yeniden üretir (`l10n.yaml` → output-dir `lib/l10n/generated`). Bu oturumda elle yazılan üçlü bu şekilde doğrulandı, çıktı birebir aynı çıktı. (2) Push öncesi uçtan uca doğrulama YERELDE yapılabilir (analyze ~40-105 sn, test ~15 sn) — CI'ya bel bağlamaya gerek yok. (3) `pubspec.yaml` değişince `pub get` lock'u yerelde tazeler.

- 2026-07-18: **ponytail audit uygulandı — net -502 satır, -3 bağımlılık** (doğrulama: `flutter analyze` temiz + 30/30 test): (1) **Ölü `/voice` ekranı silindi**: `VoiceCaptureScreen` (301 satır) + rota + import; derin bağlantı 2026-07-18'de ana sayfa + `voiceAutostartProvider`'a taşındığından ekrana giden çağrı kalmamıştı (önceki madde "dead code olarak duruyor" diyordu — rule 4b gereği silindi). (2) `GeminiService.chatWithNotes()` hiç çağrılmıyordu (sohbet `assistantChat` kullanıyor), silindi. (3) 8 ölü l10n anahtarı üç dosyadan da kaldırıldı: `selectRow`/`selectAll` (liste paketinde özel context menü kaldırılmıştı), `dictationPaused/Pause/Resume`, `colorDefault`, `noteNotFound`, `voiceTapToFinish`. (4) `AiTextResult` (ai/presentation): brifing + öneriler ekranlarının birebir kopya loading/error/boş/metin-kartı gövdesi tek widget'a alındı. KARAR: `mail_summary` bilerek DIŞARIDA — sonucu `List<ImportantEmail>` ve hata dalında ekstra "Ayarlar" düğmesi var; katmak parametre eklemek olurdu, kod kısaltmak değil (koda `ponytail:` notu düşüldü). (5) `StringDailyCache` tabanı: `DailyCacheNotifier<String>` alt sınıflarındaki `emptyValue=''`/`encode`/`decode` kimlik tekrarı bir kez tanımlandı; `suggestions_screen`'deki açık `DailyCacheNotifier<String> notifier` tip anotasyonu KORUNDU (LUB tuzağı hâlâ geçerli). (6) Hiç import edilmeyen 3 paket düştü: `animations`, `flutter_slidable`, `cupertino_icons`. DAVRANIŞ DEĞİŞİKLİĞİ: brifing hata ekranındaki "Tekrar dene", ücretsiz kullanıcı o gün üretmişse eskiden sessizce hiçbir şey yapmıyordu; artık öneriler ekranıyla aynı "bugün oluşturuldu" bildirimini gösterir. TUZAK: `gemini_service.dart`'ta parantez sayısı zaten dengesiz görünür (Türkçe istem metinlerinde `)` geçiyor) — kaba parantez sayımıyla sözdizimi doğrulamaya çalışma, `analyze` kullan.

- 2026-07-19: **TTS temeli (cihaz seslendirmesi) + öğe animasyonu + kart/dashboard sadeleştirme**: (1) **KÖK NEDEN — "seslendirme yapılmıyor"**: `GeminiService.synthesizeSpeech` ham Gemini REST'e `x-goog-api-key` ile gidiyordu ve ses tipi kodda SABİT (`'Kore'`) idi; uygulamanın geri kalanı anahtarsız Firebase AI Logic kullandığından anahtarı olmayan kullanıcıda hiç ses çıkmıyordu. Aynı sebep canlı çeviriyi de vuruyor (`LiveTranslateSession` WebSocket'e `?key=` ile bağlanıyor — bu HÂLÂ anahtar istiyor, taşınmadı). (2) **KARAR — cihaz TTS'i (`flutter_tts`), Gemini TTS DEĞİL**: Gemini TTS tamamen silindi (`synthesizeSpeech` + `geminiTtsModel` sabiti). Gerekçe: sesli okuma uzun metinlerde çalışacak (bir PDF'in tamamı); her cümleyi modele göndermek kota yakar, ağ bekletir, anahtar ister. Cihazınki bedava/anında/çevrimdışı ve sistem ses listesi "ses tipi seçimi"ni bedavaya verir. Bu, SpeechRecognizer kararının aynısı — ses girişi de çıkışı da cihazda. (3) `core/utils/speech_output.dart`: cümle cümle okuma (tek parça verilirse durdurmak tepki vermiyor + motor uzun metni sessizce yutuyor), duraklat/devam/durdur, ilerleme, hız. Ses seçimi DİL BAŞINA saklanır (`tts_voice_<lang>`; eski tek anahtar `tts_voice` Türkçe'ye devredilir): tr + en kullanıcı seçer, kalan 14 dil otomatik. (4) **TUZAK — cinsiyet çıkarımı**: Android ses cinsiyetini ayrı alan olarak VERMEZ, ada gömer (`de-de-x-nfh#male_1-local`). Düz `contains('male')` KADIN sesi seçer çünkü "female" kelimesi "male" içerir — önce dişil eleme şart (`pickAutoVoice`, testli). Bazı motorlar hiç male/female yazmaz → ilk sese düşer, garanti yok. (5) **TUZAK — AnimatedOpacity işaretli öğede oynamaz**: `ItemsEditor`'da işaretli öğeler `ReorderableListView`'in FOOTER'ında ayrı blokta durur; öğe işaretlenince gövdeden footer'a, yani BAŞKA BİR WIDGET AĞACINA taşınır ve animasyon State'i hedef değerle yeniden doğar. Çözüm `_settling` haritası: görünüm hemen değişir (solma oynar), YERLEŞİM 220 ms eski blokta tutulur, sonra gerçek yerine taşınır. Örtülü animasyonlar yalnız AYNI State değer değişimi görürse çalışır — bloklar arası taşınan hiçbir widget'ta implicit animation kurma. (6) `speak()` `languageCode` alır; verilmezse 'tr' varsayılır. Çevirmen hedef dili geçer (konuşulanın karşısı) — yoksa İngilizce metin Türkçe okunuşuyla okunuyordu. Cihazda dil yoksa varsayılan sese düşülür. Duraklat motorun dilini sıfırlayabildiğinden dil saklanıp devam ederken yeniden uygulanır. (7) `share_intake` KÖK NEDEN: `receive_sharing_intent` yalnız SEND değil ACTION_VIEW'ı da yakalıyor → widget'ın `notlar://voice` derin bağlantısı paylaşılan URL sanılıp gövdesi o olan ÇÖP NOT oluşuyordu; `notlar://` şeması alımda yok sayıldı. (8) `_appendText` listede sondaki BOŞ öğeleri atıp ekler (liste sonunda hep boş "yeni öğe" satırı bekler, yeni maddeler onun arkasına düşüp boş satır ortada kalıyordu). (9) UX değerlendirmesi uygulandı: hızlı ekleme barı TAMAMEN silindi (FAB zaten üç tipin hepsini + el yazısını veriyordu; 52dp prime alan), kart 6 katmandan 4'e (gövde 8→4 satır, AI özeti ayrı satırdan üst rozete), kart zaman damgası/mini rozetlerdeki `fontSize: 10` + %70 alfa kaldırıldı (Material'in en küçük rolü labelSmall=11sp; 10 keyfi ve tip ölçeği dışı), kart ⋮ dokunma alanı ~18x22 → 36x36, dashboard ⋮ menüsüne grup ayraçları. `note_actions_sheet` 8 satırla varsayılan 9/16 yükseklik sınırını aşıp son satırı ("Sil") gezinme çubuğunun altına düşürüyordu → `isScrollControlled` + kaydırma. (10) `flutter` PATH'te değil, `C:\src\flutter\bin` önekiyle çağrılır; `flutter gen-l10n` yeni arb anahtarları için ŞART, yoksa analyze `undefined_getter` verir.

- 2026-07-19: **ML Kit çeviri + cihaz tanıma + PDF sesli okuma/podcast + Firebase dosya boyutu**: (1) **KARAR — bas-konuş çevirisi artık tümüyle cihazda**: eski yol ses dosyasının TAMAMINI Gemini'ye gönderiyordu (ses ≈ 32 token/sn). Şimdi `DeviceSpeech` (SpeechRecognizer) yazıya döker, `google_mlkit_translation` çevirir. **BEDEL: APK 42 MB → 85.5 MB (+43.5 MB)** — ML Kit yerel kütüphaneleri gömüyor, ölçüldü. Kazancın büyük kısmı (~10× token) zaten CİHAZ TANIMA adımından geliyor ve o 0 MB; ML Kit yalnız çeviri kotasını sıfırlıyor. Boyut sorun olursa geri alınacak ilk şey ML Kit, cihaz tanıma DEĞİL. (2) **TUZAK — ML Kit metin çevirir, ses değil**: tanıyıcı dili baştan bilmek zorunda olduğundan Gemini'nin otomatik dil tespiti kayboldu. Çözüm: HER DİL İÇİN AYRI DÜĞME (Google Çeviri'nin karşılıklı konuşma modu gibi) — kullanıcının istediği "sıra sıra" davranış da bu. (3) **TUZAK — Azerbaycanca ML Kit'te YOK** (56 dil destekler); `supportsPair` false dönüp Gemini'ye düşer, sessizce yanlış çeviri üretmez. 4 test korur. (4) **TUZAK — `fromRawValue` enum'ın değil `BCP47Code` UZANTISININ statiği**: `TranslateLanguage.fromRawValue(...)` derlenmez, `BCP47Code.fromRawValue(...)` doğru. (5) Ayarlar'a `preferGeminiTranslateProvider` (varsayılan false = cihazda). Çevirmen `voiceButtonModeProvider`'ı (hold/tap) artık dinliyor — ayar zaten vardı, yalnız çevirmen kullanmıyordu. (6) **PDF SESLİ OKUMA**: `pdfrx` zaten kurulu ve metin katmanını veriyor (`PdfPage.loadText().fullText`) — yeni bağımlılık gerekmedi. `features/notes/data/pdf_text.dart`: çıkarma + `cleanForSpeech` (satır sonu tirelemesi birleştirme, yalnız sayfa numarası olan satırları atma, 3+ kez tekrarlayan kısa satırları = üstbilgi/altbilgi silme). **TUZAK (test yakaladı)**: tireleme birleştirmesi `-\n` deseniyle yazılırsa `- 13 -\n14` gibi süsleme satırlarını da yapıştırır ve sayfa numarası tespitini bozar — tire İKİ YANDAN da harfe bitişik olmalı (`(?<=\w)-\r?\n[ \t]*(?=\w)`). (7) `GeminiService.podcastScript`: ham PDF metnini sesli okutmak dinlenmez (tablo kırıntıları, dipnotlar, "Sayfa 12 / 47" sesli okunur); istem metni akıcı anlatıya çevirir. `ai/presentation/listen_screen.dart` iki aşamalı: "Sesli dinle" (bedava/çevrimdışı, model çağrısı YOK) → "Podcast'e dönüştür" (bir Gemini çağrısı). Taranmış PDF'te metin katmanı yok → ekran sebebini söyler, OCR'a bağlanmadı (sayfa sayfa Gemini çağrısı olurdu). (8) **FIREBASE DOSYA BOYUTU**: ses kaydı 96 kbps stereo → **48 kbps mono** (dakikada ~720 KB → ~180 KB, 4× kazanç, konuşmada duyulur fark yok); görsel JPEG q85 → **q80** (~%25). Görselde **2048 px KORUNDU** — OCR ve "PDF'i özetle" o görsellerden metin okuyor, çözünürlük düşürmek onları bozardı. PDF sıkıştırılamıyor: 5 MB üstünde (`largeAttachmentWarnBytes`) boyutu söyleyen onay diyaloğu, engelleme yok. (9) **TUZAK — `dart format lib/` TÜM kod tabanını yeniden biçimlendirir**: Dart 3.12'nin yeni "tall style" biçimlendiricisi satır yapısını değiştirdiği için `git diff -w` ile ayıklanamaz; yalnız dokunulan dosyalar verilmeli, yoksa 60+ dosyalık gürültü commit'e karışır.

- 2026-07-19: **BEKLEYEN İŞ — madde 4 ve 6 (kullanıcı hatırlatılmasını istedi)**: (4) **Notu PDF'e dönüştürme, düzenleyerek**: `pdf` + `printing` paketleri gerekir, sayfa düzeni + dışa aktarma öncesi düzenleme ekranı. Bağımsız iş, TTS/çeviriyle ilgisi yok. (6) **Word/PowerPoint/txt okuyup hem tam sesli okuma hem özet**: txt bedava; PDF `pdf_text.dart` ile ZATEN çözüldü (madde 3 tamamlandı); **DOCX/PPTX gerçek iş** — ikisi de ZIP+XML, hazır Dart paketi yok, `archive` + `xml` ile elle ayrıştırma gerekir. Sesli okuma tarafı `speech_output.dart` + `listen_screen.dart` ile hazır, yalnız METİN ÇIKARMA eksik. Ayrıca yapılmayan: **ses dosyası olarak kaydetme** (`flutter_tts.synthesizeToFile` var ama Android'de WAV üretiyor; 30 dk okuma ~150 MB tahmin ediliyor, ÖLÇÜLMEDİ — sıkıştırma/parçalama ayrı tasarım kararı).

- 2026-07-19: **Madde 4 ve 6 tamamlandı (bekleyen iş kapandı) + podcast özet seçeneği**: (1) **Notu PDF'e aktarma** — `printing` paketi BİLEREK eklenmedi: dosyayı `share_plus` paylaşıyor, önizlemeyi zaten kurulu `pdfrx` yapıyor (sahte `Attachment` ile mevcut `PdfViewerScreen` yeniden kullanıldı). Yeni paket yalnız saf-Dart `pdf` (+ path_parsing, qr). (2) **TUZAK — `pdf` paketinin hazır Helvetica'sı WinAnsi**: ı ğ ş İ YOK, Türkçe not bozuk çıkardı. Font gömmek zorunlu. Roboto artık yalnız variable font olarak yayımlanıyor (static TTF YOK), app'in kullandığı Inter Tight'ın da static'i yok → **PT Sans Regular** (OFL, 432 KB, `assets/fonts/`). gstatic'in eski-UA uçnoktası geçerli TTF DEĞİL obfuscated subset veriyor (sfnt başlığı yok) ve subset'ler Türkçe glifleri düşürüyor; kaynak `raw.githubusercontent.com/google/fonts`. Glif varlığı cmap'ten doğrulandı, üretilen PDF'in ToUnicode tablosu da doğrulandı (metin seçilebilir/aranabilir). (3) **PT Sans'ta ✓ (U+2713) ve ☐ (U+2610) YOK** → onay kutuları glif değil `pw.CustomPaint` ile vektör çiziliyor (PDF'te başlangıç sol alt, y yukarı büyür). (4) **Yapı tek metin kutusundan okunuyor**: dışa aktarma ekranı başlık + tek düz metin alanı veriyor, satır başındaki `[x]`/`[ ]`/`1.`/`-` işaretleri biçime dönüşüyor. Ayrı liste düzenleyicisi yazmaya gerek kalmadı, `Note.toPlainText()` zaten bu biçimi üretiyor. Kilitli not PDF'e de kimlik doğrulaması olmadan çıkmıyor. (5) **DOCX/PPTX** — `archive` ve `xml` ZATEN bağımlılık ağacındaydı, direct'e alındı, yeni paket ağırlığı YOK. İkisinde de metin aynı yapıda (paragraf `p`, parça `t`), yalnız ad alanı farklı (`w:`/`a:`) → `namespaceUri: '*'` jokeriyle TEK işlev ikisini de okuyor. xml 7.x'te parametre adı `namespace`→`namespaceUri` (joker semantiği aynı, paket kaynağından doğrulandı). (6) **TUZAK — slayt sırası**: `slide10` dizgi sıralamasında `slide2`'nin ÖNÜNE geçiyor, sunum karışık okunuyordu; sayısal sıralama şart (test bunu yakaladı). (7) **TUZAK — metin kutusu paragrafı**: DOCX'te `<w:p>` içinde `<w:p>` olabiliyor, dıştaki zaten içteki metni topladığı için iç paragraf ayrıca yazılırsa aynı cümle İKİ KEZ okunuyor; ata kontrolüyle atlanıyor. (8) **TUZAK — .txt kodlaması**: Windows'ta üretilmiş Türkçe txt çoğunlukla CP1254; düz latin1 geri düşüşü ı/ş/ğ'yi ý/þ/ð yapıyordu → 13 baytlık eşleme tablosu. (9) **Belge okuma nota EKLENMİYOR, Firebase'e yüklenmiyor** (kullanıcının "büyük dosyalar" şikayeti yüzünden bilinçli): dosya seçilir, okunur, saklanmaz. Android dosya seçici uzantıya değil MIME'a bakıyor — `mimeTypes` verilmezse Word/PowerPoint seçilemez görünür. (10) `ListenScreen` artık `Attachment` değil `(title, loadText)` alıyor; PDF/Word/sunum/txt tek ekranı paylaşıyor. `podcastScript`'e `summarize` bayrağı eklendi (aynı çağrı, değişen tek şey "hepsini koru" vs "beşte birine indir"). (11) **YAPILMADI**: sayfa boyutu A4 sabit (Letter seçeneği yok), ses dosyası olarak kaydetme hâlâ yok.

- 2026-07-19: **Uygulama ikonu yenilendi (B — büyük sayfa) + adaptive icon çift kırpma tuzağı**: Eski ikonun dört sorunu: özne küçük (sayfa tuvalin ~%45'i → 48dp'de beyaz leke), iki odak (sayfa ile yıldız birbirini yiyor), düz tek renk zemin, ve adaptive maskede daha da küçülmesi. Yeni: degrade zemin + kenardan kenara sayfa + yıldız ast konumda. **Kaynak SVG'ler `assets/icon/src/` altında** (PNG'ler oradan Chrome headless ile üretiliyor, ek araç gerekmez — komut pubspec.yaml'da yazılı). Degrade tek hex'le anlatılamadığı için `adaptive_icon_background` artık RENK değil GÖRSEL; `values/colors.xml` içindeki `ic_launcher_background` rengi ölü kaldı, silindi (dosyada başka şey yoktu). **TUZAK — iki kırpma üst üste biniyor**: (1) launcher 108dp tuvalin yalnızca merkezdeki 72dp'sini gösterir, (2) flutter_launcher_icons ürettiği XML'e ayrıca `android:inset="16%"` ekler. Önce yalnız (2)'yi görüp ön planı 1.19'a BÜYÜTTÜM — yanlıştı, daire maskede sayfa soldan ve alttan kesiliyordu. Üç adayı (0.845 / 1.0 / 1.19) daire+squircle maskeyle SİMÜLE EDİP bakınca doğrusu ilk hesap olan **0.845** çıktı; o ölçekte çizimin köşegeni 66dp güvenli daireye tam oturuyor. Üretilen PNG'nin alfa sınırları ölçülerek doğrulandı (614x684, merkez 512,512). XML'i elle düzeltmeye kalkma — araç her çalışmada yeniden yazıyor, telafi KAYNAK dosyada yapılmalı. Yapılmadı: Android 13 temalı ikon (`adaptive_icon_monochrome`).

- 2026-07-19: **Görev başına model seçimi + Gemini TTS araştırması (uygulanmadı)**: (1) **Model seçici zaten vardı ama TEK SATIR gizliyordu**: `_ModelSelectors` içinde `if (!hasKey) return SizedBox.shrink()` — kendi API anahtarını girmeyen kullanıcı hiç göremiyordu. Oysa alt katman anahtarsızı zaten destekliyordu: `availableModels()` anahtar yoksa `AppConstants.geminiModelPreference`'ı döndürüyor, `FirebaseAiClient` de `preferModel`'i uyguluyor. Koşul kaldırıldı. (2) **Tek `chatModel` yerine `AiTask` enum'u** (general/document/translate/voice) + tek `aiTaskModelsProvider` (Map tutan tek Notifier; family provider API'sini doğrulamaya gerek kalmasın diye bilerek böyle). Eşleme: özet/başlık/etiket/iyileştirme/brifing/sohbet→general, podcast+PDF/not sohbeti→document, metin+konuşma çevirisi→translate, sesli not→voice. **`general` ve `voice` ESKİ prefs anahtarlarını (`model_chat`, `model_voice`) koruyor** — değişseydi güncelleyen kullanıcının seçimi sessizce kaybolurdu; test bunu kilitliyor. Desen: kullanıcı açıkça model seçtiyse ona uyulur, seçmediyse görevin optimize varsayılanı (`generateTitle`→fastGeminiModel, sesli not→voiceAssistantModel) kalır. (3) **GEMİNİ TTS — ARAŞTIRILDI, UYGULANMADI**: "podcast API" aslında TTS API'si; podcast metnini zaten biz yazıyoruz (`podcastScript`), bu yalnız okumayı gerçekçi sese çeviriyor. Ölçüler: `gemini-3.1-flash-tts-preview`/`gemini-2.5-flash-preview-tts`, **preview**, girdi 32k token, çıktı 24kHz 16-bit mono PCM = **2,88 MB/dakika** (20 dk ≈ 58 MB), **en fazla 2 konuşmacı**, Türkçe var, ücretsiz katman var (ücretlisi 1M çıktı token'ı $10-20). **ENGEL: Firebase AI Logic desteklemiyor** — resmî model listesinde TTS modelleri YOK, ses çıkışı yalnız **Live API** altında listeli (`gemini-2.5-flash-native-audio-preview`). `firebase_ai` 3.14.1'de `SpeechConfig`/`multiSpeaker` görünmesi yanıltıcı: o alan `BaseGenerationConfig`'te duruyor ve `LiveGenerationConfig` ile `GenerationConfig` ikisi de miras alıyor, yani `generateContent`'in TTS yapabildiğini KANITLAMIYOR. Örneklerin Cloud Functions üzerinden gitmesi de bunu doğruluyor. Sonuç: yalnız kendi anahtarı olanlara REST üzerinden isteğe bağlı özellik olarak eklenebilir (geçmişte tam bu yüzden silinmişti); anahtarsız kullanıcı için yol yok. Sonda yazmak APK turu gerektireceği için yapılmadı — kanıt doküman düzeyinde yeterince kesin.

- 2026-07-19: **AI çıktıları önbelleğe alındı (boşa token yanmasın)**: PDF podcast'i, not özeti, not analizi ve PDF özeti her açılışta yeniden üretiliyordu. Yeni `AiCache` (`lib/features/ai/data/ai_cache.dart`): anahtar sha256(tür uzunluğu + tür + girdi), çıktı cihazda `<appSupport>/ai_cache/<hash>.txt`. **Firestore'a YAZILMADI, bilinçli**: podcast metni 20-50 KB tutuyor, nota gömülseydi her not düzenlemesinde yeniden senkronlanırdı; ayrıca "Belge oku" akışının bağlı olduğu bir not yok. **KARAR — zaman damgası karşılaştırması reddedildi**: ilk tasarım `aiSummary.createdAt > note.updatedAt` ile tazelik ölçecekti ama `updatedAt` SUNUCU damgası, `createdAt` CİHAZ damgası — saat kayması önbelleği sessizce hep-isabet ya da hiç-isabet yapardı. İçerik hash'i saatten bağımsız ve not değişince kendiliğinden tazeleniyor. Anahtar **uzunluk önekli** (`'${kind.length}:$kind$input'`) çünkü düz birleştirmede ('ab','c') ile ('a','bc') aynı anahtara düşerdi; test bunu kilitliyor. Önbellek 40 dosyada sınırlı, budama en eskiyi atıyor (okuma erişim damgasını tazeliyor ki sık kullanılan atılmasın). PDF özetinde önbellek isabeti dosyanın Storage'dan İNDİRİLMESİNİ de atlıyor (anahtar `pdf.id`, ek bir kez eklendikten sonra değişmiyor). Podcast'te "Yeniden üret" düğmesi var (uzun ve öznel çıktı, kötü çıkarsa mahkûm kalınmasın); özet/analizde yok — ucuz ve içerik değişince zaten tazeleniyor. **TUZAK — çiğ NUL baytı**: anahtar ayracı için NUL (0x00) kullanmak istedim; `backslash-u0000` kaçışı komut yolunda tek ters bölüye düşüp dosyaya GERÇEK NUL baytı yazdı (git dosyayı ikili sayıyor, grep "Binary file matches" diyor, iki tur kaybettirdi). Uzunluk öneki hem bunu çözdü hem daha temiz — kaçış gerektirmiyor. **Önbelleklenmeyen**: çeviri ve "geliştir" (girdi/hedef her seferinde değişiyor, isabet oranı düşük).

- 2026-07-19: **AI geliştir yapı bozması + yabancı dil hızı + toplu seçim işlemleri + sıralama/çerçeve + Hızlı Not widget'ı** (kullanıcı 5 maddelik istek): (1) **AI "notu düzelt/geliştir" checklist yapısını bozuyordu** — KÖK NEDEN: `Note.toPlainText()` başlığı ve `- [ ]`/`[x]`/numara işaretlerini metne katıyor; model bunları aynen geri döndürünce `_replaceText` satırları öğe yapıyor → başlık ilk madde oluyor, `[ ]`/`[x]` öğe metnine sızıyor ("çift parantez ve çarpılı durum"). ÇÖZÜM: geliştir/düzelt akışı artık `Note.toContentText()` gönderiyor (başlık YOK, işaret YOK, her satır bir öğe); `_replaceText`/`_appendText` yeni `_parseListLine` ile baştaki madde imi/numara/`[ ]`/`[x]` işaretlerini ayıklıyor ve checklist'te öğe sayısı korunuyorsa işaretli durum + id'ler korunuyor. (2) **Yabancı dil TTS çok hızlı**: `speech_output` artık dile göre hız uyguluyor — `_rateFor(lang)` tr için `tts_rate` (0.5), diğerleri için ayrı `tts_rate_foreign` (varsayılan 0.4, daha yavaş); `speak`/`resume` her okumada uyguluyor; Ayarlar'a "Yabancı dil hızı" kaydırıcısı eklendi. (3) **Toplu işlemler**: çoklu seçim üst çubuğu artık arşivle/kopyala/sil simgeleri + taşma menüsünde sabitle/yıldız/renk/çerçeve/paylaş — "üç noktadaki işlemler seçim sonrası tek yerde". (4) **Sıralama + renkli çerçeve**: `noteSortProvider` (elle/güncellenen/oluşturma/başlık, kalıcı) `filteredNotesProvider`'da uygulanıyor, dashboard taşma menüsünde "Sıralama"; `Note.frameColor` (NoteColor, zeminden bağımsız) eklendi — kart ve editör çevresine renkli çerçeve, ortak `showNoteColorPicker` (zemin=dolu, çerçeve=halka önizleme) editör paletinde + kart üç-nokta menüsünde + toplu seçimde. (5) **Hızlı Not widget'ı**: `QuickNoteWidgetProvider` + yeşil zeminli tek düğme, `notlar://new?type=text` derin bağlantısıyla doğrudan yeni metin notu açar (router zaten işliyordu). TUZAK: Flutter SDK bu ortamda yok → l10n `flutter gen-l10n` ile değil, `app_localizations.dart`/`_tr.dart` elle güncellendi.

- 2026-07-19: **Gmail yeniden açılışta bozuk + APK "paket geçersiz" tanısı**: (1) GMAIL KÖK NEDEN: `GmailAuth.getClient()` doğrudan `authorizationClient.authorizeScopes` çağırıyordu ama Google oturumunu geri kurmuyordu. Firebase oturumu kalıcı, google_sign_in oturumu DEĞİL: uygulama yeniden açılınca yetkilendirilecek Google kullanıcısı olmadığından Gmail "bir sorun oluştu" veriyordu (bağlarken çalışıyor, yeniden açılışta bozuluyordu — klasik v6→v7 tuzağı). ÇÖZÜM: getClient() önce SESSİZ `authorizationForScopes` dener; null dönerse `authenticate(scopeHint)` + `authorizeScopes` ile yeniden doğrular ve kayıtlı hesabı günceller. (2) APK "paket geçersiz görünüyor" (MIUI): v1.0.79 CI logunda "Kalıcı imza anahtarı hazırlandı" — APK GEÇERLİ ve kalıcı release anahtarıyla imzalı. MIUI'de mevcut uygulamanın ÜZERİNE kurarken "paket geçersiz" = telefondaki eski kurulumun FARKLI/eski anahtarla imzalanmış olması (keystore secret'ı eklenmeden önceki bir sürüm). Çözüm koda değil: eski uygulamayı KALDIR, v1.0.79'u temiz kur (veriler Firebase'de). Anahtar artık sabit olduğundan sonraki güncellemeler sorunsuz.

- 2026-07-20: **5 UX düzeltme + silme temizliği (PR #22)**: (1) Dashboard yatay çekişle Tümü→görünür filtreler→klasörler gezinme (`_cycleFilterFolder`, GestureDetector.onHorizontalDragEnd; dikey kaydırma ayrı eksende kalır). (2) Filtre sırası ayarlanabilir: `visibleNoteFiltersProvider` Set→sıralı List, filtre menüsünde ReorderableListView ile sürükle-bırak. (3) PDF metin seçimi: `PdfViewerParams(enableTextSelection: true)` — önceden PDF salt görüntüydü. (4) Ayarlar zıplaması KÖK NEDEN: `_ModelSelectors` inline FutureBuilder her rebuild'de `availableModels()`'ı yeniden kurup bölümü boşaltıp dolduruyordu → önbellekli `availableModelsProvider` (FutureProvider). (5) Üç nokta menüsü genişliği: ListTile (tam genişlik) → mainAxisSize.min Row. (6) Silinenler Firebase'de kalmasın: `purgeOldTrash` 30 gün→24 saat; hesap silmede `notes` yanı sıra `folders`+`aiReports` alt koleksiyonları da siliniyor (doküman silmek alt koleksiyonu silmiyor — yetim veri). TUZAK: Flutter 3.44.6 analyze'ında `ReorderableListView.onReorder` deprecated (onReorderItem lehine, newIndex'i kendi düzeltiyor); tek info bile CI'ı düşürüyor → satır bazlı `// ignore: deprecated_member_use` ile susturuldu (mevcut reorder mantığı klasik onReorder semantiğine göre doğru).

- 2026-07-21: **4 istek: sabit üst bar + "yeni not olarak aç" + resimde OCR butonu + serbest görsel tuvali.** (1) **Dashboard üst barı kaydırırken kayıyordu**: iki `SliverAppBar`'da `floating:true`+`snap:true`, `pinned:true` ile birlikte kullanılınca bar aşağı inince küçülüp kayboluyordu. `floating`/`snap` kaldırıldı, yalnız `pinned` bırakıldı → arama+ayarlar tepede TAM sabit (`dashboard_screen.dart`). (2) **"Yeni not olarak aç" (istek 1+2)**: AI düzeltme sonucu eskiden yalnız "Notu değiştir" (geri-alınamaz üzerine yaz) idi; kullanıcı "değiştirmeden + düzeltilmiş iki seçenek" istedi. `ai_sheet.dart`'a üçüncü callback `onCreateNote` + `_ResultView`'e "Yeni not olarak" butonu (HER sonuç türünde: düzeltme/çeviri/özet/OCR); editörde `_createNoteFromText` orijinali DEĞİŞTİRMEDEN `createNote`+`updateFields` ile yeni not üretip `context.push('/note/$id')` ile açıyor (başlık+klasör taşınır; liste tipinde `_parseListLine` ile öğelere ayrılır). `_replaceAsType` yalnız düzeltme sonucunda taşınır. **Editöre `go_router` import edildi** (önce yalnız Navigator kullanıyordu). (3) **OCR zaten vardı ama gömülüydü** (`GeminiService.extractTextFromImage`, ai_sheet'te "Metni çıkar"); istek 3 için doğrudan resmin araç çubuğuna taşındı → editör `_ocrImage` (readBytes→extractTextFromImage→`_appendText`, snackbar'lı ilerleme/hata), `NoteImages.onExtractText` callback'iyle. (4) **KARAR — görseller inline'dan SERBEST TUVALE (canvas) geçti (istek 5, kullanıcı "tam serbest" seçti).** `Attachment`'a `x`/`y` (tuval oranı 0–1, sol-üst) eklendi (copyWith/toMap/fromMap; toMap'te yalnız null değilse yazılır → geriye dönük uyumlu). `note_images.dart` tamamen yeniden yazıldı: `Stack` tuval (yükseklik `cw.clamp(220,460)`), her görsel `Positioned`; dokun→seç, seçiliyken sürükle-taşı (onPan, x/y persist), sağ-alt tutamak + alttaki slider ile serbest boyut (`displayWidth`), araç çubuğunda tam ekran/OCR/sil, boş alana dokun→seçim kalkar. **Tek doğruluk kaynağı `_resolve()`**: canlı taşıma/boyut değerlerini alıp kutuyu her zaman tuval içine clamp'ler (yükseklik sığmazsa oran korunarak küçültülür) — resize sırasında taşma imkânsız. `align` alanı bırakıldı (eski uyum) ama canvas'ta yok sayılıyor; `x/y` null (eski görsel) → `_defaultX/Y` ile sıralı yerleşim, kullanıcı taşıyınca kalıcılaşır. **Gesture: taşıma yalnız SEÇİLİYKEN aktif** ki seçilmemiş görselde dikey liste kaydırma bozulmasın; iç (tutamak) pan, dış (taşıma) pan'a arena'da baskın. **TUZAK: Flutter bu ortamda YOK** → `flutter analyze/test` çalıştırılamadı, l10n (`openAsNewNote`) üç dosyaya (arb + generated abstract + _tr) elle eklendi; kod mevcut kalıplara birebir uyacak şekilde yazıldı.

- 2026-07-20: **KARAR — graphify-out artık commit'leniyor (Faz 1).** Kök tespit: graf
  yalnız yerel makinede duruyordu (`graphify-out/` .gitignore'daydı, CI'da/repoda hiç
  izi yoktu), dolayısıyla bulut oturumları `GRAPH_REPORT.md`'yi okuyamıyordu ve
  "commit'te hook otomatik tazeler" iddiası taşınabilir değildi (bu ortamda .git/hooks
  boş). Faz 1: `graphify-out/` .gitignore'dan çıkarıldı → graf commit'lenip her oturum
  ve CI tarafından OKUNABİLİR olacak. Grafın kendisi bu bulutta üretilemez (graphify
  aracı burada kurulu değil, "usta paketi" özel), o yüzden ilk grafı ANA MAKİNEDE
  `graphify update .` ile üretip commit'lemek gerekiyor. Faz 2 (CI'da otomatik tazeleme)
  ana makineden yapılacak — graphify'ın kurulum kaynağı gerektiği için ertelendi.

- 2026-07-23: **3 hata düzeltmesi (dashboard önizleme + karışık not AI düzeltmesi + "+" FAB tip menüsü).** (1) **Kart önizlemesi işaretsiz maddeleri gizliyordu**: checklist/karışık notta editör işaretsizleri üste alıp gösteriyor ama `_NotePreview` (note_card.dart) depodaki HAM sırayı gösteriyordu; işaretliler araya serpiştiğinde önizlemenin ilk 6 slotu doluyor, aktif (işaretsiz) maddeler görünmüyordu ("notta 4 madde var, kartta 2 görünüyor"). ÇÖZÜM: önizleme artık editörle aynı düzende — işaretsizler önce, işaretliler sonra (checklist + karışık metin dalları). Sıralı listede (ordered) numara sırası korunur, dokunulmadı. Not: bu görünüm-sıralaması; depo sırası ancak kullanıcı bir öğeyi işaretleyince kalıcılaşıyor (ItemsEditor._toggleItem), o yüzden önizlemenin kendi sıralaması şart. (2) **KÖK NEDEN — karışık not (metin tipi + checklist) AI ile düzeltilince maddeler düz metne dönüşüyordu**: `Note.toContentText()` metin tipinde gövdeyi + tüm madde metinlerini TEK metne birleştiriyor; `_replaceText` targetType==text dalında sonucu gövdeye yazıp maddeleri olduğu gibi bırakıyor → içerik hem gövdede düz metin hem checklist olarak ÇİFTLENİYOR (kullanıcı bunu "maddeler düz metine dönüştü" olarak görüyor). ÇÖZÜM: `ai_sheet.dart`'a `_contentForTextOp(skipChecked, converting)` — TİPİ KORUYAN işlemlerde (düzelt/geliştir-Resmî-Kısalt/çeviri) karışık notta AI'a yalnız `note.body` gider, maddeler dokunulmadan kalır; TİP DEĞİŞTİREN dönüşümlerde (maddeye/sıralıya çevir) tüm içerik bilerek birleşir. `_createNoteFromText` (editör) da karışık notta yeni nota maddeleri taşıyor. **KARAR**: karışık notta madde METİNLERİ düzeltilmiyor (yalnız gövde) — round-trip'te gövde çok satırlı düzyazı olduğundan satır-sayısı eşlemesi kırılgan; yapıyı korumak veri kaybını önlemekten öncelikli. (3) **"+" FAB yalnız metin notu açıyordu**: tek dokunuş doğrudan metin notu üretiyor, madde/sıralı liste yalnız BASILI TUTUNCA çıkıyordu ama kullanıcı bunu bulamıyordu. ÇÖZÜM: `quick_add_fab.dart` tek dokunuş artık tip menüsünü açıyor (metin/madde/sıralı/el yazısı hepsi görünür); basılı tutmak da aynı menüyü açıyor. Tooltip "Yeni not — tip seç" olarak güncellendi. TUZAK: Flutter SDK bu ortamda YOK → analyze/test çalıştırılamadı; l10n elle güncellendi (arb + generated _tr).

- 2026-07-23: **Slayt eki + kısa/detaylı özet (slayt & PDF).** Kullanıcı 2 istek: (a) not ek menüsüne "Slayt ekle", (b) slayt/PDF özetinde "kısa" ve "detaylı" seçeneği (detaylı = kaynağa bakmadan anlaşılır kapsamlı özet), sonuç nota eklenebilir / yeni not olabilir. (1) **Slayt eki**: `AttachmentKind.slide` eklendi; `AttachmentRepository.prepareSlide` (PDF gibi sıkıştırmasız saklıyor, pptx mime). Editörde `_pickSlide` (yalnız `pptx`, Android için `mimeTypes` şart yoksa dosya soluk görünür; PDF gibi büyük-dosya uyarısı). Ek şeridinde ve `note_card` önizlemesinde `slideshow_outlined` + `scheme.tertiary`; slayt PdfViewer/ImageViewer ile açılamadığından `_open` erken dönüyor (ses gibi). (2) **Özet metni PPTX'ten YERELDE çıkarılıyor**: Gemini inline_data pptx mime'i KABUL ETMİYOR (yalnız PDF + text/*), o yüzden `DocText.extractFromBytes(ext, bytes)` eklendi (mevcut `_extract`'i compute'la; yol yerine baytla → cihazlar-arası senkronda yerel dosya olmadan da çalışır) ve `GeminiService.summarizeDocumentText(text, fileName, detailed)` metni gönderiyor. PDF tarafı hâlâ baytları doğrudan gönderiyor (`summarizePdf`'e `detailed` bayrağı eklendi). (3) **Kısa/detaylı seçim**: `ai_sheet.dart`'ta `_pickSummaryDetail()` (SimpleDialog, bool? döndürür) hem PDF hem slayt "Özetle"de çağrılıyor; önbellek anahtarı detaylıda ayrı (`pdf_summary_detailed`/`slide_summary_detailed`) ki iki sürüm birbirini ezmesin. İki ortak istem sabiti: `_shortSummaryPrompt`, `_detailedSummaryPrompt` (detaylı: başlıklara böl, tüm ana bölüm/veri/örnek/sonucu kapsa, sonda "ana çıkarımlar"). Sonucun "Nota ekle"/"Yeni not olarak" düğmeleri ZATEN vardı (`_ResultView` onAppend/onCreateNote, editör callback'leri geçiyor) — ek iş gerekmedi. (4) **TUZAK — not sohbeti (chatAboutNote) slayt eki ile kırılırdı**: not-modu ekleri ham inline_data olarak gönderiyor; pptx mime reddedilir → `doc_chat_screen` not-modu döngüsünde slayt de ses gibi ATLANIYOR (notun metniyle sohbet sürer). (5) Slayt "Sesli dinle" `DocText.extract(localPath)` kullanıyor (PDF listen gibi yerel yola bağımlı, aynı sınır). TUZAK: Flutter SDK bu ortamda YOK → analyze/test çalıştırılamadı; l10n 3 dosyaya elle eklendi (`addSlide`, `summaryDetailTitle`, `summaryShort(+Info)`, `summaryDetailed(+Info)`).

- 2026-07-23: **PDF üzerine elle yazma/çizme (kalıcı, düzenlenebilir katman).** Kullanıcı PDF eklerinin üzerine yazıp çizebilsin, çizim notta kayıtlı kalsın, geri al/silgi olsun istedi. **KARAR (kullanıcı seçti — seçenek 1): çizim PDF dosyasına GÖMÜLMÜYOR, ayrı vektör katmanı olarak saklanıyor.** Gerekçe: PDF yeniden yazılmıyor (dosya bozulma riski yok), çizim her açılışta tekrar düzenlenip silinebiliyor, iş çok daha küçük; bedeli → PDF'i dışa paylaşınca çizim görünmez (yalnız uygulama içi). (1) `Attachment`'a `ink: List<InkStroke>` alanı + `InkStroke` modeli (`page`, ARGB `color`, `width`, düzleştirilmiş `points`); **koordinatlar sayfa boyutunun ORANI (0–1)** — yakınlaştırma/ekran/cihaz değişse de çizgi aynı yere düşüyor, kalınlık da sayfa genişliğinin oranı olarak saklanıyor. `toMap`'te yalnız doluysa yazılıyor (geriye dönük uyumlu, temizleyince alan düşüyor). (2) `pdf_viewer_screen.dart` StatelessWidget→StatefulWidget: pdfrx `pageOverlaysBuilder` ile her sayfanın üstüne `IgnorePointer(ignoring: !_editing)` + `GestureDetector` + `CustomPaint` katmanı kondu — çizim KAPALIYKEN dokunuş geçiyor (PDF normal kayar/yakınlaşır), AÇIKKEN parmağı katman yakalıyor. **`pagePaintCallbacks` yerine overlay CustomPaint seçildi**: çizgiyi kendi setState'imiz anında tazeliyor, viewer'ın sayfa görüntüsü önbelleğine bağımlı değil. Çizim modunda `enableTextSelection: false` (metin seçim katmanı parmağı kapıyordu). (3) Araç çubuğu: kalem/silgi, 6 renk (`kInkPalette` — drawing_screen'deki özel palet ortak sabite taşındı), kalınlık slider'ı, geri al, tümünü temizle. **Silgi = dokunulan ÇİZGİYİ siler** (piksel silme değil; vektör katmanında karşılığı yok, tek dokunuşla temiz sonuç). (4) Kayıt: `AttachmentStrip.onChanged` → editördeki mevcut `_updateAttachment` → Firestore (çizgi bitince, mod kapanınca ve ekrandan çıkarken `PopScope` ile). Nokta seyreltme (0.002 oran altındaki hareketler atlanıyor) → not dokümanı şişmiyor. (5) `pdf_export_screen` önizlemesi `onChanged` geçmiyor → orada çizim düğmesi hiç çıkmıyor (kalıcılığı olmayan çizim gösterilmiyor). Doğrulama: `flutter analyze` temiz, `flutter test` 79/79 (yeni `test/pdf_ink_test.dart` — ink round-trip + temizleme).

- 2026-07-23: **KÖK NEDEN — yerel derlenen APK'da Google girişi çalışmıyor.** Android Google girişi `AppConstants.serverClientId` = `String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID')` ile çalışıyor ve projede `google-services.json` YOK; değer yalnız CI'da `--dart-define=GOOGLE_SERVER_CLIENT_ID=${{ secrets... }}` ile gömülüyor (`.github/workflows/build.yml`). Düz `flutter build apk --release` bu define'ı geçmediğinden `GoogleSignIn.instance.initialize(serverClientId: null)` kalıyor → `authenticate()` hata veriyor. **KURAL: elde APK derlerken MUTLAKA `--dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id>` ver** (aksi halde giriş bozuk çıkar; imza/keystore ile ilgisi yok — yerel `android/key.properties` zaten CI ile aynı jks'i gösteriyor). Client ID'yi bulmanın taşınabilir yolu: yayınlanmış bir APK'nın `lib/arm64-v8a/libapp.so` dosyasında `...apps.googleusercontent.com` dizesini aramak (dart-define AOT snapshot'ına gömülü kalıyor). **AYRICA: GitHub Actions ödeme/limit nedeniyle durdu** — 2026-07-21'den beri tüm run'lar "recent account payments have failed or your spending limit needs to be increased" ile başlamadan düşüyor; yani CI ne test ne APK/Release üretiyor, doğrulama ve telefona kurulum şimdilik yerelden yapılmak zorunda.

- 2026-07-23: **Slayt (.pptx) eki artık gerçek tasarımıyla notta açılıyor + üzerine elle yazma.** İstek: slayt eki açılmıyordu (attachment_strip `_open` slaytta erken dönüyordu); "dosya okuyucu" (Desktop/dosya okuyucu) uygulamasının PPTX çizicisini nota entegre et, slayt slayt gösterilsin, PDF'teki elle yazma katmanı burada da olsun. **KARAR: okuyucunun `pptx_render.dart` (SlideVM/ShapeVM/ParaVM/RunVM üreten motor, ~%80 sadakat — SmartArt/tablo/grafik/gradient/gömülü font ÇİZİLMEZ) + `slide_canvas.dart` widget'ı nota KOPYALANDI** (iki repo ayrı; ortak paket yok, kopya bilinçli — usta 4b istisnası, kaynak okuyucuda kalıyor). Sürüm uyarlaması: okuyucu archive^3+xml^6, not archive^4+xml^7 → archive4 `.content`'i geriye-uyumlu alias olarak tutuyor (derledi), xml 6→7 API sabit; tek elle iş `_fileByName`'de `f.content`→`f.readBytes()` (yeni `slide_deck.dart`'ta). (1) `data/pptx_render.dart` + `presentation/viewers/slide_canvas.dart` kopyalandı (import yolu + withOpacity→withValues + `(_,__,___)`→`(_,_,_)` info düzeltmeleri, bu projede tek info bile CI'ı düşürür). (2) `data/slide_deck.dart`: baytlardan `List<SlideVM>` üretir (`compute` ile arka planda unzip+parse; slayt sırası `p:sldIdLst`→yoksa dosya no); okuyucunun `pptx_editor`'ından yalnız sıralama+rel çözümü alındı, düzenleme motoru ALINMADI (nota salt görüntüleme yetiyor). (3) `presentation/viewers/slide_viewer_screen.dart` (ConsumerStatefulWidget): `attachmentRepositoryProvider.readBytes` ile bayt (yerel→yoksa Storage), `PageView` + her slayt `AspectRatio(widthPt/heightPt)` içinde `Stack(SlideCanvas + InkPageLayer)`. (4) **Çizim katmanı ORTAKLAŞTIRILDI**: PDF ekranındaki inline çizim mantığı `presentation/viewers/ink_layer.dart`'a çıkarıldı — `InkController(ChangeNotifier)` + `InkPageLayer` + `InkToolbar` + `InkPainter`; hem `pdf_viewer_screen` hem `slide_viewer_screen` bunu kullanıyor (kopya kod yok). Tek-parmak-çizer/iki-parmak-kaydırır kilidi: PDF'te `panEnabled:!lockPan`, slaytta `physics: lockPan?NeverScrollable:PageScroll`. (5) `attachment_strip._open` switch'e çevrildi: pdf→PdfViewer, slide→SlideViewer, diğer→ImageViewer; slayt "açılmıyor" tuzağı kalktı. TUZAK: `ZipEncoder().encode` archive4'te `List<int>` döner, `SlideDeck.fromBytes(Uint8List)` için testte `Uint8List.fromList(...)` sarmak gerekti. Doğrulama: analyze temiz, `flutter test` 81/81 (yeni `test/slide_deck_test.dart` bellek-içi gerçek pptx render smoke — archive/xml sürüm kırılırsa düşer). SINIR: slaytta tablo/grafik/SmartArt boş görünür; yakınlaştırma yok (slayt ekrana sığdırılır).

- 2026-07-23: **Slaytta yakınlaştırma + beyaz kalem; tablo zaten çiziliyordu.** 3 istek. (1) **Zoom**: `slide_viewer_screen`'de her slayt `InteractiveViewer` içine alındı — çizim katmanı (InkPageLayer) IV'nin İÇİNDE, birlikte ölçeklendiğinden çizim zoom'da hizalı kalır (Listener'ın localPosition'ı IV tarafından dönüştürülmemiş çocuk uzayında gelir, oran doğru). Jest modeli: `TransformationController _zoom` yalnız GÖRÜNEN slayda bağlı (`isCurrent ? _zoom : null`), ölçek>1.02 → `_zoomed`; `panEnabled = editing ? !lockPan : (isCurrent && _zoomed)` — çizimde tek parmak çizer/iki parmak yakınlaştırır, normalde yakınken kaydırır, uzakken pan kapalı ki PageView slaytı geçirsin (IV pan'ı scale=1'de bile arena'yı kapıp paging'i bloke ediyordu — kök neden buydu). PageView physics `lockPan || _zoomed` iken kilitli; slayt değişince `_zoom` identity'ye sıfırlanır. (2) **Beyaz kalem**: `kInkPalette`'e `Colors.white` eklendi (koyu slayt/PDF üstüne; beyaz zeminde görünmez — normal). InkToolbar renk noktalarına seçili değilken de ince `outlineVariant` çerçeve verildi ki beyaz açık toolbar'da kaybolmasın. (3) **Tablo**: kopyalanan motorda `_table` (a:tbl→hücre başına ShapeVM: dolgu/kenarlık/metin) ZATEN çalışıyordu; boş görünen slaytlar grafik(chart)/SmartArt. Kullanıcı "şimdilik tablo yeter" dedi → grafik çizimi YAPILMADI (ayrı büyük iş: chart XML seri/eksen ayrıştırma). Yalnız yanıltıcı başlık yorumu düzeltildi. Doğrulama: analyze temiz, 81/81 test.

- 2026-07-23: **KÖK NEDEN — PDF/slaytta çizim modunda iki parmak yakınlaştırma/kaydırma çalışmıyordu.** İki ayrı hata, tek kökene yakın. (1) **PDF**: `panEnabled`'ı parmak sayısına göre canlı değiştiriyordum (`!lockPan`). pdfrx'te `PdfViewerParams.doChangesRequireReload` LİSTESİNDE `panEnabled` VE `enableTextSelection` var → ikisi değişince görüntüleyici belgeyi yeniden yükler. İkinci parmak inince panEnabled false→true olunca pdfrx HAREKET ORTASINDA yeniden kuruluyor, jest ölüyordu ("yazarken yakınlaştıramıyorum"). ÇÖZÜM: paramlar artık YALNIZ çizim modu açılıp kapanınca değişir (`panEnabled:!_editing`, `enableTextSelection:!_editing`, ekran `_editing` state + setState). Çizimde `panEnabled:false` ama `scaleEnabled` varsayılan AÇIK → tek parmak çizer, İKİ PARMAK YAKINLAŞTIRIR (scale jesti panEnabled'dan bağımsız). İki parmak serbest KAYDIRMA (pan) çizimde yok (panEnabled false) — bilinçli sınır; yakınlaştırma yeter, kaydırmak için "bitir"e bas. Çizim modu değişmeden hiç reload olmadığından jest bozulmaz. (2) **Ek: görüntüleyiciyi çizgi başına yeniden kurma**: eskiden tüm PdfViewer/SlideCanvas `ListenableBuilder(_ink)` içindeydi → her pointerMove/nokta bütün görüntüleyiciyi rebuild ediyordu (pdfrx'te reload'la birleşince felç). ÇÖZÜM: çizgiler artık `InkPageLayer` İÇİNDEKİ küçük `ListenableBuilder`'da bağımsız tazeleniyor; görüntüleyici (PDF/SlideCanvas) rebuild olmuyor. `InkToolbar` da kendi ListenableBuilder'ında. (3) **Slaytta pinch sırasında sayfa sağa/sola kayıyordu**: PageView'in yatay drag recognizer'ı InteractiveViewer'ın scale'iyle arena'da çekişiyordu. ÇÖZÜM: üst düzey HEP AKTİF `Listener` parmak sayar (`_touch`); `lockPage = _editing || _zoomed || _touch>=2` → iki parmak iner inmez PageView kilitlenir, pinch slaytı kaydırmaz. `_touch` yalnız çizim KAPALIYKEN setState eder (çizimde zaten kilitli, çizgi başına rebuild olmasın). Slaytta `panEnabled = !_editing && isCurrent && _zoomed` (uzakken pan kapalı ki PageView kaysın, yakınken kaydır), scaleEnabled açık. InkController'dan `lockPan`/`toggleEditing` kaldırıldı, `setEditing(bool)` eklendi. Doğrulama: analyze temiz, 81/81 test. SINIR: çizim modunda iki parmak serbest kaydırma yok (yalnız yakınlaştırma) — hem PDF hem slaytta.

- 2026-07-24: **7 maddelik paket (kullanıcı listesi, tamamı) — main'e merge edildi.** (1) **KÖK NEDEN — çizim modunda iki parmak KAYDIRMA hiç çalışmıyordu** (zoom da güvenilmezdi): hem Flutter hem pdfrx InteractiveViewer'ı, mesafesi değişmeden birlikte hareket eden iki parmağı `_getGestureType`'ta "pan" sayar ve `panEnabled:false`'ta (çizim modu) JESTİ TÜMDEN YUTAR — scale jestindeki odak-takibi pan'ı yalnız ölçek değişirken çalışır. ÇÖZÜM: `InkNavLayer` (ink_layer.dart) — jest arenasına girmeyen Listener tüm parmakları sayar, iki parmak inince `InkController.beginNav()` (başlamış çizgi geri alınır, sayfa katmanı çizimi askıya alır) ve odak/mesafe farkından matrisi KENDİSİ sürer: PDF'te `PdfViewerController.value` (setter zaten normalize ediyor; üst sınır maxScale=8 katmanda), slaytta `TransformationController` + katman içi clamp (IV sınır denetimi doğrudan controller yazımında çalışmaz). Çizim modunda görüntüleyicinin panEnabled VE scaleEnabled'ı kapalı — jest çifte işlenmez. TUZAK: nav parmaklarından biri sayfa DIŞINA (kenar boşluğu) düşerse sayfa katmanı onu hiç görmez; bu yüzden parmak sayacı sayfa katmanında değil, görüntüleyiciyi saran nav katmanında. (2) **Senkron limiti**: `syncLimitMbProvider` (5/10/25/50/sınırsız, varsayılan 25 MB; Ayarlar>Senkronizasyon) — UploadQueue sınırı aşan eki yüklemez (cihazda kalır), sınır yükselince listener hemen yeniden işler. Ayrıca başarısız yüklemeye 1 dk geri-çekilme eklendi (her tuş vuruşunda retry fırtınası ağ/pil yakıyordu). (3) **Serbest tuval TAM SAYFA oldu (yalnız saf metin notu)**: `NotePageCanvas` (note_images.dart) — görseller (el yazısı çizimleri de görsel ek) başlık+gövde içeriğinin ÜZERİNDE yüzer, sayfayla kayar, metnin sağına/soluna sürüklenir; sayfa en alttaki görseli kapsayacak kadar uzar. KARAR: dikey konum yeni `Attachment.pageY` alanında MUTLAK dp (sayfa yüksekliği metinle değiştiğinden oran tutulamaz); eski `y` oranı ilk açılışta 440dp tuval varsayımıyla çevrilir, x oran olarak ortak. Liste tipleri (ItemsEditor ReorderableListView — Stack'e sarılamaz) eski kutu tuvalde kaldı. Boş alana dokunma → önce seçim kalkar, seçim yoksa gövdeye odak (onTapEmpty). (4) **Dışa aktarma**: PDF'e görseller gömülür (ExportImage; sayfaya sığdırılır — MultiPage taşan tek parçayı bölemez, yükseklik sınırı şart) + **Word (.docx) YENİ BAĞIMLILIKSIZ**: docx = zip+XML → `NoteDocx` (note_docx.dart) mevcut `archive` paketiyle üretir, satır yapısı `NotePdf.parseLines` ile ORTAK (@visibleForTesting kaldırıldı), görseller word/media'ya gömülü (EMU=px*9525, 15,2cm tavan). (5) **Performans/pil**: tema saati `_clockProvider` autoDispose (zamanlama kapalıyken dakikalık timer tümüyle durur; effectiveThemeMode de autoDispose olmak ZORUNDA — autoDispose olmayan autoDispose'u izleyemez), Kotlin RMS olayları <0.04 farkta gönderilmez (saniyede 10-20 olay → kanal+rebuild seli), görsel decode hedefleri: kart/şerit küçük resmi 480/420px, tuval görseli ekran genişliği×dpr (2048px'lik ekin tam boy decode'u kaydırma takılmasının kaynağıydı). (6) **"Sesle yazma çalışmıyor / yapay zeka isteği başarısız" KÖK NEDENİ İKİ AYRI HATA**: (a) satır-içi dikte/asistan/çevirmen mikrofon İZNİ HİÇ İSTEMİYORDU — SpeechRecognizer izin yokken sistem kutusunu açmaz, sessizce ERROR_INSUFFICIENT_PERMISSIONS düşer (eski alt sayfa yolu izni record'un hasPermission'ından alıyordu, yeni doğrudan yol bunu atlamıştı) → `DeviceSpeech.ensureMicPermission()` (record.hasPermission — yeni bağımlılık yok) 4 başlangıç noktasına eklendi; (b) cihaz tanıma hatası kullanıcıya `aiError` ("yapay zeka isteği başarısız") olarak gösteriliyordu — AI ile ilgisi yok, yeni `speechRecognitionFailed` mesajı. (7) **Keep tarzı sesli not**: + menüsünde "Sesli not" → `/note/:id?voice=1` → editör kayıt (m4a 48kbps mono) + canlı dikte AYNI ANDA başlatır; durunca ses `prepareAudio` ile ek olur, döküm notta. SIRA BİLİNÇLİ: önce tanıyıcı sonra kayıt — mikrofonu paylaşamayan cihazda SONRA başlayan kazandığından ses dosyası asla sessiz çıkmaz (dökümün durması görünür eksik, sessiz dosya gizli kayıp olurdu). Ekrandan kayıt sürerken çıkılırsa `_finishVoiceCaptureDetached`: provider'lar dispose içinde senkron okunur, ek `NotesRepository.appendAttachment` (yeni; transaction'la güncel listeye ekler) ile bağlanır; boş-not silme adımı bu durumda atlanır (ek yazılana dek not "boş" görünür). DOĞRULAMA SINIRI: bu ortamda Flutter yok — analyze/test çalıştırılamadı, CI da Actions ödeme sorunu nedeniyle kapalı; ilk yerel derlemede doğrulanmalı.

- 2026-07-24: **Metin sarması (Word tarzı), Firebase AI dayanıklılığı, ağırlıklı AI kotası.** (1) **KÖK NEDEN — görseller metnin/başlığın üzerine biniyordu**: `NotePageCanvas` görselleri Stack'te mutlak konumlu çiziyor, gövde metni altında akışına devam ediyordu; hiçbir çakışma denetimi yoktu. Kullanıcı "gerçek sarma" (Word) istedi. **ÖLÇÜM (tercih değil, kısıt):** Flutter'ın satır kırıcısında dışlama alanı (exclusion rect) YOK — bir paragrafın her satırı aynı genişlikte kırılır; `RenderEditable`'ın TextPainter'ı enjekte edilemez. İki gerçek yol vardı: kendi dizgicimizi yazmak (imleç/seçim/IME/kopyala-yapıştır elle → 3-4 oturum, düzenleyicide regresyon riski) ya da satır başlarına görünmez dolgu. **KARAR: dolgu yolu** (`text_wrap.dart`) — görselin kestiği satırların başına genişliği kadar `WidgetSpan` konur, kırıcı kalan yere göre kırar, dizgi Flutter'da kalır. **KRİTİK TUZAK:** dolgu metin uzayında GERÇEK bir karakter olmak ZORUNDA (U+FFFC): `buildTextSpan`'in ürettiği span'in düz metni `controller.text` ile birebir aynı uzunlukta olmazsa `getOffsetForCaret` kayar ve imleç/seçim bozulur — "görünmez dolgu ekle" yaklaşımının naif hâli tam burada ölüyor. Çapalar yalnız düzenleme tamponunda yaşar; **tek boğaz noktası `_mutate`** (her çağrı yerine ayrı koruma koymak yerine) `stripWrapAnchors` ile temizler, böylece nota/AI'a/dışa aktarmaya asla sızmaz. Satır indeksleri gerçek `LineMetrics`'ten okunur (sabit satır yüksekliği varsayımı yok). Sütunun %70'inden fazlasını kaplayan görsel `blocking` sayılır: dolgu satırın TAMAMINI yer, o satıra kelime sığmaz ve metin görselin ALTINA iner (yanına sıkıştırılmaz) — döngü her turda bir satır yüksekliği ilerlediği için görselin altında biter. **BİLİNEN SINIR (KALANLAR.md'de):** sağ kenardaki görselin yanından metin akmıyor; sağdan daraltma satır SONUNA dolgu koymayı gerektirir, kırıcı o dolguya sıra gelmeden satırı zaten kırar — çözümü yalnız kendi satır kırıcımız. Ayrıca sarma etkinken IME oluşturma aralığı (altı çizili tahmin) gösterilmiyor (çapalar konumu kaydırıyor). Sarma planı gövde TextField'ının stiliyle BİREBİR aynı stille hesaplanmak zorunda — bu yüzden `style:` artık örtük bırakılmıyor, açıkça `bodyLarge` veriliyor (ölçüm/çizim ayrışırsa satırlar yanlış kırılır). Görseller `topLimit` (başlık+çip yüksekliği, `KeyedSubtree` ile ölçülür) altına inemez; taşıma tek jeste indi (`onLongPress*`), sürükleme başlangıcı `_moveOrigin*`'de AYRI tutulur çünkü `_resolve` taşıma sırasında canlı değeri döndürür ve onu baz almak hareketi katlıyordu. (2) **KÖK NEDEN — "Firebase AI bazen çalışıyor bazen çalışmıyor"**: `_withModel` geçici hatada (overloaded/unavailable/503/429/soket) beklemeden SIRADAKİ MODELE atlıyordu; arka uç meşgulken üç modelin üçü de saniyeler içinde tükenip istek düşüyordu. Model değiştirmek yük hatasının çaresi değil. ÇÖZÜM: `_isTransient` ayrımı — geçici hatada AYNI model üstel geri çekilmeyle (400ms, 1200ms) yeniden denenir, model geçişi yalnız kalıcı hatalarda (not found/quota) olur; istek zaman aşımı 90 sn (sınırsız bekleyiş kullanıcıyı süresiz çarkla bırakıyordu). Ayrıca `_mapError` ham hatayı yutup sade Türkçe mesaj döndürdüğü için teşhis imkânsızdı → `AiDiagnostics` son 10 ham hatayı (model + zaman + metin) tutuyor, Ayarlar > AI tanılama gösteriyor. **NOT: `firebase_app_check` paketi kurulu (firebase_ai'ın bağımlılığı) ama Dart'ta HİÇ aktive edilmemiş** — konsolda AI Logic için App Check zorunluysa 403 gelir ve "bu sürümde etkinleştirilmemiş" mesajına dönüşür; tanılama çıktısı bunu doğrulayacak. Model ID'lerinin üçü de (3.1-flash-lite, 3.5-flash, 2.5-flash) Gemini API'de MEVCUT — canlı doğrulandı, sorun model listesinde değil. (3) **AI maliyeti çağrı değil PUAN sayıyor**: eski sayaç 100 sayfalık PDF özetiyle başlık üretimini aynı "1 hak" sayıyordu — faturayı öngörülemez kılan asıl şey buydu. Puan isteğin İÇERİĞİNDEN ölçülür (`AiCost.forContents`: görsel +3, belge +10, her 4000 karakter +1), böylece çağrı yerlerinin doğru puanı geçmesi beklenmez ve yeni AI özelliği eklendiğinde kota kendiliğinden doğru çalışır. Sayaç SharedPreferences'tan Firestore `users/{uid}.aiUsage`'a taşındı (uygulama verisi silinince sıfırlanmıyor, cihazlar ortak); yerel sayaç çevrimdışı yedek olarak kaldı. **TUZAK:** işlem (transaction) tavan aşımında sayacın kendisini döndürünce yerel yedek kontrol hakkı geçiriyordu → ayrı `_remoteDenied` (-1) sentineli. `firestore.rules` aynı gün içinde `aiUsage.points`'in AZALMASINI engelliyor (gün değişince serbest sıfırlanır); gerçek zorlama için sunucu tarafı (Cloud Functions + App Check) hâlâ gerekli. Bütçe: ücretsiz 30, premium 300 puan/gün. (4) **Yerel APK kurulumu**: `flutter install` her seferinde ÖNCE KALDIRIYOR (uygulama verisi gidiyor); `adb install -r` aynı imzayla üstüne kurar ve veriyi korur — bundan sonra bu kullanılacak. DOĞRULAMA: `flutter analyze` temiz, `flutter test` 93/93 (yeni `text_wrap_test.dart` + `ai_cost_test.dart`); sarmanın CİHAZDAKİ görsel davranışı ve AI tanılama çıktısı kullanıcı tarafından denenecek.

- 2026-07-24: **Sağ kenar sarması, tam ekran görselde elle yazma, imleç kök nedeni, liste modunda sarma.** (1) **SAĞ KENAR SARMASI ÇÖZÜLDÜ — "kendi satır kırıcımızı yazmak şart" varsayımı yanlıştı**: satır SONUNA dolgu koymak, dolgudan önce bir KELİME BİRLEŞTİRİCİ (U+2060 WORD JOINER, `kWrapGlueChar`) yazılınca çalışıyor — birleştirici kendinden önce/sonra kırılmayı yasakladığı için kırıcı dolguyu bir alt satıra kaçıramıyor, dolgu satırın son kelimesine yapışıyor ve kalan kelimeler alt satıra iniyor. Dolgunun gireceği yer `getPositionForOffset(limitX)` ile bulunup kelime başına geri sarılarak seçilir (kelime bölünmez). `FloatBox` artık `width`+`blocking` yerine sütun uzayında `left`/`right` taşıyor; metin görselin GENİŞ tarafından akar (`spaceRight >= spaceLeft` → satır başı dolgusu, aksi hâlde satır sonu dolgusu), kalan yer sütunun %25'inin altına düşerse satır tümüyle boşaltılır (metin görselin altına iner) — eski %70 `blocking` eşiği kalktı. TUZAK: aynı satıra ikinci kez dolgu denenmemesi için `rightPadded` satır kümesi tutulur; yoksa kırıcı dolguyu yapıştıramadığında sonsuz döngü olurdu. İmleç eşlemesi de ikiye ayrıldı: satır BAŞI dolgusunun ARDINA geçilir, satır SONU dolgusunun ÖNÜNDE kalınır (ayrım birleştiricinin varlığından anlaşılır) — yoksa imleç son harften sonra sütunun sağ kenarına atlardı. (2) **KÖK NEDEN — imleç görselin üstünde/solda yanıp sönüyordu**: `planTextWrap` `logical.isEmpty` ile ERKEN DÖNÜYORDU; boş satırda hiç çapa olmayınca imleç sütunun en solunda, yani soldaki görselin ÜZERİNDE kalıyordu. Boş tamponun `computeLineMetrics()`'i boş liste döndürdüğü için satır yüksekliği `painter.preferredLineHeight`'tan alınıp ilk satıra çapa konuyor; sonuç: kullanıcı yazmaya başlamadan da imleç görselin sağında. YAN ETKİ (kabul edildi): soldaki görsel varken gövde boşken ipucu metni (`hintText`) görünmez, çünkü tampon artık boş değil. (3) **TAM EKRAN GÖRSELDE ELLE YAZMA**: yeni bir altyapı YAZILMADI — PDF/slaytın `InkController`+`InkPageLayer`+`InkToolbar`+`InkNavLayer` dörtlüsü `ImageViewerScreen`'e (page=1) bağlandı, çizim ekin `ink` alanına gidiyor (dosyaya gömülmez, notla senkron). Çizim katmanı görselin en-boy oranındaki kutuya oturtulur (`AspectRatio`) — oranlı noktalar ancak o zaman yakınlaştırmada da hizalı kalır; oranı bilinmeyen eski ekte kare varsayılır. Çizim nottaki küçük görselin üstünde de `InkPainter` ile çizilir (yoksa "kayboldu" görünüyordu). `AttachmentStrip`'ten açılan görsel de artık düzenlenebilir. (4) **LİSTE MODUNDA DA SARMA**: `NoteImages` (başlık altındaki küçük kutu tuval) TÜMÜYLE SİLİNDİ — artık her not tipi `NotePageCanvas` (tam sayfa serbest katman) kullanıyor; `ItemsEditor` dış kaydırıcının içinde `shrinkWrap:true` + `NeverScrollableScrollPhysics` ile duruyor ("ReorderableListView Stack'e sarılamaz" eski kaydı böylece geçersiz). KARAR: koordinat çevirisi çağıranlardan alınıp yeni `WrapFieldMeasure`'a taşındı — her metin alanı kendi konumunu/genişliğini sayfa köküne göre ÖLÇER ve sayfa uzayındaki bantları kendi uzayına çevirir; böylece gövde metni ve her liste maddesi aynı yolu kullanır, kenar boşluğu (`_kGutter`) hesabı koddan silindi. `NotePageCanvas.onFloats` artık sayfa uzayında bildiriyor. Madde denetleyicileri `WrapTextController` oldu (`onChanged` → `logicalText`), madde stili örtük varsayılan yerine açıkça `bodyLarge` (ölçüm/çizim ayrışmasın). TUZAK: son görsel silinince tuval erken dönüp bantları bildirmediği için metin olmayan bir görselin etrafından akmaya devam ediyordu → boş dalda da `_reportFloats(0)`. DOĞRULAMA: `flutter analyze` temiz, `flutter test` 101/101 (yeni `items_editor_wrap_test.dart`, `image_ink_test.dart`, genişletilen `text_wrap_test.dart`). SINIR: `flutter` bu makinede `C:\src\flutter\bin` altında (PATH'te değil).

- 2026-07-24 (ikinci paket): **KÖK NEDEN — `dispose()` içinde `ref` kullanmak istisna atıyor.** Sonda testiyle ÖLÇÜLDÜ: bu Riverpod sürümünde `ConsumerState.dispose` içinde `ref.read` → "Using ref when a widget is about to or has been unmounted is unsafe". Editörden ÇIKARKEN çalışan her şey bu yüzden sessizce ölüyordu: boş notun silinmesi, otomatik etiket, **otomatik başlık** (kullanıcı "çalışmıyor" dedi), sürmekte olan sesli notun kaydı (`_finishVoiceCaptureDetached` — HAFIZA'daki eski "provider'lar dispose içinde senkron okunur" notu YANLIŞ, o kod hiç çalışmamış). Aynı hata `listen_screen`'de de vardı (ekrandan çıkınca sesli okuma durmuyordu). ÇÖZÜM: gereken bağımlılıklar her `build`'de alanlara alınır (`_cacheDeps`), `dispose` yalnız alanları kullanır. **KURAL: bundan sonra hiçbir `dispose`'da `ref` kullanılmayacak.** (2) **(+) menüsündeki "Sesli not" hiç başlamıyordu**: açılış niyeti ilk karede çalışıyor, yeni oluşturulan not dashboard önbelleğinde olmadığı için `_note` null ve `_startVoiceCapture` SESSİZCE dönüyordu. Niyet artık beklemede tutulup not gelince çalışır (`_pendingDraw/_pendingVoice/_pendingVideo` + `_runPendingIntents`). (3) **Liste modunda madde eklerken titreme**: satır kaydırması (`_FloatRow`) yerleşimden SONRA ölçülüp uygulanıyordu; yeni satır artık KOMŞUSUNUN kaydırmasıyla doğar (`_pads` önbelleği), ölçüm yalnız düzeltir. (4) **Görsel eklenince notun üzerine düşüyordu**: konum/boyut verilmediğinden tuval sol üste, sayfanın yarısı genişliğinde koyuyordu → yeni görsel %32 genişlikle mevcut içeriğin ALTINA yerleşir (`_placeNewImage`). (5) **Satır başında geri silme çalışmıyordu** (kullanıcı: "silme sadece o satırı siliyor, üst satıra geçmiyor"): imleç satır başı dolgusunun ardında olduğundan geri silme gerçek metni değil DOLGUYU siliyor, dolgu bir sonraki dizgide geri geliyordu. `WrapTextController.value` artık "mantıksal metin değişmeden tampon kısaldıysa" durumunu yakalayıp önceki karakteri siler (satırlar birleşir). (6) **PDF dışa aktarma düzeni**: görseller metnin SONUNA yığılıyordu; artık her görsel nottaki satırına girer (metin notunda TextPainter ile birebir hesaplanır, liste notunda oranla), genişliği nottaki oranı, hizası nottaki x'i izler. Düzen bilgisi editörden `PdfExportScreen(layout:)` ile gelir; paylaş menüsünden açılırsa eski davranış sürer. (7) **Görüntülü not (video)**: `AttachmentKind.video`, `prepareVideo` (yalnız yerel kopya), UploadQueue + `upload()` içinde ÇİFT kapı ile buluta hiç gitmez, `video_player` ile uygulama içi oynatma, (+) menüsü ve ek menüsünde giriş, `?video=1` yolu. Süre sınırı 60 sn — AI'a satır içi gönderilebilmesi için. (8) **AI videodan not**: `GeminiService.noteFromVideo` (görüntü+ses birlikte; Özet/Görülenler/Konuşulanlar/Yapılacaklar), ek kartındaki "Videodan not çıkar" düğmesi; kota puanı `AiCost` tarafından belge gibi (10) sayılır. (9) **İzinler**: manifest'e CAMERA + `uses-feature required=false`, MainActivity'ye `cameraPermissionGranted`/`requestCamera` köprüsü (+`onRequestPermissionsResult`), Ayarlar > İzinler'e kamera satırı, ilk açılışta tek seferlik izin tanıtımı (`PermissionsOnboarding`, SharedPreferences `perms_onboarded`; bayrak ekran AÇILIRKEN yazılır ki kullanıcı kapatsa da tekrar çıkmasın). TUZAK: manifest'te CAMERA bildirilince Android çekim niyetini izin olmadan reddediyor, bu yüzden `_addVideo` çekimden önce izni kendisi ister. DOĞRULAMA: `flutter analyze` temiz, `flutter test` 105/105, imzalı APK `adb install -r` ile cihaza kuruldu (veri korundu).

- 2026-07-25: **AI geri bildirimi, video akışı ve çip görünürlüğü.** (1) **KÖK NEDEN — "AI çalışıyor mu belli değil"**: uzun AI işleri (OCR, videodan not, etiket önerisi) tek bir SnackBar gösterip sessizleşiyordu; SnackBar kaybolunca kullanıcı çalışıp çalışmadığını anlamıyor, dakikalar sonra gelen hatayı da bağlayamıyordu. ÇÖZÜM tek giriş noktası: `_runAi(label, body)` — editörün altında iş bitene kadar duran canlı şerit (`_AiBanner`, LinearProgressIndicator), aynı işin ikinci kez başlatılmasını engelleme ve TEK biçimli hata bildirimi. Yeni AI özelliği eklerken gösterge ayrıca düşünülmeyecek; OCR + videodan not + etiket önerisi bu yoldan geçiyor ("Başlık öner" zaten kendi çarkını gösteriyordu, ai_sheet kendi yükleniyor görünümüne sahip). (2) **Video AI'da sessiz başarısızlık**: satır içi gönderim sınırı aşılınca hata dakikalar sonra geliyordu → istek ÖNCESİ 15 MB denetimi ve anlaşılır mesaj (`videoTooBigForAi`). (3) **AI çıktısı artık doğrudan nota YAZILMIYOR**: yeni `showAiResultSheet` (ai_result_sheet.dart) geniş, düzenlenebilir bir alanda gösterir; biçim düğmesi metni düz metin / "- " madde / "1. " sıralı biçimine çevirir (satır başı işaretleri `_bare` ile temizlenir, üst üste binmez), sonra "Nota ekle" ya da "Yeni not olarak" (seçilen tiple) uygulanır. KARAR: dönüşüm METİN üzerinde yapılır — dışa aktarma (NotePdf.parseLines) ve liste editörüyle aynı dili konuşur. (4) **Video "senkron ediliyor" görünüyordu**: ek kartındaki "yükleme sürüyor" çarkı `!isUploaded && hasLocal` koşuluyla çiziliyordu; video hiç yüklenmediği için sürekli dönüyordu → video bu göstergeden muaf. (5) **Çip barında etiket/klasör gizleme**: `showTagChipsProvider` / `showFolderChipsProvider` (SharedPreferences), "Filtreleri düzenle" sayfasına iki anahtar; hem kompakt satır hem genişletilmiş panel bunları izler. DOĞRULAMA: `flutter analyze` temiz, `flutter test` 108/108 (yeni `ai_result_sheet_test.dart`), imzalı APK `adb install -r` ile kuruldu.

- 2026-07-25: **KÖK NEDEN — izin VERİLMİŞKEN "Mikrofon izni verilmedi" ((+) menüsü → Sesli not)**: `DeviceSpeech.ensureMicPermission()` doğrudan `record` eklentisinin `hasPermission()`'ını çağırıp altındaki `catch (_) { return false; }` ile HER hatayı "izin yok"a katlıyordu. İki ayrı yalan kaynağı: (a) record 7.1.1'de `hasPermission()` önce `_safeCall` içinde `await _createFuture` yapar — eklenti `create`'i patlarsa istisna fırlar ve catch onu "izin yok"a çevirir; (b) eklentinin `PermissionManager.hasPermission`'ı `activity == null` iken izni hiç OKUMADAN düz `false` döner. TANI KANITI: cihazda `dumpsys package` → `RECORD_AUDIO: granted=true`, ve `notlar://voice` (ana ekran sesli asistanı) logcat'te SODA tanıyıcıyı sorunsuz açıyordu — yani izin değil, ölçüm yolu bozuktu. ÇÖZÜM: `ensureMicPermission()` artık ÖNCE zaten var olan `micPermissionGranted` MethodChannel'ını (MainActivity, `checkSelfPermission` — sistem kutusu açmaz, eklentiye/activity'ye bağlı değil) okur; verilmişse `AudioRecorder`'a hiç dokunmadan true döner, yalnızca izin gerçekten yoksa eklenti yoluna düşer (kutuyu açması gereken tek durum). Paylaşılan fonksiyon olduğu için editör diktesi, sesli asistan ve çeviri ekranı da aynı anda düzeldi. GENEL DERS: `catch (_) => false` "ölçemedim"i "negatif" diye raporlar — tetkik hatasıyla gerçek negatif ayrılmalı. DOĞRULAMA: `flutter analyze` temiz, imzalı APK `adb install -r` ile kuruldu; (+) → Sesli not uçtan uca cihazda DENENMEDİ (telefon kilitliydi), kullanıcı testi bekliyor.

- 2026-07-25 (2. tur — sesli notun ASIL kök nedeni; yukarıdaki mikrofon-izni maddesini TAMAMLAR, o düzeltme doğruydu ama şikâyetin sebebi değildi): **KÖK NEDEN — "(+) → Sesli not"ta ses kaydı boş çıkıyordu**: bu mod aynı anda hem canlı dikteyi (Android SpeechRecognizer) hem kendi `AudioRecorder`'ımızı açıyordu. Android'de **tek mikrofonu SON açan istemci alır**; tanıyıcı mikrofonu ASENKRON (~250 ms gecikmeyle) açtığından "sonra başlayan" hep o oluyor ve bizim kaydımız anında susturuluyordu. ÖLÇÜM (logcat): 9.4 saniyelik kayıtta `MPEG4Writer: encoded 6 frames`, dosya 4267 bayt ≈ 0.14 sn ses. Koddaki eski varsayım ("önce döküm sonra kayıt → sonra başlayan kazanır, kayıt güvende") tam TERSİNE işliyordu; korkulan "sessiz dosya = gizli veri kaybı" birebir gerçekleşmişti. Bu cihaza özel değil, Android 10+ tasarım kısıtı. ÇÖZÜM (Keep'in yaptığının aynısı): kendi mikrofon istemcimizi hiç açma — Google'ın sesli giriş EKRANINI `ACTION_RECOGNIZE_SPEECH` + belgesiz `android.speech.extra.GET_AUDIO` ile çağır; dönüşte hem metin hem Google'ın KENDİ kaydettiği AMR gelir (`content://com.google.android.tts.AudioRecordingProvider/...`, önbelleğe kopyalanır). Tek mikrofon istemcisi Google olduğu için çakışma doğmuyor. `MainActivity.voiceInputWithAudio` köprüsü + `DeviceSpeech.voiceInputWithAudio`; editördeki çift-mikrofon makinesi (`_captureRecorder`/`_voiceCapturing`/`_stopVoiceCapture`/`_finishVoiceCaptureDetached`, durdurma şeridi, çıkışta-kurtarma) TÜMÜYLE SİLİNDİ (~130 satır → 55). BEDEL (bilinçli, Keep'te de aynı): canlı yazım yok (metin bitişte düşer), ses telefon kalitesi (AMR-NB), duraklayınca oturum biter. TUZAK: `GET_AUDIO` belgesiz — Google vermeyi keserse `audioPath` null gider ve akış yalnız metinle sürer (çökmez); Play politikası açısından sorun yok (gizli API değil, intent ekstrası). Süre bilgisini Google vermediği için dosya boyutundan kestiriliyor (~1.6 KB/sn). AYRICA bu turda düzeltilen ikinci gerçek bug: tanıyıcı sessizlikte kendini yeniden kurarken YENİ örnek ölmekte olan servise bağlandığı için anında `ERROR_SERVER_DISCONNECTED` (11) alıyor ve bu, gerçek hata sanılıp dikteyi öldürüyordu ("Konuşma tanıma çalışmadı"); 11 artık yutuluyor (yeniden başlatılMIYOR — 11'in kendisi yeniden kurulumun ürünü, restart sonsuz döngü olurdu). YANLIŞ YOL (denendi, ölçümle elendi): hatanın ESKİ (destroy edilen) tanıyıcıdan geldiği varsayılıp kuşak/generation koruması yazıldı — `stale` logu hiç düşmedi, hata güncel örneğe geliyormuş; kod geri alındı. DOĞRULAMA: `flutter analyze` temiz, `flutter test` 108/108, imzalı APK cihaza kuruldu ve UÇTAN UCA denendi → `NotlarSpeech: sesli giris text=31 audio=true`, istisna yok.

- 2026-07-25: **KARAR — dashboard'da uzun basış artık HER ZAMAN seçer; elle sıralama ⋮ menüsüne taşındı**: eskiden uzun basış `LongPressDraggable`'ı başlatıyor, toplu seçim ise yalnızca parmak 24 px'den az oynatılıp bırakılınca (`onDraggableCanceled` + `_pressStart` mesafe ölçümü) gerçekleşen bir YAN ÜRÜNdü — kullanıcı seçmek isterken kartı kazara taşıyordu. Tek jestin iki işe hizmet etmesi (Keep'ten esinlenen özgün tasarım) pratikte seçimi kazara taşımaya çeviriyordu. YENİ: uzun basış = seçim (sade `GestureDetector`); sürükle-sırala `reorderModeProvider` ile açılan ayrı bir mod (⋮ → "Notları sırala" → üstte "Bitti" barı). Mesafe ölçüm mantığı SİLİNDİ, `_ReorderableNoteCell` StatefulWidget'tan StatelessWidget'a indi. İKİ ALT KARAR: (1) menü maddesi arama/filtre/klasör/etiket aktifken GİZLENİR — elle sıra alt kümede anlamsız (yalnız görünen notların orderIndex'i değişir), tıklanıp "neden olmuyor" denmesin; (2) mod açıkken çip'e dokunulup filtre değişirse mod KENDİLİĞİNDEN kapanır (`reorderActive` süzgeç koşullarını da içerir) — aksi hâlde bar durur ama kartlar sürüklenmez, bozuk görünürdü. DOĞRULAMA: `flutter analyze` temiz, `flutter test` 108/108, imzalı APK kuruldu, kullanıcı cihazda onayladı.

- 2026-07-26: **9 maddelik UI turu (ekran görüntüsü geri bildirimi).** (1) **Liste seçim çubuğu artık ekranın DİBİNDE sabit**: çubuk `ReorderableListView.header`'ındaydı, yani listeyle kayıyordu — uzun listede aşağıdaki maddeleri seçtikten sonra "Kopyala"ya basmak için başa dönmek gerekiyordu (dosyadaki eski `ponytail` notu "kısa listelerde gerekmiyor" diyordu, kullanıcı aksini bildirdi). ÇÖZÜM: `OverlayPortal` (`_barController`) — çubuk Overlay katmanında, `bottom: 8 + viewInsets + viewPadding` ile klavye ve gezinme çubuğunun üstünde durur; seçim değişen her yerde `_syncBar()` çağrılır (show/hide build DIŞINDA yapılmalı). Ek olarak "Tümünü seç" düğmesi. BEDEL: çubuk açıkken editörün alt araç şeridini örter (bilinçli — o modda ilgisiz). (2) **Ek boyutları**: görseller 2048px/q80 → **1600px/q75** (`AppConstants.maxImageDimension`/`imageJpegQuality`), ses 48 kbps → **32 kbps / 22.05 kHz mono** (`audioBitRate`/`audioSampleRate`). OCR gerekçesi elendi: Gemini görseli 768 px karolarla işliyor, 1600 px fazlasıyla yeter. TUZAK: **video hâlâ buluta hiç gitmiyor** (tasarım kararı, `prepareVideo`/`upload` iki kapı); `image_picker.pickVideo` çözünürlük/kalite parametresi SUNMUYOR, video küçültmek yeni bağımlılık (ör. video_compress) ister — yapılmadı. (3) **Tema seçici tek satıra sığdı**: `showSelectedIcon: false` (segment başına ~28 px), dolgu 8→4 ve yer yetmezse `LayoutBuilder` etiketleri düşürüp yalnız simge+tooltip bırakıyor; eski çözüm yatay kaydırmaydı ve "Kağıt" ekran dışında kalıyordu (kullanıcı varlığını göremiyordu). (4) **Not işlem menüsü 2 SÜTUN** (`_ActionsGrid`): 13 işlem tek sütunda ekranı doldurup "Sil"i kaydırma arkasına atıyordu; ızgarada hepsi tek bakışta, "Sil" ayrı satırda + `errorContainer` (yıkıcı işlem kazara seçilmesin). (5) **Filtre menüsünde her klasör/etiket için AYRI aç-kapa** (`_ChipVisibilitySection` + `hiddenTagChipsProvider`/`hiddenFolderChipsProvider`, kalıcı): tek "hepsini göster" anahtarı "şu üçünü görmek istiyorum"a çare değildi. Sayfa artık `isScrollControlled` + %82 yükseklik sınırı. (6) **"+" menüsü tamamen yenilendi**: sağ kenara dizili 8 mini FAB + baloncuk etiketi yerine `_QuickAddPanel` — 3 sütun, 84 px hücreli tek kart (en çok 360 dp), sağ-alttan ölçek/solma ile açılır. `_StaggeredMenu` ve `_option` SİLİNDİ. (7) **Boş gövdenin "Not..." ipucu artık resmin altında kalmıyor**: KÖK NEDEN — görseller serbest katmanda metnin ÜSTÜne çiziliyor; yazılı metin `text_wrap.dart` ile etrafından akıyor ama ipucu metni akmaz, sabit durur. Gövde boşken bir satırlık pay (`hintReserve`) `NotePageCanvas.topLimit`'e eklendi, görsel o bandın altına iniyor. (8) **GİZLİ KLASÖR** (`NoteFolder.hidden`): çipi görünmez, notları `filteredNotesProvider` + `semanticSearchProvider` + `allTags`/`tagCounts`'tan düşer (`_suppressedFolderIdsProvider`); ⋮ → "Gizli klasörler" `authenticateForNote` ile O OTURUM boyunca açar (`hiddenFoldersRevealedProvider` KALICI DEĞİL — gizlinin anlamı bu). Yatay çekiş turu ve klasör seçimi de gizli klasörü atlar. NOT: bu ŞİFRELEME DEĞİL, içerik Firestore'da düz durur (omuz üstü bakışa karşı); gerçek koruma isteyen not başına "Kilitle"yi kullanır. (9) **İki parmak zoom → 1/2/3/4 sütun** (`gridColumnsProvider`, 0 = otomatik): eşik 1.25 (ham yuvarlama sütunu titretiyordu), adımdan sonra taban güncellenir ki aynı jestle 1→4 gezilebilsin; `pointerCount < 2` kontrolü tek parmak jestlerini (dikey kaydırma + yatay filtre çekişi) korur — ölçek tanıyıcısı pan slop'a (36 px) sürükleme tanıyıcısından (18 px) SONRA vardığı için arena çakışması pratikte doğmuyor. DOĞRULAMA: bu ortamda Flutter kurulu değildi; SDK 3.44.8 (Dart 3.12.2) indirilip `flutter analyze` (yalnız 2 ESKİ info: `use_null_aware_elements` + `cacheExtent` deprecation) ve `flutter test` **122/122** koşuldu; `flutter gen-l10n` elle yazılan generated dosyalarla BİREBİR aynı çıktı verdi. Yeni testler: `items_editor_selection_bar_test` (çubuk listenin içinde değil + kaydırınca yerinde kalır), `action_grids_layout_test` (2 ve 3 sütun geometrisi, taşma yok), `hidden_folder_test` (gizli not aramaya da girmiyor), `grid_columns_test`.

- 2026-07-26 (ikinci tur — QR/link, AI'sız ses, Material You widget, video istemi). (1) **Notlarda tıklanabilir link**: Flutter'da DÜZENLENEBİLİR bir `TextField` içinde span'e `TapGestureRecognizer` bağlamak ÇALIŞMAZ — dokunuş imleci taşımak için `EditableText`'e gider. Bu yüzden yol seçim menüsü oldu: `contextMenuBuilder` ile uzun basma menüsüne "Bağlantıyı aç" eklenir (`_bodyContextMenu`/`_selectedLink`), renklendirme ise `WrapTextController.buildTextSpan` içinde yapılır. İKİ TUZAK: (a) ölçüm (TextPainter) ile çizim AYNI span'i kullandığından link stili yalnız renk + alt çizgi olabilir — punto/kalınlık değiştirirsek satır kırılması ölçümden ayrışır ve imleç kayar; (b) IME oluşturma aralığı açıkken (`value.isComposingRangeValid`) span'e hiç dokunulmaz, yoksa klavyenin öneri altı çizgisi kayıyor. KARAR: çıplak alan adı kalıbı BİLEREK dar (TLD listesi) — `\w+\.\w+` gibi geniş bir kalıp "rapor.txt", "sürüm 1.2.3", "saat 14.30" gibi metinleri maviye boyuyordu; `test/link_text_test.dart` bu yanlış pozitifleri bekçiliyor. (2) **QR okunca "Linke git"**: QR kodların çoğu link ve tek yol adresi nota yazmaktı. Seçim sayfası `isDismissible: false` — `DetectionSpeed.noDuplicates` yüzünden yarım bırakılan tarama AYNI kodu bir daha okumuyor, o yüzden üç seçenekten biri mutlaka seçilir. (3) **KÖK NEDEN — AI ölüyken sesli asistan kaydı tümden yok oluyordu**: `finish()` içindeki `on GeminiException` yedeği, döküm yoksa `service.transcribeAudio`'ya, yani YİNE AI'a gidiyordu; anahtar yok + dahili AI kapalı + kota bitti hâlinde o çağrı da patlıyor ve istisna dış catch'e düşüp konuşma kayboluyordu. ÇÖZÜM: yedek artık AI'a hiç dokunmaz — döküm varsa düz not, yoksa ses kaydı nota EK olarak eklenir (`prepareAudio`); `_audioPath` alanı eklendi, `_collectAudio` dosyayı artık silmiyor, `finish` sonunda kullanılmayan artık temizleniyor. NOT: editör diktesinin (`dictation_sheet`) Windows yolu hâlâ AI'sız çalışamaz — oradan METİN dönmesi gerekiyor, eke düşecek yer yok; cihaz tanıması olan Android'de zaten AI'a hiç uğramıyor. (4) **ÖLÇÜM — Firebase AI kapsamı**: üretim çağrılarının tamamı `_generateFromContents` üzerinden dahili yola düşüyor, DEĞİŞİKLİK GEREKMEDİ. Yalnız iki istisna var: `embedTexts` (semantik arama — zaten `GeminiException` yakalanıp düz metin aramasına iniyor) ve canlı çeviri. Canlı çeviri Firebase AI'a TAŞINAMAZ: `firebase_ai 3.14.1` paketinde `translationConfig`/`targetLanguageCode` hiç geçmiyor (pub cache'te grep'lendi), yani Live Translate'in o alanı SDK'da yok; ham WebSocket + kullanıcı anahtarı zorunlu kalıyor. (5) **Widget'lar Material You**: renkler artık `values/colors.xml` belirteçlerinden okunuyor, `values-v31/` aynı adları `system_accent1/accent3/neutral1` ailelerine bağlıyor (duvar kâğıdı paleti); köşe yarıçapı da sabit dp değil `system_app_widget_background_radius`. Gece/gündüz ayrımı artık belirtecin işi olduğu için `drawable-night/` kopyaları SİLİNDİ. Dört stok `@android:drawable/*` ikon kendi vektörlerimizle değişti (`ic_widget_checklist`, `ic_widget_ordered` çizgiyle kuruldu — rakam yolları 24dp'de okunmuyordu). TUZAK: **RemoteViews dinamik liste kuramaz** (ayrı bir `RemoteViewsService` ister), bu yüzden not satırları SABİT dört görünüm; sağlayıcı boşları `GONE` yapıyor ve Dart artık "• " ile birleştirilmiş yığın yerine sade başlıkları `\n` ile gönderiyor. Dört kart 2 hücreye sığmadığı için varsayılan yükseklik 2→3 hücre. (6) **Video notu istemi**: "Özet / Görülenler / Konuşulanlar / Yapılacaklar" sabit başlık şablonu çıktıyı robotlaştırıyordu; istem artık şablon yasaklıyor ve "videoda ... görülüyor / konuşmacı ... diyor" anlatıcı kalıplarını da yasaklayıp bilginin kendisini yazdırıyor. DOĞRULAMA: `flutter analyze` temiz (yalnız 2 ESKİ info), `flutter test` **128/128** (yeni `link_text_test.dart` 6 test), imzalı APK derlendi ve `adb install -r` ile cihaza kuruldu (silinmedi, imza aynı). Widget'ların cihazdaki GÖRÜNÜMÜ doğrulanmadı — kullanıcı testi bekliyor.

- 2026-07-26 (üçüncü tur — hatırlatıcı). **KÖK NEDEN — sesli asistan hatırlatıcı kurmuyordu** ("yarın sabah 9'da toplantım var" → not oluştu, `reminderAt` boş, çip yok; kullanıcı ölçümü). Zincirin geri kalanı SAĞLAMdı (ReminderService bildirim planlıyor, AssistantService `reminderAt`'i işliyor, editörde çip var) — sorun modelin aracı **eksik argümanla** çağırmasıydı: `reminderAt` her iki şemada da `optionalParameters` içinde ve açıklaması *"(isteğe bağlı)"*; üstelik "toplantım var" bir EMİR değil bildirim cümlesi, o yüzden model isteğe bağlı alanı rutin olarak atlıyordu. KARAR: istemi güçlendirip ummak YETERSİZ — davranış modelin keyfine bırakılmaz. Üç katmanlı çözüm: (1) yeni `lib/core/utils/tr_datetime.dart` — Türkçe konuşmadan zaman çıkaran saf fonksiyon (bugün/yarın/öbür gün, gün adları + "haftaya" öneki, sabah/öğlen/öğleden sonra/akşam/gece varsayılanları, `14:30` / `saat 9` / `9'da` / `9 buçuk`); (2) `VoiceAssistantController.finish()` içinde emniyet ağı — model `reminderAt`'i boş bıraktıysa zaman dökümden yerelde çıkarılıp `setReminder` ile kurulur (model doldurduysa DOKUNULMAZ, onun bağlamı geniş), aynı ağ AI tümden ölüyken açılan yedek nota da bağlandı; (3) şema açıklaması "(isteğe bağlı)" yerine "gün/saat geçiyorsa MUTLAKA doldur, kullanıcının 'hatırlat' demesi gerekmez" oldu (iki yerde: `gemini_service._assistantTools` + `firebase_ai_client._assistantTools`) ve modele giden "şu an" damgası artık ofset + gün adı taşıyor (`_nowStamp()`) — düz `toIso8601String()` ofsetsizdi ve modeller onu UTC sanıp gece yarısına yakın saatlerde "yarın"ı bir gün kaydırabiliyordu. TUZAK (testle bekçilendi): düz `contains` "bugünlük bu kadar"da "bugün", "yarım ekmek"te "yarın" görüp hatırlatıcı UYDURUYORdu → `_hasWord` ile kelime sınırı denetimi (Dart'ın `\b`'si ASCII `\w` üzerinden çalıştığı için Türkçe harflerde güvenilmez); ayrıca sayı MUTLAKA bir saat ipucuna bağlı olmalı (`saat`/`'da`/`:`/`buçuk`) yoksa "3 elma 2 armut" saat sanılıyordu. AYRICA keşfedilebilirlik: editörde "Hatırlatıcı ekle" ✨ simgeli AI menüsünün (Etiket öner / Başlık öner) içindeydi — kullanıcı "nota hatırlatıcı ekleme olmalı" dedi çünkü orada arayan yok; artık klasör çipinin yanında kendi ⏰ `ActionChip`'i. DOĞRULAMA: `flutter analyze` temiz (2 ESKİ info), `flutter test` **137/137** (yeni `tr_datetime_test.dart` 9 test), imzalı APK `adb install -r` ile kuruldu. Cihazda sesli asistanla UÇTAN UCA denenmedi — kullanıcı testi bekliyor.

- 2026-07-27: **Hatirlatici gecikmesi + klavyeden gorsel yapistirma.**
  (1) **KOK NEDEN - 9:00 hatirlaticisi 9:02'de geliyordu**: `reminder_service.dart`
  `AndroidScheduleMode.inexactAllowWhileIdle` kullaniyordu ve manifest'te kesin
  alarm izni yoktu; Android "inexact" alarmi toplu ise alip dakikalarca
  geciktirir (tasarim geregi). COZUM: `USE_EXACT_ALARM` + `SCHEDULE_EXACT_ALARM`
  izinleri + `exactAllowWhileIdle` - hem not hatirlaticisi hem gunluk brifing
  (ayni kod yolundaki sibling akis, ikisi birlikte duzeltildi). RISK: Play
  politikasinda `USE_EXACT_ALARM` "alarm saati / takvim" uygulamalarina ayrilmis;
  yayin incelemesinde reddedilirse yol `SCHEDULE_EXACT_ALARM` + calisma aninda
  izin isteme + izin yoksa inexact'e dusme.
  (2) **Bildirim "yarin saat 9'da" diyordu** cunku govde ham not metni
  (`note.toPlainText()`) ve sesli asistan dokumundeki goreli soz metinde
  doniyor. KARAR (kullanici, 2026-07-27): not metnine DOKUNULMAZ - govdenin
  basina `reminderTimePrefix()` ile mutlak zaman oneki konur
  ("Bugun 09:00 - ..."). Ay adlari elle yazili: `intl`'in Turkce adlari
  `initializeDateFormatting` cagrisi istiyor, bildirim planlamasi ise arka
  planda da kosuyor.
  (3) **Klavyeden gorsel yapistirma bug degil, eksik yapilandirmaydi**: Android
  gorseli duz metin yapistirmadan AYRI bir yolla (`commitContent`) gonderir ve
  yalnizca alan destekledigini bildirirse gonderir. Flutter karsiligi
  `TextField.contentInsertionConfiguration`; govdeye ve liste ogelerine verildi
  (`ItemsEditor.contentInsertion` parametresiyle - ekleri not editoru yonetiyor).
  Masaustunde duz **Ctrl+V'ye baglanmadi**: kisayolu yakalamak TextField'in
  normal metin yapistirmasini yutuyor, panoda gorsel olup olmadigi ise ancak
  async ogrenilebiliyor - metin yapistirmayi elle yeniden yazmak sarma
  capalarini bozma riski tasiyordu. Ctrl+Shift+V duruyor.
- 2026-07-27: **Bos notta gorsel en ust satira cikamiyordu + YANLIS TESHIS duzeltmesi.**
  KOK NEDEN: `note_editor_screen.dart` icindeki `hintReserve`, govde BOSKEN
  `NotePageCanvas.topLimit`'e bir satirlik pay ekliyordu; amac ipucu metninin
  ("Not yaz...") gorselin altinda kaybolmamasiydi, bedeli kullanicinin gorseli
  en uste hic koyamamasi. COZUM ters yone cevrildi: gorsel serbest birakildi,
  ipucu tuvale devredildi (`NotePageCanvas.hint` + saf fonksiyon
  `hintTopFor()`), gorsel ipucunun bandini kesiyorsa ipucu gorselin ALTINA
  iniyor. Ipucu metin degil DEKORASYON oldugu icin sarma motoru onu akitamiyor
  - kok fark bu.
  **TUZAK (kendi hatam, olcmeden konustum):** kullaniciya "sarma motoru
  satirlari yalnizca yana kaydirabiliyor, asagi itemiyor" dedim ve buyuk bir
  is onerdim. YANLIS. `text_wrap.dart:164-173` zaten yapiyor: kalan kullanilir
  genislik sutunun %25'inin altina duserse dolgu SATIRIN TAMAMINI yiyor,
  kirici o satira kelime sigdiramiyor ve metin gorselin altina iniyor. Testi
  de vardi ve geciyordu: `text_wrap_test.dart` > "sutunu kaplayan gorsel metni
  altina iter". KALANLAR.md'deki "dortte ucunden fazlasini kaplayan gorsel"
  maddesi LISTE MADDELERI icindi (her madde ayri TextField, dikey yeri sabit),
  govde metni icin degil - iki farkli sey karistirildi. DERS: KALANLAR/HAFIZA
  maddesini baska bir baglama tasimadan once ilgili testi calistir.
  **KARAR (kullanici sordu, 2026-07-27): kendi satir kiricimizi YAZMIYORUZ.**
  Gerekce dosyanin kendi bas yorumunda zaten yazili: kendi dizgici imlec,
  secim, IME olusturma araligi, kopyala-yapistir, metin olcegi ve bidi
  davranislarini elle ustlenmek demek. Kalan iki gercek eksik bunu
  gerektirmiyor - liste maddesi itilmesi YERLESIM (layout) isi, tek uzun
  kelime ise hedefli kucuk bir duzeltme.
- 2026-07-27: **Kapsam kesme (canli ceviri + Gmail) ve iki sarma tavaninin
  kaldirilmasi.**
  KARAR (kullanici, 2026-07-27): canli ceviri ve Gmail ozeti KALDIRILDI - not
  almayla iliskisiz, bakim maliyeti yuksek; Gmail readonly scope'u ayrica Play
  Store'da ayri guvenlik denetimi (yillik ucuncu taraf denetim) gerektiriyordu.
  Olculen sonuc: lib 26.789 -> 25.069 satir, 112 -> 104 dosya, 4 bagimlilik
  dustu, **release APK 151.1 MB -> 107.0 MB** (buyuk kismi ML Kit ceviri
  modelleri). 46 olu l10n anahtari temizlendi (10'u zaten oncesinde oluydu).
  TUZAK: `app_tr.arb`'yi ConvertFrom-Json/ConvertTo-Json ile yeniden yazmak
  TUM dosyanin bicimini degistiriyor (girinti + `":  "`) ve devasa bir diff
  cikariyor; arb'den anahtar silmek icin satir bazli filtre kullanilmali.
  Karistirilmamasi gerekenler (silinmedi): `gemini_service.translateText` +
  `AiTask.translate` nottaki metni cevirme icin, `flutter_tts`/`speech_output`
  notu sesli okuma icin, `desktop_oauth_flow` normal masaustu girisi icin.
  **Iki sarma tavani kalkti** (ikisi de kendi satir kiricimizi YAZMADAN):
  (1) Liste maddesi: `_FloatRowState._measure` kalan genislik %25'in altina
  dusunce `start = end = 0` yapip PES EDIYORDU, satir gorselin altinda
  kaliyordu. Artik satir asagi itiliyor (`top` dolgusu). TUZAK: kesisme bandi
  `box.size.height` ile olculurse kutu kendi ust dolgusunu icerdigi icin bant
  itildikce buyur ve satir sonsuza kadar asagi kacar - olcum `- _top` ile
  itmeden bagimsiz tutulmali.
  (2) `planTextWrap`: sag kenar dolgusu icin kirilacak bosluk bulunamayinca
  (tek uzun kelime, `cut == -1`) hicbir sey yapilmiyordu. Artik satir tumuyle
  bosaltiliyor (soldaki genis gorselin yaptiginin aynisi). Yan etki koruma:
  dolgu yalnizca satir gercekten dar sutuna TASIYORSA denenir
  (`overflowsIntoFloat`), yoksa sigan kisa satirlar bosuna asagi itilirdi.
- 2026-07-27: **Ingilizce dil destegi (paket A).**
  TUZAK (yakalandi, kalici ders): `app.dart` dili `locale: const Locale('tr')`
  ile SABITLIYORDU - arb dosyasi eklemek tek basina hicbir sey yapmaz, once bu
  kalkmali. Artik `localeProvider` (null = sistem dili) kullaniliyor.
  TUZAK 2: `en` desteklenir olunca widget testleri KIRILDI. Sebep: Flutter test
  binding'i varsayilan olarak en_US kosuyor, testler ise Turkce metin ariyordu
  ("Sabitle" bulunamadi). Cozum: MaterialApp kuran 7 testte `locale: Locale('tr')`
  sabitlendi - testler ortam dilinden bagimsiz olmali.
  Dil adlari (Turkce / English) BILEREK cevrilmiyor: dilini bilmedigi bir
  arayuzde dogru satiri bulamayan kullanici sikisir; yalniz "Sistem dili" cevrilir.
  `tool/check_arb.ps1`: arb dosyalari arasinda anahtar + YER TUTUCU esligini
  denetler. Yer tutucu ({count}, {error}) toplu ceviride en sik kirilan yer ve
  gozle yakalanmaz; her dil eklendiginde bu once kosulur.
  Silinen ozelliklerden kalan iki bayat Turkce dizgi de duzeltildi: `permMicInfo`
  "canli ceviri" diyordu, `hubBriefingInfo` "e-postalar" diyordu.
- 2026-07-27: **AI kapsam kararlari (paket B) + App Check.**
  KARARLAR (kullanici, 2026-07-27): (1) "sen istemeden rapor ureten" ekranlardan
  **Oneriler + Haftalik ozet KALDIRILDI**, gunluk brifing KALDI. (2) Fatura
  modeli simdilik ayni: dahili AI kalir, **App Check aktive edildi** ama
  ZORLAMA konsolda acilmadi. (3) Semantik arama kaldi.
  Silinen: `suggestions_screen.dart`, `suggestFromNotes`, `weeklySummary`,
  `/suggestions` rotasi, AI hub karti, 8 l10n anahtari (iki dilde).
  Ayrica Gmail silinirken GOZDEN KACAN olu kod temizlendi: `triageEmails`,
  `EmailMeta`, `ImportantEmail` (78 satir). DERS: bir ozellik silinirken
  `gemini_service` gibi paylasilan servislerde o ozelligin metodu kalabiliyor;
  analyze bunu YAKALAMAZ (public API, cagrilmamasi hata degil). Silme sonrasi
  servisin metod listesini gozden gecir.
  App Check sirasi (main.dart `_activateAppCheck` yorumunda da yazili):
  once token uretimi, sonra konsolda kayit + izleme, EN SON zorlama. Ters
  sirada tum kullanici aniden hata alir. `androidProvider` parametresi
  deprecated; dogrusu `providerAndroid: AndroidPlayIntegrityProvider()`.
## 2026-07-28 — Paylas menusu: PDF/sunum/txt kabul
- Baska uygulamadan "Paylas -> Notlar" artik PDF ve PPTX'i de aliyor; .txt/.md
  paylasimi EK degil, notun GOVDESINE yaziliyor (ek yapilsaydi icerik notta
  gorunmezdi). Iki yer birden degisti: `AndroidManifest.xml` intent-filter
  (uygulama turu isleyebilse bile manifestte yoksa paylas menusunde HIC
  cikmaz) + `share_intake.dart` icinde `SharedMediaType.file` dali.
- KARAR: manifest `*/*` DEGIL, yalniz islenebilen MIME'lar listelendi. Sebep:
  genel bir "file" ek turu yok (AttachmentKind = image/pdf/audio/slide/video);
  `*/*` olsaydi docx/zip paylasiminda Notlar cikip icerigi kaybolan bos not
  acardi. Genel dosya eki istenirse AttachmentKind + ek listesi + Storage
  kurallari birlikte degismeli.
- BUG KOKU (ayni gun, ilk surum calismadi): paylasilan PDF'te not hic
  olusmuyor, sadece ana ekran aciliyordu. Sebep tur tespitinin UZANTIDAN
  yapilmasi: receive_sharing_intent dosyayi cihaza kopyalarken adi
  saglayicinin `_display_name` sutunundan aliyor (FileDirectory.kt) ve bu ad
  Drive/Gmail gibi kaynaklarda UZANTISIZ geliyor -> `p.extension` bos ->
  dosya sessizce atlaniyor. Ayni dosya baska uygulamadan (adi .pdf iken)
  calisiyordu, yaniltici. Cozum: `shareAttachmentKind` MIME'a bakiyor,
  uzantı yalniz yedek. DERS: paylasim/indirme akislarinda dosya ADI guvenilir
  degil, MIME guvenilir.
- Ikinci tuzak ayni kaynaktan: eklenti .txt dosyasini `type: text` diye verip
  `path` alanina DOSYA YOLUNU koyuyor (metnin kendisi degil). Bu yuzden metin
  girdisi once diskte var mi diye bakilip okunuyor; bakilmasaydi notun
  govdesine "/data/.../cache/x.txt" yazilacakti.
- Kanit: `test/share_intake_test.dart` (uzantisiz PDF dahil 5 durum).

## 2026-07-29 — Geri tusu / cumle secimi / belge tarama / kalem secenekleri
- **Geri tusu seçim ve sıralama modunu kapatır** (`dashboard_screen.dart`).
  Ana ekran yigin KOKU oldugu icin sistem geri tusu dogrudan uygulamayi
  kapatiyordu: yanlislikla uzun basip secime giren kullanicinin cikmaktan baska
  yolu yoktu. `PopScope(canPop: !selectionActive && !reorderActive)`.
  Not: `build`'in tamami yeniden girintilenmesin diye govde once `final page`
  degiskenine alindi, PopScope onu sariyor — 400+ satirlik girinti degisikligi
  diff'i okunmaz hale getirirdi.
- **Uzun basis kelime degil CUMLE secer** (`core/utils/sentence_select.dart`).
  Flutter'da uzun basis yalnizca KELIME secer; notta secim neredeyse hep bir
  cumleyi tasimak/silmek/AI'a vermek icin yapiliyor ("yarim yamalak seciliyor").
  KARAR — genisletme denetleyici dinleyicisinden yapiliyor: `TextField`
  `onSelectionChanged`/`SelectionChangedCause` DISA ACMIYOR (yalniz
  `EditableText` biliyor), tek genel kanca budur.
  Iki koruma sart: (1) secim ONCEKI secimin icindeyse dokunulmaz — yoksa
  tutamakla daraltma imkansiz olurdu; (2) yalniz BOSLUK ICERMEYEN (tek
  kelimelik) secim buyutulur — yoksa "tumunu sec" cumleye DARALTILIRDI.
  Yeniden girisi `_busy` bayragi kesiyor (kendi yazdigimiz secim dinleyiciyi
  tekrar tetikliyor). Sinir bulmada nokta ancak ARDINDAN BOSLUK gelirse cumle
  bitirir: "12.50" ve "vb.x" boyle korunuyor. Satir sonu da sinir (baslik ve
  liste satirlari noktasiz).
- **Belge tarama** (`notes/data/document_scan.dart`) — `dosya-okuyucu`
  reposundan alindi (`services/document_scanner.dart`): kenar tespiti +
  perspektif duzeltme Google ML Kit'in (`cunning_document_scanner`), bizim
  payimiz sayfalari nota EK yapmak. O repoda sonuc tek PDF'e gidiyordu; burada
  sayfalar GORSEL eki oluyor — notta surukleniyor, uzerine yaziliyor ve zaten
  var olan "Metni al" (OCR) yolundan geciyor. Kendi `ScanReviewScreen`/
  `Perspective` kopyasi ALINMADI: ML Kit tarayicisinin kendi kirp/dondur
  ekrani var, ikinci bir duzeltme ekrani ayni isi tekrar ederdi.
  "Belge tara not al" = `+` menusu → `/note/<id>?scan=1`; tarama bitince
  "yazilar da taninsin mi?" soruluyor (evet → Gemini OCR gövdeye yazar). Soru
  sessizce atlanmiyor: OCR sayfa basina birkac saniye ve AI kotasi.
  Windows'ta eklenti YOK → `DocumentScan.supported` false, menude hic gorunmez
  (`qrScanSupported` kalibi).
- **Kalem secenekleri iki yerde birden** (`viewers/ink_pen.dart`):
  tukenmez / kececeli / fosforlu + silgi, hem el yazisi ekraninda hem PDF/
  slayt/gorsel ustu cizimde. KARAR — `DrawingScreen` kendi cizim motorunu
  (`Stroke`/`DrawingPainter`) BIRAKTI, artik `InkController` + `InkPageLayer` +
  `InkToolbar` kullaniyor. Sebep: secenekler iki yerde ayri yazilirsa biri
  guncellenip digeri geride kaliyor (istegin kendisi buydu: "ayni secenekler
  PDF'te de olsun"); tek cubuk tek kaynak.
  KARAR — kalem turu AYRI ALAN OLARAK SAKLANMIYOR, rengin ALFASINDAN okunuyor.
  `InkStroke` Firestore'a ARGB tamsayisi yaziyor; yeni alan eski notlarin
  semasini degistirirdi. Saydamlik zaten ARGB'nin icinde, eski kayitlar
  (alfa 255) tukenmez olarak dogru ciziliyor. Fosforlu DUZ uc (`StrokeCap.butt`)
  ile cizilir: yuvarlak uc saydam cizgide uc uca binince koyu leke birakiyordu.
  Kalinlik araligi kalem turune bagli (fosforlu 10–46 px); tur degisince
  kaydirici turun varsayilanina tasiniyor, yoksa fosforlu 3 px'te kalip
  "calismiyor" gorunuyordu.
- Kanit: `test/sentence_select_test.dart` (cumle siniri + genisletme kurallari),
  `test/drawing_capture_test.dart` (ortak `InkPainter` yoluna tasindi, fosforlu
  saydamligi dahil).
- **CI TUZAĞI (bu turda ortaya çıktı, KOD İLE İLGİSİ YOK):** 2026-07-23'ten
  bu yana `Derleme` iş akışının HER kosusu ~3 saniyede, LOGSUZ, "Analiz + Test"
  isinde kırmızı. `main` dahil. Runner hiç başlamıyor (runner_name bos,
  log indirme 404) → GitHub Actions tarafi (dakika/faturalandirma) sorunu,
  derleme hatası değil. Son yeşil kosu: 2026-07-22 (#111).
  DERS: bu pencerede "CI yeşil" diye güvenilemez; doğrulama YEREL yapılmalı.
  Bu tur icin /workspace altina Flutter 3.44.6 (CI ile AYNI surum) + Android
  SDK 37 + NDK 28.2 kuruldu; `analyze` (0 sorun), `test` (171 gecti) ve
  `build apk --debug` (basarili) yerelde kosuldu.
- **CI blackout'unda biriken iki `analyze` hatası düzeltildi** (kod değişikliği
  bu turun kapsamı dışıydı ama analyze bunlarla KIRMIZI kalıyordu):
  `cacheExtent` → `scrollCacheExtent: ScrollCacheExtent.pixels(...)` (AGP/Flutter
  3.44'te deprecated; `ScrollCacheExtent` yalnız `package:flutter/rendering.dart`
  içinde, material.dart onu vermiyor) ve `if (folderId != null) 'k': v` →
  `'k': ?folderId` (null-aware eleman). `flutter analyze` INFO'larda da 1
  dönüyor — bilgi seviyesi uyarı "önemsiz" değil, CI'yi kırıyor.
- **TUZAK — `dart format` tüm repoyu biçimlendiriyor:** `dart format lib test`
  50 dosyayı değiştirdi (çoğu bu turla ilgisiz); diff okunmaz hâle geldi ve
  `router.dart`'ta satır bölünmesi YENİ bir lint doğurdu
  (`curly_braces_in_flow_control_structures`). Sadece dokunduğun dosyaları
  biçimlendir; toplu biçimlendirme AYRI bir commit olmalı.
- **TUZAK — widget testinde `Picture.toImage` ilerlemiyor:** el yazısı ekranının
  "Nota ekle" akışı testte SONSUZA KADAR asılıydı (ekran kapanmıyor, sonuç null,
  hata da yok). Sebep: PNG kodlaması motora gidiyor, `testWidgets`'in sahte
  zamanlı zone'unda tamamlanmıyor — `tester.pump` ne kadar pompalanırsa
  pompalansın bitmiyor. Çözüm: `await tester.runAsync(() => Future.delayed(...))`.
  `test/handwriting_pen_test.dart` bunu yazıyor.

- 2026-07-30: **Gorsel kirpma, yazi boyutu zipmasi, Almanca+Ispanyolca.**
  (1) **KARAR — kirpma KALICI** (kullanici secimi): dosyanin kendisi yeniden
  yazilir, kirpma dikdortgeni SAKLANMAZ. Sebep: gorsel not tuvalinde, tam
  ekranda, PDF/Word disa aktariminda, OCR'de ve AI'ya gonderimde AYRI AYRI
  ciziliyor; dikdortgen saklansa bu yollarin HEPSI onu uygulamak zorunda
  kalirdi ve biri unutuldugunda orada kirpilmamis gorunurdu. Bedeli: geri
  alinamaz. Paket EKLENMEDI — `image: ^4.8.0` zaten kuruluydu (`img.copyCrop`),
  kirpma ekrani (`viewers/image_crop.dart`) dort kose tutamaci + govde
  suruklemesi olarak elle yazildi; hazir kirpma paketleri Windows'ta yok.
  TUZAK 1: kirpma gorselin ORANLI (0-1) `ink` koordinatlarini gecersiz kilar →
  `cropInk` (domain/attachment.dart) noktalari yeni cerceveye tasir, kalinligi
  1/genislik orani ile buyutur, tumuyle disarida kalan cizgiyi duserir.
  Kanit: `test/crop_ink_test.dart`. TUZAK 2: dosya AYNI yola yazildigi icin
  Flutter'in gorsel onbellegi eski hali gostermeye devam ediyordu; tek tek
  atmak yetmiyor cunku not tuvali `cacheWidth` ile sardigindan anahtar
  `ResizeImage`, `FileImage` degil → `imageCache.clear() + clearLiveImages()`.
  TUZAK 3: buluttaki kopya once SILINIR ve `downloadUrl` bosaltilir, yoksa
  kuyruk "zaten yuklu" deyip yeni baytlari hic gondermezdi.
  Kirpma ekrani `BoxFit.fill` kullanir (bkz. oradaki not) — gerilme dogrusal
  oldugundan oranlar bozulmaz, `contain` olsaydi secim ile kirpilan alan kayardi.
  (2) **KOK NEDEN — yazi boyutu kaydiricisi parmagin altindan kaciyordu**:
  `fontScaleProvider` `app.dart`'ta TUM uygulamanin `textScaler`'ini suruyor;
  `onChanged` her oynamada yazinca Ayarlar ekraninin KENDISI yeniden
  boyutlaniyor → kaydiricinin USTUNDEKI satirlar uzayip kisaldigi icin
  kaydirici dikeyde kayiyor, "%100"→"%95" etiketi daraldigi icin yatayda.
  COZUM: gercek ayar yalniz `onChangeEnd`'de yazilir (surukleme boyunca deger
  yerelde), satir `MediaQuery.withNoTextScaling` icinde, yuzde etiketi sabit
  genislikte. Canli geri bildirim kaybolmasin diye altta SABIT YUKSEKLIKTE
  bir onizleme satiri suruklenen olcekle buyur/kucultur.
  (3) **KOK NEDEN — tarihler her dilde Turkce**: `DateFormat('d MMM y', 'tr')`
  6 yerde sabitti, yani mevcut Ingilizce bile eksikti. COZUM tek yerde:
  `app.dart` builder'inda `Intl.defaultLocale = Localizations.localeOf(...)`,
  cagri yerlerinden 'tr' argumani silindi. Ek baslatma (initializeDateFormatting)
  GEREKMIYOR: `flutter_localizations` etkin dilin tarih sembollerini zaten
  yukluyor — bu yuzden ETKIN dil kullanilmali, sabit bir dil degil.
  TUZAK: `reminders_screen.dart`'taki `static final _format` bir kez kurulup
  ilk acilistaki dili omur boyu tasiyordu → getter'a cevrildi.
  (4) **TUZAK — dil eklemek yedek dili sessizce degistirir**: `gen-l10n`
  `supportedLocales`'i ALFABETIK uretiyor (de, en, es, tr) ve Flutter eslesme
  yoksa `.first`e duser; Almanca eklendigi an sistemi ör. Fransizca olan
  kullanici uygulamayi ALMANCA gorurdu. COZUM: `app.dart`'ta acik
  `resolveLocale` (yedek = tr), `test/locale_fallback_test.dart` KURALIN
  KENDISINI cagirir (kopyasini degil). Ayni test Ayarlar'daki her dilin
  cevirisinin uretildigini de dogrular.
  (5) `speech_output.dart`: okuma hizi "tr mi degil mi" yerine ETKIN uygulama
  diline gore secilir (Almanca'ya gecen kullanicinin ana dili "yabanci" sayilip
  yavas okunuyordu); olu `userChosenLanguages` sabiti silindi. Ayarlar'daki ses
  seciciler `supportedLanguages`'tan turetildi (yeni dilde sessizce eksik
  kalmasin) — `speechVoiceTurkish/English` anahtarlari tek parametreli
  `speechVoiceLanguage` ile degistirildi.
  DOGRULAMA: `flutter analyze` temiz, `flutter test` 178/178, `tool/check_arb.ps1`
  dort dilde 406 anahtar tamam. CIHAZDA DENENMEDI (bu turda APK kurulmadi).

## 2026-07-31 — usta sağlık kiti
- `hooks/pre-push` kuruldu (flutter test; kırmızıysa push engellenir) +
  `core.hooksPath=hooks`. Flutter yolu PATH'te yoksa `C:\src\flutter`'a düşer
  ve bulunamazsa push'u DURDURUR (sessizce geçmez).
  DOĞRULAMA: hook uçtan uca koşuldu — 178/178 yeşil, EXIT=0.

## 2026-08-01 — görsel düzeni, geri al, seçim modu tutamacı
- **KÖK NEDEN — "görsel en üste dönüyor, boyutu kaydedilmiyor"**: kuyruk
  yüklemeyi bitirince `patchAttachment` işlemin okuduğu GÜNCEL eki, yüklemeye
  BAŞLARKEN aldığı kopyayla olduğu gibi değiştiriyordu. Yükleme saniyeler
  sürüyor ve kullanıcı tam o sırada görseli taşıyıp boyutlandırıyor → düzen
  sessizce geri alınıyordu. ÇÖZÜM iki katmanlı: (1) `Attachment.withUploadOf`
  yalnız depo alanlarını (storagePath/downloadUrl/localPath/boyut/ölçüler)
  geçirir, düzen belgede ne ise o kalır; (2) editör açıkken gelen her anlık
  görüntü `mergeAttachmentLayout` ile birleştirilir — ek LİSTESİ sunucudan,
  her ekin DÜZENİ yerelden. Kanıt: `test/attachment_layout_test.dart`.
- **KÖK NEDEN — "görsel yazıyı tek harf tek satıra sıkıştırıyor"**: liste
  satırında sarma kararı satırın TAMAMI üzerinden veriliyordu; oysa satırın
  ~140 dp'si tutamaç/kutucuk/sil düğmesine gidiyor. Görsel satırın üçte ikisini
  kaplayınca satır eşiği geçiyor ama METNE bir-iki karakter kalıyor, satır
  dikey bir harf sütununa dönüşüyordu (ekran görüntüsündeki "adlıpında…"
  sütunu). ÇÖZÜM: `_FloatRow.reserved` — chrome payı düşülerek ölçülür;
  düğme satırlarına (`Yeni öğe/Seç`, `İşaretlileri sil`) da pay verildi, yoksa
  sıkışıp TAŞIYORLARDI (RenderFlex overflow — testte ortaya çıktı).
  Gövde metnine de mutlak taban eklendi (`_kMinUsableWidth`, 72 dp).
- KARAR — **sürükleme tutamacı yalnız "Seç" modunda**. Normalde 6 nokta yer
  kaplıyor ve ne işe yaradığı görünmüyordu. Seç modunda uzun basış SEÇİM
  demek olduğundan tutamaç gecikmesiz sürükler
  (`ReorderableDragStartListener`, `ReorderableDelayedDragStartListener` değil)
  ve seçim jestlerinin DIŞINDA durur.
- KARAR — **geri alma NOTUN TAMAMINI saklar** (`note_undo.dart`), tek tek
  işlemlerin tersini değil: her düzenleme yolu kendi tersini yazsaydı biri
  unutulduğunda "Geri al" sessizce yanlış iş yapardı. TUZAK: yapı parmak izine
  öğe SIRASI konulmamalı — işaretleme tek hareket ama iki yazma üretiyor
  (yerinde değişim + 220 ms sonra taşıma), sıra da izde olsaydı ilk "Geri al"
  öğeyi işaretli hâlde eski yerine koyup dururdu.
- TUZAK — **eki silince baytları hemen silmek geri almayı boşa düşürüyor**:
  silme artık editör kapanırken yapılır; o an nota geri dönmüş ek dosyasını
  korur (`_flushAttachmentDeletes`).
- Ses örneği cümlesi dile bağlandı (`SpeechOutputController.voiceSample`):
  "dil en mi?" koşulu yüzünden Almanca/İspanyolca ses seçilince TÜRKÇE cümle
  okunuyordu — seçilen sesin asıl merak edilen özelliği hiç duyulmuyordu.
- `Attachment.asFile`: görsel sayfada yüzmek yerine alt şeritte DOSYA eki
  olabilir; yalnız true iken Firestore'a yazılır (eski notların şeması değişmez).
- Ek panosu uygulama içidir (`attachment_clipboard.dart`): sistem panosunun
  PDF/sunum/ses karşılığı yok, görselde bile çizim/boyut taşınmıyor. Sistem
  panosuna yazma buna EK olarak, hata yutularak yapılır (`Pasteboard.writeImage`
  masaüstünde yok).
- Yeni görsel imlecin satırına yerleşir: ölçüm (+) menüsü açılmadan/klavyeden
  yapıştırılmadan ÖNCE alınır (`_rememberCaret`) — menü klavyeyi kapatınca odak
  düşüyor ve imleç bir daha ölçülemiyor.
- DOĞRULAMA: `flutter analyze` temiz, `flutter test` 199/199 (yerel Flutter
  3.44.6, CI ile aynı sürüm). CİHAZDA DENENMEDİ.

## 2026-08-01 (ikinci giriş) — APK derlemesi runner kapanmasıyla düştü
- Koşu #148 (main, `[apk]`): "Analiz + Test" YEŞİL, "Android APK" 15 dk 20 sn
  sonra `##[error]The runner has received a shutdown signal` ile öldü. Derleme
  hatası DEĞİL — Gradle `assembleRelease` 871 sn koşarken runner alındı,
  `exit code 143` (SIGTERM). Kodla ilgisi yok.
- KÖK NEDEN (neden bu sefer sığmadı): Temmuz'daki başarılı koşuda (#109)
  Gradle önbelleği İSABET etti, geri yükleme 52 sn sürdü, derleme 9 dk 02 sn'de
  bitti (iş toplam ~11 dk). Bugün önbellek ISKALADI (23 Tem'den beri CI ölü
  olduğu için 7 günlük kullanılmama süresi dolmuş, GitHub düşürmüş): Gradle
  dağıtımı + tüm bağımlılıklar sıfırdan indi, derleme başlamadan ~4,5 dk gitti.
- TUZAK — **iptal/kapanma post adımlarını çalıştırmaz**: `actions/cache@v4`
  önbelleği post adımında kaydeder; runner kapanınca hiç kaydedilmedi, yani
  her yeni deneme yine sıfırdan başlayıp aynı duvara tosluyordu (kısır döngü).
  ÇÖZÜM: `cache/restore` + AYRI `cache/save`, kaydetme UZUN DERLEMEDEN ÖNCE,
  bir "ısıtma" adımının (`flutter build apk --config-only` + `gradlew
  --dry-run assembleRelease`) hemen ardında. Böylece derleme yarıda kesilse
  bile bir sonraki koşu ısıtılmış önbellekle başlıyor. Anahtar koşuya özel
  (`...-${{ github.run_id }}`) — sabit anahtar ikinci kez yazılamıyor.
- Koşu #151 (aynı gün, önbellek düzeltmesinden sonra): ısıtma + kaydetme
  ÇALIŞTI (5 dk 05 sn + 1 dk 14 sn, önbellek main'e yazıldı) ama asıl derleme
  yine `runner has received a shutdown signal` ile öldü — bu kez işin **26.
  dakikasında**. Yani sabit bir süre sınırı YOK; runner öngörülemez biçimde
  geri alınıyor (aynı commit dalda 16 dk 17 sn'de sorunsuz derlendi).
  DERS: bu ortamda APK derlemesi tek denemede yeşile bağlanacağına
  güvenilmemeli; işi KISA tutmak (önbellek isabet edince ~12 dk) ve gerekirse
  yeniden tetiklemek gerekiyor. Önbellek artık main'de kayıtlı olduğundan
  sonraki koşularda ısıtma adımı atlanıyor.
- SONUÇ: ısıtılmış önbellekle yeniden tetiklenen koşu (#153) BAŞARILI —
  ısıtma adımı atlandı, iş ~12 dk sürdü ve **v1.0.153** sürümü
  `notlar-v1.0.153.apk` (59,4 MB) ile yayınlandı. 23 Tem'den beri ilk yeşil
  APK derlemesi. Önbellek düzeltmesinin işe yaradığı böylece ölçüldü:
  #148 (soğuk, öldü) → #151 (ısıtma+kayıt, yine öldü ama önbelleği bıraktı)
  → #153 (sıcak, 12 dk, başarılı).

## 2026-08-01 (üçüncü giriş) — biçimlendirme, önizleme, geri tuşu, asistan sesi
- KARAR — **satır içi biçim, metnin İÇİNDE işaretle taşınır** (`**kalın**`,
  `_italik_`, `~altı çizili~`, `==2:vurgu==`, `%%3:renkli%%`); ayrı bir "span"
  alanı olarak SAKLANMAZ. Sebep: notun metni on ayrı yoldan geçiyor (arama,
  AI, sesli okuma, PDF/Word/sunum, pano, paylaşım, widget, yedek); biçim ayrı
  bir alanda dursaydı bu yolların HEPSİ onu ayrıca taşımak zorunda kalırdı ve
  biri unutulduğunda metinle biçim birbirinden ayrı düşerdi. Eski notların
  şeması da değişmedi. Bedeli: işaretler düzenleyicide GÖRÜNÜR (sönük çizilir);
  gizlemek, imleç/seçim konumlarını metinden ayırmak demekti — sarma
  çapalarında ödenen bedelin aynısı. Gösterime girmeyen yollarda
  `stripRichMarkers` (kart önizlemesi, PDF/Word, `Note.toPlainText`,
  `toContentText`). Kanıt: `test/rich_text_test.dart` — çizilen metnin
  KAYNAKLA AYNI UZUNLUKTA olduğu ayrıca doğrulanıyor (imleç kaymasın).
  TUZAK: ölçüm (TextPainter) ile çizim AYNI span'i kullanmalı — kalın/italik
  metin daha geniş dizilir; `planTextWrap` da `rich` alır.
  TUZAK 2: `_` ve `~` sıradan metinde geçiyor ("dosya_adi_uzun"); kalıp
  ikisinin çevresinde kelime karakteri olmamasını şart koşuyor.
- Görselin köşe tutamacına DOKUNMAK artık büyük önizleme açıyor (sürükleme
  eskisi gibi boyutlandırır). Önizleme sayfa düzenine dokunmaz — `displayWidth`
  değişmediği için metnin sarması da değişmez.
- Geri tuşu geçici kipleri kapatır, notu/sayfayı değil: liste "Seç" kipi,
  görsel seçimi ve büyük önizleme (ana ekranda seçim/sıralama zaten böyleydi).
- **KÖK NEDEN — dökümde tekrar eden kelime**: Android köprüsü, "yeni ara sonuç
  önceki segmentin devamı mı?" sorusunda kararsız kalınca bilerek "devamı
  değil" der ve o ana kadarki metni kalıcı yapar (konuşulanı kaybetmemek
  için). Bedeli sınırdaki tekrar. Temizlik TEK YERDE, `DeviceSpeech.listen`
  içinde (`dedupeSpeechSegments`): dikte, asistan ve dikte alt sayfası ayrı
  ayrı uğraşmıyor. Kanıt: `test/speech_text_test.dart`.
- Asistan SORU sorduğunda (yanıt `?` ile bitiyorsa) sesli okur — yalnız
  Android/iOS'ta (kullanıcı isteği: "sadece ve sadece mobilde konuşsun").
  "Kaydettim" gibi bildirimler okunmaz.
- Metni BOŞ öğe işaretlenemez (kutu pasif): boş satır işaretlenip işaretliler
  bloğuna iniyordu.
- Not başlığındaki çip satırı: yalnız VAR OLANLAR (hatırlatıcı/klasör/etiket)
  çip olarak durur, tüm ekleme eylemleri tek "+" menüsünde. Ana ekranda arama
  çubuğunun yanındaki ayrı AI düğmesi kaldırıldı (⋮ menüsünün ilk maddesi).
- "Diğerleri" süzgeci: klasörü ve etiketi olmayan notlar. Mevcut kullanıcılara
  bir kez otomatik eklenir (`visible_filters_others_added` bayrağı).
- Not düzeyinde yazı tipi (varsayılan/serif/monospace) ve boyut çarpanı
  (%80–%160) — Ayarlar'daki GENEL ölçekten ayrı, nota özel. Sistemde her zaman
  bulunan genel aileler seçildi: indirilen bir yazı tipi çevrimdışı açılan
  notta eksik kalırdı.
- DOĞRULAMA: `flutter analyze` temiz, `flutter test` 220/220 (yerel Flutter
  3.44.6). CİHAZDA DENENMEDİ.
- Runner kapanması TEKRARLADI (koşu #157, main): önbellek İSABET etti (ısıtma
  atlandı, 42 sn geri yükleme) ama derleme 8,5 dakikada `shutdown signal` ile
  öldü. AYNI COMMIT dalda (koşu #156) 11 dk 59 sn'de sorunsuz derlendi ve APK
  yüklendi — yani kodla ilgisi yok, runner rastgele geri alınıyor.
  DERS: main'de APK derlemesi ilk denemede yeşil olmayabilir; kod dalda
  derlendiyse yapılacak tek şey main'i yeniden tetiklemek.
- GÖZLEM (üç koşu, aynı gün): dal ile main'in APK işleri YAN YANA koştuğunda
  main'inki `shutdown signal` ile ölüyor, dalınki tamamlanıyor (#149/#156 dal
  yeşil ↔ #148/#157/#159 main kırmızı). Tek başına koşan main derlemesi (#153)
  tamamlandı. Neden kesin değil (runner tarafı) ama dalda üretilen APK zaten
  hiçbir yere gitmiyordu — sürüm main'den yayınlanıyor. ÇÖZÜM: APK işi artık
  YALNIZ main'de (ya da elle tetiklemede) koşuyor + iş akışına `concurrency`
  eklendi. Böylece hem çakışma hem de dal başına boşa giden ~12 dk gitti.
- DOĞRULANDI: dal derlemesi kaldırıldıktan sonra main'in APK işi tek başına
  koştu ve **v1.0.161** sorunsuz yayınlandı. Korelasyon böylece pratikte
  sınandı: iki ağır derleme yan yana koşmadığında main yeşil.

## 2026-08-01 (dördüncü giriş) — biçim çubuğu, yazı tipleri, asistan sesi
- KARAR — biçim/yazı tipi ayarları **alt çubuktaki "Aa" düğmesinin açtığı
  SABİT çubukta**. Eskiden yazı tipi palet sayfasının, biçim ise seçim
  menüsünün içindeydi: "seç → menü → sayfa → düğme" dört adımdı ve yazı tipi
  bulunamıyordu. Çubuk açıkken hepsi tek dokunuş, boyut ise SÜRÜKLENDİKÇE
  canlı değişiyor (kaydırıcı sayfanın altında sabit durduğu için parmağın
  altından kaçmıyor — Ayarlar'daki tuzağın tersi).
- TUZAK — **çubuktaki düğme odağı çalarsa seçim gider**: metin alanı odağı
  düşünce seçim de düşüyor ve biçim uygulanacak metin kalmıyordu. Çubuk
  `Focus(canRequestFocus: false, descendantsAreFocusable: false)` +
  `TextFieldTapRegion` içinde; dokunma çalışır, odak yerinde kalır.
- Seçim YOKKEN biçim düğmesi imlece boş bir kutu açıp imleci ARAYA koyar:
  kullanıcı yazmaya devam edince yazdığı biçimli çıkıyor ("her harf kendi
  içinde düzenlenebilmeli").
- Biçim çubuğu hangi alana yazacağını `FormatTarget` ile bilir: gövde ve her
  liste maddesi ayrı denetleyici kullanıyor, odak değiştikçe hedef tazeleniyor
  (ItemsEditor.onFieldFocused).
- Yazı tipi listesi genişledi (`core/utils/note_fonts.dart`): ilk üçü
  çevrimdışı garanti (varsayılan/serif/monospace), gerisi Google Fonts
  katalogundan. Uygulamanın kendi tipografisi zaten aynı yoldan geliyor
  (`GoogleFonts.interTightTextTheme`), yani yeni bir çevrimdışı riski yok —
  indirilemeyen yazı tipinde metin varsayılanla çizilir (`applyNoteFont`
  hatayı yutar). Kanıt: `test/note_fonts_test.dart`.
- Not kartı önizlemesi artık notun yazı tipini ve boyut çarpanını kullanıyor
  (çarpan ızgara bozulmasın diye 0.8–1.4 arasına kırpılır).
- Asistan artık HER yanıtı sesli okuyor (yalnız mobil). Önce yalnız soru
  cümleleri okunuyordu; oysa gereken tersiymiş — kullanıcı bir şey SORDUĞUNDA
  cevabı duymak istiyor.
- Asistan bir notu oluşturup güncelleyince ana ekran o nota kaydırıp 4 sn
  vurguluyor (`focusedNoteProvider` + `_FocusHalo`): "ekledim" deniyor ama
  hangi nota eklendiği görünmüyordu.
- DOĞRULAMA: `flutter analyze` temiz, `flutter test` 226/226. CİHAZDA
  DENENMEDİ.
- DÜZELTME (koşu #165): "çakışan derlemeler" açıklaması YETERSİZ. Bu koşuda
  dalda hiçbir derleme yokken main'inki yine öldü — üstelik 25. dakikada
  (Gradle 1506 sn; sağlıklı koşularda aynı iş ~12 dk). Yani runner bazen
  YAVAŞLIYOR ve sonunda geri alınıyor; çakışma bir sebep değil, olsa olsa
  ağırlaştırıcıydı. Dal derlemesini kaldırmak yine de doğru (kullanılmayan
  ~12 dk'yı siliyor) ama sorunu ÇÖZMÜYOR.
  DERS: bu ortamda APK derlemesi ~%50 olasılıkla düşüyor; tek çare yeniden
  tetiklemek. Kod dalda `Analiz + Test` yeşilse sorun kodda değildir.
- **ÖLÇÜLDÜ — `GoogleFonts.getFont(ad)` APK'yi 8 MB büyütüyor**: ada göre
  arama, paketin bin beş yüzü aşkın yazı tipini tanımlayan kataloğunu
  derlemeye sokuyor ve ağaç budama onu atamıyor (v1.0.161: 59,4 MB →
  v1.0.167: 67,4 MB; aradaki tek fark bu çağrıydı). ÇÖZÜM: yazı tipleri
  `note_fonts.dart` içinde tek tek, adıyla çağrılıyor
  (`GoogleFonts.lora(...)`). `kNoteFonts` ile çağrı listesinin ayrışmasını
  `test/note_fonts_test.dart` yakalıyor — yazı tipini YÜKLEMEDEN, yalnız
  anahtarları karşılaştırarak (testte ağ yok; google_fonts indirmeye kalkarsa
  test kırmızıya döner).

## 2026-08-01 (beşinci giriş) — biçim motoru yeniden yazıldı, klavye, şeffaflık

- **KÖK NEDEN — biçim işaretleri neden "çok hatalıydı"**: `toggleFormat` metin
  üzerinde çalışıyordu; işaretleri elle kesip yapıştırıyordu. İki biçim üst
  üste gelince (kalın + renk), seçim işaretin ortasına düşünce ya da aynı
  düğmeye ikinci kez basılınca tutarsız metin çıkıyordu (tek başına kalmış
  `**`, kaldırılamayan biçim, kayan seçim). ÇÖZÜM: tek yol —
  `işaretli metin → _parse (düz metin + parça başına RichMark) → aralığa
  ekle/çıkar → _serialize (+ konum eşlemesi)`. İç içe biçim artık doğal
  çalışıyor (`==1:%%2:**a**%%==`), sıra sabit (dıştan içe: vurgu → renk →
  kalın → italik → altı çizili), gidiş-dönüş kararlı.
- Konum eşlemesi İKİ dizidir (`starts`/`ends`): seçim BAŞI açılış işaretinden
  sonraya, SONU kapanış işaretinden önceye düşmeli. Tek dizi olsaydı biçim
  verilen metin seçili kalmaz, arka arkaya iki biçim verilemezdi.
- Seçim işaretin ortasına düşerse en yakın gerçek karaktere hizalanır
  (`_toPlain`) — "yarım işaret" hatalarının kaynağı buydu.
- **KÖK NEDEN — "yazı tipi değişince metni seçemiyorum"**:
  `WrapTextController._reflow` her çağrıldığında `TextSelection.collapsed`
  yazıyordu. Yazı tipi/boyut değişimi ya da bir görselin taşınması dizgiyi
  tazelediği için seçim anında siliniyordu; sarma çapası olan bir notta metin
  seçmek imkânsızdı. `_reflow` artık seçimin İKİ ucunu da taşıyor
  (`_reflowKeepingSelection`). Kanıt: `test/text_wrap_test.dart`.
- **TUZAK — Scaffold `bottomNavigationBar` klavyenin ALTINDA kalır**:
  `resizeToAvoidBottomInset` yalnız GÖVDEYİ kısaltır, alt çubuğu ekranın
  dibinde bırakır. Biçim çubuğu oradaydı; klavye açıkken hem çubuk hem "Aa"
  düğmesi erişilemiyordu (kullanıcı klavyeyi kapatmak zorunda kalıyor, kapatınca
  da seçim gidiyordu — "biçim yalnız seçime uygulanmıyor" şikâyetinin asıl
  sebebi buydu). ÇÖZÜM: çubuk `MediaQuery.viewInsetsOf().bottom` kadar
  kaldırılıyor; ek şeridi klavye açıkken gizleniyor (zaten görünmüyordu).
- Word mantığı: imleç biçimli bir parçanın İÇİNDEYKEN aynı düğme biçimi o
  parçanın tamamından kaldırır. Ayrıca "biçimi temizle" düğmesi eklendi.
- Not artık `textOpacity` taşıyor (0.3–1). Taban bilerek 0.3: daha soluğunda
  kullanıcı yazdığını göremez ve ayarı geri bulamaz. Varsayılan 1 belgeye
  yazılmaz (eski notlar aynen kalır).
- Liste notlarının KART önizlemesinde ham işaretler görünüyordu: metin notu
  dalı `stripRichMarkers`'tan geçiyor, checklist/sıralı dalı atlanmıştı. Arama
  da artık işaretsiz metinde arıyor ("558" araması `**558**` notunu bulur).
- Asistan sesi tek anahtarla yönetiliyor (`assistantVoiceProvider`): Ayarlar'daki
  anahtar ile panelin "sustur" düğmesi AYNI değeri okur/yazar.
- Asistan "bu not değil" deyip hiçbir şey oluşturmadığında panelde "Yine de
  nota dönüştür" çıkıyor: eldeki döküm modele HİÇ gitmeden nota yazılır
  (zaman geçiyorsa hatırlatıcı yerelde kurulur).
- DOĞRULAMA: `flutter analyze` temiz, `flutter test` 238/238. CİHAZDA
  DENENMEDİ.

## 2026-08-01 (altıncı giriş) — APK derlemesi üst üste üç kez düştü: bellek şüphesi

- Üç ardışık main derlemesi (#168 e774033, #171 f9c1b51 ve arada #170) AYNI
  yerde öldü: javac bittikten sonra, R8/dex sırasında (~13–17. dakika),
  `The runner has received a shutdown signal` + `exit code 143`. Dalda hiçbir
  derleme koşmuyordu — yani "çakışan derleme" açıklaması bu kez de geçersiz.
- ŞÜPHE (kanıtlanmadı): host BELLEĞİ. `android/gradle.properties` Gradle
  JVM'ine `-Xmx8G -XX:MaxMetaspaceSize=4G` veriyordu; runner 16 GB. Buna
  Kotlin daemon (ayrı JVM, tavan verilmezse aynı değeri miras alır), javac,
  Dart AOT ve R8 eklenince derlemenin en ağır anında host'un belleği bitiyor
  ve runner geri alınıyor. 143 = SIGKILL, OOM killer imzası.
- YAPILAN: heap 4G, metaspace 1G, `org.gradle.workers.max=3`,
  `kotlin.daemon.jvmargs=-Xmx1536m`. Ölçüt basit: bundan sonraki main
  derlemeleri geçiyorsa şüphe doğrulanır; yine aynı yerde ölüyorsa sebep
  runner tarafındadır ve tek çare yeniden tetiklemektir (bkz. ikinci giriş).
- Yan bulgu: v1.0.167 (67,4 MB) hâlâ son sürüm; APK'yi 59 MB'a indiren
  düzeltme (PR #43) main'de yayınlanamadı çünkü o derleme de aynı şekilde
  düştü. Yeni sürüm çıktığında boyut doğrulanmalı.

### Doğrulandı (v1.0.174)
- Bellek kısıtlaması sonrası main derlemesi TEK SEFERDE geçti (dört düşüşün
  ardından). Şüphe böylece destek buldu: 16 GB'lik runner'da Gradle'a 8G heap
  + 4G metaspace vermek, R8/dex anında host belleğini bitiriyordu.
- APK boyutu da doğrulandı: **67,4 MB → 59,5 MB** (yazı tiplerinin tek tek
  çağrılması, PR #43). İki düzeltme aynı sürümde yayınlandı.

## 2026-08-01 (yedinci giriş) — görünmez işaretler, satır içi boyut/opaklık, kasma

- **İŞARETLER ARTIK GÖRÜNMÜYOR** (kullanıcı: "kelimelerin etrafındaki ** ==
  gibi simgeler var"). Karakterler metinde DURUR — çıkarılsalardı imleç/seçim
  konumları denetleyicinin metniyle ayrışırdı (dosya başındaki karar) — ama
  saydam ve ~sıfır boyutta çizilir (`fontSize: 0.01`, `color: 0x00000000`).
  Ölçüm ve çizim aynı span'den geçtiği için imleç yine kaymaz.
- Bedeli ve çözümü: imleç görünmeyen işaretlerin ARASINDA durabiliyordu;
  kullanıcıya "imleç kıpırdamıyor / geri silme çalışmıyor" gibi görünürdü
  (silinen şey görünmeyen bir yıldızdı). `snapOutOfMarkers` imleci gidilen
  yöne, gerçek bir karakterin sınırına çeker; `WrapTextController` bunu hem
  sarmalı hem sarmasız yolda uygular. Boş biçim kutusunun (`****`) içi
  ÖZELDİR: orası düz metin sayıldığından imleç orada kalır.
- **TUZAK — yeni işaretlerde önek ZORUNLU**: boyut `##k:...##` ve opaklık
  `&&k:...&&` kademe öneki olmadan eşleşmez. İşaretler görünmez olduğundan,
  düz metindeki bir "## başlık ##" ya da "a && b && c" biçim sanılsaydı
  karakterler kullanıcının gözünden KAYBOLURDU.
- Boyut/şeffaflık artık "seçim varsa ona, yoksa tüm sayfaya" (kullanıcı
  isteği): seçim varken kaydırıcı bırakılınca satır içi kademe yazılır, canlı
  önizleme yapılmaz (hangi metnin etkileneceği görünmüyordu); seçim yokken
  eskisi gibi not geneli canlı değişir. Kademe notun kendi değeriyle aynıysa
  işaret hiç yazılmaz.
- Satır içi opaklık ancak VAR OLAN bir rengin alfasını düşürebilir: editörün
  gövde stiline renk artık açıkça yazılıyor (null bırakılırsa şeffaflık hiç
  görünmezdi).
- **KASMA — kök neden**: klavye yüksekliği animasyonlu değişir ve
  `MediaQuery.viewInsetsOf(context)` ekranın ANA build'inde okunuyordu; her
  karede editörün tamamı (sayfa tuvali, sarma ölçümü, madde listesi) yeniden
  kuruluyordu. Okuma alt çubuğun içindeki küçük bir `Builder`'a indirildi.
  DERS: animasyonlu MediaQuery değerlerini yaprağa en yakın yerde oku.
- Biçim çubuğu dört satırdan İKİ satıra indi (yazı tipleri açılır menüye,
  boyut ile şeffaflık tek kaydırıcıyı paylaşıyor): klavye + çubuk açıkken
  nota ekranın beşte biri kalıyordu.
- DOĞRULAMA: `flutter analyze` temiz, `flutter test` 246/246. CİHAZDA
  DENENMEDİ.

## 2026-08-01 (sekizinci giriş) — seçim kendiliğinden büyüyordu, şeffaflık kaydı

- **KÖK NEDEN — "sadece merhabayı seçmiştim, boyut verirken tüm satır seçildi
  ve büyüdü"**: `sentence_select.dart` yeni açılan TEK KELİMELİK seçimleri
  cümleye/satıra büyütüyor (uzun basış için doğru davranış). Biçim uygulamak
  ise metni DEĞİŞTİRİR (işaret ekler) ve seçimi kaymış konumuna programlı
  olarak taşır; kaydırılan seçim "önceki seçimin içinde" kalmadığından
  genişletici devreye giriyor, kullanıcının kelimesi satırın tamamına
  büyüyordu. ÇÖZÜM: genişletme yalnız METİN AYNIYKEN çalışır (seçim gerçekten
  kullanıcı dokunuşuyla değiştiğinde). Kanıt: `test/sentence_select_test.dart`.
- **TUZAK — `set(..., merge: true)` ile koşullu alan yazmak**: `toMap`
  `fontScale`/`textOpacity` alanlarını yalnız 1'den farklıysa yazıyordu.
  Kullanıcı şeffaflığı %100'e geri çekince alan haritadan düşüyor, Firestore'da
  ESKİ değer kalıyor ve not yeniden açıldığında ayar geri geliyordu
  ("artırıyorum, çıkıp girince yine azalmış"). Bu iki alan artık KOŞULSUZ
  yazılıyor. DERS: birleştirmeli yazmada "varsayılana dönüş" ancak alanı
  açıkça yazarak (ya da silerek) anlatılabilir.
- Seçim tutamaklarının titremesi: `_reflow` aynı metni/seçimi yeniden yazınca
  seçim katmanı (tutamaklar + araç çubuğu) baştan kuruluyordu; boyut
  kaydırıcısı sürüklenirken bu her karede oluyordu. Değer gerçekten
  değişmediyse artık hiç yazılmıyor.
- Başlık da biçimlendirilebilir oldu (kullanıcı: "sadece başlığın boyutunu
  ayarlayamıyorum"): başlık alanı da `WrapTextController` kullanıyor ve biçim
  çubuğunun hedefi olabiliyor. Başlığın GÖSTERİM hâli için `Note.displayTitle`
  eklendi — kart, çöp kutusu, paylaşım, brifing, AI bağlamı hep ondan okur.
- Şeffaflık ayarı bulunamıyordu: kaydırıcının başındaki düğme artık ADIYLA
  yazılı ("Boyut" / "Şeffaflık") ve dokununca ötekine geçiyor.
- Asistan istemine iki madde eklendi: (1) notun içeriği İSTEĞİN KENDİSİ değil
  SONUCUDUR — "içinde kalın kırmızı merhaba yazsın" denince nota komut değil
  `**%%1:merhaba%%**` yazılır; (2) satır içi biçim işaretleri ve renk
  indeksleri tanıtıldı.
- Yeni not oluşturup ana ekrana dönünce o not vurgulanıyor ve çerçevesi
  yanıp sönüyor (asistanın oluşturduğu notlarda zaten vardı; artık elle
  oluşturulanlarda da var ve vurgu nefes alıyor).
- DOĞRULAMA: `flutter analyze` temiz, `flutter test` 247/247. CİHAZDA
  DENENMEDİ.

## 2026-08-01 (dokuzuncu giriş) — görünmez işaretlerin üstünde geri silme

- **KÖK NEDEN — "silmeye başladığımda işaretler geldi, tek tek siliniyor"**:
  işaretler görünmez çizildiğinden imleç biçimli metnin sonunda aslında
  KAPANIŞ İŞARETİNİN ARDINDA duruyor. Geri silme önce o işaretleri siliyor;
  ilk silmede biçim bozulduğu için (`%%1:merhaba%%` → `%%1:merhaba%`) kalan
  işaretler artık eşleşmiyor ve DÜZ METİN olarak ekranda beliriyordu.
  ÇÖZÜM: silinen karakter bir işaretse silme metnin kendisine yönlendirilir
  (`deleteThroughMarkers`) — imlecin solundaki gerçek karakter silinir, biçim
  korunur, son harf de silinince işaret çifti `_serialize` sırasında
  kendiliğinden düşer.
- Boş işaret kutusu (`****`, `%%1:%%`) artık GÖRÜNMEZ çiziliyor: kutu hem
  biçim düğmesine seçimsiz basınca hem de biçimli metnin son harfi silinince
  oluşuyor; eskiden düz metin sanılıp ekranda yıldız olarak duruyordu.
- DERS: görünmez karakter yalnız ÇİZİMDE değil, DÜZENLEME yollarında da
  görünmez olmalı — imleç hareketi (snapOutOfMarkers) yetmiyor, silme de
  yönlendirilmeli. Sıradaki adaylar: ileri silme (Del) ve kelime silme
  (Ctrl+Backspace) — bu sürümde ele alınmadı.
- DOĞRULAMA: `flutter analyze` temiz, `flutter test` 251/251. CİHAZDA
  DENENMEDİ.

### ACİL — v1.0.181'de yeni not açılamıyordu (rota metni)
- Dashboard'daki `_openNew` yardımcısı betikle üretilirken `'/note/$id$query'`
  ifadesindeki `$` KAÇIRILMIŞ ve rota DÜZ METİN olarak gitmişti
  (`/note/\$id\$query`). Uygulama var olmayan bir notu beklediği için yeni not
  açan BÜTÜN modlar sonsuz "yükleniyor" ekranında kaldı.
- Ne derleyici ne test gördü: geçerli bir dizeydi ve rota metni hiçbir yerde
  doğrulanmıyordu.
- ÖNLEM: rota tek bir yerden kuruluyor (`noteRoutePath`) ve
  `test/note_route_test.dart` içinde `$` kaçağına karşı test edildi. Ayrıca
  editör 6 saniye içinde not gelmezse "Not bulunamadı" gösteriyor — sonsuz
  halka bir daha sessizce dönmesin.
- DERS: Dart kaynağını heredoc/betikle üretirken `$` ve `\` kaçışlarını
  ÜRETİLEN DOSYADA gözle doğrula; string içeren üretimlerde en az bir test
  yaz. (Bu turda üç dosya betikle düzenlendi, hata yalnız bunda oluştu.)

## 2026-08-02 — boş işaret artıkları, liste notunda metin, zemin görseli

- **KÖK NEDEN — "sildikçe yeni işaretler geliyor"**: biçimli bir kelimenin son
  harfi normal yoldan silinince geriye İÇ İÇE BOŞ işaretler kalıyor
  (`%%1:**_` + `_**%%`). İçi boş olduğundan hiçbiri biçim olarak eşleşmiyor ve
  DÜZ METİN gibi çiziliyorlar. `deleteThroughMarkers` yalnız "silinen karakter
  işaretse" devreye giriyordu, bu durumu kapsamıyordu. ÇÖZÜM:
  `collapseEmptyMarkersAt` — silmeden sonra imlecin İKİ YANI eşleşen bir
  açılış/kapanış çiftiyse çift kaldırılır; içteki gidince dıştaki yan yana
  geldiği için döngü hepsini toplar. Yalnız imlecin yanına bakar: metnin
  başka yerindeki `__` gibi diziler korunur.
- Liste notlarına serbest metin bloğu eklendi (alt çubukta "Metin ekle"):
  gövde alanı madde listesinin başlığında duruyor; `toPlainText` ve
  `toContentText` artık liste notlarında da gövdeyi taşıyor (yoksa dışa
  aktarmada kaybolurdu).
- Alt çubuktaki "Yapay Zeka" etiketi dar ekranda taşıyordu → "AI" (tam adı
  ipucunda).
- **Zemin görseli**: not artık `backgroundImageId` + `backgroundOpacity`
  taşıyor. Görsel ayrı bir alanda değil EKLER listesinde duruyor (yükleme
  kuyruğu, çevrimdışı kopya, silme mantığı yeniden kullanılıyor) ama sayfada
  yüzmüyor ve şeritte/kartta görünmüyor — editör onu id'ye göre ayıklıyor.
  Yerleştirirken kırpma ImageCropScreen ile, sonradan da değiştirilebiliyor.
  Varsayılan opaklık %35: tam opak fotoğrafın üstünde not okunmuyor.
- TUZAK (yine): `merge: true` yazımında kaldırılabilir alanlar KOŞULSUZ
  yazılmalı — `backgroundImageId` null da olsa haritaya girer, yoksa zemin
  bir daha kaldırılamazdı.
- DOĞRULAMA: `flutter analyze` temiz, `flutter test` 256/256. CİHAZDA
  DENENMEDİ.

### Zemin görselleri: kartta ve ana ekranda
- Notun zemin görseli artık KARTTA da çiziliyor (aynı görünürlük ayarıyla,
  kartın köşelerine kırpılarak). Kullanıcı isteği: "her notun zemin görseli
  dashboard'ta da görülmeli".
- ANA EKRANIN kendi zemin görseli eklendi (Ayarlar → Görünüm). Nota özel
  zeminden farkı: cihaza aittir, buluta yazılmaz. Seçilen görsel uygulamanın
  klasörüne KOPYALANIR — galeriden gelen yol geçici olabiliyor (paylaşım
  önbelleği), kopyalanmazsa zemin bir süre sonra kendiliğinden kaybolurdu.
  Dosya adı her seçimde değişir: aynı yola yazsaydık Flutter'ın görsel
  önbelleği eski kareyi göstermeye devam ederdi.
- Varsayılan görünürlükler düşük (not %35, ana ekran %25): tam opak bir
  fotoğrafın üstünde ne not ne kart okunuyor.

- 2026-08-02: **KÖK NEDEN — "not düzenlerken dashboard'a dönmeden uygulamayı tamamen kapatınca not bazen kaydolmuyor/kayboluyor"** (dal: `claude/note-lost-on-app-close-mbx8bk`). Kayıt ÜÇ ayrı yerden sızıyordu, üçü birlikte notun tamamen yok olmasını açıklıyor:
  1. **Debounce hiç dolmuyordu.** `Debouncer.call` her çağrıda zamanlayıcıyı SIFIRDAN başlatıyordu; aralıksız yazan kullanıcıda 500 ms'lik boşluk hiç oluşmadığından dakikalarca yazılan notta TEK bir kayıt bile yapılmıyordu. ÇÖZÜM: `maxWait` (varsayılan 3 sn) — bekleyen ilk çağrıdan bu kadar sonra eylem ertelenmeden çalışır. TUZAK: `maxWait` zamanlayıcısı `??=` ile kurulur; her çağrıda sıfırlansaydı `delay`in ikinci kopyası olurdu.
  2. **Yaşam döngüsü kapısı yoktu.** Kayıt yalnız zamanlayıcı dolunca ve `dispose()`taki flush'ta kesinleşiyordu. Uygulama görev listesinden kapatılınca rota pop EDİLMEZ → `dispose()` HİÇ çalışmaz → bekleyen yazım onunla gider. ÇÖZÜM: editör `WidgetsBindingObserver`; `resumed` dışındaki her evrede (`inactive`/`hidden`/`paused`/`detached`) ve masaüstünde `didRequestAppExit`te `_saveNow()`. `_saveNow` denetleyicilerin metnini nota işler (son tuşun `onChanged`i gelmemiş olabilir) ve `setState` ÇAĞIRMAZ (`detached` evresinde güvensiz). Gereksiz yazımı önlemek için "sürüklenme yok + bekleyen yok" ise hiç dokunmaz — `inactive` kamera/galeri/izin diyaloğunda sık gelir, her seferinde `updatedAt` tazelemek notu listede öne fırlatırdı.
  3. **`_mutate`in save kapanışı `ref.read` kullanıyordu.** Aynı kapanışı `dispose()` içindeki `_debouncer.flush()` de çalıştırır — ve `dispose` sırasında `ref` kullanmak istisna atar (bu dosyada zaten belgeliydi). Yani editörden ÇIKARKEN bile bekleyen son kayıt yutuluyor, üstelik atılan istisna dispose'un geri kalanını (ek silme flush'ı, boş not temizliği, otomatik başlık) iptal ediyordu. ÇÖZÜM: her build'de tazelenen `_notesRepo` alanı kullanılır.
  Ayrıca **boş not temizliği artık açık editöre dokunmuyor**: `openEditorNoteIds` (düz küme, provider değil — değişimi hiçbir arayüzü yeniden çizmemeli) editörde açık notları tutar, `cleanupEmptyNotes` bunları atlar. Yeni notta doküman ilk kayda kadar boş görünüyordu; 2 dk sonra silinmesi, editörün merge'lü yazımı dokümanı yeniden yaratsa bile klasör/renk/sıra alanlarını sıfırlıyordu. Regresyon testi: `test/debouncer_test.dart` (sahte saat için `testWidgets`+`tester.pump` — `fake_async` yalnızca transitive bağımlılık, doğrudan import `depend_on_referenced_packages`a takılır). NOT: bu oturumda da Flutter SDK ortamda YOKTU; `analyze`/`test` doğrulaması CI'ya bırakıldı.

- 2026-08-02: **Çok sağlayıcılı BYOK + canlı model kataloğu** (dal: `claude/note-lost-on-app-close-mbx8bk`, 2. tur). Kullanıcı isteği: "artık sadece gemini değil, OpenAI veya diğer sağlayıcıların API key'i de desteklenmeli; modeller otomatik çekilmeli, not için yeterli olanlar önerilen şeklinde gösterilmeli."
  **KARAR — iç istek biçimi Gemini `contents` olarak KALIR.** `GeminiService`'te 30'a yakın çağrı yeri (özet, OCR, PDF sohbeti, asistan…) bu şekli üretiyor ve `AiCost.forContents` maliyeti de bu şekilden ölçüyor. Sağlayıcı başına çağrı yerlerini çoğaltmak yerine biçim TEK yerde çevriliyor (`provider_chat.dart`): yeni sağlayıcı eklemek 1000 satırlık servisi değil yalnız o çeviriyi ilgilendiriyor. Boğaz noktası `_generateFromContents` olduğu için değişiklik oraya sığdı.
  Yeni dosyalar: `ai_provider.dart` (Gemini/OpenAI/Anthropic/OpenRouter — kimlik başlıkları, anahtar alma URL'si, anahtar biçim ipucu), `model_catalog.dart` (sağlayıcının `/models` yanıtını çözer, sohbet dışı modelleri eler, "not için yeterli" olanları `recommended` işaretler), `provider_chat.dart` (tel biçimi çevirisi).
  TUZAKLAR: (1) Gemini'nin depo anahtarı `gemini_api_key` olarak KALMALI — şema değişirse güncelleyen kullanıcı anahtarını kaybeder. (2) Anthropic'te `max_tokens` zorunlu, JSON kipi YOK (talimat `system` alanına yazılır) ve web'de `anthropic-dangerous-direct-browser-access` başlığı olmadan CORS'a takılır. (3) OpenAI'nin `json_object` kipi istemde "json" kelimesini şart koşar — sistem mesajı bu şartı da karşılıyor. (4) Gemini'de model YOLDA, OpenAI/Anthropic'te GÖVDEDE. (5) `_withModel`: katalog boş + kullanıcı model seçmemişse `ordered` boş kalıyor ve eski kod `lastSkipped!` null kontrolünde patlıyordu.
  **BİLİNEN SINIR**: araç çağrılı asistan, embedding (semantik arama) ve ses/video girişi yalnız Gemini + dahili AI'da. Diğer sağlayıcıda `_requireGemini` ne yapılacağını söyleyen Türkçe hata veriyor; sessizce yanlış sonuç yok. Ses/video için `UnsupportedContentException` çeviri katmanında atılıyor.

- 2026-08-02: **AI kota açığı kapatıldı + yerel (anonim) hesap** (dal: `claude/note-lost-on-app-close-mbx8bk`, 3. tur).
  **KÖK NEDEN — kota sayacı iki ayrı yoldan sıfırlanabiliyordu, ikisi de faturayı projeye çıkarıyordu**: (1) sayaç `users/{uid}` içindeydi ve o doküman istemciden SİLİNEBİLİYOR (hesap silme akışı için gerekli) — silip yeniden yaratmak sayacı sıfırlıyordu. (2) **Daha büyüğü**: gün bilgisi istemcinin yazdığı bir METİNDİ ('2026-08-02') ve kural "gün değiştiyse sıfırlanabilir" diyordu; yani istemci her istekte uydurma bir gün yazarak kotayı hiç doldurmadan sınırsız dahili AI kullanabilirdi — silmeye bile gerek yok. ÇÖZÜM: sayaç ayrı kök koleksiyona (`aiQuota/{uid}`) taşındı; pencere damgası artık SUNUCU zamanı (`request.resource.data.dayStart == request.time` — serverTimestamp'ı zorlayan standart kalıp), aynı pencerede puan yalnız ARTAR, pencere ancak `resource.data.dayStart < request.time - duration.value(24,'h')` ise sıfırlanır, `allow delete: if false`. KARAR (takas): kota artık gece yarısı değil, son sıfırlamadan 24 saat sonra yenilenir — takvim gününü kurallarda güvenle hesaplamak (saat dilimi + metin biçimlendirme) mümkün değil. İstemci pencereyi kendi saatine göre değerlendiriyor ama son söz sunucuda: saatini ileri alan istemcinin sıfırlama yazımı kurala takılır, işlem düşer, yerel yedek sayaç devreye girer. **`firebase deploy` GEREKLİ** (yeni kurallar).
  **Yerel hesap** = Firebase anonim girişi. Play'de ilk açılışta hesap zorunluluğu en büyük kurulum kaybı sebeplerinden; anonim giriş uid ürettiği için veri katmanı (tamamı uid'e bağlı) olduğu gibi çalışıyor. Yükseltme `linkWithGoogle` ile — `signInWithGoogle` DEĞİL: yeni giriş yeni uid demek ve anonim hesapta biriken bütün notlar erişilemez kalırdı. TUZAK: seçilen Google hesabı başka bir hesaba zaten bağlıysa `credential-already-in-use` gelir, Firebase iki uid'i birleştiremez.
  **KARAR — anonim kullanıcı dahili AI'ı KULLANAMAZ**: anonim kullanıcı çıkıp yeniden girince yeni uid alır, sunucu sayacı uid'e bağlı olduğundan bu sınırsız ücretsiz AI musluğu olurdu. Kendi anahtarını (BYOK) girerse kapıya hiç uğramaz, orada sınır yok. `GeminiException`ın `isAuthError`ı bilerek false: çağrı yerleri o bayrakta kendi genel "anahtar gir" metnini gösterip asıl açıklamayı yutuyordu.
  **App Check**: kod tarafı ZATEN hazırdı (`main.dart` → Play Integrity, debug'da AndroidDebugProvider). Yapılacak tek şey Firebase konsolunda enforcement'ı AÇMAK — Play'den kurulan uygulamada attestation çalışır (sideload'da çalışmadığı için kapatılmıştı, bkz. 2026-07-18).

- 2026-08-02: **Araç çağrılı asistan artık OpenAI/Anthropic/OpenRouter'da da çalışıyor** (kullanıcı OpenRouter anahtarı girip "Notlarla Sohbet"i açınca "yalnızca Google Gemini ile çalışıyor" duvarına tosladı — kısıt bilinçliydi ama ana özelliği kapatıyordu, kabul edilemezdi).
  **KARAR — Gemini araç döngüsüne DOKUNULMADI, ikinci bir döngü yazıldı** (`_runToolLoopCompat`). Gerekçe: Gemini döngüsü modelin gönderdiği parçaları geçmişe AYNEN geri koyuyor; bu, modelin kendi iç imzalarını (thought signature vb.) koruyor. Ortak bir iç biçimde toplayıp her istekte yeniden çevirmek çalışan yolu bozma riski taşırdı. Yeni döngü de aynı ilkeyi izliyor: sağlayıcının HAM yanıt mesajını (araç çağrısı kimlikleriyle) geçmişe aynen ekliyor, geçmişi Gemini `contents` biçimine geri çevirmiyor.
  TUZAKLAR: (1) OpenAI araç argümanlarını JSON NESNESİ değil JSON METNİ olarak gönderiyor — çözülmesi gerek, bozuk JSON'da boş haritaya düşülüyor ki döngü kendini toparlayabilsin. (2) Sonuç mesajları: OpenAI her sonuç için AYRI `{role:'tool', tool_call_id}` mesajı ister, Anthropic hepsini TEK kullanıcı mesajının içinde `tool_result` parçaları olarak bekler. (3) Kimlik eşleşmesi kritik: `tool_call_id`/`tool_use_id` yeniden üretilemez, ham yanıttan taşınmalı. (4) Şema lehçesi: Gemini tip adlarını BÜYÜK harf ('OBJECT'/'STRING'), OpenAI ve Anthropic küçük harf ister; araçlar tek yerde Gemini lehçesinde tutulup `_toJsonSchema` ile özyinelemeli çevriliyor — iki kopya tutulsa biri güncellenmeyi unuturdu.
  Kalan tek Gemini-özel yetenek: embedding (semantik arama) ve ses/video girişi.

- 2026-08-02: **Çok dillilik altyapısı (100+ dil hedefi)** (dal: `claude/note-lost-on-app-close-mbx8bk`).
  **ÖLÇÜM**: 447 çeviri anahtarı × 100 dil = ~45.000 dizge. Elle yazılamaz; `tool/translate_arb.dart` yazıldı — kaynak ARB'yi modele çevirtip `app_xx.arb` üretir, TEKRAR çalıştırılınca yalnız EKSİK anahtarları çevirir (yeni anahtar eklenince 100 dili baştan çevirmek gerekmez). Dört sağlayıcıyı da konuşur. 40'lık paketler hâlinde gider: model tek dev JSON'da bir anahtar atlarsa hangisinin kaybolduğu belli olmaz.
  **KRİTİK SINIR — Flutter'ın kapsamı**: `GlobalMaterialLocalizations`/`GlobalCupertinoLocalizations` çevirisi olmayan bir yerel ayar eklenirse uygulama o dilde ÇALIŞMA ANINDA hata verir (tarih seçici, metin seçim menüsü). Flutter ~78 taban dil destekliyor; "100+" hedefine bölge varyantlarıyla (pt-BR, zh-Hans/Hant, es-419...) ulaşılır. `language_names.dart` bilerek bu kümeyle sınırlı. Regresyon testi `locale_fallback_test.dart` → `GlobalMaterialLocalizations.delegate.isSupported(locale)` her dil için doğrulanıyor; çeviri aracı yanlış kod üretirse CI yakalar.
  **KARAR — `supportedLanguages` elle tutulmuyor**, `AppLocalizations.supportedLocales`tan TÜRÜYOR. Eskiden elle yazılmış 4 girdilik sabit haritaydı ve `.arb`'lerle senkron kalması kullanıcıya bırakılmıştı. Artık `app_xx.arb` eklemek dili seçilebilir yapmaya yeter. Ad kataloğu (`language_names.dart`) desteklenen kümeyi BELİRLEMEZ, yalnız adlandırır — dil adları kendi yazımıyla ("日本語"), çünkü kullanıcı listede kendi dilini arar.
  TUZAKLAR: (1) Dil seçici 8 dilden sonra radyo listesinden ARAMALI alt sayfaya geçiyor — 100 satırlık radyo listesi ayarlar sayfasını yaşanmaz yapardı; eşik konuldu çünkü 4 dilde arama kutusu da gereksiz sürtünme. (2) Ayarlardaki TTS ses seçicileri `supportedLanguages`ın TAMAMI için çiziliyordu → 100 seçici demekti; artık yalnız aktif dil + tr + en. (3) `voiceSample` testi "her desteklenen dilin benzersiz örnek cümlesi var" diyordu — 100 dilde kaçınılmaz kırılırdı, sabit listeye çevrildi (bilinmeyen dil İngilizce'ye düşer). (4) `LocaleNotifier` artık dil ETİKETİ saklıyor; `Locale('pt-BR')` dil kodunu 'pt-BR' sanıp hiçbir çeviriyle eşleşmeyeceğinden ayrıştırma eklendi.
  **KALAN İŞ**: RTL. Kodda 62 yönlü `EdgeInsets` + 22 `Alignment` kullanımı var; Arapça/Farsça/İbranice/Urduca eklenmeden önce `EdgeInsetsDirectional`/`AlignmentDirectional`e çevrilmeli (tuval geometrisi olanlar hariç — orada fiziksel doğru).

- 2026-08-02: **RTL (sağdan sola) desteği + çeviri CI iş akışı** (dal: `claude/note-lost-on-app-close-mbx8bk`). Arapça/Farsça/İbranice/Urduca eklenmeden önce yerleşim aynalanabilir olmalıydı. Flutter yönü yerel ayardan çıkarıyor ama bunu YALNIZCA yönlü tiplerde uyguluyor — `EdgeInsets.only(left:)` RTL'de de soldadır. 17 dolgu, 12 hizalama, 6 `Positioned` yönlü karşılıklarına çevrildi (`EdgeInsetsDirectional`/`AlignmentDirectional`/`PositionedDirectional`).
  **AYIRIM — neyin fiziksel KALMASI gerektiği**: tuval geometrisi. `items_editor`'ün sarma dolgusu, `note_images`, `slide_canvas`, `image_crop` ölçülen x koordinatlarından hesaplanıyor; yönlüye çevrilirse RTL'de metin görselin BULUNMADIĞI tarafa kaçar (sarma tam ters yerde olur). `note_pdf`'teki hiza kullanıcının açık seçimi, `quick_add_fab`'in `targetAnchor`/`followerAnchor`'ı ise `CompositedTransformFollower`'a ait ve `Alignment` (Geometry değil) istiyor — üçü de bilerek dokunulmadı, koda gerekçesi yazıldı.
  Regresyon testi `test/rtl_layout_test.dart`: aynalanması gereken dosyalara fiziksel yerleşim geri sızarsa CI kırılır (RTL'de bozulan yerleşim ancak o dile geçilip ekrana bakılınca fark edilir, kod incelemesinde kaçar). `fromLTRB` bilerek kapsam dışı: kullanımların hemen hepsi simetrik ve simetrik yatay dolgunun yönü yoktur; asimetrik olanlar (sağda ⋮ düğmesine yer bırakan not kartı dolgusu) elle çevrildi.
  **Çeviri CI**: `.github/workflows/translate.yml` — Actions'tan elle tetiklenir, anahtar `AI_TRANSLATE_KEY` secret'ında durur (loglara düşmez), üretilen ARB'ler doğrudan main'e DEĞİL yeni bir dala gider ve draft PR açılır. PR'dan önce `gen-l10n` + `analyze` + `test` koşar: bozuk yer tutuculu bir çeviri depoya hiç giremez. Makine çevirisi gözden geçirilmeden yayınlanmamalı.

- 2026-08-02: **TUZAK — `[apk]` işareti commit GÖVDESİNDEN de tetikliyordu.** Kullanıcı "merge et ama APK derleme" dedi; merge mesajının başlığına `[apk]` konmadı ama gövdeye açıklama olarak "APK derlemesi bilerek TETİKLENMEDİ (commit mesajında [apk] yok)" yazıldı — ve `contains(github.event.head_commit.message, '[apk]')` mesajın TAMAMINA baktığından derleme yine başladı. İşaretten SÖZ ETMEK bile tetikliyor. ÇÖZÜM: işaret artık `test` işinde bash ile yalnız ilk satırdan (`git log -1 --pretty=%s`) okunuyor ve `android` işi `needs.test.outputs.apk`'ya bakıyor; gövdede işaretten serbestçe söz edilebilir. AYRICA: GitHub App'in Actions'a YAZMA izni yok — `cancel_workflow_run` da 403 veriyor (rerun/run_workflow gibi), yani yanlış başlayan bir derleme yalnız kullanıcı tarafından ya da aynı dala yeni bir push'la (`concurrency: cancel-in-progress`) durdurulabilir.

- 2026-08-03: **`aiQuota` kuralları YAYINLANDI** (`firebase deploy --only firestore:rules`, proje `notlar-kaimau`). 2026-08-02'de yazılan sunucu zamanlı kota kuralları o güne dek yalnız depodaydı; sayaç sunucuda uygulanmıyordu. Artık yayında.

- 2026-08-03: **YANLIŞ TEŞHİS düzeltildi — "çevrimdışıyken ek eklenemiyor" diye bir bug yoktu.** KALANLAR'daki madde `appendAttachment` ve `patchAttachment`'ın `runTransaction` kullandığını, transaction'ın ağ turu gerektirdiğini söylüyordu. Triage: (1) `appendAttachment`'ı **hiçbir yer çağırmıyordu** — ölü kod, silindi; doc yorumu "sesli not modu bunu kullanır" diyordu ama `voice_assistant.dart` `updateFields` kullanıyor (yerine geçen eskisini bırakmış, usta 4b). (2) `patchAttachment`'ın tek çağıranı `UploadQueue` ve yalnız Storage yüklemesi BİTTİKTEN sonra çalışıyor — yani ağ zaten var, çevrimdışı hiç ulaşılmıyor; transaction orada doğru araç (listenin tek elemanını değiştirmek oku-değiştir-yaz istiyor), bırakıldı ve gerekçesi koda yazıldı. (3) Gerçek ek EKLEME yolları çevrimdışı zaten çalışıyor: paylaşım `arrayUnion` (`share_intake.dart`), editör yerel state + `set(merge:true)`, sesli not `updateFields` (yeni notta liste zaten boş). **DERS**: KALANLAR'a "düzeltmesi küçük" diye yazılan madde, çağıran taraması yapılmadan yazılmıştı; koda girmeden önce çağıran grep'i bir düzeltmeyi tamamen gereksiz kılabiliyor.

- 2026-08-03: **docx dışa aktarımı artık görselleri NOTTAKİ yerine koyuyor** (PDF ile aynı kural). Önceden hepsi metnin sonuna yığılıyordu. `NotePdf._withImages` semantiği birebir taşındı: `ExportImage.line` verilen satırdan ÖNCE, `widthFraction` satır genişliğine oran, `align` → `<w:jc>`. **TUZAK (asıl risk buydu)**: docx'te `rId` ve `word/media/imageN.ext` dosya adı ÖZGÜN `images` sırasından üretiliyor, yerleşim ise sırayı değiştiriyor — naif çözümde görseller birbirinin yerine gömülürdü ve bu ancak Word'de açınca fark edilirdi. Bu yüzden sıralama görsellerin kendisi yerine İNDEKSLER üzerinden yapılıyor. Regresyon testi `test/note_docx_layout_test.dart` id↔sıra eşleşmesini ayrıca doğruluyor. Ayrıca ölçekleme PDF ile eşitlendi: artık piksel boyutu değil satır genişliğinin oranı esas (`_emuPerPx` gereksiz kaldı, silindi).

- 2026-08-03: **Sohbet asistanına hatırlatıcı emniyet ağı bağlandı** (`chat_screen.dart` → `_ensureReminder`). Sesli asistandaki ağın aynısı: model not oluşturup `reminderAt`'i doldurmayı atlarsa (alan şemada isteğe bağlı) zaman kullanıcının kendi cümlesinden YERELDE çıkarılır, ekstra API çağrısı yok. `onToolCall` sarmalanarak oluşan not id'si yakalanıyor (`delete_note` hariç — sesli asistandaki kalıbın aynısı). Ayrıştırıcı hâlâ yalnız Türkçe; diğer dillerde `null` döner ve davranış eskisi gibi kalır.

- 2026-08-03: **YEREL imzalı APK derleme reçetesi** (Actions kotası azaldığında gerekiyor; CI'ı taklit etmezsen sessizce bozuk APK çıkar). Üç şart: (1) **İmza** — keystore `android/app/notlar-release.jks`, `android/key.properties` ile okunuyor, ikisi de gitignore'lu. Telefondaki APK'nın sertifikasıyla AYNI (`CN=Notlar, O=kaimau`, SHA-256 `5A:12:FF:D0…`); doğrulama: `apksigner verify --print-certs` ile telefondan çekilen APK'yı `keytool -list -v` çıktısıyla karşılaştır. Farklıysa `adb install -r` reddeder. (2) **`--build-number`** — pubspec `1.0.0+1`de sabit, CI `github.run_number` enjekte ediyor; telefondaki `versionCode`tan büyük verilmezse `INSTALL_FAILED_VERSION_DOWNGRADE`. (3) **`--dart-define=GOOGLE_SERVER_CLIENT_ID=…`** — projede `google-services.json` YOK (Firebase tamamen `firebase_options.dart` üzerinden), yani `constants.dart`taki "boş bırakılırsa eklenti json'dan okur" yedeği pratikte YOK: define'sız derlersen `serverClientId: null` olur ve **Google girişi kırılır**. Değer GitHub secret'ında; kaybolursa mevcut APK'nın `lib/arm64-v8a/libapp.so` dosyasında gömülü (`grep -a -o '[A-Za-z0-9._-]*apps\.googleusercontent\.com'`). Ayrıca `--target-platform android-arm64` (fat APK üç mimari için ayrı AOT derlemesi yapıp süreyi üçe katlıyor).

- 2026-08-03: **11 dil eklendi — çeviriler ARAÇLA DEĞİL elle yazıldı** (fr, it, pt, ru, hi, ja, ko, zh, id, nl, pl; 458 anahtar × 11 ≈ 5.000 dizge, toplam 15 dil). Kullanıcı `tool/translate_arb.dart` + kendi Gemini anahtarı yerine bunu seçti. **ÖLÇÜM neden önemliydi**: dizgeler kısa (ortalama 24,8 karakter, hepsi düğme/etiket), tek dil 11.349 karakter — yani 11 dil ≈ 125.000 karakter, elle yazılabilir bir hacim. Kalite farkının gerçekten önemli olduğu iki yer: yer tutuculu 26 dizge ve kısa düğme etiketlerinin uzamaması.
  **YÖNTEM — ham JSON elle yazılmadı**, `scratchpad/build_arb.py` üretici kullanıldı: çeviriler `{anahtar: metin}` sözlüğü olarak verildi, betik anahtar SIRASINI `app_en.arb`'den alıp JSON'u `json.dump` ile yazdı. Böylece iki sessiz hata sınıfı tamamen ortadan kalktı: (1) sıra kayması, (2) virgül/kaçış hatası. Eksik/fazla anahtar varsa dosya HİÇ yazılmıyor, eksik listesi basılıyor. Ayrıca `check_arb.py` her dil için anahtar kümesi + sıra + YER TUTUCU kümesi + `@@locale` denetliyor (`gen-l10n` de yakalar ama 3 dakika sürüyor; bu anında).
  **TUZAK — konsol kodlaması**: kaynak dizgeleri Windows konsolundan okurken `—` (U+2014) ve `×` (U+00D7) `?` olarak görünüyordu; `PYTHONIOENCODING=utf-8` olmadan çeviriye yanlış karakter taşınırdı. Dosyalar sağlamdı, bozuk olan yalnız görüntüydü.
  **KARAR — Arapça listeden ÇIKARILDI** (iş akışının varsayılan dil listesinde var). `supportedLanguages` ARB dosyalarından türediği için `app_ar.arb` oluşur oluşmaz Arapça seçilebilir hâle gelir; `text_wrap.dart` ve görsel tuvali hâlâ soldan-sağa varsayımıyla yazılı olduğundan editör gözle bozuk görünürdü. RTL işi bitince eklenecek.
  **KARAR — `pt` = Avrupa Portekizcesi** (dil kodu düz `pt`, Flutter'da `pt_BR` ayrı). Brezilya pazarı için `pt-BR` ayrı bölge varyantı olarak eklenebilir.
  **KALAN RİSK**: hiçbir dil anadili konuşan biri tarafından okunmadı (de/es için de geçerli) — yapısal doğruluk (yer tutucu, anahtar bütünlüğü, Flutter desteği) test edildi, DOĞALLIK edilmedi.

- 2026-08-03: **TUZAK — APK'da dize ararken Dart'ın iki farklı saklama biçimi yanlış alarm veriyor.** Çevirilerin gerçekten pakete girdiğini doğrulamak için `libapp.so` içinde UTF-8 arandı; sonuç: Lehçe/Almanca/Endonezce 5/5 bulundu ama Rusça/Japonca/Korece/Çince/Hintçe 0/5, **Türkçe bile 2/5**. Türkçe kesinlikle paketteydi — yani ölçüm yanlıştı, çeviriler değil. NEDEN: Dart AOT anlık görüntüsü dizeleri iki biçimde tutuyor — Latin-1'e sığan dize TEK BAYT (`OneByteString`), sığmayan dize UTF-16LE (`TwoByteString`). Dolayısıyla UTF-8 araması yalnız saf ASCII dizeleri buluyor; `ğ/ş/İ` içeren Türkçe dizeler bile kaçıyor. DOĞRUSU: her dizeyi önce `latin-1`, sonra `utf-16-le` ile kodlayıp aramak — böylece 14 dilin hepsi 10/10 çıktı. Ayrıca Windows'ta Bash `grep`'ine ASCII olmayan DESEN geçirmek kodlama bozulmasına uğruyor; ikili dosyada dize aramasını kabuk yerine Python'la yap.

- 2026-08-03: **RTL sarma motoru düzeltildi, Arapça eklendi** (16 dil). Aynı gün çeviriler yazılırken Arapça bilerek dışarıda bırakılmıştı; kullanıcı "düzgün, bozulmayacak şekilde kur" deyince önkoşul iş yapıldı.
  **KÖK AYRIM — fiziksel konum vs mantıksal kenar**: görselin yeri FİZİKSELdir (tuvalde ölçülen x), sarma dolgusu ise MANTIKSAL satır başına/sonuna konan bir çapa karakteridir. LTR'de satır başı fiziksel solda, RTL'de fiziksel sağdadır. `planTextWrap` bu eşlemeyi sabit LTR varsayıyordu, yani RTL'de dolguyu görselin BULUNMADIĞI tarafa koyar ve metin görselin üstüne binerdi. Düzeltme üç noktada: (1) `hugsLeft == ltr` ile fiziksel kenar → mantıksal kenar eşlemesi, (2) `_rightPadOffset`'in `limitX`'i RTL'de `columnWidth - indentEnd` değil `indentEnd` (satır sağdan aktığı için sınır soldan içeride), (3) `WrapTextController.updateLayout` artık `Directionality.of(context)` geçiriyor — parametre zaten vardı ama HİÇ verilmiyordu, varsayılan `ltr`de kalıyordu.
  **DEĞİŞMEMESİ GEREKEN — `_FloatRowState` dolgusu**: KALANLAR "yöne duyarlı dolgu" gerektiğini yazıyordu ama YANLIŞTI. Oradaki `EdgeInsets.only(left:, right:)` bilerek fiziksel ve RTL'de de doğru: görsel fiziksel olarak neredeyse metin oradan kaçmalı, okuma yönünden bağımsız. Yönlüye çevrilseydi RTL'de bozulurdu. Kodda zaten bunu açıklayan yorum vardı. `_lineRange` de yöne duyarsız ama güvenli: `getLineBoundary` fiziksel x ne olursa olsun tam satırı döndürüyor.
  Regresyon testi `test/rtl_text_wrap_test.dart` (5 test): aynı görsel için RTL sonucu LTR'nin AYNASI olmalı — fiziksel soldaki görsel LTR'de satır BAŞI çapası, RTL'de satır SONU birleştiricisi üretmeli. Dolgunun MİKTARI yönden bağımsız (120dp görsel her iki yönde 120dp), değişen yalnız TARAFI.
  **KALAN RİSK**: Arapça ne çeviri ne yerleşim olarak cihazda görülmedi.

## 2026-08-04 — i1 simgesi, widget'lar kağıt paletine, editör 3b

- 2026-08-04: **Devir paketi uygulandı — i1 uygulama simgesi.** Çivit degrade + beyaz sayfa + altın kıvılcım yerine kağıt paleti: krem `#F5EDD8` zemin, sepya `#7D5703` sayfa, kat SAĞ ÜSTTE, üç satır (en alt kısa). Kullanıcı sade sürümü seçti (kıvılcımlı alternatif pakette duruyor, uygulanmadı).
  **KARAR — zemin PNG değil hex**: zemin düz renge döndüğü için `adaptive_icon_background: "#F5EDD8"`; araç bunu `values/colors.xml`'e yazıyor ve MEVCUT 13 widget rengini koruyor (doğrulandı). 384 KB'lık `icon_background.png` ve `drawable-*/ic_launcher_background.png` (5 dosya) silindi.
  **KÖK DÜZELTME — paketteki monokrom SVG Android'de çalışmazdı.** Devir dosyası satırları ve katı `#C9C6BF` ile DOLU çiziyordu; Android monokrom katmanın rengini yok sayıp yalnız ALFA kanalını kullandığı için tintlendikten sonra her şey tek blob olur, satırlar kaybolurdu. Doğrusu satırların/katın maske ile OYULMASI (saydam delik) — `assets/icon/src/icon_monochrome.svg` öyle yazıldı.
  **TUZAK — `flutter_launcher_icons` `<monochrome>` yazmıyor** ve `mipmap-anydpi-v26/ic_launcher.xml`'i her koşuda baştan yazıp elle eklenen bloğu SİLİYOR. Uyarı hem XML'e hem `pubspec.yaml`'a yazıldı. `compileSdk = 37`, katman destekleniyor.
  **TUZAK — headless Chrome ekran görüntüsü ASENKRON**: `chrome --screenshot` çağrısı dönse bile PNG birkaç saniye sonra yazılıyor; hemen kontrol edilirse ESKİ dosya görülüp "üretilmedi" sanılıyor (bir tur bu şekilde kaybedildi).

- 2026-08-04: **Varsayılan tema kağıt oldu** (`AppThemeChoice.paper`). Simge kağıt paletine geçince marka orası oldu. Kayıtlı `theme_mode` anahtarı olan kullanıcı kendi seçiminde kalır; ayarı hiç ellememiş olan güncellemede kağıda geçer. `test/theme_default_test.dart` bu geriye uyumu koruyor.

- 2026-08-04: **Widget'lar Material You'dan ÇIKARILDI.** `values-v31/colors.xml` ve `values-night-v31/colors.xml` silindi; renk artık her cihazda kağıt paletinden geliyor.
  **NEDEN ÖNCE TERSİ ÖNERİLDİ**: ilk öneri "Material You kalsın"dı, dayanağı "uygulamanın varsayılan teması çivit, widget'ı kağıda zorlarsak uyumsuz görünür"dü. Kullanıcı aynı oturumda varsayılanı kağıt yapınca DAYANAK ÇÜRÜDÜ ve karar geri alındı. Bedeli bilinçli: widget artık duvar kâğıdıyla değişmiyor.
  **KORUNDU** — `values-v31/dimens.xml`: köşe yarıçapı hâlâ launcher'ın sistem değerinden geliyor. Renk bağı kesildi, ŞEKİL hizası değil.
  **KALAN SINIR**: widget sistem gece moduna bakıyor, uygulamadaki tema seçimine değil. Kullanıcı uygulamada Koyu seçip telefon açık modda kalırsa widget kağıt durur. Çözümü (SharedPreferences + RemoteViews ile 4 palet) ayrı iş olarak reddedilmedi, ertelendi.
  Gradyanlar kaldırıldı (yeni dilde gradyan/gölge yok), `widget_accent_start/_end` + `widget_note_start/_end` çiftleri tek belirtece indi, yarıçaplar 24/16 → 16/12 (yalnız 12 öncesi).

- 2026-08-04: **3b — editör üst/alt barı + ortak dinleme levhası.**
  **KARAR — levha sıfırdan yazılmadı**: `editor/dictation_sheet.dart` zaten cihaz tanıma / kayıt+Gemini yedeği, basılı-tut tercihi ve hata evrelerini taşıyordu; tasarıma taşınıp `presentation/voice_capture_sheet.dart` olarak iki ekranın ortak bileşeni yapıldı, eski dosya silindi.
  **DAVRANIŞ DEĞİŞİKLİĞİ — canlı dikte kaldırıldı.** Eskiden tanınan metin doğrudan gövdeye yazılıyordu (liste notunda her duraklama = yeni madde, `_syncDictatedItems`). Artık metin levhada birikiyor, kullanıcı düzeltip onaylıyor. BEDELİ: liste notunda maddelere bölme artık yerel değil, "Maddelere böl" çipiyle YAPAY ZEKÂ çağrısı — bir puan harcıyor. Kullanıcı bilerek onayladı.
  **KORUNDU — `_writeDictated`**: Keep tarzı sesli not (`_startVoiceCapture`, `?voice=1`) onu hâlâ kullanıyor; canlı dikte temizliğinde silinmemesi gerekiyordu.
  **TUZAK (eski koddan devralındı, korundu)**: basılı-tut modunda ana düğme idle ve listening evrelerinde AYNI ağaçta kalmalı — aksi hâlde parmak basılıyken düğme ağaçtan kalkar ve `onLongPressEnd` hiç gelmez.
  **SAPMA — "Ekle ▾" açılırında 5. satır var.** Tasarım dört satır istiyor; mevcut ek menüsünde kamera, belge tarama, QR, slayt, çizim, ses ve video da var. Dörde indirmek bunları ERİŞİLEMEZ yapardı, altta "tüm ekler" satırı bırakıldı.
  **EKSİK BIRAKILDI**: biçim düğmelerinde "aktif biçim" vurgusu yok — editör imlecin bulunduğu parçanın biçimini şeride akıtmıyor, sahte aktiflik göstermek yerine boş bırakıldı.
  12 yeni l10n anahtarı 16 dile çevrildi (`tool/translate_arb.dart`). **TUZAK**: `~/.claude/gemini-keys.txt` ilk satırı YORUM; ayrıca `gemini-3.1-flash` ve `gemini-2.5-flash` bu anahtarla 404, `gemini-3.5-flash` dakikada 5 istekte kotaya takılıyor — toplu çeviride `gemini-3.1-flash-lite` çalıştı.

## 2026-08-04 (ikinci giriş) — 5a ana ekran, 6a yapay zekâ, 4a ayarlar

- 2026-08-04: **5a — ana ekran.** Çip barı (`dashboard_chips.dart`, 587 satır) tümüyle silindi; yerine Süz levhası (`filter_sheet.dart`) + yalnız UYGULANMIŞ süzgeçleri gösteren satır geldi.
  **SESSİZ ÖLÜ KOD RİSKİ**: çip barıyla birlikte 6 sağlayıcı (`visibleNoteFilters`, `showTagChips`, `showFolderChips`, `hiddenTagChips`, `hiddenFolderChips`, `filtersExpanded`) ve `tagCountsProvider` sahipsiz kaldı. Analyzer public sağlayıcıları KULLANILMIYOR diye işaretlemez — elle taranıp silindi. Bir dosya silindiğinde bu taramayı yapmak şart.
  **EKLENEN VERİ KATMANI**: tasarımın istediği `NoteFilter.reminded`, `NoteFilter.locked` ve `NoteSort.color` kodda YOKTU; eklendi (`note_filter_sort_test.dart`). Tasarımın DURUM listesi tür süzgeçlerini (Metin/Liste/Sıralı) düşürüyordu — silinmediler, aynı bölümde duruyorlar.
  **KARAR — tarih kovaları yalnız "Son düzenlenen" sıralamasında.** Başlık/Renk sıralamasında "BUGÜN" başlığı altındaki sıra tarihe göre olmaz, başlık yalan söyler. Süz levhasında bu bir ipucu satırıyla yazılı.
  **TUZAK — `toUpperCase()` Türkçe'yi bozar**: bölüm başlıkları ("ETİKET") kodda büyük harfe çevrilmez, ARB'de zaten büyük harfli anahtarlar olarak tutulur. Dart'ın `toUpperCase()`i yerel ayar tanımaz, "Etiket" → "ETIKET" (noktasız I) yapardı.
  **KORUNDU** — `_cycleFilterFolder` (yatay çekiş) artık süzgeçlerin tamamını geziyor; gizli klasörler yine atlanıyor.

- 2026-08-04: **Sesli asistan düğmesi → ortak dinleme levhası.** `VoiceAssistantButton` (≈148 satır) silindi.
  **KAYBOLMASI AN MESELESİ OLAN ÖZELLİK**: mevcut asistan konuşmadan başlık/madde/HATIRLATICI çıkarıyor ve bunu `test/tr_datetime_test.dart` (9 test) koruyor. Tasarımın dört çipinin hiçbiri bu işi yapmıyordu; düz uygulasaydım özellik ve testleri sahipsiz kalırdı. ÇÖZÜM: levhaya ana ekranda beşinci çip ("Asistan oluştursun") + `VoiceAssistantController.composeFromTranscript`.
  **NEDEN `finish()` YENİDEN YAZILMADI**: asıl değer onun içindeki güvenlik ağlarında (model boş not kurarsa dökümle doldurma, hatırlatıcıyı yerelde çözme, AI ölüyken düz nota düşürme). `_useSpeech = true` ses toplama adımını atlatıyor, o yolda `finish()` zaten yalnız dökümle çalışıyor.
  `VoiceAssistantPanel` DURUYOR: ana ekran widget'ından (`notlar://voice`) başlayan oturumun durumunu hâlâ o gösteriyor.

- 2026-08-04: **6a — yapay zekâ sayfası.** Üç satırlık menü çalışan sayfaya döndü: puan çubuğu, sohbet kartı, öneri kutuları, belge oku.
  **KARAR — sohbet geçmişi sağlayıcıya taşındı** (`chat_controller.dart`). Sohbet iki yerde birden görünüyor (hub kartı + tam ekran); geçmiş `ChatScreen`'in kendi `State`inde kalsaydı "tam ekran"a geçen kullanıcı yazdıklarını kaybederdi.
  **UYDURMA SAYI YOK**: öneri kutularındaki sayılar gerçek sorgudan (etiketsiz/başlıksız not sayısı, arşivlenmiş ve kilitli notlar hariç). Tasarımdaki dördüncü kutu ("Kopyaları temizle — 3 benzer not") EKLENMEDİ: benzerlik ölçümü uygulamada yok, sahte sayı göstermektense kutu hiç konmadı. "SON İŞLEMLER" bölümü de yok — beslendiği bir işlem geçmişi deposu yok.

- 2026-08-04: **4a — ayarlar.** Dokuz kart altı akordeon alana indi (`_SettingsArea`), her başlığın altında DURUM ÖZETİ var; ayar arama eklendi.
  **KARAR — arama ALAN düzeyinde**: tasarım satır satır süzme istiyor ama her satırı aranabilir bir tanıma çevirmek 2000 satırlık dosyanın tümünü yeniden yazmak demekti. Alanların başlığı + elle yazılmış anahtar kelimeleri aranıyor; eşleşen alanlar açık geliyor.
  **ÖZETE GİRMEYEN DEĞER**: okuma hızı, motordan ASENKRON okunuyor (`speechOutputProvider.rate()`); özet satırı senkron String istiyor, yanıp sönen bir "%100" yerine yalnız düğme modu gösteriliyor.
  Dil ayarı "Ses" alanına taşındı (tasarımın yerleşimi), `_SettingsGroup` silindi.

- 2026-08-04: **TUZAK — yerleşim testi tasarım değişince kırılır, kırılmalıdır da.** `action_grids_layout_test` "+" panelini üç sütun olarak doğruluyordu; panel YAZ satırları + YAKALA ızgarasına ayrılınca kırıldı. Test YANLIŞ değildi, eski niyeti koruyordu — yeni niyete göre güncellendi (satırlar alt alta, ızgara altta). Aynı şekilde `rtl_layout_test` yeni `voice_capture_sheet.dart`teki fiziksel `EdgeInsets.only(left:)`i yakaladı; Arapça'da imleç yanlış tarafa düşecekti.

- 2026-08-04: **TUZAK — `flutter install` DERLEMEZ.** Telefona kurulum istendiğinde `flutter install --release` çalıştırıldı ve "başarıyla kuruldu" denildi; oysa o komut yalnız `build/app/outputs/flutter-apk/app-release.apk` dosyasını kurar. Oradaki APK BİR GÜN ÖNCEDEN kalmaydı (bu turdaki doğrulama derlemelerinin hepsi `--debug` olduğu için release APK'ya hiç dokunulmamıştı) — kullanıcı telefonda dünkü uygulamayı gördü, "hiçbir şey değişmemiş" dedi. DOĞRUSU: `flutter build apk --release` SONRA `flutter install`. Kontrol: kurmadan önce APK'nın `LastWriteTime`ına bak, derleme tarihinden eskiyse kurma.

- 2026-08-04: **KÖK NEDEN — yerel release APK'da Google girişi çöküyor: `--dart-define` eksikliği.** Telefonda `GoogleSignInException(clientConfigurationError, "serverClientId must be provided on Android")`. İlk teşhis YANLIŞTI (SHA-1 imza uyuşmazlığı sanıldı); kullanıcı "CI derlemesi de çalışıyordu" deyince ölçüm yapıldı: `pubspec.lock` DEĞİŞMEMİŞ, auth kodu bu turda hiç dokunulmamış, `google_sign_in` sürümü aynı. Yani kod CI ile birebir aynıydı — fark yalnız DERLEME KOMUTUNDA.
  **ZİNCİR**: `AppConstants.serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID')` → define geçilmezse boş string → kod eklentiye `null` geçiyor → eklenti hatayı atıyor. Uygulama sorunsuz DERLENİYOR; hata yalnız telefonda, giriş anında görünüyor. Sessiz kırılma bu yüzden tehlikeli.
  **NEDEN "google-services.json'dan okur" YORUMU YANILTICIYDI**: bu repoda o dosya YOK, Firebase yapılandırması `firebase_options.dart` üzerinden geliyor — eklentinin keşfedecek bir kaynağı yok. Yorum düzeltildi.
  **ÇÖZÜM**: değer Firebase CLI ile geri kazanıldı (`firebase apps:sdkconfig ANDROID <appId> --project notlar-kaimau` → `oauth_client` içinde `client_type: 3` = web istemcisi), `env.json`'a yazıldı (gitignore'lu), derleme `--dart-define-from-file=env.json` ile yapıldı. `env.example.json` bu anahtarı hiç belgelemiyordu — eklendi. `CLAUDE.md`'ye yerel release komutu yazıldı.
  **YAN BULGU — imza anahtarı yedeksiz**: CLAUDE.md "anahtar repo DIŞINDA `Desktop\notlar-keystore\`" diyordu ama o klasör YOK. Tek kopya `android/app/notlar-release.jks` (gitignore'lu, yani depoda da yok). Makine giderse aynı imzayla güncelleme yayınlanamaz. CLAUDE.md gerçeğe göre düzeltildi; makine dışı yedek KULLANICININ işi.
  **YAN BULGU — APK boyutu**: bayraksız `flutter build apk` tüm mimarileri paketliyor (110 MB); CI `--target-platform android-arm64` ile ~60 MB üretiyor.

- 2026-08-04: **Beş arayüz hatası paketi** (dal: `claude/ui-bugs-fixes-zmfn46`, ekran görüntüleriyle bildirildi).
  **KÖK NEDEN — "ses kısmını çalıştıramıyorum":** basılı-tut modu `GestureDetector.onLongPressStart/End` üzerine kuruluydu. Uzun basış tanıyıcısı ~500 ms bekler; o süre içinde söylenenler kaybolur, kullanıcı erken bırakırsa dinleme HİÇ başlamaz ve levha "konuşma algılanamadı" hatasına düşer. Ayrıca mikrofon izni ilk basışta isteniyordu: sistem kutusu parmak düğmedeyken açılıyor, kullanıcı "İzin ver"e basmak için parmağını kaldırınca bırakma olayı dinlemeyi başlamadan bitiriyordu. ÇÖZÜM: `Listener.onPointerDown/Up` (parmak değer değmez başlar), izin levha AÇILIRKEN istenir ve **kısa dokunuş dinlemeyi KİLİTLER** (< 600 ms → parmak kalksa da dinleme sürer, düğme "Bitir"e döner). Böylece tek düğme iki modu da taşıyor. Başlık da düzeltildi: mikrofon kapalıyken "Dinliyorum..." yazıyordu.
  **KÖK NEDEN — levhalar sistem gezinme çubuğunun altında kalıyor:** `showModalBottomSheet(useSafeArea: true)` üst/yanları korur, ALTI bilerek korumaz (klavye için `SafeArea(bottom: false)`). Alt boşluğu levhanın kendisi eklemeli: `max(viewInsets.bottom, viewPadding.bottom)` — ses levhası ve Süz levhası düzeltildi. `SafeArea` ile sarılan öteki levhalarda sorun yok.
  **KÖK NEDEN — "süz alanı kullanışlı değil":** `_Option` kutusunda `alignment: Alignment.center` vardı. `Wrap` çocuklarına GEVŞEK kısıt verir ve hizalaması olan bir kutu gevşek kısıtta en geniş ölçüyü alır — her seçenek satırın tamamını kaplıyor, levha ekranlarca uzuyordu. `Center(widthFactor: 1)` ile genişlik metne bağlandı; seçenekler çip gibi yan yana akıyor (`filter_sheet_layout_test.dart` bunu kilitliyor).
  **"2 kez ekle seçeneği":** editör alt çubuğundaki "Ekle" açılırının son satırı da `addAttachment` ("Ekle") anahtarını kullanıyordu — düğmeyle aynı ad. Yeni anahtar `addAttachmentMore` ("Diğer ek türleri…", 16 dil). İkinci tekrar: "Yeni öğe" satırı metin notunda alt çubuğun "Liste" segmentiyle aynı işi yapıyordu; artık yalnız liste notunda görünüyor.
  **KÖK NEDEN — "kaydet dememe rağmen not oluşturmuyor":** not GERÇEKTEN oluşuyordu. Yeni notun `orderIndex`'i onu "Diğerleri" bölümünün başına koyuyor; sabitlenmiş kartların altında, çoğu ekranda görünür alanın DIŞINDA kalıyor. Satır da sessizce temizlendiği için ekranda hiçbir şey değişmiyor, kullanıcı kaydın kaybolduğunu sanıyordu. ÇÖZÜM: kayıttan sonra klavye kapanır, kart `focusedNoteProvider` ile vurgulanıp görünür alana kaydırılır ve "Notu aç" düğmeli bir bildirim çıkar. (Yazma yolu değişmedi.)
  **Ayarlar → AI görünümü:** "Gelişmiş" katlanır bölümünün ilk çocuğu, etiketi kutunun ÜSTÜNE taşan bir form alanıydı ve `childrenPadding`'de üst boşluk yoktu — etiket başlığın üstüne biniyordu. Ayrıca tema alanları yalnız dolguyla çiziliyor, kâğıt temada dolgu kart zeminiyle aynı olduğundan alanların sınırı görünmüyordu: AI bölümündeki alanlara görünür kenarlık (`_aiFieldDecoration`), anahtar satırlarına tek tip biçim (`_AiSwitchTile`) verildi.
  **NOT**: bu oturumda Flutter SDK ortamda YOKTU; `analyze`/`test` çalıştırılamadı, doğrulama CI'ya bırakıldı. Yeni l10n anahtarı hem 16 ARB'ye hem `lib/l10n/generated/` altındaki dosyalara elle eklendi (CI `pub get` sırasında zaten yeniden üretiyor).

- 2026-08-04: **KÖK NEDEN — "API anahtarı yoksa sesli asistanda not oluşmuyor".** Konuşma üç ayrı yoldan nota dönüşüyor ve ikisinde yapay zekâ ARADA ZORUNLU duruyordu:
  (1) **Ses levhası, kayıt yolu** (cihazda yerleşik konuşma tanıma YOKSA — Windows ve tanıma bileşeni kapalı Android cihazlar): konuşma m4a olarak kaydedilip `transcribeAudio` ile yazıya döktürülüyor. Anahtar yok / kota dolu / ağ yoksa o çağrı düşüyor, levha hata ekranına geçiyor — ve kayıt dosyası ÇAĞRIDAN ÖNCE silinmiş olduğu için (`File(path).delete()` satırı okuma ile döküm arasındaydı) konuşulan her şey yok oluyordu. ÇÖZÜM: dosya artık yalnız döküm BAŞARILI olunca silinir; başarısızlıkta levha gözden geçirme evresine geçer, kaydı elinde tutar ve sonuç kaydında `audioPath` ile çağırana devreder. Not, SES EKİYLE oluşur (`prepareAudio`); metin alanı boş kalır, kullanıcı isterse yazar. AI isteyen çipler (özetle/böl/düzelt) o durumda gizlenir — hepsi aynı hatayla düşerdi.
  (2) **Sesli asistan (`finish`)**: yedek yol `on GeminiException` ile sınırlıydı. Anahtarsız kullanıcıda ağ/eklenti kaynaklı BAŞKA bir istisna çıktığında (GeminiException değil) dış `catch (_)` yakalayıp yalnız hata gösteriyordu — not hiç oluşmuyordu. Artık yedek yol HER hatayı yakalar. TUZAK: yedek genişleyince, aynı try içindeki "güvenlik ağı" bloğunun (oluşan notu dökümle doldurma + hatırlatıcı çıkarma) kendi Firestore hatası da yedeği tetikleyip İKİNCİ bir not oluşturabilirdi; blok try'dan çıkarıldı ve kendi (yutulan) try'ına alındı.
  (3) **Ana ekran, çip yolu**: `rewriteText` yalnız `GeminiException` için yakalanıyordu ve içindeki `if (!mounted) return;` fonksiyondan ÇIKIYORDU — o dönüşte not oluşturma kodu hiç çalışmıyordu. Artık her hata yakalanır ve `mounted` yalnız BİLDİRİMİ atlar.
  **KURAL**: sesten nota giden hiçbir yolda yapay zekâ ZORUNLU HALKA olmamalı — AI yalnız iyileştirir; düşerse ham döküm, o da yoksa ses kaydı nota girer.

- 2026-08-04: **KÖK NEDEN — "yeni not kısmında not bazen oluşuyor bazen oluşmuyor".** Üç ayrı sebep, üçü de "not yok" gibi görünüyordu:
  (1) **İKİ AYRI YAZIM**: hızlı yakalama önce BOŞ not oluşturup (`createNote`) sonra gövdeyi ayrı bir `updateFields` ile yazıyordu. İki yazım arasında doküman boştur; Firestore o aralıkta bir anlık görüntü yayınlarsa not ana ekran süzgecinden (`!n.isEmpty`) düşer. Zamanlamaya bağlı olduğu için "bazen". ÇÖZÜM: `createNote` artık `body` ve `folderId` alıyor, içerik TEK yazımda gidiyor — doküman hiçbir an boş kalmıyor.
  (2) **BEKLEYEN SUNUCU DAMGASI**: `updatedAt` alanı `FieldValue.serverTimestamp()` ile yazılıyor ve sunucuya ulaşana dek YEREL kopyada NULL okunuyor. "Son düzenlenen" sıralamasında tarihsiz not `dateBuckets` içinde "DAHA ÖNCE" kovasına, yani listenin en DİBİNE düşüyordu; ağ hızlıysa saniyesinde "BUGÜN"e sıçrıyor, yavaşsa dipte kalıyordu. ÇÖZÜM: `Note.fromDoc` artık `doc.metadata.hasPendingWrites` doğruysa tarihi ŞİMDİ kabul ediyor (yalnız bekleyen yazımda; eski kayıtların tarihi uydurulmuyor). `cleanupEmptyNotes` bundan etkilenmez — 2 dakika eşiği zaten geçilmiyor.
  (3) **AÇIK SÜZGEÇ/ARAMA**: yeni not sade bir metin notu; "Yıldızlı" süzgeci, seçili bir etiket ya da yazılı bir arama varken hiçbirine uymaz ve listede hiç belirmez. Kullanıcı için bu, notun oluşmamasıyla aynı şey. ÇÖZÜM: kayıttan sonra notu GİZLEYECEK süzgeçler temizleniyor (klasör süzgeci kalır — not zaten o klasöre doğuyor).

- 2026-08-04: **Sekiz maddelik ikinci arayüz paketi** (ekran görüntüleriyle bildirildi).
  **Ses levhası çipleri**: yatay kaydırılan liste ekranın dışına taşıyordu ("Asistan oluştursun" görünmüyordu); `Wrap` ile taşan çip alt satıra iner, hepsi tek bakışta görünür.
  **Hızlı not satırından mikrofon KALDIRILDI**: sağ altta zaten kalıcı bir sesli yakalama düğmesi var, aynı iş iki yerdeydi.
  **FAVORİ SÜZGEÇLER**: Süz levhasındaki her seçeneğin sonunda yıldız var; yıldızlanan süzgeç ana ekranda "Süz"ün sağında tek dokunuşluk çip olur (`favoriteFiltersProvider`, jetonlar `filter:`/`tag:`/`folder:`/`sort:`). Silinen klasör/etiketin jetonu çözülemez ve çizilmez — ayrı temizlik gerekmez. Uygulanmış olan favori çizilmez (solundaki kaldırılabilir çip onu zaten gösteriyor). Levhaya ayrıca "Notları sırala" (elle sürükleme kipi) düğmesi kondu: o kip yalnız ⋮ menüsündeydi ve sıralama arayan kullanıcı Süz levhasını açıyordu.
  **Çöp kutusu 24 saat → 30 GÜN** (`NotesRepository.trashRetention`). Yorum "30 gün" diyordu, kod 24 saat siliyordu; gerçek artık yorumla aynı.
  **"Ekle" alanı tek levhaya indi** (`editor/attach_sheet.dart`): iki katman (küçük açılır menü + ayrı "tüm ekler" levhası) kaldırıldı, on üç seçenek iki sütunlu tek sayfada. "Yeni öğe" çıkarıldı — alt çubuğun kendi liste/metin segmenti aynı işi yapıyor.
  **Not içindeki AI levhası** Yapay Zeka sayfasının dilini konuşuyor: üstte günlük puan çubuğu (`AiPointsBar` herkese açık yapıldı), altında asistan satırı, sonra iki sütunlu iş kutuları. Düz ListTile listesi kalktı.
  **Sesli düğme varsayılanı `tap`** (bas-başlat / bas-bitir): basılı tutmak uzun konuşmada yoruyor ve parmak kayınca kayıt kesiliyordu.
  **Sohbetin adı "Not Asistanı"** (`chatTitle` + `aiChatWithNotes`, 16 dil).

- 2026-08-04: **AI mantığı denetimi** (kullanıcı: "asistan ve sesli not işleyişi doğru mu"). Mimari sağlam çıktı (kapı/kota, sağlayıcı teli, araç döngüsü, sesten-nota yedekleri); dört gerçek kusur bulundu ve düzeltildi.
  **KÖK NEDEN — sesli notta ÇİFT not**: `voice_assistant.dart finish()` yedek yolu KOŞULSUZ not kuruyordu. Asistan `create_note`'u çağırıp notu kurduktan SONRA çağrı düşerse (6 tur sınırı, sonraki turda ağ hatası) aynı konuşmadan iki not oluşuyordu. `resultNoteId` zaten doluysa yedek artık not kurmuyor, yalnız "kaydedildi" diyor — içerik eksikse arkadaki güvenlik ağı dökümle dolduruyor. TUZAK: araç çağrısı geri arama içinde başarılı olabilir ama SARAN çağrı yine de fırlatabilir; "hata = hiçbir şey olmadı" varsayımı araç çağrılı akışlarda yanlıştır.
  **KÖK NEDEN — "Dinle" ekranında sonsuz çark**: `listen_screen.dart _makePodcast` yalnız `GeminiException` yakalıyordu, `finally` de yoktu. Gemini dışı bir istisnada (güvenli depo okuması, dosya sistemi, eklenti) `_generating` true kalıyor ve ekran süresiz dönen çarkta takılıyordu. Projedeki diğer beş AI çağrı yerinde genel `catch` + `finally` vardı, burada eksikti.
  **KÖK NEDEN — semantik arama yedeğe düşmüyor**: `SemanticIndex.search` boş vektör listesinin `.first`ine gidip `StateError` atıyordu; `semanticSearchProvider` yalnız `GeminiException` yakaladığı için düz metin araması devreye girmiyor, arama hata ekranına düşüyordu. Muhafız kök nedene (paylaşılan `GeminiService.embedTexts`) kondu: vektör gelmezse `GeminiException` atar, mevcut yedek çalışır.
  **BYOK/premium'da yanlış puan çubuğu**: sınırsız kullanıcı dahili kapıdan hiç geçmediği için sayaç azalmıyor, `AiPointsBar` sürekli "30 / 30" gösteriyordu (Yapay Zeka sayfası + not içi AI levhası). Ayarlar ekranı ayrımı zaten doğru yapıyordu (`_BuiltInAiStatus` → `aiBuiltInByok`); iki gösterim yeri `aiUnlimitedProvider` ile gizlendi (yeni l10n anahtarı gerekmedi).
  **NOT (kapsam dışı, bilinçli)**: PDF özeti `AiTask.document` değil `AiTask.general` modelini kullanıyor. Ayardaki etiket zaten "Podcast ve belge sohbeti" dediği için tutarsızlık değil; değiştirilmedi.
  **Doğrulama**: `flutter analyze` temiz, `flutter test` 327/327 yeşil. Sesli asistan ve semantik arama için Firestore/servis sahtesi olmadığından bu iki düzeltmeye yeni test YAZILMADI — muhakemeyle doğrulandı, cihazda görülmedi.

- 2026-08-05: **KALANLAR temizliği — altı maddelik paket** (kullanıcı: "kalanlarda iş varmı varsa yap hepsini kalmasın"). Listenin 33 maddesinden 21'i ya kullanıcının konsol/gözle-bakma işi ya bilinçli karar/platform sınırı; yapılabilir 6 kod maddesi bu oturumda kapatıldı.
  **KÖK NEDEN — sürüklerken kenar kaydırması yok**: liste serbest görsel tuvalinin içinde `shrinkWrap: true` + `NeverScrollableScrollPhysics` ile duruyor. `ReorderableListView`'ın yerleşik otomatik kaydırıcısı KENDİ görünüm kutusunu kaydırır; o kutu bu kipte kaydırılamaz olduğu için hiçbir şey olmuyordu. Dış kaydırıcıya `ScrollController` PLUMBLAMAK yanlış yol olurdu (aynı controller iki ScrollPosition'a bağlanır, assert patlar) — çözüm `Scrollable.maybeOf(context)`: ItemsEditor'ın context'i zaten DIŞ kaydırıcının çocuğu, oradan alınan `ScrollableState` üzerinden `onReorderStart/End` + `Listener.onPointerMove` ile kenar kaydırması elle yürütülüyor. Bant matematiği ayrı işlevde (`reorderAutoScrollStep`) — widget kurmadan sınanabilsin diye. TUZAK: bant kutunun yarısından büyükse üst ve alt bantlar örtüşür ve parmak nerede olursa olsun kaydırma tetiklenir; bant `min(band, yükseklik/2)` ile kısılıyor.
  **Biçim şeridinde aktif biçim vurgusu**: `activeFormats(text, start, end)` eklendi ve tanımı BİLEREK `toggleFormat` ile birebir aynı — imleçte soldaki karakterin biçimi, seçimde yalnız aralığın TAMAMINI kaplayan biçimler. Farklı bir tanım seçilseydi vurgu yalan söylerdi: basılı görünen düğmeye basınca biçim kalkmaz, eklenirdi. Şerit `FormatTarget`in controller'ına abone (TextEditingController seçim değişiminde de bildirir); `_setFormatTarget` yalnız şerit AÇIKKEN setState çağırıyor (odak her satırda değişiyor, kapalıyken çizimi etkilemiyor).
  **"Kopyaları temizle" — AI'sız benzerlik**: embedding kotayı harcar ve yalnız Gemini'de var; kopya notlar zaten anlamca değil METİNCE aynı. Üçlü harf kümesi (trigram) üzerinde Jaccard yerelde ölçüyor (`note_similarity.dart`, eşik 0.8). O(n²) iki ucuzlatmayla: trigram kümeleri bir kez hesaplanır ve liste küme boyutuna göre sıralanıp oran eşiğin altına düşünce iç döngü kırılır (Jaccard `min/max` oranını aşamaz). 12 karakterden kısa notlar hiç karşılaştırılmıyor — kısa metinde örtüşme rastlantısal. Silme değil ÇÖP KUTUSU ve önce kümeler gösteriliyor: ölçüm yaklaşık, körlemesine silmek yanlış eşleşmede veri kaybı olurdu.
  **"SON İŞLEMLER"**: `AiHistory` prefs'te en fazla 10 kayıt; yalnız işin ADI ve zamanı — soru metni/not içeriği/model yanıtı YAZILMAZ (KVKK). Yalnız BAŞARILI iş kaydediliyor. Göreli zaman ("3 dk önce") yerine intl'in saat/tarih biçimi kullanıldı: dört yeni l10n anahtarı ve 16 çeviri gerektirmiyor.
  **Ayar araması satır düzeyine indi**: `_Area.children: List<Widget>` → `rows: List<_SettingRow>` (başlık + anahtar kelime). Kural: ALANIN kendisi eşleşiyorsa (kullanıcı "ses" yazdı) bölümün TAMAMI, eşleşmiyorsa yalnız eşleşen satırlar. `_Area`/`_SettingRow` private kaldı; test `@visibleForTesting` iki yapıcı üzerinden nesne kuruyor (tip dışarı açılmadan — Dart'ta private tipin public üyeleri çıkarımla çağrılabiliyor).
  **KÖK NEDEN — widget uygulamanın temasını giymiyordu**: widget renkleri yalnız kaynak niteleyicilerinden (`values/` + `values-night/`) geliyordu, onları seçen şey SİSTEM gece modu. Uygulamada Koyu seçip telefon açık modda kalınca widget kağıt duruyordu. Çözüm: Dart `effectiveThemeModeProvider`'ı `widget_theme` anahtarına yazıyor ("light"/"dark"/"system"), Kotlin sistemden FARKLI seçimde renkleri çalışma anında uyguluyor ("system"de hiç dokunmuyor — niteleyiciler zaten doğru). TUZAK: zemini düz renge çevirmek köşe yarıçapını ve 1px kenarlığı yok eder; minSdk 23'te çizimi çalışma anında boyayacak RemoteViews yolu yok (`setColorStateList` API 31+). Bu yüzden her şekil çiziminin palete SABİTLENMİŞ `_light`/`_dark` ikizi üretildi ve `setInt(id, "setBackgroundResource", ...)` ile takılıyor. `effectiveThemeModeProvider` autoDispose olduğu için WidgetService onu izleyemiyor (autoDispose olmayan sağlayıcı autoDispose'u dinleyemez) — kaynakları (`themeChoiceProvider`, `darkScheduleProvider`) dinlenip değer okuma anında hesaplanıyor.
  **Doğrulama**: `flutter analyze` temiz, `flutter test` 359/359 yeşil (32 yeni test), `tool/check_arb.ps1` 16 dilde 531 anahtar tam, `flutter build apk --release` Kotlin'i derliyor. Widget'ın cihazdaki görünümü DOĞRULANMADI (KALANLAR'a yazıldı).

- 2026-08-05: **KÖK NEDEN — "kelimenin içine tıklayıp biçim uygulayınca ham markdown çıkıyor".** `toggleFormat` seçim yokken imlecin bulunduğu yere BOŞ biçim kutusu açıyordu (`**` `**`). İmleç bir kelimenin ORTASINDAysa bu iki ayrı şekilde bozuluyordu: (1) `_` (italik) ve `~` (altı çizili) çözümleyicide kelime içinde SAYILMIYOR — `_formatPattern`'daki `(?<!\w)`/`(?!\w)` koşulları düz metindeki "dosya_adi_uzun" gibi yazımları korumak için konmuştu; sonuç `merh__aba` hiçbir zaman italiğe dönüşmüyor, kullanıcı notunda HAM alt çizgi görüyordu. (2) `**` çözümleniyor ama kelimeyi `merh****aba` diye ikiye bölüyordu.
  **ÇÖZÜM** Word/Docs davranışı: imleç kelimenin içindeyse (iki yanında da kelime karakteri var) biçim KELİMENİN TAMAMINA uygulanır; kelime kenarında ya da boşlukta imleç eski davranışta kalır (boş kutu = "biçimli yazmaya başla") — o durumda işaretler zaten çözümleniyor.
  **TUZAK**: kelime sınırı `\w` ile hesaplanamaz. Dart'ta unicode bayrağı olmadan `\w` = `[A-Za-z0-9_]`, yani "çalışma"daki "ş" kelime karakteri sayılmaz ve aynı tıklama Türkçe kelimede başka, ASCII kelimede başka davranırdı. `_wordChar` için `[\p{L}\p{N}_]` + `unicode: true` kullanıldı. Aynı tutarsızlık çözümleyicideki `(?<!\w)` koşulunda HÂLÂ var (Türkçe harften sonraki `_` biçim sayılıyor, ASCII harften sonraki sayılmıyor) — kelime-içi yol artık oraya hiç düşmediği için kullanıcıya yansımıyor, ama düz metinde `çalış_ma_` yazan biri hâlâ istemeden italik alabilir.
  **Doğrulama**: önce KIRMIZI repro (`merh__aba`, `merh****aba`), sonra 11 testlik `format_caret_in_word_test.dart` YEŞİL, tam paket 370/370.

- 2026-08-05: **KARAR — APK'yı CI değil YEREL derliyoruz** (kullanıcı: "apk derlemesin git sen derle kur"). Commit başlığına `[apk]` KONMAZ; `.github/workflows/build.yml` yalnız o etiketi görünce APK derliyor (analiz + test her push'ta zaten koşuyor). Telefona kurulum akışı: `flutter build apk --release --target-platform android-arm64 --dart-define-from-file=env.json` → `flutter install --release -d <cihaz>`. Sebep: CI derlemesi ~10 dk sürüyor ve cihaz elin altındayken gereksiz; yerel derleme aynı bayraklarla aynı APK'yı veriyor.

- 2026-08-05: **KÖK NEDEN — "Yapay Zeka sayfasında 2 kutu var" (dört iş kutusunun tamamı görünmüyordu).** `ai_hub_screen.dart`'taki iki `Row` `crossAxisAlignment: CrossAxisAlignment.stretch` kullanıyor ve doğrudan `ListView`'ın çocuğu. Stretch çocukları Row'un YÜKSEKLİĞİNE gerer; ListView'da dikey alan sınırsız olduğundan Row sonsuz yükseklik alıyor.
  **TUZAK — neden fark edilmedi:** debug'da bu bir assert (`BoxConstraints forces an infinite height`) ama **release'de assert ÇALIŞMAZ**. Yayın APK'sında çökme yok; kutular sonsuz yükseklikle yerleşiyor ve altındaki HER ŞEY (iki kutu satırı, SON İŞLEMLER, "Belge oku", puan yenileme notu) erişilemez uzağa itiliyor. Kullanıcı sayfada yalnız sohbet kartı ile brifing satırını görüyor. Yani "eksik özellik" gibi görünen şey aslında yerleşim çökmesiydi.
  **KAYNAK**: `34fa65c` (2026-08-04 devir paketi, "4 ekran yeniden tasarım") — o gün geldi, o bölümün widget testi olmadığı için bir gün boyunca fark edilmedi. Ben 2026-08-05'te ikinci kutu satırını eklerken aynı kalıbı kopyaladım.
  **ÇÖZÜM**: her iki Row `IntrinsicHeight` ile sarıldı — Row'a en uzun çocuğun yüksekliği verilir, stretch sınırlı hale gelir. `Column` üzerindeki stretch kullanımları (login, ai_sheet, qr, slide_canvas) ETKİLENMEZ: orada stretch yatay ve genişlik zaten sınırlı.
  **KURAL**: `CrossAxisAlignment.stretch` olan bir **Row** asla kaydırılabilir bir listenin doğrudan çocuğu olamaz; ya `IntrinsicHeight` ya sabit yükseklik gerekir. Aynı hata sınıfı release'de sessiz olduğundan yalnız widget testiyle yakalanır — `ai_hub_tiles_test.dart` bunu kilitliyor.

- 2026-08-05: **Kalanlardan üç yapılabilir madde** (kullanıcı: "kalanlarda ki işlerden yapılabilir olanları yap"; gece, gözetimsiz — bu yüzden cihaz/konsol isteyen 20+ madde ile büyük riskli paketler [çakışma çözümü + sürüm geçmişi, Play Billing, PPTX portu] bilerek AÇILMADI).
  **(1) Toplam depolama tavanı** (ücretsiz 50 MB / premium 2 GB): tek dosya sınırı (10/50 MB) maliyeti öngörülebilir kılmıyordu — 10 MB'lik eklerden 500 tane aynı faturayı yakıyor; lifetime paketinin maliyeti ancak TOPLAM tavanla hesaplanabilir. Sayım `cloudAttachmentBytes(notes)` (notlardaki `sizeBytes` toplamı) → `storageUsedBytesProvider`. Denetim TEK kapıda: `AttachmentRepository._store` (görsel/PDF/sunum/kopyala hepsi oradan geçiyor) + `prepareAudio` (dosyayı kopyaladığı için `_store`'a girmiyor). TUZAK: kırpma da `_store`'dan geçiyor ve YERİNİ ALDIĞI ek hâlâ sayımda — `freedBytes` düşülmeseydi tavana dayanmış kullanıcı görselini KIRPAMAZDI (kırpma neredeyse her zaman yer boşaltır). Görüntülü not sayılmaz (buluta hiç yüklenmiyor). KARAR: çöp kutusundaki notlar sayılmaz — sayılsaydı "yer açmak için sil" işe yaramaz görünürdü (çöp 30 günde boşalıyor); karşılığında gerçek Storage kullanımı sayımın biraz üstünde olabilir. `StorageFullException extends FileTooLargeException`: arayüzdeki 9 `on FileTooLargeException` yakalaması onu da tutuyor, yani yeni bir çağrı yeri eklendiğinde ek sessizce TAVANSIZ geçmez — en kötü ihtimalle mesaj "dosya çok büyük" der. Provider'a `usedBytes: () => ref.read(...)` closure'ı geçildi (watch DEĞİL): notlar her değiştiğinde depo yeniden kurulsaydı yükleme kuyruğu elindeki nesneyi kaybederdi.
  **(2) Tarih ayrıştırıcısı çok dilli** (`tr_datetime.dart` → `spoken_datetime.dart`, tr/en/de/es): mantık ortak, her dil bir sözlük girişi. Türkçe davranışı birebir korundu (eski testler değişmeden geçti). DİL TUZAKLARI: Almanca "morgens"/"übermorgen" içinde "morgen" GEÇER ama kelime değildir (mevcut kelime-sınırı denetimi ikisini de eliyor — `\b` ASCII olduğu için sınır elle denetleniyor); İspanyolca "mañana" hem yarın hem sabah demek, "la/esta mañana" GÜN değil bölümdür (geriye bakışlı kalıp); Almanca "halb 9" 8:30 demek olduğundan BİLEREK yok sayıldı (yanlış saat kurmaktansa modele düşmek iyi). Çağrı yerleri dil kodunu tek tek hesaplamasın diye `parseSpokenDateTimeNow` (`Intl.getCurrentLocale`) eklendi — biri unutulsaydı o akış sessizce Türkçeye sabitlenirdi.
  **(3) Semantik aramanın boş vektör yedeği artık testli** (`test/embed_texts_test.dart`): `ApiKeyStore.read` override edilebiliyor (sınıf açık) ve `Dio.httpClientAdapter` değiştirilebiliyor — Firestore sahtesi gerekmeden servis sınanabiliyor. AI denetiminin diğer yarısı (sesli nottaki çift-not koruması) hâlâ testsiz: Firestore + mikrofon sahtesi ister.
  **ORTAM**: bu oturumda Flutter SDK YOKTU — `analyze`/`test` yerelde koşmadı, doğrulama CI'ya bırakıldı; l10n'un 3 yeni anahtarı 16 dile ve üretilen Dart dosyalarına ELLE (script'le) eklendi. TUZAK: `gen-l10n` yer tutucu (`placeholders`) tanımlarını YALNIZ şablon dilde (app_tr.arb) tutar; diğer arb'lere `@anahtar` blokları yazılmaz.

- 2026-08-05: **Güvenlik + performans + pil denetimi (üç paralel tarama) ve toplu düzeltme.** Önemli kararlar/kökler:
  - **firestore.rules `aiQuota` açığı**: aynı pencerede `points >= resource.points` EŞİTLİĞE izin veriyordu — değiştirilmiş istemci sayacı hep aynı değerde yazıp kotayı hiç doldurmadan sınırsız dahili AI kullanabilirdi. Katı `>` + `hasOnly(['dayStart','points'])` + mutlak tavan (1000) eklendi. **KURALLAR HENÜZ YAYINLANMADI** — `firebase deploy --only firestore:rules` gerekiyor.
  - **Yedek JSON'u ekleri `downloadUrl` ile yazıyordu**: `?token=`'lı URL Storage kurallarını atlar ve süresi dolmaz; yedeği gören herkes tüm eklere oturumsuz erişirdi. Artık `storagePath` yazılıyor (geri yükleme ekleri zaten atlıyor).
  - **Not kilidi `LockedOut` ile aşılabiliyordu**: 5 kez yanlış parmak izi → local_auth PlatformException → catch bloğu `true` dönüyordu. Artık yalnız NotAvailable/NotEnrolled/PasscodeNotSet serbest (Windows Hello kapalı senaryosu), gerisi kapalı.
  - **Kilitli not widget'a sızıyordu**: `widget_service` `locked` süzmüyordu (uygulama içindeki diğer yüzeyler süzüyor). Tek satır: `!n.locked`.
  - **Android konuşma tanıyıcı restart döngüsü frensizdi**: sessizlik kapanışında anında yeniden kurulum; mikrofon kapılmışsa ana thread'de sıcak bind/unbind döngüsü, dinleme unutulursa süresiz mikrofon. Eklendi: hızlı-restart üstel geciktirme + 5 denemede kapatma, 2 dk ilerleme yoksa oturum kapatma, `onStop`'ta bırakma. Dart tarafı `speech_background`/`speech_idle` kodlarında dikteyi gözden geçirmeye taşıyor (metin kaybolmaz).
  - **Arama debounce'suzdu**: her tuş vuruşu tüm notları tarıyor, anlamsal modda ayrıca embedding HTTP isteği atıyordu (17 karakter = 15 istek). `debouncedSearchQueryProvider` (350 ms) eklendi; arama kutusu anlık sağlayıcıyı, süzme/anlamsal arama geciktirilmişi izliyor. Sorgu vektörü artık sorgu metnine göre önbellekli, not vektörleri normalize `Float32List` (kosinüs → düz iç çarpım).
  - **PDF/DOCX dışa aktarma ana izolede**ydi (font altkümeleme + zip deflate = saniyelerce donma). `compute()`'a taşındı. **TUZAK**: `DateFormat` yerel sembollerini flutter_localizations YALNIZ ana izolede yükler — tarih etiketi ana izolede biçimlenip izoleye String geçirilmeli, yoksa `tr` biçimlendirme izolede fırlatır.
  - **`_clockProvider` dakikalık tik** tüm MaterialApp'i günde 1440 kez yeniden kuruyordu (zamanlama açıkken); tek Timer bir SONRAKİ start/end sınırına kuruluyor (günde 2 uyandırma).
  - **`trashStreamProvider` ve `duplicateNotesProvider` kalıcıydı**: bir kez açılan çöp/AI Hub ekranı oturum boyu ikinci tam koleksiyon dinleyicisi + her snapshot'ta O(n²) kopya taraması bırakıyordu. İkisi de autoDispose; kopya taramasının trigram kümeleri `(id, updatedAt)` anahtarlı önbellekte.
  - **`main()` açılışı**: App Check (Play Integrity 300-1500 ms) ve yüksek yenileme isteği `runApp` SONRASINA alındı — ikisi de ilk kareyi beklemiyordu.
  - **Brifing bildirimi exact alarm'dı**: her sabah Doze kırmak + `USE_EXACT_ALARM` Play politikası riski, birkaç dakika hassasiyet kazandırmıyordu → `inexactAllowWhileIdle`. Not hatırlatıcıları bilerek exact kaldı.
  - **build() içinde `existsSync`**: kart/ek başına her karede senkron stat. `localFileExists` önbelleği (yalnız POZİTİF sonuç önbelleklenir; silen yol `forgetLocalFile` çağırır — negatif önbellek indirme bitince bayat kalırdı).
  - **Masaüstü OAuth refresh token'ı hiçbir yer okumuyordu** ama her girişte isteniyor ve diske yazılıyordu → `access_type=offline`/`prompt=consent` ve saklama kaldırıldı (ölü `refresh()` de silindi). `client_secret` KALDI: Google "Desktop app" istemcisi token değişiminde istiyor.
  - Ertelenenler KALANLAR'da: `localPath`'in Firestore'a yazılmaması (cihaz-yerel eşleme ister), AI önbellek şifrelemesi, Storage toplam kota kuralı, watchNotes artımlı ayrıştırma, dalga formu CustomPaint.
- 2026-08-05: **Metin seçimi "premium" yapıldı** (`sentence_select.dart`): (1) çift dokunuş noktalamayla yapışık token'ı (API anahtarı, URL, sürüm no) BÜTÜN seçer, kenar tırnak/parantez/virgül kırpılır; (2) aynı kelimeye ikinci çift dokunuş token→cümle tırmanır (tutamak daraltması korunur); (3) cümle sınırında kısaltmalar (`bkz.`, `Dr.`, `T.C.`…), tek harf+nokta (ad baş harfi), küçük harfle süren sıra sayısı (`3. katta`) ve küçük harfle süren üç nokta artık cümle sonu sayılmıyor. **KÖK**: noktalama ÖBEĞİ yalnız ilk karakterinden yargılanmalı — "..."ün son noktası tek başına değerlendirilince kısaltma/üç nokta kuralları atlanıyordu.

- 2026-08-05 (devam): **Denetimin ertelenen maddeleri de işlendi** ("iş bırakma" isteği):
  - **`localPath` artık Firestore'a YAZILMIYOR**: yol cihazda türetiliyor — depo kalıbı belirlenimci (`<appSupport>/attachments/<noteId>/<ekId>_<dosyaAdı>`), taban `main()`'de bir kez çözülüp `appSupportPath`'e konuyor; `Attachment.fromMap(noteId:)` yolu oradan kurar, eski belgelerdeki alan yalnız yedek. **TUZAK**: türetilen yol `_store`/`prepareAudio`/`prepareVideo` adlandırmasıyla birebir aynı kalmalı; adlandırma değişirse eski ekler "yerelde yok" görünür.
  - **`watchNotes` artımlı**: `docChanges` ile yalnız değişen doküman `Note.fromDoc`tan geçer; önbellek akış başına Map. İlk snapshot'ta hepsi "added" gelir.
  - **Yedek dışa aktarımı kilitli not varsa kimlik istiyor** (`authenticateForNote`) — kilit ekran perdesiyken yedekten düz metin sızıyordu.
  - **AI önbelleği**: kilitli nottan türeyen çıktı yazılmıyor (tek kapı `_run`/`allowCache`); G/Ç async'e çevrildi; budama oturumda bir kez ve stat'lar sıralama DIŞINDA.
  - **Asistan silmesi onaylı**: sohbette `delete_note` çalışmadan modal onay (`confirmAssistantDelete`), sesli akışta silme tümden kapalı (eller serbest, kutu gösterilemez). Yeni l10n anahtarı `assistantDeleteConfirm` (tr+en; kalan diller çeviri dalgasına).
  - Dalga formu tek CustomPaint (`repaint: ValueNotifier`) — vsync başına 24 widget'lık setState kalktı. `cleanForSpeech` 20k+ karakterde compute() izolesinde (testler `cleanForSpeechSync`). Hatırlatıcı listesi builder'lı.
  - **storage.rules toplam kota**: kurallarla ZORLANAMAZ (bucket kullanımı sayılamaz) — Cloud Function işi olarak KALANLAR'da netleştirildi.

- 2026-08-06 (2. tur): **Genel kullanım denetimi — beş paralel tarama + düşmanca doğrulama + taze göz** (kullanıcı: "yazma/kaydetme/kopyalama/yeni not/gezinme... eksikleri kapat, dış gözle tekrar değerlendir, otonom bitir"). ~45 doğrulanmış kusur kapatıldı (PR #61). Önemli kökler/kararlar/tuzaklar:
  - **KÖK NEDEN — kilitli not Arşiv/Çöp/Hatırlatıcı'da sızıyordu**: `openNoteRoute`'un kendi yorumu uyarmıştı ("kilit kontrolü iki yerde tekrarlanırsa biri unutulur"); arşiv doğrudan `context.push` kullanıyordu, üç ekran da önizlemeyi süzmüyordu. Kural: içerik gösteren HER yeni yüzey karta (`openNoteRoute` + `locked ? lockedNote : ...`) uymak zorunda. Gizli klasör bastırması da aynı akıbetteydi (kopyalar/hatırlatıcı/arşiv/çöp) — `suppressedFolderIdsProvider` artık public, dört tüketiciye uygulandı.
  - **KÖK NEDEN — widget "Yeni not" çift not açıyordu**: app_links'te `getInitialLink` bayrağı İŞARETLEMEDEN bağlantıyı verir, stream'in `onListen`'ı da aynı bağlantıyı ilk dinleyiciye gönderir (Android+Windows kaynağından doğrulandı). İkisini birden dinlemek = soğuk açılışta çift tetik. Tek doğru yol: yalnız `uriLinkStream`.
  - **KÖK NEDEN — "Not oluşturuldu" bildirimi hiç kapanmıyordu**: bu Flutter sürümünde AKSİYONLU SnackBar varsayılanı `persist: true` (kaynak: snack_bar.dart `persist = persist ?? action != null`) — zamanlayıcı hiç kurulmuyor. Aksiyonlu her snackbar'a `persist: false` yazılmalı.
  - **KÖK NEDEN — Geri al / AI "Değiştir" madde metinlerinde çalışmıyordu**: ItemsEditor denetleyicileri yalnız İLK kurulumda metin alıyordu; dış değişim ekrana yansımıyor ve o satıra yazılan ilk harf BAYAT metni nota geri yazıyordu. didUpdateWidget artık `setLogical` ile senkronluyor.
  - **Editör uzak değişiklikleri eziyordu**: dinleyici yalnız ekleri/AI özetini benimsiyordu; artık uzak SİLMEDE editör kapanıyor (`_deleted` muhafızı ŞART — kendi silmesinin gecikme-telafili snapshot'ı dalı ikinci kez tetikleyip ALTTAKİ rotayı da düşürüyordu), meta+sıra+görünüm alanları benimseniyor, kullanıcı hiç yazmadıysa içerik de canlı akıyor. LWW içerik kararı (2026-07-27) DEĞİŞMEDİ.
  - **Pano temizliği**: Kes/Kopyala ham işaret+çapa sızdırıyordu. Seçim menüsü `cleanClipboardMenuItems`, klavye `Action.overridable` devralması (`CopySelectionTextIntent` — EditableText kendi eylemlerini overridable kaydeder, üst ağaçtaki Actions kazanır; uymayan durum `callingAction`'a devredilir). `plainSelection` uçları işaretin dışına hizalar + boş kutuları süzer. Android'de "Eki kopyala" FileProvider yokluğundan HİÇ çalışmıyormuş (pasteboard `${packageName}.provider` ister, plugin cacheDir'e yazar → `cache-path`).
  - **TUZAK — `Note.isEmpty` genişletmesinin yan etkisi**: hatırlatıcılı metinsiz not artık silinmiyor AMA "boş sayılmama" AI muhafızlarını da deldi — dispose'daki oto-başlık/etiket artık ayrıca içerik (body/items/ek) kontrol ediyor; yoksa boş içerikle model çağrılırdı.
  - **TUZAK — PopScope + async işleyici**: geri tuşuna bağlanan async kapanış (`_stop`) yeniden-giriş kilidi ister; iki hızlı geri = iki pop = alttaki rota da kapanır. `canPop:false` + kaydederek çık deseni ses kaydı/çizim/sesli yakalamada; kalıcı kayıt hatasında ikinci geri kaydetmeden çıkarır (çıkışsız ekran bırakma).
  - **Karışık çok satırlı yapıştırma**: madde alanına `\n` gelirse satırlara bölünür (donanım Enter dahil); işaretli satırlar işaretli BLOĞA gider — "işaretsizler _items'ın başında" değişmezi (sürükle-sırala buna dayanır) yapıştırmada da korunmalı.
  - **Klavye açılış kasması**: her tuş vuruşu 3700 satırlık build'i setState'liyordu; saf yazımda (görünür hiçbir alan değişmedi + undo/redo durumu aynı) setState atlanır (`_sameVisual`). buildTextSpan'ın findLinks+stripRichMarkers taraması metin değişmediyse önbellekten.
  - **Süz levhası sıfırdan**: bölüm kartları + ikonlu tonal çipler (kenarlık kalabalığı yerine), seçili=primary. Klasör YÖNETİMİ (yeniden adlandır/gizle/sil) çip barı silindiğinde ERİŞİLMEZ kalmış (ölü kod `showFolderActionsSheet`) — seçili klasör çipindeki ⋮ ve uzun basışla geri bağlandı. Ders: bir yüzey silinince oradan açılan levhaların başka girişi var mı diye grep'lenmeli.
  - **Yedek geri yükleme kayıplıydı**: locked/archivedAt/color/frameColor/starred/createdAt/reminderAt artık geri yazılıyor (kilitli not kilitSİZ dönüyordu — gizlilik!). folderId bilinçli dönmez (başka hesapta anlamsız id).
  - **Anonim çıkış = veri kaybı**: çıkış onayı anonim hesapta açık uyarı + kırmızı düğme; profil kartındaki sabit "Senkronize edildi" anonimde "Yerel hesap" oldu. Hesap silmede `requires-recent-login` yedeği anonimde artık Google'a YÖNLENMİYOR ve uid eşleşmesi doğrulanıyor (yanlış hesabı silme riski).
  - **Diğer**: hatırlatıcı geçmişe kurulamıyor (2 seçici de), tek hatalı planlama kalanları iptal etmiyor (try döngü içinde) + exact izni kapalıysa inexact'e düşüş; kalıcı silme cihaz ek klasörünü de async temizliyor; kırpma çevrimdışı çalışıyor; QR "Vazgeç" taramaya devam ediyor; anlamsal arama uygulanmış süzgeçlere uyuyor (`noteMatchesFilter` tek tanım); redo eklendi (undo(current)/redoStep(current) — push redo'yu temizler); hızlı not satırı ayarlarla gizlenebilir (varsayılan GİZLİ, kullanıcı isteği).
  - **Doğrulama**: `flutter analyze` temiz, tam test 490+/490+ yeşil (bu oturumda Flutter 3.44.6 SDK kuruldu — CI ile aynı sürüm). Yanlış pozitif ayıklaması: `onReorderItem` yeni API, indeksleri kendisi düzeltir (klasik `newIndex-1` GEREKMEZ).

- 2026-08-06: **Gece turu (kullanıcı uyurken, "hepsini yap" talimatı).** Dört iş:
  1. **Ekran görüntüsü düzeltmeleri**: (a) liste maddesinde çift kaydırma — `_FloatRow` satırı BÜTÜN kaydırırken alan içi sarma çapaları da aynı banda girinti basıyordu; madde alanlarında alan içi çapa kapatıldı (`items_editor._wrapped` boş bant geçer, test güncellendi). (b) Tek satır kipinde taşan maddeye `…` göstergesi (TextField üç nokta koyamaz — taşma TextPainter ile ölçülüp alanın sağına ayrı `…` kondu). (c) Görsel araç paneli artık görsel/panel DIŞINA her dokunuşta kapanıyor (`NotePageCanvas`a translucent `Listener`; alttaki GestureDetector metin alanına giden dokunuşları hiç görmüyordu). (d) Klasör seçicide "Yeni klasör" EN ÜSTE alındı + süz levhasının Klasör bölümüne "+ Yeni klasör" çipi (bölüm klasör yokken de görünür; oluşan klasör süzgeç olarak seçilir).
  2. **Belge tarama + PDF taşıması (dosya-okuyucu projesinden — kullanıcı "direk kopyala, uyarla" dedi)**: `data/scan/` altına doc_edges (Hough kenar bulma), perspective (GPU homografi), scan_enhance (gölge giderme/keskinleştirme/uyarlamalı eşik), scan_ocr (ML Kit satır kutuları), scan_pdf (A4 + GÖRÜNMEZ metin katmanı — `PdfTextRenderingMode.invisible`, saydam renk İŞE YARAMAZ), scan_title (OCR'dan akıllı belge adı). Ekranlar: ScanReviewScreen (filtre/döndür/sil/köşe + "PDF olarak ekle"/"Görsel olarak ekle"), ScanEditScreen (köşe tutamaçları). Editör akışı: ML Kit → inceleme → aranabilir PDF eki (adı OCR'dan) YA DA görsel ekler (+eski OCR-gövde sorusu). **Masaüstünde tarama artık VAR**: seçilen fotoğraflar otomatik kenar bulma + perspektif borusundan geçer (`DocumentScan.available`). Testler de taşındı (doc_edges/scan_enhance/scan_title/perspective/scan_pdf — 42 test). Yeni bağımlılık: `google_mlkit_text_recognition` (cihaz içi, ücretsiz, AI kotası harcamaz).
  3. **Premium çalışması**: `/premium` ekranı — durum (premiumUntil), ücretsiz/premium karşılaştırması (puan 30→300, ek 10→50 MB, depo 50 MB→2 GB, otomatik günlük içerik), BYOK dürüstçe söylenir, "gözden kaçan özellikler" vitrini (tarama→PDF, anlamsal arama, sesli asistan, kilit, gizli klasör, dışa aktarma). Girişler: Ayarlar'daki durum satırı + AI Hub puan çubuğu. Satın alma Play Billing'e kadar bilgilendirme. KARAR: anlamsal arama premium'a BAĞLANMADI — embedding dahili modda zaten yok (BYOK gerekli), kapı koymak özelliği öldürürdü.
  4. Merge: PR #60 → main, `[apk]` işaretiyle (APK derlensin).

- 2026-08-06 (3. tur): **Videolar sayfada görseller gibi serbest + yerinde oynatma; tarama güncellemeleri dosya-okuyucudan.** (Kullanıcı: "notlarda videolar da resimler gibi serbest olabilsin ve oynatılabilsin olduğu yerde; belge tara ve PDF kısmını dosya-okuyucuda güncelledim, notlarda da güncelleyelim".)
  1. **Video = görsel serbestliği**: tek kapı `Attachment.floatsOnPage` artık `video` türünü de sayıyor (`asFile` ile şeride iner, "Sayfaya koy" geri getirir — `_canPlaceOnPage` genişletildi). Yeni video `_placeNewImage` ile imlecin satırına yerleşir. `NotePageCanvas`ta `_VideoBox`: video **olduğu yerde** oynar (ortada oynat/durdur; dokunuş düğmede kalır, kenara dokunmak seçer), taşıma/boyutlandırma/metin sarması görselle birebir aynı yol. Araç menüsünde videoya OCR/kopyala YOK, "Videodan not çıkar" VAR; tam ekran `VideoViewerScreen`e gider.
     **TUZAK — en-boy oranı**: `prepareVideo` `width/height` yazmıyor; `_resolve` oranı 1:1 varsayar ve video kare kutuda açılırdı. `_VideoBox` ilk çözümde doğal boyutu `onSize` ile eke kalıcılaştırır (yalnız alanlar boşken — döngü yok). Oynatıcı dinleyicisi yalnız oynuyor/durdu GEÇİŞİNDE setState çağırır; her karede çağırmak kutuyu boşuna ısıtırdı.
     **SINIR**: `video_player` Windows'ta yok ve video buluta çıkmıyor — dosya yoksa/oynatıcı açılamazsa kamera simgeli yer tutucu (kutu yine taşınabilir). Kart önizlemesi ve PDF/Word dışa aktarımı videoyu bilerek almıyor (değişmedi).
  2. **Tarama portu (dosya-okuyucu fd738b8'den)**: `scan_deskew.dart` (temkinli `worthApplying`: alan %45–98 + kimliğe-yakın-değil; testli) — ML Kit çıktısı da artık açılışta kendiliğinden düzelir (`_prepareAll`: ham fotoğrafta eski zorunlu `_autoCrop`, tarayıcı çıktısında temkinli `autoStraighten`). Köşe ekranına RawMagnifier büyüteci (1,8×, sürüklenen köşeyi izler). dosya-okuyucunun AYNI turdaki pdfium seçim düzeltmeleri ve taranmış-PDF yeniden yazımı TAŞINMADI: not'un PDF'i pdfrx (seçim yerleşik), PDF düzenleyici yok.
  3. Doğrulama: Flutter 3.44.6 yerel — `analyze` temiz, `flutter test` 477/477 yeşil (+6: deskew 4, video floatsOnPage 2).

- 2026-08-06 (4. tur): **Meta çipleri başlığın üstüne + iki kullanıcı hatası (imleç, kasma).**
  1. **Çipler başlığın ÜSTÜNE** (kullanıcı ekran görüntüsüyle: "başlık ve üst alan arasındaki boşluğa yerleşsin, yeni bir alan açılmasın, orası sıkışsın" — seçenek sunuldu, "başlığın hemen üstü + kompakt" onaylandı). O boşluk zaten vardı: üst barın 56 dp'lik bandında içerik küçük (11,5 punto tarih) olduğu için altı kullanılmıyordu. `header` sırası `[metaChips, titleField]` oldu, çipler `VisualDensity(-3,-3)` + `shrinkWrap` + 12,5 punto + dar silme kutusuyla sıkıştırıldı, başlığın üst boşluğu 8→2 dp. **Başlık bloğu UZAMADI, ~24 dp KISALDI.** TUZAK: `materialTapTargetSize` varsayılanı çipin görünen yüksekliğini değiştirmese de dokunma hedefini 48 dp'ye yuvarlayıp satıra 10+ dp ekliyordu — asıl sıkışma oradan geldi.
  2. **KÖK NEDEN — "yeni öğede imleç ancak yazmaya başlayınca çıkıyor (yalnız 'liste satırlarını tam göster' KAPALIYKEN)":** satır alt ağacının ŞEKLİ odakla değişiyordu — odaksızken `LayoutBuilder > Row > Expanded > TextField` ("…" taşma göstergesi için), odaklanınca çıplak `TextField`. Dokunuş odağı verir, gelen çizimde alanın öğesi başka konuma düştüğü için TextField (ve içindeki EditableText) state'i SIFIRDAN kurulur; yeni state odağı ZATEN almış bir düğümle açıldığından "odak değişti" olayı hiç gelmez ve imlecin yanıp sönme zamanlayıcısı başlamaz — ilk harfte beliriyordu. ÇÖZÜM: sarmalayıcıyı yalnız `expandItems` belirler (odaktan bağımsız); odak artık yalnız "…"in görünürlüğünü değiştirir. **KURAL: odak/seçim gibi sık değişen bir durum, metin alanının ağaçtaki KONUMUNU değiştiremez.** Test `editor_typing_perf_test.dart` state kimliğini kilitliyor.
  3. **KÖK NEDEN — "yazarken kasma" (liste notunda):** saf-yazım kısayolu (`_sameVisual`, 2026-08-06 2. tur) madde listelerini `identical` ile karşılaştırıyordu; `ItemsEditor` her tuşta YENİ liste nesnesi ürettiği için kısayol liste notunda HİÇ çalışmıyor, her harf 3700 satırlık editör build'ini (tuval, çipler, ek şeridi, tüm satırlar) yeniden kuruyordu. Kısayol yalnız gövde/başlık alanında işliyordu. `sameItemsVisually` (public, testli): metin dışındaki her fark (sayı/sıra/kimlik/işaret) VE metnin DOLULUĞU görünür sayılır, metnin kendisi sayılmaz.
  4. **Kasmanın ikinci kaynağı — tuş başına N metin yerleşimi:** "…" göstergesi taşmayı her satırda, her çizimde `TextPainter.layout` ile ölçüyordu; (3) yüzünden bu tuş başına satır sayısı kadar oluyordu. Ayrıca `resizeToAvoidBottomInset` varsayılan açık olduğu için klavye açılıp kapanırken (yani GERİ giderken de) gövde her karede yeniden yerleşiyor ve ölçümler yine koşuyordu — "geri giderken kasıyor" şikayetinin payı burası. Ölçüm artık satır başına (metin+genişlik+punto) önbellekli. `NoteUndoStack.push` de tuş başına iki kez tüm maddeleri/ekleri dizip sıralıyordu (`structureKey`); nesne kimliğine bağlı önbellekle yarısı bedava.
  Doğrulama: Flutter 3.44.6 — analyze temiz, 483/483 test yeşil (+6).

- 2026-08-06 (5. tur): **Kalanlardan 4 düzeltme + asistan tarih kök nedeni + başlık biçiminin gövdeden ayrılması.**
  1. **KÖK NEDEN — asistan "son 7 günde not yok" diyor ama notlar var:** `AssistantService.buildNotesContext` modele her not için id/tip/etiket/hatırlatıcı gönderiyor ama **TARİH göndermiyordu**. Modele "şu an" damgası veriliyor (`_nowStamp`, saat dilimi + gün adı), notların tarihi verilmiyordu; asistanın not ARAMA aracı da yok (yalnız create/update/delete_note), yani tarihi başka yoldan öğrenmesi imkânsız. Zamanla ilgili HER soru bu yüzden yanlış cevaplanıyordu, sadece "7 gün" değil. Artık `güncellendi:`/`oluşturuldu:` gün hassasiyetiyle yazılıyor (ikisi aynı günse tek satır — jeton). İkinci sorun aynı yerde: `take(80)` kullanıcının SIRALAMA TERCİHİYLE gelen listeden kesiyordu, 80+ notu olanda yeni notlar bağlama hiç girmeyebiliyordu → önce `updatedAt` azalan sıralanıyor.
  2. **Başlık biçimi gövdeden AYRILDI** (kullanıcı: "başlıkta boyutu artırdığımda metinde de artıyor"; seçenek sunuldu, **(b) üçü de** — yazı tipi + boyut + opaklık — onaylandı). Eskiden tek `fontScale`/`fontFamily`/`textOpacity` üçlüsü hem başlığı hem gövdeyi besliyordu (eski yorum bunu "aynı çarpandan beslenir" diye tasarım olarak yazıyordu). Artık `Note.titleFontFamily/titleFontScale/titleTextOpacity` var ve biçim çubuğu **odaktaki alana** yazıyor (`_titleIsTarget`). **GEÇİŞ**: eski notlarda bu alanlar kayıtta yok → `fromDoc` onları gövdenin değerinden devralır, görünüm birebir korunur; ayrışma ilk düzenlemeden sonra başlar. `titleFontFamily`de `containsKey` şart: "hiç yazılmamış" ile "bilerek null (varsayılan yazı tipi)" farklı. Üçü de toMap'te KOŞULSUZ yazılır — `set(merge:true)` tuzağı (koşullu yazılsa varsayılana dönüş kayıtta eski değeri bırakırdı, `fontScale`/`textOpacity` için zaten böyleydi).
  3. **"Metin ekle"/"Liste maddesi ekle" alt çubuktan Ekle levhasına taşındı** (kullanıcı isteği): çubuk üç segmentle kalabalıktı ve ekleme işi iki ayrı yere bölünmüştü; levhanın en üstünde "Not içeriği" bölümü, çubukta yalnız Biçim + Ekle kaldı. `showAttachSheet` artık `textNote` alıyor (metin notuna liste maddesi, liste notuna serbest metin).
  4. **KALANLAR'dan biten üç madde**: çift PopScope (seçim modu + "+" paneli birlikte açıkken tek geri ikisini birden kapatıyordu — Flutter aynı rotadaki TÜM PopScope geri çağrılarını çalıştırır; `quickAddPanelOpen` bayrağıyla sıra panele bırakıldı), kopyalar levhasında "Tümünü sil" → Geri Al (`repo.restore`), belge tarama incelemesinde geri tuşu artık onay soruyor. Ek olarak klasör diyaloğundaki sabit `width: 340` ≤380dp telefonlarda taşıyordu → `min(340, genişlik-80)`.
  5. **TUZAK — yerel APK derlemesi**: CI `--build-number=${{ github.run_number }}` geçiyor, yerelde bayrak verilmezse `pubspec` `+1` kullanılıyor ve telefondaki sürümün altında kalıp `INSTALL_FAILED_VERSION_DOWNGRADE` veriyor (`adb install -d` release APK'da geçmiyor). Yerel derlemede `--build-number` telefondakinden BÜYÜK olmalı. Ayrıca `flutter` bu makinede PATH'te değil: `C:\src\flutter\bin\flutter.bat`.
  Doğrulama: analyze temiz, 483/483 test yeşil.

- 2026-08-06 (6. tur): **Ek yükleme "yeniden dene" + çakışma/sürüm geçmişi kesin olarak KAPANDI.**
  1. **Ek yükleme kalıcı hatasında elle yeniden deneme**: `UploadQueue._lastFailure` üstel beklemeyi zaten yönetiyordu ama tamamen İÇ durumdu; arayüzde kural reddi/bozuk dosya gibi hiç düzelmeyecek bir hatada da aynı dönen çark vardı, kullanıcı "yükleniyor" ile "hiç yüklenmeyecek"i ayırt edemiyordu. Yeni `uploadFailuresProvider` (ek id'si → ardışık deneme sayısı) durumu şeride açıyor; **eşik 3 deneme ≈ 1+2+4 dk** (geçici kesinti bu eşiğe gelmeden düzelir, kalıcı hata gelir), eşik aşılınca çark yerine dokunulabilir hata rozeti çıkıyor ve `retryNow` üstel beklemeyi sıfırlayıp kuyruğu hemen tetikliyor (6 saatlik tavana tırmanmış bir ekte kullanıcı sorunu düzeltse bile saatlerce hiçbir şey olmuyordu). KARAR: anahtar **ek id'si**, `noteId/attachmentId` değil — birleşik anahtar kuyruğun içinde kaldı, şeride kadar `noteId` taşımak iki widget katmanını değiştirmek demekti ve ek id'leri zaten uuid.
  2. **KARAR — çakışma çözümü + sürüm geçmişi YAPILMAYACAK (kullanıcı, 2026-08-06).** Tasarım sunuldu (Firestore `notes/{id}/versions/{ts}` alt koleksiyonu, oturum başına bir sürüm, 20 sürüm/30 gün budama, çakışmada "benimkini tut / diğerini al / farkı gör" şeridi, `items`→map göçü ÖNERİLMEDİ çünkü invaziv ve kazancı açık çakışma sorusuyla karşılanıyor); kullanıcı "sürüm geçmişine gerek yok, en son neyse o" dedi. Mevcut davranış zaten bu: alan bazlı `merge: true` → son yazan kazanır. KALANLAR'daki "Sonra yapılacak" maddesi silindi, "Bilinen eksik/risk" maddesi "YAPILMAYACAK" olarak güncellendi. Bilinen bedel kayıt altında: iki cihazda eşzamanlı düzenlemede ikinci kayıt ilkini sessizce siler, geri dönüş yok. Yeniden açma koşulu: gerçek bir not kaybı yaşanması.

- 2026-08-06 (7. tur): **Tarih ayrıştırıcısı 16 dilin tamamına çıktı + kalan üç maddenin engelleri tespit edildi.**
  1. **12 dil eklendi** (fr, it, pt, nl, pl, ru, id, hi, ja, ko, zh, ar) — `spoken_datetime.dart` artık uygulamanın bütün dillerini kapsıyor, sesli asistanın hatırlatıcı emniyet ağı hiçbir dilde modele mahkûm değil. 28 test (`spoken_datetime_i18n_test.dart`).
     **TUZAK — Dart'ın `\b`'si ASCII:** `\bà`, `\bв`, `\bال` HİÇBİR ZAMAN eşleşmez, çünkü sınır bir tarafta ASCII `\w` ister ve iki taraf da ASCII-dışıdır. Fransızca/Rusça/Arapça saat kalıplarında `\b` yerine `(?:^|\s)` … `(?!\d)` kullanıldı. Aynı sebeple sondaki `\b` de "à 9h"/"9時" gibi saate harf bitişen yazımları kaçırıyordu.
     **KARAR — `_letter` (kelime sınırı) hangi yazıları kapsar:** Latin Ext-A + Kiril + Arap + Devanagari DAHİL (bu yazılar kelimeleri boşlukla ayırıyor; harf sayılmazlarsa "завтра" uzun bir kelimenin ortasında da eşleşirdi — `завтракать` testi bunu kilitliyor). CJK ve Hangul BİLEREK DIŞARIDA: Japonca/Çince boşluk kullanmıyor, Korece ekleri bitiştiriyor ("내일에"); onları harf saymak her eşleşmeyi öldürürdü, orada alt dize eşleşmesi kabul edildi.
     Diğer notlar: Hintçe `कल` hem "yarın" hem "dün" — hatırlatıcı istemi geleceğe baktığı için yarın kabul edildi. Endonezcede `minggu` hem Pazar hem hafta; "minggu depan" gelecek Pazar'a çözülüyor (yanlış saat değil, kabul edilebilir yaklaşım). Lehçe gün adları çekimli ("w środę") — taban biçim yazıldı, gerisi modele düşer. Felemenkçe "half 9" = 8:30, Almancadaki gerekçeyle `halfPast` bilerek yok.
     Eski testteki "desteklenmeyen dil" örneği `fr` idi, artık destekleniyor → `sv` ile değiştirildi.
  2. **ENGEL — PDF çizimini paylaşılan PDF'e gömmek şu anki bağımlılıklarla YAPILAMIYOR.** `pdfrx` yalnız görüntüler, `pdf` yalnız sıfırdan üretir; var olan bir PDF'i ayrıştırıp içerik akışına yazan kütüphane yok. İki seçenek kullanıcıya sunuldu: (a) sayfaları rasterleştirip yeniden kurmak — yeni bağımlılık yok ama uygulamanın kendi taradığı PDF'lerdeki **görünmez OCR metin katmanını yok eder**, (b) `syncfusion_flutter_pdf` eklemek — metin korunur, bedeli ağır bağımlılık + Play lisans denetimi. Karar beklemede.
  3. **ENGEL — anonim→Google hesap çakışması akışı uçtan uca DOĞRULANAMIYOR.** Kritik ayrıntı: anonim hesaptan bir kez çıkılınca **geri girilemez**, yani "notları kopyala" yarıda kalırsa kalan kısım kalıcı kayıptır. Güvenli tasarım: önce yerel yedek al → Google'a gir → yedeği geri yükle (bir şey giderse dosya diskte). Ama yedekle/geri yükle mantığı şu an `settings_screen.dart` içindeki widget'lara gömülü, önce servise çıkarılması gerekiyor; sınamak da iki ayrı Google hesabı + gerçek cihaz istiyor.
  4. **ÖLÇÜM — PPTX portu tek oturuma sığmıyor**: kaynak `Desktop\dosya okuyucu` deposunda `pptx_render.dart` 61 KB + `pptx_editor.dart` 18 KB + `pptx_geometry.dart` 25 KB (~104 KB, ~2500 satır) ve `Attachment` modeli iki depoda farklı. Kendi oturumunu ister.
  Doğrulama: analyze temiz, 517/517 test yeşil.

- 2026-08-07: **KÖK NEDEN — "biçim verirken ham markdown çıkıyor" (boşlukta/satır sonunda).**
  Kullanıcı ekran görüntüsü yolladı: başlık sonunda `~~`, madde içinde `~_~`. **İki katmanlı bir kusurdu.**
  (1) `richTextSpans.walk` bir eşleşmeyi ancak İÇİ DOLUYSA biçim sayıyor (`content.isEmpty` → `continue`); içi boş kutu `emitPlain`'e düşüyor, o da yalnız `_emptyBoxPattern`'deki kutuları görünmez çiziyordu. Kalıpta `****`, `==:==`, `%%%%`, `##d:##`, `&&d:&&` vardı ama **italik (`__`) ve altı çizili (`~~`) YOKTU** — bu yüzden yalnız o iki biçimin boş kutusu ekranda görünüyordu.
  (2) Kutunun kendisi zaten çöp: seçim yokken biçim düğmesi metne boş kutu yazıp imleci arasına koyuyordu; kullanıcı içine bir şey yazmazsa işaretler notta kalıyordu.
  **REDDEDİLEN kolay çözüm:** kalıba `__|~~` eklemek. `__init__` gibi gerçek metinlerin alt çizgileri kutu sanılıp gizlenir/kırpılırdı (kullanıcının notlarında `#yazilim` içeriği var) — `****` için aynı risk vaktiyle kabul edilmişti ama `__` gerçekçi bir çakışma.
  **KARAR — boş kutu HİÇ yazılmıyor (bekleyen biçim).** `toggleFormat` artık o durumda metni değiştirmeyip `pending` (+`pendingIndex`) döndürüyor; `applyRichFormat` bunu `WrapTextController.setPendingFormat`'a yazıyor; denetleyicinin `value` setter'ı bir sonraki yazılan metni işaretlerin içine alıyor. Böylece ne ekranda ne notta hiçbir an ham işaret oluşmuyor, kalıp genişletilmediği için gerçek metin de bozulmuyor.
  **TUZAK — IME:** Gboard kelimeyi oluşturma aralığında (`composing`) tutarken metne işaret sokmak oluşturmayı bozar. Sarma yalnız `composing` geçersiz/boşken yapılıyor, o ana kadar yazılan her şey birlikte sarılıyor ("biçimli yazmaya devam et", Word davranışı). İmleç geri giderse / seçim yapılırsa / metin kısalırsa bekleme düşüyor.
  **BAYAT YORUM DÜZELTİLDİ:** `rich_text.dart` başlığı "işaretler düzenleyicide GÖRÜNÜR (sönük çizilir)" diyordu; oysa v1.0.175'ten beri saydam renk + ~0 punto ile tamamen görünmezler. Bu yorum yüzünden kullanıcıya önce "bu bilinçli tasarım" diye yanlış bilgi verildi. Ders: davranış iddiası yorumdan değil koddan doğrulanmalı.
  Eski davranışı sabitleyen 5 test güncellendi (rich_text_test 2, format_caret_in_word_test 3) + pending için 6 yeni durum. Doğrulama: analyze temiz, 521/521 yeşil. **Cihazda doğrulanmadı**: gerçek klavyeyle biçim düğmesine basıp yazmak.

- 2026-08-07 (2. tur): **İlk açılışta giriş itilmiyor, "admin" hatası anlamına çevrildi, kartlarda biçimli metin ayarı.**
  1. **İLK AÇILIŞTA GİRİŞ EKRANI YOK** (kullanıcı: "uygulama ilk açılışında ilk giriş itiyor onu kaldıralım"). `LoginScreen` artık ilk karede sessizce `signInAnonymously()` deniyor; başarılıysa kullanıcı hiçbir düğmeye dokunmadan notlara giriyor, Google hesabı isteyen sonradan Ayarlar → Hesap'tan **bağlıyor** (uid aynı kalır, notlar taşınmaz). **KARAR — deneme prefs'e işaretleniyor** (`auto_guest_signin_tried`): bayrak olmasa hesabından çıkan kullanıcı giriş ekranına döner dönmez yeniden anonim oturuma sokulur ve Google ile HİÇ giremezdi. Bayrak sonuçtan bağımsız yazılıyor — anonim giriş kapalıysa her açılışta yeniden denemek açılışı boşuna geciktirirdi.
  2. **KÖK NEDEN — "Google'sız giriş sadece admin uyarısı veriyor"**: giriş ekranı her hatayı `loginError(e.toString())` ile HAM basıyordu; Firebase konsolunda **Anonymous sağlayıcısı kapalı** olduğu için gelen `admin-restricted-operation` kullanıcıya "[firebase_auth/admin-restricted-operation]" diye görünüyordu. Kod tarafı çözümü yok — **anonim giriş Firebase konsolunda açılmadan çalışmaz** (Authentication → Sign-in method → Anonymous). Yapılan: `auth_errors.dart` kodları anlamlarına çeviriyor (kapalı sağlayıcı / ağ yok / kullanıcı vazgeçti), mesaj SnackBar yerine ekranda kalıcı duruyor (sessiz giriş başarısız olduğunda SnackBar kullanıcı gelmeden söner) ve hesap seçiciyi kapatmak artık hata sayılmıyor. Giriş ekranı `SingleChildScrollView`a alındı: hata satırıyla birlikte küçük ekranda taşıyordu.
  3. **Kartlarda satır içi biçim** (kullanıcı: "dashboardta notların renklendirme altını çizme vs görülebilir olsun ama ayar olarak ayarlarda bulunsun"): kart önizlemesi biçimi `stripRichMarkers` ile söküyordu, editörde renklendirilen not ana ekranda düz görünüyordu. Artık `noteBodyText` ayara göre `richSpans` çiziyor (işaretler zaten saydam + ~0 punto). Ayar: **Ayarlar → Görünüm → "Kartlarda biçimli metin"**, varsayılan AÇIK (`card_rich_preview`). **KARAR — arama sürerken biçim çizilmez**: eşleşmenin vurgusu ile notun kendi renk/vurgusu üst üste binince hangisinin sonuç olduğu okunmuyordu. İşaretli (checked) maddede de çizilmez: üstü çizili + soluk stil biçimin üstünde kalmalı. Yan bulgu: `NoteListRow._preview` işaretleri hiç sökmüyordu (liste görünümünde ham `**` görünüyordu) — düzeltildi.
  Doğrulama: analyze temiz, 526/526 test yeşil (5 yeni). **Cihazda doğrulanmadı**: temiz kurulumda ilk açılış (anonim sağlayıcı konsolda açık olmalı) ve kartların biçimli görünümü.

- 2026-08-07 (3. tur): **Tipografi cihazdan bağımsız: yazı tipi APK'ya gömüldü, sistem yazı ayarları yok sayılıyor.**
  **KÖK NEDEN** (kullanıcı: "yazı boyutu ve fontumuz tüm telefonlarda sabit olmalı sadece uygulama içerisinden değiştirilebilmeli"): `google_fonts` yazı tipini ÇALIŞMA ANINDA `fonts.gstatic.com`dan indirir ve indiremediğinde (ilk açılış çevrimdışı, ağ kısıtlı, DNS engeli) SESSİZCE cihazın varsayılan fontuna düşer — Samsung One UI Sans / MIUI Sans / Roboto ayrı metrikler, yani uygulama telefondan telefona başka görünüyordu. Kod hiçbir zaman hata vermediği için bu "tasarım" sanılabilirdi.
  **ÇÖZÜM**: Inter Tight `assets/google_fonts/InterTight-{Regular,Medium}.ttf` olarak GÖMÜLDÜ. Paket, varlık manifestinde `InterTight-<Ağırlık>.ttf` ile biten bir dosya bulursa indirme yapmaz (bkz. `google_fonts_base._findFamilyWithVariantAssetPath`) — **dosya adı bu kalıpta olmak zorunda**, yeniden adlandırma sessizce indirmeye döndürür (test bunu kilitliyor). Dosyalar paketin kendi indirdiği sürümlerin BİREBİR aynısı (sha256 katalogla doğrulandı).
  **KARAR — yalnız 400 ve 500 gömülü**: `interTightTextTheme` gövde temasındaki ağırlıkları yükler, Material 3 tipografisi de yalnız bu ikisini kullanıyor; w600/w700 metinler bugün de bu iki yüzden kalınlaştırılarak çiziliyor. 600/700 gömmek +0,6 MB APK, sıfır fayda olurdu (yüklenmezlerdi). Gerçekten gerekirse hem pubspec'e hem `GoogleFonts` çağrısına birlikte eklenmeli. Notların KENDİ yazı tipleri (Lora, Caveat…) hâlâ indirilir — isteğe bağlı ve not başına.
  **Sistem ayarları**: `fixedTypography` (app.dart) sistem yazı ölçeğini uygulamanınkiyle DEĞİŞTİRİR (çarpmaz — bu zaten böyleydi, artık testli) ve erişilebilirlikteki "kalın metin" ayarını kapatır (açık kalsa başlık/gövde kalınlık hiyerarşisi düzleşiyordu). Android'in "Ekran boyutu" (yoğunluk) ayarı kapsam dışı: metni değil tüm arayüzü ölçekler, uygulamadan bastırılamaz.
  Doğrulama: analyze temiz, 530/530 test yeşil (4 yeni). **Cihazda doğrulanmadı**: uçak modunda temiz kurulumda açılış (font Inter Tight gelmeli), sistem yazı boyutu en büyükken uygulamanın değişmemesi.

- 2026-08-07 (4. tur): **Yazı boyutu dört kademeye indi, uygulama geneli yazı tipi seçimi geldi, katalog (19 aile) APK'ya gömüldü.**
  1. **Yazı boyutu artık KADEME** (kullanıcı: "küçük orta büyük çok büyük seçeneklerinde olsun"): 0.85 / 1.0 / 1.15 / 1.35 → `FontScaleStep`. Kaydırıcı "%107" gibi hatırlanmayan değerler üretiyordu, iki cihazda aynı boyutu tutturmak imkânsızdı. Değerler eski aralığın (0.85–1.4) içinde: kayıtlı eski değer `nearestFontScaleStep` ile en yakın kademede görünür, kimsenin boyutu güncellemede kendiliğinden değişmez. Ayarlar özeti de yüzde yerine kademe adını yazıyor.
  2. **Uygulama geneli yazı tipi** (`appFontProvider`, prefs `app_font`, varsayılan Inter Tight): `AppTheme.light/dark/paper({font})` → `appFontTextTheme`. Notun kendi yazı tipi bunun ÜSTÜNE biner (değişmedi).
  3. **19 aile gömülü** (~5,3 MB): Inter Tight, Roboto, Open Sans, Lato, Source Sans 3, Work Sans, Rubik, Nunito, Montserrat, Poppins, Lora, Merriweather, PT Serif, EB Garamond, Playfair Display, Roboto Mono, JetBrains Mono, Caveat, Patrick Hand. Hepsi Türkçe harfleri taşıyor. Dosyalar paketin kendi indirdiklerinin BİREBİR aynısı: hash'ler `google_fonts` kataloğundan (`part_*.g.dart`) okunup `https://fonts.gstatic.com/s/a/<sha256>.ttf` ile çekildi, sha256 + boyut doğrulandı.
     **KARAR — aile başına yalnız 400 ve 500**: `...TextTheme` çağrıları gövde temasındaki ağırlıkları yükler, M3 tipografisi de yalnız bu ikisini kullanır; w600/w700 metinler bu iki yüzden kalınlaştırılarak çiziliyor. 500'ü olmayan ailelerde (Lato, Merriweather, PT Serif, Patrick Hand) paket 400'e düşüyor, o yüzden tek dosyaları var — hangi varyantın indiğini `_closestMatch` (|ağırlık farkı|/100) belirliyor, gömerken de aynı hesap yapıldı.
     **TUZAK**: katalog artık DÖRT yerde birden yaşıyor (liste, tek stil çağrıları, metin teması çağrıları, dosyalar). Biri ayrışırsa hata SESSİZ: seçenek görünür ama varsayılanla çizilir ya da paket ağdan indirmeye çalışır. `test/font_catalog_test.dart` dördünü bağlıyor.
  4. **Yan bulgu**: bir önceki commit'e `assets/google_fonts/build/.last_build_id` sızmış (test'i o klasörden çalıştırmışım) — silindi.
  Doğrulama: analyze temiz, 535/535 test yeşil (6 yeni). **Cihazda doğrulanmadı**: yazı tipi seçiminin anında uygulanması ve APK boyutunun ~5 MB artışı.

- 2026-08-07 (5. tur): **Liste sıralaması/yeni öğe kusurlarının ORTAK kök nedeni + kasma turu.** (Kullanıcı ekran görüntüsüyle: "madde sıralamasını değiştiremiyorum iptal oluyor", "yeni öğe alta eklenmiyor / yanlış yere gidiyor", "eklendiğinde uygulama kasmaya başlıyor, font değişince kasıyor", "yeni öğe görselin yanına ilk defa eklendiğinde yanıp sönen imleç çıkmıyor", "ayarlarda font seçimi vs çok dağınık", "kasma hiçbir yerde kalmasın".)
  1. **KÖK NEDEN — üç ayrı hata TEK bir bozuk değişmezden geliyordu.** `ItemsEditor`'ın bütün konum hesabı "işaretsizler `_items`'ın BAŞINDA" değişmezine dayanıyordu ama bu değişmez hiçbir yerde ZORLANMIYORDU, yalnızca umuluyordu. Bozulması kolay: bir madde işaretlenince görünüm animasyonu bitene kadar (`_settleDuration`, 220 ms) öğe listede YERİNDE kalıyor ve o hâliyle bir kez `_commit` ediliyor — kullanıcı o aralıkta editörden çıkarsa nota "işaretli madde ortada" diye yazılıyor. (Aynı sonucu başka cihazdan/eski sürümden gelen ya da AI'ın kurduğu listeler de veriyor.) Bozulunca:
     - `_addItem`/`_insertAfter` `_checkedStart`e (ilk işaretlinin konumu = listenin ORTASI) ekliyordu → **"yeni öğe yanlış yere gidiyor"**. Ekran görüntüsündeki iki boş "Yeni öğe" satırının 2. ve 3. sırada durmasının sebebi tam olarak bu.
     - `onReorderItem` indeksleri `_items` indeksleriyle **birebir aynı sayılıyordu** → sürüklenen satır yerine BAŞKA bir madde taşınıyor, ekranda satır eski yerine dönüyor ve hareket **"iptal oluyor"** gibi görünüyordu.
     **ÇÖZÜM üç katmanlı**: (a) `normalizeItems` (public, testli, kararlı bölme) — liste dışarıdan her benimsendiğinde geçiyor, bozuk kayıt açılışta ONARILIYOR; (b) konum hesapları düzene GÜVENMİYOR (`_uncheckedInsertIndex` sayarak buluyor, `_reorder` öğenin KENDİSİ üzerinden eşliyor, görünmeyen öğeler yerinde kalıyor); (c) onarım nota hemen YAZILMIYOR — açılışta kaydetmek her eski notun `updatedAt`ini tazeler ve ana ekran sıralamasını karıştırırdı; ilk gerçek düzenlemede zaten kaydediliyor.
     **TUZAK — `identical` süzgeci şart**: gelen liste düzensizse yerel kopya onarılmış hâli tutar, yani `_sameItems` bir daha ASLA tutmaz; `_adoptedFrom` olmasa aynı bozuk liste her üst build'de yeniden "farklı" görünüp boşuna `setState` çağırırdı.
  2. **Sürüklemenin gerçekten İPTAL olduğu ikinci yol**: `SliverReorderableList` öğe SAYISI değişir değişmez sürüklemeyi bırakır (`didUpdateWidget` → `cancelReorder`). Editör arka planda kaydediyor; Firestore'dan dönen anlık görüntü tam sürükleme ortasında listeyi tazelerse hareket sessizce düşüyordu. Artık dış güncelleme sürükleme sürerken ERTELENİYOR (`_adoptDeferred`), `onReorderEnd`'de uygulanıyor.
  3. **KÖK NEDEN — "görselin yanına ilk defa eklenen öğede imleç yanıp sönmüyor":** `_floatRow` sarmalayıcısı yalnız `floats.isEmpty` DEĞİLKEN kuruluyordu. Bantlar çalışma anında doluyor (tuval görsellerin yerini ilk çizimden SONRA ölçüp bildiriyor); o anda satırın ağacına araya bir katman girip çıkıyor, TextField başka konuma düşüyor ve state'i (içindeki EditableText ile) SIFIRDAN kuruluyor — yeni state odağı ZATEN almış bir düğümle açıldığı için "odak değişti" olayı gelmiyor, imlecin yanıp sönme zamanlayıcısı hiç başlamıyordu. **KURAL GENİŞLEDİ** (2026-08-06'da odak için bulunmuştu): ağacın ŞEKLİ çalışma anında hiç değişmemeli, yalnız odak için değil. Sarmalayıcı artık koşulsuz; bant yokken bedeli sıfır (ölçüm bile planlanmıyor).
  4. **KASMA — dört ölçülebilir kaynak kapatıldı.**
     a. **Tema her build'de sıfırdan kuruluyordu**: `NotlarApp.build` `theme:` ve `darkTheme:` için İKİ tam `ThemeData` üretiyordu; her biri bir `ColorScheme.fromSeed` (Material'ın renk algoritması) + paketin on beş metin biçimini kuran bir `...TextTheme` çağrısı. Üstelik her seferinde YENİ nesne döndüğü için `Theme.updateShouldNotify` `ThemeData`'nın yüzlerce alanlı `==`'ini koşuyordu. Artık `(parlaklık|kağıt|yazı tipi)` anahtarlı önbellek — en çok 57 giriş, hepsi kullanıcının gerçekten seçebildiği kombinasyonlar. **"Font değişince kasıyor" şikayetinin başrolü buydu.**
     b. **Odak dinleyicisi `setState(() {})` çağırıyordu**: odak satırdan satıra her dokunuşta İKİ kez değişir (bırakan + alan satır) ve her seferinde listenin TAMAMI — her TextField, her taşma ölçümü, her sarma kutusu — yeniden kuruluyordu. Odağın değiştirdiği tek şey o satırın kendi görünümü; artık satır başına `ValueNotifier<bool>` + `ValueListenableBuilder`. **TUZAK**: bayrak build SIRASINDA yazılmamalı (dinleyici çizim ortasında tetiklenir) — düğümün o anki hâliyle DOĞUYOR (`putIfAbsent` içinde).
     c. **Kare-sonu ölçümleri her build'de yeniden sıraya giriyordu** (`_FloatRow`, `WrapFieldMeasure`, `_measureBodyTop`): satır bir karede birden çok kez kurulabildiği için aynı ölçüm defalarca planlanıyordu. Üçünde de "bu kare için zaten planlandı" bayrağı var; ayrıca bant/çapa yokken hiç planlanmıyor.
     d. `_selectionBar` `MediaQuery.of` ile MediaQuery'nin HER alanına bağlanıyordu; iki ölçüye (`viewInsetsOf`/`viewPaddingOf`) indirildi.
     **Yeni koruma**: `items_editor_order_test.dart`'taki "ölçüm yakınsar" testi görselin yanındaki listede `pumpAndSettle` ile kare döngüsünü yakalar — yakınsamayan bir yerleşim uygulamayı KALICI kasar, tam da kullanıcının tarif ettiği "eklendiğinde kasmaya başlıyor" tablosu.
  5. **Sesli notta ana ekran bitiş satırı iki düğme**: "AI not" (asistan notu kendisi kurar — başlık/madde/hatırlatıcı) ve "Düz not" (döküm olduğu gibi). "Asistan oluştursun" ARTIK ÇİP DEĞİL: çipler arasında öteki üçüyle aynı ağırlıkta görünüyordu, oysa notu baştan sona o kuruyor. Döküm yapılamadıysa (ses eki yolu) AI düğmesi yok — yapay zekâ zaten çağrılamıyor.
  6. **Ayarlar → Görünüm derlendi**: yazı tipi + yazı boyutu TEK satırda, ORTAK önizlemeyle. Eskiden ikinci kart katalogdaki **19 yazı tipini çip çip ekrana seriyordu** — tek başına dört-beş satır kaplayan, altındaki bütün ayarları aşağı iten bir duvar. Yazı tipi artık bir SATIR (seçili ad kendi yazı tipiyle) → dokununca ÖBEKLENMİŞ levha (sade/kitap/daktilo/el yazısı, `NoteFontGroup`). Yeni l10n: `voiceCaptureAiNote`, `voiceCapturePlainNote`, `fontGroup*` (16 dilin tamamı).
  Doğrulama: analyze temiz, testler yeşil (+12 yeni: `items_editor_order_test.dart` 8, `theme_cache_test.dart` 3 + mevcutlar). **Cihazda doğrulanmadı**: sürükleyerek sıralamanın gerçek parmakla tutması, imlecin görselin yanında ilk karede yanıp sönmesi, kasmanın gerçekten gitmesi.

- 2026-08-07 (6. tur): **Kasmanın ASIL kökleri (kısıt yayılımı + çözdürme fırtınası + Firestore yankısı), Keep gibi biçim şeridi, görsele çift dokunuş, sesli levhanın kapanışı.** (Kullanıcı: "yeni öğe ekleyince klavye açılırken kasma devam ediyor ve kasma birikip artıyor sanki", "görsel ekleyince sayfaya kasma artıyor", "yeni öğe eklemesem bile kasma devam ediyor derinlemesine çöz".)
  1. **KÖK NEDEN — klavye açılırken TÜM madde listesi yeniden yerleşiyordu.** `NotePageCanvas` sayfanın en az yüksekliğini `ConstrainedBox(minHeight: …)` ile veriyordu; `ConstrainedBox` bu değeri ÇOCUĞUN KISITINA yazar ve çocuk bütün not sayfasıdır (başlık + gövde + `shrinkWrap` olduğu için tek tek yerleştirilen HER madde satırı). En az yükseklik = gövdenin görünür yüksekliği ve klavye açılırken alt çubuk klavye kadar büyüdüğü için bu değer HER KAREDE değişiyor. Yani klavyenin her animasyon karesinde 20 maddelik notta 20 `TextField` yerleşimi koşuyordu. **"Birikip artıyor" hissinin kaynağı bu**: bedel madde sayısıyla doğru orantılı, her yeni madde klavyeyi bir tık daha ağırlaştırıyor. Çözüm `PageMinHeight` (küçük bir `RenderProxyBox`): çocuğu GELEN kısıtla ölçer (kısıt değişmediği için kirli olmayan çocuk yerleşimi tümden atlar), yalnız KENDİ boyunu büyütür. Dokunulabilir alan ve kaydırma uzunluğu aynı. `test/page_min_height_test.dart` çocuğun yerleşim SAYISINI sayıp kilitliyor.
     **KURAL**: sık değişen bir ölçüyü (klavye, animasyon) çocuğun KISITINA yazma — kısıt değişimi yerleşim atlamayı öldürür.
  2. **KÖK NEDEN — görsel çözdürme fırtınası.** `_ImageBox` `cacheWidth: kutuGenişliği × dpr` veriyordu; kutu bir piksel değişse başka bir değer çıkıyor ve o değer görsel önbelleğinin ANAHTARININ parçası. Sonuç: (a) görseli köşesinden boyutlandırmak kare başına bir tam disk çözdürmesi, (b) aynı görselin onlarca kopyası 100 MB'lık önbelleği doldurup BAŞKA görselleri attırıyor — kasma kullandıkça birikiyor, (c) anahtar değişince kare boşa düşüp görsel bir an kayboluyor. `decodeWidthBucket` 256 px'lik adımlara yuvarlıyor (yukarı — çözünürlük gösterilenden düşük kalmaz). Ayrıca her görsel kutusuna `RepaintBoundary`.
  3. **KÖK NEDEN — Firestore yankısı editörü yeniden kuruyordu.** Gecikme telafisi yüzünden editörün KENDİ kaydı da anında bir anlık görüntü olarak geri düşer; akış dinleyicisi bunu KOŞULSUZ `setState` ile karşılıyordu. Yazarken (debounce 0,5 sn / en geç 3 sn) düzenli aralıklarla 4000 satırlık editör build'i boşuna koşuyordu — "yeni öğe eklemesem bile kasma devam ediyor" şikayetinin payı burası. `sameRenderedNote` (public, testli): metnin KENDİSİ dışarıda (alanların denetleyicileri çiziyor), çizimi etkileyen her alan içeride; fark yoksa `_note` sessizce güncellenir, `setState` atlanır.
  4. **Biçim şeridi Keep mantığına geçti** (kullanıcı iki ekran görüntüsüyle: "basınca direkt aktifleştiği belli olmalı ve birden çok açılabilmeli, açılanlarla yazmaya devam etmeli"). Bekleyen biçim TEK biçimdi ve şeritte hiç görünmüyordu. Artık `Map<RichFormat,int?> _pending` (ekleme sırası korunur — önce basılan en dışta sarar), `togglePendingFormat` aç/kapa, `notifyListeners()` ile şerit BASIŞ ANINDA yanıyor, `activeRichFormats` bekleyenleri de etkin sayıyor. `_wrapPending` hepsini iç içe sarıyor ve imleç bütün kapanışların önünde kalıyor (yazmaya devam = biçimler sürüyor).
  5. **Görsele ÇİFT DOKUNUŞ büyük önizleme açıyor** — aynı iş sağ-alt köşedeki tutamakta vardı ama o tutamak yalnız görsel seçiliyken görünüyor. **TUZAK**: `onTap` + `onDoubleTap` birlikteyken tek dokunuş çift-dokunuş penceresi (~300 ms) kadar gecikir; görseli seçmek o kadar yavaşlar, bilinçli kabul edildi.
  6. **Sesli yakalama levhası dört yoldan kapanıyor** (çarpı, geri, aşağı sürükleme, karartı). Eskiden `isDismissible: false, enableDrag: false` idi ÇÜNKÜ tek koruma buydu — 10 dakikalık dökümü yanlış dokunuşla kaybetmek kabul edilemezdi; bedeli kapanışın tek ve uzak bir düğmeye bağlanmasıydı ("kullanışsız"). Doğru çözüm kapıları kilitlemek değil çıkarken SORMAK: hepsi `_askBeforeClosing`'e düşüyor, içerik varsa üç seçenek (Düz not / Konuşmaya devam et / Sil). Dinleme sürerken kapatma isteği önce dinlemeyi bitirir, metin gözden geçirmeye taşınır. Yeni l10n: `voiceCloseTitle`, `voiceCloseKeepTalking` (16 dil).
  Doğrulama: analyze temiz, 565/565 test yeşil (+19 yeni: page_min_height 6, pending_format_multi 8, note_echo_rebuild 5). **Cihazda doğrulanmadı**: kasmanın gerçekten gitmesi, çift dokunuşun tek dokunuşu ne kadar geciktirdiği, levhanın yeni kapanış akışı.

- 2026-08-07 (7. tur): **KÖK NEDEN — "biçimli yazarken hâlâ problemler" (ham işaret kelimenin ortasına dağılıyor).**
  Kullanıcı iki ekran görüntüsü yolladı: kalın açıkken `merhaba` yazınca ekranda `me` düz, `rh` kalın, ardından HAM `_aba_` çıkıyor.
  **KÖK**: bekleyen biçimin sarması "IME oluşturma aralığı bitti" anında yapılıyordu (`!composing.isValid`). Ama Gboard bir kelimeyi yazarken oluşturma aralığını ARADA BİR kapatıp yeniden açıyor (otomatik düzeltme, tahmin, imleç güncellemesi). Tam o anda tampona işaret sokmak klavyenin KENDİ metin modelindeki konumları kaydırıyor; Gboard bir sonraki tuşta artık bayat olan konumlarına göre yazınca işaretler kelimenin ortasına dağılıyor ve eşi kalmayan işaret ham karakter olarak çiziliyor.
  **ÇÖZÜM**: sarma yalnız KELİME SINIRINDA (boşluk/satır sonu/sekme) — Gboard'ın kelimeyi kesinlikle bıraktığı an. Boşluk işaretlerin İÇİNDE kalır ve imleç kapanışların önünde durur, böylece sonraki kelimeler aynı kutuya eklenir: **koşu başına tampona TEK müdahale**, sonrası hiç yeniden yazma yok. Satır odaktan çıkarken `flushPendingFormat()` bekleyeni yazıyor (tek kelime yazıp başka yere dokunan kullanıcı biçmi kaybetmesin).
  **KABUL EDİLEN BEDEL**: ilk kelime yazılırken metin henüz biçimli görünmüyor (düğme yanık ama harfler düz); biçim ilk boşlukta beliriyor. Keep'te bu yok çünkü Keep biçmi metin tamponunda İŞARET olarak tutmuyor — ayrı bir span modeli (offset aralığı + stil) var, yani tampon her zaman tam olarak kullanıcının yazdığı şey. **Bu mimari fark bizde duruyor**: satır içi işaret modeliyle IME'yle yarışmamanın tek yolu tampona müdahaleyi kelime sınırına çekmek. Gerçek çözüm span modeline geçmek olurdu (büyük iş, ayrı oturum).
  Doğrulama: analyze temiz, 568/568 test yeşil (+3: kelime ortasında tampona dokunulmadığını harf harf kilitleyen test dahil). **Cihazda doğrulanmadı.**

- 2026-08-07 (8. tur): **Renk paleti ve seçicisi Keep'e çevrildi** (kullanıcı seçenek listesinden ikisini işaretledi: "seçici alt şeride insin" + "palet Keep tonlarına dönsün").
  1. **Palet 5 → 11 ton** (+ "renksiz"): Keep'in kendi değerleri (Coral/Peach/Sand/Mint/Sage/Fog/Storm/Dusk/Blossom/Clay/Chalk), açık ve koyu tema için ayrı kümeler — açık tonları karartmak gri/bulanık veriyordu. **KURAL**: ilk beş kimlik (`red`,`amber`,`green`,`blue`,`purple`) ASLA değişmez, Firestore'da o dizgilerle kayıtlı notlar var; yeni tonlar YENİ kimliklerle eklendi. Eski sürüm bilmediği kimlikte `fromId` sayesinde varsayılana düşer (not kaybı yok, yalnız renk solar). Seçici noktası artık zeminin KENDİ rengini gösteriyor (eskiden ayrı, daha doygun bir "swatch" listesi vardı — kullanıcı noktaya bakıp sayfanın rengini kestiremiyordu).
  2. **Şerit canlı**: `showNoteColorPicker` artık `onChanged` alıyor. Verilirse dokunulan renk ANINDA uygulanıyor, şerit AÇIK kalıyor ve karartı şeffaf — kullanıcı tonlar arasında gezinirken sayfanın gerçek hâlini görüyor. Tek satır, yatay kaydırmalı (11 ton dar ekranda alt alta sarılınca şerit pencereye dönüşüyordu). **Editör canlı yolu kullanıyor; kart menüsü ve toplu işlem eski "seç ve kapan" yolunda kaldı** — orada önizlenecek bir sayfa yok.
  Doğrulama: analyze temiz, 568/568 test yeşil. **Cihazda doğrulanmadı.**

- 2026-08-07 (9. tur): **KARAR — "PDF ekle not al" not tipi (ve slayt sürümü) tasarlandı, YAPILMADI.** (Kullanıcı isteği; iki tasarım sorusu soruldu ve yanıtlandı, uygulama sonraki oturuma kaldı — bu oturumun bağlamı bitti.)
  **İstenen**: yeni bir not tipi; PDF görseller gibi sayfaya gömülü, sayfa geçişi notun İÇİNDE yapılıyor. Ekran iki bölme: ÜSTTE PDF sayfası, ALTTA not. Aynı modun SLAYT sürümü de olacak. PDF üzerinde düzenleme de olacak.
  **KARAR 1 — not PER SAYFA tutulur** (kullanıcı seçti; "alt taraf sabit kalacak" ifadesi alt bölmenin YERİNİN sabitliğini anlatıyormuş, içeriğinin değil). Yani veri modeli sayfa indeksi → not. `Note.items`/`body` bunu taşımaz; yeni bir alan gerekir (öneri: `pageNotes: Map<int,String>` — Firestore'da map, `items` gibi liste değil; sayfa silinince kayması diye indeks yerine sayfa kimliği düşünülmeli).
  **KARAR 2 — sayfa notlarının TOPLU görünümü şart**: kullanıcı "PDF için tutulan sayfa sayfa tüm notları tek bir alanda görmeyi de sağlamalıyız" dedi. Yani ikinci bir görünüm: bütün sayfa notları tek akışta (sayfa numarası başlıklı).
  **KARAR 3 — PDF düzenleme dosya-okuyucudan PORT EDİLECEK**: kullanıcı "dosya tanıma uygulamamızda var, oradan al düzenleme seçeneklerini bize entegre et" dedi. **ENGEL**: o depo (`Desktop\dosya okuyucu`) bu konteynerden ERİŞİLEBİLİR DEĞİL — port için depo oturuma eklenmeli ya da ilgili dosyalar getirilmeli. 2026-08-06'da kaydedilen "çizimi paylaşılan PDF'e gömmek pdfrx+pdf ile yapılamıyor" engeli bu kararla ÇÖZÜLMÜŞ SAYILMAZ; dosya-okuyucunun hangi yolu kullandığı görülmeden karar verilemez.
  **Zemin hazır**: `pdfrx: ^1.3.4`, `viewers/pdf_viewer_screen.dart`, `data/pdf_text.dart`, slayt tarafında `data/slide_deck.dart` + `data/pptx_render.dart` + `viewers/slide_canvas.dart` + `viewers/slide_viewer_screen.dart`, çizim için `viewers/ink_layer.dart`/`ink_pen.dart` (görsel eklerinde `Attachment.ink` ile zaten kullanılıyor — sayfa başına çizim aynı kalıptan gidebilir).
  **NoteType**: `text/checklist/ordered` var; `pdf` ve `slides` eklenecek (kimlikler yeni dizgi; `fromId` bilinmeyeni `text`e düşürüyor — eski sürümde not kaybolmaz, düz metin görünür).

- 2026-08-07 (10. tur): **PDF not tipi UYGULANDI — 1/4: iki bölmeli editör + sayfa başına not.** (9. turdaki tasarımın birinci parçası; kalanlar: toplu görünüm, slayt sürümü, PDF düzenleme portu.)
  **Veri modeli — `Note.pageNotes: Map<String,String>`**, anahtar `"<ekId>#<sayfaKimliği>"` (`domain/page_notes.dart`). Ek kimliği ÖNDE: bir notta birden çok belge olabilir, aynı numaralı sayfalar karışmasın. Sayfa kimliği sayfa NUMARASI DEĞİL — `Attachment.pageIds` (sıra→kimlik) taşır; liste boşken kimlik `p<N>` olarak TÜRETİLİR, yani bugünkü kayıtlarda ikisi aynı şey. Kimlik listesi ancak PDF düzenleme (4. parça) gelince yazılmaya başlayacak; o gün sayfa silinip sıralanınca YALNIZ liste yeniden yazılır, notların anahtarları sabit kalır.
  **TUZAK (renk/şeffaflık tuzağının haritalı hâli) — silinen sayfa notu BOŞ DİZGİ yazılır, anahtar KALDIRILMAZ.** Belgeler `set(..., merge: true)` ile güncelleniyor ve merge haritaları DERİN birleştiriyor: anahtar haritadan düşürülürse Firestore'daki eski değer olduğu gibi kalır ve kullanıcının sildiği not bir sonraki açılışta geri gelirdi. `pageNotes` alanı yalnız doluyken yazılır — PDF olmayan notların şeması büyümez.
  **KÖK NEDEN olacak sıra (kodda yorumlu, testle kilitli)**: sayfa değişiminde ÖNCE yazılmakta olan sayfanın notu kesinleştirilir, SONRA sayfa numarası değişir. Ters sırada, kullanıcı 3. sayfaya yazarken kaydırıp 4'e geçtiğinde son tuş vuruşları 4. sayfaya yapışıyordu.
  **Sayfa düğmeleri alt bölmeyi ÖNCE çevirir**, görüntüleyiciyi sonra: belge buluttan inerken ya da hiç senkronlanmamışken yalnız `goToPage`'e güvenmek düğmeyi ölü bırakıyor, kullanıcı notunu yazamadan bekliyordu.
  **Mimari**: ayrı ekran DEĞİL, `NoteEditorScreen` içinde tip dalı (`_pdfBody`) — başlık, renk, kilit, paylaşım, geri al/yinele, otomatik başlık/etiket ve kaydetme yolu olduğu gibi yeniden kullanılıyor. Sayfa notu alanı `WrapTextController` kullanır, yani biçim çubuğu (kalın/renk/boyut) orada da çalışır. Çizimler panoda GÖRÜNÜR ama düzenlenmez — küçük bölmede tek parmak çizim sayfayı kaydırmayı imkânsız kılıyordu; kalem tam ekran görüntüleyicide (`InkController.replace` ile pano tazeleniyor).
  **Akış birleştirme**: `sameRenderedNote` artık sayfa notlarını da karşılaştırıyor (alt bölme onlardan çiziliyor) ve `pristine` dalı `pageNotes`'u uzaktan benimsiyor; yazılmışsa YEREL esas — bayat yankı tuş vuruşlarını geri almasın.
  Doğrulama: analyze temiz, 585/585 test yeşil (+17 yeni: kimlik taşıma, silinen sayfa, merge tuzağı, sayfa çevirince alandaki notun değişmesi, yazının doğru sayfaya gitmesi). **Cihazda doğrulanmadı.**
  **DOSYA-OKUYUCU ENGELİ ÇÖZÜLDÜ (4. parça için, henüz uygulanmadı)**: depo bu oturumda erişilebilir. 2026-08-06'da "çizimi paylaşılan PDF'in içine gömmek pdfrx+pdf ile yapılamıyor" diye kaydedilen engel orada **`syncfusion_flutter_pdf` ile** aşılmış (`services/pdf_tools.dart` → `stampStrokes` çizgileri VEKTÖR olarak sayfaya basıyor; `pdf_annotator.dart` vurgu annotation'ı; `pdf_tools` sayfa sil/seç/döndür/parola/sıkıştır; `replaceText` yerinde metin değiştirme). Mimarileri: **görüntüleme pdfrx/pdfium'da KALIR, YAZMA Syncfusion'da** (yeni bayt üret → dosyaya yaz → pdfrx'te yeniden aç). Yani port etmek `not`'a YENİ BİR AĞIR BAĞIMLILIK eklemek demek: `syncfusion_flutter_pdf` + `syncfusion_flutter_core`, **sürümleri birlikte pinlenmeli** (dosya-okuyucuda 31.1.19; 32+/core 31.2.x Flutter >=3.35.1 istiyor — bizim CI 3.44.6 olduğu için bu kısıt bizde SORUN DEĞİL, ama pin kararı yine de bilinçli verilmeli). **Lisans Syncfusion Community** (birey/küçük ekip ücretsiz; PDF kütüphanesi çalışma-anı banner göstermez). Bu bağımlılık kararı kullanıcıya sorulmadan verilmeyecek.

- 2026-08-07 (11. tur): **PDF not tipi 2/4 — sayfa notlarının TOPLU görünümü.** (9. tur KARAR 2: "sayfa sayfa tüm notları tek bir alanda görmeyi de sağlamalıyız".)
  Sayfa çubuğundaki "≡" düğmesi `PdfNotesOverviewScreen`'i açıyor: notu OLAN sayfalar, "Sayfa N" başlıklı tek akışta. Boş sayfalar listelenmiyor — akışı seyreltip aranan satırı gömüyorlardı; yeni not iki bölmeli ekranda yazılır. Başlığa dokunmak ekranı kapatıp o sayfayı döndürüyor, pano oraya gidiyor. Alanlar DÜZENLENEBİLİR: salt okunur bir döküm, göze çarpan yazım yanlışı için kullanıcıyı sayfa sayfa geri dolaştırırdı.
  **KÖK NEDEN — `PdfNotePane` artık `Note` DEĞİL `Note Function()` alıyor.** Sayfa notuna yazmak editörde "saf yazım" sayılıyor ve ekran geneli `setState` bilerek atlanıyor (kasma kök nedeni, 6. tur); dolayısıyla panoya geçirilen `Note` anlık görüntüsü kullanıcı yazar yazmaz BAYAT kalıyordu. Toplu görünümden dönüşte alan o bayat metinle doldurulunca kullanıcının az önce yazdığı satır geri alınmış görünüyordu. Kapanış her okumada canlı notu alıyor.
  Toplu görünüm listeyi ekran AÇILIRKEN donduruyor: akış her tuş vuruşunda yeniden hesaplansaydı, notunu tümüyle silen kullanıcının alanı odaktayken ağaçtan düşerdi.
  Doğrulama: analyze temiz, 588/588 test yeşil (+3). **Cihazda doğrulanmadı.**

- 2026-08-07 (12. tur): **KÖK NEDEN — "yine markdownlar çıkıyor, kalın butonuna basıp kalın yazamıyorum; Word'daki gibi olmalı".** (Kullanıcı; 7. turdaki "kabul edilen bedel" kabul EDİLMEDİ.)
  Üç ayrı kusur çıktı, üçü de aynı tasarım baskısından:
  **1) Yazarken biçim GÖRÜNMÜYORDU.** İşaretler tampona ancak kelime sınırında girdiği için, "kalın"a basıp yazan kullanıcı harflerini DÜZ görüyordu; biçim ilk boşlukta beliriyordu. Word'de imleç basar basmaz kalınlaşır. **ÇÖZÜM: canlı önizleme** — koşunun aralığı (`WrapTextController.pendingRange`) EKRANDA biçimli çizilir, tampona hiç dokunulmadan (`restyleRange`, rich_text.dart). Düz metin uzunluğu değişmez; imleç/seçim konumları buna bağlı.
  **2) Tampona koşu ORTASINDA dokunmak sürüyordu.** 7. turda "kelime sınırı güvenli an" denmişti; değilmiş — Gboard boşluktan SONRA da kendi oluşturma aralığını yeniden açıyor ve o an sokulan işaret klavyenin konumlarını kaydırıyor. Eşi kalmayan işaret `richSpans`'ta eşleşmediği için DÜZ karakter olarak çiziliyor: ekranda ham markdown tam olarak budur. **ÇÖZÜM: koşu boyunca tampona HİÇ dokunulmuyor.** İşaret yalnız koşu BİTİNCE yazılıyor (`_wrapRun`): odak kaybı, imlecin koşu dışına taşınması, biçim kümesinin değişmesi, kaydetme. Koşu başına tek müdahale ve o da klavyenin koşuyu bıraktığı andan sonra.
  **3) Gövde ve BAŞLIKTA bekleyen biçim hiç yazılmıyordu.** `flushPendingFormat` yalnız `ItemsEditor` satır odağından çağrılıyordu; gövdede "kalın"a basıp yazıp başka yere dokunan kullanıcının biçmi sessizce kayboluyordu. Artık gövde/başlık/sayfa notu odak kaybında ve `_saveNow`'da flush ediliyor (uygulama arka planda öldürülürse koşu hiç bitmeyecekti).
  **Ek kural — biçim KAPATILINCA imleç kutunun DIŞINA çıkar** (`caretOutside`). "Kalın yaz → kalını kapat → düz devam et"te imleç kapanış işaretlerinin önünde kalsaydı sonraki metin de kalın olurdu. Kalan biçimler (bold+italic'ten bold kapatılınca italic) yeni koşuda sürer.
  **Koşu SÜRÜYOR ölçütü**: metin uzunluğundaki değişim ile imlecin hareketi BİREBİR aynı olmalı. Bu, "yazmaya devam etti" ile "başka yere dokundu / uzağa yapıştırdı"yı ayırır; ayırmasaydı metnin ilerisine dokunmak aradaki bütün metni koşunun içine alır ve hepsi kalın olurdu (testle kilitli).
  **Mimari kararda değişiklik YOK**: biçim hâlâ metnin içinde işaretle taşınıyor (span modeline geçilmedi) — depolama biçimi, eski notlar, arama/AI/dışa aktarma yolları aynen duruyor. Word hissi ÇİZİM katmanından geldi.
  **AÇIK KALAN**: eski notlarda geçmiş hatadan kalmış eşsiz işaretler hâlâ ham görünür; bu tur onları temizlemiyor (metinde gerçekten yazılmış `**` ile ayırt edilemez, otomatik temizlik kullanıcının yazdığını yiyebilir).
  Doğrulama: analyze temiz, 598/598 test yeşil (+10; canlı önizlemenin gerçekten çizildiği, koşu boyunca tampona dokunulmadığı, koşu dışına dokunmanın metni yutmadığı, kapatınca imlecin dışarı çıktığı harf harf kilitlendi). **Cihazda doğrulanmadı.**

- 2026-08-07 (13. tur): **PDF not tipi 3/4 — SLAYT sürümü (`NoteType.slides`, "Sunum ekle not al").**
  Not tarafının TAMAMI ortak: `PageNotePane` (sayfa çubuğu, bölme tutamağı, alan, toplu görünüm, bekleyen biçim flush'ı) tek kopya; PDF ve slayt yalnız ÜST BÖLMEDEKİ görüntüleyicide ayrışıyor (`PdfNotePane` / `SlideNotePane` ince sarmalayıcılar). Sayfa durumu PANODA tutulur, görüntüleyicide değil — `PageNoteHost` ile konuşuyorlar; alt bölmenin hangi sayfanın notunu göstereceği tek yerden belirleniyor ve iki sürüm birebir aynı davranıyor.
  **Veri modeli AYNI**: slayt notu da `Note.pageNotes` + `"<ekId>#<sayfaKimliği>"`. Yani toplu görünüm, kart önizlemesi, paylaşım/AI metni ve dışa aktarma hiç değişmeden slaytlarda da çalışıyor. `NoteType.isPageNoteType` iki tipi tek dalda topluyor.
  **Panoda yakınlaştırma/çizim jesti YOK** (tam ekran sürümünde var): bölme küçük ve altında bir yazı alanı duruyor; iki parmak jestleri klavye açılıp kapanırken kazara tetikleniyordu. Çizim tam ekran görüntüleyicide, panoya `InkController.replace` ile yansıyor.
  Doğrulama: analyze temiz, 601/601 test yeşil (+3). **Cihazda doğrulanmadı.**

- 2026-08-07 (14. tur): **PDF not tipi 4/4 — PDF DÜZENLEME (dosya-okuyucudan port) + beş ajanlı denetimden çıkan kasma/biçim düzeltmeleri.**
  **A) PDF DÜZENLEME — 2026-08-06 engeli AŞILDI.** "Çizimi paylaşılan PDF'in içine gömmek pdfrx+pdf ile yapılamıyor" doğruydu: pdfrx SALT-RENDER, `pdf` paketi VAR OLAN belgeyi açamıyor (yalnız sıfırdan üretiyor). Dosya-okuyucu bunu **Syncfusion** ile aşmış; aynı mimari buraya alındı: **görüntüleme pdfrx/pdfium'da KALIR, YAZMA Syncfusion'da** (yeni bayt üret → dosyaya yaz → pdfrx'te yeniden aç). `data/pdf_edit.dart`: sayfa sil (YERİNDE — annotation korur), sırala/çıkar (kopyalar — annotation kaybeder, bilinçli), döndür (`/Rotate`, kayıpsız), **`burnInk`** çizgileri vektör olarak sayfaya basar. Hepsi `Isolate.run` içinde.
  **BAĞIMLILIK: `syncfusion_flutter_pdf` + `_core` ^33.2.13** (ikisi birlikte). **Sürüm tuzağı**: 33.2.13'ten eski seriler `xml ^6.5.0` istiyor, bizim `xml ^7.0.1` ile çakışıyor — dosya-okuyucudaki 31.1.19 pini oradaki eski Flutter'a özgü, buraya TAŞINAMAZ. Lisans Syncfusion Community; PDF kütüphanesi çalışma-anı banner göstermiyor (o `SfPdfViewer` gibi UI widget'larına özgü, biz yalnız bayt üreten API'yi kullanıyoruz).
  **SAYFA KİMLİĞİ BAKIMI — 1. parçadaki tasarımın karşılığını verdiği yer.** Düzenlemede `Attachment.pageIds` önce SOMUTLAŞTIRILIR (`p1..pN` — rastgele kimlik üretilseydi `a1#p3` anahtarlı mevcut notlar sahipsiz kalırdı), sonra yeni düzene göre dizilir. Notların anahtarlarına DOKUNULMAZ: 4. sayfanın notu, o sayfa nereye giderse oraya gider; silinen sayfanın notu kayıtta kalır ama listede görünmez. Testle kilitli.
  **B) BİÇİM — ekranda ham markdown üreten ÜÇ ayrı yol kapatıldı** (kullanıcı: "yine markdownlar çıkıyor"):
  1. **Koşu içinde ENTER**: biçim kalıbı satır sonuyla eşleşmiyor; `**abc\ndef**` yazılınca hiçbir eşleşme çıkmıyor ve İKİ işaret de ham çiziliyordu. Sarma artık her satır parçasını AYRI sarıyor.
  2. **Kelime sınırı — YAZAN ile OKUYAN farklı dilbilgisi kullanıyordu**: `_` ve `~` kalıpta "iki yanında harf/rakam olmasın" şartı taşıyor ama yazan taraf denetlemiyordu. Kelimenin ortasından başlayan koşu/seçim `_ilk_sonrasi`, `mer_haba` üretiyor, kalıp eşleştiremiyor, alt çizgiler ham görünüyordu. Hem bekleyen koşu hem seçim yolu artık kelime sınırına GENİŞLİYOR (Word davranışı).
  3. **Öneksiz `==`**: vurgu kademe öneki artık ZORUNLU. Öneksiz `==` düz metinde çok geçiyor ("if (a == b && c == d)") ve işaretler görünmez çizildiği için o eşittirler EKRANDAN kayboluyordu. Uygulama vurguyu her zaman önekle yazar, yani gerçek vurgular kırılmadı. `__`/`~~` boş kutuları da artık gizleniyor.
  Ayrıca: koşu sürerken SEÇİME biçim vermek koşuyu ÇÖPE ATIYORDU (`clearPendingFormat` → `flushPendingFormat`, konumlar okunmadan ÖNCE); koşunun başının altına geri silmek biçmi sessizce yutuyordu (koşu oradan yeniden başlıyor).
  **C) KASMA — beş paralel ajanın taramasından uygulananlar:**
  - **`pendingWritesProvider` build'in başında izleniyordu**: her kayıtta false→true→false, yani yazarken 3 sn'de bir 4000 satırlık editör build'i BAŞTAN koşuyordu — üstelik tetikleyici Riverpod olduğu için "saf yazım" kısayolu da akış yankısı koruması da devreye giremiyordu. Abonelik tek bir ikona indi. (Kalan kasmanın büyük olasılıkla en büyük parçası buydu.)
  - **Alt çubuk klavyenin her karesinde tümüyle yeniden kuruluyordu** (kullanıcı ekran görüntüsüyle: "klavye açılıp üste itilirken titriyor"). `_KeyboardLift` yalnız dolguyu yeniliyor; çocuk aynı widget örneği olduğu için Flutter alt ağacı atlıyor. Sayfa tuvalinin `minHeight`i de klavyeden bağımsız hâle getirildi (klavyenin yediği yükseklik geri eklenerek SABİTLENDİ).
  - **`AttachmentStrip` klavye açılınca ağaçtan düşürülüyordu** — bütün State'ler dispose oluyordu; ÇALAN SES sessizce duruyordu. Koşul kaldırıldı (şerit zaten kendi içinde gizleniyor).
  - **Çizim katmanı**: `InkPainter.shouldRepaint` KOŞULSUZ `true` idi; sayfa süzgeci `paint` içindeydi (her nokta için tüm belgenin çizgileri taranıyordu); `RepaintBoundary` yoktu. Üçü de düzeltildi (denetleyiciye `revision` sayacı).
  - Dashboard: seçim kümesi TÜM ızgarayı yeniden kurduruyordu (`select` + seçim çubuğu kendi `Consumer`ına); `_FocusHalo` her kart için `AnimationController` + `Ticker` yaratıyordu (~130 tane) — artık yalnız ODAKLI kartta kuruluyor; `allTagsProvider` `autoDispose` oldu.
  - `build()` içindeki çıplak `existsSync` çağrıları önbellekli `localFileExists`'e çevrildi (4 dosya); `_keyboardImagePaste` getter'dan alana çevrildi (her okumada yeni nesne üretip `didUpdateWidget` zincirleri tetikliyordu).
  **D) Sabitleme düğmesi üst barda** (kullanıcı isteği): ⋯ menüsündeyken bulunması ve durumunun okunması iki dokunuş istiyordu; başlıktaki raptiye göstergesi yalnız durumu söylüyor, dokunulabilir değildi.
  **UYGULANMADI — sıradaki tur için ajan raporlarındaki açık maddeler**: `planTextWrap`'in her tuşta O(satır) tam `TextPainter.layout` koşması (görsel varken; en büyük kalan kazanç, en dikkat isteyen iş), `items_editor`'ın `shrinkWrap` yüzünden görüntü alanı ayıklaması yapamaması, `richSpans`/`_parse` önbelleği, `scrollCacheExtent: 10000`, Gemini'ye giden base64+jsonEncode'un UI izolatında olması, `slide_canvas`'ın her build'de iki kez `TextPainter` ölçmesi, PPTX görsellerinde `cacheWidth` yokluğu, `_saveNow`'ın madde satırlarının bekleyen biçmini flush etmemesi, seçim silmenin biçim sınırında eşsiz işaret bırakması, eski sürümün `type`ı `text`e geri yazması.
  Doğrulama: analyze temiz, 633/633 test yeşil (+32). **Cihazda doğrulanmadı.**

- 2026-08-07 (15. tur): **Ajan raporlarındaki KALAN maddelerin tamamına yakını uygulandı** (kullanıcı: "hepsini düzelt").
  **En büyük kazanç — üç ÖNBELLEK.** Üçü de saf memoizasyon, davranış değişmiyor:
  1. **`_parse` (tek girişli)**: biçim ayrıştırması on ayrı yerden çağrılıyor — biçim şeridi HER TUŞ VURUŞUNDA ve HER İMLEÇ HAREKETİNDE `activeFormats` üzerinden tüm metni yeniden ayrıştırıyordu, arama süzgeci not başına koşuyordu.
  2. **`buildTextSpan` span ağacı**: her ÇİZİMDE tüm metin özyinelemeli gezilip yüzlerce `TextSpan` üretiliyordu. Eski önbellek yalnız "metin düz mü" sorusunu kapsıyordu, asıl pahalı iş her karede yapılıyordu.
  3. **`planTextWrap` (sarma planı)**: satır satır ilerlerken her turda TAM bir `TextPainter.layout` + tam biçim ayrıştırması — maliyet O(satır × metin). `set value`'yu tetikleyen HER ŞEYDE koşuyordu (imleç taşımak, metne dokunmak, seçim). Artık yalnız METİN ya da yerleşim girdileri değişince. **Bantlar YERİNDE değişebildiği için önbellek anahtarı listenin KOPYASI** — kimliğe bakmak bayat plan verirdi. Testle kilitli (`wrap_plan_cache_test`): gereksiz hesaplama yok AMA gerektiğinde mutlaka var, çünkü bayat plan imleci kaydırır.
  **Arama süzgeci**: not başına "aranabilir gövde" önbelleği (`updatedAt` anahtarlı). Sorgu yazılıyken HER Firestore anlık görüntüsünde (yani editörde yazarken de) tüm notların gövdesi ve maddeleri `stripRichMarkers`'tan geçiyordu; debounce yalnız tuş vuruşunu bastırıyor, snapshot'ı bastırmıyor.
  **Ana ekran**: klavye ve arama odağı okuması build'den çıktı — `viewInsets` klavye animasyonunun her karesinde değişiyor, yani arama kutusuna dokunmak 250 ms boyunca ızgarayı 15–30 kez yeniden kuruyordu. `_searchFocus.addListener(setState)` de tüm ekranı kurduruyordu. `hiddenFolderIds` `select`'e alındı, anlamsal sağlayıcılar yalnız anlam modu açıkken izleniyor.
  **Arka plan servisleri**: `UploadQueue` ve `ReminderService` not akışını debounce ediyor (2/3 sn). İkisi de her tuş vuruşunda tüm notlar × tüm ekler üzerinde küme kuruyordu.
  **Medya**: `slide_canvas._fitScale` önbelleklendi (şekil başına İKİ tam metin ölçümü, her build'de — slaytta bir yere dokunmak 20 kutulu slaytta ~40 yerleşim demekti); PPTX görsel baytları paylaşılıyor (aynı logo 30 slaytta 30 kopya + 30 ayrı bitmap oluyordu) ve arşiv ad→içerik dizinine alındı; tam ekran görselde çözünürlük kovası; `PdfText.hasTextLayer` artık tüm belgeyi çıkarmıyor, ilk 6 sayfada eşiği görünce çıkıyor.
  **Gemini**: `base64Encode` büyük yüklerde `compute`'a taşındı. 20 MB'lık bir PDF ~27 MB'lık String demek; tek bir "PDF'i özetle" isteğinde UI iş parçacığı yüzlerce ms kilitleniyordu. **Kalan**: dio'nun `jsonEncode`'u hâlâ ana izolatta (gövdeyi String olarak geçirmek sağlayıcı dallarının hepsini test etmeyi gerektiriyor).
  **Doğruluk düzeltmeleri**: `_clearFormatTargetFor` build fazında `setState` çağırabiliyordu (ÇÖKME — `mounted` "build içindeyiz"i korumaz); `_saveNow` artık odaktaki alanın (madde satırı / sayfa notu) bekleyen biçmini de yazıyor; geri al/yinele belge notunda odağı bırakıyor (odaklı alan dışarıdan geleni benimsemiyor, geri alma bir sonraki tuşta iptal oluyordu); `restyleRange` sarmalayıcı stilini koruyor; `_shiftOffset` geçersiz seçimde imleci sarmanın sonuna koyuyor; `InkController.replace` İÇERİK karşılaştırıyor (her Firestore yankısında katman boşuna tazeleniyordu); `_SlidePaneViewer` denetleyicisi `initState`te; sayfa notu ve toplu görünüm alanlarına TEMİZ Kes/Kopyala eklendi (panoya ham işaret gidiyordu).
  **`hasPageNotes` ile `isEmpty` BİLEREK farklı sorular soruyor**: birincisi "gösterilecek not var mı" (yalnız MEVCUT eklerin), ikincisi "sessizce silinebilir mi" (hiçbir yazı yoksa). Belgesi silinmiş notun yazıları gösterilmez ama arka plan temizliği de onu yok edemez.
  **ESKİ SÜRÜM ONARIMI**: eski sürüm `type` alanını koşulsuz yazıp `pdf`/`slides`'ı `text`e düşürerek GERİ KAYDEDİYOR; o andan sonra not yeni sürümde de düz metin olarak açılıyordu (sayfa notları dokümanda durur, erişilemez). `repairNoteType` okuma sırasında telafi ediyor: sayfa notu OLAN ve belge eki taşıyan bir "text" notu geri yükseltiliyor. Ölçüt dar — yalnız PDF eki olan düz metin notu meşru, ona dokunulmuyor.
  **TARTILDI, YAPILMADI (gerekçeli)**: video oynatıcısının tembelleştirilmesi — kutunun ilk karesi oynatıcıdan geliyor, tembel kurulumda kullanıcı dokunana kadar yerinde genel bir kamera simgesi duruyor. Bir videolu (yaygın) durumda görünür gerileme, dört videolu (nadir) durumda kazanç; küçük resim ayrıca üretilmedikçe takas kabul edilmedi.
  **HÂLÂ AÇIK**: `items_editor`'ın `shrinkWrap` yüzünden görüntü alanı ayıklaması yapamaması (60 maddelik notta 60 `TextField` her build'de kuruluyor — çözümü sayfayı tek `CustomScrollView`/sliver dünyasına taşımak, `pageBox` ölçüm uzayını değiştirdiği için ayrı bir tur); `scrollCacheExtent: 10000` (önce diğerleri ölçülmeli, tek başına düşürmek eski kaydırma sıçramasını geri getirebilir); bekleyen koşu konumlarının GÖRÜNTÜ uzayında tutulması (sarma çapası eklenip çıktığında bayatlıyor — sayfa notu bölmesinde çapa yok, orada güvenli); seçim silmenin biçim sınırında eşsiz işaret bırakması; `stripRichMarkers` ile `richSpans`'ın boş kutuları farklı sırada işlemesi.
  Doğrulama: analyze temiz, 644/644 test yeşil (+11). **Cihazda doğrulanmadı.**

- 2026-08-07 (16. tur): **Açık kalan iki mimari maddenin kapanışı.** (Kullanıcı: "hala açık 2 maddeyi de bitir".)
  **1) `items_editor` — SATIR ÖNBELLEĞİ (kök çözüm, sliver'a geçmeden).** Liste `shrinkWrap: true` ile bir `SingleChildScrollView`'ın içinde; `ShrinkWrappingViewport` kendi boyunu bulmak için BÜTÜN çocukları kurmak zorunda, yani 60 maddelik notta ekranda 8 satır görünse bile 60 `TextField` her build'de yeniden kuruluyor ve yerleşiyordu — editörün her yeniden kurulumunun bedeli madde sayısıyla doğru orantılıydı.
  Denetimin önerisi sayfayı tek `CustomScrollView`/sliver dünyasına taşımaktı; **yapılmadı**, çünkü sayfa tuvali (yüzen görseller, `_pageBox`, `_bodyTop`, `WrapFieldMeasure`) TEK KUTU koordinat uzayı varsayıyor ve sliver'a geçmek o ölçüm zincirinin tamamını yeniden yazmak demek.
  **Yerine: satır widget'ı önbelleği.** Girdileri değişmemiş satır için AYNI widget örneği dönüyor. Kritik nokta şu: Flutter `updateChild`te birebir aynı widget'ı görünce alt ağacı hiç kurmuyor — ve kurulmayan `RenderObject` "kirli" işaretlenmediği için **`layout()` da erken dönüyor.** Yani kazanç yalnız yeniden kurulumda değil, YERLEŞİMDE de. Culling'in çözdüğü şeyin (kare başına O(madde) iş) neredeyse tamamı bu yolla kalkıyor; culling'in ayrıca çözdüğü tek şey ÇOK uzun listede ilk kurulum ve bellek — o kabul edildi.
  Anahtar bir KAYIT (record): yapısal eşitlik, hash çakışması yok. Liste düzeyi girdiler (tema, stil, kutucuklar, seçim modu, bantlar) değişince önbellek tümden düşüyor; **bantlar YERİNDE değişebildiği için anahtar listenin KOPYASI**. **TUZAK**: önbellekteki widget ESKİ `NoteItem` örneğini kapanışlarında tutuyor — güvenli, çünkü satır geri çağrılarının hepsi öğeyi KİMLİĞİYLE arıyor. Yan etki: `_FloatRow`'un kare-sonu ölçüm planlaması da yalnız satır gerçekten değişince kuruluyor (eskiden her build'de satır sayısı kadar geri çağrı sıraya giriyordu).
  Testle kilitli (`items_editor_row_cache_test`): boş yeniden kurulum satırları TAZELEMEMELİ, değişen satır tazelenmeli, komşuları kurulmamalı, liste düzeyi girdi ve bantlar değişince hepsi tazelenmeli. Ölçüt widget ÖRNEK KİMLİĞİ (`identical`).
  **2) `scrollCacheExtent: 10000` — DÜŞÜRÜLMEDİ, bilerek; yerine BİRİM MALİYET sıfırlandı.** Denetim payı "her yeniden kurulumun çarpanı" diye işaretlemişti (~130 kart canlı). Doğru sıra çarpanı değil birim maliyeti düşürmekti: `richSpans` (metni özyinelemeli gezip span ağacı kuruyordu) ve `applyNoteFont` (kart başına iki katalog araması + yeni `TextStyle`) artık önbellekli. Payı ayrıca düşürmek, belgelenmiş ve KULLANICI TARAFINDAN BİLDİRİLMİŞ bir hatayı ("aşağı kaydırırken liste yukarı sıçrıyor") geri getirme riski taşıyor — masonry uzunluğu yeniden TAHMİN olurdu. Ölçmeden düşürmek kazançtan çok gerileme getirir; cihazda ölçüm yapılabildiğinde yeniden değerlendirilsin.
  `richSpans` önbelleği listeyi PAYLAŞTIĞI için `List.unmodifiable` döndürüyor: bir çağıranın yerinde değiştirmesi başka bir kartın çizimini bozardı.
  **Liste görünümünde eksik `key` ve `RepaintBoundary` eklendi**: anahtarsız satırlarda not silinince `_FocusHaloState` YANLIŞ nota bağlanıyordu (vurgu başka satırda yanıp sönüyordu), sınır yokluğunda da tek satırın vurgusu görünen listenin tamamını yeniden boyatıyordu.
  Doğrulama: analyze temiz, 649/649 test yeşil (+5). **Cihazda doğrulanmadı.**

- 2026-08-07 (17. tur): **PDF metin seçimi + PDF/slayt not balonları + podcast seslendirme ayrımı + not paketi paylaşımı.** (Kullanıcı istekleri: "PDF üzerindeki metinleri aynı dosya okuma programındaki gibi seçebilme", "liste ekle seçeneği yok", "podcast kısmında Gemini modelini seçme ayarı ayrı olsun ve seslendirmesi ona yaptırma seçeneği de olsun, TTS modelini de seçebilelim, podcast dinle kısmında da AI ile dinle olsun", "PDF ve slayt üzerine istenilen bir alana yazı yazmak için balon", "paylaş seçeneğinde notu başka bir Not kullanıcısına aynı şekilde açılacak biçimde paylaşabilmeli, PDF üzerindeki balonlar girmiş olsun".)

  **1) PDF metin seçimi — dosya-okuyucu projesinden PORT.** İki uygulama da `pdfrx` (pdfium) kullanıyor, katman olduğu gibi taşınabildi: `viewers/pdf_select_layer.dart` + `data/pdf/{selection_rects,ocr_page_text,pdf_page_ocr,edge_auto_scroll}.dart`, pano metni `core/utils/pdf_copy_text.dart`. Uzun basış kelimeyi seçer, parmak kalkmadan sürükleme kelime kelime büyütür, tutamaçlar karakter hassasiyetinde ayarlar, büyüteç gezer, kenarda sayfa kendiliğinden akar; masaüstünde fare + Ctrl/Cmd+C.
  **Neden pdfrx'in kendi seçimi DEĞİL**: 1.3.x'in `SelectionArea` tabanlı seçimi Android'de vurgu çıkarmıyor; düzgün seçim 2.x'te yeniden yazıldı ama 2.x'e geçilemiyor (bkz. pubspec — pdfrx 2.x farklı bir Dart/archive tabanı istiyor).
  **KORUNAN İKİ KÖK NEDEN (dosya-okuyucu'da haftalar süren hata):** (a) `painter:` verilmiş bir `CustomPaint`, `hitTest` geçersiz kılınmazsa kapladığı alandaki HER dokunuşu yutar (`hitTestSelf` içinde `?? true`) — katman sayfanın tamamını kapladığı için kaydırma ve yakınlaştırma tümüyle ölürdü; `_SelectionPainter.hitTest => false` silinmemeli. (b) Katman jest tanıyıcısı DEĞİL `Listener` kullanır: tanıyıcı arenaya girip pdfrx'in kaydırma/ölçek tanıyıcılarını eliyordu. Uzun basış elle ölçülür (zamanlayıcı + kayma toleransı + ikinci parmak iptali); pan yalnız parmak yerdeyken kilitlenir.
  **Taranmış sayfa**: metin katmanı ince olan sayfada cihaz-içi ML Kit OCR (`PdfPageOcr`) sayfa görünür olunca sessizce koşar ve sonucu `PdfPageText` arayüzünü giyen `OcrPageText`e çevirir — seçim katmanı yazılmış/taranmış farkını HİÇ bilmez, tek yol. `ScanOcr.recognizeImageWordLines` eklendi (satır kutusu seçim için yetmiyor, sözcük kutusu şart). Disk önbelleği BİLEREK alınmadı (dosya-okuyucu'da var): platform kanalı kritik yolda `await` edilince flutter_test'te asılıyor, bellek önbelleği bu uygulamanın kullanımına yetiyor.

  **2) Not balonları (`PageBubble`).** PDF/slayt sayfasının istenen noktasına bırakılan, açılıp kapanan, sürüklenen METİN balonları — çizimden farkı aranabilir/düzenlenebilir olması. Çizimle (`InkStroke`) aynı ilkeler: PDF'e GÖMÜLMEZ, ekin `bubbles` alanında sayfa oranlı (0–1) konumla durur, Firestore'a not ile gider, yalnız doluysa yazılır (eski notların şeması büyümez). Dört yerde birden: PDF tam ekran, PDF panosu, slayt tam ekran, slayt panosu. Panoda da DÜZENLENEBİLİR (çizimden ayrıldığı yer): balon metin alanı, küçük bölmede de yazılabiliyor. Balon bırakma kipi ile çizim kipi birbirini kapatır (aynı parmağı isterler). Yazılmadan bırakılan balon ekrandan çıkarken düşer.

  **3) "Liste ekle" — kök neden şuydu**: "Ekle" levhası not tipine göre TEK seçenek gösteriyordu (metin notunda "Liste maddesi", ötekinde "Metin"). Oysa notlar karışık içerik taşıyabiliyor; var olan yetenek ekranda yokmuş gibi görünüyordu. İkisi de her tipte gösteriliyor. Belge (PDF/sunum) notunda bölüm HİÇ gösterilmiyor: o ekranda ne gövde ne madde çiziliyor, seçenek koyup hiçbir şey olmaması yanıltırdı.

  **4) Podcast modeli ve seslendirme.** `AiTask.podcast` ayrıldı (`model_podcast`): podcast tek seferde uzun akıcı anlatı üretiyor, belge sohbeti kısa turlarla ilerliyor — biri için doğru model öteki için pahalı/yetersiz. Seçilmemişse belge modeline düşer (eski davranış korunur).
  **Gemini TTS** (`GeminiService.speech`): metin üretiminden AYRI yol, çünkü yanıt metin değil `inline_data` içinde HAM PCM ve istek `responseModalities:["AUDIO"]` + `speechConfig` istiyor. **WAV başlığını biz yazıyoruz** (`pcm_wav.dart`) — başlıksız akışı hiçbir oynatıcı çalmaz; örnekleme hızı MIME'dan okunur (koda gömülseydi hız değişince ses tiz/pes çalar, fark edilmesi zor). **KISIT: yalnız kullanıcının kendi Gemini anahtarıyla**; dahili (Firebase AI Logic) yol ses döndürmüyor — anahtarsızda "AI ile dinle" hiç gösterilmiyor.
  `AiSpeechController` cihaz TTS'iyle AYNI durumu (`SpeechOutputState`) yayar, böylece dinleme ekranının oynat/duraklat/ilerleme arayüzü hiç değişmedi. Metin paragraf boyunda (~900 karakter) parçalanır ve bir parça çalarken sonraki üretilir. **TUZAK**: just_audio'nun `play()`'i çalma bitince döndüğü gibi DURAKLATILDIĞINDA da döner; yalnız ona güvenilirse duraklat→devam sırasında iki parça üst üste çalar — parçanın bittiği `processingState` ile doğrulanıyor. AI seslendirmesi hata verirse (kota/anahtar/ağ) ekran mesaj gösterip CİHAZ sesine düşer.

  **5) Not paketi (`.notpaket`) — notu her şeyiyle paylaşma.** Düz metin paylaşımı yalnız yazıyı taşıyordu. Paket bir ZIP: `not.json` + `dosyalar/<ekKimliği>`. Ekler, sayfa notları, çizimler, **balonlar**, renkler, yazı tipleri ve etiketler gider.
  **Firestore `toMap()` KULLANILMADI**: `Timestamp`/`FieldValue.serverTimestamp()` JSON'a çevrilemez ve sunucuya özel; paket biçimi ayrı ve SÜRÜMLÜ (`v`), bilinmeyen sürüm reddediliyor.
  **Ek KİMLİKLERİ korunuyor** (yeniden üretilmiyor): sayfa notlarının anahtarı `<ekId>#<sayfaKimliği>` ve notun zemin görseli ek kimliğine bağlı — kimlik değişseydi paketten gelen notun sayfa notları ve zemini sessizce kaybolurdu. Gönderenin `storagePath`/`downloadUrl`/`localPath` alanları pakete YAZILMIYOR (alıcıda işe yaramaz, üstelik kullanıcı kimliği yolun içinde).
  **Manifest**: `.notpaket` için VIEW + `pathPattern` (dosya yöneticisinden "birlikte aç") ve SEND + `application/zip`. `application/octet-stream` BİLEREK alınmadı — Notlar tanımsız her dosya türünde paylaş menüsünde çıkardı. Paket olmayan bir zip çalışma anında anlaşılıp normal paylaşım yoluna düşüyor, gövdeye ikili bayt yazılmıyor.

  Doğrulama: analyze temiz, 687/687 test yeşil (+38: pano metni temizliği, satır birleştirme, OCR sayfa metni, kenar kaydırma, WAV başlığı, seslendirme parçalama, paket gidiş-dönüş). **Cihazda doğrulanmadı — APK CI'da.**

- 2026-08-08 (18. tur): **Balonlar ANA araç oldu** — sürükleme, vurgu birleşmesi, toplu liste ve panonun yeniden düzeni. (Kullanıcı maddeleri: sürükleme çok zor / balonlar artık ana metot / alt not alanı gizli başlasın / balona yazarken her şey kayıyor / seçim ve yazma tam ekransız çalışsın / vurgulama yok / sayfaya dokununca balon kapansın / kasma olmasın / renk + yıldız / toplu liste + arama + balona git / vurgu-balon birleşimi / aynısı slaytta.)

  **1) Sürüklemenin KÖK NEDENİ ve çözümü.** Eski sürüm `onPanUpdate` kullanıyordu: sürükleme jesti pdfrx'in `InteractiveViewer`'ıyla AYNI jest arenasında yarışır ve kaydırma tanıyıcısı çoğu zaman önce kazanır — parmak balonu değil sayfayı çeker. Taşıma artık **uzun basışla** başlıyor (`onLongPressStart` + `onLongPressMoveUpdate`): uzun basış arenayı kesin kazanır. Üstüne titreşim (`mediumImpact`) + "kaldırma" animasyonu (ölçek/gölge) ve taşıma sürerken üst katman `panEnabled: false` yapıyor. Kartın TAMAMI tutamaç — eskiden yalnız 16 px'lik başlık şeridiydi. **TUZAK**: `onLongPressMoveUpdate` TOPLAM kaymayı verir, kare farkı için son değer saklanmalı (`_last`); saklanmazsa balon parmaktan kat kat hızlı uçar.

  **2) Vurgu ile balon TEK veri modeli.** Ayrı bir "highlight" tipi yapılmadı: vurgu, `rects` alanı dolu olan bir `PageBubble`. Böylece toplu liste, arama, senkron, paylaşım ve silme tek yoldan çalışıyor ve kullanıcının istediği "vurguya tıklayınca balon açılsın" kendiliğinden geliyor. Dikdörtgenler sayfa ORANINDA (0–1, sol-ÜST orijin) saklanıyor; pdfium PDF puntosu ve sol-ALT orijin kullandığı için çevrim `normalizedPageRects`ta (saf, testli). Ham `PdfRect` saklansaydı vurgu başka sayfa boyutunda bambaşka yere düşerdi. Seçim çubuğu: **Vurgula · Vurgula+not · Kopyala**.

  **3) Pano yeniden düzenlendi.** Alt sayfa-notu alanı artık **kapalı başlıyor** (ekranın yarısını kaplıyordu) ve sayfa çubuğundaki düğmeyle açılıp kapanıyor. Balona yazarken `suppressNotes` ile zorla gizleniyor — kök neden: klavye açılınca ekranın altı yarıya iniyor, iki bölme + klavye sığmıyor ve balon kartı bölmenin dışında kalıyordu (kullanıcı: "klavye, sayfa hepsi kayıyor"). Metin seçimi, vurgu ve balon artık PANODA da var: tam ekranla aynı `pdfLayerParams` kurulumundan geliyor, tek kopya.

  **4) KASMA — üç kaynak kapatıldı.** (a) Seçim durumu `setState`teydi: her parmak hareketinde `PdfViewerParams` ve bütün sayfa katmanları yeniden kuruluyordu. Artık `PdfSelectionState` içinde `ValueNotifier`; yalnız seçim çubuğu dinliyor. (b) Pan kilidi de aynı bayrağa bağlı ve hareket başına İKİ kez değişiyor (belge yeniden YÜKLENMEZ — pdfrx yalnız documentRef değişiminde yükler). (c) Balona yazarken her tuş `notifyListeners` çağırıp sayfadaki tüm balonları ve vurgu boyamasını yeniden kuruyordu; metin artık `updateText` ile SESSİZ yazılıyor (TextField zaten gösteriyor), dışarıya haber yalnız kaydetmede gidiyor.

  **5) Dokunsal geri bildirim WIDGET katmanında.** `HapticFeedback` denetleyicinin içindeyken birim testleri platform kanalı olmadığı için patlıyordu; denetleyici saf tutuldu, titreşimi çağıran arayüz veriyor.

  **6) Toplu balon listesi** (`bubbles_overview.dart`): arama, yıldız süzgeci, sayfa numarası, "balona git" (o sayfaya gidip balonu TEK BAŞINA açar — `openOnly`), düzenle, sil. Sıra: yıldızlılar → sayfa → sayfa içi dikey konum, yani belgeyi okurken karşılaşılacak sıra.

  **7) Diğerleri**: renk paleti 5'ten 12'ye çıktı, yıldız eklendi (renk KONU ayırır, yıldız ÖNEM); açık balon varken sayfanın boşluğuna dokunmak kapatır (`collapseAll`; yalnız TAP dinlenir, kaydırma/yakınlaştırma alta geçer); `dropEmpty` boş SERBEST balonu atar ama boş VURGUYU korur (vurgunun kendi başına anlamı var); slaytta da hepsi var (balon taşınırken `PageView` kilitleniyor).

  Doğrulama: analyze temiz, 704/704 test yeşil (+17). **Cihazda doğrulanmadı — APK CI'da.**

- 2026-08-08 (19. tur): **Cihaz denemesinden çıkan 12 + 4 madde** — sürüklemenin gerçek kök nedeni, fosforlu vurgu, balonun yeniden tasarımı, slayt zoom'u, ana ekran çipleri ve üç kasma kaynağı.

  **1) SÜRÜKLEMENİN ASIL KÖK NEDENİ (18. turda yarım kalmıştı).** Uzun basışa geçmek yetmedi; iki şey kalmıştı:
  (a) **Pan kilidi jesti öldürüyordu.** Taşıma başlarken `selection.selecting` true yapılıyor, o da `PdfViewerParams`ı değiştirip **`PdfViewer`'ı jestin ORTASINDA yeniden kuruyor** ve başlamış uzun basışı iptal ediyordu. Kilide GEREK YOK: uzun basış arenayı kazandığı an pdfrx'in kaydırma/ölçek tanıyıcıları zaten eleniyor. Kilit yalnız METİN SEÇİMİNDE şart — o katman arenaya hiç girmeyen bir `Listener` kullanıyor.
  (b) **Süre.** Flutter'ın uzun basışı 500 ms; `GestureDetector` süreyi dışarı açmıyor. `RawGestureDetector` + `LongPressGestureRecognizer(duration: 220ms)` ile yeni bir `BubbleDragArea` yazıldı — "tut ve taşı" tek akış oldu. Kartın TAMAMI tutamaç.

  **2) Vurgu artık FOSFORLU KALEM.** Tek düz dikdörtgen "seçim vurgusu" gibi duruyordu. Şimdi iki katman: satırın tamamını kaplayan soluk zemin (%20) + ortasından geçen, uçları yuvarlak KALIN iz (%42, satır yüksekliğinin %58'i). Vurgunun rengi balon renginden AYRI (`highlightColor`, varsayılan fosforlu kırmızı): balon rengi KONU ayırır, vurgu göze çarpmak için vardır.

  **3) Balon yeniden tasarlandı.** Üst şerit 26 px'e indi (simgeler 15 px) — eski şerit kartın yarısını yiyordu. **Başlık alanı şeridin İÇİNDE** (ayrı satır kartı bir kat daha büyütürdü), en çok 12 karakter. Başlık doluysa balon KAPALIYKEN yuvarlak nokta yerine **başlığı yazan küçük etiket** görünür — sayfaya bakınca açmadan ne dediği anlaşılır. **Ünlem** (acil) eklendi: kapalı balon yanıp söner. Yanıp sönme denetleyicisi YALNIZ acil+kapalı balonda kurulur; her balon için sürekli dönen bir animasyon kare kare yeniden boyama demekti.

  **4) ÜÇ KASMA KAYNAĞI kapatıldı.**
  * `note_editor_screen`: sayfa tuvalinin alt sınırı `constraints.maxHeight + viewInsets.bottom` idi. Değer doğruydu ama `viewInsetsOf` BAĞIMLILIK kurar — klavye animasyonunun her karesinde (~15 kare) tuval, yüzen görsel bantları ve satır ölçümleriyle yeniden kuruluyordu. Artık MediaQuery'ye hiç dokunulmuyor: görülen EN BÜYÜK yükseklik saklanıyor (`_stableCanvasHeight`), genişlik değişince sıfırlanıyor.
  * Balon metni/başlığı `updateText`/`updateTitle` ile dinleyicileri UYANDIRMADAN yazılıyor (TextField zaten gösteriyor).
  * Pan kilidi kaldırıldığı için taşıma sırasında görüntüleyici hiç yeniden kurulmuyor.

  **5) Balona yazarken ekran boşaltılıyor.** Klavye ekranın yarısını alıyor: alt not alanı (18. tur), **sayfa çubuğu** ve **editörün alt çubuğu** (Biçim/Ekle/AI + ek şeridi) gizleniyor. Sonuncusu panodan editöre `onImmersiveChanged` ile bildiriliyor. Ayrıca balon odağa gelince ekran dikdörtgeni ölçülüp belge yukarı itiliyor (`ensureVisible`) — kart klavyenin altında kalmıyor. **Ölçüm 320 ms GECİKMELİ**: klavye animasyonu bitmeden ölçülen dikdörtgen "klavye yokmuş gibi" çıkar, kaydırma hesabı sıfırlanırdı.

  **6) Seçim çubuğu telefon tuşlarının altında kalıyordu**: `Scaffold` gövdesi `bottomNavigationBar` yokken sistem payını eklemiyor; çubuğa `viewPadding.bottom` eklendi.

  **7) Slaytta zoom** (`ZoomBox`): çift dokunuş DOKUNULAN NOKTAYA yakınlaşır, ikinci çift dokunuş sığdırır, arada iki parmakla serbest gezinme. Yakınken `PageView` kilitli — yatay sürükleme büyütülmüş sayfada gezinmektir, slayt değiştirmek değil. Slayt öğeleri `RepaintBoundary` içinde.

  **8) Ana ekran.** Kullanıcının ETİKETLERİ artık Süz'ün yanında **varsayılan** çip (önce yıldızlananlar, sonra kalanlar); yatay çekiş de aynı kümeyi geziyor (süzgeç → klasör → etiket). Eskiden etiketin çip olması için önce "favorile" adımı gerekiyordu — gereksiz bir kapıydı.

  **9) İki parmakla sütun değişimi KÖK NEDEN.** `GestureDetector.onScaleUpdate`, altındaki kaydırma görünümünün dikey sürükleme tanıyıcısıyla aynı arenada yarışıyor ve sürükleme İLK parmakta kabul edildiği için çoğu zaman önce kazanıyordu. Arenaya hiç girmeyen `Listener` tabanlı `_PinchColumns` yazıldı (aynı çözüm PDF seçim katmanında da var). **TUZAK**: adım atıldıktan sonra taban uzaklık şimdiki değere çekilmeli; çekilmezse oran eşiğin üstünde kaldığı sürece her karede bir adım daha atılır ve tek jestte en uca fırlanır.

  Doğrulama: analyze temiz, 708/708 test yeşil (+4). **Cihazda doğrulanmadı — APK CI'da.**

- 2026-08-08 (20. tur): **Sürüklemenin GERÇEK kök nedeni + balon içeriği sayfadan ÜST KARTA taşındı.**

  **1) "Sürüklemeye başlayınca kenarlara fırlıyor" — KÖK NEDEN.** `BubbleDragArea` içindeki `last` (son bildirilen toplam kayma) **`build()` içinde YEREL bir değişkendi**. Taşıma sırasında her hareket denetleyiciyi güncelliyor, denetleyici katmanı yeniden kuruyor, `build()` yeniden koşuyor ve değişken SIFIRLANIYORDU. Bir sonraki olayda fark, kare farkı yerine jestin BAŞINDAN itibaren toplam kayma olarak uygulanıyor — balon parmaktan kat kat hızlı fırlıyordu. Değer `State`e taşındı. **Kural: jest sırasında biriken hiçbir değer `build()` içinde yaşayamaz.**

  **2) Açık balonun İÇERİĞİ artık sayfada DEĞİL, görüntüleyicinin üstüne demirlenmiş kartta** (`BubbleDock`). Kullanıcının kendi önerisi; PDF yorum araçlarının da yolu.
  Neden: kart sayfa koordinatındayken klavye açılınca görünür alan yarıya iniyor ve sayfanın alt yarısındaki kart klavyenin ALTINDA kalıyordu. Bir önceki turda belgeyi kaydırarak telafi denendi (`ensureVisible`) — okunan yeri kaçırdığı ve klavye animasyonuyla yarıştığı için yetmedi. Şimdi sayfada YALNIZ tutamaç (nokta/başlık etiketi) ve vurgu var; içerik hep en üstte, klavye ne kadar yer alırsa alsın görünür. Yan faydalar: kart artık sayfa kenarına taşmıyor, iki kart üst üste binmiyor, konum hesabı ve kıstırma kodu tümüyle kalktı.
  Açık balonun tutamacı KOYU halkayla işaretli: üstteki kartın sayfada nereye ait olduğu görünüyor.

  **3) "Başlık kısmı hiç görülmüyor" — kök neden.** Başlık alanı, beş simgeyle AYNI şeritte `Expanded` idi; dar sayfada (pano bölmesi) simgeler 130 px alıp başlığa birkaç piksel bırakıyordu. Şeritte artık yalnız **kapat** ve **taşma menüsü (⋮)** var; yıldız, ünlem, renk ve silme menüde. Başlık şeridin geri kalanını alıyor.

  **4) Balona yazarken not BAŞLIĞI da gizleniyor** (18-19. turlarda not alanı, sayfa çubuğu ve editör alt çubuğu gizlenmişti). Klavye ekranın yarısını alıyor; kalan alan belgeye ve karta gidiyor.

  Doğrulama: analyze temiz, 709/709 test yeşil (+1). **Cihazda doğrulanmadı — APK CI'da.**

- 2026-08-08 (21. tur): **Balonda OKU/YAZ ayrımı, yazma kartı klavyenin üstüne indi, slaytlar PDF gibi dikey aktı.**

  **1) İki kip: OKUMA ve YAZMA** (`BubbleController.editMode`). Yazılmış bir balonun tutamacına dokunmak artık klavye açmıyor — not, sayfanın üzerinde durduğu yerde küçük bir balonda (`_BubbleReadCard`) okunuyor; yazmak için "Düzenle" deniyor. Boş balon (yeni bırakılan, vurgudan doğan) doğrudan yazmaya açılıyor: orada okunacak bir şey yok. Kullanıcı isteği: "not yazıldıktan sonra küçük simgesine tıklandığında sadece not orada balon olarak görülsün, düzenleme için düzenle butonu olsun."

  **2) Yazma kartı ÜSTTEN ALTA taşındı** — bir tur önce üste demirlenmişti (20. tur), kullanıcı "güzel değil, 2.ss'teki alana al" dedi. Kart görüntüleyicinin ALT kenarında: `Scaffold` klavye kadar daraldığı için "alt kenar" = klavyenin hemen üstü. Göz ve parmak zaten orada; üstteyken bakış sayfanın bir ucundan öbürüne gidip geliyordu. Tasarım da değişti: zemin balonun rengiyle dolu koca bant değil, **belge rengi (yüzey) + solda 5 px renk şeridi**.

  **3) "Tıklanan balon klavye ile ekranın üstü arasında ortalanmalı".** Balon açılınca (`onOpened`) belge kaydırılıp balon, **kartın üstünde kalan** alanın ortasına getiriliyor. PDF'te `PdfViewerController.calcMatrixFor(nokta, viewSize: Size(w, serbestYükseklik))` — küçültülmüş `viewSize` vermek tam olarak bu işi yapıyor. Slaytta aynı hesap `SlideStripMetrics.centerOffset`. Kartın yüksekliğini kartın kendisi bildiriyor (`dockHeight`). **340 ms gecikme ŞART**: klavye ~250 ms'de açılıyor, hemen ortalamak klavye kapalıyken doğru olan yere kaydırıyor.

  **4) Sürüklemenin İKİNCİ kök nedeni: "parmağımdan geride kalıyor".** 20. turda fırlama düzeldi ama gecikme kaldı. Neden: her hareket `controller.update` → `notifyListeners` → sayfanın BÜTÜN balon katmanı (vurgu boyaması, vurgu dokunma alanları, tüm tutamaçlar) yeniden kuruluyordu. Kare başına bir tam yeniden kurulum = parmağın gerisi. Artık kayma tutamacın kendi `ValueNotifier`ında birikiyor, tek bir `Transform.translate`i besliyor; **model taşıma BİTİNCE bir kez** yazılıyor. Ayrıca tutamaçtaki `Tooltip` kaldırıldı — kendi uzun basış tanıyıcısını arenaya sokup taşımayla yarışıyordu.

  **5) Başlık CANLI.** `updateTitle/updateText` hâlâ dinleyicileri uyandırmıyor (kasma) ama `revision` sayacını artırıyor; **yalnız AÇIK balonun** tutamacı onu dinliyor. Böylece etiket harf harf güncelleniyor, öbür balonlar hiç tazelenmiyor.

  **6) Slaytlar PDF gibi: dikey, kesintisiz, boşluksuz** (`SlideStripMetrics` + `ListView.itemExtentBuilder`). Yatay `PageView` bırakıldı. Yükseklikler oranlardan önceden hesaplandığı için liste ölçmeden kuruluyor, "balona git" tam yere gidiyor ve kaydırma konumundan slayt numarası doğrudan çıkıyor. **TUZAK**: kaydırma → panoya sayfa bildir → pano geri sıçrat döngüsü; bildirilen sayfa kendi `_page`'imizle karşılaştırılmadan sıçratma yapılmamalı.

  **7) Kaydırmadaki takılmalar.** `_HighlightPainter.shouldRepaint` hep `true` idi — katman her tazelendiğinde bütün vurgu yolları baştan çiziliyordu; artık içerik karşılaştırılıyor. Vurgu boyası ve sayfa katmanlarının tamamı `RepaintBoundary` içine alındı.

  Doğrulama: analyze temiz, 722/722 test yeşil (+13). **Cihazda doğrulanmadı — APK CI'da.**

- 2026-08-08 (22. tur): **Paylaşımın üç yolu, PDF sayfa sıçraması, okuma balonunun yeni görüntüsü ve balon menüsünün klavyeyi kapatması.** (Kullanıcı maddeleri: paylaş seçenekleri doğru çalışmıyor / PDF modunda balonlu PDF'yi başka bir Not kullanıcısına atabilmeliyim / sayfa geçişlerinde zıplama / balonun görüntüsü yenilenmeli / 3 noktaya basınca klavye kapanıyor.)

  **1) "Paylaş" PDF notunda SESSİZCE hiçbir şey yapmıyordu — kök neden.** Tek bir düğme vardı ve `note.toPlainText()` gönderiyordu; PDF/sunum notunun düz metni SAYFA NOTLARIDIR, o da çoğu zaman boştur ve `if (text.isEmpty) return;` ile akış sessizce ölüyordu. Üstelik belgenin üzerindeki balonlar hiçbir yoldan karşı tarafa gitmiyordu: `.notpaket` yalnız not kartının uzun basış menüsünde duruyor, editörden erişilemiyordu. Artık tek bir levha var (`share_sheet.dart`) ve üç yol birbirinin yerine geçmiyor: **düz metin** (boşsa GEREKÇE gösterilir, sessiz kapanma yok), **not olarak** (`.notpaket` — başka bir Not kullanıcısına, balonlar DÜZENLENEBİLİR gelir), **balonlu PDF** (damgalanmış kopya, alıcının Not uygulaması olması gerekmez). Aynı levha hem editörün ⋯ menüsünden hem kartın işlem ızgarasından açılıyor; ızgaradaki ikinci "Not olarak paylaş" kutusu kalktı. Toplu seçimde de boş metin artık gerekçeyle söyleniyor.

  **2) Balonlar PDF'in İÇİNE basılabiliyor** (`PdfEdit.burnBubbles`). Çizimlerdeki yolun aynısı (Syncfusion ile yeni bayt üretimi, `stampTransform` ile döndürülmüş sayfa düzeltmesi): vurgu = %20 zemin + satırın %58'i kalınlığında %42 iz (uçlarda yarım daire — ekrandaki fosforlu kalemin aynısı), balon = ucunda renkli nokta + beyaz zeminli, solda 5 px renk şeritli kutu. **Font gömmek ZORUNLU**: Syncfusion'ın hazır Helvetica'sı WinAnsi ve içinde ı ğ ş İ yok — `assets/fonts/PTSans-Regular.ttf` ANA izolede okunup izoleye geçiriliyor (`rootBundle` izolede yok, NotePdf'teki kuralın aynısı). **TUZAK**: Syncfusion sarma yüksekliğini dışarıya vermiyor; kutu yüksekliği satır sayısından kabaca hesaplanıp yarım satır PAY bırakılıyor (eksik hesap son satırı kırpardı). Ek dosyaya DOKUNULMUYOR: damgalı kopya geçici klasöre yazılıyor, uygulamadaki belge katmanlı kalıyor.

  **3) PDF sayfa geçişlerindeki ZIPLAMA — kök neden.** `_PdfPaneViewer.didUpdateWidget` "pano sayfası değişti mi" sorusunu `old.host.page != widget.host.page` ile soruyordu. Kullanıcı parmağıyla kaydırınca pdfrx `onPageChanged` ile panoya haber veriyor, pano `setState` ile YENİ bir `PageNoteHost` kuruyor ve bu koşul doğru çıkıp `goToPage` çağırıyordu — yani kaydırmanın ORTASINDA belge sayfa başına sıçratılıyordu. Artık görüntüleyici kendi gösterdiği sayfayı `_page`'te tutuyor ve yalnız pano DIŞARIDAN başka bir sayfa isterse (oklar, toplu görünüm, balona git) sıçratıyor. Aynı tuzak 21. turda slaytta çözülmüştü; PDF'te kalmış. **Kural: iki yönlü sayfa senkronunda "dışarıdan gelen" ile "benim bildirdiğim" ayrılmadan asla sıçratma.**

  **4) Okuma balonunun görüntüsü yenilendi.** Kart baştan sona balon rengiyle doluydu, sayfanın %86'sı genişliğindeydi ve içinde koca bir "Balonu düzenle" düğmesi taşıyordu — altındaki belgeyi tümüyle kapatıyordu (kullanıcının ekran görüntüsü). Şimdi yazma kartıyla (`BubbleDock`) aynı dili konuşuyor: zemin belgenin rengi, balonun rengi solda 5 px şerit, başlık + düzenle/kapat tek satırda simge olarak, genişlik en çok 260 px.

  **5) "3 noktaya basınca klavye kapanıyor" — kök neden.** `PopupMenuButton` bir ROTA iter; itilen rota kendi odak kapsamını alır, `TextField` odağı düşer ve klavye kapanır (menü kapansa da geri gelmez). Odak düşünce `editing` false olduğu için gizlenen çubuklar da geri gelip ekran zıplıyordu. Renk seçici de aynı sebeple (modal levha) suçluydu. Eylemler (yıldız/acil/renk/sil) ve renk şeridi artık KARTIN İÇİNDE açılıyor, `TextFieldTapRegion` + `ExcludeFocus` ile: hiçbir düğme odağı istemez, yazı alanı odakta kalır, klavye açık kalır. **Kural: metin yazılırken açılan hiçbir yardımcı arayüz rota itmemeli.**

  Doğrulama: analyze temiz, testler yeşil (+6: balonun PDF'e basılması ve kart içi eylemlerin odağı düşürmemesi). **Cihazda doğrulanmadı — APK CI'da.**

- 2026-08-08 (23. tur): **Paylaşılan PDF artık Notlar'da DÜZENLENEBİLİR açılıyor** (kullanıcı: "gönderilen PDF'yi PDF görüntüleyicilerde açabiliyorum ama notlar uygulaması çıkmıyor; notlarda açıp aynı şekilde düzenlemeye devam edebilmek istiyorum").

  **1) Damga artık GERİ ALINABİLİR.** 22. turda balonlar sayfanın içeriğine düzleştiriliyordu: dosya her okuyucuda doğru görünüyor ama karşı tarafta balon taşınamaz/silinemez hâle geliyordu. Çözüm iki parça ve ikisi de aynı dosyada:
  * Damga, adlandırılmış bir **PDF katmanına** (optional content group, `PdfEdit.shareLayerName`) çizilir. Her okuyucu normal içerik gibi gösterir; Notlar `layers.remove(isRemoveGraphicalContent: true)` ile katmanı grafiğiyle söker.
  * Balonların/çizimlerin KENDİ verisi PDF'e **ek dosya** olarak iliştirilir (`notlar-balonlar.json`). Başka programlar için görünmez bir eklenti, Notlar için notun kaynağı.
  Böylece belgenin İKİ kopyası taşınmıyor (dosya boyutu iki katına çıkmıyor) ve alıcıda balonlar ilk günkü gibi düzenlenebiliyor. Okuma sırasında hem katman hem veri sökülür: aynı dosya ikinci kez alınırsa balonlar ÇİFTLENMEZ.
  **TUZAK**: bir `PdfLayer` grafiğini İLK sayfa için kurup önbelleğe alıyor; aynı katman ikinci sayfada kullanılırsa çizim yanlış sayfaya gider. Her sayfaya AYNI ADLA ayrı katman açılıyor — silme ada göre çalıştığı için hepsi tek çağrıda kalkıyor.

  **2) "Notlar açılacaklar listesinde çıkmıyordu" — kök neden.** Manifest'te PDF için yalnız **SEND** (paylaş menüsü) filtresi vardı; dosya yöneticisinden, indirilenlerden ya da bir sohbet uygulamasının ekinden gelen **ACTION_VIEW** ("birlikte aç") filtresi yoktu. PDF ve sunum için VIEW filtresi eklendi (BROWSABLE yok — bir web bağlantısı uygulamayı açıp not oluşturamamalı; tür listesi dar, `*/*` Notlar'ı her dosyada çıkarırdı). `receive_sharing_intent` VIEW'ı zaten SEND ile aynı yoldan veriyor.

  **3) Paylaşılan belge artık BELGE NOTU olarak doğuyor.** Gelen tek bir PDF/sunum, metin notuna iliştirilmiş bir ek olarak açılıyordu (belge yalnız bir rozetti). Artık not `NoteType.pdf`/`slides` tipinde oluşuyor, yani editör üstte sayfa altta o sayfanın notu olarak açılıyor ve balon bırakılabiliyor.

  **4) Geri yükleme İKİ kapıda birden**: paylaşım/aç yolunda (`share_intake`) ve nota elle PDF eklerken (`_pickPdf`) — kullanıcı dosyayı indirip sonra uygulamadan seçerse de balonlar geri gelir. Sıradan PDF'te `readSharedPdf` null döner ve dosya olduğu gibi eklenir (belge yalnız açılır, kaydedilmez: maliyet sıfıra yakın).

  Doğrulama: analyze temiz, testler yeşil (+2: gidiş-dönüşte katmanın sökülüp balonların veri olarak dönmesi, sıradan PDF'in null dönmesi). **Cihazda doğrulanmadı — APK CI'da.**

- 2026-08-08 (24. tur): **OK aracı.** (Kullanıcı: "bir de ok işareti çekme istiyorum.")

  Ok, ayrı bir veri tipi DEĞİL: `InkStroke.arrow` bayrağı taşıyan iki noktalı bir çizgi (ilk nokta kuyruk, ikinci uç). Böylece kaydetme, senkron, geri al, silgi, `.notpaket` ve paylaşılan PDF damgası tek yoldan çalışıyor; ayrı model yazılsaydı hepsi ikişer kez yazılacaktı. Alan yalnız TRUE iken kayda giriyor — eski çizimlerin şeması büyümüyor. Kalem türü (`InkPen`) SAYDAMLIKTAN okunuyor ama ok kalemin bir türü değil (her kalem ve renkle çizilebilir), bu yüzden aynı numara ona uygulanamazdı.

  **Jest**: ok kipinde parmak serbest çizmez — basılan yer kuyruk, sürüklenen uç. `pointerMove` nokta EKLEMEZ, ucu taşır; sürüklenmeden bırakılan (yönü olmayan) ok atılır. Silgi için okun gövdesi boyunca örnek noktalar üretiliyor: iki uçlu bir çizgi yalnız uçlarından yakalanırdı.

  **Geometri tek kopya** (`domain/arrow.dart`, saf Dart): ekran katmanı ile PDF damgası aynı hesabı kullanıyor — iki yerde ayrı yazılsaydı paylaşılan PDF'teki ok ekrandakinden başka türlü çıkardı. Gövde başlığın dibinde biter (kalın kalemde çizgi ucun sivriliğini bozuyordu) ve başlık okun yarısından uzun olamaz (kısa okta uç gövdeyi yutmamalı).

  Doğrulama: analyze temiz, testler yeşil (+9: ok kaydı, kırpma, geometri, jest, silgi, PDF damgasında gidiş-dönüş). **Cihazda doğrulanmadı — APK CI'da.**

- 2026-08-08 (25. tur): **Vurgu hiç kaydedilmiyormuş — Firestore iç içe dizi almıyor.** (Kullanıcı maddeleri: balon kaydolmuyor / fosforlu görüntü kötü / dışa aktarmada maddeler ve biçim yok / PDF sesli oku çalışmıyor / AI sesi çalışmıyor, çok ayar var / ekler satırı alta gelsin / kalem alt çubukta olsun / sayfa sil-boş sayfa ekle / başlık satırı + etiketler / görsel notu modu.)

  **1) KÖK NEDEN — "metin seçip balon koyunca kaydolmuyor, geri gidince kayboluyor".** `PageBubble.toMap` vurgu dikdörtgenlerini `[[l,t,r,b], ...]` yani **dizi içinde dizi** olarak yazıyordu. **Firestore iç içe dizi kabul etmez**: o notun yazımı TÜMÜYLE reddediliyordu — yani yalnız vurgu değil, vurgu eklendikten sonraki her değişiklik de kaydedilmiyordu (sessizce, çünkü yazım `unawaited`). Artık düz liste (`[l,t,r,b,l,t,r,b,...]`, çizimin `points`'i ile aynı kural); okuma iki biçimi de anlıyor. **Kural: Firestore'a giden hiçbir alan dizi içinde dizi olamaz.**

  **2) Fosforlu vurgu yeniden yazıldı.** İki katman vardı (soluk zemin + ortasından geçen KOYU kalın bant); üst üste binince satırın ortası, yani harflerin gövdesi, en koyu yer oluyordu — "yazıyı okunmaz hâle getiriyor". Şimdi tek ve düzgün %28 dolgu; PDF damgası da aynı (paylaşılan dosya ekranın fotoğrafı olmalı). Balon tutamacı da yarı saydam (%72) — kapalıyken altındaki yazı okunuyor, taşınırken/açıkken opak.

  **3) Balondan vurgulanan metne OK.** Balon sürüklendikçe ok uzuyor, kısalıyor, yöneliyor: ok yalnız kendi katmanında (`_LeaderPainter`) ve `dragDelta` adlı ayrı bir `ValueNotifier`ı dinliyor — denetleyiciyi uyandırmak sayfanın bütün balon katmanını kare kare yeniden kurardı (kasmanın bilinen kök nedeni).

  **4) Dışa aktarma iki yerde birden kırıktı.** (a) **Maddeler yazılmıyordu**: metin notunun gövdesi alınıyor, aynı nottaki onay kutuları/maddeler atlanıyordu. (b) **Biçim gitmiyordu**: işaretler yalnız SÖKÜLÜYORDU, üstelik alanlarda HAM görünüyordu (`##5:**_~ezan vakti~_**##`). Artık alanlarda temiz metin, çıktıda gerçek biçim var: `richSegments` (ayrıştırıcının tek kopyası) → `pw.RichText`. **PT Sans kalın ve italik kesimleri eklendi**: `pdf` paketi bu kesimleri sentezlemez, dosyası verilmezse kalın metin düz çıkar.

  **5) "PDF sesli oku çalışmıyor" — kök neden.** Okuma ekranına notun DÜZ METNİ veriliyordu; PDF notunun düz metni sayfa notlarıdır ve çoğu notta boştur, ekran da "okunabilir metin çıkmadı" diyordu — oysa metin belgenin içindeydi. `noteSpeechText` artık belgenin kendi metnini de çıkarıyor (yerel kopya yoksa buluttan geçici dosyaya yazıp).

  **6) Seslendirme ayarı TEK yerde.** Motor seçimi "Gelişmiş AI" bölümünde, sesler/hızlar "Ses" bölümündeydi; okuma ekranında da ayrı bir anahtar vardı ve ayarda yapay zekâ seçiliyken bile kapalı kalabiliyordu ("AI seçince çalışmıyor, hâlâ android sesiyle okuyor"). Ekrandaki anahtar kalktı, her şey Ses bölümünde ve **yapay zekâ sesi kullanılamıyorsa sebebi yazıyor** (kendi Gemini anahtarı gerekiyor). Model etiketleri de düzeltildi: iki ayrı ayar "podcast" diyordu.

  **7) Alt çubuk iki iş kazandı.** "Ekler (1) · Göster" satırı kalktı, aç/kapa alt çubuktaki ek düğmesine taşındı (kapalıyken artık HİÇ yer kaplamıyor). PDF/sunum notunda **kalem alt çubukta**: tam ekrana geçmeden bölmede çizim — açıkken tek parmak çizer, iki parmak gezinir, kalem çubuğu bölmenin dibinde.

  **8) Sayfaları düzenle**: boş sayfa ekleme (`PdfEdit.blankPage` = -1, sıralamada beyaz sayfa doğurur; kimliği yeni uuid, yoksa sonraki sayfaların notları kayardı) ve silme artık her zaman görünür.

  **9) Görsel notu modu — yeni TİP AÇILMADI.** Seçilen görseller `ScanPdf` ile tek belgeye diziliyor ve PDF notu olarak açılıyor: sayfa notu, balon, vurgu, ok, kalem, sayfa ekle/sil, paylaşım, dışa aktarma hepsi bedava geliyor. Ayrı bir tip aynı ekranların ikinci kopyasını doğururdu.

  **10) Başlık satırı.** Başlık artık TEK satır; etiket/klasör/hatırlatıcı çipleri ve "+" düğmesi başlığın SAĞINDA, iki sütuna sığan dar bir alanda (çip etiketleri kısaltılıyor — dar alanda `Chip` taşma hatası verir).

  Doğrulama: analyze temiz, testler yeşil. **Cihazda doğrulanmadı — APK CI'da.**

- 2026-08-09 (26. tur): **Dokuz maddelik paket** (dal: `claude/file-browser-selection-ghco7i`). Kullanıcı maddeleri: dosya tarayıcısı seçilemiyor / görsel notta kırp-döndür / foto-tarama-video için balonlu mod / iki seçenekli önizlemeli kip seçimi / etiket-klasör alanı bozuk / slaytta kalem çalışmıyor / balon oku yazıyı kapatıyor / ayarlarda ses+AI dağınık / kasma olmasın. Ek olarak tur içinde: "görsel eklendiğinde direk ekrana".

  **1) KÖK NEDEN — "belge seçerken dosya tarayıcısını seçemiyorum".** `file_selector` Android'de `ACTION_OPEN_DOCUMENT` kullanıyor; o niyeti YALNIZCA sistemin belge arayüzü (DocumentsUI) karşılar ve çekmecede ancak **DocumentsProvider yazmış** sağlayıcılar (cihaz deposu, Drive, OneDrive) görünür — telefonun kendi dosya yöneticisi uygulaması oraya asla düşmez. Yeni köprü (`MainActivity.pickDocuments` + `core/utils/doc_picker.dart`) `ACTION_GET_CONTENT`i `Intent.createChooser` ile açıyor: sıradan bir uygulama seçimi olduğu için DocumentsUI listede KALIYOR, yanına dosya yöneticileri ve galeri geliyor. **Seçilen içerik URI'si kalıcı DEĞİL** (izin yalnız o niyet boyunca) — dosya hemen önbelleğe, GERÇEK ADIYLA kopyalanıyor (çağıranların bir kısmı uzantıya bakıyor). Köprü yoksa/kimse karşılamazsa sessizce `file_selector`a düşülür.

  **2) Kip seçimi: balonlu / klasik, ÖNİZLEMELİ.** Foto çek, belge tara, görüntülü, görsel ekle, PDF ekle ve sunum ekle — altısı da artık önce `showCaptureModeSheet` ile soruyor. Önizlemeler `CustomPaint` ile ÇİZİLİYOR (varlık dosyası yok): tema renklerini kullandıkları için kağıt/koyu temada da doğru ve APK büyümüyor. Balonlu = içerik `ScanPdf` ile belgeye çevrilip **PDF notu**; klasik = düz metin notu + ek. Yeni tip yine AÇILMADI (25. turdaki gerekçe).

  **3) TUZAK — video balonlu olamaz, kapak karesi olur.** Balon/vurgu/el yazısı bir SAYFANIN oranlı uzayında yaşıyor; videonun sayfası yok. Balonlu kipte `MediaMetadataRetriever` ile 1. saniyenin karesi çıkarılıp belge sayfası yapılıyor, video da nota `asFile` ek olarak bağlanıyor. Kare çıkarılamayan platformda (masaüstü) **seçenek hiç sorulmuyor** — sorup sessizce klasiğe düşmek kullanıcının seçimini yok saymak olurdu.

  **4) KÖK NEDEN — "etiketlerde yazılar kesiliyor, hizalı değil".** Çipler başlık satırının sağında 168 dp'lik kutuya sıkıştırılmış, her çip ayrıca 80 dp'ye kırpılmıştı; 80 dp'de dolgu + silme (×) ikonundan sonra ~34 dp yazı kalıyor, "#yapılacak" → "#ya…" oluyordu. `Wrap` sağa dayalı olduğundan hiçbir kenara da hizalanmıyordu. Artık başlığın ALTINDA tek satırlık YATAY ŞERİT: genişlik sınırı yok, hepsi aynı hizada, sığmayan kaydırılarak görülüyor; "+" şeridin dışında sabit.

  **5) KÖK NEDEN — "slaytta kalem çalışmıyor".** Editördeki tek `_penMode` bayrağı yalnız `PdfNotePane`e bağlanmıştı; `SlideNotePane` parametreyi hiç almıyordu, düğme slaytta hiçbir şey yapmıyordu. İki pano artık AYNI sözleşmeyi taşıyor (silgi zaten ortak `InkToolbar`da). Slaytta iki parmak gezinme için `InkNavLayer` KULLANILMADI: `ZoomBox.enabled=false` tam ekran görüntüleyicideki kurulumun aynısı — ölçek korunur, jest kapanır.

  **6) Ok "yazının arkasına" nasıl geçer.** Belge sayfası rasterize bir görüntü (pdfrx tek katman çiziyor) — ayrı bir metin katmanı olmadığı için boyayı harflerin altına koymanın gerçek yolu YOK. `BlendMode.multiply` aynı sonucu veriyor: sonuç alttaki pikselle çarpıldığı için koyu harfler okun üzerinden geçiyor, ok yalnız açık zeminde görünüyor (fosforlu kalemin kâğıttaki davranışı). Opaklık %65. Ok balon başına kapatılabiliyor: `PageBubble.arrow`, kayda **yalnız kapatılınca** yazılıyor (`'a': false`) ve alan yoksa AÇIK okunuyor — eski kayıtlarda ok kaybolmamalı.

  **7) Seslendirme tek blokta.** Motor (cihaz/AI) + model + ses + deneme `_VoiceSection`da; cihaz sesleri dil başına ayrı satırlar yerine TEK menüde (dil seç → ses seç, seçince örnek cümle o dilde okunuyor). Eksik ayar eklendi: **ses tonu** (`tts_pitch`, 0,5–2,0). Ton/hız kaydırırken değil BIRAKINCA yazılıyor — her karede motor ayarını yeniden kurmak sesi tutukluyor.

  **8) "Görsel eklendiğinde direk ekrana".** `_placeNewImage` imleç ölçülemediğinde görseli var olan BÜTÜN eklerin altına yığıyordu; uzun notta bu ekranın metrelerce aşağısı demekti, kullanıcı "eklenmedi" sanıyordu. Artık imleç yoksa **görünen alanın tepesi** çapa (sayfa tuvaline `ScrollController` bağlandı).

  Doğrulama: `flutter analyze` temiz, 745 test yeşil (+3: ok kaydı ve aç/kapa). **Cihazda doğrulanmadı — APK CI'da.**

- 2026-08-09 (27. tur): **Üç uygulama tek simge dili** (dal: `claude/app-icons-settings-4mmer4`). Kullanıcı: *"3 uygulamanın simgelerini aynı dile getirelim; dosya okumanın boyutu güzel, ezan vaktinin çerçeve rengi güzel."* Notlar · Dosya Okuyucu · Ezan Vakti aynı ana ekranda duruyor, üçü üç ayrı dil konuşuyordu.

  **Ortak dilin dört kuralı** (üç depoda da aynı, karşılıkları: burada `assets/icon/src/*.svg`, Dosya Okuyucu'da `tool/gen_icon.py`, Ezan Vakti'nde `res/drawable/ic_launcher_*.xml`): (1) zemin düz **beyaz** `#FFFFFF`, gradyan/gölge/doku yok — Ezan Vakti'nden; (2) işaret tek renk **dolu silüet**, ayrıntılar zeminden oyuk; (3) işaretin uzun kenarı **66dp / 108dp** tuval, kare/dairesel işaretler keyline kuralıyla ×0,95; (4) sınır kutusu tuvalin merkezinde.

  **Notlar'da değişen üç şey.** Zemin `#F5EDD8` → `#FFFFFF` (`pubspec.yaml` + `values/colors.xml#ic_launcher_background`; widget paleti KAĞIT KALDI, o ayrı bir yüzey). Kat üçgeni ve satır dolguları zemin rengiyle boyandığı için onlar da beyaza döndü. Ölçek 7.48 → **13.7352**: belge, basıldığında görünür 72dp'lik alanın yalnız %50'sini kaplıyordu, artık %92'sini.

  **TUZAK — `android:inset="16%"` ölçeği DIŞARIDAN küçültüyor.** `ic_launcher.xml` ön planı inset ile sarıyor, yani PNG %68'e inerek basılıyor; SVG'deki ölçek bunu **önceden telafi ediyor** (`66/108*1024 / 0,68 / 67`). Inset'i XML'den silmek çözüm DEĞİL — `flutter_launcher_icons` dosyayı her koşuda baştan yazıp geri koyuyor (aynı sebeple `<monochrome>` de elle geri ekleniyor). Telafi kaynakta durduğu sürece araç çalışsa da ölçü bozulmuyor.

  **TUZAK — 66dp'nin nedeni: "güvenli alan" KARE DEĞİL.** Maskeler 108dp tuvalin ortadaki 72dp'sine uygulanıyor ama hepsi kare değil. Belge oranıyla (50×67, köşe 5) MIUI'nin squircle'ına sığan en büyük ölçü 67,8dp, Pixel'in dairesine 60,6dp. 66 seçildi: squircle TAM, daire köşeleri hafifçe tıraşlıyor — kullanıcının "boyutu güzel" dediği ölçüden %14 küçülmemek için bilinçli ödünç (hedef cihaz MIUI, üç simge de aynı kuralı kullanıyor). Piksel piksel sınandı.

  **TUZAK — headless Chrome'un görünen alanı `--window-size`'dan ~88 px kısa.** PNG tam boyda çıkıyor ama alt şerit kırpık geliyor; belgenin alt köşeleri düz kesikti ve bu ancak sınır kutusu ölçülünce fark edildi. SVG→PNG çevirirken **fazladan pay ile çekip sol-üstten kırp**. (`pubspec.yaml`'daki çevirme komutu bu yüzden tek başına yeterli değil.)

  Doğrulama: PNG'ler yeniden üretildi (assets + mipmap/drawable tüm yoğunluklar + monochrome), sınır kutuları ve üç maske piksel piksel sınandı. Kod değişmedi. **Cihazda doğrulanmadı — APK CI'da.**

- 2026-08-09 (28. tur): **Arayüz düzeltme paketi + görselde metin tanıma** (dal: `claude/ui-fixes-feature-updates-q3vl88`). Kullanıcının ekran görüntüleriyle bildirdiği dokuz madde ve bir yeni özellik.

  **1) ⋮ menüsü levhaya döndü, "PDF olarak dışa aktar" → "Dışa aktar".** Editörün ⋮'ü on maddelik tek sütunlu bir `PopupMenu` idi ve sayfanın ortasına inen bir sütun kaplıyordu; ana ekranın kart menüsü ([showNoteActionsSheet]) aynı işi çoktandır iki sütunlu levhada yapıyordu — editör de artık aynı dili konuşuyor (`editor/note_menu_sheet.dart`). **KÖK NEDEN — "dışa aktar eskide kaldı":** madde her not tipinde tek bir ekrana, `PdfExportScreen`e gidiyordu; o ekran BELGE (balonlu) notunda yalnız sayfa notlarının METNİNİ yazıyor, belgenin kendisini, balonları, vurguları ve el yazısını hiç almıyordu — yani PDF notunu "PDF olarak dışa aktar"mak çoğu zaman boş/yarım dosya üretiyordu. Balonları belgeye basan yol (`NoteShare.shareAnnotatedPdfs`) ZATEN vardı, sadece Paylaş levhasının içine gömülüydü. Artık damgalanabilir belge varsa hangi çıktının istendiği soruluyor (`showExportChoiceSheet`); aynı düzeltme kart menüsüne de uygulandı.

  **2) Yapay Zeka sayfasında "Belge oku" yukarı taşındı.** Satır sayfanın en altında, "SON İŞLEMLER" listesinin hemen ardındaydı: geçmiş kayıtlarının son maddesi gibi okunuyor, üstelik listede kaç kayıt varsa o kadar aşağı kayıyordu. Artık Günlük Brifing'in yanında. Alt dolguya sistem gezinme çubuğu eklendi ("gece yarısı yenilenir" satırı çubuğun arkasında yarım kalıyordu).

  **3) Sabit başlık ile kayan ızgara arasına SINIR.** Başlık bloğu (arama çubuğu + süzgeç çipleri) zaten kaydırma görünümünün dışındaydı ama arkası saydam, altında hiçbir sınır yoktu; kartlar bloğun dibinden kırpılarak geçtiği için yarım kalan kart çiplerin devamı gibi okunuyor, göz başlığın da kaydığını sanıyordu. Kaydırma başlar başlamaz beliren gölgeli ayırıcı (`_HeaderSeparator`, `ValueNotifier` ile — bildirim ekranın tamamını değil yalnız o çizgiyi çizsin).

  **4) "+" panelinde YAZ bölümü de ızgara.** Metin/Liste/Sıralı liste tam genişlik satırlardı, YAKALA ise ızgara — iki bölüm iki ayrı düğme dili konuşuyordu.

  **5) KÖK NEDEN — "renk seçiyorum geri bırakamıyorum".** Yazı rengi ve vurgu için geri dönüşün TEK yolu paletten AYNI rengi ikinci kez seçmekti (`toggleFormat` o durumda kaldırıyor); hiçbir yerde yazmadığı için bulunamıyordu, kullanıcının bildiği tek çıkış "Biçimi temizle" idi, o da kalın/italik dahil her şeyi siliyordu. Palet artık kendi **"Kaldır"** düğmesini taşıyor (`removeRichFormat` — yalnız o biçmi düşürür, bekleyen biçim de dahil), etkin renk **tikli** çiziliyor ve "Biçimi temizle" biçimsiz metinde SOLUK/tıklanamaz duruyor.

  **6a) KÖK NEDEN — "seçerken kaymalar oluyor".** `Ink`, dekorasyonun kenarlığını çocuğa DOLGU olarak ekliyor (`BoxDecoration.padding == border.dimensions`). Seçince kenarlık 1 → 2 px olunca kart 2 px uzuyor; masonry ızgarada bir kartın 2 px'i altındaki bütün sütunu kaydırıyor, arka arkaya seçimde liste gözle görülür biçimde zıplıyordu. Seçim çerçevesi artık yerleşimi hiç etkilemeyen ayrı bir BOYA katmanı (`Positioned.fill` + `IgnorePointer`).

  **6b) Seçili kart ikinci uzun basışta sürüklenir** — ayrı bir sıralama moduna girmeden. Süzgeç/arama açıkken kapalı: alt kümede taşımak asıl sırayı bozar.

  **6c) Çoklu ek.** Görsel ve PDF seçicileri tek dosyayla sınırlıydı; artık `pickMultiImage` / `DocPicker.pickMany`. Ekler SIRAYLA işleniyor (paralel değil): her ek notu yazıyor ve sayfadaki yerini bir öncekine göre hesaplıyor, aynı anda koşsalardı hepsi aynı noktaya binerdi.

  **6d) Balonlu notun adı.** Fotoğraf/görselden kurulan balonlu notta belgeye yakalama kipinin adı veriliyordu ("Foto çek not al.pdf") — ana ekran aynı adla dolup notlar ayırt edilemiyordu. Ad artık **yakalama levhasında**, kip seçilmeden önce alınıyor (`CaptureChoice.noteTitle`): hem notun başlığı hem üretilen belgenin dosya adı oluyor; boş bırakılırsa eski varsayılana düşülüyor. Paylaşılan damgalı PDF de not başlığını alıyor (`safePdfBaseName`).

  **6e) Bir satır kazanıldı.** Çip şeridi HER NOTTA 34 dp yükseklikte duruyordu — içinde tek bir "+" olsa bile. "+" başlığın sağına taşındı; şerit ancak gerçekten bir çip (hatırlatıcı/klasör/etiket) varsa kuruluyor.

  **6f) "Yeni öğe" ve "Seç" hep görünür.** İkisi madde listesinin FOOTER'ındaydı: elli maddelik notta madde eklemek için önce dibe kadar kaydırmak gerekiyordu. Seçim çubuğunun kullandığı `OverlayPortal` katmanına taşındılar — tek katman, seçim kipinde seçim çubuğu, dışında ekleme çubuğu (ikisi hiç üst üste binmez).

  **6g) Ataç rozeti yeni ek gelince yanıp söner.** Şerit kapalıyken ek eklemek ekranda hiçbir iz bırakmıyordu.

  **6h) KÖK NEDEN — "görsel eklenince klavye kasarak açılıyor" (kalıntı).** `AttachmentStrip`, klavyenin İLK karesinde `SizedBox.shrink()` dönüyordu; şeridin bütün alt ağacı (karolar, görsel çözdürmeleri, ses oynatıcısının State'i) ağaçtan düşüyor, klavye kapanınca sıfırdan kuruluyordu — yeni eklenmiş bir görselde bu, animasyonun tam ortasına denk gelen bir çözdürme demek. Artık `Offstage` + build dışında YAKALANMIŞ çocuk: ağaçta kalır, yerleşim/boyama yapılmaz, alt ağaç hiç yeniden kurulmaz.

  **YENİ — görseldeki metni tanı (Lens tarzı).** Tam ekran görselde bir düğme; tanınan satırlar görselin üstünde kutu kutu beliriyor, dokunulan satır seçiliyor, seçim panoya kopyalanıyor (`ImageViewerScreen` + `_OcrTextLayer`). Tamamen **cihaz içi** (ML Kit, `ScanOcr.recognizeImageLines`): internet gerekmez, **AI puanı harcamaz**. Var olan tek yol notun gövdesine OCR metni yazdıran "Metni al" idi — model çağırıyor, puan yakıyor ve sonucu notun İÇİNE döküyordu. Kutular GÖRSEL PİKSEL uzayında geldiği için katman `InteractiveViewer`'ın çocuğu: yakınlaştırınca kutular yazının üstünde kalır. Düğme yalnız yerel kopyası olan ve piksel ölçüsü bilinen ekte görünür.

  **YAPILMADI:** "notlarda seç yaparken görsellerde seçilebilsin" — tekil görsel zaten seçilip ⋮ → Kopyala ile hem uygulama hem sistem panosuna gidiyor; madde listesiyle BİRLİKTE çoklu görsel seçimi yapılmadı, çünkü ek panosu (`attachmentClipboardProvider`) tek yuvalı.

  Doğrulama: bu oturumda Flutter SDK YOK — `flutter analyze` / `flutter test` **çalıştırılamadı**, doğrulama CI'a bırakıldı. Etkilenen test güncellendi (`action_grids_layout_test.dart`: YAZ bölümü artık ızgara).

- 2026-08-09 (29. tur): **Metni Tanı ekranı, çoklu görsel, dışa aktarma düzeni, model seçici** (dal: `claude/ui-fixes-feature-updates-q3vl88`).

  **1) Metin tanımanın TEK yüzeyi** (`viewers/text_recognize_screen.dart`). Uygulamada üç ayrı davranış vardı: sayfadaki görselin ⋮ menüsündeki "Metni al" modele gidip **bütün metni sormadan notun gövdesine döküyordu** (kullanıcı: "böyle olmaz, yine metni tanı ekranı gelmeli" — üstelik her seferinde AI puanı yakıyordu), tam ekran görüntüleyicide satır seçen ayrı bir katman vardı, AI levhasındaki giriş ise bambaşka bir yola sapıyordu. Üçü de artık aynı ekrana gelir; ML Kit yoksa (masaüstü) eski model yolu yedek kalır.

  **2) KÖK NEDEN — "harf harf seçebilmeliyiz, şu an cümle cümle seçiliyor".** İlk katman ML Kit'in SATIR kutularını dokunulabilir kutulara çeviriyordu; en küçük seçim birimi bir satırdı. `RecognizedText` (data/scan) metni tek dizeye toplar ve **her karakterin** kutusunu tutar: OCR karakter kutusu vermediği için sözcük kutusu karakter sayısına eşit dilinir (taranmış PDF'te de aynı yaklaşım — `buildOcrPageText`). Sözcük arası boşluğun kutusu iki sözcüğün ARASI: seçim vurgusu kesintisiz görünsün. BMP dışı karakterde (emoji) kutu iki UTF-16 birimi için de eklenir, yoksa indeksler kayardı.

  **TUZAK — jest arenası.** Seçim katmanı `GestureDetector` KULLANMAZ, yalnız `Listener`: arenaya giren bir tanıyıcı dıştaki kaydırma görünümleriyle yarışır ve biri hep kaybeder. Uzun basış elle ölçülür (zamanlayıcı + kayma toleransı), seçim sürerken kaydırma `NeverScrollableScrollPhysics` ile kilitlenir. Yakınlaştırma da `InteractiveViewer` DEĞİL, ölçek düğmeleri — iç içe tanıyıcılar seçimi güvenilmez kılıyordu.

  **3) Görsellerde çoklu seçim.** Bir görselin araç panelinden "Görselleri seç" → dokunarak işaretleme → ekranın dibindeki çubuktan toplu kopyala/sil. Ek panosu (`attachmentClipboardProvider`) tek yuvadan **listeye** geçti; yapıştırma hepsini SIRAYLA getirir (paralel olsaydı hepsi sayfanın aynı noktasına binerdi — bkz. `_placeNewImage`). Sistem panosu tek görsel taşıyabildiği için oraya yalnız ilki yazılır.

  **4) KÖK NEDEN — dışa aktarmada görselin yeri.** Görsel HER ZAMAN tam genişlik bir blok olarak iki satırın arasına konuyordu; notta yanından metin akan görsel, belgede altına yarım sayfa boşluk bırakıyor ve metni bir sonraki sayfaya itiyordu (kullanıcı: "yanında metin olanın ayrı bir sayfa olarak değil"). Artık sayfa genişliğinin en çok %70'ini kaplayan ve bir kenara yaslı görsel FLOAT sayılıyor: yüksekliği kadar satır (`_lineHeight`) `Row`un öbür gözüne diziliyor. **TUZAK:** `MultiPage` tek bir `Row`u ikiye BÖLEMEZ — görsel sayfanın yarısından uzunsa float'tan vazgeçilir, yanına konacak satır sayısı da sayfaya sığacak kadarla sınırlanır. Dışa aktarma ekranına görsel başına hiza / genişlik / konum ayarı ve dahil etme anahtarı eklendi.

  **5) KÖK NEDEN — model seçimi (kullanıcı üçüncü kez bildirdi).** Ayarlarda beş `DropdownButtonFormField` alt alta duruyordu; her biri sağlayıcının onlarca modelini iki satırlık öğelerle listeliyor, telefonda açılan menü ekranı kaplıyordu. Artık her iş TEK SATIR (solda iş adı, altında seçili model); dokununca arama kutulu, "Önerilen"/"Diğer" gruplu levha açılıyor. **TUZAK:** `RadioListTile.groupValue`/`onChanged` kullanımdan kalktı — `flutter analyze` bunu hata sayıyor; seçili değer dıştaki `RadioGroup`tan gelmeli (dil seçicisindeki desen).

  **6) İki düzeltme.** "Yeni öğe"/"Seç" tam genişlik bir şeritti, altındaki maddeyi örtüyordu → iki küçük yüzen düğme (`TextButton` KALDI: testler bu tipi arıyor, görünüm `style` ile veriliyor). Ana ekranda seçili kartı ikinci basışla sürükleme çalışmıyordu: **bırakma hedefi yalnız seçili kartlardı**, yani bırakacak yer yoktu; artık hedef tüm kartlar, sürükleyen seçili olan.

  Doğrulama: Flutter SDK bu oturumda YOK; `analyze`/`test` CI'da. Elle yakalanan iki analiz hatası (eksik `dart:math`, kullanımdan kalkmış Radio API) daha push'tan önce düzeltildi.

- 2026-08-09 (30. tur): **"Seç" alt çubuğa, "Yeni öğe" eski yerine** (dal: `claude/ui-fixes-feature-updates-q3vl88`).

  **KÖK NEDEN — yüzen düğmeler alt paneli örtüyordu.** 28. turda "seç ve yeni öğe hep görülmeli" isteğiyle iki düğme `OverlayPortal`a alınıp `bottom: 8 + klavye + sistem çubuğu` ile ekranın dibine demirlenmişti. O konumda ekranın dibinde ZATEN başka şeyler var: ek şeridi ve `BottomAppBar` (Biçim / Ekle / AI / mikrofon). Yüzen katman onların üstüne biniyor, kullanıcı alt çubuğa dokunamıyordu (kullanıcı: "alttaki seç ve yeni öğe satırı alt paneli kapatmış"). Ders: ekranın dibi Scaffold'ın `bottomNavigationBar`ına ait; oraya Overlay ile bir şey demirlemek her zaman çakışır — kalıcı olması gereken eylem alt çubuğun KENDİ segmenti olmalı.

  **Yeni yer.** "Seç" alt çubuktaki kapsülün segmenti (Biçim · Ekle · **Seç** · Ekler); `ItemsEditorState.startSelection()` genel giriş noktasıyla `GlobalKey` üzerinden çağrılır, yalnız notta madde varken görünür. "Yeni öğe" listenin footer'ında, eski yerinde. Kapsül artık `Expanded` + yatay `SingleChildScrollView`: segment sayısı nota göre değiştiği için (dördü birden) dar ekranda taşıyordu; `Spacer` kalktı, boşluğu kaydırma görünümü sağlıyor.

  **TUZAK — testler.** Üç widget testi seçim kipini `find.text('Seç')`e dokunarak açıyordu; düğme artık düzenleyicinin İÇİNDE olmadığı için hepsi `tester.state<ItemsEditorState>(...).startSelection()` çağırıyor.

  Not: 3c22920'nin APK işi runner geri alınması yüzünden İPTAL oldu (analiz+test yeşildi) — o turun APK'sı çıkmadı, bu turun derlemesi ikisini birden taşıyor.

- 2026-08-10 (31. tur): **Asistan not işlevleri, "en çok çalışılan" sıralaması, sıralama modu, imleç ve ses denemesi** (dal: `claude/ui-fixes-feature-updates-q3vl88`).

  **1) KÖK NEDEN — asistan "kırmızı çerçeve yap" isteğini nota MADDE olarak yazıyordu.** `update_note` aracının alanları yalnız metin/madde/etiket/sabitle/arşiv/hatırlatıcıydı; notun görünümünü değiştirecek bir yol YOKTU. Model elindeki tek araçla isteği yerine getirmeye çalışıp isteğin kendisini içerik sanıyordu (ekran görüntüsü: "kırmızı çerçeve koy" maddesi). Araca `color`, `frameColor`, `starred`, `locked`, `checkItems`, `uncheckItems`, `removeItems` eklendi; açıklamasına "isteği notun içine madde olarak YAZMA" kuralı yazıldı ve sesli not görevi "var olan nota yönelik istekte update_note çağır" diye genişletildi. **TUZAK:** araç şeması İKİ yerde tanımlı — `gemini_service._assistantTools` (REST) ve `firebase_ai_client._assistantTools` (dahili anahtar yolu); biri güncellenip öbürü unutulursa özellik yalnız bir sağlayıcıda çalışır. Renk argümanı Türkçe de gelebiliyor, `parseColor` diğer adları tanır.

  **2) "En çok çalışılan" sıralaması.** Sayaç CİHAZ YERELİ (`noteActivityProvider`, SharedPreferences): notu açmak bir puan, o oturumda değiştirmek bir puan daha. Firestore'a yazılmadı — her açılışta not belgesini güncellemek `updatedAt`i tazeler ve "son güncellenen" sıralamasını anlamsızlaştırırdı. Sayaç yalnız o sıralama seçiliyken izlenir (aksi hâlde her not açılışı dashboard'ı yeniden hesaplardı).

  **3) KÖK NEDEN — sıralama modunda "istediğim yere koyamıyorum".** Mod, normal masonry ızgarayı kullanıyordu; masonry kartı O AN en kısa sütuna atar, yani sıradaki n. notun hangi hücreye düşeceği kart YÜKSEKLİKLERİNE bağlıdır. Kullanıcının kurduğu sıra ile ekrandaki yerleşim tutmuyor, aralarda boşluklar kalıyordu. Modda artık eşit yükseklikte kompakt karolar (`_ReorderTile`, 104 px) çizilir: n. not her zaman (n ~/ sütun, n % sütun) hücresindedir. Tarih kovaları modda kapatıldı (kartlar bölümler arası taşınamıyor) ve üst çubuğa ipucu satırı kondu.

  **4) KÖK NEDEN — "imleç resmin solunda ama yazı sağa gidiyor".** Sarma dolguları `WidgetSpan` + `Size(w, 0)` ile, yani YÜKSEKLİĞİ SIFIR kutulardı. İmlecin ekran konumu `TextPainter`ın kutu ölçümünden gelir; dejenere (yüksekliği sıfır) kutu ölçümde işe yaramıyor ve imleç satır başına, görselin üstüne düşüyordu — yazma konumu doğruydu, yalnız imleç yalan söylüyordu. Kutu yüksekliği yarım puntoya çekildi (`wrapAnchorHeight`), ölçüm ve çizim yolunda AYNI değer. Regresyon testi: imlecin dx'i dolgu genişliğinden küçük olamaz + dolgu satır yüksekliğini büyütmez.

  **5) Ses denemesi.** Hız/ton kaydırıcıları ve cihaz sesi seçimi artık örnek cümle okur. Yapay zekâ sesinde örnek model+ses başına BİR KEZ üretilir, `getApplicationSupportDirectory()/tts_samples/` altına yazılır ve sonraki denemeler dosyadan çalar (kullanıcı isteği: "kota harcamasın"). Geçici klasör kullanılmadı — sistem temizleyince örnek yeniden üretilir ve kota boşuna yanardı.

  **6)** "Notları sırala" ⋮ menüsünden kaldırıldı; sıralamanın tek yeri Süz levhası.

  Doğrulama: Flutter SDK yok, `analyze` + 750+ test CI'da yeşil (26858fd).

- 2026-08-10 (32. tur): **Izgara yerleşimi, alt çubuk, sayfa rengi, kağıt tonu ve görsel katmanı** (dal: `claude/note-layout-visual-fixes-35dd2c`).

  **1) KÖK NEDEN — "notların sıralaması düzgün olmuyor, kaymalar oluyor; 2 kolonluda sağ kolonda sürekli boşluklar kalıyor".** `SliverMasonryGrid` kartı YERLEŞİM ANINDA en kısa sütuna atar; yani bir notun hangi sütuna düşeceği, o an ölçülmüş kart yüksekliklerine bağlıdır. Yükseklik kıpırdadığı her durumda (seçim, küçük resmin gelmesi, notun güncellenmesi, tembel yerleşimin sırası) aynı not başka bir sütuna geçiyor, altındaki kartlar kayıyor ve bir sütunda kapanmayan boşluk kalıyordu. Dağıtım artık ÇİZİMDEN ÖNCE ve yalnız NOT İÇERİĞİNE bakılarak yapılıyor (`estimateNoteCardHeight` + `_balancedColumns`): her sütun sıkı bir `Column`, yani kartların ARASINDA boşluk oluşamaz; tahmin şaşarsa bedeli yalnız sütunların DİBİNDEKİ fark. **TUZAK:** bu yerleşim bölümün tamamını tek kutuda çizer, yani tembel değildir — 200'den uzun bölümlerde (`_kStaticGridLimit`) eski masonry'ye dönülür ki çok notlu kitaplıkta ilk kare bedeli büyümesin. Bölümler zaten sabitlenmiş/bugün/bu hafta/daha önce diye bölündüğü için bu sınıra seyrek varılır.

  **2) KÖK NEDEN — "alt kısım sığmıyor: biçim, ekle, seç ve eklerin olduğu kısım".** Kapsül `Expanded` + yatay kaydırma içindeydi: taşma HATASI vermiyor ama segmentler AI düğmesinin solunda kesiliyor, dar telefonda "Seç" yarım ve ataç rozeti hiç görünmüyordu. Kaydırılabilir olduğu da belli değildi. Artık `LayoutBuilder` + `TextPainter` ile etiketlerin gerçek genişliği ölçülüyor; sığmıyorsa etiketler düşüyor ve dört segment de simge olarak yan yana kalıyor (ipuçları duruyor). Kaydırma son çare olarak yerinde.

  **3) Sayfa rengi "Ekle" levhasından BİÇİM şeridine taşındı** (kullanıcı: "sayfa rengi ve yanındaki kısımları biçim menüsüne al"). Renk, PDF/ses/QR gibi EK EKLEYEN maddelerin arasında duruyordu; oysa "bu not nasıl görünsün" ayarı. Biçim şeridinde metin biçimlerinden ince bir çizgiyle ayrılmış palet düğmesi: zemin rengi + çerçeve rengi + zemin görseli aynı levhayı açıyor.

  **4) Kağıt tonu sarı-gri arasına çekildi.** Eski küme saman kağıdıydı; en koyu yüzeyde kırmızı ile mavi kanal arasındaki fark 53 birimdi (0xFFDCCDA7). Fark yarıya indirilip parlaklık korundu — kağıt hissi kalıyor, sarılık göze batmıyor. **TUZAK:** `theme_cache_test` yüzey rengini birebir bekliyor, birlikte güncellendi.

  **5) KÖK NEDEN — "yeni öğe + yazısı resimlerin altında kalıyor".** İki kusur birleşiyordu: (a) düğme satırının yana kayıp kaymayacağı kararı METNE kalan yere bakıyordu, oysa düğme satırının metni yok — küçülemeyen 280 dp'lik sabit bir blok; (b) footer `Column`u `CrossAxisAlignment.start` idi, yani satır yalnız DÜĞME kadar genişti ve `_FloatRow` kesişmeyi kendi genişliğinden ölçtüğü için sayfanın sağ yarısındaki bir görselle "kesişmiyor" görünüyordu. Düğme satırları artık `pushOnly`: bandına değen her görselin ALTINA iner, yana hiç geçmez; footer `stretch` ile tam genişlikte ölçülür.

  **6) KÖK NEDEN — "görseli ön izlemede üst ve yanlarına tıklayınca kapanıyor, altına tıklayınca kapanmıyor".** Önizleme katmanı `Positioned(top: …)` idi ve ALT SINIRI yoktu: kutu yalnız görselin kendi bandı kadar yer kaplıyor, o bandın altına düşen dokunuş katmana hiç ulaşmıyordu. `Positioned.fill` ile katman sayfanın tamamını kapsıyor.

  **7) Sürüklenen görsel yarı saydam** ("notu sürüklediğinde metin notu resmin altında kalıyor"). Görseller metnin ÜSTÜNE çizilir; metin etraflarından akar ama akış ancak yeni bantlar ölçülüp uygulandıktan SONRA (kare sonu) yerine oturur. Parmak hızlıysa görsel arada metnin üstünde duruyor ve satırlar kayboluyordu. Saydamlık yalnız taşıma sürerken; bırakınca görsel tam opak.

  **8) Sessiz bekleme bitti** ("görüntü kopyalanırken veya başka bir şey yüklenirken sessizlik var"). Pano ve ek işleri ancak BİTİNCE SnackBar gösteriyordu; büyük görselin baytlarını okumak (bulut kopyasında indirmek) saniyeler sürüyordu. `_runBusy` + şeritteki canlı gösterge: kopyalama, yapıştırma ve görsel hazırlama artık görünür. Yeni l10n anahtarı `attachmentCopying` on altı dile eklendi (generated dosyalar elle, CI `pub get` ile yeniden üretiyor).

  Doğrulama: Flutter SDK bu oturumda ortamda YOK — `analyze`/`test` çalıştırılamadı, CI'ya bırakıldı. Cihazda doğrulanmadı.

- 2026-08-10 (33. tur): **Sarma garantisi ve klavye karesi** (dal: `claude/note-layout-visual-fixes-35dd2c`).

  **1) KÖK NEDEN — "metin modunda görselin altında kalıyor".** `planTextWrap` dolguyu satır SIRASINA göre, tek geçişte koyuyor; bir satıra dolgu eklemek SONRAKİ satırların kırılımını değiştirdiği için kimi satır dolgusuz kalabiliyordu. En belirgin yol: satır sonu dolgusunun (birleştirici + çapa) kırıcı tarafından bir alt satırın BAŞINA atılması — o satır artık "başında çapa var" sayılıp satır başı dolgusu da almıyor ve metin görselin bandına giriyordu. Görseller metnin ÜSTÜNE çizildiğinden o satırlar okunmaz oluyordu. Plan artık son bir denetimden geçiyor: satırların GERÇEK kutuları görsel bantlarıyla karşılaştırılıyor, hâlâ binen satır tümüyle boşaltılıyor (metin görselin altına iniyor). Denetim tek geçişin bulduğu düzgün sarmayı bozmuyor; yalnız gerçekten binen satıra dokunuyor. Bedel: plan başına EN FAZLA bir ek dizgi — `laidOut` bayrağı, ana döngünün bıraktığı ölçüm tazeyse onu yeniden kullanıyor.

  **2) Sarma eşiği 0.25 → 0.35.** Sayfanın ORTASINA konmuş görsel iki yanında da sütunun dörtte birinden biraz fazla yer bırakıyor, yani eski eşiği geçiyordu; kalan şeride satır başına on beş karakter sığıyor ve metin `NLDESB/` · `270726/0050/01` gibi parçalara bölünüyordu (kullanıcının ekran görüntüsü). Sütunun en az üçte biri kalmıyorsa metin artık yana sıkışmıyor, görselin altına iniyor. Regresyon testi olarak planın GARANTİSİ yazıldı: plan ölçülüp harf harf denetleniyor, hiçbir görünür karakter görselin bandına giremiyor.

  **3) KÖK NEDEN — klavye açılırken kasma.** Alt çubuk klavye yüksekliği kadar büyüyor (`_KeyboardLift`), dolayısıyla Scaffold GÖVDESİNİN kısıtı animasyonun her karesinde değişiyor ve gövdedeki `LayoutBuilder` her karede yeniden koşuyordu: `SingleChildScrollView` + `NotePageCanvas` + her görselin kutusu karede bir baştan yaratılıyordu. Oysa tuvalin kısıttan aldığı tek şey olan taban yükseklik `_stableCanvasHeight` sayesinde ZATEN sabit. Artık aynı taban için BİREBİR AYNI widget örneği dönüyor; Flutter `updateChild`te aynı örneği görünce alt ağacı hiç kurmuyor, animasyon boyunca yeniden kurulan tek şey `Padding` kalıyor. Önbellek her editör build'inde düşürülüyor — bayat ağaç bir kare bile yaşamıyor. **TUZAK:** `_canvasCache` yalnız TEK bir build içindeki `LayoutBuilder` tekrarları içindir; build'ler arasında taşınırsa not değişimi ekrana yansımaz.

  Doğrulama: Flutter SDK yok, `analyze` + testler CI'da. Cihazda doğrulanmadı; kasma ölçümü ancak cihazda yapılabilir.

  **CI'da yakalanan iki tuzak (aynı tur).** (a) Yumuşak satır sonundaki BOŞLUK sarma sınırının ötesine yerleştirilir — Flutter onu satır genişliğine saymaz ama kutusunu üretir. Denetim o kutuya bakınca düzgün sarılmış satırları "bindi" sanıp aşağı itiyordu; karar artık yalnız GÖRÜNÜR harflerden veriliyor. (b) Satırın dikey yerini `LineMetrics.height` toplayarak bulmak yanlış: boşaltılmış satır (yalnız çapa taşıyan) metinli satırdan kısa olabiliyor. Üstüne `_lineRange` konumu x=0'dan okuyor — RTL'de x=0 satırın SONU, LTR'de de tam genişlikte çapa varsa konum bir alt satıra düşüyor. İkisi birden "yanlış satırı denetle" demek. Satır aralıkları artık metnin başından `getLineBoundary` ile yürünerek çıkarılıyor. **Ders:** satır geometrisi metin motorundan OKUNUR, sayılarak bulunmaz.

  **RTL testleri gevşetildi (bilerek).** `startAnchors == 0` ve `widths.every(120)` beklentileri, satır BOŞALTMAYI da yasaklıyordu; oysa boşaltma LTR'de zaten var olan üçüncü uç. Testler artık niyeti ölçüyor: yana kaydıran (kısmi) dolgu doğru tarafta mı + planın GARANTİSİ (hiçbir görünür karakter görselin bandında olamaz). Sayı beklentisi mekanizmayı, geometri beklentisi sonucu ölçer; ikincisi doğru olandı.

- 2026-08-16 (34. tur): **On dokuz maddelik istek listesi** (dal:
  `claude/app-development-tasks-blibxu`). Kararlar ve kök nedenler:

  **1) KÖK NEDEN — "bazı mailler ve internet adresleri eksik yanlış adres
  işaretine alınıyor".** `link_text.dart`'ta e-posta kalıbı HİÇ YOKTU.
  `ali@ornek.com` yazıldığında çıplak alan adı kalıbı `@`'in SAĞINDAKİ
  `ornek.com`'u yakalıyor, kullanıcı adını dışarıda bırakıyordu: adresin
  yarısı maviye boyanıyor, tıklanınca `https://ornek.com` açılıyordu.
  E-posta kalıbı web kalıbından ÖNCE geliyor (alternasyon sırası önemli) ve
  `openLink` `@` görünce `mailto:` şeması kuruyor. Uzantı listesi 17'den
  ~120'ye çıkarıldı (tr alt alanları, ülke kodları, yeni nesil uzantılar).
  **TUZAK:** `at`, `be`, `in`, `it`, `no`, `to`, `us`, `id`, `ma`, `my`, `so`
  BİLEREK dışarıda — "bitti.It happens" gibi noktadan sonra boşluk unutulmuş
  cümleler linke düşüyordu. O alan adları `www.`/`https://` ile yakalanıyor.

  **2) KÖK NEDEN — "3 resim gönderdim 2'si geldi ve üst üste geldiler".**
  İKİ ayrı kusur: (a) `share_intake` her ek için ayrı bir `arrayUnion`
  ateşleyip HİÇBİRİNİ beklemiyordu; son yazım yoldayken açılan editör kendi
  anlık görüntüsünü (henüz 2 ekli) geri yazınca son ek siliniyordu. Artık
  ekler önce toplanıp TEK arrayUnion'da, `await` ile yazılıyor (zaman aşımı
  şart: dönen Future sunucu onayını bekliyor, çevrimdışıyken hiç
  tamamlanmaz). (b) Konumu yazılmamış görsellerin otomatik yığını
  `8 + index * 130` sabit aralıklıydı; varsayılan genişlik sütunun yarısı
  olduğundan dikey bir fotoğraf ~240 dp geliyor ve sonraki görsel öncekinin
  ortasına düşüyordu. Yığın artık GERÇEK yüksekliklerle kuruluyor.

  **3) Metin içi ek etiketi GİZLİ KİMLİK TAŞIMAZ, dosya ADIYLA eşleşir**
  ("📎 rapor.pdf"). Biçim işaretleri metinde durup görünmez çiziliyor; ek
  etiketi için ikinci bir gizli karakter sınıfı daha eklemek, imleç/seçim
  konumlarının denetleyicinin metniyle birebir örtüşmesi gereken bir yerde
  yeni bir kayma kaynağı olurdu. Ad ile eşleşmede çizilen metin ile ham metin
  AYNI; kopyala/yapıştır, paylaşım ve dışa aktarma etiketi okunur taşıyor.
  Bedeli: aynı adlı iki ek varsa etiket ilkine bağlanır. **TUZAK:** PT Sans'ta
  ATAÇ (U+1F4CE) glifi yok — PDF/Word dışa aktarımında etiket
  `exportAttachmentTags` ile "[ek: rapor.pdf]"e çevriliyor, yoksa çıktıda boş
  kutu görünürdü. Düzenlenebilir alanda span'e tıklama çalışmadığı için
  önizleme `TextField.onTap` + imleç konumundan açılıyor.

  **4) Arşiv defteri ayrı bir EKRAN, editörün içinde bir kip değil.** Editör
  tek bir sayfa üstünde çalışıyor (gövde metni, yüzen görseller, ek şeridi);
  defterin içeriği ise sayfalara bölünmüş bir dizin ve asıl işlemi aramak.
  İkisini tek ekrana sığdırmak her iki yerleşimi de bozardı. Otomatik
  sayfaların adları l10n'dan geldiği için kayda YAZILMAZ (dil değişince adlar
  da değişsin); yalnız kullanıcının açtığı sayfalar `Note.archivePages`'te
  durur. Dosyalar KOPYALANIR (kullanıcının açık tercihi): kaynak not silinse
  bile kopya sağlam kalır, bedeli Storage'da iki kez yer kaplaması.

  **5) `Note.listColumns` HER ZAMAN yazılır (koşullu değil).** Notlar
  `set(merge: true)` ile kaydediliyor; atlanmış anahtar SİLİNMEZ, yani
  koşullu yazılsaydı iki sütundan tek sütuna dönmek kayda hiç yansımaz ve not
  her açılışta yine iki sütunlu gelirdi. Aynı gerekçe `archivePages` için de
  geçerli. `NoteItem.starred`/`section` koşullu yazılabiliyor çünkü madde
  dizisi bütün olarak değişiyor.

  **6) İki sütunlu listede SÜRÜKLEYEREK SIRALAMA KAPALI.**
  `ReorderableListView` tek eksende çalışıyor; iki sütunlu ızgarada "araya
  bırak" hedefi belirsiz ve yanlış hesaplanan tek bir indeks bütün listeyi
  karıştırırdı. Sıralama gerekince tek sütuna dönülür; menüdeki "Maddeleri
  sırala" iki sütunda da çalışır.

  **7) KÖK NEDEN — `abiFilters` 32 biti ELEMEDİ (ölçüldü, koşu
  #31951618844).** APK'ya boyut raporu adımı eklenene kadar bu görülmedi:
  rapor üç mimarinin de paketlendiğini gösterdi (arm64 50 MB, x86_64 23 MB,
  armeabi-v7a 14 MB). `libapp.so`/`libflutter.so` gerçekten tek mimariydi —
  yani `--target-platform android-arm64` çalışıyor — fazlalık EKLENTİLERİN
  hazır `.so` dosyalarıydı (ML Kit OCR, barkod, pdfium).
  `defaultConfig.ndk.abiFilters` bunlara işlemiyor. Çözüm
  `packaging.jniLibs.excludes` ile x86/x86_64/armeabi/armeabi-v7a
  klasörlerini paketleme sırasında atmak; koşu #31952689706 yalnız arm64
  kaldığını doğruladı. `splits.abi` bilerek KULLANILMADI: çıktının adını
  `app-arm64-v8a-release.apk` yapıp CI'daki yayınlama yolunu kırardı.
  Rapor adımı artık DENETİM — istenmeyen mimari sızarsa derleme düşer.

  **TUZAK — ölçü birimi karıştırma.** İlk turda "APK 60 MB'tan 100 MB'a
  çıktı" diye yanlış teşhis kondu: karşılaştırılan 51.6 MB önceki koşunun
  ARTIFACT ZIP'iydi, 99.8 MB ise APK dosyasının kendisi. `unzip -l`
  toplamı (110.8 MB) ile dosya boyutunun (99.8 MB) birbirine yakın olması
  yerel kitaplıkların SIKIŞTIRILMADAN saklandığını gösteriyor (AGP
  varsayılanı) — yani APK dosyası zaten büyük görünür. Boyut kıyaslarken
  her zaman aynı şeyi ölç.

  **7b) R8 küçültme AÇILDI.**
  `--target-platform android-arm64` yalnız FLUTTER'ın kitaplıklarını tek
  mimariye indiriyordu; eklentilerin yerel kitaplıkları (ML Kit, pdfium,
  mobile_scanner, record) üç mimari için de paketleniyordu. `proguardFiles`
  zaten tanımlıydı ama `isMinifyEnabled` kapalı olduğu için HİÇ OKUNMUYORDU.
  **TUZAK:** yansıma kullanan yollar tek tek korunuyor —
  `flutter_local_notifications` (Gson ile JSON saklıyor, alan adları
  karışırsa hatırlatıcılar sessizce kaybolur), `home_widget` (sağlayıcı sınıfı
  ADA GÖRE bulunuyor), `io.flutter.**`. Release APK CİHAZDA denenmeli: R8
  hatası derlemede değil, o kod yolu ilk kez çalıştığında patlar.

  **8) AI özet/analizi tamamlanmış maddeleri artık değerlendirmiyor**
  (`Note.toPlainText(skipChecked:)`). Modelin "liste eksik" sanıp uydurmaması
  için kaç madde elendiği tek satırla istemde bildiriliyor. Paylaşım/dışa
  aktarma varsayılanı (false) kullanır — orada işaretli madde GÖRÜNMELİ.

  Doğrulama: bu oturumda Flutter SDK kuruldu (3.47.0), `analyze` temiz ve
  641 test geçiyor. **20 test yerelde `pdfrx` 1.3.5'in Dart 3.13 ile
  derlenmemesi yüzünden YÜKLENEMİYOR** — kusur paketin içinde, değişikliklerle
  ilgisi yok; aynı testler değişiklik ÖNCESİ ağaçta da düşüyor. CI Flutter
  3.44.6 kullanıyor, orada derleniyorlar. Cihazda hiçbir madde
  doğrulanmadı.


- 2026-08-16 (35. tur): **Cihaz denemesinden gelen on bulgu** (dal:
  `claude/app-development-tasks-blibxu`).

  **1) KÖK NEDEN — liste↔metin dönüşümünde maddelerde "OBJ- [x] ..." ham
  metni.** Dönüşüm `_bodyController.text`i okuyordu; o metin görünmez SARMA
  ÇAPALARI (U+FFFC) ve kelime birleştiricileri (U+2060) taşıyor. Çapa satır
  başına düşünce `^([-*•]|\d+[.)])\s+` kalıbı eşleşmiyor, önek sökülmüyor ve
  kullanıcı maddede ham işareti görüyordu; üstelik ham çapalar gövde olarak
  NOTA da yazılıyordu. Artık her iki yön de `logicalText` okuyor, yazarken
  `setLogical` kullanılıyor ve `itemsFromText` görünmezleri kendi de
  temizliyor. **Ders:** editör tamponundan çıkan metin nota gitmeden önce
  MUTLAKA `logicalText`ten geçmeli.

  **2) KÖK NEDEN — "2 sütun anlık görünmüyor, çıkıp girince oluyor".**
  `_sameVisual` (saf-yazım kestirmesi) `listColumns`u KARŞILAŞTIRMIYORDU;
  sütun değişimi "görünür hiçbir şey değişmedi" sayılıp `setState` atlanıyor,
  yeni düzen ancak başka bir sebeple gelen çizimde görünüyordu. `starred` de
  aynı boşluktaydı. **Ders:** çizimi etkileyen her yeni alan `_sameVisual`e
  eklenmeli — unutulursa hata "bazen oluyor" diye görünür ve teşhisi zordur.

  **3) KÖK NEDEN — ipucu ("Not…") ile imlecin ayrı yerde olması.** İpucu
  görselin ALTINA itiliyordu (`hintTopFor`), oysa metin görselin YANINDAN
  akıyor ve imleç ilk satırda kalıyordu. İpucu artık metnin kuralını izliyor
  (`hintPlacement`): yanda kullanılabilir genişlik kalıyorsa görselin
  sağından başlar, kalmıyorsa altına iner — eşik metin sarmasıyla aynı.

  **4) Döndürme ekranı KAPATMIYOR.** Kırpma sonucu notun tuvalinde görülmek
  istenir (ekran kapanır), döndürme ise arka arkaya yapılan bir ayardır;
  her turda ekranı kapatmak kullanıcıyı görseli yeniden açmaya zorluyordu.
  `onRotate` artık güncellenmiş eki döndürüyor, ekran kendini tazeliyor
  (`Image` anahtarına sayaç konur, yoksa aynı yoldaki yeni dosya eski
  önbellekten çizilir).

  **5) Metne gömülü ek bağı: taşıyıcı DOSYA ADI değil KULLANICININ YAZISI.**
  Kullanıcı "o yazıya PDF gömülür" dedi; ilk sürüm etiketi dosya adından
  kuruyordu. Bağ artık `Note.tagLinks` listesinde (etiket metni →
  ek kimliği) duruyor, metinde yalnız görünür bir ataç var. **Metne GİZLİ
  KİMLİK GÖMÜLMEDİ** — biçim işaretlerinin görünmez çizilmesi imleç/seçim
  sözleşmesine bağlı ve ikinci bir gizli karakter sınıfı o sözleşmeyi
  yeniden riske atardı. Harita değil LİSTE: etiket metni nokta içerebiliyor
  ve Firestore harita anahtarı olarak sorun çıkarırdı.

  **6) KÖK NEDEN — klavye kasması (DÜZELTİLDİ, aynı tur).** İlk teşhis
  "Scaffold gövde kısıtı her karede değişiyor" idi ve eksikti: gövdenin
  çocuğu kaydırma görünümünde SINIRSIZ yükseklik kısıtı alıyor, yani tuval
  zaten yeniden yerleşmiyordu. Asıl maliyet ALT ÇUBUKTAYDI. `_KeyboardLift`
  bir `Padding`di; `Padding` çocuğu KISITI DARALTARAK yerleştirir, dolayısıyla
  alt dolgu her animasyon karesinde değişince çocuğun `maxHeight`i de
  değişiyor ve alt çubuğun tamamı (ek şeridi + biçim çubuğu + banner'lar,
  düzinelerce düğme) kare başına bir kez yeniden YERLEŞİYORDU. Widget'lar
  aynı olduğu için yeniden KURULUM yoktu — bu yüzden önceki turlarda
  "yeniden kurmayı önleme" çözümleri sorunu bitirmedi; kasmayı yapan
  yerleşimdi.
  ÇÖZÜM: `_KeyboardLift` artık bir `RenderShiftedBox` — çocuğu GELEN kısıtla
  ölçüyor (kısıt animasyon boyunca sabit, yerleşim atlanıyor) ve yalnız kendi
  boyunu büyütüyor. Sayfa tuvalindeki `PageMinHeight` ile birebir aynı
  yöntem. Ayrıca çubuk `RepaintBoundary`ye alındı: yer değiştirirken gövdeyi
  yeniden boyatmıyor.
  **Ders:** "kısıtı daraltan" her sarmalayıcı (Padding, ConstrainedBox,
  SizedBox) animasyonlu bir değerle beslendiğinde alt ağacın TAMAMINI her
  karede yeniden yerleştirir. Bu depoda aynı tuzağa üçüncü kez düşüldü.

  **6b) İlk teşhis (kayıt için):** Editörün ana build'i
  klavye animasyonundan etkilenmiyor (yalnız `_KeyboardLift` `viewInsets`e
  bağlı ve çocuğu aynı örnek olduğu için alt ağaç yeniden kurulmuyor). Kalan
  maliyet YERLEŞİMDE: alt çubuğun yüksekliği her karede değişince Scaffold
  GÖVDENİN kısıtını da her karede değiştiriyor, yani sayfa tuvali yeniden
  yerleşiyor. Kalıcı çözüm alt çubuğu Scaffold'ın gövde kısıtından ayırmak
  (`resizeToAvoidBottomInset: false` + yığında konumlandırma) ama bu, uzun
  uğraşla ayarlanmış klavye davranışını değiştirir; cihazda profil almadan
  yapılmamalı.


- 2026-08-16 (36. tur): **Kasmanın ASIL kökü ve Paint metin aracının yeri.**

  **1) KÖK NEDEN — klavye kasması (35. turdaki düzeltme YETMEDİ).** O tur
  `_KeyboardLift`in çocuğa DARALTILMIŞ kısıt vermesi düzeltildi ve çubuğun
  İÇİ korundu; ama çubuk hâlâ Scaffold'ın `bottomNavigationBar` YUVASINDAYDI
  ve toplam yüksekliği klavye kadar BÜYÜYORDU. Scaffold gövde alanını
  `bottom - max(viewInsets, altÇubukYüksekliği)` ile hesapladığı için, her
  animasyon karesinde Scaffold'ın kendisi ve gövde yeniden yerleşiyordu.
  ÇÖZÜM: çubuk yuvadan çıkarılıp GÖVDENİN DİBİNE bir `Column` çocuğu yapıldı.
  `Column`da esnek olmayan çocuk SINIRSIZ yükseklik kısıtıyla ölçülür — kısıt
  klavyeden bağımsız, yerleşim tümüyle atlanır. Klavye yüksekliğini artık
  Scaffold'ın kendi `resizeToAvoidBottomInset`i hallediyor; çubuk gövdenin
  dibinde olduğu için kendiliğinden klavyenin üstünde kalıyor ve elle
  kaldırma (`_KeyboardLift`) tümüyle SİLİNDİ.
  **TUZAK:** `SafeArea(bottom: false)` şart. Çubuk yuvadayken Scaffold gövdeden
  alt dolguyu kaldırıyordu; yuva boşalınca dolgu geri gelir ve sayfa alanı
  sebepsiz kısalırdı.
  **Ders:** "alt çubuğu klavyeyle birlikte büyüt" kalıbı Scaffold'ın yerleşim
  hesabına giriyor. Çubuk gövdenin İÇİNDE olmalı; yuva sabit yükseklikli
  çubuklar için.

  **2) KÖK NEDEN — "paint tarzı metin alanını bulamıyorum".** Özellik 34.
  turda BALON KİPİNİN bir seçeneği olarak eklenmişti; oysa balon kipi yalnız
  PDF/SUNUM görüntüleyicisinde var — yani bir FOTOĞRAFIN üstüne yazı koymanın
  hiçbir yolu yoktu ve Paint'te metin aracının doğal yeri tam olarak orası.
  35. turda araç çubuğundaki düğmeyi belirginleştirmek de bu yüzden işe
  yaramadı: sorun düğmenin görünürlüğü değil, EKRANIN yokluğuydu.
  ÇÖZÜM: metin aracı GÖRSEL görüntüleyiciye eklendi (üst barda "T" düğmesi,
  görselde varsayılan olarak açık-metin kipi). Veri modeli hazırdı —
  `Attachment.bubbles` her ek türünde var ve senkronlanıyor; görsel tek sayfa
  olduğu için hepsi `page: 1`. Yazılan metin not sayfasındaki KÜÇÜK HALDE de
  çiziliyor (`_ImageBox._plainTexts`), yoksa kullanıcı fotoğrafa yazıyor ama
  notta hiçbir şey değişmiyordu.
  **Ders:** bir özellik "bulunamıyor" deniyorsa önce o özelliğin BULUNDUĞU
  EKRAN doğru mu diye bakılmalı; düğmeyi büyütmek yanlış ekranda çare değil.

  **3) Ek gömme iki saklı giriş noktasındaydı** (ek şeridindeki 16 px simge ve
  Android'in metin seçim menüsü — fazla maddeleri "⋮" taşmasına atıyor).
  "+ Ekle" levhasına alındı: yazı seçiliyse o yazıya, değilse imlecin yerine
  bağlanıyor. Seçim levha açılırken ANLIK GÖRÜNTÜYE alınıyor — levha klavyeyi
  kapatıyor ve odak düşünce seçim daralabiliyor.


- 2026-08-16 (37. tur): **Ek gömme İKİ YÖNLÜ.** Kullanıcı: "ek gömmede ters
  olarak da çalışmalı, yani önce eki seçip sonra metni seçme de olmalı."
  İlk sürüm tek yönü destekliyordu (önce yazıyı seç → sonra eki). İkinci yön
  BAĞLAMA KİPİ ile eklendi: ek seçilince `_pendingEmbed` dolar, alt çubukta
  "… bağlanacak yazıyı seç" şeridi çıkar; yazı seçilince hem şeritteki
  "Buraya bağla" düğmesi hem de metin seçim menüsünün ilk maddesi bağlamayı
  bitirir.

  **Neden şeritteki düğme seçimi düşürmüyor:** seçim denetleyicide yaşıyor
  (`controller.selection`), alan odağı kaybetse bile korunuyor — biçim
  çubuğu yıllardır aynı varsayıma dayanıyor (bkz. `FormatTarget`). Bu yüzden
  ayrıca bir anlık görüntü tutmaya gerek yok; "+ Ekle" levhası yolunda ise
  levha klavyeyi kapattığı için anlık görüntü ALINIYOR (`_selectionSnapshot`).

  Ek şeridindeki "Metne ekle" düğmesi de artık dosya adını imlece yazmıyor,
  bağlama kipini başlatıyor — kullanıcının tarif ettiği "önce ek" yönünün
  doğal giriş noktası orası.

- 2026-08-18 (38. tur): **Beş kullanıcı bulgusu**: balonlu PDF adı, "Buraya
  bağla" çalışmıyor, açık metin balonu Paint tarzı değil, klasör = etiketin
  ikizi, Süz çubuğunda istenmeyen etiket çipleri, klavye kasması sürüyor.

  **1) Belge adı KÖK NEDEN.** Balonlu not oluşturma yolları (`_buildPageNote*`
  / `_createPageNoteWithPdf`) belgeye NOTUN BAŞLIĞI yerine YAKALAMA KİPİNİN
  MENÜ ETİKETİNİ ("PDF ekle not al") veriyordu — 09-08'deki düzeltme yalnız
  görsellerden kurulan belgeleri kapsamış, editörde SONRADAN eklenen PDF/sunum
  ekleri (`_pickPdf`/`_pickSlide`) ise hâlâ dosyanın KENDİ adını taşıyordu ama
  bu kez başlık istendiğinde uygulanmıyordu. Tek kural: `documentBaseName()`
  (note_share.dart) — başlık doluysa o, boşsa dosyanın kendi adı + "notlar".

  **2) "Buraya bağla" ÇALIŞMIYOR — 37. turdaki varsayım YANLIŞTI.** O turun
  notu "seçim denetleyicide yaşıyor, alan odağı kaybetse bile korunuyor"
  diyordu; bu YANLIŞ — `TextSelection.selection` odak düşünce (ör. şeritteki
  düğmeye dokunmak `EditableText`in odağını düşürür) İMLECE ÇÖKER
  (`isCollapsed`). `_finishPendingEmbed` çöken seçimi görünce sessizce
  "yazıyı seç" uyarısına dönüyordu — kullanıcıya "hiçbir şey olmuyor" gibi
  görünüyordu. ÇÖZÜM iki katmanlı: şerit `TextFieldTapRegion` + `ExcludeFocus`
  içine alındı (dokunmak artık odağı düşürmüyor) VE son DOLU seçim ayrıca
  `_lastBodySelection`de yedekleniyor (odak yine de düşerse diye). **Ders:**
  "biçim çubuğu yıllardır buna dayanıyor" gibi bir emsal, YENİ bir widget'ın
  aynı garantiye sahip olduğunun kanıtı değil — biçim çubuğunun kendi
  düğmeleri zaten `TextFieldTapRegion` içindeydi, bağlama şeridi değildi.

  **3) Klasör = etiketin ikizi — kök tasarım hatası.** Klasör bugüne kadar bir
  SÜZGEÇTİ (Süz levhasında seçilip listeyi daraltan bir seçenek), etiketin
  yaptığı işin birebir aynısı. Kullanıcı isteği net: klasör bir YER olsun, ana
  ekranda kendi karosu olsun, içine girilsin. `FolderTile` (karo) +
  `FolderScreen` (kendi sayfası, `Navigator.push` — GoRouter kabuğunun sağ
  paneline sıkışmasın) eklendi; `folderNotesProvider` klasörün içini SÜZGEÇTEN
  BAĞIMSIZ verir. `filteredNotesProvider` artık klasörlü notu KÖK listede
  GÖSTERMEZ (yalnız süzgeçsiz/aramasız kök görünümde — arama ve etiket/durum
  süzgeçleri klasörün içine yine ulaşır, "notum kayboldu" en pahalı hata).

  **4) Süz çubuğundaki etiket çipleri — TUTARSIZ istisna.** 08-08'de etiketler
  bilerek istisna tutulup yıldızlanmasalar da hepsi çip olmuştu; ama çubuktan
  KALDIRMANIN yolu yoktu (yıldız zaten kapalıydı). Kural artık HER seçenek
  için aynı: yalnız Süz levhasında yıldızlanan şey çubukta çip olur.

  **5) Klavye kasması — YERLEŞİM maliyeti, kurulum değil.** 33./35./36.
  turlar KURULUMU (rebuild) durdurdu: alt çubuk/tuval artık aynı widget
  örneğini dönüyor. Kalan maliyet YERLEŞİMDİ: `Scaffold.resizeToAvoidBottomInset`
  gövdenin kısıtını klavye animasyonunun HER KARESİNDE (~30 kare) değiştiriyor;
  Flutter alt ağacı yeniden KURMASA bile YENİDEN ÖLÇÜYOR — yüzlerce kartlık ana
  ekran ızgarası ve pdfrx (her yeni yükseklikte sayfayı yeniden pişiriyor) bu
  tek başına takılmaya yetiyor. Ana ekran ve editörde `resizeToAvoidBottomInset:
  false`; editörde boşluk artık `KeyboardSnap` (core/widgets/keyboard_snap.dart)
  ile KADEMELİ (96 dp) veriliyor — ~30 yerleşim yerine 3-4. **TUZAK (ilk
  sürümde teste yakalandı):** kademeleme her `build()`'te yeniden hesaplanırsa,
  animasyon durup TAM değere indikten SONRAKİ bir build (ör. tazeleme
  zamanlayıcısının kendi `setState`'i) aynı `live` değerini TEKRAR kademeleyip
  tam değeri anında geri yuvarlar; kademeleme yalnız `live` bir ÖNCEKİ build'e
  göre DEĞİŞTİYSE uygulanmalı. Tam ekran PDF/sunum/görsel görüntüleyicileri
  BİLEREK dokunulmadı — oradaki balon yazma kartı `resizeToAvoidBottomInset`in
  varsayılan davranışına dayanıyor (21. turda ince ayarlanmış "klavyenin
  hemen üstü" konumlaması); kapatmak kartı klavyenin ALTINDA bırakırdı.

- 2026-08-18 (39. tur): **Ortak notlar klasörü + Kişiler (arkadaşlar).**
  Kullanıcı isteği: "ortak notlar klasörü kişiler bağlanır notları ortak
  görür … kişiler kullanıcıya dışarıdan (e-postayla) belirlenebilmeli."
  Sunucusuz mimaride (Cloud Function yok) e-posta → uid çözümü `userDirectory`
  kök koleksiyonuyla, arkadaşlık istek/kabul akışı `friendRequests` +
  `friends` alt koleksiyonlarıyla, klasör paylaşımı `folderShares` kök
  aynasıyla çözüldü (bkz. `firestore.rules` başındaki yorumlar). Paylaşılan
  klasörün notları KOPYALANMAZ — hep SAHİBİNİN koleksiyonunda kalır; paylaşan
  kişi de kendi ekleyeceği notu doğrudan sahibin koleksiyonuna yazar (bkz.
  `sharedFolderNotesProvider`, `FolderScreen._SharedFolderView`).

  **KENDİ KENDİNE GÖZDEN GEÇİRMEDE YAKALANAN İKİ GÜVENLİK AÇIĞI** (kurallar
  yazıldıktan sonra, deploy'dan ÖNCE emülatörle test edilirken bulundu —
  ikisi de canlıya çıksaydı gerçek bir sızıntı olurdu):

  1) **Ters `exists()` yolu.** Arkadaşlık kabulünde Y, X'in `friends` alt
  koleksiyonuna yazarken kanıt olarak `users/{X}/friendRequests/{Y}`'e
  bakıyordu — ama istek her zaman ALICININ (Y) gelen kutusunda durur
  (`users/{Y}/friendRequests/{X}`). Yanlış yön, kabul akışının TAMAMINI
  sessizce reddederdi (`exists()` hep false).

  2) **`folderShares` sahiplik taklidi (gerçek açık).** İlk taslakta
  `folderShares/{folderId}` oluşturma kuralı yalnız `ownerId ==
  request.auth.uid` istiyordu — bu, AYRI bir kök koleksiyon olduğundan,
  herhangi bir kullanıcının RASTGELE bir folderId için sahte bir ayna
  yaratıp kendini `sharedWith`e ekleyerek o klasörün (ve İÇİNDEKİ NOTLARIN)
  sahibiymiş gibi davranmasına izin verirdi. Çözüm: yazan kişinin
  `users/{kendi_uid}/folders/{folderId}` altında GERÇEK bir klasöre sahip
  olduğu `exists()` ile doğrulanır. AYRICA not kuralı yalnız "bu folderId
  bana paylaşılmış mı" değil, "`noteOwnerUid` gerçekten bu folderId'nin
  sahibi mi" diye de sormalı — yoksa biriyle paylaşılan HERHANGİ bir
  klasörün id'si, o klasörle hiç ilgisi olmayan bir kurbanın not
  koleksiyonuna yazı enjekte etmek için kullanılabilirdi.

  **Ders:** paylaşım/yetki kuralları yazıldıktan sonra "mantıken doğru
  görünüyor" yeterli değil — `firebase-tools` + `@firebase/rules-unit-testing`
  ile YEREL EMÜLATÖRDE gerçek `assertSucceeds`/`assertFails` senaryoları
  koşturmak (özellikle "yetkisiz taraf X'i yapabilir mi" testleri) canlıya
  çıkmadan önce iki gerçek deliği yakaladı. Araç bu ortamda önceden kurulu
  değildi; `npm install -g firebase-tools` + `firebase setup:emulators:firestore`
  ile kuruldu, iş bitince kaldırıldı (proje bağımlılığı değil).

  Ayrıca: `NoteFolder`e `ownerId`/`sharedWith` eklendi (klasör dashboard'ta
  karo olduğu için — bkz. 37. tur — artık iki tür karo var: kendi klasörüm
  `FolderTile`, paylaşılan `SharedFolderTile`, aynı rafta yan yana). Kişiler
  ekranı Ayarlar'dan da erişilebilir; hesap silme akışı kendi arkadaş/istek/
  paylaşım kayıtlarını temizler (BİLİNEN SINIR: karşı tarafın aynası, Cloud
  Function olmadığı için, karşı tarafın kendi temizliğine kalır — zararsız
  kalıntı, bkz. account_service.dart).

- 2026-08-18 (40. tur): **"Böyle bir hesap var ama bulamıyor" — KÖK NEDEN.**
  Canlı denemede (v1.0.333) kullanıcı, arkadaş olarak eklemeye çalıştığı
  hesabın var olduğunu ama "bulunamadı" dediğini bildirdi. Diyalog: hedef
  hesap "zaten açıktı, güncelleme yaptım ama çıkıp geri girmedim." Dizin
  senkronu (`syncOwnDirectoryEntry`) yalnız `DashboardScreen.initState`te,
  yani State İLK KURULDUĞUNDA çalışıyordu. APK güncellenip uygulama tam
  kapat-aç yapılmadan arka planda kalıp öne getirilerek devam edilince
  eski State (ve onun bir kez çalışmış initState'i) hayatta kalabiliyor —
  yeni sürümün senkron kodu o oturumda HİÇ tetiklenmiyor, kullanıcının
  e-postası dizine yazılmıyor. ÇÖZÜM: `DashboardScreen` artık
  `WidgetsBindingObserver`; uygulama ÖNE her getirildiğinde (`resumed`) de
  senkron tazelenir — ucuz tek-doküman `merge` yazımı, güncelleme sonrası
  ilk arkaya al/öne getir kendiliğinden düzeltir. **Ders:** "girişte bir
  kez" varsayımı APK GÜNCELLEMESİ senaryosunda YANLIŞ — State ölmeden süren
  bir oturum, kodun yeni sürümünü hiç çalıştırmamış olabilir; tek seferlik
  başlatma mantığı `resume` gibi tekrarlanan, ucuz bir kancayla desteklenmeli.

- 2026-08-18 (41. tur): **"Çıkış yaptım tekrar giremiyorum" — credential-already-in-use.**
  Kullanıcı ⋮ → Çıkış yap sonrası (muhtemel neden: sürüm test ederken temiz
  kurulum SharedPreferences'ı sıfırlamış, `_autoGuestTriedKey` yeniden false
  olmuş) sessiz anonim girişe düşmüş, sonra "Google hesabı bağla" ile ESKİ
  gerçek hesabına dönmeye çalışmış. `linkWithCredential`, o Google kimliği
  zaten BAŞKA (kendi eski) bir uid'e ait olduğu için `credential-already-in-use`
  ile reddediyordu ve ekran ham hata metnini gösterip kullanıcıyı çıkmaza
  sokuyordu — "bağlama" burada yanlış eylemdi, gereken doğrudan GİRİŞ'ti.

  ÇÖZÜM: `_linkAccount` artık bu hatayı özel yakalıyor; Firebase'in hatayla
  birlikte verdiği `e.credential` (reddedilen ama geçerli kimlik bilgisi) ile
  DOĞRUDAN `signInWithCredential` çağırıyor — Google hesap seçicisi tekrar
  açılmadan gerçek hesaba dönülüyor. O anki (atılacak) anonim oturumda not
  varsa (nadir ama olası) önce sayısını söyleyip onay istiyor, yoksa
  sormadan geçiyor.

  **Ders:** "credential-already-in-use" Firebase'in EN SIK karşılaşılan
  anonim-hesap-yükseltme hatasıdır ve SDK bilerek `.credential` alanında
  kurtarma yolunu taşır — ham hata metni basmak yerine bu alan her zaman
  kontrol edilip doğrudan giriş denenmeli.

- 2026-08-18 (42. tur): **Paylaşılan klasör "Missing or insufficient
  permissions" — KÖK NEDEN ve ortak çalışmanın eksik yarısı.**

  Kullanıcı bulgusu: arkadaş eklendi, klasör paylaşıldı, ama karşı hesapta
  klasör açılınca ekranda yalnız
  `[cloud_firestore/permission-denied]` yazıyordu.

  KÖK NEDEN: `sharedFolderNotesProvider`, sahibin notlarını
  `NotesRepository.watchNotes()` ile — yani KOLEKSİYONUN TAMAMINI isteyerek —
  okuyordu. Firestore'da bir LİSTE sorgusu sonuçları kurala göre AYIKLAMAZ:
  kural sonuçtaki her doküman için geçmiyorsa sorgunun TAMAMI reddedilir.
  Kural erişimi yalnız "paylaşılan klasöre ait" notlara veriyordu, sahibin
  öbür notları sorguya girdiği an istek çöküyordu. ÇÖZÜM: yeni
  `watchFolderNotes(folderId)` — sorgu tek eşitlik süzgeciyle klasöre
  daraltıldı (çöp süzgeci istemcide; ikinci bir sunucu süzgeci bileşik
  indeks sorusu açardı, `firestore.indexes.json` bilerek boş).

  **İKİNCİ, DAHA SESSİZ HATA:** liste düzelse bile nota DOKUNULAMIYORDU.
  Editör bütün okuma/yazımlarını `notesRepositoryProvider` (= giriş yapmış
  kullanıcının koleksiyonu) üzerinden yapıyor; paylaşılan not sahibinin
  koleksiyonunda yaşadığı için editör onu bulamıyor, yazımlar da kendi
  altımıza aynı kimlikle HAYALET bir not olarak düşüyordu. Sahip artık
  rotanın `?owner=` parametresiyle taşınıyor (`NoteEditorScreen.ownerId`) ve
  `ownedNoteStreamProvider`/`ownedPendingWritesProvider` sahibin
  koleksiyonunu okuyor. Aynı gerekçeyle paylaşılan kartta ⋮ menüsü
  GİZLENDİ: oradaki işlemlerin hepsi kendi depoma yazıyor.

  **Ders:** "Firestore liste sorgusu = kuralın süzgeci" sanmak bu projede
  ikinci kez pahalıya patladı. Kural neyi açıyorsa SORGU DA tam onu
  istemeli. Ve bir belgeyi başka bir kullanıcının koleksiyonundan göstermek
  yetmez — o belgeye dokunan HER yol (editör, kart menüsü, geri alma,
  silme) hangi depoya yazdığını ayrıca söylemek zorunda.

  **Bu turda eklenenler (kullanıcı listesi):** not paylaşımı (alıcıda
  `users/{uid}/inboxNotes` → "Gelen notlar" ekranı, kabul edince kendi notu
  olur — canlı bağ DEĞİL kopya, çünkü gönderen sonradan silince alıcının
  notu yok olmamalı); klasör yetkileri (okuma / yazma / her ikisi;
  `folderShares.roles` haritası, varsayılan `both` ki eski paylaşımların
  erişimi sessizce kesilmesin); davet kabul/ret (`pending` dizisi + davetli
  yalnız KENDİ satırını `arrayUnion`/`arrayRemove` ile taşıyabilir —
  klasörü okuyamadığı için oku-değiştir-yaz yapamaz); klasör sohbeti
  (`folderShares/{id}/messages`, klasörün altında DEĞİL: erişim sorusunun
  cevabı zaten aynada); ana ekranda arkadaşlık isteği + klasör daveti
  şeridi; klasör rafı varsayılan olarak tek satırlık çip şeridi (karo rafı
  üç klasörde bir 92 px'lik satır açıyordu); sağ üstte hesap simgesi
  (Google fotoğrafı / yerel hesap simgesi) + ⋮ menüsünde hesap-kişiler-gelen
  notlar; Ayarlar'da Hesap ve Kişiler en üste alındı.

  **BİLİNEN SINIR (bilinçli):** ortak klasörde EKLERİN yönetimi paylaşılmaz.
  Görüntüleme çalışır (`downloadUrl` jetonu Storage kurallarından bağımsız),
  ama ek ekleme/silme her zaman giriş yapmış kullanıcının kendi Storage
  yoluna gider — Storage kuralları Firestore'daki paylaşımı GÖREMEZ
  (Cloud Function olmadan çözümü yok). Ortak klasörler metin ve listeler
  için tasarlandı. Aynı gerekçeyle gönderilen notun ekleri taşınmaz.

## 2026-08-21 — Kullanıcı pull listesi: kapsam kararları

Kullanıcı çok maddeli bir "pull" listesi verdi (senkron/görsel/PDF hataları,
web PC görünümü, klavye zıplaması, arkadaş arama, klasör izinleri kişi
bazlı, madde modu hizalama, birlikte-çalışma pomodoro modu, kalem/tablet
premium modu). Netleştirme soruları soruldu, kararlar:

- **Pomodoro/"birlikte çalışalım" modu**: ERTELENDİ, kullanıcı "bunu kaydet
  sonra yapalım" dedi — bu oturumda YAPILMAYACAK. Sonraki bir oturumda ele
  alınacak, kapsam (basit ortak sayaç mı / tam oda-eşleştirme sistemi mi)
  o zaman netleştirilecek.
- **Kalem/tablet premium modu**: bu oturumda KODLANMAYACAK, sadece plan/
  özellik listesi yazılacak (el yazısı sayfası, şekil tanıma otomatik/
  manuel düzelt, premium ek fikirler). Kodlama ayrı bir görev.
- **Diğer maddeler**: hepsi bu oturumda sırayla ele alınacak → bitince
  main'e merge + release APK derlenecek.

Sıradaki liste (pull'dan, pomodoro ve kalem modu hariç):
1. Görsel/belge senkron sorunu (özellikle balonlu modda)
2. Masaüstü/web'de balonlu modda görsel görüntülenememesi
3. "Unsupported operation" hatası — PDF/görsel ekleme (web)
4. Web sürümü mobilin büyütülmüşü gibi — PC'ye özgü layout gerekiyor
5. Kalan kasma/zıplama: klavye açılıp kapanırken biçim/ekle panelinin zıplaması
6. Arkadaş eklemede tüm kullanıcılar içinde arama seçeneği
7. Paylaşılan klasörlerde kişi bazlı okuma/yazma izni (NOT: HAFIZA'da daha
   önce `folderShares.roles` ile read/write/both zaten eklenmiş görünüyor —
   önce mevcut duruma bakılacak, eksikse tamamlanacak)
8. Tablet/kalem modları — SADECE PLAN (bkz. yukarı)
9. Madde modunda kutu hizalaması: kutular ilk satıra göre değil ortalanarak
   diziliyor, düzeltilecek

## 2026-08-21 (devam) — Arkadaş aramada tüm kullanıcılar içinde arama

Kullanıcı "Cloud Function ile tam özellik yap" dedi. Eklenenler:

- `functions/` (yeni klasör, Node.js 20, `firebase-admin`/`firebase-functions`
  v2) — tek callable: `searchUsers({query})`. Giriş şart, sorgu ≥2 karakter,
  en fazla 15 sonuç, kendisi hariç. `userSearch` koleksiyonunda `nameLower`/
  `emailLower` alanlarında iki ayrı önek (prefix) sorgusu çalıştırıp
  birleştiriyor (composite index gerekmiyor, tek alan sıralaması).
- `userSearch/{uid}` — YENİ Firestore koleksiyonu. `userDirectory`'den FARKI:
  istemciden HİÇ okunamaz (`get`/`list` ikisi de `false`), yalnız Admin SDK
  (yani bu fonksiyon) okuyabilir. Yazma yalnız kendi dokümanına
  (`FriendsRepository.syncOwnDirectoryEntry` içinde `userDirectory` ile
  birlikte yazılıyor).
  **Gerekçe**: `userDirectory` zaten `get`e (tam e-posta bilinmeden
  okunamaz) herkese açık ama isimle arama `list`/aralık sorgusu istiyor —
  bunu istemciye açmak tüm kullanıcı tabanının taranabilir olması demek.
  Onun yerine okuma sunucu tarafına (Cloud Function) taşındı, sonuç 15
  kayıtla sınırlı.
- `firestore.rules`: `userSearch` kuralı eklendi.
- `firebase.json`: `functions` bloğu eklendi (`functions/`, nodejs20).
- `pubspec.yaml`: `cloud_functions` paketi eklendi.
- `friends_screen.dart`: "Arkadaş ekle" artık iki sekmeli bir alt sayfa
  (`_AddFriendSheet`) — "Ara" (debounce'lu canlı arama, sonuç listesinde
  doğrudan "Ekle") ve "E-posta ile" (eski tam e-posta akışı, arananın henüz
  `userSearch`e düşmemiş köşe durumları için bırakıldı).
- `friends_repository.dart`: `searchUsers()`, `sendRequestToUid()` eklendi.
- l10n: yeni anahtarlar (`friendsSearch*`) yalnız `app_tr.arb` (şablon) ve
  `app_en.arb`'a eklendi — diğer 14 dil ÇEVİRİLMEDİ, çalışma zamanında
  şablona (Türkçe) düşecekler. Kapsam nedeniyle bilinçli bırakıldı, bir
  sonraki oturumda tamamlanmalı.

**BİLİNEN SINIR / YAPILMASI GEREKEN**: bu özellik DEPLOY EDİLMEDEN
çalışmaz — `functions/README.md`'de adımlar var. Özetle:
`cd functions && npm install && firebase deploy --only functions &&
firebase deploy --only firestore:rules`. Cloud Functions için Blaze
(pay-as-you-go) plana geçiş gerekebilir. Bu ortamda (Claude Code oturumu)
firebase CLI/deploy erişimi YOK, kullanıcı kendi makinesinden yapmalı.

**Bu ortamda Flutter SDK da kurulu değil** — hiçbir değişiklik
`flutter analyze`/`flutter build` ile burada doğrulanamadı, yalnız kod
okuması + Node syntax check (`node --check functions/index.js`) yapıldı.
Gerçek doğrulama push sonrası CI'da (GitHub Actions) ya da kullanıcının
kendi makinesinde olacak.
