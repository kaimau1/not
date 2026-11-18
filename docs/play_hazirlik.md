# Play derlemesi hazırlığı (PLAN §1.5 PL1 + PL5)

Kaynak: `docs/rapor_2026-11-16_beyin_firtinasi.md` E1–E3, E8, E9, §2.6, §4.5. Denetim 2026-11-17
(bulut, Android SDK yok → derleme denenmedi; aşağıdaki "doğrula" adımları ilk Play derlemesinde).

## Bayraklar

| Katman | Bayrak | Etki |
|---|---|---|
| Dart | `--dart-define=NOTLAR_PLAY=true` → `lib/core/play_build.dart` `PlayBuild.*` | GitHub güncelleyicisi (E1), Gmail (E2), konum hatırlatıcı (E3), Antalia sesi (§2.6), YouTube otomatik PiP (§4.5) kapalı; `/gmail` rotası `const` dalla ağaçtan düşer |
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
ayrı mı. Uygulama kısayolları (`res/xml/app_shortcuts.xml`) `targetPackage="dev.kaimau.notlar"` sabit
→ Play paketinde kısayollar açılmaz; kişisel dosyaya dokunmamak için bırakıldı (çözüm: `resValue` +
`@string` ya da `src/play/res/xml` eşi).

## Yerel Play derleme komutu

```
# android/app/src/release/google-services.json = Play projesinin dosyası; env_play.json dolu
NOTLAR_PLAY=1 NOTLAR_PLAY_APP_ID=<paket.adi> flutter build appbundle --release   --dart-define=NOTLAR_PLAY=true --dart-define-from-file=env_play.json   --obfuscate --split-debug-info=build/app/outputs/symbols   --build-name=<A.B.C> --build-number=<N>
# bitince src/release/google-services.json'ı KALDIR (yoksa kişisel derleme durur)
```

## Kontrol listesi

- [x] **E8 hedef API 36**: `targetSdk = flutter.targetSdkVersion`; Flutter 3.47.9'da 36
  (`packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt:34`), CI de 3.47.9
  (`build.yml` `FLUTTER_VERSION`). `compileSdk = 37`. Flutter sürümü düşürülürse yeniden bak.
- [ ] **E9 16 KB sayfa** — beklenen durum (doğrula):
  - `libflutter.so`, `libapp.so`: Flutter 3.47 + NDK 28.2 → 16 KB hizalı (varsayılan).
  - `libonnxruntime.so`: `flutter_onnxruntime` 1.9.0 → `onnxruntime-android:1.28.0`
    (eklenti CHANGELOG: 1.22'den beri 16 KB) — Play'de zaten çıkarılacak (aşağıda).
  - `libpdfium.so`: pdfrx 2.6.6 (CHANGELOG: "Explicitly specify 16KB page size on Android").
  - ML Kit OCR/barkod: Play Hizmetleri'nden (`play-services-mlkit-text-recognition`,
    `mobile_scanner.useUnbundled=true`) → pakette .so yok.
  - Bilinmeyen: AndroidX/Firebase'in küçük .so'ları (ör. datastore). Doğrulama:
    `unzip` + `llvm-objdump -p lib/arm64-v8a/*.so | grep LOAD` (hizalama `2**14` olmalı)
    ya da Android Studio APK Analyzer; AAB yüklenince Play Console ön denetimi.
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
2. **[ ] ONNX (§2.6, ~11 MB) — YAPILMADI, kanıtlı:** önerilen (a) `.so` dışlaması GÜVENSİZ.
   `flutter_onnxruntime` 1.9.0 `FlutterOnnxruntimePlugin.onAttachedToEngine` (satır 178)
   `OrtEnvironment.getEnvironment()` çağırır → yerel kütüphane AÇILIŞTA yüklenir; `.so`
   yoksa `UnsatisfiedLinkError` (Error; GeneratedPluginRegistrant yalnız Exception yakalar)
   → Play uygulaması açılışta çöker. Yol (b): Antalia'yı ayrı Dart paketine/eklentiye alıp
   Play'de bağımlılıktan çıkarmak (pubspec çeşide göre değişmez → ayrı paket + koşullu
   içe aktarma ya da eklentiyi çatallayıp tembel yükleme). Sabah bakılacak.
3. **[x] Gmail kapsamı (E2)**: pakette/manifestte Gmail izni yok; kapsam yalnız Gmail ekranında
   istenir, Play'de ekran yok (`PlayBuild.gmail`). Play Firebase/Cloud projesinin OAuth onay
   ekranına Gmail kapsamı EKLENMEZ (kullanıcı, konsolda).
4. **[x] Paket adı / Firebase yapılandırması**: PL13 (yukarıda "Play çeşidi").
5. **Güncelleyici (E1)**: Play'in uygulama içi güncelleme API'si istenirse ayrı iş (bağımlılık
   gerekir); şimdilik mağaza güncellemesine bırakıldı.

## Hak (entitlement) sözleşmesi — PL14 (2026-11-18) / PL6 doğrulama Function'ı için

Belge: `entitlements/{uid}` (kök koleksiyon). **Yazan yalnız sunucu (Admin SDK)**; istemci
yalnız KENDİ belgesini `get` eder, liste/yazma/silme kurallarda kapalı (`rules-test` PL14).
İstemci: `lib/features/entitlement/` (`entitlementProvider`, `proFeatureProvider`); kapı yalnız
`NOTLAR_PLAY` derlemesinde. Belge yok/okunamıyor = ücretsiz.

