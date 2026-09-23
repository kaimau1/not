# CLAUDE.md — Not (Flutter not uygulaması)

Flutter + Firebase (Firestore/Storage senkron) not uygulaması; Android + Windows hedefli. AI özellikleri Gemini tabanlı: asistan, sesli komut, canlı konuşma çevirisi, semantik arama, OCR, PDF sohbet, günlük brifing. Dil: Türkçe.

> 🔐 **İmza anahtarı**: `android/app/notlar-release.jks` (gitignore'lu, commit'lenmiyor) + parolalar `android/key.properties`. **`Desktop\notlar-keystore\` klasörü ARTIK YOK** — 2026-08-04'te kontrol edildi, tek kopya repo klasöründe. Asla commit'leme, grafa/zip'e katma; **kaybolursa aynı imzayla güncelleme yayınlanamaz — makine dışında bir yedeği olmalı.** CI imzası GitHub Secrets üzerinden.

## Komutlar
> ⚠️ **`flutter` PATH'te DEĞİL** (2026-08-30'da doğrulandı): tam yol `C:\src\flutter\bin\flutter.bat`. Bash aracından `"C:/src/flutter/bin/flutter.bat" test`. "flutter: command not found" görünce SDK yok sanma — 2026-08-30'un ilk turu bu yüzden testleri hiç koşmadan 3 KIRMIZI test commit'ledi ve aynı bug iki tur kaçtı.
- Kurulum: `flutter pub get` · Çalıştır: `flutter run` · Test: `flutter test` (tam takım ~2 dk, 996 test)
- **Yerel release APK**: `flutter build apk --release --target-platform android-arm64 --build-number=<N> --dart-define-from-file=env.json`
  - `--dart-define-from-file` ZORUNLU: `GOOGLE_SERVER_CLIENT_ID` olmadan uygulama derlenir ama **Google girişi çalışma anında çöker** (bkz. `env.example.json`, `core/constants.dart`). CI aynı değeri Secrets'tan geçer.
  - `--build-number=<N>` YEREL KURULUM İÇİN ZORUNLU: `pubspec.yaml` sabit `1.0.0+1`, CI ise `--build-number=${{ github.run_number }}` geçiyor. Bayraksız derlenen APK versionCode 1 olur ve telefondaki CI sürümünün üstüne kurulmaz: `INSTALL_FAILED_VERSION_DOWNGRADE` (adb'nin `-d` bayrağı da bunu geçmez). N, telefondaki sürümün üstü olmalı — telefondaki en güncel sürüm CI'ın ürettiği **372** (v1.0.372, 2026-09-01), yerel derlemede bunun üstünü ver.
  - `flutter install` **DERLEMEZ**, var olan APK'yı kurar — önce `build`, sonra `install`. Kurmadan önce APK'nın tarihine bak.
  - `--target-platform android-arm64`: CI de böyle derliyor; bayrak olmadan APK ~110 MB (tüm mimariler), onunla ~60 MB.
- APK: CI push'ta imzalı üretir (`.github/workflows/`)
- Firestore/Storage kural değişince: `firebase deploy` (yapılandırma `firebase.json`)

## Hafıza (usta koordineli — 3 katman)
- Kod yapısı        → graphify-out/     (oku: GRAPH_REPORT.md · güncelle: commit'te hook otomatik, elle `graphify update .`)
- Proje ne/niye     → HAFIZA.md         (oku: iş başı · yaz: iş sonu karar/bug-kök/tuzak, tarihli append-only)
- Kullanıcı tercihi → .claude memory/   (otomatik, projeler-arası — proje bilgisi buraya YAZILMAZ)
Yaz kuralı: usta rule 12 / YAZ — tetikleyici (kalıcı karar, bug kök nedeni, yanlış yol) oluştuysa iş bitmeden yaz. Sır/anahtar/kişisel veri hafızaya YAZILMAZ.
