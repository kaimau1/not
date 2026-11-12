# DEVIR — P35 (Faz 74: ana ekran cilası), dal `oto/P35-ana-ekran` (taban origin/main 8b5c24db)
- **Yapılanlar:** F74.1 K-D3 ev düğmesi `primaryContainer` (8e23ff1a) · F74.2 K-D4 şeritte gün adı üç harf (54b96865) · F74.3 zamanı gelen şeridi belirteçlerle, ✕ `MinTapTarget` · F74.4 K-D5 kartta işaretliler tek satır + `card_show_checked` + ⋮ sessiz.
- **Üstünde çalışılan:** F74.5 ("+" yanındaki mikrofon nötr) → F74.6 (boş ana ekran).
- **Kanıt / kök:** `card_preview.dart` `cardItemSlice` (saf; `test/card_checked_collapse_test.dart` yeni — eskiyle derlenmez/kırmızı → yeşil); `folder_strip_chips_test` ev düğmesi rengi + boyu; `calendar_backdrop_themes_test` 360 dp'de "Pzt"; `due_items_test` ✕ `MinTapTarget`, şerit 44 dp.
- **Kapsam notu:** F74.4 tercih için `settings_providers`, `prefs_sync`, `settings_appearance`, ARB'lere girildi (plan "card_show_* kalıbıyla" diyor). F74.5/F74.6 `dashboard_widgets.dart` / `dashboard_slivers.dart` (dashboard_screen'in part dosyaları) — yalnız `_DashVoiceButton` rengi ve `HomeEmptyNotes` etiketi; P19 dalı main'de (fark yok).
- **Testler güncellendi:** P32/renk bekçileri (`card_checked_item`, `note_accent_consistency`, `note_everywhere_same`) işaretli kutuyu görmek için `card_show_checked: true` ile koşar. `design_tokens/budget.json` düştü.
- **İşe yaramayan:** `folder_strip_fixed_test` Windows'ta CRLF yüzünden kırmızı (`'\n}\n'` arıyor) — main'de de aynı, CI (Linux) yeşil; dokunulmadı.
- **Doğrulanmadı:** cihaz A/B (`ab_liste.py` + `ab_klavye.py`) — yürütücü yapacak. Kart yüksekliği tahmini (`estimateNoteCardHeight`) özeti bilmiyor: yalnız alt boşluk payı.
- **Açık test komutu:** `flutter test test/card_checked_collapse_test.dart test/folder_strip_chips_test.dart test/calendar_backdrop_themes_test.dart test/due_items_test.dart test/design_tokens_guard_test.dart test/perf_budget_test.dart test/keyboard_jank_guard_test.dart --reporter failures-only`

## Sürüm notu maddeleri
- (doldurulacak)
