# Regresyon listesi

Düzeltilen HER sorun tek satır (OTURTMA_PLANI protokol madde 8). Her faz/paket bitiminde
liste baştan koşulur: otomatik olanlar test, cihaz isteyenler en az ölçümle. Kırmızı çıkan
şey fazı kapatmaz.

| Madde | Belirti | 1 dakikalık denetim | Beklenen |
|---|---|---|---|
| F60.1 | Sabit/gömülü PDF'e kalemle yazarken her çizgide bütün editör kuruluyor ve anında tam kayıt atılıyor (yazarken takılma) | `flutter test test/perf_budget_test.dart --reporter failures-only` (S6, S7); cihazda `tool/perf/ab_kalem.py` PDF evresi (F59.5'ten sonra) | 10 çizgide kök kurulum ≤ 1, `updateNote` ≤ 1; sayfa çevirince ve not kapanınca çizgiler duruyor |
| F60.S2 | Notlara gir-çık yaptıkça klavye açılışında alt panel kasması artıyor (birikim) — cihazsız üretilemedi, bekçi konuldu | `flutter test test/editor_leak_test.dart --reporter failures-only`; cihazda taze açılış ile 30 gir-çık SONRASI `tool/perf/ab_klavye.py` klavye evresi | 18 gir-çıkta atılmamış nesne ve genel dinleyici artmaz, klavye turu kurulum sayıları aynı; cihazda 30 gir-çık sonrası UI ms taze açılışın ≤ %110'u |
| F60.S3 | "Tümü" çipine dokununca Klasörler ekranı açılıyordu; klasör içindeyken "Tümü" de vurgulu kalıyordu | `flutter test test/folder_strip_chips_test.dart --reporter failures-only` | Tümü dokun = ana ekranda bütün notlar (klasör/süzgeç sıfır), uzun bas = `/folders`; ev/Tümü/Gelen/kendi/paylaşılan çipte yalnız dokunulan vurgulu |
