# DEVIR — oto/P66-play-hazirlik (P66: PL1, PL5, PL12)

- PL1 Play bayrağı: `lib/core/play_build.dart` (`NOTLAR_PLAY` → `PlayBuild.*`), kapılar:
  güncelleyici (`AppUpdate.supported`, Ayarlar oto güncelleme satırı), Gmail (`gmailAvailableProvider`,
  `/gmail` rotası const if), konum hatırlatıcı (`PlaceReminderService.supported`), Antalia
  (`AntaliaModelFiles.supported`, ses motoru seçicisi, `TtsEngineNotifier` → cihaz), YouTube oto PiP.
  Bekçi: `test/play_build_test.dart` (bayraksız + `--dart-define=NOTLAR_PLAY=true` ikisi de yeşil).
  Gradle/manifest tarafı yapılmadı (izin, ONNX .so, Gmail kapsamı) → `docs/play_hazirlik.md`.
- Şu an: PL5 (Gradle denetimi + docs/play_hazirlik.md), sonra PL12 (hız günlüğü).
- Test: `flutter test test/play_build_test.dart --reporter failures-only` (+ `--dart-define=NOTLAR_PLAY=true`).
