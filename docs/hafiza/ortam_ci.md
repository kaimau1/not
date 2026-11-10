# Hafıza — Ortam, CI, Test tuzakları, Android

HAFIZA.md'den cümle değiştirilmeden taşındı (F58.2, 2026-11-10). Tam eski hâl: `HAFIZA_ARSIV_3.md`.

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

## Açık sorular / bilinen
- Misafir notunda üst çubuk "Senkronize", ana ekran "yalnız bu cihazda"
  diyor — karara bağlanmadı (2026-11-01). **Kapandı (F60.4, 2026-11-10):** üst çubuk da
  misafirde "Yalnız bu cihazda" (`isAnonymousProvider`).
- **Kare ölçümü tabanı** (F18.7, koşu 41422268562, emülatör): ana ekran fırlatma build p90 4,12 / raster p90 6,33 ms; editör yazma build p90 0,26 / raster p90 6,28 ms; kaçan kare 0. Karşılaştırma koşudan koşuya (mutlak değer cihazda farklı). Ölçüm işi `NOTLAR_ALL_ABIS=1` + `--no-dds` ister.
- Cihaz doğrulama listesi `KALANLAR.md` §2 (F18.31 duman testi).
- **2026-11-06 cihaz turu tuzakları:** (1) Not ekranı İÇ İÇE gezginde: kök gezgine açılan levha varken `ModalRoute.of(context).isCurrent` yine true → "levha kapanınca göster" denetimi yanıltır; bildirimi akışın SONUNDA (kayıttan sonra) çağır (`maybeShowAutoStartHint`). (2) Paylaşım alıcısı ikili dosyayı uzantıyla eliyordu; `.notyedek` "PK..." metin notu oldu → `looksLikeZip` imza denetimi. (3) Tam yedek Android'de `saveDocument` (sistem Kaydet) ile; paylaşım levhası yalnız web. (4) adb'nin `am start SEND` ile verdiği media URI'sını uygulama okuyamaz (doğru eleniyor) — paylaşımı Dosyalar uygulamasından dene. (5) Bash aracında heredoc içindeki `\` rtk/kabukta teke iner: düzenli ifade içeren Python'u satır tabanlı yaz.


## Oto güncelleme (2026-11-10 yeniden yazım — dosya-okuyucu düzeni)
- Kaynak: `lib/core/app_update.dart` `AppUpdate` + `ApkGuncelleme.kt` (PackageInstaller oturumu, Android 12+ `USER_ACTION_NOT_REQUIRED`). Algılama doğrudan GitHub `releases/latest` (asset `notlar-v<ANA.ARA.N>.apk`, `PackageInfo.version` ile hane hane); açılışta + öne gelişte, 30 dk sınırlı. Firestore `config/app.latestBuild` artık İSTEMCİDE OKUNMUYOR (CI yazması `continue-on-error`'dı; yazılamayınca telefon hiç duymuyordu — eski kusurun kökü). CI hâlâ yazıyor, zararsız.
- Akış: `AppUpdateRunner` (app.dart kökü) açılıştan 4 sn sonra `runOnStartup`: önbellekte inmiş yeni APK varsa kurar (vazgeçilen sürüm `app_update_declined`, açılışta yeniden sorulmaz), yoksa denetler + arka planda dosyaya indirir. Kurulum not yazarken DEĞİL, sonraki açılışta ya da şeride dokununca. Ana ekranda kapatılamaz `UpdateBanner` (yalnız ValueNotifier; yoksa `SizedBox.shrink`). Ayar `app_update_auto` (Ayarlar en alt).
- Kurulum izni yalnız kişisel derlemede (`canSelfUpdate`); değilse şerit GitHub sayfasını açar. Eski `installApk` (ACTION_VIEW) kanalda duruyor, Dart çağırmıyor.
- Cihazda doğrulanmadı (2026-11-10): ilk geçişte sistem onayı beklenir (kurulum sahibi tarayıcı/dosya yöneticisi); sonrakilerde onaysız olmalı.

## Güncellemeden sonra yeniden aç (2026-11-10)
- Kurulum süreci öldürür. `ApkGuncelleme` commit öncesi `GuncellemeSonrasiAc.mark` (prefs zaman damgası; başarısız
  durumda `unmark`); `GuncellemeSonrasiAlici` (yalnız kişisel manifest, `MY_PACKAGE_REPLACED`) işaret ≤15 dk ise
  `startActivity` dener + yüksek öncelikli "açmak için dokun" bildirimi (izin varsa tam ekran niyeti) — Android 10+
  arka plan başlatma engelinin yedeği. `MainActivity.onCreate` bildirimi kaldırır. Cihazda doğrulanmadı.

- **Bug kökü (2026-11-10, kullanıcı: "Diğer uygulamaların üzerinde göster listesinde çıkmıyor"):** `SYSTEM_ALERT_WINDOW`
  hiç bildirilmemişti → uygulama o listede yoktu, Android 10+'da `startActivity` hep engellenip bildirime düşüyordu.
  Kişisel manifeste eklendi; Ayarlar alt bilgisinde izin durumu satırı (`canDrawOverlays` / `openOverlaySettings`).

## Yenilikler tostu + Ayarlar güncelleme durumu (2026-11-10)
- `lib/app/release_notes_toast.dart` (`ReleaseNotesToast`, AppUpdateRunner altında, 2,5 sn sonra): kurulu sürüm
  prefs'tekinden farklıysa sürüm notlarından GÖRÜLMEMİŞ maddeler (en yeni bölüm kimliği + o bölümde görülen
  maddeler saklanır; aynı gün çok sürüm çıktığı için sürüm değil madde bazlı) ilk 3'ü kısaltılmış tost, "Tümünü gör"
  → `/guide?doc=notes`. İlk kez: yalnız en yeni bölüm. Test `test/release_notes_toast_test.dart`.
- Ayarlar sürüm satırı `AppUpdate.progress`'i dinler: indirme nereden başlarsa başlasın yüzde + çubuk; sonra
  "kuruluyor", iptal/hata/tarayıcı sonucu yazılır.
