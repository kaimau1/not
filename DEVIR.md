# DEVIR — oto/P66-play-hazirlik (P66: PL1, PL5, PL12)

- PL1 Play bayrağı: `lib/core/play_build.dart` (`NOTLAR_PLAY` → `PlayBuild.*`), kapılar:
  güncelleyici (`AppUpdate.supported`, Ayarlar oto güncelleme satırı), Gmail (`gmailAvailableProvider`,
  `/gmail` rotası const if), konum hatırlatıcı (`PlaceReminderService.supported`), Antalia
  (`AntaliaModelFiles.supported`, ses motoru seçicisi, `TtsEngineNotifier` → cihaz), YouTube oto PiP.
  Bekçi: `test/play_build_test.dart` (bayraksız + `--dart-define=NOTLAR_PLAY=true` ikisi de yeşil).
  Gradle/manifest tarafı yapılmadı (izin, ONNX .so, Gmail kapsamı) → `docs/play_hazirlik.md`.
- PL5: denetim → `docs/play_hazirlik.md` (targetSdk 36 zaten Flutter 3.47.9 varsayılanı; 16 KB beklenen
  durum + doğrulama; AAB/--obfuscate komutu). Gradle: `NOTLAR_PLAY=1` → `useLegacyPackaging=false`,
  KISISEL ile birlikte → derleme durur. Android SDK yok → Gradle derlemesi denenmedi.
- Yerel Play derleme: `NOTLAR_PLAY=1 flutter build appbundle --release --dart-define=NOTLAR_PLAY=true
  --dart-define-from-file=env.json --obfuscate --split-debug-info=build/app/outputs/symbols --build-number=<N>`
- Şu an: PL12 (hız günlüğü).
- Test: `flutter test test/play_build_test.dart --reporter failures-only` (+ `--dart-define=NOTLAR_PLAY=true`).
