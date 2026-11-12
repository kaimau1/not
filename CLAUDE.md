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

## Gece / zamanlanmış görev kuralı (kullanıcı kararı 2026-11-03)
- **Gözetimsiz zincir (2026-11-09 izni):** yürütme düzeni, işçi/telefon kuralları ve iş kuyruğu `OTOMASYON.md`'de (paket ayrıntıları `KUYRUK_AYRINTI.md`); zamanlanmış oturum önce onu okur, "Bir turun adımları"nı uygular.
- Plan dosyalarındaki KARAR maddeleri verilmiştir (**KARAR (kullanıcı, 2026-11-03)**): SORMADAN uygula; yeni karar çıkarsa en güvenli seçeneği uygula, maddeye "sabah bakılacak" yaz.
- Akış: kendi dalında çalış → değişenin testi → push → **CI yeşilse main'e birleştir, başlıkta `[apk]`** (kişisel APK; CI'da `NOTLAR_KISISEL=1`) → main CI'ını izle; kırmızıysa düzelt ya da birleştirmeyi geri al (`git revert -m 1`). CI kırmızıyken main'e ASLA birleştirme.
- Telefon gerektiren ölçüm yapılamaz: "yazıldı, cihazda doğrulanmadı" işaretle, `KALANLAR.md` §2'ye adım ekle.
- Veri göçü / kayıt sıfırlama (F22.4, F28.2): önce yerel tam yedek, göç geri alınabilir, kural testleri (`rules-test`) yeşil.

## Kasma kontrol listesi — "editör baştan kuruluyor" (kullanıcı isteği 2026-11-09)
Editöre/kart ızgarasına GÖRÜNÜR yeni alan, kip ya da sarmalayıcı eklerken, push'tan ÖNCE:
1. Yeni madde/not alanı → üç karşılaştırmaya da ekle: `sameItemsVisually` (note_editor_screen), `ItemsEditor._sameItems`, `text_merge._sameItem`. Eksikse Firestore yankısı her kayıtta "değişti" sayılır → editör baştan kurulur.
2. Satır önbelleği (`ItemsEditor._cachedItemRow`): satırı değiştiren alan anahtara girsin; liste düzeyi girdi `_syncRowCache` env'ine. Env'e HER BUILD'DE YENİ nesne (map, liste, kapanış) koyma — önbellek her karede boşalır.
3. Yerel UI durumu (aç/kapa, seçim, hover) için editörün KÖK `setState`'i değil, alt widget'ın kendi durumu ya da `ValueNotifier` + dar `ListenableBuilder`.
4. Sarmalayıcı (Stack, KeyedSubtree, TapRegion) eklediysen ağaç ŞEKLİ koşula göre değişmesin (koşulda `SizedBox.shrink` tut) — şekil değişince alt ağaç ve metin alanları sıfırdan kurulur.
5. Doğrula: `test/items_editor_row_cache_test.dart` kalıbıyla "girdisi değişmeyen satır `identical`" testi yaz; şüphede `tool/perf/` ile cihazda ölç. Ölçmeden "düzeldi" deme.
6. **Editör gövdesiyle aynı Column/Row'daki bir şeyin BOYUNU animasyonla değiştirme** (yükseklik, `heightFactor`, `AnimatedSize`, `AnimatedContainer` boyu): gövde her karede yeniden dizilir. Boy TEK ADIMDA değişsin, hareket yalnız boyamada (`Transform`/`FractionalTranslation`/`Opacity`). Bekçi: `keyboard_jank_guard_test.dart`.
7. Klavyeye bağlı gösterme/gizleme (`KeyboardSwitch`) alt ağacı SÖKMEZ: iki taraf da kurulu, `Offstage` ile değişir. `MediaQuery.of(context)` kök/kabuk bağlamında okunmaz — `viewInsetsOf`/`sizeOf` ya da ayrı küçük öğe.
8. `test/perf_budget_test.dart` kırmızıysa birleştirme yok (bütçeler `test/perf_budget/budgets.json`, mandal: yalnız DÜŞER; senaryolar OTURTMA Ek A).

**ÖLÇÜM KAPISI (2026-11-10):** editör, klavye, alt/üst çubuk, ana ekran listesi ya da geçişe dokunan iş `[apk]`'ya girmeden önce cihazda A/B ölçülür: `tool/perf/ab_klavye.py` (klavye aç/kapa ×3, yazma ×4, not kapanışı; evre başına UI kare/ms/LAYOUT). Taban: önceki `[apk]` commit'inin profil derlemesi (`git worktree add ../not_ab <commit>` → `flutter build apk --profile`). Bir evrede UI ms ya da LAYOUT ms %20'den fazla artarsa birleştirme yok — önce kök neden. Telefon yoksa tablette telefon düzeni: `adb shell wm size 1080x2400; adb shell wm density 420` (sonra `wm size reset; wm density reset`); fiziksel klavye takılıysa ⌨ ile sanal klavye.

