# DEVIR — P35 (Faz 74: ana ekran cilası), dal `oto/P35-ana-ekran` (taban origin/main 8b5c24db)
- **Yapılanlar (hepsi [x]):** F74.1 K-D3 ev düğmesi `primaryContainer` (8e23ff1a) · F74.2 K-D4 şeritte gün adı üç harf (54b96865) · F74.3 zamanı gelen şeridi belirteçlerle, ✕ `MinTapTarget` · F74.4 K-D5 kartta işaretliler tek satır + `card_show_checked` + ⋮ sessiz · F74.5 "+" yanındaki mikrofon nötr · F74.6 boş ana ekranda "İlk notunu yaz" + tur `TOUR_EMPTY=1`.
- **Üstünde çalışılan:** yok — paket bitti; cihaz A/B bekliyor.
- **Kanıt:** `card_preview.dart` `cardItemSlice` + `test/card_checked_collapse_test.dart` (yeni); `folder_strip_chips_test` ev düğmesi rengi + boyu; `calendar_backdrop_themes_test` 360 dp'de "Pzt"; `due_items_test` ✕ `MinTapTarget`, şerit 44 dp; `color_roles_test` mikrofon nötr; `home_gestures_test` "İlk notunu yaz". `perf_budget_test`, `keyboard_jank_guard_test`, `design_tokens_guard_test` (bütçe düştü) yeşil; `flutter analyze` temiz.
- **Kapsam notu:** F74.4 tercihi için `settings_providers`, `prefs_sync`, `settings_appearance`, ARB'ler (plan "card_show_* kalıbıyla"). F74.5/F74.6 `dashboard_widgets.dart`/`dashboard_slivers.dart` (dashboard_screen part'ları) — yalnız `_DashVoiceButton` rengi, `HomeEmptyNotes` etiketi; P19 dalı main'de (fark yok). `EmptyState` §2.3 ölçüsü F79.6'ya (P40) kaldı.
- **Testler güncellendi:** `card_checked_item`, `note_accent_consistency`, `note_everywhere_same` işaretli kutuyu görmek için `card_show_checked: true` ile koşar.
- **İşe yaramayan / bilinen:** `folder_strip_fixed_test` Windows'ta CRLF yüzünden kırmızı (main'de de; CI Linux'ta yeşil). Kart yüksekliği tahmini özeti bilmiyor (yalnız alt boşluk payı) — sabah bakılacak.
- **Tur:** `build/tour-once` ↔ `build/tour` (%0,5 üstü 97 PNG: hepsi ana ekran ya da yanında liste bölmesi olan bölünmüş sahneler); koyu `build/tour-koyu`. Kabul: `telefon-ana.png`, `telefon-ana-koyu.png`, `telefon-kucuk-ana.png`, `telefon-ana-bos.png`, `telefon-kucuk-ana-bos.png`.
- **Doğrulanmadı:** cihaz A/B (`ab_liste.py` + `ab_klavye.py`) — yürütücü yapacak (ÖLÇÜM KAPISI). CI bu dalda izlenmedi.
- **Sıradaki:** CI yeşil + A/B regresyon yok → main'e `[apk]` + sürüm notu (aşağıda).
- **Açık test komutu:** `flutter test test/card_checked_collapse_test.dart test/folder_strip_chips_test.dart test/calendar_backdrop_themes_test.dart test/due_items_test.dart test/color_roles_test.dart test/home_gestures_test.dart test/design_tokens_guard_test.dart test/perf_budget_test.dart test/keyboard_jank_guard_test.dart --reporter failures-only`

## Sürüm notu maddeleri
- Ana ekran daha sakin: ev düğmesi ve mikrofon artık göz almıyor, tek dolu düğme "+".
- Takvim şeridinde günler tek harf yerine kısaltmayla yazıyor (Pzt, Sal, Çar…).
- Kartta tamamlanan maddeler tek satıra iniyor: "✓ 3 tamamlandı" — yapılacaklar öne çıkıyor. Eskisi gibi görmek için Ayarlar → Görünüm → Kartta görünenler → "Tamamlanan maddeler".
- Hiç not yokken ana ekranda tek düğme: "İlk notunu yaz".
