# DEVIR — P56 (not sürükle-sırala: iki sütun arasında zıplama)

Dal: `oto/P56-surukle-zipla` (main 2026-11-13 birleştirildi).

## Durum
- Kod bitti: `lib/features/notes/presentation/reorder_hover_gate.dart` (durma 100 ms, soğuma 300 ms, itilen kart parmak çıkana dek kilitli); `dashboard_screen.dart` `_previewCardDrop` kapıdan geçer, durgun parmak için `_hoverRetry` zamanlayıcısı; hücrelerde `DragTarget.onLeave` → `_leaveCardHover`.
- Kanıt: `test/reorder_boundary_jitter_test.dart` (ana ekran, iki sütun sınırında ±6 px titreşim, 60 kare). Kapı kapalı: 60 yer değişimi (KIRMIZI); kapıyla ≤ 1 (YEŞİL). Birim: `test/reorder_hover_gate_test.dart`. `drag_trash_target_test` yeşil (P47/P58 korunur).
- Belgeler: OTOMASYON P56 satırı, KUYRUK_AYRINTI §P56 Durum, regresyon listesi, hafiza/akicilik.md, sürüm notları 13 Kasım (tr/en).
- Bütçe: ana ekran yüzeyi S13 (`perf_budget_test`) mevcut; kapı yer değişimi (setState) sayısını yalnız AZALTIR.

## Kalan
- CİHAZ A/B (ÖLÇÜM KAPISI, ana ekran listesi) — yürütücü. Elle: notu iki sütun sınırında tut → zıplama yok; bilinçli taşıma akıcı mı (100 ms durma hissediliyor mu)?
- Sonra main'e `[apk]` birleştirme.