**HIZ SÖZLEŞMESİ (2026-11-12):** plan `HIZ_PLANI.md` (Faz 81–84). (1) Yeni özellik/güncelleme hangi yüzeye dokunursa (editör, liste, geçiş, levha, arama, açılış, ekler) o yüzeyin cihazsız bütçe senaryosu `test/perf_budget_test.dart`'ta olmalı — yoksa işin parçası olarak YAZILIR (OTURTMA Ek A'ya S satırı). (2) Her `[apk]` öncesi cihazda tam ölçüm (`tool/perf/ab_hepsi.py --altin` hazır olunca; o güne dek `ab_klavye.py` + `ab_liste.py`) — önceki `[apk]`'ya karşı %20, altın tabana karşı %15 kayma = birleştirme yok. (3) Hız/akıcılık işlerinde kötüleşme SIFIR; madde başı ayrı commit, kötüleştiren tek commit geri alınır, iyiler birleşir. (4) Mandallar (`budgets.json`, tasarım bütçesi, altın taban) yalnız düşer. Ölçmeden "akıcı/hızlı" denmez.

## Hafıza (3 katman)
- Kod yapısı → `graphify-out/` (oku: GRAPH_REPORT.md · güncelle: elle `graphify update .`, otomatik kanca yok; son 2026-11-12 — kod ilerledikçe bayatlar, satır/dosya bilgisini koddan doğrula)
- Proje ne/niye → `HAFIZA.md` (≤30 KB, `test/hafiza_size_test.dart` bekçisi: ortam + her oturumda geçerli kurallar + konu dizini — iş başı oku) → ayrıntı `docs/hafiza/*.md` (ortam_ci, veri, akicilik, editor, kalem, ekler_pdf, arayuz, web, takvim_gmail, ai_ses; iş sonu İLGİLİ konu dosyasına yaz, değişen kuralı GÜNCELLE) · tarihçe `HAFIZA_ARSIV.md`, `_2`, `_3` (dondurulmuş, grep)
- Kullanıcı tercihi → `.claude memory/` (otomatik, projeler-arası; proje bilgisi YAZILMAZ)
Yaz kuralı: kalıcı karar, bug kök nedeni ya da yanlış yol oluştuysa iş bitmeden yaz. Sır/anahtar/kişisel veri hafızaya YAZILMAZ.

## Yol haritası
**Açık iş önceliği: `OTOMASYON.md` Kuyruk (ayrıntı `KUYRUK_AYRINTI.md`) → `HIZ_PLANI.md` → `DENEYIM_PLANI.md` → `OTURTMA_PLANI.md`.** "Faz N'i yap" denince dosyanın başındaki protokol: önce kanıtı üret, sonra düzelt; yalnız o faz; KARAR GEREKİR'de sor; bitince `[x]` + Durum + HAFIZA + commit/push. Akıcılık bütçesi (AKICILIK Faz 21/23) bağlayıcı.
- `HIZ_PLANI.md` — hız güvencesi, Faz 81–84, kuyruk P43–P46. `DENEYIM_PLANI.md` — görünüş/his, Faz 72–80, kuyruk P33–P42; tasarım sözleşmesi §2 (ölçüyü elle yazma), kararlar K-D1…K-D10 verildi. **Bileşenin görünüşünü/yerini değiştirmeden önce `python tool/design/istek_tara.py <dosya>`**; çelişen fikir yapılmaz (§4). `OTURTMA_PLANI.md` — ANA PLAN, Faz 58–69, kararlar K-O1…K-O14 AÇIK; eski planlarla çelişirse bu geçerli.
- Açık (alt): `KALAN_ISLER_PLANI.md` (Faz 18/19/28; cihaz doğrulama `KALANLAR.md` §2), `TEMA_PLANI.md` (Faz 29–35, kısmen), `TUTARLILIK_PLANI.md` (Faz 36–45; görsel tur `flutter test tool/tour/screen_tour_test.dart`), `TAKVIM_PLANI.md` (Faz 46–53, `lib/features/calendar/`), `YORUM_ANALIZI_PLANI.md` (Faz 54–57), `AKICILIK_PLANI.md` (Faz 20–27, `tool/perf/`).
- Bitti: `YOL_HARITASI`, `PERFORMANS_TOPARLAMA_PLANI`, `KULLANICI_DENEYIMI_PLANI`.
