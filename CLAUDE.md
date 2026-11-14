# CLAUDE.md — Not (Flutter not uygulaması)

Flutter + Firebase (Firestore/Storage senkron) not uygulaması; Android + web hedefli (Windows sürümü 2026-10-19'da kaldırıldı, bilgisayarda web). AI özellikleri Gemini tabanlı: asistan, sesli komut, canlı çeviri, semantik arama, OCR, PDF sohbet, günlük brifing. Dil: Türkçe.

> 🔐 **İmza anahtarı**: `Desktop\Yazılımlar\notlar-keystore\notlar-release.jks` (repo DIŞINDA; repoda `android/app/*.jks` ve `android/key.properties` YOK — yerel imzalı derleme için önce ikisi yerine konmalı). Kullanıcı makine dışı yedeği aldı (2026-11-01). Asla commit'leme, grafa/zip'e katma, içeriğini yazdırma; **kaybolursa aynı imzayla güncelleme yayınlanamaz.** CI imzası GitHub Secrets'ta.

## Komutlar
> ⚠️ **`flutter` PATH'te DEĞİL**: tam yol `C:\src\flutter\bin\flutter.bat`; Bash'ten `"C:/src/flutter/bin/flutter.bat" test`. "command not found" = SDK yok DEMEK DEĞİL; testleri koşmadan commit'leme.
- Kurulum: `flutter pub get` · Çalıştır: `flutter run` · Test: `flutter test -j 4`
- **Bulutta Flutter**: önce `/opt/flutter/bin/flutter` (PATH'e ekle). Yoksa 3.47.9: `https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.9-stable.tar.xz` → scratchpad'e aç → PATH. `pub get` `pubspec.lock`'u (bağımlılık eklemediysen) değiştirirse commit'e katma.
- **DOĞRULAMA = CI (kullanıcı kararı 2026-11-05):** tam takımı oturumda/yerelde KOŞMA (paylaşılan çekirdek değişse bile); push öncesi tam takım yok.
  1. Oturumda: `flutter test test/<ilgili>_test.dart --reporter failures-only` + `dart analyze <değişen dosyalar>` (hızlı geri bildirim; zorunlu değil). İlgili test yoksa yaz.
  2. Push et, CI'ı GitHub MCP ile kontrol et (`actions_list`). Kırmızıysa YALNIZ başarısız parçanın kaydını oku (`get_job_logs`, kuyruğu), düzelt, push.
  3. **CI yeşil olmadan "bitti" DENMEZ; CI kırmızıyken main'e birleştirilmez.**
  4. **Test seçimi** (`tool/ci_test_secimi.sh` + `tool/etkilenen_testler.py`): dalda yalnız main'den ayrılınca değişen dosyaların import grafiğinden ETKİLENEN testler koşar (pubspec/.arb/assets/.github değişirse tam takım). main'de birleştirme ağacı yeşil dal başıyla aynıysa test atlanır. Zorlamak: başlıkta `[tam]`. Analiz hep tam.
  5. Uzun komut çıktısını kes (`| tail -n 40`).
- **`dart format lib` ÇALIŞTIRMA**: depo tek biçimde değil, toplu biçimlendirme yüzlerce ilgisiz dosyaya dokunur. Yalnız kendi eklediğin dosyayı biçimlendir (`lib/l10n/generated` hariç — o hep `dart format`).
- **Yerel release APK**: `flutter build apk --release --target-platform android-arm64 --build-number=<N> --dart-define-from-file=env.json`
  - `--dart-define-from-file` ZORUNLU: `GOOGLE_SERVER_CLIENT_ID` olmadan Google girişi çalışma anında çöker (`env.example.json`); CI Secrets'tan geçer.
  - `--build-number=<N>` ZORUNLU: `pubspec.yaml` sabit `1.2.0+1`; bayraksız APK versionCode 1 olur ve telefondaki CI sürümünün üstüne kurulmaz (`INSTALL_FAILED_VERSION_DOWNGRADE`, `-d` de geçmez). N telefondaki sürümün (Ayarlar → Hakkında'daki parantezli sayı) ve son Actions koşu numarasının üstünde olmalı. CI: `--build-name=<ANA.ARA.N> --build-number=${{ github.run_number }}`; ANA.ARA pubspec'te elle (başlıkta `[minor]` +1), N = `[apk]` sayısı (`tool/surum_hesapla.sh`; Release `v1.2.N`).
  - `flutter install` **DERLEMEZ**, var olan APK'yı kurar — önce `build`, sonra `install`; kurmadan önce APK tarihine bak.
  - `--target-platform android-arm64`: CI de böyle (bayraksız ~110 MB, bununla ~60 MB); CI ayrıca `--split-debug-info=build/app/outputs/symbols` verir.
- APK: CI push'ta imzalı üretir (`.github/workflows/`)
- Firestore/Storage kuralı değişince: önce `cd rules-test && npm ci && npm test` (emülatör, Java 11+; CI `rules` işi de koşar); yayın main push'ta CI'da (elle: `firebase deploy`)

## Sürüm notları (kullanıcı isteği 2026-11-10)
Her `[apk]` birleştirmesinde `assets/guide/release_notes_tr.md` ve `_en.md`'ye günün bölümü (`## 10 Kasım 2026 {#2026-11-10}`, en yenisi üstte) kullanıcı diliyle "ne değişti" maddesi eklenir (commit başlığı değil). İki dosyada tarih kimlikleri aynı (`test/guide_screen_test.dart` bekçisi).

## Gece / zamanlanmış görev kuralı (kullanıcı kararı 2026-11-03; zincir izni 2026-11-09)
- Gözetimsiz zincir: yürütücü **`oto-tur` skill'ini**, alt ajan **`isci` skill'ini** uygular; Kuyruk ve SIRA `OTOMASYON.md`'de (ayrıntı Kuyruk satırı + `PLAN.md`).
- Plan KARAR maddeleri verilmiştir (**KARAR (kullanıcı, 2026-11-03)**): SORMADAN uygula; yeni karar → en güvenli seçenek + "sabah bakılacak".
- Dalda çalış → CI yeşilse main'e birleştir (`[apk]`, kişisel APK, `NOTLAR_KISISEL=1`); **CI kırmızıyken main'e ASLA birleştirme**, main kırmızıysa düzelt ya da `git revert -m 1`.
- Telefon gerektiren ölçüm yapılamazsa "yazıldı, cihazda doğrulanmadı" + `KONTROL_LISTEM.md` "Telefonda bak". Veri göçü / kayıt sıfırlama (F22.4, F28.2): önce yerel tam yedek, geri alınabilir göç, `rules-test` yeşil.

## Kasma ve hız kapıları (bağlayıcı)
- **Kasma kontrol listesi (2026-11-09):** editöre/kart ızgarasına GÖRÜNÜR yeni alan, kip ya da sarmalayıcı eklerken push'tan önce **`kasma-kontrol` skill'ini** uygula (8 madde; `test/perf_budget_test.dart` kırmızıysa birleştirme yok).
- **ÖLÇÜM KAPISI (2026-11-10):** editör, klavye, alt/üst çubuk, ana ekran listesi ya da geçişe dokunan iş `[apk]`'dan önce cihazda A/B ölçülür (`tool/perf/ab_hepsi.py <A> <B> --altin`, taban = önceki `[apk]` profil derlemesi; evrede UI/LAYOUT ms > %20 = birleştirme yok). Ayrıntı: **`ab-olcum` skill'i**.
- **HIZ SÖZLEŞMESİ (2026-11-12; tedbirler `docs/hafiza/akicilik.md` sonu):** dokunulan yüzeyin bütçe senaryosu `test/perf_budget_test.dart`'ta olmalı; her `[apk]` öncesi tam ölçüm (önceki `[apk]` %20, altın taban %15); hız işlerinde kötüleşme SIFIR; mandallar yalnız düşer. Ölçmeden "akıcı/hızlı" denmez. Ayrıntı: **`ab-olcum` skill'i**.

## Hafıza (3 katman)
- Kod yapısı → `graphify-out/` (oku: GRAPH_REPORT.md · güncelle: elle `graphify update .`, otomatik kanca yok; son 2026-11-12 — kod ilerledikçe bayatlar, satır/dosya bilgisini koddan doğrula)
- Proje ne/niye → `HAFIZA.md` (≤30 KB, `test/hafiza_size_test.dart` bekçisi: ortam + her oturumda geçerli kurallar + konu dizini — iş başı oku) → ayrıntı `docs/hafiza/*.md` (ortam_ci, veri, akicilik, editor, kalem, ekler_pdf, arayuz, web, takvim_gmail, ai_ses; iş sonu İLGİLİ konu dosyasına yaz, değişen kuralı GÜNCELLE) · tarihçe `HAFIZA_ARSIV.md`, `_2`, `_3` (dondurulmuş, grep)
- Kullanıcı tercihi → `.claude memory/` (otomatik, projeler-arası; proje bilgisi YAZILMAZ)
Yaz kuralı: kalıcı karar, bug kök nedeni ya da yanlış yol oluştuysa iş bitmeden yaz. Sır/anahtar/kişisel veri hafızaya YAZILMAZ.

## Yol haritası
**Açık iş: `PLAN.md`; kullanıcının kontrol listesi: `KONTROL_LISTEM.md`; eski planlar `docs/arsiv/planlar/` (yalnız geçmiş; koddaki `TEMA_PLANI F31.4` gibi kimlikler orada).** "Faz N'i yap" denince arşivdeki planın başındaki protokol: önce kanıtı üret, sonra düzelt; yalnız o faz; KARAR GEREKİR'de sor; bitince `[x]` + Durum + HAFIZA + commit/push. Akıcılık bütçesi bağlayıcı.
- **Bileşenin görünüşünü/yerini değiştirmeden önce `python tool/design/istek_tara.py <dosya>`**; çelişen fikir yapılmaz — tasarım ilkeleri + 16 "yapılmayacak" `docs/hafiza/arayuz.md` sonunda (ölçüyü elle yazma: `AppRadius`/`AppSpace`/`AppText`/`AppMotion`). Görsel tur: `flutter test tool/tour/screen_tour_test.dart`.
- **Dondurma (K-O1, F58.1):** plan dışı yeni özellik fikirleri `ISTEK_KUTUSU.md`'ye yazılır, gözetimsiz zincir kendiliğinden yeni özellik açmaz; düzeltme, bug fix ve kullanıcının sohbette açıkça istediği iş yapılır. Plan F69.5'e göre kapanışta kalkacaktı — kaldırmak kullanıcı kararı (sabah bakılacak), o güne dek geçerli.
- **Oturum disiplini (F58.4):** bir oturum = bir faz/konu; `[apk]` başına en çok 5 kullanıcıya görünür değişiklik; her `[apk]`'dan önce bütçe testleri (`test/perf_budget_test.dart`) yeşil; "yazıldı, cihazda doğrulanmadı" maddeleri (`KONTROL_LISTEM.md`) 40'ı geçerse yeni iş durur, cihaz turu yapılır.
