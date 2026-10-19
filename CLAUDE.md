# CLAUDE.md — Not (Flutter not uygulaması)

Flutter + Firebase (Firestore/Storage senkron) not uygulaması; Android + Windows hedefli. AI özellikleri Gemini tabanlı: asistan, sesli komut, canlı konuşma çevirisi, semantik arama, OCR, PDF sohbet, günlük brifing. Dil: Türkçe.

> 🔐 **İmza anahtarı**: `android/app/notlar-release.jks` (gitignore'lu, commit'lenmiyor) + parolalar `android/key.properties`. **`Desktop\notlar-keystore\` klasörü ARTIK YOK** — 2026-08-04'te kontrol edildi, tek kopya repo klasöründe. Asla commit'leme, grafa/zip'e katma; **kaybolursa aynı imzayla güncelleme yayınlanamaz — makine dışında bir yedeği olmalı.** CI imzası GitHub Secrets üzerinden.

## Komutlar
> ⚠️ **`flutter` PATH'te DEĞİL** (2026-08-30'da doğrulandı): tam yol `C:\src\flutter\bin\flutter.bat`. Bash aracından `"C:/src/flutter/bin/flutter.bat" test`. "flutter: command not found" görünce SDK yok sanma — 2026-08-30'un ilk turu bu yüzden testleri hiç koşmadan 3 KIRMIZI test commit'ledi ve aynı bug iki tur kaçtı.
- Kurulum: `flutter pub get` · Çalıştır: `flutter run` · Test: `flutter test` (tam takım ~3,5 dk, __TESTCOUNT__ test — 2026-10-19)
- **Bulut oturumunda Flutter YOK**: CI ile aynı sürümü (3.44.6) indir — `curl -o f.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.6-stable.tar.xz` → scratchpad'e aç → `PATH` başına `.../flutter/bin`. 3.47+ KULLANMA (pdfrx 1.3.5 derlenmiyor). `pub get` `pubspec.lock`'u değiştirirse (bağımlılık eklemediysen) commit'e katma.
- **`dart format lib` ÇALIŞTIRMA**: depo tek biçimde değil; toplu biçimlendirme yüzlerce ilgisiz dosyaya dokunur. Yalnız kendi eklediğin dosyayı biçimlendir (üretilen `lib/l10n/generated` hariç — o hep `dart format`).
- **Yerel release APK**: `flutter build apk --release --target-platform android-arm64 --build-number=<N> --dart-define-from-file=env.json`
  - `--dart-define-from-file` ZORUNLU: `GOOGLE_SERVER_CLIENT_ID` olmadan uygulama derlenir ama **Google girişi çalışma anında çöker** (bkz. `env.example.json`, `core/constants.dart`). CI aynı değeri Secrets'tan geçer.
  - `--build-number=<N>` YEREL KURULUM İÇİN ZORUNLU: `pubspec.yaml` sabit `1.0.0+1`, CI ise `--build-number=${{ github.run_number }}` geçiyor. Bayraksız derlenen APK versionCode 1 olur ve telefondaki CI sürümünün üstüne kurulmaz: `INSTALL_FAILED_VERSION_DOWNGRADE` (adb'nin `-d` bayrağı da bunu geçmez). N, telefondaki sürümün üstü olmalı — telefondaki en güncel sürüm CI'ın ürettiği **372** (v1.0.372, 2026-09-01), yerel derlemede bunun üstünü ver.
  - `flutter install` **DERLEMEZ**, var olan APK'yı kurar — önce `build`, sonra `install`. Kurmadan önce APK'nın tarihine bak.
  - `--target-platform android-arm64`: CI de böyle derliyor; bayrak olmadan APK ~110 MB (tüm mimariler), onunla ~60 MB.
  - CI ayrıca `--split-debug-info=build/app/outputs/symbols` verir ve derlemeden önce pdfrx'in pubspec'indeki `- assets/` satırını (web motoru `pdfium.wasm`, 4 MB) pub önbelleğinde yorum yapar, SONRA geri alır (bkz. build.yml; pub önbelleği web derlemesiyle ortak — geri alınmazsa web'de PDF açılmaz). pdfrx'in kendi `remove_wasm_modules` aracı 1.3.5'te derlenmiyor, kullanma.
- APK: CI push'ta imzalı üretir (`.github/workflows/`)
- Firestore/Storage kural değişince: `firebase deploy` (yapılandırma `firebase.json`)

## Hafıza (usta koordineli — 3 katman)
- Kod yapısı        → graphify-out/     (oku: GRAPH_REPORT.md · güncelle: elle `graphify update .` — depoda otomatik kanca YOK; grafik 2026-07-30'dan (`ebba874e`) beri BAYAT, satır/dosya bilgisini koddan doğrula)
- Proje ne/niye     → HAFIZA.md         (oku: iş başı · yaz: iş sonu karar/bug-kök/tuzak, tarihli append-only)
- Kullanıcı tercihi → .claude memory/   (otomatik, projeler-arası — proje bilgisi buraya YAZILMAZ)
Yaz kuralı: usta rule 12 / YAZ — tetikleyici (kalıcı karar, bug kök nedeni, yanlış yol) oluştuysa iş bitmeden yaz. Sır/anahtar/kişisel veri hafızaya YAZILMAZ.

## Yol haritası (fazlı plan)
- `YOL_HARITASI.md` — 2026-10-19 dış göz incelemesinden çıkan 4 fazlı plan (güvenlik/veri → akıcılık → sadeleştirme → eksikler). Kullanıcı **"Faz N'i yap"** dediğinde dosyanın başındaki protokolü izle: yalnız o faz, KARAR GEREKİR maddelerinde önce sor, bitince maddeleri `[x]` + Durum tablosu + HAFIZA + commit/push. Kendiliğinden sonraki faza geçme.
