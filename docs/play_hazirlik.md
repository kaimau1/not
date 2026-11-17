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

## Yerel Play derleme komutu (henüz CI'da yok)

```
NOTLAR_PLAY=1 flutter build appbundle --release \
  --dart-define=NOTLAR_PLAY=true --dart-define-from-file=env.json \
  --obfuscate --split-debug-info=build/app/outputs/symbols \
  --build-name=<A.B.C> --build-number=<N>
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
- [ ] **AAB**: `flutter build appbundle` (komut yukarıda); CI işi PL13 ile (iki imza).
- [ ] **`--obfuscate`**: yalnız Play komutunda. Crashlytics'te okunur Dart yığın izi için
  sembol yüklemesi gerekir (`flutterfire upload-crashlytics-symbols`, PL15). Kişisel APK'ya
  eklenmedi (yığın izleri bugünkü gibi okunur kalsın).
- [ ] **CI boyut raporu AAB için** (16K §2.6, `build.yml:432-441` adımı): PL13'te.

## PL1'in yerel (derleme dışı bırakma) yarısı — yapılmadı, yapılacak

Dart kapıları özelliği kapatır; ama aşağıdakiler Play paketinde/onay ekranında hâlâ GÖRÜNÜR.
Derleme denenemediği için bilerek yapılmadı:

1. **Konum izinleri (E3)**: `src/main/AndroidManifest.xml:22-24` `ACCESS_*_LOCATION`. Play'de
   `src/play/AndroidManifest.xml` (ör. `<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" tools:node="remove"/>`,
   FINE/COARSE ve geofence alıcısı da) ve `sourceSets.release` içinde `if (play) manifest.srcFile(...)`.
   `play-services-location` bağımlılığı `if (!play)` olacaksa `src/main/.../PlaceReminders.kt`
   (geofence kodu `main`'de) Play için boş eşine taşınmalı (kisisel/genel kalıbı).
2. **ONNX (§2.6, ~11 MB)**: `flutter_onnxruntime` pub bağımlılığı derlemeye hep girer.
   Seçenekler: (a) `packaging.jniLibs.excludes += "**/libonnxruntime*.so"` yalnız `play`
   (Dart kapısı motoru hiç açmadığı için yüklenmez; eklentinin Java kaydı .so'yu açılışta
   yüklemiyorsa güvenli — cihazda doğrula); (b) Antalia'yı ayrı pakete alıp koşullu içe
   aktarma. Önerilen (a) + cihazda açılış/seslendirme denemesi.
3. **Gmail kapsamı (E2)**: kod yalnız Gmail ekranı açılınca `gmail.readonly` ister (Play'de
   ekran yok). Yeni Firebase/Cloud projesinin OAuth onay ekranına Gmail kapsamı EKLENMEZ.
4. **Paket adı / Firebase yapılandırması**: ad seçilince (PL13): `applicationId` Play'de
   yeni ad, `google-services.json` + `firebase_options` çifti.
5. **Güncelleyici (E1)**: Play'in uygulama içi güncelleme API'si istenirse ayrı iş (bağımlılık
   gerekir); şimdilik mağaza güncellemesine bırakıldı.
