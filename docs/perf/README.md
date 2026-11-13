# Hız ölçümü geçmişi

- `gecmis.csv`: `tool/perf/ab_hepsi.py` her koşuda evre başına bir satır ekler (etiket = koşu).
- `altin_taban.json`: evre başına en iyi değerler (yalnız iyileşir).
- Özet: `python tool/perf/gecmis.py` → evre başına son 10 koşunun UI ms eğilimi, altın tabana göre %.
  Kayma > %10 olan evre `KAYMA` işaretlenir, çıkış kodu 1. Kendi kendine kontrol: `--self-check`.
- Gürültü: aynı APK tekrarında evre ±%15 oynar (özellikle `menu`, `yaz` LAYOUT); tek koşuluk +%10-15
  kaymayı kesin sayma, ikinci koşuyla doğrula. Açılışta UI ms anlamsız (2 kare); karar `ilk_kare_ms`.
- Haftalık tur: `python tool/perf/gecmis.py`; `KAYMA` varsa OTOMASYON Kuyruk'a `hız: <evre>` satırı ekler.
- Her `[apk]` birleştirmesinden ÖNCE `ab_hepsi.py <A> <B> --altin` (OTOMASYON 8. adım). Telefon yoksa `[apk]` ertelenir.
