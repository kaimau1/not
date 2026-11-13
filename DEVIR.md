# DEVIR — P55 KASMA KÖKTEN (dal `oto/P55-kasma`, main 5850b487'den)

## Yapılanlar
- 8f2698e2 alt panel titremesi KÖKÜ: Android<35 motoru (`ImeSyncDeferringInsetsCallback.onProgress`) klavye animasyonunda IME boşluğundan gezinme çubuğunu düşüyor (Mi Note 10 Lite API 31: 18→…→253,1→300,7; son adım 47,3 = gezinme). Video: klavye üst kenarı = bildirilen + 47,3 → çubuk öneri şeridinin altında, sonda birden beliriyordu. Düzeltme `keyboard_snap.dart` `KeyboardInsetScope._trackEngine` + `KeyboardInset.navExcludedWhileAnimating` (yerel `sdkInt`, `MainActivity.kt`; `main.dart` init).
- Kanıt: `test/bottom_panel_jitter_test.dart` (telefon/tablet yatay/dikey × metin/sabit PDF × düz/yarıda dönen/yarıda duran; Android<35 modeli) önce 6 kırmızı → 12 yeşil. Cihaz (ekran kaydı, kare kare): A hareket karelerinin 63/85'inde çubuk görünmez → B 0/85, çubuk–klavye aralığı her karede 6–7 px, ters yön 0.
- Belgeler: plan maddeleri, regresyon satırı, `docs/hafiza/akicilik.md` P55, sürüm notu (13 Kasım).

## Cihaz ölçümleri (B, profil, telefon)
- F84.3 soğuk açılış ilk kare 36–64 ms ✓ (ilk veri karesi 160–228 ms, kart metin dizimi).
- Not açma en uzun 61 ms (gövde paragraf dizimi %37, `findLinks`/`_scanPlainness` %24). Yazma 215 kare, 4 > 16 ms, en uzun 38,9.
- F60.S2: taze vs 30 gir-çık klavye UI en uzun 17,3 → 12,5 ms — birikim yok.
- 4b (P49 `AnimatedSize` 6 kare): P46 sonrası üretilemedi — S17 sabit PDF'te Scaffold yalnız geçiş karelerinde (çevrimde 4) diziliyor; kalan ses hapı `AnimatedSize` klavyede boy değiştirmiyor.

## Açık / doğrulanamayan
- F84.1/F84.2 düzeltmesi yok (döküm var): uzun TEK paragrafta her tuş tüm paragrafı tarıyor. F68.3 yapılamadı (gerçek hesap gerekir) — sabah bakılacak.
- Alt çizgili madde (P55a) cihazda doğrulanmadı. Tablet (API 36) motoru düşmüyor → düzeltme orada etkisiz (beklenen), cihazda bakılmadı.
- A/B APK: A `scratchpad/apk/A_5850b487.apk`, B `scratchpad/apk/B_p55.apk` (yol raporda).

## Komut
`flutter test test/bottom_panel_jitter_test.dart test/keyboard_jank_guard_test.dart test/keyboard_snap_test.dart --reporter failures-only`
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
