# DEVIR — Entegrasyon P55 + P56 + P38 + P50 (dal `oto/entegre-P55-P56-P38-P50`)

`origin/main` (4b5a0a88) üstüne sırayla `--no-ff`: `oto/P55-kasma`, `oto/P56-surukle-zipla`,
`oto/P38-hareket`, `oto/P50-duzenleme`. Paket başına ayrıntılı devir notları ilgili dallardaki
`DEVIR.md`'de (git show origin/oto/<dal>:DEVIR.md).

## Çakışma çözümü
- `OTOMASYON.md`: main'deki P55/P56/P38/P50 satırları dallardakinden yeni ("cihaz bekliyor") → main korundu.
- Sürüm notları TR/EN: dört paketin maddeleri tek `13 Kasım 2026 {#2026-11-13}` başlığında birleşti.
- `KALANLAR.md`: P50'nin cihaz adımı L13 → **L14** (L13 tablette dikte); KUYRUK_AYRINTI §P50 ve regresyon listesi buna göre.
- `lib/core/widgets/customizable.dart` kendiliğinden birleşti: P50 düzenleme modu (anında uygula, Geri al/Bitti) + P38 `AppHaptics.tick`.

## Durum
- Kod birleşti, CI dalda; main'e `[apk]` birleştirme cihaz A/B (`tool/perf/ab_hepsi.py --altin`) GEÇTİ'den sonra.
- A/B APK'ları: `Desktop\ab_apk\A_main.apk` (4b5a0a88), `Desktop\ab_apk\B_entegre.apk` (bu dal).

## Paketlerin kalan işi
- P55: F84.1/F84.2 (uzun tek paragrafta tuş başı tam tarama) düzeltilmedi; F68.3 sabah bakılacak; önceki A/B'de yalnız altın tabana karşı `yaz` LAYOUT +%33.
- P56: cihazda elle: iki sütun sınırında zıplama yok mu, 100 ms durma hissediliyor mu.
- P38: çitteki 35 doğrudan `HapticFeedback` (dashboard_*, note_editor_*, items_editor*) `AppHaptics`e göçmedi; bildirim şeridi kayması yapılmadı.
- P50: ana ekran sarmaları ve üst çubuk sıralama yok (P20); düzenleme modunda yerinde sürükle-sırala yok.
- Hepsi: cihazda doğrulanmadı (KALANLAR §2).
