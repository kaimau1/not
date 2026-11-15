# DEVIR — oto/sablon-kasma (kullanıcı bulgusu "şablon oluştururken aşırı kasıyor")

Yapılanlar:
- 8820bba2 `showNoteTemplateSheet`: levha örneği builder dışında bir kez (klavye karesinde yeniden kurulmaz) + `TemplateComposer._memo` satır/çip örnek önbelleği.
- 36293386 `TemplateEditorScreen`: `_dirty` → `_dirtyN` ValueNotifier, yalnız PopScope dinler.
- bafc0144 S47 bütçe senaryosu (`test/perf_budget_test.dart`, `budgets.json`) + geri onayı testi (`note_templates_test`).
- Belgeler: akicilik.md, regresyon_listesi, KONTROL_LISTEM "Telefonda bak", sürüm notu 15 Kasım.

Kök neden / kanıt (S47, önce → sonra):
- klavye 6 inset karesi kurulum 14124 → 396, dizilme 5784 → 258 (builder `MediaQuery.viewInsetsOf` okur, her çağrıda yeni `NoteTemplateSheet` → 74 çip + satırlar kare başına baştan)
- öneri çipi dokunuşu 2302 → 354; kutucuk 2266 → 328 (kök setState bütün çipleri kuruyordu)
- galeri arama klavyesi 7590 → 330
- düzenleyici (20 madde) 5 tuş 1840 → 191 (ilk tuşta kök setState)

Dokunulmayan: önizleme açılış ilk karesi ~2400 kurulum (74 çip; sonraya yaymak levha boyunu değiştirir). Aynı builder kalıbı: capture_mode_sheet, file_use_sheet, place_reminder_sheet, share_target_sheet (kapsam dışı).

Test: `flutter test test/perf_budget_test.dart --plain-name S47`; `flutter test test/note_templates_test.dart test/template_sheet_layout_test.dart`.
Sıradaki: CI yeşil → yürütücü birleştirir (cihaz kanıtı ayrı ajanda).
