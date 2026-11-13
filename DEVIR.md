# DEVIR — P43 (oto/P43-hiz-olcum)

## Yapılanlar
- F82.1–F82.3 bitti, main'de (580e40b1). F81.1–F81.5 `tool/perf/ab_hepsi.py` + kapı metinleri (980cd82c, 3e085383).
- TAM A/B koşusu (2026-11-13, 25→37 °C, AC'de): A=altin_9c837495, B=P39_02ebd989, 3'er koşu →
  `docs/perf/altin_taban.json` + `docs/perf/gecmis.csv` yazıldı. KARAR: KALDI — menu LAYOUT 44→50,
  klasor LAYOUT 82→108 (altın +%33), sabit_kay UI 877→967 ms. Ayrıntı tablo KUYRUK_AYRINTI §P46.
- Düzeltme: `acilis` evresinde UI ms anlamsız (duraklatılmış başlangıç çoğu koşuda 2 kare yakalıyor:
  ab_hepsi.py cold_start) → karar/altın açılışta `ilk_kare_ms`'ye bakar (decide()).

## Şu an (2. işçi, 2026-11-13 sabah)
- Öneri uygulandı (0b741b8c): A/B eşiği %20, koşu başlangıcı < 34 °C, `--altin-yaz` A=B'de 6 koşu (≥5).
- dbfa1233: ready() null odakta bekler. Altın taban SİLİNDİ, 6 koşuluk A=A ile yeniden yazılıyor; sonra kabul A=A `--altin`.

## Önceki (F81 kabulü KALDI)
- Kabul A=A (aynı 9c837495 APK, 36,6–36,9 °C): KARAR KALDI — `yaz` LAYOUT 269→300 yanlış alarm;
  altına karşı `yaz` +%40, `menu` +%28, `not_ac` +%22. Kök: gürültü ±%15 + sıcaklık (HIZ_PLANI F81 Durum).
  Kural gevşetilmedi (en güvenli). Öneri: A/B eşiği %20, altın 5+ koşu ortancası, başlangıç < 34 °C şarjsız.
- F68.4 ölçüldü (liste evresi = ab_liste): > 16 ms %2,3–3,3, hedef %2 tutmadı → P46.
- Belgeler güncel: HIZ_PLANI, OTURTMA F68.4, KUYRUK_AYRINTI §P43, OTOMASYON satırı, regresyon listesi, hafiza/akicilik.

## Tuzaklar
- 2. koşuda (A ve B) `liste` evresi 1 kare yakaladı (kök neden bulunamadı; ortanca etkilenmedi).
- Kilit ekranında yukarı kaydırma USB bildirimini açabiliyor (UsbDetailsActivity) — sonra am start düzeltiyor.
- Ekran ~30 sn'de kilitleniyor: her dokunuştan önce `ready()`. Git Bash'te `adb push` için `MSYS_NO_PATHCONV=1`.

## Komut
`cd tool/perf && PYTHONIOENCODING=utf-8 python -u ab_hepsi.py <A.apk> <B.apk> --etiket-a .. --etiket-b .. --commit .. --altin`
