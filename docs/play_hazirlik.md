# Play derlemesi hazırlığı (PLAN §1.5 PL1 + PL5 + PL6)

Kaynak: `docs/rapor_2026-11-16_beyin_firtinasi.md` E1–E3, E8, E9, §2.6, §4.5. Denetim 2026-11-17
(bulut, Android SDK yok → derleme denenmedi; aşağıdaki "doğrula" adımları ilk Play derlemesinde).

## Bayraklar

| Katman | Bayrak | Etki |
|---|---|---|
| Dart | `--dart-define=NOTLAR_PLAY=true` → `lib/core/play_build.dart` `PlayBuild.*` | GitHub güncelleyicisi (E1), konum hatırlatıcı (E3), Antalia sesi (§2.6), YouTube otomatik PiP (§4.5) kapalı; ilk akıllı karar rızası (`aiConsent`) açık; `CLOUDFLARE_API_BASE` tanımlıysa Cloudflare Workers/D1/R2 (`cloudflareSync`) etkin (Gmail `lib/features/gmail/` Faz 1'de tamamen kaldırıldı) |
| Gradle | `NOTLAR_PLAY=1` (ya da `-Pplay=true`) → `android/app/build.gradle.kts` `play` | `useLegacyPackaging = false` (sıkıştırılmamış .so); `NOTLAR_KISISEL` ile birlikte verilirse derleme DURUR |

Bayrak yokken (kişisel APK, web) hiçbir şey değişmez — bekçi `test/play_build_test.dart`
(bayraklı koşu: `flutter test test/play_build_test.dart --dart-define=NOTLAR_PLAY=true`).
**Play derlemesi `NOTLAR_KISISEL` OLMADAN** yapılır: `REQUEST_INSTALL_PACKAGES` ve
`SYSTEM_ALERT_WINDOW` (güncelleyicinin kurulum/yeniden açılma izinleri) yalnız
`android/app/src/kisisel/AndroidManifest.xml`'de; genel derlemeye zaten girmiyor.

## Play çeşidi (PL13, P73 2026-11-18)

Çeşit Gradle `productFlavors` DEĞİL, bayrak (`NOTLAR_PLAY=1`): flavor kişisel APK'nın çıktı adını
(`app-release.apk` → `app-<çeşit>-release.apk`) ve CI/Release/güncelleyici yollarını değiştirirdi.
Kişisel/genel derlemede kimlik `dev.kaimau.notlar`, imza, sürüm hesabı AYNEN.

| Ne | Kişisel (bugünkü) | Play |
|---|---|---|
| Paket adı | `dev.kaimau.notlar` | `NOTLAR_PLAY_APP_ID` (env) / `-PplayAppId`; YOKSA derleme DURUR |
| Firebase (yerel) | `android/app/google-services.json` | `android/app/src/release/google-services.json` (gitignore; yoksa derleme DURUR; Play dışı derlemede varsa DURUR) |
| Firebase (Dart) | `DefaultFirebaseOptions.android` | `DefaultFirebaseOptions.play` ← `env_play.json` `PLAY_FIREBASE_*`; boşsa kurulum ekranı |
| env | `env.json` | `env_play.json` (örnek `env_play.example.json`) |
| Site / gizlilik / silme | `AppLinks` varsayılanı `https://notlar-web.pages.dev` + `/gizlilik.html`, `/hesap-silme.html` | `SITE_URL` define'ı |
| İmza | `ANDROID_KEYSTORE_*` | `PLAY_KEYSTORE_BASE64`, `PLAY_KEYSTORE_PASSWORD`, `PLAY_KEY_ALIAS` (yoksa `upload`) |
| Kural yayını | `FIREBASE_SERVICE_ACCOUNT` | `PLAY_FIREBASE_SERVICE_ACCOUNT` + `PLAY_FIREBASE_PROJECT_ID` (yoksa adım atlanır) |

CI (`build.yml`): `play_hazir` + `play` işleri YALNIZ elle ("play" kutusu); `PLAY_APP_ID`,
`PLAY_ENV_JSON` (env_play.json'ın tamamı), `PLAY_GOOGLE_SERVICES_JSON`, `PLAY_KEYSTORE_BASE64`,
`PLAY_KEYSTORE_PASSWORD`'ın biri eksikse uyarı + `play` atlanır (kırmızı değil). AAB denetimi: köprü,
`REQUEST_INSTALL_PACKAGES`, `*_LOCATION` yok; paket adı var. `rules-test` tek kural kümesini sınar →
iki proje için aynı. Eski F18.29 "Genel AAB" adımları (kişisel projeye bağlı) kaldırıldı.

**Sabah bakılacak (kullanıcı):** Play paket adı, ikinci Firebase projesi (+ Android/Web uygulama kaydı,
SHA-1, OAuth istemcisi; Gmail kapsamı EKLENMEZ), yükleme anahtarı, yukarıdaki Secrets; `SITE_URL`
ayrı mı. *(Uygulama kısayolları `android/app/src/main/kisayol/app_shortcuts.xml` artık `targetPackage="${applicationId}"` şablonundan `build.gradle.kts` `KisayolUret` göreviyle çeşit kimliğine göre üretiliyor, P84.)*

## Yerel Play derleme komutu

```
# android/app/src/release/google-services.json = Play projesinin dosyası; env_play.json dolu
bash tool/play_stub/play_hazirla.sh && flutter pub get   # ONNX kuklası (aşağıda PL1 madde 2)
NOTLAR_PLAY=1 NOTLAR_PLAY_APP_ID=<paket.adi> flutter build appbundle --release   --dart-define=NOTLAR_PLAY=true --dart-define-from-file=env_play.json   --obfuscate --split-debug-info=build/app/outputs/symbols   --build-name=<A.B.C> --build-number=<N>
# bitince src/release/google-services.json'ı KALDIR (yoksa kişisel derleme durur) ve
# bash tool/play_stub/play_hazirla.sh geri; git checkout pubspec.lock; flutter pub get
```

## Kontrol listesi

- [x] **E8 hedef API 36**: `targetSdk = flutter.targetSdkVersion`; Flutter 3.47.9'da 36
  (`packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt:34`), CI de 3.47.9
  (`build.yml` `FLUTTER_VERSION`). `compileSdk = 37`. Flutter sürümü düşürülürse yeniden bak.
- [x] **E9 16 KB sayfa** — `build/app/outputs/flutter-apk/app-profile.apk` ARM64 tüm `.so` kitaplıklarında (`libapp.so`, `libflutter.so`, `libvmservice_snapshot.so`: 65536; `libdartjni.so`, `libdatastore_shared_counter.so`, `libimage_processing_util_jni.so`, `libonnxruntime.so`, `libonnxruntime4j_jni.so`, `libpdfium.so`, `libsurface_util_jni.so`: 16384) ELF `LOAD` hizalaması ≥ 16384 doğrulandı (2026-11-27). Play derlemesinde `libonnxruntime*.so` da çıkarılır.
- [x] **Sıkıştırılmamış yerel kütüphane** (Play): Gradle `play` bayrağıyla (yukarıda).
- [x] **AAB**: CI `play` işi (P73, Secrets tanımlanınca); yerel komut yukarıda.
- [x] **`--obfuscate`**: yalnız Play komutunda (CI `play` işi de). Crashlytics'te okunur Dart yığın izi için
  sembol yüklemesi gerekir (`flutterfire upload-crashlytics-symbols`, PL15). Kişisel APK'ya
  eklenmedi (yığın izleri bugünkü gibi okunur kalsın).
- [x] **CI boyut raporu AAB için**: `play` işi denetim adımı `base/lib/` en büyük 20 girdiyi yazar (P73).

## PL1'in yerel (derleme dışı bırakma) yarısı — P73 (2026-11-18)

1. **[x] Konum izinleri (E3)**: `src/play/AndroidManifest.xml` FINE/COARSE/BACKGROUND_LOCATION
   ve `PlaceReminderReceiver`/`PlaceBootReceiver`'ı `tools:node="remove"` ile siler; Gradle
   `play` iken release manifestine ekler. `play-services-location` + `PlaceReminders.kt` kalır
   (izinsiz çalışamaz; Dart kanalı Play'de çağrılmaz). Bekçi `test/play_build_test.dart`;
   CI `play` işi AAB'de `_LOCATION` arar.
2. **[x] ONNX (§2.6, ~11 MB):** `.so` dışlaması GÜVENSİZ (kanıt: `flutter_onnxruntime` 1.9.0
   `FlutterOnnxruntimePlugin.onAttachedToEngine` satır 178 `OrtEnvironment.getEnvironment()`
   çağırır → yerel kütüphane AÇILIŞTA yüklenir; `.so` yoksa `UnsatisfiedLinkError` (Error;
   GeneratedPluginRegistrant yalnız Exception yakalar) → açılışta çöker). Çözüm: Play'de eklenti
   HİÇ kayıtlı olmaz. `tool/play_stub/play_hazirla.sh` depoya girmeyen `pubspec_overrides.yaml`
   yazar → `flutter_onnxruntime` `tool/play_stub/flutter_onnxruntime` kuklasına (eklenti DEĞİL,
   aynı Dart yüzü, her çağrı `UnsupportedError`) yönlenir; `flutter pub get` sonrası Android
   eklenti listesinde yok → `GeneratedPluginRegistrant`'ta yok, `libonnxruntime.so` pakette yok.
   Kişisel APK/web: dosya yok → gerçek paket, hiçbir şey değişmez. CI `play` işi kuklayı kendisi
   bağlar ve AAB'de `libonnxruntime` varsa durur. Bekçi `test/play_build_test.dart`.
   Yerelde Play derlemesinden sonra: `bash tool/play_stub/play_hazirla.sh geri` +
   `git checkout pubspec.lock` + `flutter pub get`. Antalia kodu yeni bir ONNX çağrısı
   kullanırsa kuklaya da eklenmeli (yoksa Play derlemesi derleme hatası verir).
3. **[x] Gmail kapsamı (E2)**: Faz 1'de `lib/features/gmail/` (5 dosya) ve `/gmail` rotası tamamen kaldırıldı; pakette/manifestte Gmail izni yoktur. Play Firebase/Cloud projesinin OAuth onay ekranına Gmail kapsamı EKLENMEZ (kullanıcı, konsolda).
4. **[x] Paket adı / Firebase yapılandırması**: PL13 (yukarıda "Play çeşidi").
5. **Güncelleyici (E1)**: Play'in uygulama içi güncelleme API'si istenirse ayrı iş (bağımlılık
   gerekir); şimdilik mağaza güncellemesine bırakıldı.

## Hak (entitlement) sözleşmesi — PL14 (2026-11-18) + Faz 1/2 (2026-11-25)

Belge: Firebase yolunda `entitlements/{uid}` (kök koleksiyon); Cloudflare yolunda (`PlayBuild.cloudflareSync`) `GET /v1/entitlement` (`cloudflare/src/billing.ts`). **Yazan yalnız sunucu**; istemci yalnız kendi belgesini okur (`rules-test` PL14 + `billing_util.js`).
İstemci: `lib/features/entitlement/` (`entitlementProvider`, `effectiveTierProvider`, `EntitlementGate`); kapı yalnız `NOTLAR_PLAY` (`EntitlementGate.active`) iken etkilidir — kişisel APK/web derlemelerinde her özellik açıktır. Belge yok/okunamıyor = `free` (Lite).

| Alan | Tür | Yazan | Anlam |
|---|---|---|---|
| `tier` | string `free` \| `lifetime` | `verifyPurchase` / `playRtdn` / Cloudflare `/v1/billing/*` | Satın alınmış katman; tanınmayan değer = `free` (eski `pro` kaydı süre dolana dek `lifetime` sayılır) |
| `lifetimeOwned` | bool | Sunucu (50 TL tek seferlik `lifetime`; iade = `false`) | Tek seferlik Tam Sürüm sahipliği (`ProFeature.values` tümünü açar) |
| `decisionCredits` | int | Sunucu (`decision_pack_1000`, tüketilebilir +1.000) | Kalan ek Akıllı Karar paketi çağrı kredisi (`EntitlementGate.allows(ProFeature.smartDecisions, ...)` açık) |
| `decisionTokenCredits` | int | Sunucu (`decision_pack_1000`, +800.000) | Kalan ek Akıllı Karar girdi jetonu bütçesi |
| `proUntil`, `trialEndsAt` | Timestamp? | Eski süreli kayıt geriye uyumu | Yalnız eski abonelik/deneme kaydı varsa bitiş anına dek Tam Sürüm kabul edilir; yeni abonelik satışı YOKTUR |
| `lifetimeTokenKey`, `source`, `updatedAt` | string / Timestamp | Sunucu | Denetim izi + hesap silmeye dayanıklı token özeti |

`purchaseTokens/{sha256(purchaseToken)}` (`purchase_tokens`) hangi hesaba bağlı olduğunu tutar; başka hesaba bağlı belirteç `other-account` döner.

## Karar vekili — Decisions kotası (Faz 0+1+2, `gemini-decision-1`)

`functions/decisions.js` (`decide`, App Check zorunlu) ve Cloudflare Worker `POST /v1/decide` (`cloudflare/src/decisions.ts`), kendi Gemini anahtarı (BYOK) olmayan Tam Sürüm/paketli kullanıcının **yalnız `gemini-decision-1`** karar çağrılarını (`shopAisle`, `dropTarget`, `captureRoute`, `noteTriage`, `listClassify`) uygulamanın anahtarıyla yapar (`GEMINI_DECISIONS_KEY`).

- **Maliyet ve istismar korumaları (P0-1, P0-3, P0-4):**
  - İstek doğrulama: yalnız `gemini-decision-1`, toplam JSON payload `≤ 8.000` karakter (`input ≤ 8.000` karakter, `≤ 60` soru).
  - Çift kilitli ömür boyu bütçe (`lifetime`, 50 TL): **750 çağrı VE 600.000 gerçek girdi jetonu (`usage.total_input_tokens`)** (en fazla ~\$0,06 AI maliyeti). Sayaç `uid` değil **`lifetimeTokenKey` / `token_hash`** altında tutulur; hesap silinip yeniden açıldığında sıfırlanmaz.
  - Ek paket (`decision_pack_1000`, 30 TL, idempotent): **+1.000 çağrı VE +800.000 girdi jetonu**.
  - Sunucu tarafı acil kapatma: Firebase'de `config/app.aiKillSwitch === true`, Cloudflare Worker'da `AI_KILL_SWITCH === "true"`.
- Kurulum: AI Studio'dan yalnız Generative Language API'ye kısıtlı anahtar → Firebase `GEMINI_DECISIONS_KEY` ve/veya Worker sırrı + Cloud Billing bütçe uyarısı (\$5 / \$20 / \$50).

## Satın alma — 2-Katmanlı Tek Seferlik Model (Faz 1)

**Ürünler (kimlikler TEK yer `lib/features/entitlement/data/billing_products.dart`, sunucu eşi `functions/billing_util.js` ve `cloudflare/src/billing.ts`; bekçi `test/billing_test.dart`; Play'de verilen kimlik bir daha kullanılamaz):**

- Abonelik (`pro` aylık/yıllık) ve 7 gün deneme Faz 1'de kaldırılmıştır; tek seferlik model geçerlidir. Eski `tier: 'pro'` kayıtları geriye uyumlu olarak Tam Sürüm (`lifetime`) sayılır.

| Play Console | Kimlik | Not |
|---|---|---|
| Tek seferlik Tam Sürüm (tüketilmez) | `lifetime` | 50 TL (~750 karar / 600K girdi jetonu dahil) |
| Ek Akıllı Karar Paketi (tüketilebilir) | `decision_pack_1000` | 30 TL (+1.000 karar / +800K girdi jetonu; idempotent) |

Fiyat KODDA YOKTUR: uygulama mağazanın biçimlediği yerelleştirilmiş fiyatı (`ProductDetails`) gösterir.

**Akış:** Satın al (`GooglePlayPurchaseParam`, `obfuscatedAccountId` = sha256(uid)) →
`purchaseStream` → `verifyPurchase` (`/v1/billing/verify`) → onay (`completePurchase`; sunucu da `:acknowledge` eder). Doğrulanamayan
satın alma ONAYLANMAZ (Play 3 günde iade eder). Açılışta ve Tam Sürüm ekranı açılınca onaylanmamış/eksik satın alma sessizce yeniden doğrulanır. Misafir (anonim) hesaba satış kapalıdır.

**Sunucu (`functions/billing.js`, `cloudflare/src/billing.ts`):** `verifyPurchase` (`enforceAppCheck: true` + Cloudflare Worker) ve `playRtdn` (Pub/Sub / RTDN webhook) iade/ters ibraz bildirimlerinde (`voidedPurchaseNotification`) hakkı düşürür; `decision_pack_1000` iadesinde ek paket kredilerini de düşer.

### Kullanıcının yapacakları (Play hesabı + Play projesi açılınca)

1. **Play Console → Para kazanma → Ürünler:** yukarıdaki `lifetime` ve `decision_pack_1000` kimliklerini kur (kimlikleri DEĞİŞTİRME; fiyatları sen belirle).
2. **Hizmet hesabı izni (anahtar dosyası YOK):** Google Cloud (Play projesi) → IAM çalışma hizmet hesabını Play Console → Kullanıcılar ve izinler'e ekle (*"Finansal verileri görüntüle"*, *"Siparişleri ve abonelikleri yönet"*). Google Cloud → API'ler: **Google Play Android Developer API** etkinleştir.
3. **RTDN:** Google Cloud (Play projesi) → Pub/Sub → konu `play-rtdn` (`google-play-developer-notifications@system.gserviceaccount.com` = *Pub/Sub Yayıncısı*). Play Console'da `projects/<play-proje>/topics/play-rtdn` bağlayıp deneme bildirimi gönder.
4. **Ortam / Secret'lar:** `functions/.env.<play-proje-kimliği>` içine `PLAY_PACKAGE_NAME=<paket.adi>`; Cloudflare Worker için `wrangler secret put` ile `GEMINI_DECISIONS_KEY` ve doğrulama sırları.
5. **App Check:** Play projesinde Android (**Play Integrity**) kaydını aç; `enforceAppCheck: true`.
6. **Geliştirici hesabı Tam Sürüm:** Firestore `entitlements/<senin uid>` (`tier: "lifetime"`, `lifetimeOwned: true`, `source: "manual"`) — veya Cloudflare D1 `entitlements` satırı.
7. **Lisans testçisi ile uçtan uca deneme:** Kapalı test kanalından kur → Ayarlar → Tam Sürüm (`lifetime` al → iade et → hak kalkar; yeniden al → `decision_pack_1000` al → ikinci hesapla "Satın alımları geri yükle" → `other-account` uyarısı; hesap sil + aynı Play hesabıyla yeniden bağlan → Tam Sürüm geri gelir ama `lifetimeTokenKey` karar sayacı sıfırlanmaz).

## AI korumaları ve Sunucu Durumu (Faz 1+2 güncel)

- Üretken Firebase AI Logic (`firebase_ai`), `GeminiService`, `AiRateLimiter` ve `aiQuota/{uid}` **Faz 1'de kod tabanından tamamen kaldırılmıştır**.
- Uygulamada sunucuya çıkan tek yapay zekâ yolu **Decisions API**'dir (`gemini-decision-1`); hem istemci kapısı (`AiPolicy` + `aiConsent` + `EntitlementGate`) hem de sunucu doğrulaması (`functions/decisions.js` + `cloudflare/src/decisions.ts`: payload ≤ 8.000 karakter, 750 çağrı / 600K jeton çift kilidi, `aiKillSwitch`, App Check) uygulanmıştır (`functions` 37/37, `cloudflare` Worker testleri yeşil).
- **Konsolda açık (kullanıcı):** Play projesinde Google Cloud Billing bütçe uyarısı (\$5 / \$20 / \$50), App Check Enforce ve `PLAY_PACKAGE_NAME` / Cloudflare Worker gizli anahtarlarının atanması.
