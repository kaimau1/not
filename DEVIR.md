# DEVIR — P43 (oto/P43-hiz-olcum), bu tur yalnız F82 (cihazsız)

## Yapılanlar
- F82.2 `test/jank_patterns_guard_test.dart` (kaynak tarama; md. 3/4/6/7, bozma denemesi testte) — commit 1.
- F82.1 S18–S25 `test/perf_budget_test.dart` + `budgets.json` (bugünkü değer = mandal) + S17 sabit görsel klavye evresi (`keyboard_jank_guard_test`); OTURTMA Ek A satırları — commit 2.
  `_pumpHome` artık DashboardScrollMemory + TipOnce oturumunu sıfırlar (yoksa sayılar test sırasına bağlıydı: S18 877↔879, S23 kaydırma geçmiyordu).

- F82.3 `test/editor_leak_test.dart` 'uzun oturum' (200 gir-çık + 50 klavye; denetleyici + akış aboneliği başlangıçla aynı; bozma: _titleController.dispose() kaldırınca 200 sızıntıyla kırmızı) — commit 3.

## Nerede kaldım
- F82 bitti (cihazsız). CI kontrolü.

## Bulgular (DÜZELTİLMEDİ — P46/P49 satırlarına yazıldı)
- S21 arama: harf başına 114 NoteCard (görünür 18).
- S25 `note_card_media.dart` `_image` thumbUrl dalı (~satır 868) `memCacheWidth` yok → 21 kart tam boy çözülüyor.
- S22 takvim hafta fırlatma tek karede 978 kurulum; S23 süzgeç kaydırma 2941.
- Editör kökünde gövde Column'unda 3 AnimatedSize (`note_editor_screen.dart` ~4140/4204/4374).
- S17 sabit görsel/PDF: hareket karelerinde sabit bölme diziliyor (P49).

## Test
- `C:/src/flutter/bin/flutter.bat test test/perf_budget_test.dart test/jank_patterns_guard_test.dart test/keyboard_jank_guard_test.dart test/editor_leak_test.dart --reporter failures-only`

## Sonra
- F81 (cihaz: ab_hepsi.py, altın taban) — bu turda YAPILMADI. Sıradaki: F81 (cihaz).
