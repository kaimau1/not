# Play derlemesi hazırlığı (PLAN §1.5 PL1 + PL5 + PL6)

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

## Hak (entitlement) sözleşmesi — PL14 (2026-11-18) + PL6 (2026-11-20)

Belge: `entitlements/{uid}` (kök koleksiyon). **Yazan yalnız sunucu (Admin SDK)**; istemci
yalnız KENDİ belgesini `get` eder, liste/yazma/silme kurallarda kapalı (`rules-test` PL14).
İstemci: `lib/features/entitlement/` (`entitlementProvider`, `proFeatureProvider`); kapı yalnız
`NOTLAR_PLAY` derlemesinde. Belge yok/okunamıyor = ücretsiz.

| Alan | Tür | Yazan | Anlam |
|---|---|---|---|
| `tier` | string `free` \| `pro` \| `lifetime` | `verifyPurchase` / `playRtdn` (PL6) | Satın alınmış katman; tanınmayan değer = ücretsiz. `pro` + geçmiş `proUntil` = Pro bitti |
| `proUntil` | Timestamp | PL6 = en geç(`paidUntil`, `grantUntil`) | Pro bu ana dek açık; yoksa `tier: pro` Pro SAYILMAZ |
| `paidUntil` | Timestamp | PL6 (Play `lineItems[].expiryTime`) | Ödenmiş abonelik süresi; askı/süre dolumu/iade = en geç işlem anı |
| `grantUntil` | Timestamp | YALNIZ ELLE (konsol) | Geliştirici hesabı Pro'su (`2100-01-01`); satın alma bunu kısaltmaz |
| `subTokenKey` | string | PL6 | Geçerli aboneliğin belirteç özeti; plan değişiminde ESKİ belirtecin "bitti"si yenisini ezmez |
| `lifetimeTokenKey` | string | PL6 | Ömür boyunu veren belirtecin özeti; yalnız ONUN iptali/iadesi ömür boyunu kaldırır |
| `trialEndsAt` | Timestamp | `startTrial` — BAĞLI DEĞİL (aşağıda KARAR) | Bu ana dek Pro; bitince ücretsiz/ömür boyu |
| `lifetimeOwned` | bool | PL6 (tek sefer ürünü; iade = false) | Ömür boyu alındı; Pro'ya geçse/Pro bitse de kalır (`tier: lifetime` da aynı anlam) |
| `source`, `updatedAt` | string / Timestamp | PL6 | Denetim izi (`play`); istemci okumaz |

`purchaseTokens/{sha256(purchaseToken)}` = `{uid, productId, createdAt}` (kural eşleşmesi YOK →
istemciye tamamen kapalı, Admin SDK yazar): belirteç hangi hesaba bağlı. Başka hesaba bağlı
belirteç `permission-denied: other-account` (hesap paylaşımı / çalınmış belirteç). Belirteç YALNIZ
Play doğruladıktan sonra yazılır. Hesap silinince (`dropEntitlement`) bağlar da silinir → aynı Play
hesabıyla yeni hesap "Geri yükle" ile ödediğini alır.

## Satın alma — PL6 (P85, 2026-11-20; Play hesabı yok → gerçek satın alma DENENMEDİ)

**Ürünler (kimlikler TEK yer `lib/features/entitlement/data/billing_products.dart`, sunucu eşi
`functions/billing_util.js`; bekçi `test/billing_test.dart`; Play'de verilen kimlik bir daha
kullanılamaz):**

| Play Console | Kimlik | Not |
|---|---|---|
| Abonelik | `pro` | temel planlar `monthly` (P1M) ve `yearly` (P1Y), ikisi de otomatik yenilenir |
| Teklif (her temel planda) | `trial-7d` (ad serbest) | ücretsiz deneme 7 gün, uygunluk "Yeni müşteri edinme" (Play denemeyi yalnız uygun olana listeler; uygulama hangi teklif dönerse onu gösterir) |
| Tek seferlik ürün | `lifetime` | tüketilmez |

Fiyat KODDA YOK (kararı açık): uygulama mağazanın biçimlediği fiyatı gösterir.

**Akış:** satın al (`GooglePlayPurchaseParam`, `obfuscatedAccountId` = sha256(uid)) →
`purchaseStream` → `verifyPurchase` → onay (`completePurchase`; sunucu da onaylar). Doğrulanamayan
satın alma ONAYLANMAZ (Play 3 günde iade eder; kullanıcı boşa ödemez). Bekleyen ödemede belirteç
şimdiden hesaba bağlanır, ödeme onaylanınca RTDN hakkı açar. Açılışta (20 sn sonra) ve Pro ekranı
açılınca sessiz onarım: onaylanmamış ya da hak belgesinde görünmeyen satın almayı yeniden doğrular.
Misafir (anonim) hesaba satılmaz (istemci + sunucu). Web: "satın alma telefondan" yazısı, aynı belgeyi
okur. Kişisel APK / web derlemesinde `InAppPurchase`'a hiç dokunulmaz (bekçi test).

