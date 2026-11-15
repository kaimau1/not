# DEVIR — oto/madde-kasma (kullanıcı bulgusu "normal madde notundaki kasma")

Yapılanlar (tek commit'te kod + test + belge):
- `NoteEditorScreen._mutate(itemsShown:)`: ItemsEditor'dan gelen madde değişikliği kökü kurmaz (yalnız liste boş/dolu değişirse).
- `ItemsEditor._updateText`: boş↔dolu geçişte yerel setState (kutunun etkinleşmesi kökten geliyordu).
- `ItemsEditor._slotCache` + shrinkWrap'te `addAutomaticKeepAlives: false`: değişmeyen satırın yuvası/sarmalayıcıları kurulmaz.
- `_disposeRowFor`: FocusNode kare sonunda atılır (silinen odaklı satır → ~110 Focus kurulumu yok).
- S50 bütçe senaryosu, S3/S4 kök 1→0; `test/items_root_skip_test.dart`; row_cache yuva testi.

Kanıt S50 (dalda S48 idi; main S48=şablon) (40 madde; kurulum/dizilme), önce → sonra:
- kutucuk (+1 sn) 2331/442 → 587/335 · Enter 1499/486 → 566/430 · Geri Sil 1450/300 → 569/273 · kök 4 → 0

Kalan (çerçeve, dokunulmadı): ilk odakta ~210 Focus; geri sil tuş olayı vurgu kipini değiştirince ~25 InkResponse; tuş başına ~106 kurulum.
Yerel tuzak: worktree CRLF (autocrlf) → `editor_core_guard_test` yerelde `;\n` bulamaz; dosyayı LF yap ya da CI'a güven.

Test: `flutter test test/perf_budget_test.dart --plain-name S50`; `flutter test test/items_root_skip_test.dart test/items_editor_row_cache_test.dart test/items_editor_*_test.dart`.
Sıradaki: CI yeşil → yürütücü birleştirir; cihazda KONTROL_LISTEM "Madde notunda kasma".