| Alan | Tür | Yazan | Anlam |
|---|---|---|---|
| `tier` | string `free` \| `pro` \| `lifetime` | doğrulama Function'ı (PL6); deneme tetikleyicisi `free` | Satın alınmış katman; tanınmayan değer = ücretsiz |
| `proUntil` | Timestamp | doğrulama Function'ı (Play `expiryTime`) | Pro bu ana dek açık; yoksa `tier: pro` Pro SAYILMAZ (geliştirici hesabı = uzak tarih) |
| `trialEndsAt` | Timestamp | `startTrial` (ilk giriş, +7 gün; misafire yok) | Bu ana dek Pro; bitince ücretsiz/ömür boyu |
| `lifetimeOwned` | bool | doğrulama Function'ı (tek sefer ürünü) | Ömür boyu alındı; Pro'ya geçse/Pro bitse de kalır (`tier: lifetime` da aynı anlam) |
| `createdAt` | Timestamp | `startTrial` | Belge ilk yaratılış |
| öneri: `source`, `purchaseToken`, `orderId`, `updatedAt` | string / Timestamp | doğrulama Function'ı | Denetim izi; istemci okumaz. `purchaseToken` başka uid'de kullanılmışsa reddet (hesap paylaşımı) |

**Doğrulama Function'ı arayüzü (PL6, YAZILMADI):** `verifyPurchase` (onCall, App Check zorunlu)
girdi `{productId, purchaseToken}` → Google Play Developer API (`purchases.subscriptionsv2.get` /
`purchases.products.get`) ile doğrula → onaylanmamışsa `acknowledge` → belgeye `set(merge)`
→ dönüş `{tier, proUntil}`. Yenileme/iptal: Play RTDN (Pub/Sub) tetikleyicisi aynı belgeyi
günceller. Web satın almaz ("telefondan al"); aynı belgeyi okur.

**Tetikleyici taslağı:** `functions/entitlements.js` (`startTrial` = auth onCreate, `create()` —
belge varsa dokunmaz; `dropEntitlement` = auth onDelete). `index.js`'e BAĞLI DEĞİL, deploy
edilmez; Play projesi (PL13) kurulunca bağlanır.

**Açık (sabah bakılacak):** (1) hangi özellik hangi katman — `ProFeature` listesi yer tutucu;
(2) misafir → Google bağlanınca deneme (onCreate tetiklenmez; callable ya da `beforeUserSignedIn`);
(3) deneme hesap tabanlı mı, Play aboneliğinin kendi ücretsiz deneme süresi mi (ikisi birden
çifte deneme verir); (4) Storage kuralı: Pro değilken buluta YENİ ek yüklemeyi sunucuda da
kapatmak (`firestore.get(entitlements)`; okuma her zaman açık kalır); (5) eski
`users/{uid}.premiumUntil` (`ai_gate.dart`) bu belgeye taşınır (PL2).
## AI korumaları (PL2) — durum 2026-11-18 (P70)
**İstemcide var (P70):**
- **Acil kapatma** `config/app.aiKillSwitch` (bool, alan yok = false). `true` yazılınca istemci bütün AI
  çağrılarını ağa çıkmadan reddeder, düğmeler kilitli, kart "Yapay zekâ geçici olarak kapalı". Ayrı okuma
  yok: `config/app`'i zaten dinleyen `saveCadenceSyncProvider` uygular (`lib/core/ai_kill_switch.dart`).
  İstemci bu belgeye yazmaz (kural: herkes okur, istemci yazamaz). Bayrağı konsoldan elle yaz; geri almak için sil.
- **Yerel hız sınırı** `AiRateLimiter` (dakikada 30, saatte 300 çağrı; anlamsal arama gömmeleri hariç) —
  takılı döngü ve art arda dokunuş freni; aşılırsa "Çok fazla istek gitti". Atlatılabilir, sunucu
  sınırının yerini TUTMAZ.
- **Tek kapı** `AiAdmission.check` (`lib/features/ai/data/ai_policy.dart`): kullanıcı kapattıysa → acil
  kapatma → rıza (Play) → hız sınırı; `GeminiService` ağa çıkan her yolda önce bunu çağırır.
- Günlük puan sayacı `aiQuota/{uid}` (Firestore; kural: pencere damgası sunucudan, puan yalnız artar,
  tavan 1000) — kotanın istemci tarafı; değiştirilmiş istemci saymadan çağırabilir.

**Sunucuda YOK (Play'den önce şart; F18.28, E4):**
- Dahili AI (Firebase AI Logic) istemciden doğrudan çağrılıyor; App Check Android'de etkin ama konsolda
  **zorlama (enforce) açık mı doğrulanmadı** → Firebase konsolu → App Check → AI Logic: Enforce.
- Kullanıcı başı hız sınırı ve Pro günlük kotası **sunucuda sayılmıyor**: istemci kapısı atlatılabilir.
  Çözüm: AI çağrısını Cloud Function (callable, App Check zorunlu) arkasına al; sayaç Function'da
  (`entitlements/{uid}` Pro ise), `aiKillSwitch`'i de Function okusun.
- Bütçe tavanı: yeni Play projesinde (PL13) Blaze bütçe uyarısı + aşımda AI API'sini kapatan
  bütçe bildirimi → Function. Kişisel proje `notlar-kaimau`'da yok.
