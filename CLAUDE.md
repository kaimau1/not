# CLAUDE.md — Not (Flutter not uygulaması)

Flutter + Firebase (Firestore/Storage senkron) not uygulaması; Android + web hedefli (Windows sürümü 2026-10-19'da kaldırıldı — bilgisayarda web kullanılır). AI özellikleri Gemini tabanlı: asistan, sesli komut, canlı konuşma çevirisi, semantik arama, OCR, PDF sohbet, günlük brifing. Dil: Türkçe.

> 🔐 **İmza anahtarı**: `android/app/notlar-release.jks` (gitignore'lu, commit'lenmiyor) + parolalar `android/key.properties`. **`Desktop\notlar-keystore\` klasörü ARTIK YOK** — 2026-08-04'te kontrol edildi, tek kopya repo klasöründe. Asla commit'leme, grafa/zip'e katma; **kaybolursa aynı imzayla güncelleme yayınlanamaz — makine dışında bir yedeği olmalı.** CI imzası GitHub Secrets üzerinden.

## Komutlar
> ⚠️ **`flutter` PATH'te DEĞİL** (2026-08-30'da doğrulandı): tam yol `C:\src\flutter\bin\flutter.bat`. Bash aracından `"C:/src/flutter/bin/flutter.bat" test`. "flutter: command not found" görünce SDK yok sanma — 2026-08-30'un ilk turu bu yüzden testleri hiç koşmadan 3 KIRMIZI test commit'ledi ve aynı bug iki tur kaçtı.
- Kurulum: `flutter pub get` · Çalıştır: `flutter run` · Test: `flutter test -j 4` (tam takım ~1,5 dk — `-j` olmadan çekirdeklerin yarısıyla ~3 dk)
- **Bulut oturumunda Flutter YOK**: CI ile aynı sürümü (3.47.7) indir — `curl -o f.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.7-stable.tar.xz` → scratchpad'e aç → `PATH` başına `.../flutter/bin`. pdfrx 2.6 Flutter ≥3.47 ister (F3.15, 2026-10-19). `pub get` `pubspec.lock`'u değiştirirse (bağımlılık eklemediysen) commit'e katma.
- **`dart format lib` ÇALIŞTIRMA**: depo tek biçimde değil; toplu biçimlendirme yüzlerce ilgisiz dosyaya dokunur. Yalnız kendi eklediğin dosyayı biçimlendir (üretilen `lib/l10n/generated` hariç — o hep `dart format`).
- **Yerel release APK**: `flutter build apk --release --target-platform android-arm64 --build-number=<N> --dart-define-from-file=env.json`
  - `--dart-define-from-file` ZORUNLU: `GOOGLE_SERVER_CLIENT_ID` olmadan uygulama derlenir ama **Google girişi çalışma anında çöker** (bkz. `env.example.json`, `core/constants.dart`). CI aynı değeri Secrets'tan geçer.
  - `--build-number=<N>` YEREL KURULUM İÇİN ZORUNLU: `pubspec.yaml` sabit `1.1.0+1`, CI ise `--build-name=1.1.<koşu> --build-number=${{ github.run_number }}` geçiyor (sürüm adı her derlemede ilerler, Release `v1.1.N`). Bayraksız derlenen APK versionCode 1 olur ve telefondaki CI sürümünün üstüne kurulmaz: `INSTALL_FAILED_VERSION_DOWNGRADE` (adb'nin `-d` bayrağı da bunu geçmez). N, telefondaki sürümün üstü olmalı — telefondaki en güncel sürüm CI'ın ürettiği **372** (v1.0.372, 2026-09-01), yerel derlemede bunun üstünü ver.
  - `flutter install` **DERLEMEZ**, var olan APK'yı kurar — önce `build`, sonra `install`. Kurmadan önce APK'nın tarihine bak.
  - `--target-platform android-arm64`: CI de böyle derliyor; bayrak olmadan APK ~110 MB (tüm mimariler), onunla ~60 MB.
  - CI ayrıca `--split-debug-info=build/app/outputs/symbols` verir. pdfrx 2.x `pdfium.wasm`'ı yalnız web'e paketler; eski pub önbelleği yaması (1.3.5) kaldırıldı.
- APK: CI push'ta imzalı üretir (`.github/workflows/`)
- Firestore/Storage kural değişince: önce `cd rules-test && npm ci && npm test` (emülatör, Java 11+ — CI `rules` işi de koşar), yayın main push'ta CI'da (elle: `firebase deploy`)

## Hafıza (usta koordineli — 3 katman)
- Kod yapısı        → graphify-out/     (oku: GRAPH_REPORT.md · güncelle: elle `graphify update .` — depoda otomatik kanca YOK; grafik 2026-07-30'dan (`ebba874e`) beri BAYAT, satır/dosya bilgisini koddan doğrula)
- Proje ne/niye     → HAFIZA.md         (≤30 KB, geçerli kararlar/tuzaklar — oku: iş başı · yaz: iş sonu, ilgili bölüme; değişen kuralı GÜNCELLE) · tarihçe `HAFIZA_ARSIV.md` (2026-10-19'a kadar, dondurulmuş, grep ile)
- Kullanıcı tercihi → .claude memory/   (otomatik, projeler-arası — proje bilgisi buraya YAZILMAZ)
Yaz kuralı: usta rule 12 / YAZ — tetikleyici (kalıcı karar, bug kök nedeni, yanlış yol) oluştuysa iş bitmeden yaz. Sır/anahtar/kişisel veri hafızaya YAZILMAZ.

## Yol haritası (fazlı plan)
- `YOL_HARITASI.md` — 2026-10-19 dış göz incelemesinden çıkan 4 fazlı plan (güvenlik/veri → akıcılık → sadeleştirme → eksikler). Kullanıcı **"Faz N'i yap"** dediğinde dosyanın başındaki protokolü izle: yalnız o faz, KARAR GEREKİR maddelerinde önce sor, bitince maddeleri `[x]` + Durum tablosu + HAFIZA + commit/push. Kendiliğinden sonraki faza geçme. (Faz 1–4 bitti.)
- `PERFORMANS_TOPARLAMA_PLANI.md` — 2026-10-20 inceleme: **Faz 5–9** (doğrulanmış hatalar + bellek sızıntıları → CPU → RAM → toparlama → ölçüm/isteğe bağlı). "Faz 5'i yap" vb. bu dosyanın başındaki protokolle yürür. (Faz 5–9 bitti, 2026-10-20 — plan tamamlandı.)
- `KULLANICI_DENEYIMI_PLANI.md` — 2026-10-30 baştan sona inceleme (web'de canlı tur + kod): 120 satırlık özellik tablosu (iyi/kötü/yapılmalı) ve **Faz 10–17** (kırıklar → ana ekran → not ekranı → balonlu mod/paylaşım → anlaşılırlık → erişilebilirlik → görsel bütünlük → ölçüm). "Faz 10'u yap" vb. dosyanın başındaki protokolle yürür.
