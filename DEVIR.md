# DEVIR — P73 (oto/P73-play-altyapi)

Kota kararı (2026-11-18): dal PUSH EDİLMEZ, CI koşmaz; doğrulama yerel.

Yapılanlar:
- PL1 (E3): `android/app/src/play/AndroidManifest.xml` konum izinleri + PlaceReminder/PlaceBoot alıcılarını siler; Gradle `play` iken release manifestine ekler.
- PL1 ONNX: YAPILMADI. Kanıt: flutter_onnxruntime-1.9.0 `FlutterOnnxruntimePlugin.kt:178` `OrtEnvironment.getEnvironment()` onAttachedToEngine'de → .so dışlanırsa açılışta UnsatisfiedLinkError.
- PL13: Gradle `NOTLAR_PLAY_APP_ID` şart, `src/release/google-services.json` bekçileri; `DefaultFirebaseOptions.play` (env_play.json), `lib/core/app_links.dart`, `env_play.example.json`, .gitignore; CI `play_hazir`/`play` işleri + deploy'da Play kural yayını (Secrets yoksa atlanır); eski F18.29 AAB adımları kaldırıldı.
- Belgeler: docs/play_hazirlik.md, docs/hafiza/ortam_ci.md, PLAN PL1/PL13, OTOMASYON P73, regresyon listesi.

Doğrulama komutları:
- `flutter test test/play_build_test.dart test/security_guard_test.dart --reporter failures-only` (+ `--dart-define=NOTLAR_PLAY=true`)
- `NOTLAR_KISISEL=1 flutter build apk --release --target-platform android-arm64 --build-number=999` → `aapt dump badging` package dev.kaimau.notlar
- DİKKAT: derleme sürerken `flutter test` koşma — GeneratedPluginRegistrant yeniden yazılır, release derlemesi integration_test yüzünden düşer (yaşandı).

Sabah bakılacak: Play paket adı, 2. Firebase projesi, yükleme anahtarı, PLAY_* Secrets; ONNX ayrı paket; app_shortcuts targetPackage sabit.