**Sunucu (`functions/billing.js`):** `verifyPurchase` (onCall, `enforceAppCheck: true`) — Google Play
Developer API `purchases.subscriptionsv2.get` / `purchases.products.get` → `entitlements/{uid}`
(işlem içinde, `billing_util.mergeEntitlement`) → onaylanmamışsa `:acknowledge`. `playRtdn`
(Pub/Sub, `retry: true`): abonelik bildiriminde durum API'den yeniden okunur (yenileme, iptal, askı,
süre dolumu, geri alma); plan değişiminde yeni belirtecin hesabı `linkedPurchaseToken`'dan; tek sefer
bildiriminde ömür boyu; `voidedPurchaseNotification` (iade/ters ibraz) = hak hemen kalkar. Geçersiz /
bağlanmamış belirteç yutulur, geçici hata yeniden denenir. **Gizli anahtar YOK:** API'ye Functions'ın
çalışma hizmet hesabıyla (ADC) gidilir.

**Bağlama:** `index.js` billing işlevlerini (+ `dropEntitlement`) YALNIZ `PLAY_PACKAGE_NAME` ortam
değişkeni varken dışa aktarır → kişisel proje (`notlar-kaimau`, CI deploy) DEĞİŞMEZ.

**KARAR (en güvenli, sabah bakılacak):** 7 gün deneme = Play aboneliğinin deneme TEKLİFİ (ödeme yöntemi
ister, yeni hesap açarak yenilenemez); hesap tabanlı `startTrial` BAĞLANMADI (ikisi birden çifte
deneme verirdi; misafir → Google yolu da böylece kalktı). Katman kapısı: yalnız AI bağlı (dahili AI
Pro, kendi anahtarı ömür boyu + Pro, ücretsizde AI yok — `AiAvailability.needsPro`,
`AiAdmission.checkTier`); Play'de `premiumProvider` = hak belgesindeki Pro (`users/{uid}.premiumUntil`
okunmaz). Sürüm geçmişi / yedek / görünüm / anında eşitleme / bulut eki kapıları BAĞLANMADI (kimsenin
elinden özellik alınmasın; temel tema seti, S1 eşitleme aralığı, S4 Drive ekleri kararıyla).

### Kullanıcının yapacakları (Play hesabı + Play Firebase projesi açılınca)

1. **Play Console → Para kazanma → Ürünler:** yukarıdaki tabloyu birebir kur (kimlikleri DEĞİŞTİRME;
   değişirse iki dosyada birlikte değişmeli). Fiyatları sen belirle. Abonelik ayarlarında "Ödemesiz
   dönem" (grace) açık kalabilir.
2. **Hizmet hesabı izni (anahtar dosyası YOK):** Google Cloud (Play projesi) → IAM'de Functions'ın
   çalışma hesabı (2. nesil: `<proje-numarası>-compute@developer.gserviceaccount.com`). Play Console →
   Kullanıcılar ve izinler → bu e-postayı davet et → uygulama izinleri: "Finansal verileri görüntüle",
   "Siparişleri ve abonelikleri yönet". Google Cloud → API'ler: **Google Play Android Developer API**
   etkin. (İzin Play'e yayılması 24 saate dek sürebilir; o arada `verifyPurchase` 401/403 → istemci
   "doğrulanamadı" der, onaylamaz.)
3. **RTDN:** Google Cloud (Play projesi) → Pub/Sub → konu `play-rtdn` oluştur → izinler:
   `google-play-developer-notifications@system.gserviceaccount.com` = "Pub/Sub Yayıncısı". Play
   Console → Para kazanma kurulumu → Gerçek zamanlı geliştirici bildirimleri → konu adı
   `projects/<play-proje>/topics/play-rtdn` → "Deneme bildirimi gönder" (Functions günlüğünde
   "RTDN deneme bildirimi geldi").
4. **Functions ortamı:** `functions/.env.<play-proje-kimliği>` (gitignore'da, sır değil) içine
   `PLAY_PACKAGE_NAME=<paket.adi>` (konu adı farklıysa `PLAY_RTDN_TOPIC=<ad>`). Sonra
   `firebase deploy --only functions --project <play-proje>` (CI Play projesine Functions yayınlamaz).
5. **App Check:** Play projesinde Android (Play Integrity) kaydı; `verifyPurchase` App Check'i
   ZORUNLU tutar (kayıtsız istemci reddedilir).
6. **Geliştirici hesabı Pro'su:** Firestore → `entitlements/<senin uid>` → `tier: "pro"`,
   `proUntil` ve `grantUntil` = 2100-01-01 (Timestamp), `source: "manual"`. Satın alma bunu kısaltmaz.
7. **Deneme:** Play Console → Lisans testi'ne kendi + test hesaplarını ekle (gerçek ücret alınmaz,
   abonelik dakikalar içinde yenilenir). Kapalı test kanalından kur → Ayarlar → Pro → aylık "Ücretsiz
   dene" → durum kartı "Pro · … tarihine dek"; Play'den iptal et → süre sonunda Ücretsiz; ömür boyu al →
   iade et (Play Console → Siparişler) → hak kalkar; ikinci hesapla "Geri yükle" → "başka hesaba bağlı".

**Açık (sabah bakılacak):** (1) fiyatlar; (2) Storage kuralı: Pro değilken buluta YENİ ek yüklemeyi
sunucuda da kapatmak (`firestore.get(entitlements)`; okuma her zaman açık kalır) — S4 ile; (3) AI
kotasının sunucuda sayımı (PL2, Function arkasına alma); (4) ücretsiz katmanda AI girişlerini gizleme
(PL2; şimdilik girişler kilitli görünür, dokununca "Yapay zekâ Pro'da" levhası); (5) Play'in uygulama
içi abonelik değiştirme (aylık → yıllık) — şimdilik Play abonelik sayfasından ("Aboneliği yönet").

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
