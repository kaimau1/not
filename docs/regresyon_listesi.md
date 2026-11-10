# Regresyon listesi

Düzeltilen HER sorun tek satır (OTURTMA_PLANI protokol madde 8). Her faz/paket bitiminde
liste baştan koşulur: otomatik olanlar test, cihaz isteyenler en az ölçümle. Kırmızı çıkan
şey fazı kapatmaz.

| Madde | Belirti | 1 dakikalık denetim | Beklenen |
|---|---|---|---|
| F60.1 | Sabit/gömülü PDF'e kalemle yazarken her çizgide bütün editör kuruluyor ve anında tam kayıt atılıyor (yazarken takılma) | `flutter test test/perf_budget_test.dart --reporter failures-only` (S6, S7); cihazda `tool/perf/ab_kalem.py` PDF evresi (F59.5'ten sonra) | 10 çizgide kök kurulum ≤ 1, `updateNote` ≤ 1; sayfa çevirince ve not kapanınca çizgiler duruyor |
