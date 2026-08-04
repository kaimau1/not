# CLAUDE.md — Not (Flutter not uygulaması)

Flutter + Firebase (Firestore/Storage senkron) not uygulaması; Android + Windows hedefli. AI özellikleri Gemini tabanlı: asistan, sesli komut, canlı konuşma çevirisi, semantik arama, OCR, PDF sohbet, günlük brifing. Dil: Türkçe.

> 🔐 **İmza anahtarı**: `android/app/notlar-release.jks` (gitignore'lu, commit'lenmiyor) + parolalar `android/key.properties`. **`Desktop\notlar-keystore\` klasörü ARTIK YOK** — 2026-08-04'te kontrol edildi, tek kopya repo klasöründe. Asla commit'leme, grafa/zip'e katma; **kaybolursa aynı imzayla güncelleme yayınlanamaz — makine dışında bir yedeği olmalı.** CI imzası GitHub Secrets üzerinden.

## Komutlar
- Kurulum: `flutter pub get` · Çalıştır: `flutter run` · Test: `flutter test`
- **Yerel release APK**: `flutter build apk --release --target-platform android-arm64 --dart-define-from-file=env.json`
  - `--dart-define-from-file` ZORUNLU: `GOOGLE_SERVER_CLIENT_ID` olmadan uygulama derlenir ama **Google girişi çalışma anında çöker** (bkz. `env.example.json`, `core/constants.dart`). CI aynı değeri Secrets'tan geçer.
  - `flutter install` **DERLEMEZ**, var olan APK'yı kurar — önce `build`, sonra `install`. Kurmadan önce APK'nın tarihine bak.
  - `--target-platform android-arm64`: CI de böyle derliyor; bayrak olmadan APK ~110 MB (tüm mimariler), onunla ~60 MB.
- APK: CI push'ta imzalı üretir (`.github/workflows/`)
- Firestore/Storage kural değişince: `firebase deploy` (yapılandırma `firebase.json`)

## Hafıza (usta koordineli — 3 katman)
- Kod yapısı        → graphify-out/     (oku: GRAPH_REPORT.md · güncelle: commit'te hook otomatik, elle `graphify update .`)
- Proje ne/niye     → HAFIZA.md         (oku: iş başı · yaz: iş sonu karar/bug-kök/tuzak, tarihli append-only)
- Kullanıcı tercihi → .claude memory/   (otomatik, projeler-arası — proje bilgisi buraya YAZILMAZ)
Yaz kuralı: usta rule 12 / YAZ — tetikleyici (kalıcı karar, bug kök nedeni, yanlış yol) oluştuysa iş bitmeden yaz. Sır/anahtar/kişisel veri hafızaya YAZILMAZ.
